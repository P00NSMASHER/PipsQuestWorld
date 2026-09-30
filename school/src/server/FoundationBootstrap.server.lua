local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))

local sessions = {}
local periodIndex = 1
local schoolDay = 1
local periodStartedAt = os.clock()

local function currentPeriod()
    return SchoolConfig.Periods[periodIndex]
end

local function getMainSpawn()
    local campus = Workspace:FindFirstChild("SchoolCampus")
    local spawn = campus and campus:FindFirstChild("MainSpawn")
    if spawn and spawn:IsA("SpawnLocation") then
        return spawn
    end
    return nil
end

local function setupPlayer(player)
    if sessions[player] then
        return
    end

    sessions[player] = {
        joinedAt = os.clock(),
        attendance = {},
    }

    local spawn = getMainSpawn()
    if spawn then
        player.RespawnLocation = spawn
    end
end

local function removePlayer(player)
    sessions[player] = nil
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removePlayer)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

task.spawn(function()
    while true do
        task.wait(1)

        if os.clock() - periodStartedAt >= SchoolConfig.PERIOD_SECONDS then
            periodIndex = (periodIndex % #SchoolConfig.Periods) + 1
            if periodIndex == 1 then
                schoolDay += 1
            end
            periodStartedAt = os.clock()
        end

        local period = currentPeriod()
        Workspace:SetAttribute("SchoolDay", schoolDay)
        Workspace:SetAttribute("SchoolPeriodIndex", periodIndex)
        Workspace:SetAttribute("SchoolPeriodId", period.id)
        Workspace:SetAttribute("SchoolPeriodRoom", period.room)
    end
end)
