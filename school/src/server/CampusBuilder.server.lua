local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))

local existing = Workspace:FindFirstChild("SchoolCampus")
if existing then
    existing:Destroy()
end

local campus = Instance.new("Folder")
campus.Name = "SchoolCampus"
campus.Parent = Workspace

local geometry = Instance.new("Folder")
geometry.Name = "Geometry"
geometry.Parent = campus

local roomSpawns = Instance.new("Folder")
roomSpawns.Name = "RoomSpawns"
roomSpawns.Parent = campus

local function makePart(name, size, cframe, color, material, parent)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent or geometry
    return part
end

local function makeLabel(text, cframe)
    local sign = makePart("Sign_" .. text:gsub("%W", ""), Vector3.new(18, 5, 0.6), cframe, Color3.fromRGB(35, 45, 64), Enum.Material.SmoothPlastic)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 40
    gui.Parent = sign

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Parent = gui
end

local wallColor = Color3.fromRGB(232, 236, 243)
local floorColor = Color3.fromRGB(203, 210, 220)
local accentA = Color3.fromRGB(92, 132, 204)
local accentB = Color3.fromRGB(126, 92, 181)

makePart("CampusGround", Vector3.new(720, 2, 820), CFrame.new(0, -1, 185), Color3.fromRGB(117, 163, 102), Enum.Material.Grass)
makePart("SchoolFloor", Vector3.new(190, 1, 245), CFrame.new(0, 0, 0), floorColor, Enum.Material.Concrete)

makePart("NorthWall", Vector3.new(190, 18, 2), CFrame.new(0, 9, -122), wallColor, Enum.Material.Brick)
makePart("SouthWallLeft", Vector3.new(80, 18, 2), CFrame.new(-55, 9, 122), wallColor, Enum.Material.Brick)
makePart("SouthWallRight", Vector3.new(80, 18, 2), CFrame.new(55, 9, 122), wallColor, Enum.Material.Brick)
makePart("SouthWallHeader", Vector3.new(30, 5, 2), CFrame.new(0, 15.5, 122), wallColor, Enum.Material.Brick)
makePart("WestWall", Vector3.new(2, 18, 245), CFrame.new(-95, 9, 0), wallColor, Enum.Material.Brick)
makePart("EastWall", Vector3.new(2, 18, 245), CFrame.new(95, 9, 0), wallColor, Enum.Material.Brick)

makePart("CentralHall", Vector3.new(34, 0.4, 218), CFrame.new(0, 0.7, 0), Color3.fromRGB(238, 225, 190), Enum.Material.WoodPlanks)
makePart("CrossHall", Vector3.new(170, 0.4, 26), CFrame.new(0, 0.7, 72), Color3.fromRGB(238, 225, 190), Enum.Material.WoodPlanks)

-- Give the school a readable high-school interior spine instead of an empty prototype corridor.
local trimColor = Color3.fromRGB(44, 62, 92)
local metalColor = Color3.fromRGB(74, 92, 120)
local glassColor = Color3.fromRGB(184, 218, 232)

makePart("FrontLobbyFloor", Vector3.new(54, 0.45, 32), CFrame.new(0, 0.75, 101), Color3.fromRGB(225, 229, 234), Enum.Material.Marble)
makePart("FrontDesk", Vector3.new(22, 4, 5), CFrame.new(-19, 2.5, 96), Color3.fromRGB(123, 88, 61), Enum.Material.Wood)
makePart("FrontDeskTop", Vector3.new(23, 0.5, 6), CFrame.new(-19, 4.7, 96), Color3.fromRGB(61, 68, 82), Enum.Material.SmoothPlastic)
makePart("EntryMat", Vector3.new(16, 0.12, 8), CFrame.new(0, 1.05, 111), trimColor, Enum.Material.Fabric)

