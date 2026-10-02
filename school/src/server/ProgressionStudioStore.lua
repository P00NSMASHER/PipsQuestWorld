--!strict
-- Local-only versioned persistence adapter for unpublished Roblox Studio sessions.
-- Production never selects this adapter; ClassEducation uses it only when
-- RunService:IsStudio() and game.GameId == 0.

local StudioStore = {}
StudioStore.__index = StudioStore

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

function StudioStore.new(backing)
    return setmetatable({
        _backing = backing or {},
    }, StudioStore)
end

function StudioStore:read(playerId)
    local row = self._backing[tostring(playerId)]
    if not row then
        return nil, 0, nil
    end
    return clone(row.snapshot), row.version, nil
end

function StudioStore:compareAndSwap(playerId, expectedVersion, snapshot)
    if type(snapshot) ~= "table" or type(snapshot.revision) ~= "number" then
        return false, nil, "invalid_snapshot"
    end

    local key = tostring(playerId)
    local row = self._backing[key]
    local currentVersion = row and row.version or 0
    if currentVersion ~= expectedVersion then
        return false, nil, "conflict"
    end
    if snapshot.revision ~= expectedVersion + 1 then
        return false, nil, "invalid_revision"
    end

    self._backing[key] = {
        version = snapshot.revision,
        snapshot = clone(snapshot),
    }
    return true, snapshot.revision, nil
end

return StudioStore
