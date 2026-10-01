--!strict
-- Converts only server-authoritative class completion results into durable progression.
-- The binding deliberately does not own class lifecycle, answers, schedule state, or UI.

local ProgressionBinding = {}
ProgressionBinding.__index = ProgressionBinding

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function pointsFor(response)
    if response.correct == true then
        if response.attempts == 1 then
            return 25
        end
        return 15
    end
    return 10
end

function ProgressionBinding.new(repository)
    assert(type(repository) == "table" and type(repository.record) == "function", "repository is required")
    return setmetatable({ _repository = repository }, ProgressionBinding)
end

function ProgressionBinding:consume(playerId, classKey, submissionId, classResponse)
    if not isInteger(playerId) or playerId <= 0
        or type(classKey) ~= "string" or classKey == ""
        or type(submissionId) ~= "string" or submissionId == ""
        or type(classResponse) ~= "table" then
        return {
            committed = false,
            returnToFreeRoam = false,
            code = "invalid_progression_input",
        }
    end

    local completionSignal = classResponse.classCompleted == true
        or classResponse.completionAlreadyRecorded == true
    if not completionSignal then
        return {
            committed = false,
            skipped = true,
            returnToFreeRoam = classResponse.returnToFreeRoam == true,
            code = "no_class_completion",
        }
    end

    if type(classResponse.attempts) ~= "number" or classResponse.attempts < 1
        or type(classResponse.correct) ~= "boolean" then
        return {
            committed = false,
            returnToFreeRoam = false,
            code = "invalid_class_completion",
        }
    end

    local receipt = self._repository:record({
        completionId = tostring(playerId) .. "|" .. classKey,
        playerId = playerId,
        classId = classKey,
        points = pointsFor(classResponse),
        attempts = classResponse.attempts,
        correct = classResponse.correct,
    })

    local committed = receipt.durable == true
        and (receipt.status == "applied" or receipt.status == "duplicate")

    return {
        committed = committed,
        progressionStatus = receipt.status,
        progressionError = receipt.error,
        state = receipt.state,
        returnToFreeRoam = committed and classResponse.returnToFreeRoam == true,
        code = committed and "progression_committed" or "progression_commit_failed",
    }
end

return ProgressionBinding
