--!strict
-- Server-only state machine for Pip High's original Market stock-sorting job.
-- Correct aisle answers and the queued task sequence never enter replicated code.

local MarketStockJobController = {}
MarketStockJobController.__index = MarketStockJobController

local JOB_ID = "market-stock"
local STEPS_PER_SHIFT = 3
local DEFAULT_WAGE = 45
local MAX_REQUEST_ID_LENGTH = 64
local MAX_SHIFT_ID_LENGTH = 96
local MAX_TASK_TOKEN_LENGTH = 128
local MAX_REQUEST_CACHE = 24

local TASK_CATALOG = {
    {
        itemLabel = "Crisp apples",
        prompt = "Which aisle keeps these easy to find?",
        correctChoiceId = "produce",
        choices = {
            { id = "produce", label = "Produce" },
            { id = "bakery", label = "Bakery" },
            { id = "chilled", label = "Chilled Goods" },
        },
        hint = "Fresh fruit belongs with other fruits and vegetables.",
        success = "Fresh pick! The apples are ready in Produce.",
    },
    {
        itemLabel = "Cold milk",
        prompt = "Where should this carton be stocked?",
        correctChoiceId = "chilled",
        choices = {
            { id = "chilled", label = "Chilled Goods" },
            { id = "pantry", label = "Pantry" },
            { id = "home_care", label = "Home Care" },
        },
        hint = "Look for the aisle that keeps food cold.",
        success = "Cool choice! The milk is safely chilled.",
    },
    {
        itemLabel = "Study notebooks",
        prompt = "Which section helps students get class-ready?",
        correctChoiceId = "school_supplies",
        choices = {
            { id = "school_supplies", label = "School Supplies" },
            { id = "produce", label = "Produce" },
            { id = "home_care", label = "Home Care" },
        },
        hint = "Think about what you would pack for class.",
        success = "Sharp sorting! The notebooks are with School Supplies.",
    },
    {
        itemLabel = "Fresh bread",
        prompt = "Where will shoppers look for this loaf?",
        correctChoiceId = "bakery",
        choices = {
            { id = "bakery", label = "Bakery" },
            { id = "pantry", label = "Pantry" },
            { id = "chilled", label = "Chilled Goods" },
        },
        hint = "This item was baked today.",
        success = "Nicely done! The fresh loaf is in Bakery.",
    },
    {
        itemLabel = "Breakfast cereal",
        prompt = "Which aisle stores this shelf-stable box?",
        correctChoiceId = "pantry",
        choices = {
            { id = "pantry", label = "Pantry" },
            { id = "bakery", label = "Bakery" },
            { id = "school_supplies", label = "School Supplies" },
        },
        hint = "It stays fresh on a dry grocery shelf.",
        success = "Great match! The cereal is stocked in Pantry.",
    },
    {
        itemLabel = "Dish soap",
        prompt = "Where should this cleaning item go?",
        correctChoiceId = "home_care",
        choices = {
            { id = "home_care", label = "Home Care" },
            { id = "chilled", label = "Chilled Goods" },
            { id = "produce", label = "Produce" },
        },
        hint = "This helps clean things around the home.",
        success = "Spotless sorting! The soap is in Home Care.",
    },
}

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function validPlayerId(playerId)
    return isInteger(playerId) and playerId > 0
end

local function validIdentifier(value, maximumLength)
    return type(value) == "string"
        and #value > 0
        and #value <= maximumLength
        and value:match("^[%w:_%-]+$") ~= nil
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copied = {}
    for key, child in pairs(value) do
        copied[key] = deepCopy(child)
    end
    return copied
end

local function copyOperation(operation)
    return {
        operationId = operation.operationId,
        playerId = operation.playerId,
        delta = operation.delta,
        reason = operation.reason,
    }
end

local function shuffledIndices(count, randomInteger)
    local indices = {}
    for index = 1, count do
        indices[index] = index
    end
    for index = count, 2, -1 do
        local swapIndex = randomInteger(1, index)
        assert(
            isInteger(swapIndex) and swapIndex >= 1 and swapIndex <= index,
            "randomInteger returned an out-of-range value"
        )
        indices[index], indices[swapIndex] = indices[swapIndex], indices[index]
    end
    return indices
