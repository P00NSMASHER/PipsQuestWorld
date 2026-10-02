local Repository = assert(loadfile("school/src/server/ProgressionRepository.lua"))()
local StudioStore = assert(loadfile("school/src/server/ProgressionStudioStore.lua"))()

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

local function newStore(initial)
    return {
        snapshot = initial and clone(initial) or nil,
        version = initial and initial.revision or 0,
        saves = 0,
        failSave = false,
        injectConflict = nil,
        read = function(self, _playerId)
            return self.snapshot and clone(self.snapshot) or nil, self.version, nil
        end,
        compareAndSwap = function(self, _playerId, expectedVersion, snapshot)
            if self.failSave then
                return false, nil, "injected"
            end
            if self.injectConflict then
                local hook = self.injectConflict
                self.injectConflict = nil
                hook(self)
            end
            if self.version ~= expectedVersion then
                return false, nil, "conflict"
            end
            self.snapshot = clone(snapshot)
            self.version = snapshot.revision
            self.saves = self.saves + 1
            return true, self.version, nil
        end,
    }
end

local function completion(id, points)
    return {
        completionId = id,
        playerId = 101,
        classId = id,
        points = points,
        attempts = 1,
        correct = true,
    }
end

local store = newStore(nil)
local repo = assert(Repository.open(store, 101))
eq(repo:getState().completionCount, 0, "new completion count")

local first = repo:record(completion("1:2:math", 25))
eq(first.status, "applied", "first status")
eq(first.durable, true, "first durable")
eq(first.revision, 1, "first revision")
eq(repo:getState().totalPoints, 25, "first points")

local duplicate = repo:record(completion("1:2:math", 25))
eq(duplicate.status, "duplicate", "duplicate status")
eq(duplicate.durable, true, "duplicate durable")
eq(store.saves, 1, "duplicate wrote again")

local conflictRecord = completion("1:2:math", 15)
local conflict = repo:record(conflictRecord)
eq(conflict.status, "conflict", "completion id conflict status")
eq(conflict.error, "COMPLETION_ID_CONFLICT", "completion id conflict error")
eq(store.saves, 1, "conflict wrote")

local reopened = assert(Repository.open(store, 101))
eq(reopened:getState().completionCount, 1, "rejoin completion count")
eq(reopened:getState().totalPoints, 25, "rejoin points")

store.injectConflict = function(s)
    s.snapshot = {
        schemaVersion = 2,
        revision = 2,
        completions = {
            completion("1:2:math", 25),
            completion("1:3:ela", 20),
        },
    }
    s.version = 2
end

local raced = reopened:record(completion("1:4:science", 15))
eq(raced.status, "applied", "raced status")
eq(raced.durable, true, "raced durable")
eq(raced.revision, 3, "raced revision")
eq(raced.state.completionCount, 3, "raced lost concurrent completion")
eq(raced.state.totalPoints, 60, "raced total points")

local afterRace = assert(Repository.open(store, 101))
eq(afterRace:getState().completionCount, 3, "rejoin after race count")
eq(afterRace:getState().totalPoints, 60, "rejoin after race points")

store.failSave = true
local failed = afterRace:record(completion("1:6:social", 10))
eq(failed.status, "rejected", "save failure status")
eq(failed.durable, false, "save failure durable")
eq(failed.error, "SAVE_FAILED:injected", "save failure error")
eq(afterRace:getState().completionCount, 3, "failed save mutated local state")

local studioBacking = {}
local studioStore = StudioStore.new(studioBacking)
local studioRepo = assert(Repository.open(studioStore, 101))
local studioApplied = studioRepo:record(completion("studio:math", 25))
eq(studioApplied.status, "applied", "studio store apply")
eq(studioApplied.durable, true, "studio store durable")
eq(studioApplied.revision, 1, "studio store revision")

local studioReopened = assert(Repository.open(StudioStore.new(studioBacking), 101))
eq(studioReopened:getState().completionCount, 1, "studio reopen completion count")
eq(studioReopened:getState().totalPoints, 25, "studio reopen points")

local staleStudioStore = StudioStore.new(studioBacking)
local _, staleVersion = staleStudioStore:read(101)
eq(staleVersion, 1, "studio read revision")
local staleSave, _, staleError = staleStudioStore:compareAndSwap(
    101,
    0,
    {
        schemaVersion = 2,
        revision = 1,
        completions = {},
    }
)
eq(staleSave, false, "studio stale write accepted")
eq(staleError, "conflict", "studio stale write error")

print("HIGH_SCHOOL_PROGRESSION_REPOSITORY_PASS")
