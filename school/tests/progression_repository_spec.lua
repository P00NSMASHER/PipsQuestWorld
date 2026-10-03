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

local outfit = {
    OutfitName = "Filtered Hero",
    Hat1 = 101,
    Hat2 = 202,
    Hat3 = 303,
    Shirt = 404,
    Pants = 505,
    Face = 606,
    Package = 707,
    RPName = "Filtered RP",
    RPDesc = "Filtered Description",
    RemoveShirt = false,
}
local outfitSaved = studioReopened:saveOutfit(12, outfit, "studio-outfit-12")
eq(outfitSaved.status, "applied", "outfit save status")
eq(outfitSaved.durable, true, "outfit save durable")
eq(outfitSaved.outfit.Hat3, 303, "outfit third hat persisted")

local outfitReopened = assert(Repository.open(StudioStore.new(studioBacking), 101))
local loadedOutfit = assert(outfitReopened:loadOutfit(12))
eq(loadedOutfit.OutfitName, "Filtered Hero", "outfit name survives reopen")
eq(loadedOutfit.Hat1, 101, "outfit Hat1 survives reopen")
eq(loadedOutfit.Hat2, 202, "outfit Hat2 survives reopen")
eq(loadedOutfit.Hat3, 303, "outfit Hat3 survives reopen")
eq(loadedOutfit.RemoveShirt, false, "outfit boolean survives reopen")
local lastPage = assert(outfitReopened:loadOutfitPage(10))
eq(#lastPage, 3, "outfit page 10 size")
eq(lastPage[3].slot, 12, "outfit page 10 includes slot 12")


local function defaultOutfit()
    return {
        OutfitName = "",
        Hat1 = 0,
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

local legacyOutfits = {}
for slot = 1, 12 do
    legacyOutfits[slot] = defaultOutfit()
end
legacyOutfits[12].OutfitName = "Legacy Slot Twelve"
legacyOutfits[12].Hat1 = 1200

local migrationStore = newStore({
    schemaVersion = 2,
    revision = 7,
    completions = {},
    outfits = legacyOutfits,
})
local migrated = assert(Repository.open(migrationStore, 101))
eq(migrated:getState().outfitStorageSlotCount, 24, "migrated storage slot count")
eq(migrated:getState().outfitLegacyPresentedSlotCount, 12, "legacy presented slot count")
local migratedLegacy = assert(migrated:loadOutfit(12))
eq(migratedLegacy.OutfitName, "Legacy Slot Twelve", "legacy slot 12 migrated")
local migratedHidden = assert(migrated:loadOutfit(24))
eq(migratedHidden.OutfitName, "", "new storage slot 24 default name")
eq(migratedHidden.Hat1, 0, "new storage slot 24 default hat")

local hiddenOutfit = defaultOutfit()
hiddenOutfit.OutfitName = "Storage Twenty Four"
hiddenOutfit.Hat3 = 2400
local hiddenSave = migrated:saveOutfit(24, hiddenOutfit, "hidden-24")
eq(hiddenSave.status, "applied", "hidden slot save status")
eq(hiddenSave.durable, true, "hidden slot save durable")
eq(hiddenSave.revision, 8, "hidden slot save revision")

local migratedReopened = assert(Repository.open(migrationStore, 101))
local hiddenReload = assert(migratedReopened:loadOutfit(24))
eq(hiddenReload.OutfitName, "Storage Twenty Four", "hidden slot survives reopen")
eq(hiddenReload.Hat3, 2400, "hidden slot hat survives reopen")

local savesBeforeRetry = migrationStore.saves
local duplicateHidden = migratedReopened:saveOutfit(24, hiddenOutfit, "hidden-24")
eq(duplicateHidden.status, "duplicate", "same request retry status")
eq(duplicateHidden.durable, true, "same request retry durable")
eq(migrationStore.saves, savesBeforeRetry, "same request retry wrote again")

local changedHidden = clone(hiddenOutfit)
changedHidden.Hat3 = 2401
local requestConflict = migratedReopened:saveOutfit(24, changedHidden, "hidden-24")
eq(requestConflict.status, "conflict", "request-id payload conflict status")
eq(requestConflict.error, "OUTFIT_REQUEST_ID_CONFLICT", "request-id payload conflict code")
eq(migrationStore.saves, savesBeforeRetry, "request conflict wrote")

migrationStore.injectConflict = function(storeWithRace)
    local racedSnapshot = clone(storeWithRace.snapshot)
    racedSnapshot.revision = storeWithRace.version + 1
    racedSnapshot.outfits[1].OutfitName = "Concurrent Outfit"
    storeWithRace.snapshot = racedSnapshot
    storeWithRace.version = racedSnapshot.revision
end

local staleRetryOutfit = defaultOutfit()
staleRetryOutfit.OutfitName = "After Retry"
local staleRetry = migratedReopened:saveOutfit(2, staleRetryOutfit, "stale-retry-2")
eq(staleRetry.status, "applied", "stale outfit retry status")
eq(staleRetry.durable, true, "stale outfit retry durable")
eq(staleRetry.revision, 10, "stale outfit retry revision")
local afterStaleRetry = assert(Repository.open(migrationStore, 101))
eq(assert(afterStaleRetry:loadOutfit(1)).OutfitName, "Concurrent Outfit", "stale retry preserved concurrent write")
eq(assert(afterStaleRetry:loadOutfit(2)).OutfitName, "After Retry", "stale retry persisted requested outfit")

local staleStudioStore = StudioStore.new(studioBacking)
local _, staleVersion = staleStudioStore:read(101)
eq(staleVersion, 2, "studio read revision after outfit save")
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
