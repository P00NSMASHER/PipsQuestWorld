local EducationEngine = assert(loadfile("school/src/server/EducationEngine.lua"))()
local ClassSessionController = assert(loadfile("school/src/server/ClassSessionController.lua"))()
local catalog = assert(loadfile("school/src/server/ClassActivityCatalog.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local engine = EducationEngine.new(catalog, { maxAttempts = 2, maxDifficultyJump = 1 })
local controller = ClassSessionController.new(engine)

local entered, enteredStatus = controller:enter("invalid-choice-player", "1:2:math", "Math", 1)
eq(enteredStatus, "entered", "entry status")
eq(entered.accepted, true, "entry accepted")

local invalid, invalidStatus = controller:submit(
    "invalid-choice-player",
    "1:2:math",
    entered.activity.id,
    "invalid-choice-submit",
    99
)
eq(invalidStatus, "rejected", "invalid choice status")
eq(invalid.accepted, false, "invalid choice accepted")
eq(invalid.code, "invalid_choice", "invalid choice code")
eq(invalid.classCompleted, false, "invalid choice completed class")
eq(invalid.returnToFreeRoam, false, "invalid choice exited class")

local snapshotAfterInvalid = controller:getPlayerSnapshot("invalid-choice-player")
eq(snapshotAfterInvalid.active.classKey, "1:2:math", "invalid choice cleared active class")
eq(snapshotAfterInvalid.completionCount, 0, "invalid choice changed completion count")

local wrong, wrongStatus = controller:submit(
    "invalid-choice-player",
    "1:2:math",
    entered.activity.id,
    "valid-after-invalid-1",
    1
)
eq(wrongStatus, "accepted", "valid retry after invalid status")
eq(wrong.completed, false, "invalid choice consumed an attempt")

local corrected, correctedStatus = controller:submit(
    "invalid-choice-player",
    "1:2:math",
    entered.activity.id,
    "valid-after-invalid-2",
    2
)
eq(correctedStatus, "accepted", "corrective answer status")
eq(corrected.classCompleted, true, "corrective answer did not complete class")
eq(corrected.returnToFreeRoam, true, "completion did not restore free roam")
eq(controller:getPlayerSnapshot("invalid-choice-player").completionCount, 1, "completion count not exactly once")

print("CLASS_INVALID_CHOICE_LIFECYCLE_PASS")
