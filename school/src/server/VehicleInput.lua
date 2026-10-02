--!strict
-- Pure validation for owner vehicle controls.
-- Clients may request throttle/steer intent only; the server remains movement authority.

local VehicleInput = {}

local function finiteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function clampUnit(value)
    if value > 1 then
        return 1
    end
    if value < -1 then
        return -1
    end
    return value
end

function VehicleInput.normalize(throttle, steer)
    if not finiteNumber(throttle) or not finiteNumber(steer) then
        return nil, "invalid_controls"
    end

    return {
        throttle = clampUnit(throttle),
        steer = clampUnit(steer),
    }, nil
end

return VehicleInput
