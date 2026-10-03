local Repository = assert(loadfile("school/src/server/OutfitPersistenceRepository.lua"))()

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
            if self.failSave then return false, nil, "injected" end
            if self.injectConflict then
                local hook = self.injectConflict
                self.injectConflict = nil
                hook(self)
            end
            if self.version ~= expectedVersion then return false, nil, "conflict" end
            self.snapshot = clone(snapshot)
            self.version = snapshot.revision
            self.saves = self.saves + 1
            return true, self.version, nil
        end,
    }
end

local function outfit(overrides)
    local value = {
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
    for key, child in pairs(overrides or {}) do value[key] = child end
    return value
end

local function filterIdentity(_playerId, _field, value)
    if value == "blocked" then return "INVALID_NAME" end
    if value == "empty" then return "" end
    if value == "error" then error("injected filter failure") end
    return "filtered:" .. value
end

local function open(store)
    return Repository.open(store, 101, { filterIdentity = filterIdentity })
end

local contract = Repository.getContract()
eq(contract.schemaVersion, 1, "schema version")
eq(contract.storageSlotCount, 24, "storage slots")
eq(contract.legacyStoredSlotCount, 12, "legacy stored slots")
eq(contract.outfitNameMaxLength, 25, "outfit name max")
eq(contract.invalidSentinel, "INVALID_NAME", "invalid sentinel")
eq(contract.maxWornHats, 3, "max worn hats")
eq(contract.defaultOutfit.OutfitName, "", "default outfit name")
eq(contract.defaultOutfit.Hat1, 0, "default Hat1")
eq(contract.defaultOutfit.Hat2, 0, "default Hat2")
eq(contract.defaultOutfit.Hat3, 0, "default Hat3")
eq(contract.defaultOutfit.RemoveShirt, false, "default remove shirt")
eq(contract.filteredFallbacks.OutfitName, "Saved Outfit", "outfit fallback")
eq(contract.filteredFallbacks.RPName, "RP Name Here", "RP name fallback")
eq(contract.filteredFallbacks.RPDesc, "RP Desc Here", "RP desc fallback")

local missingFilterRepo, missingFilterError = Repository.open(newStore(nil), 101)
eq(missingFilterRepo, nil, "missing filter repo")
eq(missingFilterError, "FILTER_IDENTITY_REQUIRED", "missing filter error")

local store = newStore(nil)
local repo = assert(open(store))
local initial = repo:getState()
eq(initial.playerId, 101, "initial player")
eq(initial.revision, 0, "initial revision")
eq(initial.storageSlotCount, 24, "initial storage count")
eq(#initial.slots, 24, "initial slot array size")
eq(initial.slots[1].occupied, false, "initial slot occupied")
eq(initial.slots[24].occupied, false, "last slot occupied")

local primary = outfit({
    OutfitName = "Primary",
    Hat1 = 11,
    Hat2 = 12,
    Hat3 = 13,
    Shirt = 21,
    Pants = 22,
    Face = 23,
    Package = 24,
    RPName = "Jamie",
    RPDesc = "Student",
    RemoveShirt = true,
})
local request = {
    operationId = "outfit:save:slot-1:v1",
    playerId = 101,
    slot = 1,
    outfit = primary,
}
local first = repo:save(request)
eq(first.status, "applied", "first save status")
eq(first.durable, true, "first save durable")
eq(first.revision, 1, "first save revision")
eq(first.state.slots[1].occupied, true, "first slot occupied")
eq(first.state.slots[1].OutfitName, "filtered:Primary", "server-filtered outfit name")
eq(first.state.slots[1].RPName, "filtered:Jamie", "server-filtered RP name")
eq(first.state.slots[1].RPDesc, "filtered:Student", "server-filtered RP desc")
eq(first.state.slots[1].Hat3, 13, "third hat persisted")
eq(first.state.slots[1].Package, 24, "package persisted")
eq(first.state.slots[1].RemoveShirt, true, "remove shirt persisted")
eq(store.saves, 1, "first save count")

local duplicate = repo:save(request)
eq(duplicate.status, "duplicate", "duplicate status")
eq(duplicate.durable, true, "duplicate durable")
eq(store.saves, 1, "duplicate wrote again")

local changed = clone(request)
changed.outfit.Shirt = 99
local conflict = repo:save(changed)
eq(conflict.status, "conflict", "operation conflict status")
eq(conflict.error, "OPERATION_ID_CONFLICT", "operation conflict error")
eq(store.saves, 1, "conflict wrote")

local reopened = assert(open(store))
eq(reopened:getState().revision, 1, "rejoin revision")
eq(reopened:getState().slots[1].Shirt, 21, "rejoin shirt")
eq(reopened:getState().slots[1].OutfitName, "filtered:Primary", "rejoin filtered name")

local mutableCopy = reopened:getState()
mutableCopy.slots[1].Shirt = 999
mutableCopy.slots[1].OutfitName = "tampered"
eq(reopened:getState().slots[1].Shirt, 21, "read-only snapshot shirt")
eq(reopened:getState().slots[1].OutfitName, "filtered:Primary", "read-only snapshot name")

local unexpected = outfit({ OutfitName = "Bad" })
unexpected.Hat4 = 44
local unexpectedResult = reopened:save({
    operationId = "outfit:bad:hat4",
    playerId = 101,
    slot = 2,
    outfit = unexpected,
})
eq(unexpectedResult.status, "rejected", "unexpected field status")
eq(unexpectedResult.error, "UNEXPECTED_OUTFIT_FIELD", "unexpected field error")

local longName = reopened:save({
    operationId = "outfit:bad:long-name",
    playerId = 101,
    slot = 2,
    outfit = outfit({ OutfitName = string.rep("x", 26) }),
})
eq(longName.status, "rejected", "long name status")
eq(longName.error, "OUTFIT_NAME_TOO_LONG", "long name error")

local badSlot = reopened:save({
    operationId = "outfit:bad:slot",
    playerId = 101,
    slot = 25,
    outfit = outfit({ OutfitName = "Bad Slot" }),
})
eq(badSlot.status, "rejected", "bad slot status")
eq(badSlot.error, "INVALID_SLOT", "bad slot error")

local wrongPlayer = reopened:save({
    operationId = "outfit:bad:player",
    playerId = 202,
    slot = 2,
    outfit = outfit({ OutfitName = "Wrong Player" }),
})
eq(wrongPlayer.status, "rejected", "wrong player status")
eq(wrongPlayer.error, "PLAYER_SCOPE_MISMATCH", "wrong player error")

local fallback = reopened:save({
    operationId = "outfit:save:slot-2:fallback",
    playerId = 101,
    slot = 2,
    outfit = outfit({
        OutfitName = "blocked",
        RPName = "empty",
        RPDesc = "error",
    }),
})
eq(fallback.status, "applied", "fallback save status")
eq(fallback.state.slots[2].OutfitName, "Saved Outfit", "blocked outfit fallback")
eq(fallback.state.slots[2].RPName, "RP Name Here", "empty RP name fallback")
eq(fallback.state.slots[2].RPDesc, "RP Desc Here", "filter error RP desc fallback")

store.injectConflict = function(s)
    local external = outfit({
        OutfitName = "filtered:External",
        Shirt = 303,
        RPName = "filtered:External RP",
        RPDesc = "filtered:External Desc",
    })
    s.snapshot.revision = s.version + 1
    s.snapshot.slots[3] = clone(external)
    s.snapshot.slots[3].occupied = true
    table.insert(s.snapshot.operations, {
        operationId = "external:slot-3",
        slot = 3,
        outfit = clone(external),
    })
    s.version = s.snapshot.revision
end

local raced = reopened:save({
    operationId = "outfit:save:slot-4:race",
    playerId = 101,
    slot = 4,
    outfit = outfit({ OutfitName = "Race", Shirt = 404 }),
})
eq(raced.status, "applied", "raced save status")
eq(raced.durable, true, "raced save durable")
eq(raced.state.slots[3].Shirt, 303, "raced lost concurrent outfit")
eq(raced.state.slots[4].Shirt, 404, "raced own outfit")
eq(raced.state.slots[4].OutfitName, "filtered:Race", "raced filtered name")

local afterRace = assert(open(store))
eq(afterRace:getState().slots[3].Shirt, 303, "rejoin concurrent outfit")
eq(afterRace:getState().slots[4].Shirt, 404, "rejoin raced outfit")

store.failSave = true
local beforeFailedRevision = afterRace:getState().revision
local failed = afterRace:save({
    operationId = "outfit:save:slot-5:failed",
    playerId = 101,
    slot = 5,
    outfit = outfit({ OutfitName = "Failure", Shirt = 505 }),
})
eq(failed.status, "rejected", "save failure status")
eq(failed.durable, false, "save failure durable")
eq(failed.error, "SAVE_FAILED:injected", "save failure error")
eq(afterRace:getState().revision, beforeFailedRevision, "failed save mutated local revision")
eq(afterRace:getState().slots[5].occupied, false, "failed save mutated local slot")
store.failSave = false

local legacySlots = {}
for index = 1, 12 do legacySlots[index] = false end
legacySlots[1] = outfit({
    OutfitName = "Legacy One",
    Hat1 = 1,
    Shirt = 2,
    Pants = 3,
    RPName = "Legacy RP",
    RPDesc = "Legacy Desc",
})
legacySlots[12] = outfit({ OutfitName = "Legacy Twelve", Face = 12 })

local migrated, migrationError = Repository.migrateLegacySlots(legacySlots)
assert(migrated, "legacy migration failed: " .. tostring(migrationError))
eq(migrated.schemaVersion, 1, "migrated schema")
eq(#migrated.slots, 24, "migrated slot count")
eq(migrated.slots[1].occupied, true, "migrated first slot")
eq(migrated.slots[12].occupied, true, "migrated twelfth slot")
eq(migrated.slots[13].occupied, false, "migration extended slot 13")
eq(migrated.slots[24].occupied, false, "migration extended slot 24")

local migratedStore = newStore(migrated)
local migratedRepo = assert(open(migratedStore))
eq(migratedRepo:getState().slots[1].OutfitName, "Legacy One", "migrated first name")
eq(migratedRepo:getState().slots[12].Face, 12, "migrated twelfth face")
eq(migratedRepo:getState().slots[13].occupied, false, "migrated hidden storage remains empty")

local sourceFile = assert(io.open("school/src/server/OutfitPersistenceRepository.lua", "r"))
local source = sourceFile:read("*a")
sourceFile:close()
for _, forbidden in ipairs({
    "EconomyRepository",
    "PurchasePermanentItem",
    "RemoteEvent",
    "RemoteFunction",
    "TextButton",
    "ScreenGui",
    "DataStoreService",
}) do
    if source:find(forbidden, 1, true) then
        error("outfit persistence prep crossed ownership boundary: " .. forbidden, 2)
    end
end

print("HIGH_SCHOOL_OUTFIT_PERSISTENCE_REPOSITORY_PASS")
