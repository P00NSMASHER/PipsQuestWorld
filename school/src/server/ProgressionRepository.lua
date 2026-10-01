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

local function emptySnapshot()
    return {
        schemaVersion = SCHEMA_VERSION,
        revision = 0,
        completions = {},
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

return Repository
