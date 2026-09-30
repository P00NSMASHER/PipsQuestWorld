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

makePart("CampusGround", Vector3.new(260, 2, 300), CFrame.new(0, -1, 0), Color3.fromRGB(117, 163, 102), Enum.Material.Grass)
makePart("SchoolFloor", Vector3.new(190, 1, 245), CFrame.new(0, 0, 0), floorColor, Enum.Material.Concrete)

makePart("NorthWall", Vector3.new(190, 18, 2), CFrame.new(0, 9, -122), wallColor, Enum.Material.Brick)
makePart("SouthWall", Vector3.new(190, 18, 2), CFrame.new(0, 9, 122), wallColor, Enum.Material.Brick)
makePart("WestWall", Vector3.new(2, 18, 245), CFrame.new(-95, 9, 0), wallColor, Enum.Material.Brick)
makePart("EastWall", Vector3.new(2, 18, 245), CFrame.new(95, 9, 0), wallColor, Enum.Material.Brick)

makePart("CentralHall", Vector3.new(34, 0.4, 218), CFrame.new(0, 0.7, 0), Color3.fromRGB(238, 225, 190), Enum.Material.WoodPlanks)
makePart("CrossHall", Vector3.new(170, 0.4, 26), CFrame.new(0, 0.7, 72), Color3.fromRGB(238, 225, 190), Enum.Material.WoodPlanks)

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
