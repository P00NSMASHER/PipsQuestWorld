local Repository = assert(loadfile("school/src/server/ProgressionRepository.lua"))()

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
    saves = 0,
    read = function(self)
        return self.snapshot and clone(self.snapshot) or nil, self.version, nil
    end,
    compareAndSwap = function(self, _playerId, expectedVersion, snapshot)
        if self.version ~= expectedVersion then
            return false, nil, "conflict"
        end
        self.snapshot = clone(snapshot)
        self.version = snapshot.revision
        self.saves = self.saves + 1
        return true, self.version, nil
    end,
}

local function completion(id, classId, points)
    return {
        completionId = id,
        playerId = 101,
        classId = classId,
        points = points,
        attempts = 1,
        correct = true,
    }
end

local repo = assert(Repository.open(store, 101))
eq(repo:record(completion("read:math", "math", 25)).status, "applied", "math apply")
eq(repo:record(completion("read:ela", "ela", 15)).status, "applied", "ela apply")
local durableWrites = store.saves

local state = repo:getState()
eq(state.totalPoints, 40, "initial total")
eq(state.completionCount, 2, "initial count")
state.totalPoints = 999999
state.completionCount = 0
state.classes[1].points = 999999
state.classes[1].completionCount = 999999

local fresh = repo:getState()
eq(fresh.totalPoints, 40, "state total mutation leaked")
eq(fresh.completionCount, 2, "state count mutation leaked")
eq(fresh.classes[1].classId, "ela", "class ordering changed")
eq(fresh.classes[1].points, 15, "class points mutation leaked")
eq(fresh.classes[1].completionCount, 1, "class count mutation leaked")
eq(store.saves, durableWrites, "read-only state performed write")

local duplicate = repo:record(completion("read:math", "math", 25))
eq(duplicate.status, "duplicate", "duplicate status")
eq(duplicate.durable, true, "duplicate durability")
eq(store.saves, durableWrites, "duplicate replay wrote")
duplicate.state.totalPoints = 0
duplicate.state.classes[2].points = 0

local afterReceiptMutation = repo:getState()
eq(afterReceiptMutation.totalPoints, 40, "duplicate receipt mutation leaked")
eq(afterReceiptMutation.classes[2].classId, "math", "math class missing")
eq(afterReceiptMutation.classes[2].points, 25, "duplicate receipt class mutation leaked")

local reopened = assert(Repository.open(store, 101))
local rejoined = reopened:getState()
eq(rejoined.totalPoints, 40, "rejoin total")
eq(rejoined.completionCount, 2, "rejoin count")
eq(rejoined.classes[1].points, 15, "rejoin ela points")
eq(rejoined.classes[2].points, 25, "rejoin math points")
eq(store.saves, durableWrites, "reopen/read performed write")

print("HIGH_SCHOOL_PROGRESSION_READ_STATE_ISOLATION_PREP_PASS")
