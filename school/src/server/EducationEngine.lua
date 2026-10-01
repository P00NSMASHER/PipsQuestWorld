--!strict
-- Standalone, server-authoritative education engine.
-- This module intentionally owns no Roblox services, remotes, schedule state,
-- world state, scoring state, or persistence.

local EducationEngine = {}
EducationEngine.__index = EducationEngine

local DEFAULT_MAX_ATTEMPTS = 2
local DEFAULT_MAX_DIFFICULTY_JUMP = 1

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

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function normalizePrompt(prompt)
    local compact = string.gsub(prompt, "%s+", " ")
    compact = string.gsub(compact, "^%s+", "")
    compact = string.gsub(compact, "%s+$", "")
    return string.lower(compact)
end

local function assertActivity(activity, ids, prompts)
    assert(type(activity) == "table", "activity must be a table")
    assert(type(activity.id) == "string" and activity.id ~= "", "activity.id must be a non-empty string")
    assert(not ids[activity.id], "duplicate activity id: " .. activity.id)
    ids[activity.id] = true

    assert(type(activity.subject) == "string" and activity.subject ~= "", "activity.subject must be a non-empty string")
    assert(isInteger(activity.difficulty) and activity.difficulty >= 1 and activity.difficulty <= 5, "activity.difficulty must be an integer from 1 to 5")
    assert(type(activity.prompt) == "string" and activity.prompt ~= "", "activity.prompt must be a non-empty string")

    local promptKey = normalizePrompt(activity.prompt)
    assert(not prompts[promptKey], "duplicate activity prompt: " .. activity.id)
    prompts[promptKey] = true

    assert(type(activity.choices) == "table" and #activity.choices >= 2, "activity.choices must contain at least two choices")
    for index, choice in ipairs(activity.choices) do
        assert(type(choice) == "string" and choice ~= "", "choice " .. tostring(index) .. " must be a non-empty string")
    end

    assert(isInteger(activity.correctIndex), "activity.correctIndex must be an integer")
    assert(activity.correctIndex >= 1 and activity.correctIndex <= #activity.choices, "activity.correctIndex must point to a choice")
    assert(type(activity.hint) == "string" and activity.hint ~= "", "activity.hint must be a non-empty string")
    assert(type(activity.explanation) == "string" and activity.explanation ~= "", "activity.explanation must be a non-empty string")

    if activity.misconceptions ~= nil then
        assert(type(activity.misconceptions) == "table", "activity.misconceptions must be a table when provided")
        for key, message in pairs(activity.misconceptions) do
            assert(isInteger(key) and key >= 1 and key <= #activity.choices, "misconception keys must be valid choice indexes")
            assert(key ~= activity.correctIndex, "correct choice must not carry misconception feedback")
            assert(type(message) == "string" and message ~= "", "misconception feedback must be a non-empty string")
        end
    end
end

local function safeActivity(activity)
    return {
        id = activity.id,
        subject = activity.subject,
        difficulty = activity.difficulty,
        prompt = activity.prompt,
        choices = clone(activity.choices),
    }
end

local function safeHistoryEntry(entry)
    return {
        activityId = entry.activityId,
        subject = entry.subject,
        difficulty = entry.difficulty,
        attempts = entry.attempts,
        correct = entry.correct,
        independent = entry.independent,
    }
end

local function copyResponse(response)
    return clone(response)
end

local function findSession(self, sessionId)
    assert(type(sessionId) == "string" and sessionId ~= "", "sessionId must be a non-empty string")
    local session = self._sessions[sessionId]
    assert(session ~= nil, "unknown session: " .. sessionId)
    return session
end

function EducationEngine.new(catalog, options)
    assert(type(catalog) == "table" and #catalog > 0, "catalog must contain at least one activity")
    options = options or {}

    local maxAttempts = options.maxAttempts or DEFAULT_MAX_ATTEMPTS
    local maxDifficultyJump = options.maxDifficultyJump or DEFAULT_MAX_DIFFICULTY_JUMP
    assert(isInteger(maxAttempts) and maxAttempts >= 1, "maxAttempts must be a positive integer")
    assert(isInteger(maxDifficultyJump) and maxDifficultyJump >= 0, "maxDifficultyJump must be a non-negative integer")

    local ids = {}
    local prompts = {}
    local subjects = {}

    for _, sourceActivity in ipairs(catalog) do
        assertActivity(sourceActivity, ids, prompts)
        local activity = clone(sourceActivity)
        local subjectBank = subjects[activity.subject]
        if not subjectBank then
            subjectBank = {}
            subjects[activity.subject] = subjectBank
        end
        table.insert(subjectBank, activity)
    end

    for _, subjectBank in pairs(subjects) do
        table.sort(subjectBank, function(left, right)
            if left.difficulty == right.difficulty then
                return left.id < right.id
            end
            return left.difficulty < right.difficulty
        end)
    end

    return setmetatable({
        _subjects = subjects,
        _sessions = {},
        _maxAttempts = maxAttempts,
        _maxDifficultyJump = maxDifficultyJump,
    }, EducationEngine)
end

function EducationEngine:beginSession(sessionId, subject, initialDifficulty)
    assert(type(sessionId) == "string" and sessionId ~= "", "sessionId must be a non-empty string")
    assert(type(subject) == "string" and subject ~= "", "subject must be a non-empty string")
    assert(self._subjects[subject] ~= nil, "unknown subject: " .. subject)

    local existing = self._sessions[sessionId]
    if existing then
        assert(existing.subject == subject, "session already exists for another subject")
        return self:getSessionSnapshot(sessionId)
    end

    local subjectBank = self._subjects[subject]
    local floorDifficulty = subjectBank[1].difficulty
    local target = initialDifficulty or floorDifficulty
    assert(isInteger(target) and target >= 1 and target <= 5, "initialDifficulty must be an integer from 1 to 5")

    self._sessions[sessionId] = {
        id = sessionId,
        subject = subject,
        seen = {},
        receipts = {},
        history = {},
        active = nil,
        difficultyTarget = target,
        lastDifficulty = nil,
        closed = false,
    }

    return self:getSessionSnapshot(sessionId)
end

function EducationEngine:nextActivity(sessionId)
    local session = findSession(self, sessionId)
    if session.closed then
        return nil, "closed"
    end

    if session.active then
        return safeActivity(session.active.activity), "active"
    end

    local subjectBank = self._subjects[session.subject]
    local candidates = {}
    for _, activity in ipairs(subjectBank) do
        if not session.seen[activity.id] then
            local jumpAllowed = true
            if session.lastDifficulty ~= nil then
                jumpAllowed = math.abs(activity.difficulty - session.lastDifficulty) <= self._maxDifficultyJump
            end

            if jumpAllowed then
                table.insert(candidates, activity)
            end
        end
    end

    if #candidates == 0 then
        for _, activity in ipairs(subjectBank) do
            if not session.seen[activity.id] then
                return nil, "difficulty_gap"
            end
        end
        return nil, "exhausted"
    end

    table.sort(candidates, function(left, right)
        local leftDistance = math.abs(left.difficulty - session.difficultyTarget)
        local rightDistance = math.abs(right.difficulty - session.difficultyTarget)
        if leftDistance ~= rightDistance then
            return leftDistance < rightDistance
        end
        if left.difficulty ~= right.difficulty then
            return left.difficulty < right.difficulty
        end
        return left.id < right.id
    end)

    local selected = candidates[1]
    session.seen[selected.id] = true
    session.active = {
        activity = selected,
        attempts = 0,
    }

    return safeActivity(selected), "new"
end

function EducationEngine:submit(sessionId, activityId, submissionId, choiceIndex)
    local session = findSession(self, sessionId)
    assert(type(activityId) == "string" and activityId ~= "", "activityId must be a non-empty string")
    assert(type(submissionId) == "string" and submissionId ~= "", "submissionId must be a non-empty string")

    local receipt = session.receipts[submissionId]
    if receipt then
        if receipt.activityId ~= activityId or receipt.choiceIndex ~= choiceIndex then
            return {
                accepted = false,
                code = "idempotency_conflict",
                duplicate = true,
            }, "duplicate"
        end
        return copyResponse(receipt.response), "duplicate"
    end

    if session.closed then
        return {
            accepted = false,
            code = "session_closed",
        }, "rejected"
    end

    local active = session.active
    if not active or active.activity.id ~= activityId then
        return {
            accepted = false,
            code = "activity_not_active",
        }, "rejected"
    end

    local activity = active.activity
    if not isInteger(choiceIndex) or choiceIndex < 1 or choiceIndex > #activity.choices then
        return {
            accepted = false,
            code = "invalid_choice",
        }, "rejected"
    end

    active.attempts = active.attempts + 1
    local correct = choiceIndex == activity.correctIndex
    local completed = correct or active.attempts >= self._maxAttempts

    local response = {
        accepted = true,
        correct = correct,
        completed = completed,
        attempts = active.attempts,
    }

    if correct then
        response.feedback = activity.explanation
    else
        local misconception = activity.misconceptions and activity.misconceptions[choiceIndex] or nil
        response.feedback = misconception or activity.hint
        response.hint = activity.hint
        if completed then
            response.explanation = activity.explanation
        end
    end

    if completed then
        local independent = correct and active.attempts == 1
        table.insert(session.history, {
            activityId = activity.id,
            subject = activity.subject,
            difficulty = activity.difficulty,
            attempts = active.attempts,
            correct = correct,
            independent = independent,
        })

        session.lastDifficulty = activity.difficulty

        if independent then
            session.difficultyTarget = math.min(5, session.difficultyTarget + 1)
        elseif not correct then
            session.difficultyTarget = math.max(1, session.difficultyTarget - 1)
        end

        session.active = nil
    end

    session.receipts[submissionId] = {
        activityId = activityId,
        choiceIndex = choiceIndex,
        response = copyResponse(response),
    }

    return copyResponse(response), "accepted"
end

function EducationEngine:getSessionSnapshot(sessionId)
    local session = findSession(self, sessionId)
    local history = {}
    for index, entry in ipairs(session.history) do
        history[index] = safeHistoryEntry(entry)
    end

    return {
        id = session.id,
        subject = session.subject,
        difficultyTarget = session.difficultyTarget,
        completedCount = #session.history,
        closed = session.closed,
        active = session.active and safeActivity(session.active.activity) or nil,
        activeAttempts = session.active and session.active.attempts or 0,
        history = history,
    }
end

function EducationEngine:closeSession(sessionId)
    local session = findSession(self, sessionId)
    session.closed = true
    session.active = nil
    return self:getSessionSnapshot(sessionId)
end

return EducationEngine
