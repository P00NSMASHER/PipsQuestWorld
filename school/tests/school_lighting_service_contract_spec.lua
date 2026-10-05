local path = "school/src/server/SchoolLightingService.server.lua"
local handle = assert(io.open(path, "r"))
local source = handle:read("*a")
handle:close()

assert(loadfile(path), "lighting service must remain Lua 5.4 parseable")

local function has(fragment, label)
    if not source:find(fragment, 1, true) then
        error("missing lighting contract: " .. (label or fragment), 2)
    end
end

local function lacks(fragment, label)
    if source:find(fragment, 1, true) then
        error("forbidden lighting contract: " .. (label or fragment), 2)
    end
end

has('Workspace:GetAttribute("SchoolPeriodIndex")', "server period index")
has('Workspace:GetAttribute("SchoolPeriodCount")', "server period count")
has("SchoolLightingProfile.forSchedule", "pure profile integration")
has("RunService.Heartbeat:Connect(updateLighting)", "smooth runtime updates")
has("Lighting.ClockTime", "clock update")
has("Lighting.Ambient", "ambient update")
has("Lighting.OutdoorAmbient", "outdoor ambient update")
has("Lighting.Brightness", "brightness update")
has("Lighting.FogEnd", "fog update")
has('descendant.Name ~= "LampHead"', "campus lamp targeting")
has('Instance.new("PointLight")', "evening light emitter")
has("Enum.Material.Neon", "evening neon state")
has("Enum.Material.SmoothPlastic", "daytime lamp state")

lacks("OnServerEvent", "client event authority")
lacks("OnServerInvoke", "client function authority")
lacks("RemoteEvent", "remote event dependency")
lacks("RemoteFunction", "remote function dependency")

print("SCHOOL_LIGHTING_SERVICE_CONTRACT_PASS")
