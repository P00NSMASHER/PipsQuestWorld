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

local function hasCampus(fragment, label)
    if not campusSource:find(fragment, 1, true) then
        error("missing P1 campus contract: " .. (label or fragment), 2)
    end
end

hasCampus('makePart("SchoolFacadeLeft"', "blue/red/white school facade")
hasCampus('makePart("SchoolCrest"', "crest instance")
hasCampus('crestText.Text = "PH\\n★"', "school crest face")
hasCampus('"EntryStep" .. tostring(step + 1)', "broad entrance steps")
hasCampus('"AtriumDisplayTier" .. tostring(index)', "round atrium display")
hasCampus('"AtriumCeilingLight"', "bright atrium lighting")
hasCampus('"CorridorStairStep" .. tostring(step + 1)', "corridor stair focal point")
hasCampus('spawn.CFrame = CFrame.new(0, 1.55, 177)', "exterior-facing spawn seam")

local function parseVectorAssignment(prefix)
    local x, y, z = campusSource:match(
        prefix .. '%s*Vector3%.new%(([-%d%.]+),%s*([-%d%.]+),%s*([-%d%.]+)%)'
    )
    assert(x and y and z, "cannot parse vector assignment: " .. prefix)
    return { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
end

local function parsePartGeometry(name)
    local sx, sy, sz, cx, cy, cz = campusSource:match(
        'makePart%("' .. name
            .. '",%s*Vector3%.new%(([-%d%.]+),%s*([-%d%.]+),%s*([-%d%.]+)%),'
            .. '%s*CFrame%.new%(([-%d%.]+),%s*([-%d%.]+),%s*([-%d%.]+)%)'
    )
    assert(sx and sy and sz and cx and cy and cz, "cannot parse collidable geometry: " .. name)
    return {
        size = { x = tonumber(sx), y = tonumber(sy), z = tonumber(sz) },
        center = { x = tonumber(cx), y = tonumber(cy), z = tonumber(cz) },
    }
end

local function aabb(geometry)
    return {
        minX = geometry.center.x - geometry.size.x / 2,
        maxX = geometry.center.x + geometry.size.x / 2,
        minY = geometry.center.y - geometry.size.y / 2,
        maxY = geometry.center.y + geometry.size.y / 2,
        minZ = geometry.center.z - geometry.size.z / 2,
        maxZ = geometry.center.z + geometry.size.z / 2,
    }
end

local function positiveVolumeOverlap(left, right)
    return math.min(left.maxX, right.maxX) > math.max(left.minX, right.minX)
        and math.min(left.maxY, right.maxY) > math.max(left.minY, right.minY)
        and math.min(left.maxZ, right.maxZ) > math.max(left.minZ, right.minZ)
end

local spawnGeometry = {
    size = parseVectorAssignment('spawn%.Size%s*='),
    center = (function()
        local x, y, z = campusSource:match(
            'spawn%.CFrame%s*=%s*CFrame%.new%(([-%d%.]+),%s*([-%d%.]+),%s*([-%d%.]+)%)'
        )
        assert(x and y and z, "cannot parse MainSpawn CFrame")
        return { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
    end)(),
}
local spawnBounds = aabb(spawnGeometry)

for _, partName in ipairs({ "CampusGround", "EntryWalk", "DropOffLane", "ParkingLot" }) do
    local partBounds = aabb(parsePartGeometry(partName))
    assert(
        not positiveVolumeOverlap(spawnBounds, partBounds),
        "MainSpawn AABB overlaps collidable " .. partName
    )
end

local _, spawnCount = campusSource:gsub('Instance.new%("SpawnLocation"%)', "")
eq(spawnCount, 1, "single campus spawn authority")

print("FOUNDATION_WORLD_CONTRACT_OK")
