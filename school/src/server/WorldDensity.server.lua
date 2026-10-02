local Workspace = game:GetService("Workspace")

local campus = Workspace:WaitForChild("SchoolCampus")
local geometry = campus:WaitForChild("Geometry")

local existing = campus:FindFirstChild("WorldDensity")
if existing then
    existing:Destroy()
end

local root = Instance.new("Folder")
root.Name = "WorldDensity"
root.Parent = campus

local function part(name, size, cframe, color, material, parent)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent or root
    return p
end

local function sign(text, size, cframe, background)
    local board = part(
        "Sign_" .. text:gsub("%W", ""),
        size,
        cframe,
        background or Color3.fromRGB(30, 39, 58),
        Enum.Material.SmoothPlastic
    )
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 40
    gui.Parent = board

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Parent = gui
    return board
end

local function bench(name, cframe)
    local model = Instance.new("Folder")
    model.Name = name
    model.Parent = root
    part("Seat", Vector3.new(8, 0.7, 2.5), cframe * CFrame.new(0, 2.2, 0), Color3.fromRGB(129, 86, 58), Enum.Material.WoodPlanks, model)
    part("Back", Vector3.new(8, 3, 0.5), cframe * CFrame.new(0, 3.5, 1.1), Color3.fromRGB(129, 86, 58), Enum.Material.WoodPlanks, model)
    part("LegL", Vector3.new(0.6, 2, 0.6), cframe * CFrame.new(-3, 1, 0), Color3.fromRGB(65, 69, 76), Enum.Material.Metal, model)
    part("LegR", Vector3.new(0.6, 2, 0.6), cframe * CFrame.new(3, 1, 0), Color3.fromRGB(65, 69, 76), Enum.Material.Metal, model)
end

local function tree(name, position)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = root
    part("Trunk", Vector3.new(3, 11, 3), CFrame.new(position + Vector3.new(0, 5.5, 0)), Color3.fromRGB(101, 74, 54), Enum.Material.Wood, folder)
    local crown = part("Crown", Vector3.new(15, 15, 15), CFrame.new(position + Vector3.new(0, 15, 0)), Color3.fromRGB(66, 133, 72), Enum.Material.Grass, folder)
    crown.Shape = Enum.PartType.Ball
end

local function lamp(name, position)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = root
    part("Pole", Vector3.new(0.7, 13, 0.7), CFrame.new(position + Vector3.new(0, 6.5, 0)), Color3.fromRGB(55, 58, 65), Enum.Material.Metal, folder)
    local light = part("Light", Vector3.new(2.6, 1, 2.6), CFrame.new(position + Vector3.new(0, 13, 0)), Color3.fromRGB(255, 239, 184), Enum.Material.Neon, folder)
    local point = Instance.new("PointLight")
    point.Brightness = 0.7
    point.Range = 24
    point.Color = Color3.fromRGB(255, 239, 190)
    point.Parent = light
end

local function lockers(name, x, z, facing)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = root
    for i = 0, 5 do
        local dz = (i - 2.5) * 3.1
        local locker = part(
            "Locker" .. tostring(i + 1),
            Vector3.new(2.8, 7.5, 1.8),
            CFrame.new(x, 4.5, z + dz) * CFrame.Angles(0, math.rad(facing), 0),
            Color3.fromRGB(72, 112, 170),
            Enum.Material.Metal,
            folder
        )
        part("Vent", Vector3.new(1.5, 0.15, 0.15), locker.CFrame * CFrame.new(0, 1.8, -0.96), Color3.fromRGB(39, 55, 78), Enum.Material.Metal, folder)
    end
end

