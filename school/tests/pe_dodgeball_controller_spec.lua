local Controller = assert(loadfile("school/src/server/PEDodgeballController.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

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

local function assertPublicState(state)
    local forbidden = {
        sessionId = true,
        startedAt = true,
        endAt = true,
        nextBallAt = true,
        spawnedBallIds = true,
        hitBallIds = true,
    }
    local function visit(value, path)
        if type(value) ~= "table" then return end
        for key, child in pairs(value) do
            if forbidden[key] then
                error("public state exposed " .. path .. "." .. tostring(key), 2)
            end
            visit(child, path .. "." .. tostring(key))
        end
    end
    visit(state, "state")
end

local velocity = Controller.computeBallisticVelocity(
    { x = 0, y = 10, z = 0 },
    { x = 10, y = 0, z = -6 },
    2,
    4
)
approx(velocity.x, 5, 0.0001, "ballistic x")
approx(velocity.y, -1, 0.0001, "ballistic y")
approx(velocity.z, -3, 0.0001, "ballistic z")
approx(10 + velocity.y * 2 - 0.5 * 4 * 4, 0, 0.0001, "ballistic target y")

eq(Controller.segmentHitsSphere(
    { x = -5, y = 0, z = 0 },
    { x = 5, y = 0, z = 0 },
    { x = 0, y = 1, z = 0 },
    1.1
), true, "segment crossing hit")
eq(Controller.segmentHitsSphere(
    { x = -5, y = 0, z = 0 },
    { x = 5, y = 0, z = 0 },
    { x = 0, y = 3, z = 0 },
    1.1
), false, "segment distant miss")
eq(Controller.segmentHitsSphere(
    { x = 1, y = 1, z = 1 },
    { x = 1, y = 1, z = 1 },
    { x = 1.5, y = 1, z = 1 },
    0.6
), true, "zero-length segment hit")

local nextSession = 0
local controller = Controller.new({
    duration = 15,
    firstBallDelay = 0.75,
    ballInterval = 1.35,
    startCooldown = 0.75,
    sessionIdFactory = function(playerId)
        nextSession = nextSession + 1
        return "pe-session-" .. tostring(playerId) .. "-" .. tostring(nextSession)
    end,
})

local initial = controller:getState(101, 0)
eq(initial.active, false, "initial active")
eq(initial.duration, 15, "duration")
eq(initial.totalBalls, 11, "scheduled ball count")
assertPublicState(initial)

local farStart = controller:startSession(101, false, true, 0)
eq(farStart.code, "not_at_gym", "far start code")
local deadStart = controller:startSession(101, true, false, 0)
eq(deadStart.code, "player_not_ready", "dead start code")

local started = controller:startSession(101, true, true, 0)
eq(started.accepted, true, "start rejected")
eq(started.code, "session_started", "start code")
eq(started.state.active, true, "start state inactive")
eq(started.state.remainingSeconds, 15, "start remaining")
eq(started.state.hits, 0, "start hits")
assertPublicState(started.state)

local duplicateStart = controller:startSession(101, true, true, 0.1)
eq(duplicateStart.code, "session_already_active", "duplicate start code")
eq(duplicateStart.sessionId, started.sessionId, "duplicate changed session")

local beforeFirst = controller:advance(101, 0.74, true, true)
eq(#beforeFirst.spawnBallIds, 0, "ball launched early")
eq(beforeFirst.state.ballsThrown, 0, "early thrown count")

local firstLaunch = controller:advance(101, 0.75, true, true)
eq(#firstLaunch.spawnBallIds, 1, "first launch count")
eq(firstLaunch.state.ballsThrown, 1, "first thrown count")
local firstBallId = firstLaunch.spawnBallIds[1]
truthy(firstBallId:find(":ball%-1$"), "first ball id")

local unknown = controller:recordHit(101, started.sessionId, "unknown-ball", 0.8)
eq(unknown.code, "unknown_ball", "unknown ball accepted")
local otherPlayer = controller:recordHit(202, started.sessionId, firstBallId, 0.8)
eq(otherPlayer.code, "no_active_session", "other player authored hit")

local hit = controller:recordHit(101, started.sessionId, firstBallId, 0.8)
eq(hit.accepted, true, "server hit rejected")
eq(hit.code, "hit_recorded", "hit code")
eq(hit.state.hits, 1, "hit count")
assertPublicState(hit.state)

local duplicateHit = controller:recordHit(101, started.sessionId, firstBallId, 0.9)
eq(duplicateHit.code, "hit_already_recorded", "duplicate hit code")
eq(duplicateHit.state.hits, 1, "duplicate hit counted")

local secondLaunch = controller:advance(101, 2.1, true, true)
eq(#secondLaunch.spawnBallIds, 1, "second launch count")
eq(secondLaunch.state.ballsThrown, 2, "second thrown count")

local completed = controller:advance(101, 15, true, true)
eq(completed.code, "session_completed", "completion code")
eq(completed.result.completed, true, "completion flag")
eq(completed.result.reason, "completed", "completion reason")
eq(completed.result.grade, "A", "one-hit grade")
eq(completed.result.hits, 1, "result hits")
eq(completed.result.dodged, 10, "result dodged")
eq(completed.result.ballsThrown, 11, "result ball count")
eq(controller:getState(101, 15).active, false, "completion retained session")

local restart = controller:startSession(101, true, true, 15)
eq(restart.accepted, true, "completed round imposed lockout")
local left = controller:endSession(101, "left_by_player", 15.2)
eq(left.code, "session_ended", "leave code")
eq(left.result.completed, false, "leave marked complete")
eq(left.result.grade, nil, "leave assigned grade")
truthy(left.result.message:find("No penalty", 1, true), "leave message punitive")

local rateStart = controller:startSession(202, true, true, 0)
eq(rateStart.accepted, true, "rate test start")
controller:endSession(202, "left_by_player", 0.1)
local rateLimited = controller:startSession(202, true, true, 0.2)
eq(rateLimited.accepted, false, "rapid restart accepted")
eq(rateLimited.code, "start_rate_limited", "rapid restart code")
truthy(rateLimited.retryAfter <= 0.75, "rate retry too long")
local rateRecovered = controller:startSession(202, true, true, 0.75)
eq(rateRecovered.accepted, true, "short debounce became punitive lockout")
controller:endSession(202, "left_by_player", 0.8)

local deathStart = controller:startSession(303, true, true, 0)
eq(deathStart.accepted, true, "death test start")
local death = controller:advance(303, 0.5, true, false)
eq(death.result.reason, "player_died", "death reason")
eq(death.result.completed, false, "death marked complete")
eq(controller:getState(303, 0.5).active, false, "death retained session")

local boundaryStart = controller:startSession(404, true, true, 0)
eq(boundaryStart.accepted, true, "boundary test start")
local boundary = controller:advance(404, 0.5, false, true)
eq(boundary.result.reason, "left_gym", "boundary reason")
eq(boundary.result.completed, false, "boundary marked complete")

local perfectStart = controller:startSession(505, true, true, 0)
eq(perfectStart.accepted, true, "perfect test start")
local perfect = controller:advance(505, 15, true, true)
eq(perfect.result.grade, "A+", "perfect grade")
eq(perfect.result.dodged, 11, "perfect dodged")

local practiceStart = controller:startSession(606, true, true, 0)
eq(practiceStart.accepted, true, "practice test start")
local practiceAdvance = controller:advance(606, 3.45, true, true)
eq(#practiceAdvance.spawnBallIds, 3, "catch-up launch count")
for _, ballId in ipairs(practiceAdvance.spawnBallIds) do
    local practiceHit = controller:recordHit(
        606,
        practiceStart.sessionId,
        ballId,
        3.5
    )
    eq(practiceHit.code, "hit_recorded", "practice hit")
end
local practice = controller:advance(606, 15, true, true)
eq(practice.result.grade, "C", "practice grade")
truthy(practice.result.message:find("next time", 1, true), "practice feedback not encouraging")

local clearStart = controller:startSession(707, true, true, 0)
eq(clearStart.accepted, true, "clear test start")
controller:clearPlayer(707)
eq(controller:getState(707, 0.1).active, false, "clear retained session")
local clearRestart = controller:startSession(707, true, true, 0.1)
eq(clearRestart.accepted, true, "clear retained rate limit")

local invalidFactory = Controller.new({
    sessionIdFactory = function() return "invalid session id" end,
})
local invalidSession = invalidFactory:startSession(808, true, true, 0)
eq(invalidSession.accepted, false, "invalid session id accepted")
eq(invalidSession.code, "session_id_unavailable", "invalid session id code")

print("HIGH_SCHOOL_PE_DODGEBALL_CONTROLLER_PASS")
