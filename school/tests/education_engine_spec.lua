local EducationEngine = assert(loadfile("school/src/server/EducationEngine.lua"))()

local function fail(message)
    error(message, 2)
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        fail((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function assertNil(value, message)
    if value ~= nil then
        fail((message or "expected nil") .. ": got " .. tostring(value))
    end
end

local function assertDeepEqual(left, right, path)
    path = path or "value"
    if type(left) ~= type(right) then
        fail(path .. " type mismatch")
    end
    if type(left) ~= "table" then
        assertEqual(left, right, path)
        return
    end
    for key, value in pairs(left) do
        assertDeepEqual(value, right[key], path .. "." .. tostring(key))
    end
    for key, value in pairs(right) do
        if left[key] == nil and value ~= nil then
            fail(path .. " missing key " .. tostring(key))
        end
    end
end

local catalog = {
    {
        id = "math-place-value-1",
        subject = "Math",
        difficulty = 1,
        prompt = "Which number has 4 tens and 2 ones?",
        choices = { "24", "42", "402", "6" },
        correctIndex = 2,
        hint = "The tens digit comes before the ones digit.",
        explanation = "Four tens and two ones make 42.",
        misconceptions = {
            [1] = "That reverses the tens and ones.",
            [3] = "That uses a hundreds place that was not named.",
        },
    },
    {
        id = "math-sum-2",
        subject = "Math",
        difficulty = 2,
        prompt = "What is 36 + 7?",
        choices = { "43", "42", "41", "44" },
        correctIndex = 1,
        hint = "Count on seven from 36.",
        explanation = "36 plus 7 is 43.",
    },
    {
        id = "math-difference-3",
        subject = "Math",
        difficulty = 3,
        prompt = "What is 61 - 28?",
        choices = { "31", "32", "33", "39" },
        correctIndex = 3,
        hint = "Subtract the ones, then the tens.",
        explanation = "61 minus 28 is 33.",
    },
    {
        id = "ela-setting-1",
        subject = "ELA",
        difficulty = 1,
        prompt = "Which detail tells where a story happens?",
        choices = { "The park", "After lunch", "She felt proud", "A surprise ending" },
        correctIndex = 1,
        hint = "Setting includes the place.",
        explanation = "The park names the place where the story happens.",
    },
}

local engine = EducationEngine.new(catalog, {
    maxAttempts = 2,
    maxDifficultyJump = 1,
})

-- Server-only answer authority: the activity view contains no answer key, and
-- mutating the returned view cannot change validation inside the engine.
engine:beginSession("retry-session", "Math", 1)
local publicActivity, state = engine:nextActivity("retry-session")
assertEqual(state, "new", "first activity state")
assertEqual(publicActivity.id, "math-place-value-1", "deterministic first selection")
assertNil(publicActivity.correctIndex, "correctIndex leaked to client activity")
assertNil(publicActivity.misconceptions, "misconception map leaked to client activity")
publicActivity.correctIndex = 1
publicActivity.choices[2] = "tampered"

local firstWrong, firstStatus = engine:submit("retry-session", publicActivity.id, "submission-1", 1)
assertEqual(firstStatus, "accepted", "first submission status")
assertEqual(firstWrong.accepted, true, "first submission accepted")
assertEqual(firstWrong.correct, false, "server authority ignored private key")
assertEqual(firstWrong.completed, false, "first wrong attempt should remain active")
assertEqual(firstWrong.feedback, "That reverses the tens and ones.", "misconception feedback")

local afterWrong = engine:getSessionSnapshot("retry-session")
assertEqual(afterWrong.activeAttempts, 1, "attempt count after first wrong answer")
assertEqual(afterWrong.completedCount, 0, "wrong attempt must not complete session item")

-- Duplicate submission: same idempotency key returns the same response without
-- incrementing attempts or history.
local duplicateWrong, duplicateStatus = engine:submit("retry-session", publicActivity.id, "submission-1", 1)
assertEqual(duplicateStatus, "duplicate", "duplicate submission status")
assertDeepEqual(duplicateWrong, firstWrong, "duplicate response")
local afterDuplicateWrong = engine:getSessionSnapshot("retry-session")
assertEqual(afterDuplicateWrong.activeAttempts, 1, "duplicate submission incremented attempts")
assertEqual(afterDuplicateWrong.completedCount, 0, "duplicate submission changed history")

local supportedCorrect, supportedStatus = engine:submit("retry-session", publicActivity.id, "submission-2", 2)
assertEqual(supportedStatus, "accepted", "supported correct status")
assertEqual(supportedCorrect.correct, true, "correct answer rejected")
assertEqual(supportedCorrect.completed, true, "correct answer did not complete")
local supportedSnapshot = engine:getSessionSnapshot("retry-session")
assertEqual(supportedSnapshot.completedCount, 1, "completed answer missing from history")
assertEqual(supportedSnapshot.history[1].independent, false, "retry-supported answer counted as independent mastery")
assertEqual(supportedSnapshot.difficultyTarget, 1, "supported answer should not raise difficulty target")

local duplicateCorrect, duplicateCorrectStatus = engine:submit("retry-session", publicActivity.id, "submission-2", 2)
assertEqual(duplicateCorrectStatus, "duplicate", "completed duplicate status")
assertDeepEqual(duplicateCorrect, supportedCorrect, "completed duplicate response")
assertEqual(engine:getSessionSnapshot("retry-session").completedCount, 1, "completed duplicate appended history")

-- Deterministic adaptive selection: independent correct answers raise the
-- session-local target by one without skipping more than one difficulty level.
engine:beginSession("adaptive-session", "Math", 1)
local first = assert(engine:nextActivity("adaptive-session"))
assertEqual(first.id, "math-place-value-1", "adaptive first activity")
local firstResult = assert(engine:submit("adaptive-session", first.id, "a-1", 2))
assertEqual(firstResult.correct, true, "independent first answer")
assertEqual(engine:getSessionSnapshot("adaptive-session").difficultyTarget, 2, "target did not rise after independent answer")

local second = assert(engine:nextActivity("adaptive-session"))
assertEqual(second.id, "math-sum-2", "adaptive second activity")
local secondResult = assert(engine:submit("adaptive-session", second.id, "a-2", 1))
assertEqual(secondResult.correct, true, "independent second answer")
assertEqual(engine:getSessionSnapshot("adaptive-session").difficultyTarget, 3, "target did not rise to three")

local third = assert(engine:nextActivity("adaptive-session"))
assertEqual(third.id, "math-difference-3", "adaptive third activity")
local thirdResult = assert(engine:submit("adaptive-session", third.id, "a-3", 3))
assertEqual(thirdResult.correct, true, "independent third answer")

local exhausted, exhaustedStatus = engine:nextActivity("adaptive-session")
assertNil(exhausted, "completed bank should be exhausted")
assertEqual(exhaustedStatus, "exhausted", "exhaustion status")

-- Subject isolation is deterministic.
engine:beginSession("ela-session", "ELA", 1)
local elaActivity = assert(engine:nextActivity("ela-session"))
assertEqual(elaActivity.id, "ela-setting-1", "subject isolation")

print("EDUCATION_ENGINE_DETERMINISTIC_TESTS_OK")
