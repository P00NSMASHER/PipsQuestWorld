--!strict
-- Pure vehicle lifecycle authority for Pip High Free Roam.
-- Owns one-active-vehicle-per-player state only; Roblox instances/physics live in the server adapter.

local VehicleLifecycle = {}
VehicleLifecycle.__index = VehicleLifecycle

local function validKey(value)
    return type(value) == "string" and value ~= ""
end

local function copy(record)
    if not record then return nil end
    return {
        playerKey = record.playerKey,
        vehicleId = record.vehicleId,
        token = record.token,
    }
end

function VehicleLifecycle.new()
    return setmetatable({
        _active = {},
        _nextToken = 0,
    }, VehicleLifecycle)
end

function VehicleLifecycle:get(playerKey)
    assert(validKey(playerKey), "playerKey must be a non-empty string")
    return copy(self._active[playerKey])
end

function VehicleLifecycle:spawn(playerKey, vehicleId)
    assert(validKey(playerKey), "playerKey must be a non-empty string")
    assert(validKey(vehicleId), "vehicleId must be a non-empty string")

    local current = self._active[playerKey]
    if current then
        return {
            accepted = false,
            code = "vehicle_already_active",
            state = copy(current),
        }
    end

    self._nextToken = self._nextToken + 1
    local record = {
        playerKey = playerKey,
        vehicleId = vehicleId,
        token = playerKey .. "|" .. tostring(self._nextToken),
    }
    self._active[playerKey] = record

    return {
        accepted = true,
        code = "vehicle_spawn_reserved",
        state = copy(record),
    }
end

function VehicleLifecycle:despawn(playerKey, expectedToken)
    assert(validKey(playerKey), "playerKey must be a non-empty string")
    local current = self._active[playerKey]
    if not current then
        return {
            accepted = true,
            code = "vehicle_already_despawned",
            state = nil,
        }
    end

    if expectedToken ~= nil and expectedToken ~= current.token then
        return {
            accepted = false,
            code = "stale_vehicle_token",
            state = copy(current),
        }
    end

    self._active[playerKey] = nil
    return {
        accepted = true,
        code = "vehicle_despawned",
        state = nil,
        released = copy(current),
    }
end

return VehicleLifecycle
