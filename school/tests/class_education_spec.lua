local EducationEngine = assert(loadfile("school/src/server/EducationEngine.lua"))()
local ClassSessionController = assert(loadfile("school/src/server/ClassSessionController.lua"))()
local catalog = assert(loadfile("school/src/server/ClassActivityCatalog.lua"))()

local function fail(message)
    error(message, 2)
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        fail((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local engine = EducationEngine.new(catalog, { maxAttempts = 2, maxDifficultyJump = 1 })
local controller = ClassSessionController.new(engine)

local entered, enteredStatus = controller:enter("player-1", "1:2:math", "Math", 1)
assertEqual(enteredStatus, "entered", "class entry status")
assertEqual(entered.accepted, true, "class entry rejected")
assertEqual(entered.activity.id, "math-linear-1", "wrong deterministic activity")
assertEqual(entered.activity.correctIndex, nil, "answer key leaked")

local enteredAgain, enteredAgainStatus = controller:enter("player-1", "1:2:math", "Math", 1)
assertEqual(enteredAgainStatus, "active", "repeat entry must be idempotent")
assertEqual(enteredAgain.activity.id, entered.activity.id, "repeat entry changed activity")

local wrong, wrongStatus = controller:submit(
    "player-1", "1:2:math", entered.activity.id, "submission-1", 1
)
assertEqual(wrongStatus, "accepted", "first answer status")
assertEqual(wrong.correct, false, "wrong answer marked correct")
assertEqual(wrong.completed, false, "first wrong answer must allow recovery")
assertEqual(type(wrong.hint), "string", "wrong answer did not provide a hint")
assertEqual(controller:getPlayerSnapshot("player-1").completionCount, 0, "wrong answer completed class")

local wrongReplay, wrongReplayStatus = controller:submit(
    "player-1", "1:2:math", entered.activity.id, "submission-1", 1
)
assertEqual(wrongReplayStatus, "duplicate", "duplicate wrong submission not detected")
assertEqual(wrongReplay.duplicate, true, "duplicate marker missing")
assertEqual(controller:getPlayerSnapshot("player-1").completionCount, 0, "duplicate changed completion count")

local corrected, correctedStatus = controller:submit(
    "player-1", "1:2:math", entered.activity.id, "submission-2", 2
)
assertEqual(correctedStatus, "accepted", "corrected answer status")
assertEqual(corrected.correct, true, "corrected answer rejected")
assertEqual(corrected.classCompleted, true, "class completion not emitted")
assertEqual(corrected.returnToFreeRoam, true, "completion did not return to free roam")
assertEqual(controller:getPlayerSnapshot("player-1").completionCount, 1, "completion not recorded exactly once")
assertEqual(controller:getPlayerSnapshot("player-1").active, nil, "active class survived completion")

local completionReplay, completionReplayStatus = controller:submit(
    "player-1", "1:2:math", entered.activity.id, "submission-2", 2
)
assertEqual(completionReplayStatus, "duplicate", "completion replay not detected")
assertEqual(completionReplay.classCompleted, false, "completion replay emitted completion twice")
assertEqual(completionReplay.completionAlreadyRecorded, true, "completion replay missing recorded marker")
assertEqual(controller:getPlayerSnapshot("player-1").completionCount, 1, "completion replay incremented count")

local late, lateStatus = controller:submit(
    "player-1", "1:2:math", entered.activity.id, "submission-3", 2
)
assertEqual(lateStatus, "rejected", "late submission status")
assertEqual(late.code, "late_submission", "late submission code")

local reenter, reenterStatus = controller:enter("player-1", "1:2:math", "Math", 1)
assertEqual(reenterStatus, "rejected", "completed class allowed re-entry")
assertEqual(reenter.code, "already_completed", "completed class re-entry code")

local science = assert(controller:enter("player-1", "1:4:science", "Science", 1))
assertEqual(science.accepted, true, "second class entry failed")
local left, leftStatus = controller:leave("player-1", "period_changed")
assertEqual(leftStatus, "left", "period exit status")
assertEqual(left.returnToFreeRoam, true, "period exit did not return to free roam")
assertEqual(controller:getPlayerSnapshot("player-1").active, nil, "period exit left class active")
assertEqual(controller:getPlayerSnapshot("player-1").completionCount, 1, "period exit fabricated completion")

local ela = assert(controller:enter("player-2", "1:3:ela", "ELA", 1))
local firstWrong = assert(controller:submit("player-2", "1:3:ela", ela.activity.id, "p2-1", 2))
assertEqual(firstWrong.completed, false, "first wrong attempt should not soft-lock or finish")
local secondWrong = assert(controller:submit("player-2", "1:3:ela", ela.activity.id, "p2-2", 2))
assertEqual(secondWrong.correct, false, "second wrong answer unexpectedly correct")
assertEqual(secondWrong.completed, true, "max-attempt recovery did not resolve")
assertEqual(type(secondWrong.explanation), "string", "modeled answer explanation missing")
assertEqual(secondWrong.classCompleted, true, "supported recovery did not close class")
assertEqual(secondWrong.returnToFreeRoam, true, "supported recovery did not return to free roam")

print("CLASS_EDUCATION_DETERMINISTIC_TESTS_OK")
