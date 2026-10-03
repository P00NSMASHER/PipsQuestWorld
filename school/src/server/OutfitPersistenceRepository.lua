--!strict
-- Progression-owned durable outfit persistence prep.
-- Server-only state contract for the verified Legacy outfit fields; no UI/shop semantics.

local Repository = {}
Repository.__index = Repository

local SCHEMA_VERSION = 1
local STORAGE_SLOT_COUNT = 24
local LEGACY_STORED_SLOT_COUNT = 12
local OUTFIT_NAME_MAX_LENGTH = 25
local INVALID_NAME = "INVALID_NAME"
local DEFAULT_MAX_RETRIES = 3

local IDENTITY_FIELDS = { "OutfitName", "RPName", "RPDesc" }
local ASSET_FIELDS = { "Hat1", "Hat2", "Hat3", "Shirt", "Pants", "Face", "Package" }
local ALLOWED_FIELDS = {
    OutfitName = true,
    Hat1 = true,
    Hat2 = true,
    Hat3 = true,
    Shirt = true,
    Pants = true,
    Face = true,
    Package = true,
    RPName = true,
    RPDesc = true,
    RemoveShirt = true,
}
local FILTERED_FALLBACKS = {
    OutfitName = "Saved Outfit",
    RPName = "RP Name Here",
    RPDesc = "RP Desc Here",
}

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function textLength(value)
    local ok, count = pcall(utf8.len, value)
    if not ok or count == nil then return nil end
    return count
end

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

local function copyOutfit(outfit)
    return {
        OutfitName = outfit.OutfitName,
        Hat1 = outfit.Hat1,
        Hat2 = outfit.Hat2,
        Hat3 = outfit.Hat3,
        Shirt = outfit.Shirt,
        Pants = outfit.Pants,
        Face = outfit.Face,
        Package = outfit.Package,
        RPName = outfit.RPName,
        RPDesc = outfit.RPDesc,
        RemoveShirt = outfit.RemoveShirt,
    }
end

local function sameOutfit(left, right)
    for field in pairs(ALLOWED_FIELDS) do
        if left[field] ~= right[field] then return false end
    end
    return true
end

local function emptySlot()
    local slot = defaultOutfit()
    slot.occupied = false
    return slot
end

local function occupiedSlot(outfit)
    local slot = copyOutfit(outfit)
    slot.occupied = true
    return slot
end

local function copySlot(slot)
    local copy = copyOutfit(slot)
    copy.occupied = slot.occupied
    return copy
end

local function sameSlot(left, right)
    return left.occupied == right.occupied and sameOutfit(left, right)
end

local function validateOutfit(outfit)
    if type(outfit) ~= "table" then return false, "INVALID_OUTFIT" end
    for key in pairs(outfit) do
        if not ALLOWED_FIELDS[key] then return false, "UNEXPECTED_OUTFIT_FIELD" end
    end

    for _, field in ipairs(IDENTITY_FIELDS) do
        if type(outfit[field]) ~= "string" then return false, "INVALID_" .. string.upper(field) end
    end

    local nameLength = textLength(outfit.OutfitName)
    if nameLength == nil then return false, "INVALID_OUTFITNAME_UTF8" end
    if nameLength > OUTFIT_NAME_MAX_LENGTH then return false, "OUTFIT_NAME_TOO_LONG" end

    for _, field in ipairs(ASSET_FIELDS) do
        if not isInteger(outfit[field]) or outfit[field] < 0 then
            return false, "INVALID_" .. string.upper(field)
        end
    end

    if type(outfit.RemoveShirt) ~= "boolean" then return false, "INVALID_REMOVESHIRT" end
    return true
end

local function filterIdentity(outfit, playerId, filter)
    local candidate = copyOutfit(outfit)
    for _, field in ipairs(IDENTITY_FIELDS) do
        local ok, filtered = pcall(filter, playerId, field, candidate[field])
        if not ok or type(filtered) ~= "string" or filtered == "" or filtered == INVALID_NAME then
            filtered = FILTERED_FALLBACKS[field]
        end
        candidate[field] = filtered
    end

    local length = textLength(candidate.OutfitName)
    if length == nil then return nil, "INVALID_FILTERED_OUTFITNAME_UTF8" end
    if length > OUTFIT_NAME_MAX_LENGTH then return nil, "FILTERED_OUTFIT_NAME_TOO_LONG" end
    return candidate, nil
end

local function emptySnapshot()
    local slots = {}
    for index = 1, STORAGE_SLOT_COUNT do slots[index] = emptySlot() end
    return {
        schemaVersion = SCHEMA_VERSION,
        revision = 0,
        slots = slots,
        operations = {},
    }
end

local function copyOperation(operation)
    return {
        operationId = operation.operationId,
        slot = operation.slot,
        outfit = copyOutfit(operation.outfit),
    }
end

