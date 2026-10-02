--!strict
-- Canonical Pip High economy/ownership repository.
-- Owns money + durable unlock state only; gameplay systems submit idempotent operations.

local Repository = {}
Repository.__index = Repository

local SCHEMA_VERSION = 1
local DEFAULT_MAX_RETRIES = 3

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function copyUnlock(unlock)
    if unlock == nil then return nil end
    return {
        category = unlock.category,
        itemId = unlock.itemId,
    }
end

local function copyOperation(operation)
    return {
        operationId = operation.operationId,
        playerId = operation.playerId,
        delta = operation.delta,
        reason = operation.reason,
        unlock = copyUnlock(operation.unlock),
    }
end

local function sameUnlock(left, right)
    if left == nil or right == nil then
        return left == right
    end
    return left.category == right.category and left.itemId == right.itemId
end

local function sameOperation(left, right)
    return left.operationId == right.operationId
        and left.playerId == right.playerId
        and left.delta == right.delta
        and left.reason == right.reason
        and sameUnlock(left.unlock, right.unlock)
end

local function validateUnlock(unlock)
    if type(unlock) ~= "table" then return false, "INVALID_UNLOCK" end
    if type(unlock.category) ~= "string" or unlock.category == "" then return false, "INVALID_UNLOCK_CATEGORY" end
    if type(unlock.itemId) ~= "string" or unlock.itemId == "" then return false, "INVALID_UNLOCK_ITEM_ID" end
    return true
end

local function validateOperation(operation)
    if type(operation) ~= "table" then return false, "INVALID_OPERATION" end
    if type(operation.operationId) ~= "string" or operation.operationId == "" then return false, "INVALID_OPERATION_ID" end
    if not isInteger(operation.playerId) or operation.playerId <= 0 then return false, "INVALID_PLAYER_ID" end
    if not isInteger(operation.delta) then return false, "INVALID_DELTA" end
    if type(operation.reason) ~= "string" or operation.reason == "" then return false, "INVALID_REASON" end
    if operation.unlock ~= nil then
        local ok, err = validateUnlock(operation.unlock)
        if not ok then return false, err end
    end
    if operation.delta == 0 and operation.unlock == nil then return false, "EMPTY_OPERATION" end
    return true
end

