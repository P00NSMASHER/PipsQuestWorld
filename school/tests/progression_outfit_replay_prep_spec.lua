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

local function outfit(name, hat)
    return {
        OutfitName = name,
        Hat1 = hat,
        Hat2 = 0,
        Hat3 = 0,
        Shirt = 0,
        Pants = 0,
        Face = 0,
        Package = 0,
        RPName = "",
        RPDesc = "",
        RemoveShirt = false,
    }
end

local repo = assert(Repository.open(store, 101))
local first = repo:saveOutfit(3, outfit("Replay A", 1001), "replay-a")
eq(first.status, "applied", "first save")
local second = repo:saveOutfit(3, outfit("Replay B", 2002), "replay-b")
eq(second.status, "applied", "second save")
local durableRevision = second.revision
local durableWrites = store.saves

local oldReplay = repo:saveOutfit(3, outfit("Replay A", 1001), "replay-a")
eq(oldReplay.status, "duplicate", "old replay status")
eq(oldReplay.revision, durableRevision, "old replay revision")
eq(store.saves, durableWrites, "old replay write count")
eq(assert(repo:loadOutfit(3)).OutfitName, "Replay B", "old replay rollback")

local reopened = assert(Repository.open(store, 101))
local rejoinReplay = reopened:saveOutfit(3, outfit("Replay A", 1001), "replay-a")
eq(rejoinReplay.status, "duplicate", "rejoin replay status")
eq(rejoinReplay.revision, durableRevision, "rejoin replay revision")
eq(store.saves, durableWrites, "rejoin replay write count")
eq(assert(reopened:loadOutfit(3)).OutfitName, "Replay B", "rejoin replay rollback")

local conflict = reopened:saveOutfit(3, outfit("Replay A", 1002), "replay-a")
eq(conflict.status, "conflict", "payload conflict status")
eq(conflict.error, "OUTFIT_REQUEST_ID_CONFLICT", "payload conflict error")
eq(store.saves, durableWrites, "payload conflict write count")

print("HIGH_SCHOOL_PROGRESSION_OUTFIT_REPLAY_PREP_PASS")