local trophyGlass = makePart("TrophyCaseGlass", Vector3.new(24, 8, 1), CFrame.new(32, 5, 84), glassColor, Enum.Material.Glass)
trophyGlass.Transparency = 0.35
trophyGlass.CanCollide = false
makePart("TrophyCaseBase", Vector3.new(25, 1, 2.4), CFrame.new(32, 1.5, 84), trimColor, Enum.Material.SmoothPlastic)
makePart("TrophyCaseTop", Vector3.new(25, 0.8, 2.4), CFrame.new(32, 9.2, 84), trimColor, Enum.Material.SmoothPlastic)

local function buildLockerBank(sideX, startZ, count)
    for index = 0, count - 1 do
        local z = startZ + index * 4
        local locker = makePart(
            "Locker",
            Vector3.new(1.2, 7, 3.4),
            CFrame.new(sideX, 4, z),
            metalColor,
            Enum.Material.Metal
        )
        local vent = makePart(
            "LockerVent",
            Vector3.new(0.12, 0.18, 1.4),
            CFrame.new(sideX + ((sideX < 0) and 0.66 or -0.66), 5.2, z),
            Color3.fromRGB(32, 39, 52),
            Enum.Material.Metal
        )
        vent.CanCollide = false
    end
end

buildLockerBank(-15.9, -92, 33)
buildLockerBank(15.9, -92, 33)

for _, z in ipairs({-70, -22, 28, 64}) do
    makePart("HallBench", Vector3.new(8, 1.2, 2.4), CFrame.new(-9.5, 1.5, z), Color3.fromRGB(137, 96, 62), Enum.Material.Wood)
    makePart("HallBenchLegA", Vector3.new(0.7, 1.4, 2), CFrame.new(-12.5, 0.9, z), Color3.fromRGB(54, 57, 64), Enum.Material.Metal)
    makePart("HallBenchLegB", Vector3.new(0.7, 1.4, 2), CFrame.new(-6.5, 0.9, z), Color3.fromRGB(54, 57, 64), Enum.Material.Metal)
end

for _, z in ipairs({-104, -55, -6, 43, 92}) do
    makePart("HallCeilingBeam", Vector3.new(34, 0.7, 1.2), CFrame.new(0, 13.8, z), trimColor, Enum.Material.SmoothPlastic)
end

local function buildClassroom(roomName, center, accent)
    local roomFolder = Instance.new("Folder")
    roomFolder.Name = roomName
    roomFolder.Parent = geometry

    makePart("Floor", Vector3.new(58, 0.5, 42), CFrame.new(center.X, 0.6, center.Z), Color3.fromRGB(220, 225, 231), Enum.Material.Concrete, roomFolder)
    makePart("BackWall", Vector3.new(58, 14, 1), CFrame.new(center.X, 7, center.Z - 21), wallColor, Enum.Material.SmoothPlastic, roomFolder)
    makePart("SideWallA", Vector3.new(1, 14, 42), CFrame.new(center.X - 29, 7, center.Z), wallColor, Enum.Material.SmoothPlastic, roomFolder)
    makePart("SideWallB", Vector3.new(1, 14, 42), CFrame.new(center.X + 29, 7, center.Z), wallColor, Enum.Material.SmoothPlastic, roomFolder)
    makePart("FrontStripA", Vector3.new(22, 14, 1), CFrame.new(center.X - 18, 7, center.Z + 21), wallColor, Enum.Material.SmoothPlastic, roomFolder)
    makePart("FrontStripB", Vector3.new(22, 14, 1), CFrame.new(center.X + 18, 7, center.Z + 21), wallColor, Enum.Material.SmoothPlastic, roomFolder)
    makePart("Whiteboard", Vector3.new(28, 8, 0.5), CFrame.new(center.X, 8, center.Z - 20.2), Color3.fromRGB(245, 247, 250), Enum.Material.SmoothPlastic, roomFolder)
    makePart("TeacherDesk", Vector3.new(9, 3, 4), CFrame.new(center.X, 2, center.Z - 13), accent, Enum.Material.Wood, roomFolder)

    for row = 0, 2 do
        for col = 0, 3 do
            local x = center.X - 18 + (col * 12)
            local z = center.Z - 2 + (row * 9)
            makePart("Desk", Vector3.new(7, 2.5, 4), CFrame.new(x, 1.8, z), Color3.fromRGB(151, 116, 84), Enum.Material.Wood, roomFolder)
        end
    end

    makeLabel(SchoolConfig.Rooms[roomName].displayName, CFrame.new(center.X, 8, center.Z + 20.5) * CFrame.Angles(0, math.rad(180), 0))

    local spawn = Instance.new("Part")
    spawn.Name = roomName
    spawn.Size = Vector3.new(4, 1, 4)
    spawn.CFrame = CFrame.new(center.X, 2, center.Z + 13)
    spawn.Transparency = 1
    spawn.CanCollide = false
    spawn.Anchored = true
    spawn.Parent = roomSpawns
