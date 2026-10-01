--!strict
-- Mechanical integration seam between ClassSessionController and ProgressionBinding.
-- Class/Education remains authoritative for class lifecycle; Progression remains authoritative for durable progression.

local Coordinator = {}
Coordinator.__index = Coordinator

local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do
        result[key] = clone(child)
    end
    return result
end

function Coordinator.new(classController, bindingFactory)
    assert(type(classController) == "table", "classController is required")
    assert(type(bindingFactory) == "function", "bindingFactory is required")
    return setmetatable({
        _classController = classController,
        _bindingFactory = bindingFactory,
        _bindings = {},
        _pending = {},
    }, Coordinator)
end

function Coordinator:_binding(playerId, playerKey)
    local cached = self._bindings[playerKey]
    if cached then return cached end
    local binding, err = self._bindingFactory(playerId)
    if not binding then return nil, err end
    self._bindings[playerKey] = binding
    return binding
end

function Coordinator:getPending(playerKey)
    local pending = self._pending[playerKey]
    return pending and clone(pending) or nil
end

function Coordinator:getPlayerSnapshot(playerKey)
    local snapshot = self._classController:getPlayerSnapshot(playerKey)
    local pending = self._pending[playerKey]
    snapshot.progressionPending = pending ~= nil
    snapshot.pendingClassKey = pending and pending.classKey or nil
    return snapshot
end

function Coordinator:enter(playerKey, classKey, subject, initialDifficulty)
    local pending = self._pending[playerKey]
    if pending then
        return {
            accepted = false,
            code = "progression_pending",
            classKey = pending.classKey,
            returnToFreeRoam = false,
        }, "progression_pending"
    end
    return self._classController:enter(playerKey, classKey, subject, initialDifficulty)
end

function Coordinator:submit(playerId, playerKey, classKey, activityId, submissionId, choiceIndex)
    local pending = self._pending[playerKey]
    if pending and (pending.classKey ~= classKey or pending.submissionId ~= submissionId) then
        return {
            accepted = false,
            code = "progression_pending",
            classKey = pending.classKey,
            returnToFreeRoam = false,
        }, "progression_pending"
    end

    local response, classStatus = self._classController:submit(
        playerKey,
        classKey,
        activityId,
        submissionId,
        choiceIndex
    )

    local completionSignal = response.classCompleted == true
        or response.completionAlreadyRecorded == true
    if not completionSignal then
        return response, classStatus
    end

    local binding, bindingError = self:_binding(playerId, playerKey)
    if not binding then
        self._pending[playerKey] = {
            classKey = classKey,
            submissionId = submissionId,
        }
        response.accepted = false
        response.classCompleted = false
        response.progressionCommitted = false
        response.progressionError = tostring(bindingError or "binding_unavailable")
        response.code = "progression_commit_failed"
        response.returnToFreeRoam = false
        return response, "progression_pending"
    end

    local progression = binding:consume(playerId, classKey, submissionId, response)
    if not progression.committed then
        self._pending[playerKey] = {
            classKey = classKey,
            submissionId = submissionId,
        }
        response.accepted = false
        response.classCompleted = false
        response.progressionCommitted = false
        response.progressionError = progression.progressionError
        response.code = "progression_commit_failed"
        response.returnToFreeRoam = false
        return response, "progression_pending"
    end

    self._pending[playerKey] = nil
    response.progressionCommitted = true
    response.progressionStatus = progression.progressionStatus
    response.progressionState = progression.state
    response.returnToFreeRoam = progression.returnToFreeRoam
    return response, classStatus
end

function Coordinator:leave(playerKey, reason)
    local pending = self._pending[playerKey]
    if pending then
        return {
            accepted = false,
            code = "progression_pending",
            classKey = pending.classKey,
            returnToFreeRoam = false,
        }, "progression_pending"
    end
    return self._classController:leave(playerKey, reason)
end

return Coordinator
