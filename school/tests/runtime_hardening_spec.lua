local function read(path)
    local file = assert(io.open(path, "rb"))
    local value = assert(file:read("*a"))
    file:close()
    return value
end

local classService = read("school/src/server/ClassEducation.server.lua")
local foundation = read("school/src/server/FoundationBootstrap.server.lua")
local client = read("school/src/client/CanonicalSchoolClient.client.lua")
local housing = read("school/src/server/HousingService.server.lua")

assert(
    classService:find("if active and active.classKey == classKey then", 1, true),
    "active class must remain submittable across the bell"
)
assert(
    not classService:find('coordinator:leave(playerKey(player), "period_changed")', 1, true),
    "period changes must not eject an in-progress lesson"
)
assert(
    foundation:find('local scheduleEpoch = "utc-day-"', 1, true),
    "class reward epoch must be stable across servers"
)
assert(
    client:find('result.code == "progression_pending"', 1, true),
    "class modal must handle a refused close while progress is pending"
)
assert(
    client:find('if type(response) == "table" and response.retryable ~= true then', 1, true),
    "housing must retain request ids when transport outcome is uncertain"
)
assert(
    housing:find('folder:GetAttribute("LayoutRevision") == revision', 1, true),
    "housing visuals must be revision-gated"
)

print("RUNTIME_HARDENING_PASS")
