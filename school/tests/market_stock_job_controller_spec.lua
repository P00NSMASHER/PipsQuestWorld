local Controller = assert(loadfile("school/src/server/MarketStockJobController.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function truthy(value, label)
    if not value then
        error(label or "expected truthy value", 2)
    end
end

local function assertTaskHidesAnswer(task)
    local function visit(value, path)
        if type(value) ~= "table" then return end
        for key, child in pairs(value) do
            local keyText = tostring(key):lower()
            if keyText:find("correct", 1, true) or keyText:find("answer", 1, true) then
                error("public task exposed answer field at " .. path .. "." .. tostring(key), 2)
            end
            visit(child, path .. "." .. tostring(key))
        end
    end
    visit(task, "task")
end

local function newEconomy()
    local byPlayer = {}
    local failNext = false
    local calls = 0

    local function repositoryFactory(playerId)
        byPlayer[playerId] = byPlayer[playerId] or {
            balance = 0,
            operations = {},
            saves = 0,
        }
        local state = byPlayer[playerId]
        return {
            record = function(_, operation)
                calls = calls + 1
                if failNext then
                    failNext = false
                    return {
                        status = "rejected",
                        durable = false,
                        error = "injected",
                    }
                end
                local prior = state.operations[operation.operationId]
                if prior then
                    if prior.delta == operation.delta and prior.reason == operation.reason then
                        return {
                            status = "duplicate",
                            durable = true,
                            state = {
                                balance = state.balance,
                                operationCount = state.saves,
                            },
                        }
                    end
                    return {
                        status = "conflict",
                        durable = false,
                        error = "OPERATION_ID_CONFLICT",
                    }
                end
                state.operations[operation.operationId] = {
                    delta = operation.delta,
                    reason = operation.reason,
                }
                state.balance = state.balance + operation.delta
                state.saves = state.saves + 1
                return {
                    status = "applied",
                    durable = true,
                    state = {
                        balance = state.balance,
                        operationCount = state.saves,
                    },
                }
            end,
        }, nil
    end

    return {
        repositoryFactory = repositoryFactory,
        failNext = function() failNext = true end,
        balance = function(playerId)
            local state = byPlayer[playerId]
            return state and state.balance or 0
        end,
        saves = function(playerId)
            local state = byPlayer[playerId]
            return state and state.saves or 0
        end,
        calls = function() return calls end,
    }
end

local correctByItem = {
    ["Crisp apples"] = "produce",
    ["Cold milk"] = "chilled",
    ["Study notebooks"] = "school_supplies",
    ["Fresh bread"] = "bakery",
    ["Breakfast cereal"] = "pantry",
    ["Dish soap"] = "home_care",
}

local function correctChoice(state)
    return assert(correctByItem[state.task.itemLabel], "test mapping missing current item")
end

local function wrongChoice(state)
    local correct = correctChoice(state)
    for _, choice in ipairs(state.task.choices) do
        if choice.id ~= correct then
            return choice.id
        end
    end
    error("task did not offer a wrong choice", 2)
end

local ids = { "shift-a", "shift-b", "shift-c", "shift-d" }
local nextId = 0
local economy = newEconomy()
local controller = Controller.new({
    wage = 45,
    repositoryFactory = economy.repositoryFactory,
    shiftIdFactory = function()
        nextId = nextId + 1
        return ids[nextId]
    end,
    taskTokenFactory = function(_playerId, shiftId, step)
        return shiftId .. ":task-" .. tostring(step)
    end,
    randomInteger = function(_minimum, maximum)
        return maximum
    end,
})

local initial = controller:getState(101)
eq(initial.active, false, "initial state active")
eq(initial.totalSteps, 3, "initial total steps")
eq(initial.wage, 45, "initial wage")

local away = controller:startShift(101, false)
eq(away.accepted, false, "away start accepted")
eq(away.code, "not_at_market", "away start code")

local started = controller:startShift(101, true)
eq(started.accepted, true, "start rejected")
eq(started.code, "shift_started", "start code")
eq(started.state.shiftId, "shift-a", "shift id")
eq(started.state.completedSteps, 0, "start progress")
eq(started.state.task.itemLabel, "Crisp apples", "deterministic first task")
eq(#started.state.task.choices, 3, "choice count")
assertTaskHidesAnswer(started.state.task)

local duplicateStart = controller:startShift(101, true)
eq(duplicateStart.code, "shift_already_active", "duplicate start code")
eq(duplicateStart.state.task.token, started.state.task.token, "duplicate changed task")

local tooLongRequest = controller:submitSort(
    101,
    "shift-a",
    started.state.task.token,
    "produce",
    string.rep("x", 65),
    true
)
eq(tooLongRequest.code, "invalid_sort_request", "long request id accepted")

local malformedRequest = controller:submitSort(
    101,
    "shift-a",
    started.state.task.token,
    "produce",
    "contains spaces",
    true
)
eq(malformedRequest.code, "invalid_sort_request", "malformed request id accepted")

local offsite = controller:submitSort(
    101,
    "shift-a",
    started.state.task.token,
    correctChoice(started.state),
    "request-offsite",
    false
)
eq(offsite.code, "not_at_market", "offsite answer code")
eq(offsite.state.completedSteps, 0, "offsite answer advanced")

local firstWrongChoice = wrongChoice(started.state)
local wrong = controller:submitSort(
    101,
    "shift-a",
    started.state.task.token,
    firstWrongChoice,
    "request-wrong",
    true
)
eq(wrong.accepted, true, "wrong answer rejected as a request")
eq(wrong.code, "try_again", "wrong answer code")
eq(wrong.correct, false, "wrong answer flag")
eq(wrong.state.completedSteps, 0, "wrong answer advanced")
truthy(wrong.feedback:find("Almost!", 1, true), "wrong answer missing positive feedback")
eq(economy.calls(), 0, "wrong answer touched economy")

local wrongReplay = controller:submitSort(
    101,
    "shift-a",
    started.state.task.token,
    firstWrongChoice,
    "request-wrong",
    true
)
eq(wrongReplay.replayed, true, "wrong replay not marked")
eq(wrongReplay.state.completedSteps, 0, "wrong replay advanced")

local requestConflict = controller:submitSort(
    101,
    "shift-a",
    started.state.task.token,
    correctChoice(started.state),
    "request-wrong",
    true
)
eq(requestConflict.code, "request_conflict", "request id mutation accepted")

local firstCorrectId = correctChoice(started.state)
local firstCorrect = controller:submitSort(
    101,
    "shift-a",
    started.state.task.token,
    firstCorrectId,
    "request-one",
    true
)
eq(firstCorrect.code, "sort_correct", "first correct code")
eq(firstCorrect.state.completedSteps, 1, "first correct progress")
eq(firstCorrect.state.task.itemLabel, "Cold milk", "second task")
assertTaskHidesAnswer(firstCorrect.state.task)

local firstReplay = controller:submitSort(
    101,
    "shift-a",
    started.state.task.token,
    firstCorrectId,
    "request-one",
    true
)
eq(firstReplay.replayed, true, "correct replay not marked")
eq(firstReplay.state.completedSteps, 1, "correct replay advanced twice")
eq(firstReplay.state.task.itemLabel, "Cold milk", "correct replay regressed task")

local staleTask = controller:submitSort(
    101,
    "shift-a",
    started.state.task.token,
    firstCorrectId,
    "request-stale-task",
    true
)
eq(staleTask.code, "stale_task", "stale task accepted")

local secondState = firstCorrect.state
local secondCorrect = controller:submitSort(
    101,
    "shift-a",
    secondState.task.token,
    correctChoice(secondState),
    "request-two",
    true
)
eq(secondCorrect.code, "sort_correct", "second correct code")
eq(secondCorrect.state.completedSteps, 2, "second correct progress")
eq(secondCorrect.state.task.itemLabel, "Study notebooks", "third task")

economy.failNext()
local thirdState = secondCorrect.state
local failedPay = controller:submitSort(
    101,
    "shift-a",
    thirdState.task.token,
    correctChoice(thirdState),
    "request-three",
    true
)
eq(failedPay.accepted, false, "failed pay accepted")
eq(failedPay.code, "wage_commit_failed", "failed pay code")
eq(failedPay.state.active, true, "failed pay lost shift")
eq(failedPay.state.completedSteps, 2, "failed pay changed progress")
eq(economy.balance(101), 0, "failed pay changed balance")

local completed = controller:submitSort(
    101,
    "shift-a",
    thirdState.task.token,
    correctChoice(thirdState),
    "request-three",
    true
)
eq(completed.accepted, true, "retried completion rejected")
eq(completed.code, "shift_completed", "completion code")
eq(completed.result.completedSteps, 3, "result step count")
eq(completed.result.wage, 45, "result wage")
eq(completed.result.balance, 45, "result balance")
eq(economy.balance(101), 45, "economy balance")
eq(economy.saves(101), 1, "economy save count")
eq(controller:getState(101).active, false, "completed shift still active")

local completionReplay = controller:submitSort(
    101,
    "shift-a",
    thirdState.task.token,
    correctChoice(thirdState),
    "request-three",
    true
)
eq(completionReplay.accepted, true, "completion replay rejected")
eq(completionReplay.code, "shift_already_completed", "completion replay code")
eq(completionReplay.replayed, true, "completion replay flag")
eq(completionReplay.economyStatus, "duplicate", "completion replay economy status")
eq(economy.balance(101), 45, "completion replay paid twice")
eq(economy.saves(101), 1, "completion replay saved twice")

local completedConflict = controller:submitSort(
    101,
    "shift-a",
    thirdState.task.token,
    wrongChoice(thirdState),
    "request-three",
    true
)
eq(completedConflict.code, "request_conflict", "completed request mutation accepted")
eq(economy.balance(101), 45, "completed conflict changed balance")

local secondShift = controller:startShift(101, true)
eq(secondShift.state.shiftId, "shift-b", "second shift id")
local left = controller:leaveShift(101)
eq(left.accepted, true, "leave rejected")
eq(left.code, "shift_left", "leave code")
eq(left.state.active, false, "leave state active")

local thirdShift = controller:startShift(101, true)
eq(thirdShift.state.shiftId, "shift-c", "third shift id")
controller:clearPlayer(101)
eq(controller:getState(101).active, false, "clear player retained session")
local clearedReplay = controller:submitSort(
    101,
    "shift-c",
    thirdShift.state.task.token,
    correctChoice(thirdShift.state),
    "request-after-clear",
    true
)
eq(clearedReplay.code, "no_active_shift", "clear player retained completion")

local alternateEconomy = newEconomy()
local alternate = Controller.new({
    repositoryFactory = alternateEconomy.repositoryFactory,
    shiftIdFactory = function() return "alternate-shift" end,
    taskTokenFactory = function(_playerId, _shiftId, step)
        return "alternate-task-" .. tostring(step)
    end,
    randomInteger = function(minimum, _maximum)
        return minimum
    end,
})
local alternateStart = alternate:startShift(202, true)
truthy(
    alternateStart.state.task.itemLabel ~= "Crisp apples",
    "randomized sequence did not change with alternate RNG"
)

local boundedEconomy = newEconomy()
local bounded = Controller.new({
    repositoryFactory = boundedEconomy.repositoryFactory,
    shiftIdFactory = function() return "bounded-shift" end,
    taskTokenFactory = function(_playerId, _shiftId, step)
        return "bounded-task-" .. tostring(step)
    end,
    randomInteger = function(_minimum, maximum) return maximum end,
})
local boundedStart = bounded:startShift(303, true)
local boundedWrong = wrongChoice(boundedStart.state)
for index = 1, 25 do
    local response = bounded:submitSort(
        303,
        "bounded-shift",
        boundedStart.state.task.token,
        boundedWrong,
        "bounded-request-" .. tostring(index),
        true
    )
    eq(response.code, "try_again", "bounded request code " .. tostring(index))
end
local evictedReplay = bounded:submitSort(
    303,
    "bounded-shift",
    boundedStart.state.task.token,
    boundedWrong,
    "bounded-request-1",
    true
)
eq(evictedReplay.replayed, nil, "old request remained in bounded cache")
eq(evictedReplay.state.completedSteps, 0, "evicted retry advanced")

local invalidTokenController = Controller.new({
    repositoryFactory = boundedEconomy.repositoryFactory,
    shiftIdFactory = function() return "valid-shift" end,
    taskTokenFactory = function() return "token with spaces" end,
    randomInteger = function(_minimum, maximum) return maximum end,
})
local invalidTokens = invalidTokenController:startShift(404, true)
eq(invalidTokens.accepted, false, "invalid task token shift accepted")
eq(invalidTokens.code, "task_sequence_unavailable", "invalid task token code")

print("HIGH_SCHOOL_MARKET_STOCK_JOB_CONTROLLER_PASS")
