--!strict
-- Pure class-session coordinator. Owns ephemeral class/activity state only.
-- It does not own the school clock, room geometry, UI, grades, rewards, or persistence.

local ClassSessionController = {}
ClassSessionController.__index = ClassSessionController

local function clone(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, child in pairs(value) do
        copy[clone(key)] = clone(child)
    end
    return copy
end

local function assertKey(value, name)
    assert(type(value) == "string" and value ~= "", name .. " must be a non-empty string")
end

local function stateFor(self, playerKey)
    local state = self._players[playerKey]
    if not state then
        state = {
            active = nil,
            completed = {},
            completionCount = 0,
            receipts = {},
            nextSessionOrdinal = 0,
        }
        self._players[playerKey] = state
    end
    return state
end

function ClassSessionController.new(engine)
    assert(type(engine) == "table", "engine is required")
    return setmetatable({
        _engine = engine,
        _players = {},
    }, ClassSessionController)
end

function ClassSessionController:getPlayerSnapshot(playerKey)
    assertKey(playerKey, "playerKey")
    local state = stateFor(self, playerKey)
    local active = nil
    if state.active then
        active = {
            classKey = state.active.classKey,
            subject = state.active.subject,
            activity = clone(state.active.activity),
        }
    end
    return {
        active = active,
        completionCount = state.completionCount,
    }
end

function ClassSessionController:enter(playerKey, classKey, subject, initialDifficulty)
    assertKey(playerKey, "playerKey")
    assertKey(classKey, "classKey")
    assertKey(subject, "subject")

    local state = stateFor(self, playerKey)
    if state.completed[classKey] then
        return {
            accepted = false,
            code = "already_completed",
            returnToFreeRoam = true,
        }, "rejected"
    end

    if state.active then
        if state.active.classKey == classKey then
            return {
                accepted = true,
                code = "already_active",
                classKey = classKey,
                activity = clone(state.active.activity),
            }, "active"
        end
        return {
            accepted = false,
            code = "another_class_active",
        }, "rejected"
    end

    -- A player may leave an incomplete class and re-enter while the same
    -- Foundation period is still active. Closed engine sessions are immutable,
    -- so every fresh class entry needs its own deterministic attempt id.
    state.nextSessionOrdinal = state.nextSessionOrdinal + 1
    local sessionId = playerKey .. "|" .. classKey .. "|" .. tostring(state.nextSessionOrdinal)
    self._engine:beginSession(sessionId, subject, initialDifficulty)
    local activity, activityStatus = self._engine:nextActivity(sessionId)
    if not activity then
        self._engine:closeSession(sessionId)
        return {
            accepted = false,
            code = "no_activity",
            detail = activityStatus,
            returnToFreeRoam = true,
        }, "rejected"
    end

    state.active = {
        classKey = classKey,
        subject = subject,
        sessionId = sessionId,
        activity = activity,
    }

    return {
        accepted = true,
        code = "entered",
        classKey = classKey,
        activity = clone(activity),
    }, "entered"
end

function ClassSessionController:submit(playerKey, classKey, activityId, submissionId, choiceIndex)
    assertKey(playerKey, "playerKey")
    if type(classKey) ~= "string" or classKey == ""
        or type(activityId) ~= "string" or activityId == ""
        or type(submissionId) ~= "string" or submissionId == "" then
        return {
            accepted = false,
            code = "invalid_submission",
        }, "rejected"
    end

    local state = stateFor(self, playerKey)
    local previous = state.receipts[submissionId]
    if previous then
        local incompleteReceipt = previous.response.classCompleted ~= true
        local attemptIsActive = state.active ~= nil and previous.sessionId == state.active.sessionId
        if previous.classKey ~= classKey
            or previous.activityId ~= activityId
            or previous.choiceIndex ~= choiceIndex
            or (incompleteReceipt and not attemptIsActive) then
            return {
                accepted = false,
                code = "idempotency_conflict",
                duplicate = true,
                returnToFreeRoam = state.active == nil,
            }, "duplicate"
        end
        local replay = clone(previous.response)
        replay.duplicate = true
        if replay.classCompleted then
            replay.classCompleted = false
            replay.completionAlreadyRecorded = true
        end
        return replay, "duplicate"
    end

    if state.completed[classKey] then
        return {
            accepted = false,
            code = "late_submission",
            returnToFreeRoam = true,
        }, "rejected"
    end

    local active = state.active
    if not active or active.classKey ~= classKey or active.activity.id ~= activityId then
        return {
            accepted = false,
            code = "class_not_active",
            returnToFreeRoam = active == nil,
        }, "rejected"
    end

    local engineResponse, engineStatus = self._engine:submit(
        active.sessionId,
        activityId,
        submissionId,
        choiceIndex
    )

    local response = clone(engineResponse)
    response.classKey = classKey
    response.classCompleted = false
    response.returnToFreeRoam = false

    if response.accepted and response.completed then
        if not state.completed[classKey] then
            state.completed[classKey] = true
            state.completionCount = state.completionCount + 1
            response.classCompleted = true
        end
        response.returnToFreeRoam = true
        self._engine:closeSession(active.sessionId)
        state.active = nil
    end

    if response.accepted then
        state.receipts[submissionId] = {
            classKey = classKey,
            activityId = activityId,
            sessionId = active.sessionId,
            choiceIndex = choiceIndex,
            response = clone(response),
        }
    end

    return response, engineStatus
end

function ClassSessionController:leave(playerKey, reason)
    assertKey(playerKey, "playerKey")
    local state = stateFor(self, playerKey)
    if not state.active then
        return {
            accepted = true,
            code = "already_free_roam",
            returnToFreeRoam = true,
        }, "noop"
    end

    local active = state.active
    self._engine:closeSession(active.sessionId)
    state.active = nil
    return {
        accepted = true,
        code = "left_class",
        reason = reason or "requested",
        classKey = active.classKey,
        returnToFreeRoam = true,
    }, "left"
end

return ClassSessionController
