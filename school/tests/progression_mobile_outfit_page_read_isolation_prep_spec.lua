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
eq(repo:saveOutfit(10, outfit("Mobile 10", 10), "mobile-10").status, "applied", "slot 10 save")
eq(repo:saveOutfit(11, outfit("Mobile 11", 11), "mobile-11").status, "applied", "slot 11 save")
eq(repo:saveOutfit(12, outfit("Mobile 12", 12), "mobile-12").status, "applied", "slot 12 save")
eq(repo:saveOutfit(13, outfit("Hidden 13", 13), "hidden-13").status, "applied", "slot 13 save")
local writesBeforeRead = store.saves

local page = assert(repo:loadOutfitPage(10))
eq(#page, 3, "legacy page size")
eq(page[1].slot, 10, "page slot 10")
eq(page[2].slot, 11, "page slot 11")
eq(page[3].slot, 12, "page slot 12")
eq(page[1].outfit.OutfitName, "Mobile 10", "page outfit 10")
eq(page[3].outfit.OutfitName, "Mobile 12", "page outfit 12")
eq(store.saves, writesBeforeRead, "read-only page performed persistence write")

page[1].outfit.OutfitName = "tampered page"
page[2].outfit.Hat1 = 999999
eq(assert(repo:loadOutfit(10)).OutfitName, "Mobile 10", "page mutation leaked to slot 10")
eq(assert(repo:loadOutfit(11)).Hat1, 11, "page mutation leaked to slot 11")

local invalidPage, invalidError = repo:loadOutfitPage(13)
eq(invalidPage, nil, "hidden slot exposed as legacy page")
eq(invalidError, "INVALID_OUTFIT_PAGE", "hidden page rejection")
eq(assert(repo:loadOutfit(13)).OutfitName, "Hidden 13", "hidden durable slot lost")

local reopened = assert(Repository.open(store, 101))
local reopenedPage = assert(reopened:loadOutfitPage(10))
eq(reopenedPage[1].outfit.OutfitName, "Mobile 10", "rejoin page slot 10")
eq(reopenedPage[2].outfit.Hat1, 11, "rejoin page slot 11")
eq(assert(reopened:loadOutfit(13)).OutfitName, "Hidden 13", "rejoin hidden slot")
eq(store.saves, writesBeforeRead, "reopen/read performed persistence write")

print("HIGH_SCHOOL_PROGRESSION_MOBILE_OUTFIT_PAGE_READ_ISOLATION_PREP_PASS")