end

for roomName, room in pairs(SchoolConfig.Rooms) do
    if roomName == "Cafeteria" then
        local center = room.position
        makePart("CafeteriaFloor", Vector3.new(78, 0.5, 38), CFrame.new(center.X, 0.6, center.Z), Color3.fromRGB(219, 224, 229), Enum.Material.Concrete)
        for row = 0, 2 do
            for col = 0, 3 do
                local x = center.X - 27 + col * 18
                local z = center.Z - 10 + row * 10
                makePart("LunchTable", Vector3.new(12, 2.5, 5), CFrame.new(x, 1.8, z), Color3.fromRGB(166, 124, 83), Enum.Material.Wood)
            end
        end
        makeLabel("Cafeteria", CFrame.new(center.X, 8, center.Z - 18))
        local spawn = Instance.new("Part")
        spawn.Name = roomName
        spawn.Size = Vector3.new(4, 1, 4)
        spawn.CFrame = CFrame.new(center.X, 2, center.Z)
        spawn.Transparency = 1
        spawn.CanCollide = false
        spawn.Anchored = true
        spawn.Parent = roomSpawns
    elseif roomName == "Gym" then
        local center = room.position
        makePart("GymFloor", Vector3.new(82, 0.5, 46), CFrame.new(center.X, 0.6, center.Z), Color3.fromRGB(194, 154, 104), Enum.Material.WoodPlanks)
        makePart("CenterLine", Vector3.new(1, 0.15, 42), CFrame.new(center.X, 0.95, center.Z), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic)
        makeLabel("Gym", CFrame.new(center.X, 8, center.Z + 22))
        local spawn = Instance.new("Part")
        spawn.Name = roomName
        spawn.Size = Vector3.new(4, 1, 4)
        spawn.CFrame = CFrame.new(center.X, 2, center.Z + 12)
        spawn.Transparency = 1
        spawn.CanCollide = false
        spawn.Anchored = true
        spawn.Parent = roomSpawns
    elseif roomName == "Courtyard" then
        local center = room.position
        makePart("CourtyardPad", Vector3.new(72, 0.5, 44), CFrame.new(center.X, 0.6, center.Z), Color3.fromRGB(170, 185, 159), Enum.Material.Slate)
        makePart("CourtyardTreeTrunk", Vector3.new(3, 10, 3), CFrame.new(center.X, 5, center.Z), Color3.fromRGB(106, 76, 55), Enum.Material.Wood)
        local leaves = makePart("CourtyardTreeLeaves", Vector3.new(14, 14, 14), CFrame.new(center.X, 13, center.Z), Color3.fromRGB(79, 142, 82), Enum.Material.Grass)
        leaves.Shape = Enum.PartType.Ball
        local spawn = Instance.new("Part")
        spawn.Name = roomName
        spawn.Size = Vector3.new(4, 1, 4)
        spawn.CFrame = CFrame.new(center.X - 18, 2, center.Z)
        spawn.Transparency = 1
        spawn.CanCollide = false
        spawn.Anchored = true
        spawn.Parent = roomSpawns
    elseif roomName == "Library" then
        buildClassroom(roomName, room.position, Color3.fromRGB(70, 138, 116))
        for i = -2, 2 do
            makePart("Bookshelf", Vector3.new(3, 9, 10), CFrame.new(room.position.X + i * 10, 4.8, room.position.Z - 13), Color3.fromRGB(98, 70, 52), Enum.Material.Wood)
        end
    else
        buildClassroom(roomName, room.position, (room.position.X < 0) and accentA or accentB)
    end
