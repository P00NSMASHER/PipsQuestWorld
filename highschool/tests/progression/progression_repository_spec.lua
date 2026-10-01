local Repository = assert(loadfile("highschool/src/progression/ProgressionRepository.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function newStore(initial)
    return {
        snapshot = initial,
        saves = 0,
        failSave = false,
        load = function(self, _playerId)
            return self.snapshot, nil
        end,
        save = function(self, _playerId, snapshot)
            if self.failSave then
                return false, "injected"
            end
            self.snapshot = snapshot
            self.saves = self.saves + 1
            return true
        end,
    }
end

local function completion(id, playerId, score)
    return {
        completionId = id,
        playerId = playerId,
        classId = "math",
        score = score,
        completedAt = "2026-10-01T16:00:00Z",
    }
end

local store = newStore(nil)
local repo = assert(Repository.open(store, 101))
eq(repo:getLoadSource(), "default", "new state source")
eq(repo:getState().totalScore, 0, "new state score")

local first = repo:record(completion("math-001", 101, 25))
eq(first.status, "applied", "first status")
eq(store.saves, 1, "first save count")
eq(repo:getState().totalScore, 25, "first score")

local duplicate = repo:record(completion("math-001", 101, 25))
eq(duplicate.status, "duplicate", "duplicate status")
eq(duplicate.applied, false, "duplicate applied")
eq(store.saves, 1, "duplicate save count")

local reopened = assert(Repository.open(store, 101))
eq(reopened:getLoadSource(), "restored", "rejoin source")
eq(reopened:getState().totalScore, 25, "rejoin score")
local replay = reopened:record(completion("math-001", 101, 25))
eq(replay.status, "duplicate", "rejoin replay")
eq(store.saves, 1, "rejoin save count")

local mismatch = reopened:record(completion("math-other", 202, 50))
eq(mismatch.status, "rejected", "scope status")
eq(mismatch.error, "PLAYER_SCOPE_MISMATCH", "scope error")
eq(store.saves, 1, "scope save count")
eq(reopened:getState().totalScore, 25, "scope score")

store.failSave = true
local failed = reopened:record(completion("math-002", 101, 20))
eq(failed.status, "rejected", "save failure status")
eq(failed.error, "SAVE_FAILED:injected", "save failure error")
eq(reopened:getState().totalScore, 25, "save failure score")
eq(store.saves, 1, "failed save count")

store.failSave = false
local retry = reopened:record(completion("math-002", 101, 20))
eq(retry.status, "applied", "save retry status")
eq(reopened:getState().totalScore, 45, "save retry score")
eq(store.saves, 2, "save retry count")

local invalidStore = newStore({
    schemaVersion = 1,
    completions = { false },
})
local invalidRepo, invalidError = Repository.open(invalidStore, 101)
eq(invalidRepo, nil, "invalid persisted state")
eq(invalidError, "INVALID_RECORD", "invalid persisted error")

local missingStore, missingStoreError = Repository.open({}, 101)
eq(missingStore, nil, "missing store")
eq(missingStoreError, "INVALID_STORE", "missing store error")

print("HIGH_SCHOOL_PROGRESSION_REPOSITORY_PASS")
