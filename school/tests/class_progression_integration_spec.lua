local EducationEngine = assert(loadfile("school/src/server/EducationEngine.lua"))()
local ClassSessionController = assert(loadfile("school/src/server/ClassSessionController.lua"))()
local catalog = assert(loadfile("school/src/server/ClassActivityCatalog.lua"))()
local Repository = assert(loadfile("school/src/server/ProgressionRepository.lua"))()
local ProgressionBinding = assert(loadfile("school/src/server/ProgressionBinding.lua"))()
local Coordinator = assert(loadfile("school/src/server/ClassProgressionCoordinator.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function clone(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, child in pairs(value) do copy[key] = clone(child) end
    return copy
end

local store = {
    snapshot = nil,
    version = 0,
    failSave = true,
    read = function(self, _playerId)
        return self.snapshot and clone(self.snapshot) or nil, self.version, nil
    end,
    compareAndSwap = function(self, _playerId, expectedVersion, snapshot)
        if self.failSave then return false, nil, "injected" end
        if self.version ~= expectedVersion then return false, nil, "conflict" end
        self.snapshot = clone(snapshot)
        self.version = snapshot.revision
        return true, self.version, nil
    end,
}

local engine = EducationEngine.new(catalog, { maxAttempts = 2, maxDifficultyJump = 1 })
local classController = ClassSessionController.new(engine)
local repository = assert(Repository.open(store, 101))
local coordinator = Coordinator.new(classController, function(playerId)
    eq(playerId, 101, "binding player")
    return ProgressionBinding.new(repository)
end)

local entered = assert(coordinator:enter("101", "1:2:math", "Math", 1))
local failed, failedStatus = coordinator:submit(
    101,
    "101",
    "1:2:math",
    entered.activity.id,
    "submission-1",
    2
)
eq(failedStatus, "progression_pending", "failed persistence status")
eq(failed.progressionCommitted, false, "failed persistence committed")
eq(failed.returnToFreeRoam, false, "free roam released before durable commit")
eq(coordinator:getPlayerSnapshot("101").progressionPending, true, "pending progression not exposed")

local blockedLeave, blockedLeaveStatus = coordinator:leave("101", "requested")
eq(blockedLeaveStatus, "progression_pending", "pending leave status")
eq(blockedLeave.returnToFreeRoam, false, "pending leave escaped to free roam")

local blockedEnter, blockedEnterStatus = coordinator:enter("101", "1:3:ela", "ELA", 1)
eq(blockedEnterStatus, "progression_pending", "pending enter status")
eq(blockedEnter.accepted, false, "pending progression allowed another class")

store.failSave = false
local retry, retryStatus = coordinator:submit(
    101,
    "101",
    "1:2:math",
    entered.activity.id,
    "submission-1",
    2
)
eq(retryStatus, "duplicate", "retry must reuse class receipt")
eq(retry.progressionCommitted, true, "retry did not durably commit")
eq(retry.progressionStatus, "applied", "retry progression status")
eq(retry.returnToFreeRoam, true, "free roam not released after durable commit")
eq(coordinator:getPlayerSnapshot("101").progressionPending, false, "pending state not cleared")
eq(retry.progressionState.completionCount, 1, "retry completion count")

local replay, replayStatus = coordinator:submit(
    101,
    "101",
    "1:2:math",
    entered.activity.id,
    "submission-1",
    2
)
eq(replayStatus, "duplicate", "post-commit replay class status")
eq(replay.progressionCommitted, true, "post-commit replay lost durable state")
eq(replay.progressionStatus, "duplicate", "post-commit progression was applied twice")
eq(replay.progressionState.completionCount, 1, "post-commit replay incremented progression")

local rejoined = assert(Repository.open(store, 101))
eq(rejoined:getState().completionCount, 1, "rejoin lost committed completion")
eq(rejoined:getState().totalPoints, 25, "rejoin lost committed points")

print("HIGH_SCHOOL_CLASS_PROGRESSION_INTEGRATION_PASS")