end

-- Room-specific dressing keeps each class visually distinct while reusing the canonical room registry.
local science = SchoolConfig.Rooms.Science.position
for row = -1, 1 do
    for col = -1, 1 do
        local x = science.X + col * 16
        local z = science.Z + row * 10
        makePart("LabTable", Vector3.new(11, 3, 4.5), CFrame.new(x, 2, z), Color3.fromRGB(120, 132, 145), Enum.Material.Metal)
        makePart("LabTop", Vector3.new(11.5, 0.45, 5), CFrame.new(x, 3.7, z), Color3.fromRGB(224, 228, 232), Enum.Material.SmoothPlastic)
    end
end
makePart("ScienceStorage", Vector3.new(18, 8, 3), CFrame.new(science.X + 16, 4.5, science.Z - 17), Color3.fromRGB(85, 104, 118), Enum.Material.Metal)

local mathRoom = SchoolConfig.Rooms.Math.position
for offset = -1, 1 do
    makePart("MathBoardPanel", Vector3.new(9, 6, 0.35), CFrame.new(mathRoom.X + offset * 10, 8, mathRoom.Z - 20.55), Color3.fromRGB(36, 50, 70), Enum.Material.SmoothPlastic)
end

local elaRoom = SchoolConfig.Rooms.ELA.position
for offset = -2, 2 do
    makePart("ELAReadingShelf", Vector3.new(3, 8, 8), CFrame.new(elaRoom.X + offset * 9, 4.5, elaRoom.Z - 15), Color3.fromRGB(103, 73, 50), Enum.Material.Wood)
end
makePart("ELAReadingTable", Vector3.new(13, 2.5, 7), CFrame.new(elaRoom.X, 1.8, elaRoom.Z + 10), Color3.fromRGB(149, 109, 75), Enum.Material.Wood)

local social = SchoolConfig.Rooms.SocialStudies.position
makePart("SocialDisplayWall", Vector3.new(32, 7, 0.45), CFrame.new(social.X, 8, social.Z - 20.5), Color3.fromRGB(116, 91, 67), Enum.Material.Wood)
for offset = -1, 1 do
    makePart("SocialDisplayPanel", Vector3.new(8, 5, 0.2), CFrame.new(social.X + offset * 10, 8, social.Z - 20.15), Color3.fromRGB(210, 205, 186), Enum.Material.SmoothPlastic)
end

local library = SchoolConfig.Rooms.Library.position
makePart("LibraryReadingTableA", Vector3.new(16, 2.5, 7), CFrame.new(library.X - 11, 1.8, library.Z + 8), Color3.fromRGB(140, 102, 70), Enum.Material.Wood)
makePart("LibraryReadingTableB", Vector3.new(16, 2.5, 7), CFrame.new(library.X + 11, 1.8, library.Z + 8), Color3.fromRGB(140, 102, 70), Enum.Material.Wood)
makePart("LibraryCheckout", Vector3.new(18, 4, 5), CFrame.new(library.X, 2.5, library.Z + 15), Color3.fromRGB(93, 70, 54), Enum.Material.Wood)

local cafeteria = SchoolConfig.Rooms.Cafeteria.position
makePart("ServingCounter", Vector3.new(44, 4, 5), CFrame.new(cafeteria.X, 2.5, cafeteria.Z - 15), Color3.fromRGB(151, 159, 166), Enum.Material.Metal)
makePart("ServingCounterTop", Vector3.new(45, 0.5, 6), CFrame.new(cafeteria.X, 4.7, cafeteria.Z - 15), Color3.fromRGB(225, 228, 232), Enum.Material.SmoothPlastic)

