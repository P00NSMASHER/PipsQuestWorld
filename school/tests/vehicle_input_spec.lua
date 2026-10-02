local VehicleInput = assert(loadfile("school/src/server/VehicleInput.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local normal, normalError = VehicleInput.normalize(0.75, -0.5)
eq(normalError, nil, "normal input error")
eq(normal.throttle, 0.75, "normal throttle")
eq(normal.steer, -0.5, "normal steer")

local clamped = assert(VehicleInput.normalize(4, -9))
eq(clamped.throttle, 1, "high throttle clamp")
eq(clamped.steer, -1, "low steer clamp")

local zero = assert(VehicleInput.normalize(0, 0))
eq(zero.throttle, 0, "zero throttle")
eq(zero.steer, 0, "zero steer")

local invalidText, invalidTextCode = VehicleInput.normalize("1", 0)
eq(invalidText, nil, "text throttle accepted")
eq(invalidTextCode, "invalid_controls", "text throttle code")

local invalidNil, invalidNilCode = VehicleInput.normalize(0, nil)
eq(invalidNil, nil, "nil steer accepted")
eq(invalidNilCode, "invalid_controls", "nil steer code")

local nan = 0 / 0
local invalidNan, invalidNanCode = VehicleInput.normalize(nan, 0)
eq(invalidNan, nil, "NaN accepted")
eq(invalidNanCode, "invalid_controls", "NaN code")

local invalidInf, invalidInfCode = VehicleInput.normalize(math.huge, 0)
eq(invalidInf, nil, "infinity accepted")
eq(invalidInfCode, "invalid_controls", "infinity code")

print("HIGH_SCHOOL_VEHICLE_INPUT_PASS")