local function cloneSnapshot(snapshot)
    local slots = {}
    for index = 1, STORAGE_SLOT_COUNT do slots[index] = copySlot(snapshot.slots[index]) end
    local operations = {}
    for index, operation in ipairs(snapshot.operations) do operations[index] = copyOperation(operation) end
    return {
        schemaVersion = SCHEMA_VERSION,
        revision = snapshot.revision,
        slots = slots,
        operations = operations,
    }
end

local function validateArray(array)
    if type(array) ~= "table" then return false end
    local count = 0
    local maxIndex = 0
    for key in pairs(array) do
        if not isInteger(key) or key < 1 then return false end
        count = count + 1
        if key > maxIndex then maxIndex = key end
    end
    return count == maxIndex
end

local function validateSnapshot(snapshot)
    if type(snapshot) ~= "table"
        or snapshot.schemaVersion ~= SCHEMA_VERSION
        or not isInteger(snapshot.revision)
        or snapshot.revision < 0
        or not validateArray(snapshot.slots)
        or #snapshot.slots ~= STORAGE_SLOT_COUNT
        or not validateArray(snapshot.operations) then
        return false, "INVALID_SNAPSHOT"
    end

    local expectedSlots = {}
    for index = 1, STORAGE_SLOT_COUNT do
        local slot = snapshot.slots[index]
        if type(slot) ~= "table" or type(slot.occupied) ~= "boolean" then
            return false, "INVALID_SLOT"
        end
        local outfit = copyOutfit(slot)
        local ok, err = validateOutfit(outfit)
        if not ok then return false, err end
        if slot.occupied == false and not sameOutfit(outfit, defaultOutfit()) then
            return false, "NONDEFAULT_EMPTY_SLOT"
        end
        expectedSlots[index] = emptySlot()
    end

    local seenOperations = {}
    for _, operation in ipairs(snapshot.operations) do
        if type(operation) ~= "table"
            or type(operation.operationId) ~= "string"
            or operation.operationId == ""
            or not isInteger(operation.slot)
            or operation.slot < 1
            or operation.slot > STORAGE_SLOT_COUNT then
            return false, "INVALID_OPERATION"
        end
        if seenOperations[operation.operationId] then return false, "DUPLICATE_OPERATION_IN_SNAPSHOT" end
        seenOperations[operation.operationId] = true

        local ok, err = validateOutfit(operation.outfit)
        if not ok then return false, err end
        expectedSlots[operation.slot] = occupiedSlot(operation.outfit)
    end

    for index = 1, STORAGE_SLOT_COUNT do
        if not sameSlot(snapshot.slots[index], expectedSlots[index]) then
            return false, "SLOT_HISTORY_MISMATCH"
        end
    end

    return true
end

local function readSnapshot(adapter, playerId)
    local snapshot, version, readError = adapter:read(playerId)
    if readError ~= nil then return nil, nil, "LOAD_FAILED:" .. tostring(readError) end
    if snapshot == nil then
        snapshot = emptySnapshot()
        version = 0
    end
    local valid, snapshotError = validateSnapshot(snapshot)
    if not valid then return nil, nil, snapshotError end
    if version ~= snapshot.revision then return nil, nil, "REVISION_MISMATCH" end
    return cloneSnapshot(snapshot), version, nil
end

local function summarize(snapshot, playerId)
    local slots = {}
    for index = 1, STORAGE_SLOT_COUNT do slots[index] = copySlot(snapshot.slots[index]) end
    return {
        playerId = playerId,
        revision = snapshot.revision,
        storageSlotCount = STORAGE_SLOT_COUNT,
        legacyStoredSlotCount = LEGACY_STORED_SLOT_COUNT,
        slots = slots,
    }
end

local function sameOperation(operation, slot, outfit)
    return operation.slot == slot and sameOutfit(operation.outfit, outfit)
end

local function apply(snapshot, operationId, slot, outfit)
    for _, prior in ipairs(snapshot.operations) do
        if prior.operationId == operationId then
            if sameOperation(prior, slot, outfit) then
                return cloneSnapshot(snapshot), { status = "duplicate", applied = false, durable = true }
            end
            return nil, {
                status = "conflict",
                applied = false,
                durable = false,
                error = "OPERATION_ID_CONFLICT",
            }
        end
    end

    local candidate = cloneSnapshot(snapshot)
    candidate.slots[slot] = occupiedSlot(outfit)
    table.insert(candidate.operations, {
        operationId = operationId,
        slot = slot,
        outfit = copyOutfit(outfit),
    })
    return candidate, { status = "applied", applied = true, durable = false }
end

