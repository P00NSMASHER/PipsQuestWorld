local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))
local DailySchedule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DailySchedule"))

local sessions = {}
local periodIndex = 1
local schoolDay = 1
local periods = DailySchedule.forDay(schoolDay)
local periodStartedAt = os.clock()
-- A UTC-day epoch keeps reward keys consistent across servers. Server hopping
-- cannot mint a second reward for the same school day/period, while the next
-- real-world day naturally opens a fresh schedule.
local scheduleEpoch = "utc-day-" .. tostring(math.floor(os.time() / 86400))

local function currentPeriod()
    return periods[periodIndex]
end

local function getOrCreateFolder(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing then
        assert(existing:IsA("Folder"), name .. " must be a Folder")
        return existing
    end

    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function getOrCreateRemoteFunction(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing then
        assert(existing:IsA("RemoteFunction"), name .. " must be a RemoteFunction")
        return existing
    end

    local remote = Instance.new("RemoteFunction")
    remote.Name = name
    remote.Parent = parent
    return remote
end

local function getOrCreateBindableEvent(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing then
        assert(existing:IsA("BindableEvent"), name .. " must be a BindableEvent")
        return existing
    end

    local event = Instance.new("BindableEvent")
    event.Name = name
    event.Parent = parent
    return event
end

local remoteFolder = getOrCreateFolder(ReplicatedStorage, SchoolConfig.Interfaces.remoteFolder)
local stateSnapshot = getOrCreateRemoteFunction(remoteFolder, SchoolConfig.Interfaces.stateSnapshot)
local requestTravel = getOrCreateRemoteFunction(remoteFolder, SchoolConfig.Interfaces.requestTravel)

local serverEventFolder = getOrCreateFolder(ServerScriptService, SchoolConfig.Interfaces.serverEventFolder)
local sessionStarted = getOrCreateBindableEvent(serverEventFolder, SchoolConfig.Interfaces.sessionStarted)
local sessionEnded = getOrCreateBindableEvent(serverEventFolder, SchoolConfig.Interfaces.sessionEnded)
local periodChanged = getOrCreateBindableEvent(serverEventFolder, SchoolConfig.Interfaces.periodChanged)

local function snapshot(now)
    local period = currentPeriod()
    local room = SchoolConfig.Rooms[period.room]
    local elapsed = math.max(0, now - periodStartedAt)

    return {
        schoolDay = schoolDay,
        periodIndex = periodIndex,
        periodId = period.id,
        periodLabel = period.label,
        room = period.room,
        roomDisplayName = room and room.displayName or period.room,
        subject = period.subject,
        periodCount = #periods,
        secondsRemaining = math.max(0, math.ceil(SchoolConfig.PERIOD_SECONDS - elapsed)),
    }
end

local function publishState(now)
    local state = snapshot(now)
    Workspace:SetAttribute("SchoolDay", state.schoolDay)
    Workspace:SetAttribute("SchoolScheduleEpoch", scheduleEpoch)
    Workspace:SetAttribute("SchoolPeriodIndex", state.periodIndex)
    Workspace:SetAttribute("SchoolPeriodId", state.periodId)
    Workspace:SetAttribute("SchoolPeriodRoom", state.room)
    Workspace:SetAttribute("SchoolPeriodLabel", state.periodLabel)
    Workspace:SetAttribute("SchoolPeriodSubject", state.subject or "")
    Workspace:SetAttribute("SchoolPeriodCount", state.periodCount)
end

local function advanceSchedule(now)
    while now - periodStartedAt >= SchoolConfig.PERIOD_SECONDS do
        local previousSchoolDay = schoolDay
        local previousPeriodIndex = periodIndex
        local previous = currentPeriod()

        periodStartedAt += SchoolConfig.PERIOD_SECONDS
        periodIndex = (periodIndex % #periods) + 1
        if periodIndex == 1 then
            schoolDay += 1
            periods = DailySchedule.forDay(schoolDay)
        end

        periodChanged:Fire({
            previousSchoolDay = previousSchoolDay,
            previousPeriodIndex = previousPeriodIndex,
            previousPeriodId = previous.id,
            previousRoom = previous.room,
            current = snapshot(periodStartedAt),
        })
    end
end

local function getMainSpawn()
    local campus = Workspace:WaitForChild("SchoolCampus")
    local spawn = campus:WaitForChild("MainSpawn")
    assert(spawn:IsA("SpawnLocation"), "SchoolCampus.MainSpawn must be a SpawnLocation")
    return spawn
end

local function getCurrentRoomSpawn()
    local campus = Workspace:WaitForChild("SchoolCampus")
    local roomSpawns = campus:WaitForChild("RoomSpawns")
    local roomSpawn = roomSpawns:FindFirstChild(currentPeriod().room)
    if not roomSpawn or not roomSpawn:IsA("BasePart") then
        return nil
    end
    return roomSpawn
end

local function setupPlayer(player)
    if sessions[player] then
        return
    end

    sessions[player] = {
        joinedAt = os.clock(),
        attendance = {},
    }

    player.RespawnLocation = getMainSpawn()
    sessionStarted:Fire(player, snapshot(os.clock()))
end

local function removePlayer(player)
    if not sessions[player] then
        return
    end

    sessionEnded:Fire(player, snapshot(os.clock()))
    sessions[player] = nil
end

stateSnapshot.OnServerInvoke = function()
    return snapshot(os.clock())
end

requestTravel.OnServerInvoke = function(player, destinationKey)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        return {
            accepted = false,
            code = "travel_unavailable",
        }
    end

    if destinationKey ~= nil and destinationKey ~= "CurrentClass" then
        if type(destinationKey) ~= "string" then
            return {
                accepted = false,
                code = "invalid_destination",
            }
        end

        local destination = SchoolConfig.WorldLocations[destinationKey]
        if not destination then
            return {
                accepted = false,
                code = "unknown_destination",
            }
        end

        character:PivotTo(CFrame.new(destination.position + SchoolConfig.TRAVEL_OFFSET))
        return {
            accepted = true,
            destination = destinationKey,
            destinationDisplayName = destination.displayName,
        }
    end

    local roomSpawn = getCurrentRoomSpawn()
    if not roomSpawn then
        return {
            accepted = false,
            code = "travel_unavailable",
        }
    end

    character:PivotTo(roomSpawn.CFrame + SchoolConfig.TRAVEL_OFFSET)
    local period = currentPeriod()
    return {
        accepted = true,
        destination = "CurrentClass",
        destinationDisplayName = period.label,
        periodId = period.id,
        room = period.room,
    }
end

publishState(os.clock())

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removePlayer)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

task.spawn(function()
    while true do
        task.wait(1)
        local now = os.clock()
        advanceSchedule(now)
        publishState(now)
    end
end)
