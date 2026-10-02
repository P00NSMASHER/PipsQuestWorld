--!strict
-- Server adapter for the canonical class -> durable progression vertical slice.
-- Foundation owns schedule/world state; Class/Education owns class semantics;
-- Progression owns durable progression. This file only wires those authorities.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))
local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local EducationEngine = require(schoolFoundation:WaitForChild("EducationEngine"))
local ClassSessionController = require(schoolFoundation:WaitForChild("ClassSessionController"))
local ClassProgressionCoordinator = require(schoolFoundation:WaitForChild("ClassProgressionCoordinator"))
local ProgressionRepository = require(schoolFoundation:WaitForChild("ProgressionRepository"))
local ProgressionBinding = require(schoolFoundation:WaitForChild("ProgressionBinding"))
local ProgressionDataStore = require(schoolFoundation:WaitForChild("ProgressionDataStore"))
local catalog = require(schoolFoundation:WaitForChild("ClassActivityCatalog"))

local function createProgressionStore()
    if RunService:IsStudio() and game.GameId == 0 then
        local ProgressionStudioStore = require(
            schoolFoundation:WaitForChild("ProgressionStudioStore")
        )
        Workspace:SetAttribute("ProgressionPersistenceMode", "StudioMemoryUnpublished")
        return ProgressionStudioStore.new()
    end

    local DataStoreService = game:GetService("DataStoreService")
    Workspace:SetAttribute("ProgressionPersistenceMode", "DataStore")
    return ProgressionDataStore.new(
        DataStoreService:GetDataStore("PipHighProgressionV1")
    )
end

local engine = EducationEngine.new(catalog, {
    maxAttempts = 2,
    maxDifficultyJump = 1,
})
local classController = ClassSessionController.new(engine)
local progressionStore = createProgressionStore()
local coordinator = ClassProgressionCoordinator.new(classController, function(playerId)
    local repository, openError = ProgressionRepository.open(progressionStore, playerId)
    if not repository then
        return nil, openError
    end
    return ProgressionBinding.new(repository)
end)

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
local getProgressionState = getOrCreateRemoteFunction(classRemoteFolder, "GetProgressionState")
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
    local key = playerKey(player)
    local snapshot = coordinator:getPlayerSnapshot(key)
    if not schedule then
        return {
            available = false,
            code = "foundation_state_unavailable",
            progressionPending = snapshot.progressionPending,
            pendingClassKey = snapshot.pendingClassKey,
        }
    end

    local completedCurrentClass = schedule.subject ~= nil
        and coordinator:isClassCompleted(key, schedule.classKey)

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
        canEnter = not snapshot.progressionPending
            and schedule.subject ~= nil
            and not completedCurrentClass
            and isAtCurrentRoom(player, schedule),
        active = snapshot.active,
        completedCurrentClass = completedCurrentClass,
        completionCount = snapshot.completionCount,
        progressionPending = snapshot.progressionPending,
        pendingClassKey = snapshot.pendingClassKey,
    }
end

getClassState.OnServerInvoke = function(player)
    return safeDiscovery(player)
end

getProgressionState.OnServerInvoke = function(player)
    local repository, readError = ProgressionRepository.open(progressionStore, player.UserId)
    if not repository then
        return {
            available = false,
            code = "progression_state_unavailable",
            error = tostring(readError or "unknown"),
        }
    end

    return {
        available = true,
        state = repository:getState(),
    }
end

enterClass.OnServerInvoke = function(player)
    local pending = coordinator:getPending(playerKey(player))
    if pending then
        return {
            accepted = false,
            code = "progression_pending",
            classKey = pending.classKey,
            returnToFreeRoam = false,
        }
    end

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

    local response = coordinator:enter(
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

    local key = playerKey(player)
    local pending = coordinator:getPending(key)
    if pending then
        if pending.classKey ~= classKey or pending.submissionId ~= submissionId then
            return {
                accepted = false,
                code = "progression_pending",
                classKey = pending.classKey,
                returnToFreeRoam = false,
            }
        end
    else
        local schedule = readSchedule()
        if not schedule or schedule.classKey ~= classKey then
            coordinator:leave(key, "period_changed")
            return {
                accepted = false,
                code = "late_submission",
                returnToFreeRoam = true,
            }
        end

        if not isAtCurrentRoom(player, schedule) then
            coordinator:leave(key, "left_classroom")
            return {
                accepted = false,
                code = "left_classroom",
                returnToFreeRoam = true,
            }
        end
    end

    return coordinator:submit(
        player.UserId,
        key,
        classKey,
        activityId,
        submissionId,
        choiceIndex
    )
end

leaveClass.OnServerInvoke = function(player)
    return coordinator:leave(playerKey(player), "requested")
end

periodChanged.Event:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        coordinator:leave(playerKey(player), "period_changed")
    end
end)

sessionEnded.Event:Connect(function(player)
    coordinator:leave(playerKey(player), "session_ended")
end)