local function storefront(name, center, facadeColor)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = root
    part("Floor", Vector3.new(42, 1, 30), CFrame.new(center.X, 0.5, center.Z), Color3.fromRGB(215, 218, 222), Enum.Material.Concrete, folder)
    part("Back", Vector3.new(42, 16, 1), CFrame.new(center.X, 8, center.Z + 15), Color3.fromRGB(224, 226, 230), Enum.Material.Brick, folder)
    part("Left", Vector3.new(1, 16, 30), CFrame.new(center.X - 21, 8, center.Z), Color3.fromRGB(224, 226, 230), Enum.Material.Brick, folder)
    part("Right", Vector3.new(1, 16, 30), CFrame.new(center.X + 21, 8, center.Z), Color3.fromRGB(224, 226, 230), Enum.Material.Brick, folder)
    part("Facade", Vector3.new(42, 5, 1), CFrame.new(center.X, 13.5, center.Z - 15), facadeColor, Enum.Material.SmoothPlastic, folder)
    part("FrontL", Vector3.new(11, 9, 1), CFrame.new(center.X - 15.5, 4.5, center.Z - 15), Color3.fromRGB(233, 235, 238), Enum.Material.SmoothPlastic, folder)
    part("FrontR", Vector3.new(11, 9, 1), CFrame.new(center.X + 15.5, 4.5, center.Z - 15), Color3.fromRGB(233, 235, 238), Enum.Material.SmoothPlastic, folder)
    local glass = part("Window", Vector3.new(18, 8, 0.5), CFrame.new(center.X, 5, center.Z - 15.3), Color3.fromRGB(159, 204, 225), Enum.Material.Glass, folder)
    glass.Transparency = 0.25
    sign(name, Vector3.new(25, 4, 0.5), CFrame.new(center.X, 13.5, center.Z - 15.6), facadeColor)
end

-- Make the existing school feel occupied rather than like an empty prototype.
for _, z in ipairs({-92, -68, -38, -16, 18, 40}) do
    lockers("WestLockers_" .. tostring(z), -15.2, z, 90)
    lockers("EastLockers_" .. tostring(z), 15.2, z, -90)
end

bench("CrossHallBenchA", CFrame.new(-28, 0, 71))
bench("CrossHallBenchB", CFrame.new(28, 0, 71) * CFrame.Angles(0, math.rad(180), 0))

-- Cafeteria service area.
part("CafeteriaCounter", Vector3.new(48, 3.5, 4), CFrame.new(-48, 2.2, 87), Color3.fromRGB(114, 83, 60), Enum.Material.WoodPlanks)
for i = -2, 2 do
    part("ServingWindow" .. tostring(i), Vector3.new(7, 5, 0.5), CFrame.new(-48 + i * 9, 7, 86.8), Color3.fromRGB(183, 211, 221), Enum.Material.Glass)
end

-- Gym details.
for _, x in ipairs({36, 60}) do
    part("HoopPole_" .. tostring(x), Vector3.new(0.7, 10, 0.7), CFrame.new(x, 5, -108), Color3.fromRGB(65, 69, 76), Enum.Material.Metal)
    local backboard = part("Backboard_" .. tostring(x), Vector3.new(0.5, 7, 11), CFrame.new(x, 10, -108), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic)
    backboard.Transparency = 0.15
end

-- Courtyard seating and landscaping.
for _, offset in ipairs({Vector3.new(-22, 0, -12), Vector3.new(22, 0, -12), Vector3.new(-22, 0, 12), Vector3.new(22, 0, 12)}) do
    bench("CourtyardBench_" .. tostring(offset.X) .. "_" .. tostring(offset.Z), CFrame.new(Vector3.new(48, 0, 102) + offset))
end

