--!strict
-- Canonical exactly-once progression repository.
-- Owns progression state only; callers provide a versioned compare-and-swap adapter.

local Repository = {}
Repository.__index = Repository

local SCHEMA_VERSION = 2
local DEFAULT_MAX_RETRIES = 3

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function copyRecord(record)
    return {
        completionId = record.completionId,
        playerId = record.playerId,
        classId = record.classId,
        points = record.points,
        attempts = record.attempts,
        correct = record.correct,
    }
end

local function sameRecord(left, right)
    return left.completionId == right.completionId
        and left.playerId == right.playerId
        and left.classId == right.classId
        and left.points == right.points
        and left.attempts == right.attempts
        and left.correct == right.correct
end

local function validateRecord(record)
    if type(record) ~= "table" then return false, "INVALID_RECORD" end
    if type(record.completionId) ~= "string" or record.completionId == "" then return false, "INVALID_COMPLETION_ID" end
    if not isInteger(record.playerId) or record.playerId <= 0 then return false, "INVALID_PLAYER_ID" end
    if type(record.classId) ~= "string" or record.classId == "" then return false, "INVALID_CLASS_ID" end
    if not isInteger(record.points) or record.points < 0 then return false, "INVALID_POINTS" end
    if not isInteger(record.attempts) or record.attempts < 1 then return false, "INVALID_ATTEMPTS" end
    if type(record.correct) ~= "boolean" then return false, "INVALID_CORRECT" end
    return true
end

local OUTFIT_STORAGE_SLOT_COUNT = 24
local OUTFIT_LEGACY_SLOT_COUNT = 12

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
    local copy = defaultOutfit()
    if type(outfit) ~= "table" then return copy end
    for key, defaultValue in pairs(copy) do
        local value = outfit[key]
        if type(value) == type(defaultValue) then
            copy[key] = value
        end
    end
    return copy
end

local function defaultOutfits()
    local slots = {}
    for index = 1, OUTFIT_STORAGE_SLOT_COUNT do
        slots[index] = defaultOutfit()
    end
    return slots
end

local function validOutfit(outfit)
    if type(outfit) ~= "table" then return false end
    local defaults = defaultOutfit()
    for key, defaultValue in pairs(defaults) do
        if type(outfit[key]) ~= type(defaultValue) then return false end
        if type(defaultValue) == "number" and (outfit[key] < 0 or not isInteger(outfit[key])) then
            return false
        end
    end
    return true
end

local function outfitSlotCount(outfits)
    if type(outfits) ~= "table" then return 0 end
    local count = 0
    local maxIndex = 0
    for key in pairs(outfits) do
        if not isInteger(key) or key < 1 or key > OUTFIT_STORAGE_SLOT_COUNT then return -1 end
        count = count + 1
        if key > maxIndex then maxIndex = key end
    end
    if count ~= maxIndex then return -1 end
    return count
end

local function validOutfits(outfits)
    if outfits == nil then return true end
    if type(outfits) ~= "table" then return false end
    local count = outfitSlotCount(outfits)
    if count ~= OUTFIT_LEGACY_SLOT_COUNT and count ~= OUTFIT_STORAGE_SLOT_COUNT then
        return false
    end
    for index = 1, count do
        if not validOutfit(outfits[index]) then return false end
    end
    return true
end

local function normalizeOutfits(outfits)
    if outfits == nil then return defaultOutfits() end
    local result = {}
    for index = 1, OUTFIT_STORAGE_SLOT_COUNT do
        result[index] = copyOutfit(outfits[index])
    end
    return result
end

local function normalizeSaveRequestIds(values)
    local result = {}
    for index = 1, OUTFIT_STORAGE_SLOT_COUNT do
        local value = type(values) == "table" and values[index] or nil
        result[index] = type(value) == "string" and value or ""
    end
    return result
end

local function emptySnapshot()
    return {
        schemaVersion = SCHEMA_VERSION,
        revision = 0,
        completions = {},
        outfits = defaultOutfits(),
        outfitSaveRequestIds = normalizeSaveRequestIds(nil),
    }
end

