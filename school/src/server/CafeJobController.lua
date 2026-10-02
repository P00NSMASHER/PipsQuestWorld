--!strict
-- Canonical Pip High cafe-job interaction state.
-- Owns cafe shift/task lifecycle only. Money remains owned by EconomyRepository.

local CafeJobController = {}
CafeJobController.__index = CafeJobController

local JOB_ID = "cafe"
local TASK_ID = "serve_order"
local DEFAULT_WAGE = 25

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function validPlayerId(playerId)
    return isInteger(playerId) and playerId > 0
end

local function copyOperation(operation)
    return {
        operationId = operation.operationId,
        playerId = operation.playerId,
        delta = operation.delta,
        reason = operation.reason,
    }
end

local function publicState(active, wage)
    if active == nil then
        return {
            active = false,
            jobId = JOB_ID,
            taskId = TASK_ID,
            taskLabel = "Serve one cafe order",
            wage = wage,
        }
    end

    return {
        active = true,
        jobId = JOB_ID,
        shiftId = active.shiftId,
        taskId = TASK_ID,
        taskLabel = "Serve one cafe order",
        wage = wage,
    }
end

function CafeJobController.new(options)
    options = options or {}
    assert(type(options.repositoryFactory) == "function", "repositoryFactory is required")
    assert(type(options.shiftIdFactory) == "function", "shiftIdFactory is required")

    local wage = options.wage or DEFAULT_WAGE
    assert(isInteger(wage) and wage > 0, "wage must be a positive integer")

    return setmetatable({
        _repositoryFactory = options.repositoryFactory,
        _shiftIdFactory = options.shiftIdFactory,
        _wage = wage,
        _active = {},
        _completed = {},
    }, CafeJobController)
end

function CafeJobController:getState(playerId)
    if not validPlayerId(playerId) then
        return {
            active = false,
            available = false,
            code = "invalid_player",
        }
    end
    return publicState(self._active[playerId], self._wage)
end

function CafeJobController:startShift(playerId, atCafe)
    if not validPlayerId(playerId) then
        return { accepted = false, code = "invalid_player" }
    end
    if atCafe ~= true then
        return { accepted = false, code = "not_at_cafe" }
    end

    local active = self._active[playerId]
    if active ~= nil then
        local state = publicState(active, self._wage)
        state.accepted = true
        state.code = "shift_already_active"
        return state
    end

    local shiftId = self._shiftIdFactory(playerId)
    if type(shiftId) ~= "string" or shiftId == "" then
        return { accepted = false, code = "shift_id_unavailable" }
    end

    active = { shiftId = shiftId }
    self._active[playerId] = active

    local state = publicState(active, self._wage)
    state.accepted = true
    state.code = "shift_started"
    return state
end

local function committed(receipt)
    return type(receipt) == "table"
        and receipt.durable == true
        and (receipt.status == "applied" or receipt.status == "duplicate")
end

function CafeJobController:_recordWage(playerId, operation)
    local opened, repository, openError = pcall(self._repositoryFactory, playerId)
    if not opened then
        return nil, "repository_factory_failed"
    end
    if repository == nil or type(repository.record) ~= "function" then
        return nil, tostring(openError or "repository_unavailable")
    end

    local recorded, receipt = pcall(
        repository.record,
        repository,
        copyOperation(operation)
    )
    if not recorded then
        return nil, "repository_record_failed"
    end
    if not committed(receipt) then
        return receipt, nil
    end
    return receipt, nil
end

function CafeJobController:completeTask(playerId, shiftId, taskId, atCafe)
    if not validPlayerId(playerId)
        or type(shiftId) ~= "string"
        or shiftId == ""
        or type(taskId) ~= "string"
        or taskId == "" then
        return { accepted = false, code = "invalid_completion" }
    end
    if taskId ~= TASK_ID then
        return { accepted = false, code = "invalid_task" }
    end
    if atCafe ~= true then
        return { accepted = false, code = "not_at_cafe" }
    end

    local active = self._active[playerId]
    if active == nil then
        local completedState = self._completed[playerId]
        if completedState == nil or completedState.shiftId ~= shiftId then
            return { accepted = false, code = "no_active_shift" }
        end

        local replayReceipt, replayOpenError = self:_recordWage(playerId, completedState.operation)
        if replayOpenError ~= nil then
            return {
                accepted = false,
                code = "economy_unavailable",
                error = replayOpenError,
            }
        end
        if not committed(replayReceipt) then
            return {
                accepted = false,
                code = "wage_commit_failed",
                economyStatus = replayReceipt and replayReceipt.status or nil,
                economyError = replayReceipt and replayReceipt.error or "unknown",
            }
        end

        return {
            accepted = true,
            code = "shift_already_completed",
            replayed = true,
            returnToFreeRoam = true,
            shiftId = shiftId,
            taskId = TASK_ID,
            wage = self._wage,
            economyStatus = replayReceipt.status,
            economyState = replayReceipt.state,
        }
    end

    if active.shiftId ~= shiftId then
        return { accepted = false, code = "stale_shift" }
    end

    local operation = {
        operationId = "job:cafe:" .. shiftId,
        playerId = playerId,
        delta = self._wage,
        reason = "job:cafe",
    }

    local receipt, openError = self:_recordWage(playerId, operation)
    if openError ~= nil then
        return {
            accepted = false,
            code = "economy_unavailable",
            error = openError,
            shiftId = shiftId,
        }
    end
    if not committed(receipt) then
        return {
            accepted = false,
            code = "wage_commit_failed",
            economyStatus = receipt and receipt.status or nil,
            economyError = receipt and receipt.error or "unknown",
            shiftId = shiftId,
        }
    end

    self._active[playerId] = nil
    self._completed[playerId] = {
        shiftId = shiftId,
        operation = copyOperation(operation),
    }

    return {
        accepted = true,
        code = receipt.status == "duplicate" and "shift_completed_replay" or "shift_completed",
        replayed = receipt.status == "duplicate",
        returnToFreeRoam = true,
        shiftId = shiftId,
        taskId = TASK_ID,
        wage = self._wage,
        economyStatus = receipt.status,
        economyState = receipt.state,
    }
end

function CafeJobController:leaveShift(playerId)
    if not validPlayerId(playerId) then
        return { accepted = false, code = "invalid_player" }
    end
    if self._active[playerId] == nil then
        return { accepted = true, code = "no_active_shift", active = false }
    end

    self._active[playerId] = nil
    return {
        accepted = true,
        code = "shift_left",
        active = false,
        returnToFreeRoam = true,
    }
end

function CafeJobController:clearPlayer(playerId)
    self._active[playerId] = nil
    self._completed[playerId] = nil
end

return CafeJobController
