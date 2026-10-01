local EducationEngine = assert(loadfile("school/src/server/EducationEngine.lua"))()
local ClassSessionController = assert(loadfile("school/src/server/ClassSessionController.lua"))()
local catalog = assert(loadfile("school/src/server/ClassActivityCatalog.lua"))()
local Repository = assert(loadfile("school/src/server/ProgressionRepository.lua"))()
local ProgressionBinding = assert(loadfile("school/src/server/ProgressionBinding.lua"))()

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

local function newStore()
    return {
        snapshot = nil,
        version = 0,
        failSave = false,
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
end

local engine = EducationEngine.new(catalog, { maxAttempts = 2, maxDifficultyJump = 1 })
local classes = ClassSessionController.new(engine)
local store = newStore()
local repository = assert(Repository.open(store, 101))
local binding = ProgressionBinding.new(repository)

local entered = assert(classes:enter("101", "1:2:math", "Math", 1))
local completed = assert(classes:submit("101", "1:2:math", entered.activity.id, "submission-1", 2))
eq(completed.classCompleted, true, "class did not produce authoritative completion")
eq(completed.returnToFreeRoam, true, "class did not request free roam")

local committed = binding:consume(101, "1:2:math", "submission-1", completed)
eq(committed.committed, true, "progression was not committed")
eq(committed.progressionStatus, "applied", "first progression status")
eq(committed.returnToFreeRoam, true, "free roam not released after durable commit")
eq(committed.state.completionCount, 1, "first progression count")
eq(committed.state.totalPoints, 25, "first progression points")

local replay = assert(classes:submit("101", "1:2:math", entered.activity.id, "submission-1", 2))
eq(replay.classCompleted, false, "class replay emitted a second completion")
eq(replay.completionAlreadyRecorded, true, "class replay lost completion marker")

local replayCommit = binding:consume(101, "1:2:math", "submission-1", replay)
eq(replayCommit.committed, true, "duplicate progression was not recognized as durable")
eq(replayCommit.progressionStatus, "duplicate", "duplicate progression status")
eq(replayCommit.state.completionCount, 1, "duplicate progression incremented count")

local rejoined = assert(Repository.open(store, 101))
eq(rejoined:getState().completionCount, 1, "save/rejoin lost completion")
eq(rejoined:getState().totalPoints, 25, "save/rejoin lost points")

local engine2 = EducationEngine.new(catalog, { maxAttempts = 2, maxDifficultyJump = 1 })
local classes2 = ClassSessionController.new(engine2)
local failingStore = newStore()
failingStore.failSave = true
local failingRepo = assert(Repository.open(failingStore, 202))
local failingBinding = ProgressionBinding.new(failingRepo)
local entered2 = assert(classes2:enter("202", "1:3:ela", "ELA", 1))
local completed2 = assert(classes2:submit("202", "1:3:ela", entered2.activity.id, "submission-2", 1))
eq(completed2.classCompleted, true, "failure fixture did not complete class")
local failedCommit = failingBinding:consume(202, "1:3:ela", "submission-2", completed2)
eq(failedCommit.committed, false, "failed persistence reported committed")
eq(failedCommit.returnToFreeRoam, false, "free roam released before durable progression")
eq(failedCommit.code, "progression_commit_failed", "failed commit code")

print("HIGH_SCHOOL_PROGRESSION_BINDING_PASS")