function Repository.open(adapter, playerId, options)
    if type(adapter) ~= "table"
        or type(adapter.read) ~= "function"
        or type(adapter.compareAndSwap) ~= "function" then
        return nil, "INVALID_ADAPTER"
    end
    if not isInteger(playerId) or playerId <= 0 then return nil, "INVALID_PLAYER_ID" end

    options = options or {}
    if type(options.filterIdentity) ~= "function" then return nil, "FILTER_IDENTITY_REQUIRED" end
    local maxRetries = options.maxRetries or DEFAULT_MAX_RETRIES
    if not isInteger(maxRetries) or maxRetries < 1 then return nil, "INVALID_MAX_RETRIES" end

    local snapshot, _, readError = readSnapshot(adapter, playerId)
    if not snapshot then return nil, readError end

    return setmetatable({
        _adapter = adapter,
        _playerId = playerId,
        _snapshot = snapshot,
        _filterIdentity = options.filterIdentity,
        _maxRetries = maxRetries,
    }, Repository)
end

function Repository:getState()
    return summarize(self._snapshot, self._playerId)
end

function Repository:reload()
    local snapshot, _, readError = readSnapshot(self._adapter, self._playerId)
    if not snapshot then return false, readError end
    self._snapshot = snapshot
    return true
end

function Repository:save(request)
    if type(request) ~= "table" or request.playerId ~= self._playerId then
        return { status = "rejected", applied = false, durable = false, error = "PLAYER_SCOPE_MISMATCH" }
    end
    if type(request.operationId) ~= "string" or request.operationId == "" then
        return { status = "rejected", applied = false, durable = false, error = "INVALID_OPERATION_ID" }
    end
    if not isInteger(request.slot) or request.slot < 1 or request.slot > STORAGE_SLOT_COUNT then
        return { status = "rejected", applied = false, durable = false, error = "INVALID_SLOT" }
    end

    local valid, outfitError = validateOutfit(request.outfit)
    if not valid then
        return { status = "rejected", applied = false, durable = false, error = outfitError }
    end

    local filteredOutfit, filterError = filterIdentity(
        request.outfit,
        self._playerId,
        self._filterIdentity
    )
    if not filteredOutfit then
        return { status = "rejected", applied = false, durable = false, error = filterError }
    end

    for _ = 1, self._maxRetries do
        local current, version, readError = readSnapshot(self._adapter, self._playerId)
        if not current then
            return { status = "rejected", applied = false, durable = false, error = readError }
        end

        local candidate, receipt = apply(current, request.operationId, request.slot, filteredOutfit)
        if receipt.status == "duplicate" then
            self._snapshot = current
            receipt.state = summarize(current, self._playerId)
            return receipt
        end
        if not candidate then return receipt end

        candidate.revision = version + 1
        local saved, newVersion, saveError = self._adapter:compareAndSwap(
            self._playerId,
            version,
            cloneSnapshot(candidate)
        )
        if saved == true then
            if newVersion ~= candidate.revision then
                return {
                    status = "rejected",
                    applied = false,
                    durable = false,
                    error = "SAVE_REVISION_MISMATCH",
                }
            end
            self._snapshot = candidate
            receipt.durable = true
            receipt.revision = newVersion
            receipt.state = summarize(candidate, self._playerId)
            return receipt
        end
        if saveError ~= "conflict" then
            return {
                status = "rejected",
                applied = false,
                durable = false,
                error = "SAVE_FAILED:" .. tostring(saveError or "unknown"),
            }
        end
    end

    return {
        status = "rejected",
        applied = false,
        durable = false,
        error = "STALE_WRITE_RETRY_EXHAUSTED",
    }
end

function Repository.migrateLegacySlots(legacySlots)
    if not validateArray(legacySlots) or #legacySlots ~= LEGACY_STORED_SLOT_COUNT then
        return nil, "INVALID_LEGACY_SLOTS"
    end

    local snapshot = emptySnapshot()
    for index = 1, LEGACY_STORED_SLOT_COUNT do
        local outfit = legacySlots[index]
        if outfit ~= false then
            local ok, err = validateOutfit(outfit)
            if not ok then return nil, err end
            snapshot.slots[index] = occupiedSlot(outfit)
            table.insert(snapshot.operations, {
                operationId = "migration:legacy-outfit:" .. tostring(index),
                slot = index,
                outfit = copyOutfit(outfit),
            })
        end
    end
    return snapshot, nil
end

function Repository.getContract()
    return {
        schemaVersion = SCHEMA_VERSION,
        storageSlotCount = STORAGE_SLOT_COUNT,
        legacyStoredSlotCount = LEGACY_STORED_SLOT_COUNT,
        outfitNameMaxLength = OUTFIT_NAME_MAX_LENGTH,
        invalidSentinel = INVALID_NAME,
        maxWornHats = 3,
        filteredFallbacks = {
            OutfitName = FILTERED_FALLBACKS.OutfitName,
            RPName = FILTERED_FALLBACKS.RPName,
            RPDesc = FILTERED_FALLBACKS.RPDesc,
        },
        defaultOutfit = defaultOutfit(),
    }
end

return Repository
