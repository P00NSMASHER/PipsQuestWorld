local Ledger = {}
Ledger.__index = Ledger

local SCHEMA_VERSION = 1

local function validRecord(r)
    if type(r) ~= "table" then return false, "INVALID_RECORD" end
    if type(r.completionId) ~= "string" or r.completionId == "" then return false, "INVALID_COMPLETION_ID" end
    if type(r.playerId) ~= "number" or r.playerId <= 0 or r.playerId % 1 ~= 0 then return false, "INVALID_PLAYER_ID" end
    if type(r.classId) ~= "string" or r.classId == "" then return false, "INVALID_CLASS_ID" end
    if type(r.score) ~= "number" or r.score < 0 or r.score ~= r.score or r.score == math.huge then return false, "INVALID_SCORE" end
    if type(r.completedAt) ~= "string" or r.completedAt == "" then return false, "INVALID_COMPLETED_AT" end
    return true
end

local function copy(r)
    return {
        completionId = r.completionId,
        playerId = r.playerId,
        classId = r.classId,
        score = r.score,
        completedAt = r.completedAt,
    }
end

local function same(a, b)
    return a.completionId == b.completionId
        and a.playerId == b.playerId
        and a.classId == b.classId
        and a.score == b.score
        and a.completedAt == b.completedAt
end

function Ledger.new()
    return setmetatable({ completions = {}, players = {} }, Ledger)
end

function Ledger:apply(record)
    local ok, err = validRecord(record)
    if not ok then
        return { status = "rejected", applied = false, error = err }
    end

    local prior = self.completions[record.completionId]
    if prior then
        if same(prior, record) then
            return { status = "duplicate", applied = false }
        end
        return { status = "conflict", applied = false, error = "COMPLETION_ID_CONFLICT" }
    end

    local key = tostring(record.playerId)
    local player = self.players[key]
    if not player then
        player = { playerId = record.playerId, totalScore = 0, completionCount = 0, classes = {} }
        self.players[key] = player
    end

    local class = player.classes[record.classId]
    if not class then
        class = { score = 0, completionCount = 0 }
        player.classes[record.classId] = class
    end

    self.completions[record.completionId] = copy(record)
    player.totalScore = player.totalScore + record.score
    player.completionCount = player.completionCount + 1
    class.score = class.score + record.score
    class.completionCount = class.completionCount + 1

    return {
        status = "applied",
        applied = true,
        totalScore = player.totalScore,
        completionCount = player.completionCount,
    }
end

function Ledger:getPlayerState(playerId)
    local player = self.players[tostring(playerId)]
    if not player then
        return { playerId = playerId, totalScore = 0, completionCount = 0, classes = {} }
    end

    local classes = {}
    for classId, state in pairs(player.classes) do
        table.insert(classes, {
            classId = classId,
            score = state.score,
            completionCount = state.completionCount,
        })
    end
    table.sort(classes, function(a, b) return a.classId < b.classId end)

    return {
        playerId = player.playerId,
        totalScore = player.totalScore,
        completionCount = player.completionCount,
        classes = classes,
    }
end

function Ledger:save()
    local records = {}
    for _, record in pairs(self.completions) do
        table.insert(records, copy(record))
    end
    table.sort(records, function(a, b) return a.completionId < b.completionId end)
    return { schemaVersion = SCHEMA_VERSION, completions = records }
end

function Ledger.restore(snapshot)
    if type(snapshot) ~= "table"
        or snapshot.schemaVersion ~= SCHEMA_VERSION
        or type(snapshot.completions) ~= "table" then
        return nil, "INVALID_SNAPSHOT"
    end

    local ledger = Ledger.new()
    local seen = {}
    local count = 0
    local maxIndex = 0

    for key in pairs(snapshot.completions) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return nil, "INVALID_SNAPSHOT"
        end
        count = count + 1
        if key > maxIndex then maxIndex = key end
    end
    if count ~= maxIndex then return nil, "INVALID_SNAPSHOT" end

    for _, record in ipairs(snapshot.completions) do
        local valid, recordError = validRecord(record)
        if not valid then
            return nil, recordError
        end
        if seen[record.completionId] then
            return nil, "DUPLICATE_COMPLETION_IN_SNAPSHOT"
        end
        seen[record.completionId] = true

        local receipt = ledger:apply(record)
        if receipt.status ~= "applied" then
            return nil, receipt.error or "SNAPSHOT_REPLAY_FAILED"
        end
    end

    return ledger
end

function Ledger.restoreOrDefault(snapshot)
    if snapshot == nil then
        return Ledger.new(), "default"
    end

    local ledger, err = Ledger.restore(snapshot)
    if not ledger then
        return nil, err
    end
    return ledger, "restored"
end

return Ledger
