--!strict
-- Server adapter for one concise class activity at a time.
-- Foundation owns schedule/world state. This script only reads those seams.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))
local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local EducationEngine = require(schoolFoundation:WaitForChild("EducationEngine"))
local ClassSessionController = require(schoolFoundation:WaitForChild("ClassSessionController"))
local catalog = require(schoolFoundation:WaitForChild("ClassActivityCatalog"))

local engine = EducationEngine.new(catalog, {
    maxAttempts = 2,
    maxDifficultyJump = 1,
})
local controller = ClassSessionController.new(engine)

local subjectByPeriodId = {
    math = "Math",
    ela = "ELA",
    science = "Science",
    social = "SocialStudies",
}

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

local remoteRoot = ReplicatedStorage:WaitForChild(SchoolConfig.Interfaces.remoteFolder)
local classRemoteFolder = getOrCreateFolder(remoteRoot, "ClassEducation")
local getClassState = getOrCreateRemoteFunction(classRemoteFolder, "GetClassState")
local enterClass = getOrCreateRemoteFunction(classRemoteFolder, "EnterClass")
local submitAnswer = getOrCreateRemoteFunction(classRemoteFolder, "SubmitAnswer")
local leaveClass = getOrCreateRemoteFunction(classRemoteFolder, "LeaveClass")

local foundationEvents = ServerScriptService:WaitForChild(SchoolConfig.Interfaces.serverEventFolder)
local periodChanged = foundationEvents:WaitForChild(SchoolConfig.Interfaces.periodChanged)
local sessionEnded = foundationEvents:WaitForChild(SchoolConfig.Interfaces.sessionEnded)

local function readSchedule()
    local schoolDay = Workspace:GetAttribute("SchoolDay")
    local periodIndex = Workspace:GetAttribute("SchoolPeriodIndex")
    local periodId = Workspace:GetAttribute("SchoolPeriodId")
    local room = Workspace:GetAttribute("SchoolPeriodRoom")

    if type(schoolDay) ~= "number"
        or type(periodIndex) ~= "number"
        or type(periodId) ~= "string"
        or type(room) ~= "string" then
        return nil
    end

    local period = SchoolConfig.Periods[periodIndex]
    if not period or period.id ~= periodId or period.room ~= room then
        return nil
    end

    local roomConfig = SchoolConfig.Rooms[room]
    if not roomConfig then
        return nil
    end

    return {
        schoolDay = schoolDay,
        periodIndex = periodIndex,
        periodId = periodId,
        periodLabel = period.label,
        room = room,
        roomDisplayName = roomConfig.displayName,
        subject = subjectByPeriodId[periodId],
        classKey = tostring(schoolDay) .. ":" .. tostring(periodIndex) .. ":" .. periodId,
    }
end

local function playerKey(player)
    return tostring(player.UserId)
end

local function isAtCurrentRoom(player, schedule)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end
    local roomConfig = SchoolConfig.Rooms[schedule.room]
    if not roomConfig then
        return false
    end
    return (root.Position - roomConfig.position).Magnitude <= SchoolConfig.ATTENDANCE_RADIUS
end

local function safeDiscovery(player)
    local schedule = readSchedule()
    if not schedule then
        return {
            available = false,
            code = "foundation_state_unavailable",
        }
    end

    local snapshot = controller:getPlayerSnapshot(playerKey(player))
    return {
        available = true,
        schoolDay = schedule.schoolDay,
        periodIndex = schedule.periodIndex,
        periodId = schedule.periodId,
        periodLabel = schedule.periodLabel,
        room = schedule.room,
        roomDisplayName = schedule.roomDisplayName,
        classKey = schedule.classKey,
        academic = schedule.subject ~= nil,
        canEnter = schedule.subject ~= nil and isAtCurrentRoom(player, schedule),
        active = snapshot.active,
        completionCount = snapshot.completionCount,
    }
end

getClassState.OnServerInvoke = function(player)
    return safeDiscovery(player)
end

enterClass.OnServerInvoke = function(player)
    local schedule = readSchedule()
    if not schedule then
        return {
            accepted = false,
            code = "foundation_state_unavailable",
        }
    end
    if not schedule.subject then
        return {
            accepted = false,
            code = "non_academic_period",
            classKey = schedule.classKey,
            returnToFreeRoam = true,
        }
    end
    if not isAtCurrentRoom(player, schedule) then
        return {
            accepted = false,
            code = "not_at_classroom",
            classKey = schedule.classKey,
        }
    end

    local response = controller:enter(
        playerKey(player),
        schedule.classKey,
        schedule.subject,
        1
    )
    response.periodLabel = schedule.periodLabel
    response.roomDisplayName = schedule.roomDisplayName
    return response
end

submitAnswer.OnServerInvoke = function(player, classKey, activityId, submissionId, choiceIndex)
    if type(classKey) ~= "string"
        or type(activityId) ~= "string"
        or type(submissionId) ~= "string"
        or type(choiceIndex) ~= "number" then
        return {
            accepted = false,
            code = "invalid_submission",
        }
    end

    local schedule = readSchedule()
    if not schedule or schedule.classKey ~= classKey then
        controller:leave(playerKey(player), "period_changed")
        return {
            accepted = false,
            code = "late_submission",
            returnToFreeRoam = true,
        }
    end

    if not isAtCurrentRoom(player, schedule) then
        controller:leave(playerKey(player), "left_classroom")
        return {
            accepted = false,
            code = "left_classroom",
            returnToFreeRoam = true,
        }
    end

    return controller:submit(
        playerKey(player),
        classKey,
        activityId,
        submissionId,
        choiceIndex
    )
end

leaveClass.OnServerInvoke = function(player)
    return controller:leave(playerKey(player), "requested")
end

periodChanged.Event:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        controller:leave(playerKey(player), "period_changed")
    end
end)

sessionEnded.Event:Connect(function(player)
    controller:leave(playerKey(player), "session_ended")
end)
