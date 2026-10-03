local previousVector3 = _G.Vector3

_G.Vector3 = {
    new = function(x, y, z)
        return { X = x, Y = y, Z = z }
    end,
}

local SchoolConfig = assert(loadfile("school/src/shared/SchoolConfig.lua"))()
_G.Vector3 = previousVector3

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local seam = assert(SchoolConfig.WorldSpawnSeams, "WorldSpawnSeams contract missing").AutoShopRoad
assert(seam, "AutoShopRoad spawn seam missing")

local autoShop = assert(SchoolConfig.WorldLocations.AutoShop, "AutoShop location missing")
local townCenter = assert(SchoolConfig.WorldLocations.TownCenter, "TownCenter location missing")

eq(seam.anchorLocation, "AutoShop", "anchor location")
eq(seam.roadPart, "TownMainStreet", "road part")
eq(seam.position.X, autoShop.position.X, "spawn X follows AutoShop")
eq(seam.position.Z, townCenter.position.Z, "spawn Z follows TownCenter road axis")
eq(seam.headingDegrees, 90, "road heading")

local campusFile = assert(io.open("school/src/server/CampusBuilder.server.lua", "r"))
local campusSource = campusFile:read("*a")
campusFile:close()

assert(campusSource:find('makePart%("TownMainStreet"', 1), "CampusBuilder must provide TownMainStreet")
assert(campusSource:find('buildStorefront%("AutoShop"', 1), "CampusBuilder must provide AutoShop")

local roadSizeY, roadCenterY = campusSource:match(
    'makePart%("TownMainStreet",%s*Vector3%.new%([^,]+,%s*([%-%d%.]+),%s*[^%)]+%),%s*CFrame%.new%([^,]+,%s*([%-%d%.]+),'
)
assert(roadSizeY and roadCenterY, "cannot parse TownMainStreet vertical geometry")
local roadSurfaceY = tonumber(roadCenterY) + (tonumber(roadSizeY) / 2)
eq(seam.position.Y, roadSurfaceY, "spawn Y follows TownMainStreet top surface")

local function countLiteral(text, fragment)
    local count = 0
    local start = 1
    while true do
        local found = text:find(fragment, start, true)
        if not found then
            return count
        end
        count = count + 1
        start = found + #fragment
    end
end

eq(countLiteral(campusSource, 'Instance.new("SpawnLocation")'), 1, "single MainSpawn construction site")
assert(campusSource:find('spawn.Name = "MainSpawn"', 1, true), "CampusBuilder must name the sole SpawnLocation MainSpawn")
assert(campusSource:find("spawn.Parent = campus", 1, true), "MainSpawn must remain under SchoolCampus")

local runtimeFile = assert(io.open("school/src/server/FoundationBootstrap.server.lua", "r"))
local runtimeSource = runtimeFile:read("*a")
runtimeFile:close()

eq(countLiteral(runtimeSource, "player.RespawnLocation = getMainSpawn()"), 1, "single respawn authority assignment")
assert(runtimeSource:find('Workspace:WaitForChild("SchoolCampus")', 1, true), "spawn authority must wait for SchoolCampus")
assert(runtimeSource:find('campus:WaitForChild("MainSpawn")', 1, true), "spawn authority must consume SchoolCampus.MainSpawn")
assert(runtimeSource:find('assert(spawn:IsA("SpawnLocation")', 1, true), "spawn authority must validate MainSpawn type")

for _, attributeName in ipairs({ "SchoolDay", "SchoolPeriodIndex", "SchoolPeriodId", "SchoolPeriodRoom" }) do
    local publisher = 'Workspace:SetAttribute("' .. attributeName .. '"'
    eq(countLiteral(runtimeSource, publisher), 1, attributeName .. " has one Foundation publisher")
    eq(countLiteral(campusSource, publisher), 0, attributeName .. " is not published by CampusBuilder")
end

print("FOUNDATION_WORLD_CONTRACT_OK")
