local VehicleDynamics = assert(loadfile("school/src/server/VehicleDynamics.lua"))()

local function approx(actual, expected, tolerance, label)
    if math.abs(actual - expected) > tolerance then
        error(string.format(
            "%s: expected %.6f, got %.6f",
            label or "value",
            expected,
            actual
        ), 2)
    end
end

local function truthy(value, label)
    if not value then
        error(label or "expected truthy value", 2)
    end
end

local config = VehicleDynamics.DEFAULTS
local neutralHeading = 0.25

local forward = VehicleDynamics.step(config, {
    forwardSpeed = 0,
    lateralSpeed = 0,
    headingYaw = neutralHeading,
}, {
    throttle = 1,
    steer = 0,
}, 1 / 60)
approx(forward.forwardAcceleration, config.forwardAcceleration, 0.0001, "forward acceleration")
approx(forward.headingYaw, neutralHeading, 0.0001, "straight heading")

local reverse = VehicleDynamics.step(config, {
    forwardSpeed = 0,
    lateralSpeed = 0,
    headingYaw = 0,
}, {
    throttle = -1,
    steer = 0,
}, 1 / 60)
approx(reverse.forwardAcceleration, -config.reverseAcceleration, 0.0001, "reverse acceleration")

local coasting = VehicleDynamics.step(config, {
    forwardSpeed = 20,
    lateralSpeed = 0,
    headingYaw = 0,
}, {
    throttle = 0,
    steer = 0,
}, 1 / 60)
truthy(coasting.forwardAcceleration < 0, "coasting must slow forward travel")

local braking = VehicleDynamics.step(config, {
    forwardSpeed = 20,
    lateralSpeed = 0,
    headingYaw = 0,
}, {
    throttle = -1,
    steer = 0,
}, 1 / 60)
truthy(
    braking.forwardAcceleration < coasting.forwardAcceleration,
    "opposite throttle must brake harder than coasting"
)

local overspeed = VehicleDynamics.step(config, {
    forwardSpeed = config.maxForwardSpeed + 6,
    lateralSpeed = 0,
    headingYaw = 0,
}, {
    throttle = 1,
    steer = 0,
}, 1 / 60)
truthy(overspeed.forwardAcceleration < 0, "forward speed limit must decelerate")

local reverseOverspeed = VehicleDynamics.step(config, {
    forwardSpeed = -config.maxReverseSpeed - 4,
    lateralSpeed = 0,
    headingYaw = 0,
}, {
    throttle = -1,
    steer = 0,
}, 1 / 60)
truthy(reverseOverspeed.forwardAcceleration > 0, "reverse speed limit must decelerate")

local sliding = VehicleDynamics.step(config, {
    forwardSpeed = 12,
    lateralSpeed = -5,
    headingYaw = 0,
}, {
    throttle = 0,
    steer = 0,
}, 1 / 60)
truthy(sliding.lateralAcceleration > 0, "grip must oppose lateral slide")

local extreme = VehicleDynamics.step(config, {
    forwardSpeed = 1000,
    lateralSpeed = -1000,
    headingYaw = 0,
}, {
    throttle = -1,
    steer = 0,
}, 1 / 60)
approx(
    extreme.forwardAcceleration,
    -config.maximumLongitudinalAcceleration,
    0.0001,
    "bounded longitudinal acceleration"
)
approx(
    extreme.lateralAcceleration,
    config.maximumLateralAcceleration,
    0.0001,
    "bounded lateral acceleration"
)

local rightTurn = VehicleDynamics.step(config, {
    forwardSpeed = 18,
    lateralSpeed = 0,
    headingYaw = 0,
}, {
    throttle = 1,
    steer = 1,
}, 0.1)
truthy(rightTurn.yawRate < 0, "right steering must turn right while moving forward")
truthy(rightTurn.headingYaw < 0, "right steering must advance rightward heading")

local reverseRight = VehicleDynamics.step(config, {
    forwardSpeed = -12,
    lateralSpeed = 0,
    headingYaw = 0,
}, {
    throttle = -1,
    steer = 1,
}, 0.1)
truthy(reverseRight.yawRate > 0, "steering direction must invert in reverse")

local parkedTurn = VehicleDynamics.step(config, {
    forwardSpeed = 0,
    lateralSpeed = 0,
    headingYaw = 0,
}, {
    throttle = 0,
    steer = 1,
}, 0.1)
approx(parkedTurn.yawRate, 0, 0.0001, "parked steering")

local bounded = VehicleDynamics.step(config, {
    forwardSpeed = 18,
    lateralSpeed = 0,
    headingYaw = 0,
}, {
    throttle = 1,
    steer = 1,
}, 4)
approx(bounded.dt, config.maximumStep, 0.0001, "bounded step")
truthy(math.abs(bounded.headingYaw) < math.pi, "heading must stay normalized")

print("HIGH_SCHOOL_VEHICLE_DYNAMICS_PASS")
