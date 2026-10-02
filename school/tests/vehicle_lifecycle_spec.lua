local VehicleLifecycle = assert(loadfile("school/src/server/VehicleLifecycle.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local lifecycle = VehicleLifecycle.new()

eq(lifecycle:get("101"), nil, "new player unexpectedly has vehicle")

local first = lifecycle:spawn("101", "starter-sedan")
eq(first.accepted, true, "first spawn rejected")
eq(first.code, "vehicle_spawn_reserved", "first spawn code")
eq(first.state.vehicleId, "starter-sedan", "first vehicle id")
eq(type(first.state.token), "string", "first token type")
local firstToken = first.state.token

local duplicate = lifecycle:spawn("101", "starter-sedan")
eq(duplicate.accepted, false, "duplicate spawn accepted")
eq(duplicate.code, "vehicle_already_active", "duplicate spawn code")
eq(duplicate.state.token, firstToken, "duplicate changed token")

local other = lifecycle:spawn("202", "starter-sedan")
eq(other.accepted, true, "second player spawn rejected")
eq(other.state.playerKey, "202", "second player key")
eq(lifecycle:get("101").token, firstToken, "second player changed first player state")

local stale = lifecycle:despawn("101", "stale-token")
eq(stale.accepted, false, "stale despawn accepted")
eq(stale.code, "stale_vehicle_token", "stale despawn code")
eq(lifecycle:get("101").token, firstToken, "stale despawn removed vehicle")

local removed = lifecycle:despawn("101", firstToken)
eq(removed.accepted, true, "valid despawn rejected")
eq(removed.code, "vehicle_despawned", "valid despawn code")
eq(removed.released.token, firstToken, "released token mismatch")
eq(lifecycle:get("101"), nil, "valid despawn left active vehicle")
eq(lifecycle:get("202").vehicleId, "starter-sedan", "valid despawn affected other player")

local repeated = lifecycle:despawn("101", firstToken)
eq(repeated.accepted, true, "repeat despawn must be idempotent")
eq(repeated.code, "vehicle_already_despawned", "repeat despawn code")

local respawn = lifecycle:spawn("101", "starter-sedan")
eq(respawn.accepted, true, "respawn rejected")
eq(respawn.state.token == firstToken, false, "respawn reused stale token")

print("HIGH_SCHOOL_VEHICLE_LIFECYCLE_PASS")