local function validateSnapshot(snapshot, playerId)
    if type(snapshot) ~= "table"
        or snapshot.schemaVersion ~= SCHEMA_VERSION
        or not isInteger(snapshot.revision)
        or snapshot.revision < 0
        or type(snapshot.completions) ~= "table" then
        return false, "INVALID_SNAPSHOT"
    end
    if not validOutfits(snapshot.outfits) then
        return false, "INVALID_OUTFITS"
    end
    if snapshot.outfitSaveRequestIds ~= nil then
        if type(snapshot.outfitSaveRequestIds) ~= "table" then
            return false, "INVALID_OUTFIT_REQUEST_IDS"
        end
        for key, value in pairs(snapshot.outfitSaveRequestIds) do
            if not isInteger(key) or key < 1 or key > OUTFIT_STORAGE_SLOT_COUNT or type(value) ~= "string" then
                return false, "INVALID_OUTFIT_REQUEST_IDS"
            end
        end
    end

    local count = 0
    local maxIndex = 0
    local seen = {}
    for key in pairs(snapshot.completions) do
        if not isInteger(key) or key < 1 then
            return false, "INVALID_SNAPSHOT"
        end
        count = count + 1
        if key > maxIndex then maxIndex = key end
    end
    if count ~= maxIndex then return false, "INVALID_SNAPSHOT" end

    for _, record in ipairs(snapshot.completions) do
        local ok, err = validateRecord(record)
        if not ok then return false, err end
        if record.playerId ~= playerId then return false, "PLAYER_SCOPE_MISMATCH" end
        if seen[record.completionId] then return false, "DUPLICATE_COMPLETION_IN_SNAPSHOT" end
        seen[record.completionId] = true
    end

    return true
end

local function cloneSnapshot(snapshot)
    local completions = {}
    for index, record in ipairs(snapshot.completions) do
        completions[index] = copyRecord(record)
    end
    return {
        schemaVersion = SCHEMA_VERSION,
        revision = snapshot.revision,
        completions = completions,
        outfits = normalizeOutfits(snapshot.outfits),
        outfitSaveRequestIds = normalizeSaveRequestIds(snapshot.outfitSaveRequestIds),
    }
end

local function summarize(snapshot, playerId)
    local totalPoints = 0
    local classes = {}
    for _, record in ipairs(snapshot.completions) do
        totalPoints = totalPoints + record.points
        local item = classes[record.classId]
        if not item then
            item = { classId = record.classId, points = 0, completionCount = 0 }
            classes[record.classId] = item
        end
        item.points = item.points + record.points
        item.completionCount = item.completionCount + 1
    end

    local classList = {}
    for _, item in pairs(classes) do
        table.insert(classList, {
            classId = item.classId,
            points = item.points,
            completionCount = item.completionCount,
        })
    end
    table.sort(classList, function(a, b) return a.classId < b.classId end)

    return {
        playerId = playerId,
        revision = snapshot.revision,
        totalPoints = totalPoints,
        completionCount = #snapshot.completions,
        classes = classList,
        outfitStorageSlotCount = OUTFIT_STORAGE_SLOT_COUNT,
        outfitLegacyPresentedSlotCount = OUTFIT_LEGACY_SLOT_COUNT,
    }
end

local function readSnapshot(adapter, playerId)
    local snapshot, version, readError = adapter:read(playerId)
    if readError ~= nil then
        return nil, nil, "LOAD_FAILED:" .. tostring(readError)
    end

    if snapshot == nil then
        snapshot = emptySnapshot()
        version = 0
    end

    local valid, snapshotError = validateSnapshot(snapshot, playerId)
    if not valid then
        return nil, nil, snapshotError
    end
    if version ~= snapshot.revision then
        return nil, nil, "REVISION_MISMATCH"
    end

    return cloneSnapshot(snapshot), version, nil
end

local function apply(snapshot, record)
    local valid, recordError = validateRecord(record)
    if not valid then
        return nil, {
            status = "rejected",
            applied = false,
            durable = false,
            error = recordError,
        }
    end

    for _, prior in ipairs(snapshot.completions) do
        if prior.completionId == record.completionId then
            if sameRecord(prior, record) then
                return cloneSnapshot(snapshot), {
                    status = "duplicate",
                    applied = false,
                    durable = true,
                }
            end
            return nil, {
                status = "conflict",
                applied = false,
                durable = false,
                error = "COMPLETION_ID_CONFLICT",
            }
        end
    end

    local candidate = cloneSnapshot(snapshot)
    table.insert(candidate.completions, copyRecord(record))
    table.sort(candidate.completions, function(a, b)
        return a.completionId < b.completionId
    end)

    return candidate, {
        status = "applied",
        applied = true,
        durable = false,
    }
end

function Repository.open(adapter, playerId, options)
    if type(adapter) ~= "table"
        or type(adapter.read) ~= "function"
        or type(adapter.compareAndSwap) ~= "function" then
        return nil, "INVALID_ADAPTER"
    end
    if not isInteger(playerId) or playerId <= 0 then
        return nil, "INVALID_PLAYER_ID"
    end

    local snapshot, _, readError = readSnapshot(adapter, playerId)
    if not snapshot then
        return nil, readError
    end

    options = options or {}
    local maxRetries = options.maxRetries or DEFAULT_MAX_RETRIES
    if not isInteger(maxRetries) or maxRetries < 1 then
        return nil, "INVALID_MAX_RETRIES"
    end

    return setmetatable({
        _adapter = adapter,
        _playerId = playerId,
        _snapshot = snapshot,
        _maxRetries = maxRetries,
    }, Repository)
