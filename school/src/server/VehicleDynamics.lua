--!strict
-- Pure, deterministic planar vehicle dynamics for the server vehicle adapter.
-- This module deliberately has no Roblox dependencies so its safety and handling
-- rules can be exercised by the command-line spec suite.

local VehicleDynamics = {}

VehicleDynamics.DEFAULTS = {
    maxForwardSpeed = 46,
    maxReverseSpeed = 18,
    forwardAcceleration = 34,
    reverseAcceleration = 22,
    coastResponse = 2.1,
    brakingResponse = 8.5,
    overspeedResponse = 6,
    lateralGrip = 8,
    maximumLongitudinalAcceleration = 64,
    maximumLateralAcceleration = 64,
    turnRate = math.rad(95),
    fullSteerSpeed = 18,
    minimumSteerFactor = 0.22,
    controlDeadzone = 0.01,
    maximumStep = 0.1,
}

local function finiteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function approachZeroAcceleration(speed, response)
    return -speed * response
end

local function wrapAngle(angle)
    return (angle + math.pi) % (2 * math.pi) - math.pi
end

function VehicleDynamics.step(config, state, controls, dt)
    config = config or VehicleDynamics.DEFAULTS
    assert(type(state) == "table", "state is required")
    assert(type(controls) == "table", "controls are required")
    assert(finiteNumber(state.forwardSpeed), "forwardSpeed must be finite")
    assert(finiteNumber(state.lateralSpeed), "lateralSpeed must be finite")
    assert(finiteNumber(state.headingYaw), "headingYaw must be finite")
    assert(finiteNumber(controls.throttle), "throttle must be finite")
    assert(finiteNumber(controls.steer), "steer must be finite")
    assert(finiteNumber(dt) and dt >= 0, "dt must be a non-negative finite number")

    local boundedDt = math.min(dt, config.maximumStep)
    local throttle = clamp(controls.throttle, -1, 1)
    local steer = clamp(controls.steer, -1, 1)
    local forwardSpeed = state.forwardSpeed

    if math.abs(throttle) <= config.controlDeadzone then
        throttle = 0
    end
    if math.abs(steer) <= config.controlDeadzone then
        steer = 0
    end

    local forwardAcceleration
    if throttle > 0 then
        if forwardSpeed >= config.maxForwardSpeed then
            forwardAcceleration = approachZeroAcceleration(
                forwardSpeed - config.maxForwardSpeed,
                config.overspeedResponse
            )
        else
            forwardAcceleration = throttle * config.forwardAcceleration
            if forwardSpeed < 0 then
                forwardAcceleration = forwardAcceleration
                    - forwardSpeed * config.brakingResponse
            end
        end
    elseif throttle < 0 then
        if forwardSpeed <= -config.maxReverseSpeed then
            forwardAcceleration = approachZeroAcceleration(
                forwardSpeed + config.maxReverseSpeed,
                config.overspeedResponse
            )
        else
            forwardAcceleration = throttle * config.reverseAcceleration
            if forwardSpeed > 0 then
                forwardAcceleration = forwardAcceleration
                    - forwardSpeed * config.brakingResponse
            end
        end
    else
        forwardAcceleration = approachZeroAcceleration(forwardSpeed, config.coastResponse)
    end
    forwardAcceleration = clamp(
        forwardAcceleration,
        -config.maximumLongitudinalAcceleration,
        config.maximumLongitudinalAcceleration
    )

    local lateralAcceleration = clamp(
        -state.lateralSpeed * config.lateralGrip,
        -config.maximumLateralAcceleration,
        config.maximumLateralAcceleration
    )

    local steeringSpeed = math.abs(forwardSpeed)
    if math.abs(throttle) > 0 then
        steeringSpeed = math.max(
            steeringSpeed,
            config.fullSteerSpeed * config.minimumSteerFactor
        )
    end
    local steeringAuthority = clamp(
        steeringSpeed / config.fullSteerSpeed,
        0,
        1
    )
    local travelDirection = forwardSpeed < -0.5 and -1 or 1
    local yawRate = -steer
        * config.turnRate
        * steeringAuthority
        * travelDirection
    local headingYaw = wrapAngle(state.headingYaw + yawRate * boundedDt)

    return {
        forwardAcceleration = forwardAcceleration,
        lateralAcceleration = lateralAcceleration,
        yawRate = yawRate,
        headingYaw = headingYaw,
        dt = boundedDt,
    }
end

return VehicleDynamics