local gym = SchoolConfig.Rooms.Gym.position
makePart("CenterCircle", Vector3.new(18, 0.12, 18), CFrame.new(gym.X, 0.95, gym.Z), Color3.fromRGB(235, 235, 235), Enum.Material.SmoothPlastic)
for _, direction in ipairs({-1, 1}) do
    local z = gym.Z + direction * 19
    makePart("Backboard", Vector3.new(12, 7, 0.6), CFrame.new(gym.X, 10, z), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic)
    local rim = makePart("BasketRim", Vector3.new(4, 0.4, 4), CFrame.new(gym.X, 7.2, z - direction * 1.4), Color3.fromRGB(220, 95, 55), Enum.Material.Metal)
    rim.Shape = Enum.PartType.Cylinder
    rim.CFrame = rim.CFrame * CFrame.Angles(0, 0, math.rad(90))
end

-- Original campus exterior: a readable entrance, drop-off, parking, and street edge.
makePart("FrontPlaza", Vector3.new(116, 0.45, 34), CFrame.new(0, 0.7, 140), Color3.fromRGB(196, 199, 202), Enum.Material.Concrete)
makePart("EntryWalk", Vector3.new(18, 0.3, 82), CFrame.new(0, 0.75, 171), Color3.fromRGB(204, 207, 211), Enum.Material.Concrete)
makePart("EntryCanopy", Vector3.new(38, 1.2, 14), CFrame.new(0, 13.5, 129), trimColor, Enum.Material.Metal)
for _, x in ipairs({-9, 9}) do
    makePart("CanopyPost", Vector3.new(1.2, 13, 1.2), CFrame.new(x, 6.7, 134), trimColor, Enum.Material.Metal)
end

for _, x in ipairs({-8, 0, 8}) do
    local door = makePart("FrontGlassDoor", Vector3.new(7, 11, 0.45), CFrame.new(x, 6, 121.6), glassColor, Enum.Material.Glass)
    door.Transparency = 0.38
    door.CanCollide = false
end

makePart("DropOffLane", Vector3.new(210, 0.35, 32), CFrame.new(0, 0.55, 169), Color3.fromRGB(63, 66, 72), Enum.Material.Asphalt)
makePart("DropOffStripe", Vector3.new(204, 0.08, 0.35), CFrame.new(0, 0.78, 158), Color3.fromRGB(244, 205, 72), Enum.Material.SmoothPlastic)

makePart("ParkingLot", Vector3.new(230, 0.35, 104), CFrame.new(0, 0.52, 228), Color3.fromRGB(67, 70, 75), Enum.Material.Asphalt)
for col = -5, 5 do
    local x = col * 18
    makePart("ParkingStripeNorth", Vector3.new(0.3, 0.08, 33), CFrame.new(x, 0.75, 205), Color3.fromRGB(235, 235, 230), Enum.Material.SmoothPlastic)
    makePart("ParkingStripeSouth", Vector3.new(0.3, 0.08, 33), CFrame.new(x, 0.75, 251), Color3.fromRGB(235, 235, 230), Enum.Material.SmoothPlastic)
end

makePart("CampusRoad", Vector3.new(430, 0.4, 38), CFrame.new(0, 0.45, 300), Color3.fromRGB(54, 57, 62), Enum.Material.Asphalt)
makePart("RoadCenterLine", Vector3.new(420, 0.08, 0.35), CFrame.new(0, 0.7, 300), Color3.fromRGB(245, 205, 69), Enum.Material.SmoothPlastic)

-- Original town shell provides stable destinations for jobs, vehicles, housing, and shopping.
makePart("TownConnectorRoad", Vector3.new(38, 0.4, 250), CFrame.new(0, 0.45, 410), Color3.fromRGB(54, 57, 62), Enum.Material.Asphalt)
makePart("TownConnectorLine", Vector3.new(0.35, 0.08, 240), CFrame.new(0, 0.7, 410), Color3.fromRGB(245, 205, 69), Enum.Material.SmoothPlastic)
makePart("TownMainStreet", Vector3.new(430, 0.4, 38), CFrame.new(0, 0.45, 390), Color3.fromRGB(54, 57, 62), Enum.Material.Asphalt)
makePart("TownMainStreetLine", Vector3.new(420, 0.08, 0.35), CFrame.new(0, 0.7, 390), Color3.fromRGB(245, 205, 69), Enum.Material.SmoothPlastic)
makePart("TownNorthWalk", Vector3.new(430, 0.25, 10), CFrame.new(0, 0.72, 365), Color3.fromRGB(198, 201, 204), Enum.Material.Concrete)
makePart("TownSouthWalk", Vector3.new(430, 0.25, 10), CFrame.new(0, 0.72, 415), Color3.fromRGB(198, 201, 204), Enum.Material.Concrete)

