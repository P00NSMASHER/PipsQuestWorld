--!strict
-- Pure authoritative state and geometry for the Pip High P.E. dodgeball drill.
-- Roblox instances and replication live only in the server runtime adapter.

local PEDodgeballController = {}
PEDodgeballController.__index = PEDodgeballController

local DEFAULT_DURATION = 15
local DEFAULT_FIRST_BALL_DELAY = 0.75
local DEFAULT_BALL_INTERVAL = 1.35
local DEFAULT_START_COOLDOWN = 0.75
local MAX_SESSION_ID_LENGTH = 96

local function finiteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function isInteger(value)
    return finiteNumber(value) and value == math.floor(value)
end

local function validPlayerId(playerId)
    return isInteger(playerId) and playerId > 0
end

local function validIdentifier(value, maximumLength)
    return type(value) == "string"
        and #value > 0
        and #value <= maximumLength
        and value:match("^[%w:_%-]+$") ~= nil
end

local function validPoint(point)
    return type(point) == "table"
        and finiteNumber(point.x)
        and finiteNumber(point.y)
        and finiteNumber(point.z)
end

local function calculateTotalBalls(duration, firstBallDelay, ballInterval)
    local count = 0
    local scheduledAt = firstBallDelay
    while scheduledAt < duration do
        count = count + 1
        scheduledAt = scheduledAt + ballInterval
    end
    return count
end

local function gradeForHits(hits)
    if hits == 0 then
        return "A+", "Perfect footwork! You stayed clear of every foam ball."
    elseif hits == 1 then
        return "A", "Great movement! One tap could not slow you down."
    elseif hits == 2 then
        return "B", "Strong dodging! Keep changing direction and watching the lanes."
    end
    return "C", "Drill complete! Keep moving early and you will dodge even more next time."
end

local function inactiveState(duration, totalBalls)
    return {
        active = false,
        duration = duration,
        remainingSeconds = 0,
        hits = 0,
        ballsThrown = 0,
        totalBalls = totalBalls,
    }
end

local function publicState(session, now, duration, totalBalls)
    if session == nil then
        return inactiveState(duration, totalBalls)
    end
    return {
        active = true,
        duration = duration,
        remainingSeconds = math.max(0, session.endAt - now),
        hits = session.hits,
        ballsThrown = session.ballsThrown,
        totalBalls = totalBalls,
    }
end

function PEDodgeballController.computeBallisticVelocity(
    origin,
    target,
    flightTime,
    effectiveGravity
)
    assert(validPoint(origin), "origin must be a finite point")
    assert(validPoint(target), "target must be a finite point")
    assert(finiteNumber(flightTime) and flightTime > 0, "flightTime must be positive")
    assert(
        finiteNumber(effectiveGravity) and effectiveGravity >= 0,
        "effectiveGravity must be non-negative"
    )

    return {
        x = (target.x - origin.x) / flightTime,
        y = (
            target.y
            - origin.y
            + 0.5 * effectiveGravity * flightTime * flightTime
        ) / flightTime,
        z = (target.z - origin.z) / flightTime,
    }
end

function PEDodgeballController.segmentHitsSphere(
    segmentStart,
    segmentEnd,
    sphereCenter,
    radius
)
    assert(validPoint(segmentStart), "segmentStart must be a finite point")
    assert(validPoint(segmentEnd), "segmentEnd must be a finite point")
    assert(validPoint(sphereCenter), "sphereCenter must be a finite point")
    assert(finiteNumber(radius) and radius >= 0, "radius must be non-negative")

    local dx = segmentEnd.x - segmentStart.x
    local dy = segmentEnd.y - segmentStart.y
    local dz = segmentEnd.z - segmentStart.z
    local lengthSquared = dx * dx + dy * dy + dz * dz
    local closestT = 0
    if lengthSquared > 0 then
        closestT = (
            (sphereCenter.x - segmentStart.x) * dx
            + (sphereCenter.y - segmentStart.y) * dy
            + (sphereCenter.z - segmentStart.z) * dz
        ) / lengthSquared
        closestT = math.max(0, math.min(1, closestT))
    end

    local closestX = segmentStart.x + dx * closestT
    local closestY = segmentStart.y + dy * closestT
    local closestZ = segmentStart.z + dz * closestT
    local distanceX = sphereCenter.x - closestX
    local distanceY = sphereCenter.y - closestY
    local distanceZ = sphereCenter.z - closestZ
    return distanceX * distanceX + distanceY * distanceY + distanceZ * distanceZ
        <= radius * radius
