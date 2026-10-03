local projectFile = assert(io.open("school/default.project.json", "r"))
local projectSource = projectFile:read("*a")
projectFile:close()

local campusFile = assert(io.open("school/src/server/CampusBuilder.server.lua", "r"))
local campusSource = campusFile:read("*a")
campusFile:close()

local runtimeFile = assert(io.open("school/src/server/FoundationBootstrap.server.lua", "r"))
local runtimeSource = runtimeFile:read("*a")
runtimeFile:close()

assert(projectSource:find('"Brightness": 2', 1, true), "project must preserve Foundation brightness baseline")
assert(projectSource:find('"ClockTime": 10.5', 1, true), "project must preserve Foundation clock-time baseline")
assert(projectSource:find('"GlobalShadows": true', 1, true), "project must preserve Foundation shadow baseline")
assert(projectSource:find('"Technology": "ShadowMap"', 1, true), "project must preserve Foundation lighting technology")

for _, source in ipairs({ campusSource, runtimeSource }) do
    assert(not source:find("game:GetService(\"Lighting\")", 1, true), "Foundation runtime must not create a second Lighting authority")
    assert(not source:find("Lighting.", 1, true), "Foundation runtime must not mutate Lighting")
end

print("FOUNDATION_LIGHTING_AUTHORITY_OK")
