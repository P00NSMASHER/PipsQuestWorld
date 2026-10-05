-- Server-owned school day/night presentation. Foundation remains authoritative
-- for period state; clients cannot submit or override lighting values.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local SchoolConfig = require(shared:WaitForChild("SchoolConfig"))
local SchoolLightingProfile = require(shared:WaitForChild("SchoolLightingProfile"))

local PERIOD_SECONDS = tonumber(SchoolConfig.PERIOD_SECONDS) or 150
local RESPONSE_RATE = 2.4
local MAX_SMOOTHING_STEP = 0.25
local EMITTER_NAME = "SchoolEveningLight"
local DAY_LAMP_COLOR = Color3.fromRGB(235, 238, 220)
local EVENING_LAMP_COLOR = Color3.fromRGB(255, 230, 174)

local scheduleIndex, scheduleCount = SchoolLightingProfile.normalizeSchedule(
    Workspace:GetAttribute("SchoolPeriodIndex"),
    Workspace:GetAttribute("SchoolPeriodCount")
)
local periodAnchoredAt = os.clock()
local campus = nil
local campusConnections = {}
local lampEmitters = {}
local currentLampLevel = 0

local function smoothingAlpha(deltaTime)
    local step = math.max(0, math.min(MAX_SMOOTHING_STEP, tonumber(deltaTime) or 0))
    return 1 - math.exp(-RESPONSE_RATE * step)
end

local function smoothNumber(current, target, alpha)
    return current + ((target - current) * alpha)
end

local function smoothClock(current, target, alpha)
    local delta = ((target - current + 12) % 24) - 12
    local result = (current + (delta * alpha)) % 24
    if result < 0 then
        result = result + 24
    end
    return result
end

local function toColor3(color)
    return Color3.new(color.r, color.g, color.b)
end

local function disconnectCampusConnections()
    for _, connection in ipairs(campusConnections) do
        connection:Disconnect()
    end
    campusConnections = {}
end

local function registerLampHead(descendant)
    if not descendant:IsA("BasePart") or descendant.Name ~= "LampHead" then
        return
    end

    local emitter = descendant:FindFirstChild(EMITTER_NAME)
    if emitter and not emitter:IsA("PointLight") then
        return
    end
    if not emitter then
        emitter = Instance.new("PointLight")
        emitter.Name = EMITTER_NAME
        emitter.Color = EVENING_LAMP_COLOR
        emitter.Enabled = false
        emitter.Brightness = 0
        emitter.Range = 28
        emitter.Shadows = false
        emitter.Parent = descendant
    end
    lampEmitters[descendant] = emitter
end

local function unregisterLampHead(descendant)
    if lampEmitters[descendant] ~= nil then
        lampEmitters[descendant] = nil
    end
end

local function bindCampus(nextCampus)
    if campus == nextCampus then
        return
    end

    disconnectCampusConnections()
    lampEmitters = {}
    campus = nextCampus
    if not campus then
        return
    end

    for _, descendant in ipairs(campus:GetDescendants()) do
        registerLampHead(descendant)
    end
    campusConnections[#campusConnections + 1] = campus.DescendantAdded:Connect(registerLampHead)
    campusConnections[#campusConnections + 1] = campus.DescendantRemoving:Connect(unregisterLampHead)
end

local function findCampus()
    local candidate = Workspace:FindFirstChild("SchoolCampus")
    if candidate then
        bindCampus(candidate)
    else
        bindCampus(nil)
    end
end

local function refreshScheduleAnchor()
    local nextIndex, nextCount = SchoolLightingProfile.normalizeSchedule(
        Workspace:GetAttribute("SchoolPeriodIndex"),
        Workspace:GetAttribute("SchoolPeriodCount")
    )
    if nextIndex ~= scheduleIndex or nextCount ~= scheduleCount then
        scheduleIndex = nextIndex
        scheduleCount = nextCount
        periodAnchoredAt = os.clock()
    end
end

local function updateLampHeads(profile, alpha)
    currentLampLevel = smoothNumber(currentLampLevel, profile.lampLevel, alpha)
    local neon = currentLampLevel > 0.12
    local enabled = currentLampLevel > 0.01

    for lampHead, emitter in pairs(lampEmitters) do
        if lampHead.Parent == nil or emitter.Parent ~= lampHead then
            lampEmitters[lampHead] = nil
        else
            lampHead.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
            lampHead.Color = DAY_LAMP_COLOR:Lerp(EVENING_LAMP_COLOR, currentLampLevel)
            emitter.Enabled = enabled
            emitter.Brightness = smoothNumber(emitter.Brightness, profile.lampBrightness, alpha)
            emitter.Range = smoothNumber(emitter.Range, profile.lampRange, alpha)
        end
    end
end

local function updateLighting(deltaTime)
    if campus == nil or campus.Parent ~= Workspace then
        findCampus()
    end

    local elapsed = math.max(0, os.clock() - periodAnchoredAt)
    local periodProgress = math.min(1, elapsed / math.max(1, PERIOD_SECONDS))
    local profile = SchoolLightingProfile.forSchedule(scheduleIndex, scheduleCount, periodProgress)
    local alpha = smoothingAlpha(deltaTime)

    Lighting.ClockTime = smoothClock(Lighting.ClockTime, profile.clockTime, alpha)
    Lighting.Ambient = Lighting.Ambient:Lerp(toColor3(profile.ambient), alpha)
    Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(toColor3(profile.outdoorAmbient), alpha)
    Lighting.Brightness = smoothNumber(Lighting.Brightness, profile.brightness, alpha)
    Lighting.FogEnd = smoothNumber(Lighting.FogEnd, profile.fogEnd, alpha)
    updateLampHeads(profile, alpha)
end

Workspace:GetAttributeChangedSignal("SchoolPeriodIndex"):Connect(refreshScheduleAnchor)
Workspace:GetAttributeChangedSignal("SchoolPeriodCount"):Connect(refreshScheduleAnchor)
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "SchoolCampus" then
        bindCampus(child)
    end
end)
Workspace.ChildRemoved:Connect(function(child)
    if child == campus then
        bindCampus(nil)
    end
end)

findCampus()
refreshScheduleAnchor()
RunService.Heartbeat:Connect(updateLighting)
