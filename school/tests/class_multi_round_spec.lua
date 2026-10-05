local EducationEngine = assert(loadfile("school/src/server/EducationEngine.lua"))()
local ClassSessionController = assert(loadfile("school/src/server/ClassSessionController.lua"))()
local catalog = assert(loadfile("school/src/server/ClassActivityCatalog.lua"))()

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local engine = EducationEngine.new(catalog, { maxAttempts = 2, maxDifficultyJump = 1 })
local controller = ClassSessionController.new(engine, { activitiesPerClass = 3 })

local entered = assert(controller:enter("student", "1:2:math", "Math", 1))
equal(entered.round, 1, "entry round")
equal(entered.totalRounds, 3, "entry total rounds")
equal(entered.activity.correctIndex, nil, "entry leaked answer")

local roundOne = assert(controller:submit(
    "student", "1:2:math", entered.activity.id, "round-1", 2
))
equal(roundOne.classCompleted, false, "first round completed class")
equal(roundOne.roundCompleted, true, "first round completion missing")
equal(roundOne.round, 2, "second round index")
equal(roundOne.nextActivity.id, "math-supplies-2", "second activity")
equal(roundOne.nextActivity.correctIndex, nil, "second activity leaked answer")

local roundTwo = assert(controller:submit(
    "student", "1:2:math", roundOne.nextActivity.id, "round-2", 3
))
equal(roundTwo.classCompleted, false, "second round completed class")
equal(roundTwo.round, 3, "third round index")
equal(roundTwo.nextActivity.id, "math-groups-3", "third activity")

local final = assert(controller:submit(
    "student", "1:2:math", roundTwo.nextActivity.id, "round-3", 3
))
equal(final.classCompleted, true, "final round did not complete class")
equal(final.returnToFreeRoam, true, "final round did not restore free roam")
equal(final.roundCount, 3, "final round count")
equal(final.correctCount, 3, "final correct count")
equal(final.scorePercent, 100, "final score")
equal(final.grade, "A", "final grade")
equal(controller:getPlayerSnapshot("student").active, nil, "class remained active")

local retryEngine = EducationEngine.new(catalog, { maxAttempts = 2, maxDifficultyJump = 1 })
local retryController = ClassSessionController.new(retryEngine, { activitiesPerClass = 3 })
local retryEntered = assert(retryController:enter("retry-student", "1:2:math", "Math", 1))
local hinted = assert(retryController:submit(
    "retry-student", "1:2:math", retryEntered.activity.id, "retry-wrong", 1
))
equal(hinted.completed, false, "wrong first try unexpectedly completed round")
local retryRoundOne = assert(retryController:submit(
    "retry-student", "1:2:math", retryEntered.activity.id, "retry-correct", 2
))
local retryRoundTwo = assert(retryController:submit(
    "retry-student", "1:2:math", retryRoundOne.nextActivity.id, "retry-round-2", 3
))
local retryFinal = assert(retryController:submit(
    "retry-student", "1:2:math", retryRoundTwo.nextActivity.id, "retry-round-3", 3
))
equal(retryFinal.scorePercent, 87, "hint-assisted score")
equal(retryFinal.grade, "B", "hint-assisted grade")

print("CLASS_MULTI_ROUND_PASS")
