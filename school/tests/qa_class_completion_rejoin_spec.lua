local EducationEngine = assert(loadfile("school/src/server/EducationEngine.lua"))()
local ClassSessionController = assert(loadfile("school/src/server/ClassSessionController.lua"))()
local catalog = assert(loadfile("school/src/server/ClassActivityCatalog.lua"))()
local Repository = assert(loadfile("school/src/server/ProgressionRepository.lua"))()
local ProgressionBinding = assert(loadfile("school/src/server/ProgressionBinding.lua"))()
local Coordinator = assert(loadfile("school/src/server/ClassProgressionCoordinator.lua"))()

local function clone(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, child in pairs(value) do copy[key] = clone(child) end
    return copy
end

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local store = {
    snapshot = nil,
    version = 0,
    read = function(self, _playerId)
        return self.snapshot and clone(self.snapshot) or nil, self.version, nil
    end,
    compareAndSwap = function(self, _playerId, expectedVersion, snapshot)
        if self.version ~= expectedVersion then return false, nil, "conflict" end
        self.snapshot = clone(snapshot)
        self.version = snapshot.revision
        return true, self.version, nil
    end,
}

local function newCoordinator()
    local engine = EducationEngine.new(catalog, { maxAttempts = 2, maxDifficultyJump = 1 })
    local controller = ClassSessionController.new(engine)
    return Coordinator.new(controller, function(playerId)
        local repository, err = Repository.open(store, playerId)
        assert(repository, tostring(err))
        return ProgressionBinding.new(repository)
    end)
end

local first = newCoordinator()
local entered = assert(first:enter("101", "1:2:math", "Math", 1))
eq(entered.accepted, true, "initial class entry")
local completed = assert(first:submit(
    101,
    "101",
    "1:2:math",
    entered.activity.id,
    "first-server-completion",
    2
))
eq(completed.progressionCommitted, true, "initial completion was not durable")
eq(completed.returnToFreeRoam, true, "initial completion did not return to free roam")

local durable = assert(Repository.open(store, 101))
eq(durable:getState().completionCount, 1, "durable completion missing before rejoin")

-- Simulate a new server process: ephemeral ClassSessionController state is rebuilt,
-- while the canonical progression store retains the committed class completion.
local rejoined = newCoordinator()
local replayEntry, replayEntryStatus = rejoined:enter("101", "1:2:math", "Math", 1)

eq(replayEntryStatus, "rejected", "durably completed class reopened after server rejoin")
eq(replayEntry.accepted, false, "durably completed class was accepted after server rejoin")
eq(replayEntry.code, "already_completed", "rejoin completion gate returned the wrong code")
eq(replayEntry.returnToFreeRoam, true, "rejoin completion gate did not preserve free roam")
eq(assert(Repository.open(store, 101)):getState().completionCount, 1, "rejoin mutated durable progression")

print("HIGH_SCHOOL_QA_CLASS_COMPLETION_REJOIN_PASS")
