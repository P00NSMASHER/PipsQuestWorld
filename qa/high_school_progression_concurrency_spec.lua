local Repository = assert(loadfile("highschool/src/progression/ProgressionRepository.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local store = {
    snapshot = nil,
    load = function(self, _playerId)
        return self.snapshot, nil
    end,
    save = function(self, _playerId, snapshot)
        self.snapshot = snapshot
        return true
    end,
}

local function completion(id, score)
    return {
        completionId = id,
        playerId = 101,
        classId = "math",
        score = score,
        completedAt = "2026-10-01T16:45:00Z",
    }
end

-- Simulate two live writers that loaded the same player snapshot before either saved.
local writerA = assert(Repository.open(store, 101))
local writerB = assert(Repository.open(store, 101))

eq(writerA:record(completion("math-a", 10)).status, "applied", "writer A apply")
eq(writerB:record(completion("math-b", 20)).status, "applied", "writer B apply")

local reopened = assert(Repository.open(store, 101))
local state = reopened:getState()

-- Release-critical persistence invariant: independent successful completions may not be lost
-- merely because two writers began from the same earlier snapshot.
eq(state.completionCount, 2, "stale writer lost a successful completion")
eq(state.totalScore, 30, "stale writer lost score")

print("QA_PROGRESSION_CONCURRENT_WRITER_PASS")
