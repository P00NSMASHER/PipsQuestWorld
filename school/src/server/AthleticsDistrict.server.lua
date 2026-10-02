local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))
local campus = Workspace:WaitForChild("SchoolCampus")
local geometry = campus:WaitForChild("Geometry")

local old = geometry:FindFirstChild("AthleticsDistrict")
if old then old:Destroy() end

local district = Instance.new("Folder")
district.Name = "AthleticsDistrict"
district.Parent = geometry

local function loc(name)
    local entry = SchoolConfig.WorldLocations[name]
    assert(entry and entry.position, "missing world location: " .. name)
    return entry.position
end

local function part(name, size, cf, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = district
    return p
end

local white = Color3.fromRGB(240, 240, 236)
local dark = Color3.fromRGB(58, 61, 66)
local metal = Color3.fromRGB(88, 96, 107)
local concrete = Color3.fromRGB(198, 201, 204)
local football = loc("FootballField")
local basketball = loc("BasketballCourt")
local pool = loc("OutdoorPool")
local entrance = loc("AthleticsEntrance")

-- Continuous west-campus approach so the athletics block reads as part of the school map.
part("AthleticsWalk", Vector3.new(96, 0.3, 12), CFrame.new(-143, 0.75, entrance.Z), concrete, Enum.Material.Concrete)
part("AthleticsDrive", Vector3.new(30, 0.35, 238), CFrame.new(-326, 0.48, 181), dark, Enum.Material.Asphalt)
part("AthleticsDriveLine", Vector3.new(0.3, 0.08, 228), CFrame.new(-326, 0.72, 181), Color3.fromRGB(244, 205, 72), Enum.Material.SmoothPlastic)
part("AthleticsLoopConnector", Vector3.new(164, 0.35, 30), CFrame.new(-244, 0.48, 291), dark, Enum.Material.Asphalt)

-- Football stadium footprint.
part("FootballTurf", Vector3.new(118, 0.45, 190), CFrame.new(football.X, 0.62, football.Z), Color3.fromRGB(70, 126, 69), Enum.Material.Grass)
for _, z in ipairs({-88, 0, 88}) do
    part("FootballLine", Vector3.new(108, 0.08, 0.45), CFrame.new(football.X, 0.9, football.Z + z), white, Enum.Material.SmoothPlastic)
end
for _, x in ipairs({-54, 54}) do
    part("FootballSideline", Vector3.new(0.45, 0.08, 176), CFrame.new(football.X + x, 0.9, football.Z), white, Enum.Material.SmoothPlastic)
end
for i = -4, 4 do
    part("FootballYardLine", Vector3.new(108, 0.08, 0.28), CFrame.new(football.X, 0.9, football.Z + i * 17), white, Enum.Material.SmoothPlastic)
end
for _, direction in ipairs({-1, 1}) do
    local z = football.Z + direction * 92
    part("GoalPostStem", Vector3.new(0.8, 10, 0.8), CFrame.new(football.X, 5.6, z), Color3.fromRGB(242, 208, 55), Enum.Material.Metal)
    part("GoalPostCrossbar", Vector3.new(14, 0.7, 0.7), CFrame.new(football.X, 9.4, z), Color3.fromRGB(242, 208, 55), Enum.Material.Metal)
end
for row = 0, 4 do
    part("FootballBleacher", Vector3.new(70, 1.1, 4), CFrame.new(football.X + 77, 1.4 + row * 1.15, football.Z - 14 + row * 4), Color3.fromRGB(145, 151, 160), Enum.Material.Metal)
end

-- Outdoor basketball court: a documented Legacy campus activity landmark.
part("BasketballCourt", Vector3.new(92, 0.4, 54), CFrame.new(basketball.X, 0.62, basketball.Z), Color3.fromRGB(86, 111, 145), Enum.Material.SmoothPlastic)
part("BasketballCenterLine", Vector3.new(0.35, 0.08, 50), CFrame.new(basketball.X, 0.9, basketball.Z), white, Enum.Material.SmoothPlastic)
for _, z in ipairs({-25, 25}) do
    part("BasketballSideline", Vector3.new(88, 0.08, 0.35), CFrame.new(basketball.X, 0.9, basketball.Z + z), white, Enum.Material.SmoothPlastic)
end
for _, x in ipairs({-44, 44}) do
    part("BasketballBaseline", Vector3.new(0.35, 0.08, 50), CFrame.new(basketball.X + x, 0.9, basketball.Z), white, Enum.Material.SmoothPlastic)
end
for _, direction in ipairs({-1, 1}) do
    local x = basketball.X + direction * 39
    part("BasketballPost", Vector3.new(0.8, 10, 0.8), CFrame.new(x, 5.6, basketball.Z), metal, Enum.Material.Metal)
    part("BasketballBackboard", Vector3.new(0.7, 7, 11), CFrame.new(x - direction * 1.7, 9.2, basketball.Z), white, Enum.Material.SmoothPlastic)
    local rim = part("BasketballRim", Vector3.new(0.5, 4, 4), CFrame.new(x - direction * 3.3, 7.4, basketball.Z), Color3.fromRGB(221, 103, 55), Enum.Material.Metal)
    rim.Shape = Enum.PartType.Cylinder
    rim.CFrame = rim.CFrame * CFrame.Angles(math.rad(90), 0, 0)
end

-- Outdoor pool/deck landmark.
part("PoolDeck", Vector3.new(90, 0.5, 126), CFrame.new(pool.X, 0.58, pool.Z), concrete, Enum.Material.Concrete)
local water = part("PoolWater", Vector3.new(58, 1.1, 98), CFrame.new(pool.X, 0.28, pool.Z), Color3.fromRGB(69, 157, 211), Enum.Material.Glass)
water.Transparency = 0.18
water.CanCollide = false
for lane = -2, 2 do
    part("PoolLaneLine", Vector3.new(0.22, 0.08, 92), CFrame.new(pool.X + lane * 9, 0.93, pool.Z), white, Enum.Material.SmoothPlastic)
end

-- Night-readable stadium landmarks.
for _, p in ipairs({
    Vector3.new(football.X - 66, 0, football.Z - 78),
    Vector3.new(football.X - 66, 0, football.Z + 78),
    Vector3.new(football.X + 66, 0, football.Z - 78),
    Vector3.new(football.X + 66, 0, football.Z + 78),
    Vector3.new(pool.X - 48, 0, pool.Z - 56),
    Vector3.new(pool.X - 48, 0, pool.Z + 56),
}) do
    part("AthleticsLightPole", Vector3.new(1, 24, 1), CFrame.new(p.X, 12, p.Z), metal, Enum.Material.Metal)
    local lamp = part("AthleticsLightHead", Vector3.new(7, 1, 2), CFrame.new(p.X, 24, p.Z), Color3.fromRGB(238, 241, 226), Enum.Material.Neon)
    lamp.CanCollide = false
end
