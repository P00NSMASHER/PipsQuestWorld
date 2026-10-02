--!strict
-- Canonical Pip High vehicle adapter.
-- Free Roam owns vehicle lifecycle/controls. Foundation owns world/location state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))
local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local VehicleLifecycle = require(schoolFoundation:WaitForChild("VehicleLifecycle"))
local VehicleInput = require(schoolFoundation:WaitForChild("VehicleInput"))

local SPAWN_RADIUS = 72
local VEHICLE_SPEED = 42
local TURN_RATE = math.rad(95)
local CONTROL_TIMEOUT = 0.35
local VEHICLE_ID = "starter-sedan"

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

local function getOrCreateRemoteEvent(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing then
        assert(existing:IsA("RemoteEvent"), name .. " must be a RemoteEvent")
        return existing
    end
    local remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = parent
    return remote
end

local remoteRoot = ReplicatedStorage:WaitForChild(SchoolConfig.Interfaces.remoteFolder)
local freeRoamRoot = getOrCreateFolder(remoteRoot, "FreeRoam")
local vehicleRoot = getOrCreateFolder(freeRoamRoot, "Vehicles")
local getStateRemote = getOrCreateRemoteFunction(vehicleRoot, "GetState")
local spawnRemote = getOrCreateRemoteFunction(vehicleRoot, "Spawn")
local despawnRemote = getOrCreateRemoteFunction(vehicleRoot, "Despawn")
local controlsRemote = getOrCreateRemoteEvent(vehicleRoot, "SetControls")

local vehicleFolder = getOrCreateFolder(Workspace, "PipHighVehicles")
local lifecycle = VehicleLifecycle.new()
local runtimeByPlayerId = {}

local autoShop = assert(SchoolConfig.WorldLocations.AutoShop, "AutoShop location is required")
local vehicleSpawn = assert(
    SchoolConfig.WorldSpawnSeams and SchoolConfig.WorldSpawnSeams.AutoShopRoad,
    "Foundation AutoShopRoad vehicle spawn seam is required"
)
local spawnPosition = vehicleSpawn.position + Vector3.new(0, 2.2, 0)
local spawnYaw = math.rad(vehicleSpawn.headingDegrees or 0)

local function playerKey(player)
    return tostring(player.UserId)
end

local function characterRoot(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function isAtAutoShop(player)
    local root = characterRoot(player)
    return root ~= nil and (root.Position - autoShop.position).Magnitude <= SPAWN_RADIUS
end

local function addPart(model, name, size, cframe, color, className)
    local part = Instance.new(className or "Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = model
    return part
end

local function buildVehicle(player, token)
    local model = Instance.new("Model")
    model.Name = "StarterSedan_" .. tostring(player.UserId)
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("VehicleId", VEHICLE_ID)
    model:SetAttribute("VehicleToken", token)

    local baseCFrame = CFrame.new(spawnPosition) * CFrame.Angles(0, spawnYaw, 0)
    local body = addPart(
        model,
        "Body",
        Vector3.new(7.5, 1.6, 11),
        baseCFrame,
        Color3.fromRGB(67, 111, 168)
    )
    body.CanCollide = true

    local hood = addPart(
        model,
        "Hood",
        Vector3.new(7, 1.1, 3.4),
        baseCFrame * CFrame.new(0, 1.1, -3.1),
        Color3.fromRGB(79, 128, 190)
    )
    hood.CanCollide = false

    local cabin = addPart(
        model,
        "Cabin",
        Vector3.new(6.2, 2.3, 4.6),
        baseCFrame * CFrame.new(0, 1.65, 0.65),
        Color3.fromRGB(148, 190, 214)
    )
    cabin.Material = Enum.Material.Glass
    cabin.Transparency = 0.28
    cabin.CanCollide = false

    local seat = addPart(
        model,
        "DriverSeat",
        Vector3.new(2.6, 1, 2.8),
        baseCFrame * CFrame.new(0, 1.4, 1),
        Color3.fromRGB(45, 49, 58),
        "VehicleSeat"
    )
    seat.CanCollide = true
    seat.MaxSpeed = VEHICLE_SPEED
    seat.Torque = 0
    seat.TurnSpeed = 0

    for _, wheelSpec in ipairs({
        { -3.6, -1.0, -3.2 },
        { 3.6, -1.0, -3.2 },
        { -3.6, -1.0, 3.2 },
        { 3.6, -1.0, 3.2 },
    }) do
        local wheel = addPart(
            model,
            "Wheel",
            Vector3.new(1.2, 2.5, 2.5),
            baseCFrame
                * CFrame.new(wheelSpec[1], wheelSpec[2], wheelSpec[3])
                * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(32, 34, 40)
        )
        wheel.Shape = Enum.PartType.Cylinder
        wheel.CanCollide = false
    end

    model.PrimaryPart = body
    model.Parent = vehicleFolder

    return model, seat
end

local function ejectSeat(seat)
    local humanoid = seat and seat.Occupant
    if humanoid then
        humanoid.Sit = false
    end
end

local function destroyRuntime(playerId)
    local runtime = runtimeByPlayerId[playerId]
    if not runtime then
        return
    end

    ejectSeat(runtime.seat)
    if runtime.model and runtime.model.Parent then
        runtime.model:Destroy()
    end
    runtimeByPlayerId[playerId] = nil
end

local function isOwnerSeated(player, runtime)
    if not runtime or not runtime.seat then
        return false
    end
    local occupant = runtime.seat.Occupant
    return occupant ~= nil
        and Players:GetPlayerFromCharacter(occupant.Parent) == player
end

local function clearControls(runtime)
    if not runtime then
        return
    end
    runtime.throttle = 0
    runtime.steer = 0
    runtime.lastControlAt = 0
end

local function publicState(player)
    local state = lifecycle:get(playerKey(player))
    local runtime = runtimeByPlayerId[player.UserId]
    return {
        active = state ~= nil,
        vehicleId = state and state.vehicleId or nil,
        token = state and state.token or nil,
        atAutoShop = isAtAutoShop(player),
        autoShopDisplayName = autoShop.displayName,
        driving = isOwnerSeated(player, runtime),
    }
end

spawnRemote.OnServerInvoke = function(player)
    if not isAtAutoShop(player) then
        return {
            accepted = false,
            code = "not_at_auto_shop",
            state = publicState(player),
        }
    end

    local reservation = lifecycle:spawn(playerKey(player), VEHICLE_ID)
    if not reservation.accepted then
        return {
            accepted = false,
            code = reservation.code,
            state = publicState(player),
        }
    end

    local ok, modelOrError, seat = pcall(function()
        local model, driverSeat = buildVehicle(player, reservation.state.token)
        return model, driverSeat
    end)
    if not ok then
        lifecycle:despawn(playerKey(player), reservation.state.token)
        return {
            accepted = false,
            code = "vehicle_spawn_failed",
            error = tostring(modelOrError),
            state = publicState(player),
        }
    end

    local model = modelOrError
    runtimeByPlayerId[player.UserId] = {
        model = model,
        seat = seat,
        token = reservation.state.token,
        position = spawnPosition,
        yaw = spawnYaw,
        throttle = 0,
        steer = 0,
        lastControlAt = 0,
    }

    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local runtime = runtimeByPlayerId[player.UserId]
        local occupant = seat.Occupant
        if not occupant then
            clearControls(runtime)
            return
        end
        local occupantPlayer = Players:GetPlayerFromCharacter(occupant.Parent)
        if occupantPlayer ~= player then
            clearControls(runtime)
            occupant.Sit = false
        end
    end)

    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        seat:Sit(humanoid)
    end

    return {
        accepted = true,
        code = "vehicle_spawned",
        state = publicState(player),
    }
end

despawnRemote.OnServerInvoke = function(player)
    local current = lifecycle:get(playerKey(player))
    local result = lifecycle:despawn(
        playerKey(player),
        current and current.token or nil
    )
    if result.accepted then
        destroyRuntime(player.UserId)
    end
    return {
        accepted = result.accepted,
        code = result.code,
        state = publicState(player),
    }
end

getStateRemote.OnServerInvoke = function(player)
    return publicState(player)
end

controlsRemote.OnServerEvent:Connect(function(player, throttle, steer)
    local runtime = runtimeByPlayerId[player.UserId]
    if not runtime or not isOwnerSeated(player, runtime) then
        clearControls(runtime)
        return
    end

    local active = lifecycle:get(playerKey(player))
    if not active or active.token ~= runtime.token then
        clearControls(runtime)
        return
    end

    local controls = VehicleInput.normalize(throttle, steer)
    if not controls then
        clearControls(runtime)
        return
    end

    runtime.throttle = controls.throttle
    runtime.steer = controls.steer
    runtime.lastControlAt = os.clock()
end)

Players.PlayerRemoving:Connect(function(player)
    local current = lifecycle:get(playerKey(player))
    lifecycle:despawn(playerKey(player), current and current.token or nil)
    destroyRuntime(player.UserId)
end)

RunService.Heartbeat:Connect(function(dt)
    local boundedDt = math.min(dt, 0.1)

    for playerId, runtime in pairs(runtimeByPlayerId) do
        if not runtime.model or not runtime.model.Parent then
            runtimeByPlayerId[playerId] = nil
            continue
        end

        local seat = runtime.seat
        local occupant = seat and seat.Occupant
        local owner = Players:GetPlayerByUserId(playerId)
        if not owner or not occupant then
            continue
        end

        local occupantPlayer = Players:GetPlayerFromCharacter(occupant.Parent)
        if occupantPlayer ~= owner then
            occupant.Sit = false
            continue
        end

        local throttle = runtime.throttle or 0
        local steer = runtime.steer or 0
        if runtime.lastControlAt == 0
            or os.clock() - runtime.lastControlAt > CONTROL_TIMEOUT then
            throttle = 0
            steer = 0
            runtime.throttle = 0
            runtime.steer = 0
        end

        if math.abs(steer) > 0.01 then
            local turnScale = math.abs(throttle) > 0.01 and 1 or 0.45
            runtime.yaw -= steer * TURN_RATE * boundedDt * turnScale
        end

        if math.abs(throttle) > 0.01 then
            local heading = CFrame.Angles(0, runtime.yaw, 0).LookVector
            runtime.position += heading * throttle * VEHICLE_SPEED * boundedDt
        end

        runtime.model:PivotTo(
            CFrame.new(runtime.position)
                * CFrame.Angles(0, runtime.yaw, 0)
        )
    end
end)
