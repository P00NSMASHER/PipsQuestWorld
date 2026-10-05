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
local VehicleDynamics = require(schoolFoundation:WaitForChild("VehicleDynamics"))

local SPAWN_RADIUS = 72
local CONTROL_TIMEOUT = 0.35
local VEHICLE_ID = "starter-sedan"
local VEHICLE_HANDLING = VehicleDynamics.DEFAULTS

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

local function weldAssembly(body, model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if descendant ~= body then
                local weld = Instance.new("WeldConstraint")
                weld.Name = "BodyWeld"
                weld.Part0 = body
                weld.Part1 = descendant
                weld.Parent = descendant
                descendant.Massless = true
            else
                descendant.Massless = false
            end
            descendant.Anchored = false
        end
    end
end

local function setServerOwnership(body)
    if not body or not body.Parent or body.Anchored then
        return false, "vehicle body is not an active unanchored part"
    end

    -- A seated character can otherwise cause Roblox to hand the assembly to the
    -- driver's client. Keeping ownership on the server makes remote input intent,
    -- validation, timeouts, and the physics actuators the sole movement authority.
    local ok, ownershipError = pcall(function()
        local canSet, reason = body:CanSetNetworkOwnership()
        assert(canSet, reason or "vehicle network ownership is unavailable")
        body:SetNetworkOwner(nil)
    end)
    return ok, ownershipError
end

local function addActuators(body, headingYaw)
    local attachment = Instance.new("Attachment")
    attachment.Name = "DriveAttachment"
    attachment.Parent = body

    local driveForce = Instance.new("VectorForce")
    driveForce.Name = "ServerDriveForce"
    driveForce.Attachment0 = attachment
    driveForce.ApplyAtCenterOfMass = true
    driveForce.RelativeTo = Enum.ActuatorRelativeTo.World
    driveForce.Force = Vector3.zero
    driveForce.Parent = body

    local upright = Instance.new("AlignOrientation")
    upright.Name = "ServerSteering"
    upright.Attachment0 = attachment
    upright.Mode = Enum.OrientationAlignmentMode.OneAttachment
    upright.CFrame = CFrame.Angles(0, headingYaw, 0)
    upright.MaxAngularVelocity = math.rad(160)
    upright.MaxTorque = 200000
    upright.Responsiveness = 18
    upright.RigidityEnabled = false
    upright.Parent = body

    return driveForce, upright
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
    body.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.35, 0.15, 1, 1)

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
    seat.MaxSpeed = VEHICLE_HANDLING.maxForwardSpeed
    seat.Torque = 0
    seat.TurnSpeed = 0
    seat.HeadsUpDisplay = false

    for wheelIndex, wheelSpec in ipairs({
        { -3.6, -1.0, -3.2 },
        { 3.6, -1.0, -3.2 },
        { -3.6, -1.0, 3.2 },
        { 3.6, -1.0, 3.2 },
    }) do
        local wheel = addPart(
            model,
            "Wheel" .. tostring(wheelIndex),
            Vector3.new(1.2, 2.5, 2.5),
            baseCFrame * CFrame.new(wheelSpec[1], wheelSpec[2], wheelSpec[3]),
            Color3.fromRGB(32, 34, 40)
        )
        wheel.Shape = Enum.PartType.Cylinder
        wheel.CanCollide = true
        -- The force-based arcade chassis supplies its own lateral grip. Low tire
        -- friction lets the welded primitive wheels travel with the body
        -- without static friction overpowering the bounded drive acceleration.
        wheel.CustomPhysicalProperties = PhysicalProperties.new(0.8, 0.08, 0.1, 1, 1)
    end

    for lightIndex, lightSpec in ipairs({
        { x = -2.35, y = 0.45, z = -5.55, color = Color3.fromRGB(255, 239, 178), name = "Headlight" },
        { x = 2.35, y = 0.45, z = -5.55, color = Color3.fromRGB(255, 239, 178), name = "Headlight" },
        { x = -2.35, y = 0.35, z = 5.55, color = Color3.fromRGB(207, 57, 62), name = "TailLight" },
        { x = 2.35, y = 0.35, z = 5.55, color = Color3.fromRGB(207, 57, 62), name = "TailLight" },
    }) do
        local light = addPart(
            model,
            lightSpec.name .. tostring(lightIndex),
            Vector3.new(1.35, 0.6, 0.24),
            baseCFrame * CFrame.new(lightSpec.x, lightSpec.y, lightSpec.z),
            lightSpec.color
        )
        light.Material = Enum.Material.Neon
        light.CanCollide = false
    end

    for bumperIndex, zOffset in ipairs({ -5.72, 5.72 }) do
        local bumper = addPart(
            model,
            "Bumper" .. tostring(bumperIndex),
            Vector3.new(7.2, 0.42, 0.34),
            baseCFrame * CFrame.new(0, -0.38, zOffset),
            Color3.fromRGB(47, 53, 63)
        )
        bumper.Material = Enum.Material.Metal
        bumper.CanCollide = false
    end

    model.PrimaryPart = body
    model.Parent = vehicleFolder
    local driveForce, upright = addActuators(body, spawnYaw)
    weldAssembly(body, model)
    local ownsServer, ownershipError = setServerOwnership(body)
    if not ownsServer then
        model:Destroy()
        error("vehicle_server_ownership_failed: " .. tostring(ownershipError))
    end

    return model, seat, body, driveForce, upright
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
    if runtime.driveForce then
        runtime.driveForce.Force = Vector3.zero
    end
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

    local ok, modelOrError, seat, body, driveForce, upright = pcall(function()
        return buildVehicle(player, reservation.state.token)
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
        body = body,
        driveForce = driveForce,
        upright = upright,
        token = reservation.state.token,
        headingYaw = spawnYaw,
        throttle = 0,
        steer = 0,
        lastControlAt = 0,
    }

    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local runtime = runtimeByPlayerId[player.UserId]
        local occupant = seat.Occupant
        if not occupant then
            clearControls(runtime)
            setServerOwnership(body)
            return
        end
        local occupantPlayer = Players:GetPlayerFromCharacter(occupant.Parent)
        if occupantPlayer ~= player then
            clearControls(runtime)
            occupant.Sit = false
            return
        end
        setServerOwnership(body)
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
    for playerId, runtime in pairs(runtimeByPlayerId) do
        if not runtime.model or not runtime.model.Parent then
            lifecycle:despawn(tostring(playerId), runtime.token)
            runtimeByPlayerId[playerId] = nil
            continue
        end

        local seat = runtime.seat
        local occupant = seat and seat.Occupant
        local owner = Players:GetPlayerByUserId(playerId)
        local ownerIsDriving = false
        if owner and occupant then
            local occupantPlayer = Players:GetPlayerFromCharacter(occupant.Parent)
            if occupantPlayer == owner then
                ownerIsDriving = true
            else
                occupant.Sit = false
            end
        end

        local throttle = runtime.throttle or 0
        local steer = runtime.steer or 0
        if not ownerIsDriving
            or runtime.lastControlAt == 0
            or os.clock() - runtime.lastControlAt > CONTROL_TIMEOUT then
            throttle = 0
            steer = 0
            runtime.throttle = 0
            runtime.steer = 0
        end

        local body = runtime.body
        if not body or not body.Parent then
            lifecycle:despawn(tostring(playerId), runtime.token)
            destroyRuntime(playerId)
            continue
        end

        local orientation = CFrame.Angles(0, runtime.headingYaw, 0)
        local heading = orientation.LookVector
        local right = orientation.RightVector
        local velocity = body.AssemblyLinearVelocity
        local step = VehicleDynamics.step(VEHICLE_HANDLING, {
            forwardSpeed = velocity:Dot(heading),
            lateralSpeed = velocity:Dot(right),
            headingYaw = runtime.headingYaw,
        }, {
            throttle = throttle,
            steer = steer,
        }, dt)

        runtime.headingYaw = step.headingYaw
        local assemblyMass = body.AssemblyMass
        local planarForce = (
            heading * step.forwardAcceleration
            + right * step.lateralAcceleration
        ) * assemblyMass
        runtime.driveForce.Force = Vector3.new(planarForce.X, 0, planarForce.Z)
        runtime.upright.CFrame = CFrame.Angles(0, runtime.headingYaw, 0)
    end
end)
