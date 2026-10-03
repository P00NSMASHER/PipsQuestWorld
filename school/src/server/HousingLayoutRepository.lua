--!strict
-- Durable mutable housing-layout state.
-- Progression owns this repository/persistence contract; Free Roam supplies only
-- already-authorized, server-validated editor operations.

local Repository = {}
Repository.__index = Repository

local SCHEMA_VERSION = 1
local DEFAULT_MAX_RETRIES = 3
local DEFAULT_STYLE = "classic-blue"

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function isFiniteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function nonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

local function clone(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[clone(key)] = clone(child)
    end
    return result
end

local function emptySnapshot()
    return {
        schemaVersion = SCHEMA_VERSION,
        revision = 0,
        houseStyleId = DEFAULT_STYLE,
        hideWalls = false,
        operations = {},
        placements = {},
    }
end

local function validateArray(value)
    if type(value) ~= "table" then return false end
    local count = 0
    local maxIndex = 0
    for key in pairs(value) do
        if not isInteger(key) or key < 1 then
            return false
        end
        count = count + 1
        if key > maxIndex then
            maxIndex = key
        end
    end
    return count == maxIndex
end

local function validateTransform(operation)
    return isFiniteNumber(operation.x)
        and isFiniteNumber(operation.y)
        and isFiniteNumber(operation.z)
        and isFiniteNumber(operation.rotation)
end

local function validateOperation(operation)
    if type(operation) ~= "table" then return false, "INVALID_OPERATION" end
    if not nonEmptyString(operation.operationId) then return false, "INVALID_OPERATION_ID" end
    if not nonEmptyString(operation.kind) then return false, "INVALID_OPERATION_KIND" end

    local kind = operation.kind
    if kind == "set_house_style" then
        if not nonEmptyString(operation.styleId) then return false, "INVALID_STYLE_ID" end
    elseif kind == "set_hide_walls" then
        if type(operation.enabled) ~= "boolean" then return false, "INVALID_HIDE_WALLS" end
    elseif kind == "place_furniture" then
        if not nonEmptyString(operation.placementId) then return false, "INVALID_PLACEMENT_ID" end
        if not nonEmptyString(operation.itemId) then return false, "INVALID_ITEM_ID" end
        if not validateTransform(operation) then return false, "INVALID_TRANSFORM" end
        if operation.paintId ~= nil and not nonEmptyString(operation.paintId) then
            return false, "INVALID_PAINT_ID"
        end
    elseif kind == "move_furniture" then
        if not nonEmptyString(operation.placementId) then return false, "INVALID_PLACEMENT_ID" end
        if not validateTransform(operation) then return false, "INVALID_TRANSFORM" end
    elseif kind == "paint_furniture" then
        if not nonEmptyString(operation.placementId) then return false, "INVALID_PLACEMENT_ID" end
        if not nonEmptyString(operation.paintId) then return false, "INVALID_PAINT_ID" end
    elseif kind == "remove_furniture" then
        if not nonEmptyString(operation.placementId) then return false, "INVALID_PLACEMENT_ID" end
    else
        return false, "UNKNOWN_OPERATION_KIND"
    end

    return true
end

local function comparableOperation(operation)
    return {
        operationId = operation.operationId,
        kind = operation.kind,
        placementId = operation.placementId,
        itemId = operation.itemId,
        x = operation.x,
        y = operation.y,
        z = operation.z,
        rotation = operation.rotation,
        paintId = operation.paintId,
        styleId = operation.styleId,
        enabled = operation.enabled,
    }
end

local function sameOperation(left, right)
    local a = comparableOperation(left)
    local b = comparableOperation(right)
    for key, value in pairs(a) do
        if b[key] ~= value then return false end
    end
    for key, value in pairs(b) do
        if a[key] ~= value then return false end
    end
    return true
end

local function findPlacementIndex(snapshot, placementId)
    for index, placement in ipairs(snapshot.placements) do
        if placement.placementId == placementId then
            return index
        end
    end
    return nil
end

local function applyMutation(snapshot, operation)
    local kind = operation.kind
    if kind == "set_house_style" then
        snapshot.houseStyleId = operation.styleId
        return true, nil
    elseif kind == "set_hide_walls" then
        snapshot.hideWalls = operation.enabled
        return true, nil
    elseif kind == "place_furniture" then
        if findPlacementIndex(snapshot, operation.placementId) then
            return false, "PLACEMENT_ALREADY_EXISTS"
        end
        table.insert(snapshot.placements, {
            placementId = operation.placementId,
            itemId = operation.itemId,
            x = operation.x,
            y = operation.y,
            z = operation.z,
            rotation = operation.rotation,
            paintId = operation.paintId or "default",
        })
        return true, nil
    elseif kind == "move_furniture" then
        local index = findPlacementIndex(snapshot, operation.placementId)
        if not index then return false, "PLACEMENT_NOT_FOUND" end
        local placement = snapshot.placements[index]
        placement.x = operation.x
        placement.y = operation.y
        placement.z = operation.z
        placement.rotation = operation.rotation
        return true, nil
    elseif kind == "paint_furniture" then
        local index = findPlacementIndex(snapshot, operation.placementId)
        if not index then return false, "PLACEMENT_NOT_FOUND" end
        snapshot.placements[index].paintId = operation.paintId
        return true, nil
    elseif kind == "remove_furniture" then
        local index = findPlacementIndex(snapshot, operation.placementId)
        if not index then return false, "PLACEMENT_NOT_FOUND" end
        table.remove(snapshot.placements, index)
        return true, nil
    end
    return false, "UNKNOWN_OPERATION_KIND"
end

local function validatePlacement(placement)
    return type(placement) == "table"
        and nonEmptyString(placement.placementId)
        and nonEmptyString(placement.itemId)
        and isFiniteNumber(placement.x)
        and isFiniteNumber(placement.y)
        and isFiniteNumber(placement.z)
        and isFiniteNumber(placement.rotation)
        and nonEmptyString(placement.paintId)
end

local function canonicalPlacements(placements)
    local copy = clone(placements)
    table.sort(copy, function(a, b)
        return a.placementId < b.placementId
    end)
    return copy
end

local function samePlacement(left, right)
    return left.placementId == right.placementId
        and left.itemId == right.itemId
        and left.x == right.x
        and left.y == right.y
        and left.z == right.z
        and left.rotation == right.rotation
        and left.paintId == right.paintId
end

local function validateSnapshot(snapshot)
    if type(snapshot) ~= "table"
        or snapshot.schemaVersion ~= SCHEMA_VERSION
        or not isInteger(snapshot.revision)
        or snapshot.revision < 0
        or not nonEmptyString(snapshot.houseStyleId)
        or type(snapshot.hideWalls) ~= "boolean"
        or not validateArray(snapshot.operations)
        or not validateArray(snapshot.placements) then
        return false, "INVALID_SNAPSHOT"
    end

    local placementIds = {}
    for _, placement in ipairs(snapshot.placements) do
        if not validatePlacement(placement) then return false, "INVALID_PLACEMENT" end
        if placementIds[placement.placementId] then return false, "DUPLICATE_PLACEMENT" end
        placementIds[placement.placementId] = true
    end

    local replay = emptySnapshot()
    local seenOperations = {}
    for _, operation in ipairs(snapshot.operations) do
        local valid, operationError = validateOperation(operation)
        if not valid then return false, operationError end
        if seenOperations[operation.operationId] then return false, "DUPLICATE_OPERATION" end
        seenOperations[operation.operationId] = true
        local applied, applyError = applyMutation(replay, operation)
        if not applied then return false, applyError end
        table.insert(replay.operations, comparableOperation(operation))
    end

    if replay.houseStyleId ~= snapshot.houseStyleId
        or replay.hideWalls ~= snapshot.hideWalls then
        return false, "DERIVED_STATE_MISMATCH"
    end

    local expected = canonicalPlacements(replay.placements)
    local actual = canonicalPlacements(snapshot.placements)
    if #expected ~= #actual then return false, "PLACEMENT_COUNT_MISMATCH" end
    for index, placement in ipairs(expected) do
        if not samePlacement(placement, actual[index]) then
            return false, "PLACEMENT_STATE_MISMATCH"
        end
    end

    return true
end

local function summarize(snapshot)
    return {
        revision = snapshot.revision,
        houseStyleId = snapshot.houseStyleId,
        hideWalls = snapshot.hideWalls,
        operationCount = #snapshot.operations,
        placements = canonicalPlacements(snapshot.placements),
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
    local valid, snapshotError = validateSnapshot(snapshot)
    if not valid then return nil, nil, snapshotError end
    if version ~= snapshot.revision then return nil, nil, "REVISION_MISMATCH" end
    return clone(snapshot), version, nil
end

function Repository.open(adapter, playerId, options)
    if type(adapter) ~= "table"
        or type(adapter.read) ~= "function"
        or type(adapter.compareAndSwap) ~= "function" then
        return nil, "INVALID_ADAPTER"
    end
    if not isInteger(playerId) or playerId <= 0 then return nil, "INVALID_PLAYER_ID" end

    local snapshot, _, readError = readSnapshot(adapter, playerId)
    if not snapshot then return nil, readError end

    options = options or {}
    local maxRetries = options.maxRetries or DEFAULT_MAX_RETRIES
    if not isInteger(maxRetries) or maxRetries < 1 then return nil, "INVALID_MAX_RETRIES" end

    return setmetatable({
        _adapter = adapter,
        _playerId = playerId,
        _snapshot = snapshot,
        _maxRetries = maxRetries,
    }, Repository)
end

function Repository:getState()
    return summarize(self._snapshot)
end

function Repository:reload()
    local snapshot, _, readError = readSnapshot(self._adapter, self._playerId)
    if not snapshot then return false, readError end
    self._snapshot = snapshot
    return true
end

function Repository:commit(operation)
    local valid, operationError = validateOperation(operation)
    if not valid then
        return { status = "rejected", durable = false, error = operationError }
    end

    for _ = 1, self._maxRetries do
        local current, version, readError = readSnapshot(self._adapter, self._playerId)
        if not current then
            return { status = "rejected", durable = false, error = readError }
        end

        for _, prior in ipairs(current.operations) do
            if prior.operationId == operation.operationId then
                self._snapshot = current
                if sameOperation(prior, operation) then
                    return { status = "duplicate", durable = true, state = summarize(current) }
                end
                return { status = "conflict", durable = false, error = "OPERATION_ID_CONFLICT" }
            end
        end

        local candidate = clone(current)
        local applied, applyError = applyMutation(candidate, operation)
        if not applied then
            return { status = "rejected", durable = false, error = applyError }
        end
        table.insert(candidate.operations, comparableOperation(operation))
        candidate.revision = version + 1

        local saved, newVersion, saveError = self._adapter:compareAndSwap(
            self._playerId,
            version,
            clone(candidate)
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
                state = summarize(candidate),
            }
        end

        if saveError ~= "conflict" then
            return { status = "rejected", durable = false, error = "SAVE_FAILED:" .. tostring(saveError or "unknown") }
        end
    end

    return { status = "rejected", durable = false, error = "STALE_WRITE_RETRY_EXHAUSTED" }
end

return Repository