local function buildStorefront(key, width, depth, height, color)
    local location = SchoolConfig.WorldLocations[key]
    local center = location.position
    makePart(key .. "Floor", Vector3.new(width, 0.5, depth), CFrame.new(center.X, 0.6, center.Z), Color3.fromRGB(211, 214, 218), Enum.Material.Concrete)
    makePart(key .. "Back", Vector3.new(width, height, 1), CFrame.new(center.X, height / 2, center.Z + depth / 2), color, Enum.Material.Brick)
    makePart(key .. "Left", Vector3.new(1, height, depth), CFrame.new(center.X - width / 2, height / 2, center.Z), color, Enum.Material.Brick)
    makePart(key .. "Right", Vector3.new(1, height, depth), CFrame.new(center.X + width / 2, height / 2, center.Z), color, Enum.Material.Brick)
    makePart(key .. "Roof", Vector3.new(width + 2, 1, depth + 2), CFrame.new(center.X, height, center.Z), Color3.fromRGB(55, 59, 67), Enum.Material.Metal)
    local window = makePart(key .. "Window", Vector3.new(width - 8, 8, 0.45), CFrame.new(center.X, 7, center.Z - depth / 2 + 0.4), glassColor, Enum.Material.Glass)
    window.Transparency = 0.3
    window.CanCollide = false
    local door = makePart(key .. "Door", Vector3.new(6, 9, 0.5), CFrame.new(center.X, 5, center.Z - depth / 2 + 0.25), glassColor, Enum.Material.Glass)
    door.Transparency = 0.24
    door.CanCollide = false
    makeLabel(location.displayName, CFrame.new(center.X, height - 3, center.Z - depth / 2 - 0.35))
end

buildStorefront("Cafe", 58, 42, 22, Color3.fromRGB(173, 112, 78))
buildStorefront("StyleShop", 58, 42, 22, Color3.fromRGB(126, 100, 168))
buildStorefront("AutoShop", 66, 48, 24, Color3.fromRGB(82, 112, 145))
buildStorefront("Market", 64, 46, 23, Color3.fromRGB(116, 145, 99))

-- Foundation-owned world seam for the vehicle lifecycle lane.
-- Free Roam owns vehicle creation/physics; Foundation owns only the stable place to spawn it.
local vehicleWorld = SchoolConfig.VehicleWorld
local vehicleSpawn = SchoolConfig.WorldLocations[vehicleWorld.spawnLocation].position
local vehicleRoadEntry = SchoolConfig.WorldLocations[vehicleWorld.roadEntryLocation].position
assert(vehicleSpawn and vehicleRoadEntry, "vehicle world contract locations must exist")

makePart(
    "AutoShopVehicleSpawnPad",
    Vector3.new(24, 0.25, 16),
    CFrame.new(vehicleSpawn.X, 0.73, vehicleSpawn.Z),
    Color3.fromRGB(89, 94, 101),
    Enum.Material.Asphalt
)
makePart(
    "AutoShopVehicleSpawnMark",
    Vector3.new(0.35, 0.08, 12),
    CFrame.new(vehicleSpawn.X, 0.9, vehicleSpawn.Z),
    Color3.fromRGB(235, 235, 230),
    Enum.Material.SmoothPlastic
)