end

function PEDodgeballController.new(options)
    options = options or {}
    assert(type(options.sessionIdFactory) == "function", "sessionIdFactory is required")

    local duration = options.duration or DEFAULT_DURATION
    local firstBallDelay = options.firstBallDelay or DEFAULT_FIRST_BALL_DELAY
    local ballInterval = options.ballInterval or DEFAULT_BALL_INTERVAL
    local startCooldown = options.startCooldown or DEFAULT_START_COOLDOWN
    assert(finiteNumber(duration) and duration > 0, "duration must be positive")
    assert(
        finiteNumber(firstBallDelay) and firstBallDelay >= 0 and firstBallDelay < duration,
        "firstBallDelay must be within the round"
    )
    assert(finiteNumber(ballInterval) and ballInterval > 0, "ballInterval must be positive")
    assert(finiteNumber(startCooldown) and startCooldown >= 0, "startCooldown must be non-negative")

    return setmetatable({
        _sessionIdFactory = options.sessionIdFactory,
        _duration = duration,
        _firstBallDelay = firstBallDelay,
        _ballInterval = ballInterval,
        _startCooldown = startCooldown,
        _totalBalls = calculateTotalBalls(duration, firstBallDelay, ballInterval),
        _active = {},
        _lastStartAt = {},
    }, PEDodgeballController)
end

function PEDodgeballController:getState(playerId, now)
    if not validPlayerId(playerId) or not finiteNumber(now) then
        local state = inactiveState(self._duration, self._totalBalls)
        state.available = false
        state.code = "invalid_state_request"
        return state
    end
    return publicState(
        self._active[playerId],
        now,
        self._duration,
        self._totalBalls
    )
end

function PEDodgeballController:startSession(playerId, atGym, alive, now)
    if not validPlayerId(playerId) or not finiteNumber(now) then
        return { accepted = false, code = "invalid_start" }
    end
    if atGym ~= true then
        return {
            accepted = false,
            code = "not_at_gym",
            state = self:getState(playerId, now),
        }
    end
    if alive ~= true then
        return {
            accepted = false,
            code = "player_not_ready",
            state = self:getState(playerId, now),
        }
    end

    local current = self._active[playerId]
    if current then
        return {
            accepted = true,
            code = "session_already_active",
            sessionId = current.sessionId,
            state = publicState(current, now, self._duration, self._totalBalls),
        }
    end

    local lastStartAt = self._lastStartAt[playerId]
    if lastStartAt ~= nil and now - lastStartAt < self._startCooldown then
        return {
            accepted = false,
            code = "start_rate_limited",
            retryAfter = math.max(0, self._startCooldown - (now - lastStartAt)),
            state = self:getState(playerId, now),
        }
    end

    local sessionId = self._sessionIdFactory(playerId, now)
    if not validIdentifier(sessionId, MAX_SESSION_ID_LENGTH) then
        return { accepted = false, code = "session_id_unavailable" }
    end

    local session = {
        sessionId = sessionId,
        startedAt = now,
        endAt = now + self._duration,
        nextBallAt = now + self._firstBallDelay,
        nextBallNumber = 1,
        ballsThrown = 0,
        hits = 0,
        spawnedBallIds = {},
        hitBallIds = {},
    }
    self._active[playerId] = session
    self._lastStartAt[playerId] = now
    return {
        accepted = true,
        code = "session_started",
        sessionId = sessionId,
        state = publicState(session, now, self._duration, self._totalBalls),
    }
end

