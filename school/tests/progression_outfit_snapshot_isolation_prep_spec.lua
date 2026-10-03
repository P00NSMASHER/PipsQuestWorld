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

local outfit = {
    OutfitName = "Isolation",
    Hat1 = 101,
    Hat2 = 202,
    Hat3 = 303,
    Shirt = 404,
    Pants = 505,
    Face = 606,
    Package = 707,
    RPName = "RP",
    RPDesc = "Desc",
    RemoveShirt = false,
}

local repo = assert(Repository.open(store, 101))
local saved = repo:saveOutfit(2, outfit, "isolation-1")
eq(saved.status, "applied", "initial save")

saved.outfit.OutfitName = "tampered receipt"
local loaded = assert(repo:loadOutfit(2))
eq(loaded.OutfitName, "Isolation", "receipt mutation leaked into repository")

loaded.Hat1 = 999999
local loadedAgain = assert(repo:loadOutfit(2))
eq(loadedAgain.Hat1, 101, "loaded copy mutation leaked into repository")

local writesBeforeReplay = store.saves
local duplicate = repo:saveOutfit(2, outfit, "isolation-1")
eq(duplicate.status, "duplicate", "duplicate replay status")
duplicate.outfit.RPName = "tampered duplicate"
eq(store.saves, writesBeforeReplay, "duplicate replay performed write")
eq(assert(repo:loadOutfit(2)).RPName, "RP", "duplicate receipt mutation leaked")

local reopened = assert(Repository.open(store, 101))
eq(assert(reopened:loadOutfit(2)).OutfitName, "Isolation", "rejoin durable outfit changed")
eq(assert(reopened:loadOutfit(2)).Hat1, 101, "rejoin durable hat changed")
eq(assert(reopened:loadOutfit(2)).RPName, "RP", "rejoin durable roleplay name changed")

print("HIGH_SCHOOL_PROGRESSION_OUTFIT_SNAPSHOT_ISOLATION_PREP_PASS")