end

local function publicTask(task)
    local definition = TASK_CATALOG[task.catalogIndex]
    local choices = {}
    for publicIndex, definitionIndex in ipairs(task.choiceOrder) do
        local choice = definition.choices[definitionIndex]
        choices[publicIndex] = {
            id = choice.id,
            label = choice.label,
        }
    end
    return {
        token = task.token,
        itemLabel = definition.itemLabel,
        prompt = definition.prompt,
        choices = choices,
    }
end

local function publicState(active, wage)
    if active == nil then
        return {
            active = false,
            jobId = JOB_ID,
            taskLabel = "Sort three market items",
            completedSteps = 0,
            totalSteps = STEPS_PER_SHIFT,
            wage = wage,
        }
    end

    return {
        active = true,
        jobId = JOB_ID,
        taskLabel = "Sort three market items",
        shiftId = active.shiftId,
        completedSteps = active.step - 1,
        totalSteps = STEPS_PER_SHIFT,
        wage = wage,
        task = publicTask(active.tasks[active.step]),
    }
end

local function sameSignature(left, right)
    return left.shiftId == right.shiftId
        and left.taskToken == right.taskToken
        and left.choiceId == right.choiceId
end

local function committed(receipt)
    return type(receipt) == "table"
        and receipt.durable == true
        and (receipt.status == "applied" or receipt.status == "duplicate")
end

function MarketStockJobController.new(options)
    options = options or {}
    assert(type(options.repositoryFactory) == "function", "repositoryFactory is required")
    assert(type(options.shiftIdFactory) == "function", "shiftIdFactory is required")
    assert(type(options.taskTokenFactory) == "function", "taskTokenFactory is required")

    local wage = options.wage or DEFAULT_WAGE
    assert(isInteger(wage) and wage > 0, "wage must be a positive integer")

    local randomInteger = options.randomInteger or math.random
    assert(type(randomInteger) == "function", "randomInteger must be a function")

    return setmetatable({
        _repositoryFactory = options.repositoryFactory,
        _shiftIdFactory = options.shiftIdFactory,
        _taskTokenFactory = options.taskTokenFactory,
        _randomInteger = randomInteger,
        _wage = wage,
        _active = {},
        _completed = {},
    }, MarketStockJobController)
end

