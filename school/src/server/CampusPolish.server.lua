local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local campus = Workspace:WaitForChild("SchoolCampus", 15)
if not campus then
    warn("CampusPolish: SchoolCampus did not mount")
    return
end

local existing = campus:FindFirstChild("PresentationPolish")
if existing then
    existing:Destroy()
end

local polish = Instance.new("Folder")
polish.Name = "PresentationPolish"
polish.Parent = campus

local function part(name, size, cframe, color, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Transparency = transparency or 0
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = polish
    return p
end

local navy = Color3.fromRGB(32, 56, 91)
local blue = Color3.fromRGB(43, 118, 194)
local red = Color3.fromRGB(214, 67, 74)
local warmWhite = Color3.fromRGB(246, 247, 242)
local dark = Color3.fromRGB(38, 45, 57)
local green = Color3.fromRGB(74, 137, 82)
local glass = Color3.fromRGB(176, 219, 238)

Lighting.Brightness = 2.35
Lighting.ClockTime = 12.2
Lighting.Ambient = Color3.fromRGB(155, 165, 184)
Lighting.OutdoorAmbient = Color3.fromRGB(174, 184, 198)
Lighting.EnvironmentDiffuseScale = 0.45
Lighting.EnvironmentSpecularScale = 0.6

for _, name in ipairs({ "PipHighBloom", "PipHighColor", "PipHighAtmosphere" }) do
    local current = Lighting:FindFirstChild(name)
    if current then
        current:Destroy()
    end
end

local bloom = Instance.new("BloomEffect")
bloom.Name = "PipHighBloom"
bloom.Intensity = 0.16
bloom.Size = 20
bloom.Threshold = 1.15
bloom.Parent = Lighting

local color = Instance.new("ColorCorrectionEffect")
color.Name = "PipHighColor"
color.Brightness = 0.02
color.Contrast = 0.07
color.Saturation = 0.08
color.TintColor = Color3.fromRGB(255, 250, 244)
color.Parent = Lighting

local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "PipHighAtmosphere"
atmosphere.Density = 0.16
atmosphere.Offset = 0.05
atmosphere.Color = Color3.fromRGB(199, 218, 238)
atmosphere.Decay = Color3.fromRGB(110, 126, 150)
atmosphere.Glare = 0.08
atmosphere.Haze = 0.6
atmosphere.Parent = Lighting

-- Hallway ceiling rhythm and floor accents make the long corridor read as a
-- finished school instead of a single empty box. All pieces are decorative.
for index, z in ipairs({ -104, -88, -72, -56, -40, -24, -8, 8, 24, 40, 56, 72, 88, 104 }) do
    local light = part(
        "HallLight" .. tostring(index),
        Vector3.new(16, 0.22, 1.1),
        CFrame.new(0, 13.2, z),
        warmWhite,
        Enum.Material.Neon
    )
    local point = Instance.new("PointLight")
    point.Brightness = 0.45
    point.Range = 17
    point.Color = Color3.fromRGB(255, 244, 222)
    point.Shadows = false
    point.Parent = light

    part(
        "HallFloorAccent" .. tostring(index),
        Vector3.new(30, 0.06, 0.65),
        CFrame.new(0, 1.02, z),
        (index % 2 == 0) and blue or red,
        Enum.Material.SmoothPlastic
    )
end

-- Continuous wall trim visually narrows the corridor without adding collision.
for _, x in ipairs({ -16.6, 16.6 }) do
    part("LowerHallTrim", Vector3.new(0.15, 0.8, 210), CFrame.new(x, 2.2, -2), navy)
    part("UpperHallTrimBlue", Vector3.new(0.16, 0.65, 210), CFrame.new(x, 7.0, -2), blue)
    part("UpperHallTrimRed", Vector3.new(0.17, 0.42, 210), CFrame.new(x, 8.05, -2), red)
end

local function poster(name, x, z, faceRight, primary, text)
    local wallX = faceRight and x or x
    local p = part(
        name,
        Vector3.new(0.22, 5.2, 8.2),
        CFrame.new(wallX, 6.1, z),
        primary,
        Enum.Material.SmoothPlastic
    )
    local gui = Instance.new("SurfaceGui")
    gui.Face = faceRight and Enum.NormalId.Right or Enum.NormalId.Left
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 28
    gui.Parent = p

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
end

poster("PosterClubs", -16.75, 28, true, red, "CLUBS\nGET INVOLVED")
poster("PosterSports", 16.75, 4, false, blue, "PIP HIGH\nATHLETICS")
poster("PosterEvents", -16.75, -36, true, navy, "EVENTS\nTHIS WEEK")
poster("PosterSpirit", 16.75, -62, false, red, "SCHOOL\nSPIRIT")

local function planter(name, x, z)
    part(name .. "Base", Vector3.new(4.5, 2.2, 4.5), CFrame.new(x, 1.7, z), dark, Enum.Material.Slate)
    local trunk = part(name .. "Trunk", Vector3.new(0.9, 4.5, 0.9), CFrame.new(x, 4.6, z), Color3.fromRGB(100, 72, 49), Enum.Material.Wood)
    trunk.CastShadow = true
    local crown = part(name .. "Leaves", Vector3.new(5.8, 5.8, 5.8), CFrame.new(x, 7.6, z), green, Enum.Material.Grass)
    crown.Shape = Enum.PartType.Ball
end

planter("LobbyPlantA", -24, 92)
planter("LobbyPlantB", 24, 92)
planter("ExteriorPlantA", -34, 143)
planter("ExteriorPlantB", 34, 143)

-- Glass entrance doors and sidelights.
for _, x in ipairs({ -6.2, 6.2 }) do
    local door = part(
        "EntranceGlassDoor",
        Vector3.new(10.2, 12.5, 0.28),
        CFrame.new(x, 7.0, 122.1),
        glass,
        Enum.Material.Glass,
        0.38
    )
    door.Reflectance = 0.05
    part("EntranceDoorFrame", Vector3.new(0.45, 13.3, 0.5), CFrame.new(x - 5.1, 7.0, 122.0), dark, Enum.Material.Metal)
    part("EntranceDoorFrame", Vector3.new(0.45, 13.3, 0.5), CFrame.new(x + 5.1, 7.0, 122.0), dark, Enum.Material.Metal)
end

-- Window rhythm across the blue facade.
for _, x in ipairs({ -78, -66, -54, -42, -30, 30, 42, 54, 66, 78 }) do
    local window = part(
        "FacadeWindow",
        Vector3.new(7.2, 9.5, 0.22),
        CFrame.new(x, 14.0, 122.15),
        glass,
        Enum.Material.Glass,
        0.3
    )
    window.Reflectance = 0.08
    part("WindowTop", Vector3.new(7.8, 0.32, 0.35), CFrame.new(x, 18.9, 122.05), warmWhite, Enum.Material.Metal)
    part("WindowBottom", Vector3.new(7.8, 0.32, 0.35), CFrame.new(x, 9.1, 122.05), warmWhite, Enum.Material.Metal)
end

-- Exterior parking/drop-off linework.
for lane = -4, 4 do
    local x = lane * 13
    part("ParkingStripe", Vector3.new(0.28, 0.05, 22), CFrame.new(x, 0.86, 184), warmWhite, Enum.Material.SmoothPlastic)
end
part("DropoffBlue", Vector3.new(96, 0.06, 0.5), CFrame.new(0, 0.87, 158), blue, Enum.Material.SmoothPlastic)
part("DropoffRed", Vector3.new(96, 0.06, 0.5), CFrame.new(0, 0.88, 160), red, Enum.Material.SmoothPlastic)

-- Small wayfinding markers at the center hall.
for index, spec in ipairs({
    { z = 61, text = "CLASSES", color = blue },
    { z = 20, text = "LIBRARY", color = navy },
    { z = -20, text = "GYM", color = red },
    { z = -61, text = "CAFETERIA", color = Color3.fromRGB(214, 155, 58) },
}) do
    local sign = part(
        "Wayfinding" .. tostring(index),
        Vector3.new(0.2, 2.3, 7.5),
        CFrame.new(16.75, 10.2, spec.z),
        spec.color,
        Enum.Material.SmoothPlastic
    )
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Left
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 30
    gui.Parent = sign

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = spec.text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Parent = gui
end