local park = SchoolConfig.WorldLocations.TownPark.position
makePart("TownParkPad", Vector3.new(98, 0.35, 70), CFrame.new(park.X, 0.55, park.Z), Color3.fromRGB(143, 177, 126), Enum.Material.Grass)
makePart("TownParkPathA", Vector3.new(86, 0.2, 8), CFrame.new(park.X, 0.75, park.Z), Color3.fromRGB(205, 202, 190), Enum.Material.Concrete)
makePart("TownParkPathB", Vector3.new(8, 0.2, 58), CFrame.new(park.X, 0.75, park.Z), Color3.fromRGB(205, 202, 190), Enum.Material.Concrete)
makePart("TownParkFountainBase", Vector3.new(18, 2, 18), CFrame.new(park.X, 1.5, park.Z), Color3.fromRGB(150, 155, 164), Enum.Material.Slate)
local fountain = makePart("TownParkWater", Vector3.new(14, 0.5, 14), CFrame.new(park.X, 2.7, park.Z), Color3.fromRGB(86, 167, 211), Enum.Material.Glass)
fountain.Transparency = 0.2

local neighborhood = SchoolConfig.WorldLocations.Neighborhood.position
makePart("NeighborhoodRoad", Vector3.new(360, 0.4, 30), CFrame.new(neighborhood.X, 0.45, neighborhood.Z), Color3.fromRGB(58, 61, 66), Enum.Material.Asphalt)
for index, x in ipairs({-180, -120, -60, 60, 120, 180}) do
    local houseColor = (index % 2 == 0) and Color3.fromRGB(191, 177, 155) or Color3.fromRGB(176, 190, 199)
    makePart("HouseBody", Vector3.new(44, 18, 32), CFrame.new(x, 9, neighborhood.Z + 34), houseColor, Enum.Material.Brick)
    makePart("HouseRoof", Vector3.new(48, 3, 36), CFrame.new(x, 19.5, neighborhood.Z + 34), Color3.fromRGB(76, 72, 71), Enum.Material.Slate)
    local houseDoor = makePart("HouseDoor", Vector3.new(6, 10, 0.5), CFrame.new(x, 5, neighborhood.Z + 17.75), Color3.fromRGB(94, 70, 54), Enum.Material.Wood)
    houseDoor.CanCollide = false
    for _, wx in ipairs({-12, 12}) do
        local window = makePart("HouseWindow", Vector3.new(8, 7, 0.4), CFrame.new(x + wx, 10, neighborhood.Z + 17.7), glassColor, Enum.Material.Glass)
        window.Transparency = 0.25
        window.CanCollide = false
    end
end

local function buildCampusTree(x, z)
    makePart("TreeTrunk", Vector3.new(2.4, 10, 2.4), CFrame.new(x, 5, z), Color3.fromRGB(103, 76, 55), Enum.Material.Wood)
    local crown = makePart("TreeCrown", Vector3.new(12, 12, 12), CFrame.new(x, 13, z), Color3.fromRGB(74, 137, 77), Enum.Material.Grass)
    crown.Shape = Enum.PartType.Ball
end

for _, position in ipairs({
    Vector3.new(-78, 0, 145),
    Vector3.new(78, 0, 145),
    Vector3.new(-122, 0, 184),
    Vector3.new(122, 0, 184),
    Vector3.new(-138, 0, 278),
    Vector3.new(138, 0, 278),
}) do
    buildCampusTree(position.X, position.Z)
end

for _, x in ipairs({-92, 92}) do
    for _, z in ipairs({163, 214, 265}) do
        makePart("LampPost", Vector3.new(0.8, 14, 0.8), CFrame.new(x, 7, z), Color3.fromRGB(48, 53, 61), Enum.Material.Metal)
        local lamp = makePart("LampHead", Vector3.new(4, 1, 2), CFrame.new(x, 14, z), Color3.fromRGB(235, 238, 220), Enum.Material.Neon)
        lamp.CanCollide = false
    end
end

makeLabel("PIP HIGH", CFrame.new(0, 11, 123.2) * CFrame.Angles(0, math.rad(180), 0))

local spawn = Instance.new("SpawnLocation")
spawn.Name = "MainSpawn"
spawn.Size = Vector3.new(10, 1, 10)
spawn.CFrame = CFrame.new(0, 1, 105)
spawn.Anchored = true
spawn.Neutral = true
spawn.Color = Color3.fromRGB(111, 174, 229)
spawn.Material = Enum.Material.Neon
spawn.Parent = campus

makeLabel("PIP HIGH", CFrame.new(0, 12, 119.5) * CFrame.Angles(0, math.rad(180), 0))