function MarketStockJobController:_buildTasks(playerId, shiftId)
    local catalogOrder = shuffledIndices(#TASK_CATALOG, self._randomInteger)
    local tasks = {}
    local seenTokens = {}
    for step = 1, STEPS_PER_SHIFT do
        local catalogIndex = catalogOrder[step]
        local token = self._taskTokenFactory(playerId, shiftId, step)
        assert(
            validIdentifier(token, MAX_TASK_TOKEN_LENGTH),
            "taskTokenFactory returned an invalid token"
        )
        assert(not seenTokens[token], "taskTokenFactory returned a duplicate token")
        seenTokens[token] = true
        tasks[step] = {
            catalogIndex = catalogIndex,
            token = token,
            choiceOrder = shuffledIndices(
                #TASK_CATALOG[catalogIndex].choices,
                self._randomInteger
            ),
        }
    end
    return tasks
end

function MarketStockJobController:getState(playerId)
    if not validPlayerId(playerId) then
        return {
            active = false,
            available = false,
            code = "invalid_player",
        }
    end
    return publicState(self._active[playerId], self._wage)
end

function MarketStockJobController:startShift(playerId, atMarket)
    if not validPlayerId(playerId) then
        return { accepted = false, code = "invalid_player" }
    end
    if atMarket ~= true then
        return {
            accepted = false,
            code = "not_at_market",
            state = publicState(self._active[playerId], self._wage),
        }
    end

    local existing = self._active[playerId]
    if existing ~= nil then
        return {
            accepted = true,
            code = "shift_already_active",
            state = publicState(existing, self._wage),
        }
    end

    local shiftId = self._shiftIdFactory(playerId)
    if not validIdentifier(shiftId, MAX_SHIFT_ID_LENGTH) then
        return { accepted = false, code = "shift_id_unavailable" }
    end

    local built, tasksOrError = pcall(function()
        return self:_buildTasks(playerId, shiftId)
    end)
    if not built then
        return {
            accepted = false,
            code = "task_sequence_unavailable",
            error = tostring(tasksOrError),
        }
    end

    local active = {
        shiftId = shiftId,
        step = 1,
        tasks = tasksOrError,
        requests = {},
        requestOrder = {},
    }
    self._active[playerId] = active
    self._completed[playerId] = nil
    return {
        accepted = true,
        code = "shift_started",
        feedback = "Apron on! Sort each item into its best aisle.",
        state = publicState(active, self._wage),
    }
end

function MarketStockJobController:_recordWage(playerId, operation)
    local repository, openError = self._repositoryFactory(playerId)
    if repository == nil or type(repository.record) ~= "function" then
        return nil, tostring(openError or "repository_unavailable")
    end
    return repository:record(copyOperation(operation)), nil
end

function MarketStockJobController:_rememberRequest(active, requestId, signature, response)
    active.requests[requestId] = {
        signature = deepCopy(signature),
        response = deepCopy(response),
    }
    table.insert(active.requestOrder, requestId)
    while #active.requestOrder > MAX_REQUEST_CACHE do
        local expiredId = table.remove(active.requestOrder, 1)
        active.requests[expiredId] = nil
    end
end

function MarketStockJobController:_replayActiveRequest(active, requestId, signature)
    local prior = active.requests[requestId]
    if prior == nil then
        return nil
    end
    if not sameSignature(prior.signature, signature) then
        return {
            accepted = false,
            code = "request_conflict",
            state = publicState(active, self._wage),
        }
    end
    local response = deepCopy(prior.response)
    response.replayed = true
    response.state = publicState(active, self._wage)
    return response
end

function MarketStockJobController:_replayCompletedRequest(playerId, completed, requestId, signature)
    if completed.requestId ~= requestId then
        return nil
    end
    if not sameSignature(completed.signature, signature) then
        return {
            accepted = false,
            code = "request_conflict",
            state = publicState(nil, self._wage),
        }
    end

    local receipt, openError = self:_recordWage(playerId, completed.operation)
    if openError ~= nil then
        return {
            accepted = false,
            code = "economy_unavailable",
            error = openError,
            state = publicState(nil, self._wage),
        }
    end
    if not committed(receipt) then
        return {
            accepted = false,
            code = "wage_commit_failed",
            economyStatus = receipt and receipt.status or nil,
            economyError = receipt and receipt.error or "unknown",
            state = publicState(nil, self._wage),
        }
    end

    local response = deepCopy(completed.response)
    response.code = "shift_already_completed"
    response.replayed = true
    response.economyStatus = receipt.status
    response.economyState = receipt.state
    if response.result and receipt.state then
        response.result.balance = receipt.state.balance
    end
    return response
end

function MarketStockJobController:submitSort(
    playerId,
    shiftId,
    taskToken,
    choiceId,
    requestId,
    atMarket
)
    if not validPlayerId(playerId)
        or not validIdentifier(shiftId, MAX_SHIFT_ID_LENGTH)
        or not validIdentifier(taskToken, MAX_TASK_TOKEN_LENGTH)
        or not validIdentifier(choiceId, 32)
        or not validIdentifier(requestId, MAX_REQUEST_ID_LENGTH) then
        return { accepted = false, code = "invalid_sort_request" }
    end

    local active = self._active[playerId]
    local signature = {
        shiftId = shiftId,
        taskToken = taskToken,
        choiceId = choiceId,
    }
    if atMarket ~= true then
        return {
            accepted = false,
            code = "not_at_market",
            state = publicState(active, self._wage),
        }
    end

    if active == nil then
        local completed = self._completed[playerId]
        if completed and completed.shiftId == shiftId then
            local replay = self:_replayCompletedRequest(
                playerId,
                completed,
                requestId,
                signature
            )
            if replay then
                return replay
            end
        end
        return {
            accepted = false,
            code = "no_active_shift",
            state = publicState(nil, self._wage),
        }
    end

    local replay = self:_replayActiveRequest(active, requestId, signature)
    if replay then
        return replay
    end
    if active.shiftId ~= shiftId then
        return {
            accepted = false,
            code = "stale_shift",
            state = publicState(active, self._wage),
        }
    end

    local task = active.tasks[active.step]
    if task.token ~= taskToken then
        return {
            accepted = false,
            code = "stale_task",
            state = publicState(active, self._wage),
        }
    end

    local definition = TASK_CATALOG[task.catalogIndex]
    local knownChoice = false
    for _, choice in ipairs(definition.choices) do
        if choice.id == choiceId then
            knownChoice = true
            break
        end
    end
    if not knownChoice then
        local response = {
            accepted = false,
            code = "invalid_choice",
            feedback = "Choose one of the labeled aisles and try again.",
            state = publicState(active, self._wage),
        }
        self:_rememberRequest(active, requestId, signature, response)
        return response
    end

    if choiceId ~= definition.correctChoiceId then
        local response = {
            accepted = true,
            code = "try_again",
            correct = false,
            feedback = "Almost! " .. definition.hint .. " Try another aisle.",
            state = publicState(active, self._wage),
        }
        self:_rememberRequest(active, requestId, signature, response)
        return response
    end

    if active.step < STEPS_PER_SHIFT then
        active.step = active.step + 1
        local response = {
            accepted = true,
            code = "sort_correct",
            correct = true,
            feedback = definition.success,
            state = publicState(active, self._wage),
        }
        self:_rememberRequest(active, requestId, signature, response)
        return response
    end

    local operation = {
        operationId = "job:market:" .. shiftId,
        playerId = playerId,
        delta = self._wage,
        reason = "job:market-stock",
    }
    local receipt, openError = self:_recordWage(playerId, operation)
    if openError ~= nil then
        return {
            accepted = false,
            code = "economy_unavailable",
            error = openError,
            feedback = "Your work is saved in this shift. Try finishing again.",
            state = publicState(active, self._wage),
        }
    end
    if not committed(receipt) then
        return {
            accepted = false,
            code = "wage_commit_failed",
            economyStatus = receipt and receipt.status or nil,
            economyError = receipt and receipt.error or "unknown",
            feedback = "Your work is still here. Tap the aisle again to retry payment.",
            state = publicState(active, self._wage),
        }
    end

    self._active[playerId] = nil
    local response = {
        accepted = true,
        code = receipt.status == "duplicate" and "shift_completed_replay" or "shift_completed",
        correct = true,
        feedback = definition.success,
        state = publicState(nil, self._wage),
        economyStatus = receipt.status,
        economyState = receipt.state,
        result = {
            title = "Stock star!",
            message = "You sorted all three items and helped the Market run smoothly.",
            completedSteps = STEPS_PER_SHIFT,
            wage = self._wage,
            balance = receipt.state and receipt.state.balance or nil,
        },
    }
    self._completed[playerId] = {
        shiftId = shiftId,
        requestId = requestId,
        signature = deepCopy(signature),
        operation = copyOperation(operation),
        response = deepCopy(response),
    }
    return response
end

function MarketStockJobController:leaveShift(playerId)
    if not validPlayerId(playerId) then
        return { accepted = false, code = "invalid_player" }
    end
    if self._active[playerId] == nil then
        return {
            accepted = true,
            code = "no_active_shift",
            state = publicState(nil, self._wage),
        }
    end

    self._active[playerId] = nil
    return {
        accepted = true,
        code = "shift_left",
        feedback = "Shift paused. You can start a fresh one whenever you are ready.",
        state = publicState(nil, self._wage),
    }
end

function MarketStockJobController:clearPlayer(playerId)
    self._active[playerId] = nil
    self._completed[playerId] = nil
end

return MarketStockJobController
