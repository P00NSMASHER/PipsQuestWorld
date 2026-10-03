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

local function assertCatalogRejected(candidate, expectedFragment)
    local ok, err = pcall(function()
        EducationEngine.new(candidate)
    end)
    assertEqual(ok, false, "malformed catalog was accepted")
    if not string.find(tostring(err), expectedFragment, 1, true) then
        fail("malformed catalog error missing expected fragment: " .. expectedFragment .. " in " .. tostring(err))
    end
end

assertCatalogRejected({
    {
        id = "blank-prompt",
        subject = "Math",
        difficulty = 1,
        prompt = "   ",
        choices = { "A", "B" },
        correctIndex = 1,
        hint = "Hint",
        explanation = "Explanation",
    },
}, "activity.prompt must be a non-blank string")

assertCatalogRejected({
    {
        id = "duplicate-choices",
        subject = "Math",
        difficulty = 1,
        prompt = "Pick one.",
        choices = { "Same", "  same  " },
        correctIndex = 1,
        hint = "Hint",
        explanation = "Explanation",
    },
}, "activity choices must be unique after normalization")

assertCatalogRejected({
    {
        id = "blank-hint",
        subject = "Math",
        difficulty = 1,
        prompt = "Pick one.",
        choices = { "A", "B" },
        correctIndex = 1,
        hint = "\t  ",
        explanation = "Explanation",
    },
}, "activity.hint must be a non-blank string")

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

local conflictingWrong, conflictingWrongStatus = engine:submit("retry-session", publicActivity.id, "submission-1", 2)
assertEqual(conflictingWrongStatus, "duplicate", "conflicting idempotency status")
assertEqual(conflictingWrong.accepted, false, "conflicting idempotency payload was accepted")
assertEqual(conflictingWrong.code, "idempotency_conflict", "conflicting idempotency code")
assertEqual(conflictingWrong.duplicate, true, "conflicting idempotency duplicate marker")
assertEqual(engine:getSessionSnapshot("retry-session").activeAttempts, 1, "conflicting duplicate incremented attempts")

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

-- Invalid choices are pure rejections: they consume no attempt or receipt,
-- so the same submission id can be corrected without a soft lock.
engine:beginSession("invalid-choice-session", "Math", 1)
local invalidActivity = assert(engine:nextActivity("invalid-choice-session"))
local invalidChoice, invalidChoiceStatus = engine:submit(
    "invalid-choice-session", invalidActivity.id, "invalid-choice-retry", 0
)
assertEqual(invalidChoiceStatus, "rejected", "invalid choice status")
assertEqual(invalidChoice.accepted, false, "invalid choice was accepted")
assertEqual(invalidChoice.code, "invalid_choice", "invalid choice code")
local invalidAfterReject = engine:getSessionSnapshot("invalid-choice-session")
assertEqual(invalidAfterReject.activeAttempts, 0, "invalid choice consumed an attempt")
assertEqual(invalidAfterReject.completedCount, 0, "invalid choice changed history")
assertEqual(invalidAfterReject.active.id, invalidActivity.id, "invalid choice cleared the active activity")

local invalidRecovered, invalidRecoveredStatus = engine:submit(
    "invalid-choice-session", invalidActivity.id, "invalid-choice-retry", 2
)
assertEqual(invalidRecoveredStatus, "accepted", "corrected invalid choice was rejected")
assertEqual(invalidRecovered.correct, true, "corrected invalid choice was not correct")
assertEqual(invalidRecovered.completed, true, "corrected invalid choice did not complete")
assertEqual(invalidRecovered.attempts, 1, "rejected invalid choice polluted attempt count")
assertEqual(engine:getSessionSnapshot("invalid-choice-session").completedCount, 1, "corrected retry missing history")

local invalidRecoveredReplay, invalidRecoveredReplayStatus = engine:submit(
    "invalid-choice-session", invalidActivity.id, "invalid-choice-retry", 2
)
assertEqual(invalidRecoveredReplayStatus, "duplicate", "corrected retry replay status")
assertDeepEqual(invalidRecoveredReplay, invalidRecovered, "corrected retry duplicate response")
assertEqual(engine:getSessionSnapshot("invalid-choice-session").completedCount, 1, "corrected retry replay duplicated history")

-- A wrong activity id is a pure rejection: it must not consume an attempt or
-- reserve the submission id, so the same id can recover against the active activity.
engine:beginSession("wrong-activity-session", "Math", 1)
local wrongActivityActive = assert(engine:nextActivity("wrong-activity-session"))
local wrongActivity, wrongActivityStatus = engine:submit(
    "wrong-activity-session", "not-active", "wrong-activity-retry", 2
)
assertEqual(wrongActivityStatus, "rejected", "wrong activity status")
assertEqual(wrongActivity.accepted, false, "wrong activity was accepted")
assertEqual(wrongActivity.code, "activity_not_active", "wrong activity rejection code")
local wrongActivitySnapshot = engine:getSessionSnapshot("wrong-activity-session")
assertEqual(wrongActivitySnapshot.activeAttempts, 0, "wrong activity consumed an attempt")
assertEqual(wrongActivitySnapshot.active.id, wrongActivityActive.id, "wrong activity cleared active state")
local wrongActivityRecovered, wrongActivityRecoveredStatus = engine:submit(
    "wrong-activity-session", wrongActivityActive.id, "wrong-activity-retry", 2
)
assertEqual(wrongActivityRecoveredStatus, "accepted", "wrong activity rejection poisoned submission id")
assertEqual(wrongActivityRecovered.completed, true, "wrong activity recovery did not complete")
assertEqual(engine:getSessionSnapshot("wrong-activity-session").completedCount, 1, "wrong activity recovery missing history")

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

-- Closed sessions stay inert under duplicate teardown and late activity/submission calls.
engine:beginSession("closed-session", "Math", 1)
local closedActivity = assert(engine:nextActivity("closed-session"))
local firstClose = engine:closeSession("closed-session")
assertEqual(firstClose.closed, true, "closed session did not report closed")
assertNil(firstClose.active, "closed session kept active activity")
assertEqual(firstClose.completedCount, 0, "closing session fabricated history")
local secondClose = engine:closeSession("closed-session")
assertEqual(secondClose.closed, true, "duplicate close reopened session")
assertNil(secondClose.active, "duplicate close restored activity")
local closedNext, closedNextStatus = engine:nextActivity("closed-session")
assertNil(closedNext, "closed session produced another activity")
assertEqual(closedNextStatus, "closed", "closed session next-activity status")
local closedSubmit, closedSubmitStatus = engine:submit(
    "closed-session", closedActivity.id, "closed-session-late", 2
)
assertEqual(closedSubmitStatus, "rejected", "closed session accepted a late submission")
assertEqual(closedSubmit.accepted, false, "closed session late submission accepted")
assertEqual(closedSubmit.code, "session_closed", "closed session late submission code")
assertEqual(engine:getSessionSnapshot("closed-session").completedCount, 0, "closed session late submit changed history")

-- Subject isolation is deterministic.
engine:beginSession("ela-session", "ELA", 1)
local elaActivity = assert(engine:nextActivity("ela-session"))
assertEqual(elaActivity.id, "ela-setting-1", "subject isolation")

print("EDUCATION_ENGINE_DETERMINISTIC_TESTS_OK")