function PEDodgeballController:_finish(playerId, session, reason, now, completed)
    self._active[playerId] = nil
    if completed then
        session.ballsThrown = self._totalBalls
    end

    local dodged = math.max(0, session.ballsThrown - session.hits)
    local grade = nil
    local message
    local title
    if completed then
        grade, message = gradeForHits(session.hits)
        title = "Drill complete!"
    else
        title = "Drill ended safely"
        message = "No penalty. Return to the gym prompt whenever you want another try."
    end

    return {
        accepted = true,
        code = completed and "session_completed" or "session_ended",
        state = inactiveState(self._duration, self._totalBalls),
        result = {
            completed = completed,
            reason = reason,
            title = title,
            message = message,
            grade = grade,
            hits = session.hits,
            dodged = dodged,
            ballsThrown = session.ballsThrown,
            totalBalls = self._totalBalls,
            duration = self._duration,
        },
    }
end

function PEDodgeballController:advance(playerId, now, atGym, alive)
    if not validPlayerId(playerId) or not finiteNumber(now) then
        return { accepted = false, code = "invalid_advance" }
    end
    local session = self._active[playerId]
    if session == nil then
        return {
            accepted = false,
            code = "no_active_session",
            state = self:getState(playerId, now),
        }
    end
    if alive ~= true then
        return self:_finish(playerId, session, "player_died", now, false)
    end
    if atGym ~= true then
        return self:_finish(playerId, session, "left_gym", now, false)
    end
    if now >= session.endAt then
        return self:_finish(playerId, session, "completed", now, true)
    end

    local spawnBallIds = {}
    while session.nextBallAt <= now
        and session.nextBallNumber <= self._totalBalls do
        local ballId = session.sessionId
            .. ":ball-"
            .. tostring(session.nextBallNumber)
        session.spawnedBallIds[ballId] = true
        table.insert(spawnBallIds, ballId)
        session.ballsThrown = session.ballsThrown + 1
        session.nextBallNumber = session.nextBallNumber + 1
        session.nextBallAt = session.nextBallAt + self._ballInterval
    end

    return {
        accepted = true,
        code = "session_updated",
        sessionId = session.sessionId,
        spawnBallIds = spawnBallIds,
        state = publicState(session, now, self._duration, self._totalBalls),
    }
end

function PEDodgeballController:recordHit(playerId, sessionId, ballId, now)
    if not validPlayerId(playerId)
        or not validIdentifier(sessionId, MAX_SESSION_ID_LENGTH)
        or not validIdentifier(ballId, MAX_SESSION_ID_LENGTH + 24)
        or not finiteNumber(now) then
        return { accepted = false, code = "invalid_hit" }
    end

    local session = self._active[playerId]
    if session == nil then
        return { accepted = false, code = "no_active_session" }
    end
    if session.sessionId ~= sessionId then
        return { accepted = false, code = "stale_session" }
    end
    if now >= session.endAt then
        return { accepted = false, code = "session_expired" }
    end
    if session.spawnedBallIds[ballId] ~= true then
        return { accepted = false, code = "unknown_ball" }
    end
    if session.hitBallIds[ballId] then
        return {
            accepted = true,
            code = "hit_already_recorded",
            state = publicState(session, now, self._duration, self._totalBalls),
        }
    end

    session.hitBallIds[ballId] = true
    session.hits = session.hits + 1
    return {
        accepted = true,
        code = "hit_recorded",
        state = publicState(session, now, self._duration, self._totalBalls),
    }
end

function PEDodgeballController:endSession(playerId, reason, now)
    if not validPlayerId(playerId)
        or type(reason) ~= "string"
        or reason == ""
        or not finiteNumber(now) then
        return { accepted = false, code = "invalid_end" }
    end
    local session = self._active[playerId]
    if session == nil then
        return {
            accepted = true,
            code = "no_active_session",
            state = self:getState(playerId, now),
        }
    end
    return self:_finish(playerId, session, reason, now, reason == "completed")
end

function PEDodgeballController:clearPlayer(playerId)
    self._active[playerId] = nil
    self._lastStartAt[playerId] = nil
end

return PEDodgeballController
