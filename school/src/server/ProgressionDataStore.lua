--!strict
-- Roblox DataStore adapter for ProgressionRepository's versioned compare-and-swap contract.

local ProgressionDataStore = {}
ProgressionDataStore.__index = ProgressionDataStore

local function keyFor(playerId)
    return "player:" .. tostring(playerId)
end

local function clone(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = clone(child)
    end
    return result
end

function ProgressionDataStore.new(dataStore)
    assert(type(dataStore) == "userdata" or type(dataStore) == "table", "dataStore is required")
    return setmetatable({ _dataStore = dataStore }, ProgressionDataStore)
end

function ProgressionDataStore:read(playerId)
    local ok, result = pcall(function()
        return self._dataStore:GetAsync(keyFor(playerId))
    end)
    if not ok then
        return nil, nil, tostring(result)
    end
    if result == nil then
        return nil, 0, nil
    end
    if type(result) ~= "table" or type(result.revision) ~= "number" then
        return nil, nil, "INVALID_STORED_VALUE"
    end
    return clone(result), result.revision, nil
end

function ProgressionDataStore:compareAndSwap(playerId, expectedVersion, snapshot)
    local conflict = false
    local ok, result = pcall(function()
        return self._dataStore:UpdateAsync(keyFor(playerId), function(current)
            local currentVersion = 0
            if current ~= nil then
                if type(current) ~= "table" or type(current.revision) ~= "number" then
                    conflict = true
                    return nil
                end
                currentVersion = current.revision
            end

            if currentVersion ~= expectedVersion then
                conflict = true
                return nil
            end

            local nextValue = clone(snapshot)
            nextValue.revision = expectedVersion + 1
            return nextValue
        end)
    end)

    if not ok then
        return false, nil, tostring(result)
    end
    if conflict or result == nil then
        return false, nil, "conflict"
    end
    return true, result.revision, nil
end

return ProgressionDataStore