local function emptySnapshot()
    return {
        schemaVersion = SCHEMA_VERSION,
        revision = 0,
        balance = 0,
        operations = {},
        ownership = {},
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

local function ownershipKey(unlock)
    return unlock.category .. ":" .. unlock.itemId
end

local function validateSnapshot(snapshot, playerId)
    if type(snapshot) ~= "table"
        or snapshot.schemaVersion ~= SCHEMA_VERSION
        or not isInteger(snapshot.revision)
        or snapshot.revision < 0
        or not isInteger(snapshot.balance)
        or snapshot.balance < 0
        or not validateArray(snapshot.operations)
        or not validateArray(snapshot.ownership) then
        return false, "INVALID_SNAPSHOT"
    end

    local seenOperations = {}
    local expectedBalance = 0
    local expectedOwnership = {}

    for _, operation in ipairs(snapshot.operations) do
        local ok, err = validateOperation(operation)
        if not ok then return false, err end
        if operation.playerId ~= playerId then return false, "PLAYER_SCOPE_MISMATCH" end
        if seenOperations[operation.operationId] then return false, "DUPLICATE_OPERATION_IN_SNAPSHOT" end
        seenOperations[operation.operationId] = true
        expectedBalance = expectedBalance + operation.delta
        if expectedBalance < 0 then return false, "INVALID_BALANCE_HISTORY" end
        if operation.unlock ~= nil then
            local key = ownershipKey(operation.unlock)
            if expectedOwnership[key] then return false, "DUPLICATE_UNLOCK_IN_SNAPSHOT" end
            expectedOwnership[key] = true
        end
    end

    if expectedBalance ~= snapshot.balance then return false, "BALANCE_MISMATCH" end

    local seenOwnership = {}
    for _, unlock in ipairs(snapshot.ownership) do
        local ok, err = validateUnlock(unlock)
        if not ok then return false, err end
        local key = ownershipKey(unlock)
        if seenOwnership[key] then return false, "DUPLICATE_OWNERSHIP_IN_SNAPSHOT" end
        seenOwnership[key] = true
        if not expectedOwnership[key] then return false, "OWNERSHIP_HISTORY_MISMATCH" end
    end

    for key in pairs(expectedOwnership) do
        if not seenOwnership[key] then return false, "OWNERSHIP_HISTORY_MISMATCH" end
    end

    return true
end

local function cloneSnapshot(snapshot)
    local operations = {}
    for index, operation in ipairs(snapshot.operations) do
        operations[index] = copyOperation(operation)
    end
    local ownership = {}
    for index, unlock in ipairs(snapshot.ownership) do
        ownership[index] = copyUnlock(unlock)
    end
    return {
        schemaVersion = SCHEMA_VERSION,
        revision = snapshot.revision,
        balance = snapshot.balance,
        operations = operations,
        ownership = ownership,
    }
end

local function summarize(snapshot, playerId)
    local ownership = {}
    for index, unlock in ipairs(snapshot.ownership) do
        ownership[index] = copyUnlock(unlock)
    end
    table.sort(ownership, function(a, b)
        if a.category == b.category then return a.itemId < b.itemId end
        return a.category < b.category
    end)
    return {
        playerId = playerId,
        revision = snapshot.revision,
        balance = snapshot.balance,
        operationCount = #snapshot.operations,
        ownership = ownership,
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
    if not valid then return nil, nil, snapshotError end
    if version ~= snapshot.revision then return nil, nil, "REVISION_MISMATCH" end
    return cloneSnapshot(snapshot), version, nil
end

local function owns(snapshot, unlock)
    local key = ownershipKey(unlock)
    for _, prior in ipairs(snapshot.ownership) do
        if ownershipKey(prior) == key then return true end
    end
    return false
end

local function apply(snapshot, operation)
    local valid, operationError = validateOperation(operation)
    if not valid then
        return nil, { status = "rejected", applied = false, durable = false, error = operationError }
    end

    for _, prior in ipairs(snapshot.operations) do
        if prior.operationId == operation.operationId then
            if sameOperation(prior, operation) then
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

    if operation.unlock ~= nil and owns(snapshot, operation.unlock) then
        return nil, {
            status = "rejected",
            applied = false,
            durable = false,
            error = "ALREADY_OWNED",
        }
    end

    local nextBalance = snapshot.balance + operation.delta
    if nextBalance < 0 then
        return nil, {
            status = "rejected",
            applied = false,
            durable = false,
            error = "INSUFFICIENT_FUNDS",
        }
    end

    local candidate = cloneSnapshot(snapshot)
    candidate.balance = nextBalance
    -- Preserve durable commit order. operationId is an idempotency key, not
    -- transaction chronology; reordering by ID can turn a valid credit-then-debit
    -- history into debit-first history and make the persisted snapshot unreopenable.
    table.insert(candidate.operations, copyOperation(operation))

    if operation.unlock ~= nil then
        table.insert(candidate.ownership, copyUnlock(operation.unlock))
        table.sort(candidate.ownership, function(a, b)
            if a.category == b.category then return a.itemId < b.itemId end
            return a.category < b.category
        end)
    end

    return candidate, { status = "applied", applied = true, durable = false }
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
    return summarize(self._snapshot, self._playerId)
end

function Repository:reload()
    local snapshot, _, readError = readSnapshot(self._adapter, self._playerId)
    if not snapshot then return false, readError end
    self._snapshot = snapshot
    return true
end

function Repository:record(operation)
    if type(operation) ~= "table" or operation.playerId ~= self._playerId then
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
            return { status = "rejected", applied = false, durable = false, error = readError }
        end

        local candidate, receipt = apply(current, operation)
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

return Repository