-- Front entrance / parking / road / town.
part("FrontPlaza", Vector3.new(120, 1, 42), CFrame.new(0, 0.5, 145), Color3.fromRGB(187, 191, 196), Enum.Material.Concrete)
part("ParkingLot", Vector3.new(180, 1, 86), CFrame.new(0, 0.25, 208), Color3.fromRGB(54, 58, 64), Enum.Material.Pavement)
part("TownGround", Vector3.new(340, 1, 270), CFrame.new(0, -0.25, 345), Color3.fromRGB(106, 151, 91), Enum.Material.Grass)
part("MainRoad", Vector3.new(54, 0.5, 250), CFrame.new(0, 0.15, 330), Color3.fromRGB(47, 50, 56), Enum.Material.Pavement)
part("CrossRoad", Vector3.new(300, 0.5, 46), CFrame.new(0, 0.15, 310), Color3.fromRGB(47, 50, 56), Enum.Material.Pavement)
part("RoadStripeA", Vector3.new(1, 0.15, 250), CFrame.new(-2, 0.5, 330), Color3.fromRGB(245, 206, 72), Enum.Material.SmoothPlastic)
part("RoadStripeB", Vector3.new(1, 0.15, 250), CFrame.new(2, 0.5, 330), Color3.fromRGB(245, 206, 72), Enum.Material.SmoothPlastic)

for i = -4, 4 do
    local x = i * 18
    part("ParkingLine_" .. tostring(i), Vector3.new(0.35, 0.15, 32), CFrame.new(x, 0.85, 208), Color3.fromRGB(238, 238, 238), Enum.Material.SmoothPlastic)
end

for _, x in ipairs({-72, -36, 36, 72}) do
    lamp("FrontLamp_" .. tostring(x), Vector3.new(x, 0, 156))
end

storefront("Pip Cafe", Vector3.new(-86, 0, 285), Color3.fromRGB(151, 83, 70))
storefront("Pip Market", Vector3.new(-86, 0, 345), Color3.fromRGB(70, 129, 111))
storefront("Style Shop", Vector3.new(86, 0, 285), Color3.fromRGB(142, 91, 155))
storefront("Auto Shop", Vector3.new(86, 0, 345), Color3.fromRGB(67, 103, 158))

for _, pos in ipairs({
    Vector3.new(-145, 0, 255), Vector3.new(-145, 0, 320), Vector3.new(-145, 0, 390),
    Vector3.new(145, 0, 255), Vector3.new(145, 0, 320), Vector3.new(145, 0, 390)
}) do
    tree("TownTree_" .. tostring(pos.X) .. "_" .. tostring(pos.Z), pos)
end

for _, z in ipairs({250, 290, 330, 370, 410}) do
    lamp("WestStreetLamp_" .. tostring(z), Vector3.new(-31, 0, z))
    lamp("EastStreetLamp_" .. tostring(z), Vector3.new(31, 0, z))
end

-- Neighborhood shells provide immediate full-game scale; interiors can be owned by the housing lane later.
for index, data in ipairs({
    {Vector3.new(-118, 0, 420), Color3.fromRGB(218, 197, 176)},
    {Vector3.new(-58, 0, 440), Color3.fromRGB(184, 207, 220)},
    {Vector3.new(58, 0, 440), Color3.fromRGB(209, 187, 211)},
    {Vector3.new(118, 0, 420), Color3.fromRGB(198, 213, 181)}
}) do
    local center = data[1]
    local color = data[2]
    local folder = Instance.new("Folder")
    folder.Name = "HouseShell" .. tostring(index)
    folder.Parent = root
    part("Foundation", Vector3.new(44, 1, 34), CFrame.new(center.X, 0.5, center.Z), Color3.fromRGB(191, 191, 191), Enum.Material.Concrete, folder)
    part("Body", Vector3.new(40, 18, 30), CFrame.new(center.X, 9.5, center.Z), color, Enum.Material.SmoothPlastic, folder)
    part("Roof", Vector3.new(44, 3, 34), CFrame.new(center.X, 20, center.Z), Color3.fromRGB(74, 70, 70), Enum.Material.Slate, folder)
    part("Door", Vector3.new(5, 9, 0.5), CFrame.new(center.X, 4.5, center.Z - 15.3), Color3.fromRGB(104, 73, 52), Enum.Material.Wood, folder)
    local window = part("Window", Vector3.new(12, 7, 0.5), CFrame.new(center.X + 10, 10, center.Z - 15.3), Color3.fromRGB(161, 211, 235), Enum.Material.Glass, folder)
    window.Transparency = 0.2
end