end

function Repository:getState()
    return summarize(self._snapshot, self._playerId)
end

function Repository:reload()
    local snapshot, _, readError = readSnapshot(self._adapter, self._playerId)
    if not snapshot then
        return false, readError
    end
    self._snapshot = snapshot
    return true
end

function Repository:record(record)
    if type(record) ~= "table" or record.playerId ~= self._playerId then
        return {
            status = "rejected",
            applied = false,
            durable = false,
            error = "PLAYER_SCOPE_MISMATCH",
        }
    end

    for _ = 1, self._maxRetries do
        local current, version, readError = readSnapshot(self._adapter, self._playerId)
        if not current then
            return {
                status = "rejected",
                applied = false,
                durable = false,
                error = readError,
            }
        end

        local candidate, receipt = apply(current, record)
        if receipt.status == "duplicate" then
            self._snapshot = current
            receipt.state = summarize(current, self._playerId)
            return receipt
        end
        if not candidate then
            return receipt
        end

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


local function validateStorageSlot(slot)
    return isInteger(slot) and slot >= 1 and slot <= OUTFIT_STORAGE_SLOT_COUNT
end

function Repository:loadOutfit(slot)
    if not validateStorageSlot(slot) then return nil, "INVALID_OUTFIT_SLOT" end
    return copyOutfit(self._snapshot.outfits[slot]), nil
end

function Repository:loadOutfitPage(startSlot)
    if not (startSlot == 1 or startSlot == 4 or startSlot == 7 or startSlot == 10) then
        return nil, "INVALID_OUTFIT_PAGE"
    end
    local page = {}
    for slot = startSlot, math.min(startSlot + 2, OUTFIT_LEGACY_SLOT_COUNT) do
        page[#page + 1] = {
            slot = slot,
            outfit = copyOutfit(self._snapshot.outfits[slot]),
        }
    end
    return page, nil
end

function Repository:saveOutfit(slot, outfit, requestId)
    if not validateStorageSlot(slot) then
        return { status = "rejected", durable = false, error = "INVALID_OUTFIT_SLOT" }
    end
    if not validOutfit(outfit) then
        return { status = "rejected", durable = false, error = "INVALID_OUTFIT" }
    end
    if type(requestId) ~= "string" or requestId == "" then
        return { status = "rejected", durable = false, error = "INVALID_REQUEST_ID" }
    end

    for _ = 1, self._maxRetries do
        local current, version, readError = readSnapshot(self._adapter, self._playerId)
        if not current then
            return { status = "rejected", durable = false, error = readError }
        end

        local priorRequestId = current.outfitSaveRequestIds[slot]
        if priorRequestId == requestId then
            local priorOutfit = current.outfits[slot]
            local same = true
            for field, value in pairs(outfit) do
                if priorOutfit[field] ~= value then same = false break end
            end
            if same then
                self._snapshot = current
                return {
                    status = "duplicate",
                    durable = true,
                    revision = version,
                    slot = slot,
                    outfit = copyOutfit(priorOutfit),
                }
            end
            return { status = "conflict", durable = false, error = "OUTFIT_REQUEST_ID_CONFLICT" }
        end

        local candidate = cloneSnapshot(current)
        candidate.outfits[slot] = copyOutfit(outfit)
        candidate.outfitSaveRequestIds[slot] = requestId
        candidate.revision = version + 1

        local saved, newVersion, saveError = self._adapter:compareAndSwap(
            self._playerId,
            version,
            cloneSnapshot(candidate)
        )

        if saved == true then
            if newVersion ~= candidate.revision then
                return { status = "rejected", durable = false, error = "SAVE_REVISION_MISMATCH" }
            end
            self._snapshot = candidate
            return {
                status = "applied",
                durable = true,
                revision = newVersion,
                slot = slot,
                outfit = copyOutfit(candidate.outfits[slot]),
            }
        end

        if saveError ~= "conflict" then
            return {
                status = "rejected",
                durable = false,
                error = "SAVE_FAILED:" .. tostring(saveError or "unknown"),
            }
        end
    end

    return { status = "rejected", durable = false, error = "STALE_WRITE_RETRY_EXHAUSTED" }
end

Repository.OUTFIT_STORAGE_SLOT_COUNT = OUTFIT_STORAGE_SLOT_COUNT
Repository.OUTFIT_LEGACY_SLOT_COUNT = OUTFIT_LEGACY_SLOT_COUNT

return Repository
