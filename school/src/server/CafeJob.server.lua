--!strict
-- Runtime adapter for the assigned Pip High cafe-job slice.
-- Foundation owns the cafe location; EconomyRepository owns money/persistence semantics.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))
local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local CafeJobController = require(schoolFoundation:WaitForChild("CafeJobController"))
local EconomyRuntime = require(schoolFoundation:WaitForChild("EconomyRuntime"))

local CAFE_RADIUS = 34
local CAFE_WAGE = 25
local cafe = assert(SchoolConfig.WorldLocations.Cafe, "Foundation Cafe location is required")

local controller = CafeJobController.new({
    wage = CAFE_WAGE,
    shiftIdFactory = function(playerId)
        return tostring(playerId) .. ":" .. HttpService:GenerateGUID(false)
    end,
    repositoryFactory = function(playerId)
        return EconomyRuntime.open(playerId, false)
    end,
})

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

local function isAtCafe(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end
    return (root.Position - cafe.position).Magnitude <= CAFE_RADIUS
end

local remoteRoot = ReplicatedStorage:WaitForChild(SchoolConfig.Interfaces.remoteFolder)
local freeRoamRoot = getOrCreateFolder(remoteRoot, "FreeRoam")
local cafeRoot = getOrCreateFolder(freeRoamRoot, "CafeJob")
local getState = getOrCreateRemoteFunction(cafeRoot, "GetState")
local startShift = getOrCreateRemoteFunction(cafeRoot, "StartShift")
local completeTask = getOrCreateRemoteFunction(cafeRoot, "CompleteTask")
local leaveShift = getOrCreateRemoteFunction(cafeRoot, "LeaveShift")

local function discovery(player)
    local state = controller:getState(player.UserId)
    state.available = true
    state.atCafe = isAtCafe(player)
    state.displayName = cafe.displayName
    return state
end

getState.OnServerInvoke = function(player)
    return discovery(player)
end

startShift.OnServerInvoke = function(player)
    local response = controller:startShift(player.UserId, isAtCafe(player))
    response.displayName = cafe.displayName
    response.atCafe = isAtCafe(player)
    return response
end

completeTask.OnServerInvoke = function(player, shiftId, taskId)
    if type(shiftId) ~= "string" or type(taskId) ~= "string" then
        return { accepted = false, code = "invalid_completion" }
    end

    local response = controller:completeTask(
        player.UserId,
        shiftId,
        taskId,
        isAtCafe(player)
    )
    response.displayName = cafe.displayName
    response.atCafe = isAtCafe(player)
    return response
end

leaveShift.OnServerInvoke = function(player)
    local response = controller:leaveShift(player.UserId)
    response.displayName = cafe.displayName
    response.atCafe = isAtCafe(player)
    return response
end

Players.PlayerRemoving:Connect(function(player)
    controller:clearPlayer(player.UserId)
end)
