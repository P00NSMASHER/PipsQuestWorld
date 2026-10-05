--!strict
-- Server-owned physical P.E. dodgeball drill for Pip High.
-- Clients can leave the drill, but never author launches, hits, timers, or grades.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))
local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local PEDodgeballController = require(
    schoolFoundation:WaitForChild("PEDodgeballController")
)

local ROUND_DURATION = 15
local FIRST_BALL_DELAY = 0.75
local BALL_INTERVAL = 1.35
local START_COOLDOWN = 0.75
local STATE_PUSH_INTERVAL = 0.2
local BALL_HORIZONTAL_SPEED = 36
local BALL_HIT_RADIUS = 3.35
local BALL_LIFETIME_PADDING = 1.1
local GRAVITY_COMPENSATION = 0.9
local GYM_HALF_X = 43
local GYM_HALF_Z = 25
local GYM_VERTICAL_RANGE = 20

local gym = assert(SchoolConfig.Rooms.Gym, "Foundation Gym room is required")
local random = Random.new()
local controller = PEDodgeballController.new({
    duration = ROUND_DURATION,
    firstBallDelay = FIRST_BALL_DELAY,
    ballInterval = BALL_INTERVAL,
    startCooldown = START_COOLDOWN,
    sessionIdFactory = function(playerId)
        return "pe:" .. tostring(playerId) .. ":" .. HttpService:GenerateGUID(false)
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
local drillRoot = getOrCreateFolder(freeRoamRoot, "PEDodgeballDrill")
local getStateRemote = getOrCreateRemoteFunction(drillRoot, "GetState")
local leaveRemote = getOrCreateRemoteFunction(drillRoot, "Leave")
local sessionStartedRemote = getOrCreateRemoteEvent(drillRoot, "SessionStarted")
local stateUpdatedRemote = getOrCreateRemoteEvent(drillRoot, "StateUpdated")
local sessionEndedRemote = getOrCreateRemoteEvent(drillRoot, "SessionEnded")

local ballFolder = getOrCreateFolder(Workspace, "PipHighDodgeballs")
local runtimeByPlayerId = {}

local function characterStatus(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local alive = root ~= nil
        and root:IsA("BasePart")
        and humanoid ~= nil
        and humanoid.Health > 0
    return root, humanoid, alive
end

local function isAtGym(player)
    local root = characterStatus(player)
    if not root then
        return false
    end
    local offset = root.Position - gym.position
    return math.abs(offset.X) <= GYM_HALF_X
        and math.abs(offset.Z) <= GYM_HALF_Z
        and math.abs(offset.Y) <= GYM_VERTICAL_RANGE
end

local function decorateState(state)
    state.available = true
    state.displayName = "P.E. Dodgeball Drill"
    return state
end

local function makeStationPart(model, name, size, cframe, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = model
    return part
end

local function buildDrillStation()
    local existing = Workspace:FindFirstChild("PipHighPEDodgeballStation")
    if existing then
        assert(existing:IsA("Model"), "PipHighPEDodgeballStation must be a Model")
        local existingPrompt = existing:FindFirstChild("PEDodgeballPrompt", true)
        assert(
            existingPrompt and existingPrompt:IsA("ProximityPrompt"),
            "P.E. dodgeball prompt is required"
        )
        return existingPrompt
    end

    local model = Instance.new("Model")
    model.Name = "PipHighPEDodgeballStation"
    model:SetAttribute("OriginalContent", true)
    local stationPosition = Vector3.new(
        gym.position.X - 13,
        1.25,
        gym.position.Z + 14
    )
    local stationCFrame = CFrame.new(stationPosition)

    local base = makeStationPart(
        model,
        "DrillStand",
        Vector3.new(7.5, 1.3, 4.5),
        stationCFrame,
        Color3.fromRGB(55, 91, 139),
        Enum.Material.Metal
    )
    base.CanCollide = true

    makeStationPart(
        model,
        "BallRack",
        Vector3.new(7.8, 0.35, 4.8),
        stationCFrame * CFrame.new(0, 0.82, 0),
        Color3.fromRGB(225, 230, 236),
        Enum.Material.SmoothPlastic
    )

    local rackColors = {
        Color3.fromRGB(244, 110, 91),
        Color3.fromRGB(242, 184, 72),
        Color3.fromRGB(93, 174, 205),
    }
    for index, xOffset in ipairs({ -2.4, 0, 2.4 }) do
        local displayBall = makeStationPart(
            model,
            "DisplayFoamBall" .. tostring(index),
            Vector3.new(1.9, 1.9, 1.9),
            stationCFrame * CFrame.new(xOffset, 1.8, 0),
            rackColors[index],
            Enum.Material.SmoothPlastic
        )
        displayBall.Shape = Enum.PartType.Ball
        displayBall.CanCollide = false
    end

    local promptAnchor = makeStationPart(
        model,
        "PromptAnchor",
        Vector3.new(2, 1, 2),
        stationCFrame * CFrame.new(0, 3.7, 0),
        Color3.fromRGB(255, 255, 255),
        Enum.Material.SmoothPlastic
    )
    promptAnchor.Transparency = 1
    promptAnchor.CanCollide = false

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "PEDodgeballPrompt"
    prompt.ActionText = "Start 15s Drill"
    prompt.ObjectText = "P.E. Dodgeball"
    prompt.HoldDuration = 0.25
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 14
    prompt.RequiresLineOfSight = false
    prompt.Parent = promptAnchor

    local sign = Instance.new("BillboardGui")
    sign.Name = "DrillSign"
    sign.Adornee = promptAnchor
    -- Keep this sign anchored in the gym's physical space rather than drawing it through campus geometry.
    sign.AlwaysOnTop = false
    sign.Size = UDim2.fromOffset(250, 58)
    sign.StudsOffset = Vector3.new(0, 1.8, 0)
    sign.Parent = promptAnchor

    local signText = Instance.new("TextLabel")
    signText.BackgroundColor3 = Color3.fromRGB(43, 72, 113)
    signText.BackgroundTransparency = 0.06
    signText.BorderSizePixel = 0
    signText.Size = UDim2.fromScale(1, 1)
    signText.Font = Enum.Font.GothamBold
    signText.Text = "P.E. DODGEBALL DRILL"
    signText.TextColor3 = Color3.fromRGB(255, 255, 255)
    signText.TextScaled = true
    signText.Parent = sign

    local signCorner = Instance.new("UICorner")
    signCorner.CornerRadius = UDim.new(0, 10)
    signCorner.Parent = signText

    model.PrimaryPart = base
    model.Parent = Workspace
    return prompt
end

local function vectorTable(vector)
    return { x = vector.X, y = vector.Y, z = vector.Z }
end

local function vectorFromTable(vector)
    return Vector3.new(vector.x, vector.y, vector.z)
end

local function chooseLaunchOrigin()
    local side = random:NextInteger(1, 4)
    local x
    local z
    if side == 1 then
        x = gym.position.X - 37
        z = gym.position.Z + random:NextNumber(-18, 18)
    elseif side == 2 then
        x = gym.position.X + 37
        z = gym.position.Z + random:NextNumber(-18, 18)
    elseif side == 3 then
        x = gym.position.X + random:NextNumber(-34, 34)
        z = gym.position.Z - 20
    else
        x = gym.position.X + random:NextNumber(-34, 34)
        z = gym.position.Z + 20
    end
    return Vector3.new(x, gym.position.Y + 0.5, z)
end

local function cleanupRuntime(playerId)
    local runtime = runtimeByPlayerId[playerId]
    if not runtime then
        return
    end
    if runtime.folder and runtime.folder.Parent then
        runtime.folder:Destroy()
    end
    runtimeByPlayerId[playerId] = nil
end

local function createRuntime(player, sessionId, now)
    cleanupRuntime(player.UserId)
    local folder = Instance.new("Folder")
    folder.Name = "Player_" .. tostring(player.UserId)
    folder:SetAttribute("OwnerUserId", player.UserId)
    folder.Parent = ballFolder
    local runtime = {
        sessionId = sessionId,
        folder = folder,
        balls = {},
        lastStatePushAt = now,
    }
    runtimeByPlayerId[player.UserId] = runtime
    return runtime
end

local function spawnFoamBall(player, runtime, ballId, now, targetRoot)
    local origin = chooseLaunchOrigin()
    local target = targetRoot.Position + Vector3.new(
        random:NextNumber(-2.2, 2.2),
        random:NextNumber(-0.4, 0.8),
        random:NextNumber(-2.2, 2.2)
    )
    local horizontalDistance = Vector3.new(
        target.X - origin.X,
        0,
        target.Z - origin.Z
    ).Magnitude
    local flightTime = math.clamp(
        horizontalDistance / BALL_HORIZONTAL_SPEED,
        0.85,
        1.75
    )
    local effectiveGravity = Workspace.Gravity * (1 - GRAVITY_COMPENSATION)
    local velocity = PEDodgeballController.computeBallisticVelocity(
        vectorTable(origin),
        vectorTable(target),
        flightTime,
        effectiveGravity
    )

    local ball = Instance.new("Part")
    ball.Name = "FoamBall"
    ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(2.6, 2.6, 2.6)
    ball.CFrame = CFrame.new(origin)
    ball.Color = ({
        Color3.fromRGB(244, 110, 91),
        Color3.fromRGB(242, 184, 72),
        Color3.fromRGB(93, 174, 205),
        Color3.fromRGB(157, 116, 205),
    })[(runtime.ballsThrownVisual or 0) % 4 + 1]
    runtime.ballsThrownVisual = (runtime.ballsThrownVisual or 0) + 1
    ball.Material = Enum.Material.SmoothPlastic
    ball.CustomPhysicalProperties = PhysicalProperties.new(0.35, 0.2, 0.72, 1, 1)
    ball.Anchored = false
    ball.CanCollide = false
    ball.CanQuery = false
    ball.CanTouch = false
    ball.CastShadow = true
    ball:SetAttribute("OwnerUserId", player.UserId)
    ball:SetAttribute("BallId", ballId)
    ball.Parent = runtime.folder

    local forceAttachment = Instance.new("Attachment")
    forceAttachment.Name = "GravityAssistAttachment"
    forceAttachment.Parent = ball
    local gravityAssist = Instance.new("VectorForce")
    gravityAssist.Name = "FoamGravityAssist"
    gravityAssist.Attachment0 = forceAttachment
    gravityAssist.ApplyAtCenterOfMass = true
    gravityAssist.RelativeTo = Enum.ActuatorRelativeTo.World
    gravityAssist.Force = Vector3.new(
        0,
        ball.AssemblyMass * Workspace.Gravity * GRAVITY_COMPENSATION,
        0
    )
    gravityAssist.Parent = ball

    local trailStart = Instance.new("Attachment")
    trailStart.Name = "TrailStart"
    trailStart.Position = Vector3.new(-0.8, 0, 0)
    trailStart.Parent = ball
    local trailEnd = Instance.new("Attachment")
    trailEnd.Name = "TrailEnd"
    trailEnd.Position = Vector3.new(0.8, 0, 0)
    trailEnd.Parent = ball
    local trail = Instance.new("Trail")
    trail.Name = "MotionTrail"
    trail.Attachment0 = trailStart
    trail.Attachment1 = trailEnd
    trail.Color = ColorSequence.new(ball.Color, Color3.fromRGB(255, 255, 255))
    trail.Lifetime = 0.16
    trail.Transparency = NumberSequence.new(0.25, 1)
    trail.Parent = ball

    local ownershipOk = pcall(function()
        local canSet, reason = ball:CanSetNetworkOwnership()
        assert(canSet, reason or "foam ball network ownership unavailable")
        ball:SetNetworkOwner(nil)
    end)
    if not ownershipOk then
        ball:Destroy()
        return
    end

    ball.AssemblyLinearVelocity = vectorFromTable(velocity)
    runtime.balls[ballId] = {
        part = ball,
        previousPosition = origin,
        expiresAt = now + flightTime + BALL_LIFETIME_PADDING,
    }
end

local function finishRuntime(player, outcome, notifyClient)
    cleanupRuntime(player.UserId)
    if notifyClient and type(outcome.result) == "table" then
        sessionEndedRemote:FireClient(player, {
            state = decorateState(outcome.state),
            result = outcome.result,
        })
    end
end

local prompt = buildDrillStation()
prompt.Triggered:Connect(function(player)
    local now = os.clock()
    local _root, _humanoid, alive = characterStatus(player)
    local response = controller:startSession(
        player.UserId,
        isAtGym(player),
        alive,
        now
    )
    if response.code == "session_started" then
        createRuntime(player, response.sessionId, now)
    end

    -- Only public state and presentation-safe status cross the remote boundary.
    sessionStartedRemote:FireClient(player, {
        accepted = response.accepted,
        code = response.code,
        retryAfter = response.retryAfter,
        state = response.state and decorateState(response.state) or nil,
    })
end)

getStateRemote.OnServerInvoke = function(player)
    return decorateState(controller:getState(player.UserId, os.clock()))
end

leaveRemote.OnServerInvoke = function(player)
    local outcome = controller:endSession(player.UserId, "left_by_player", os.clock())
    if outcome.result then
        finishRuntime(player, outcome, false)
    end
    if outcome.state then
        decorateState(outcome.state)
    end
    return outcome
end

Players.PlayerRemoving:Connect(function(player)
    cleanupRuntime(player.UserId)
    controller:clearPlayer(player.UserId)
end)

local function stepRuntime(playerId, runtime, now)
    local player = Players:GetPlayerByUserId(playerId)
    if not player then
        cleanupRuntime(playerId)
        controller:clearPlayer(playerId)
        return
    end

    local root, _humanoid, alive = characterStatus(player)
    local outcome = controller:advance(
        playerId,
        now,
        isAtGym(player),
        alive
    )
    if outcome.result then
        finishRuntime(player, outcome, true)
        return
    end

    for _, ballId in ipairs(outcome.spawnBallIds or {}) do
        if root then
            spawnFoamBall(player, runtime, ballId, now, root)
        end
    end

    for ballId, ballRuntime in pairs(runtime.balls) do
        local ball = ballRuntime.part
        if not ball or not ball.Parent or now >= ballRuntime.expiresAt then
            if ball and ball.Parent then
                ball:Destroy()
            end
            runtime.balls[ballId] = nil
        else
            local currentPosition = ball.Position
            if root and PEDodgeballController.segmentHitsSphere(
                vectorTable(ballRuntime.previousPosition),
                vectorTable(currentPosition),
                vectorTable(root.Position),
                BALL_HIT_RADIUS
            ) then
                local hit = controller:recordHit(
                    playerId,
                    runtime.sessionId,
                    ballId,
                    now
                )
                ball:Destroy()
                runtime.balls[ballId] = nil
                if hit.accepted and hit.state then
                    stateUpdatedRemote:FireClient(player, decorateState(hit.state))
                end
            else
                ballRuntime.previousPosition = currentPosition
            end
        end
    end

    if runtimeByPlayerId[playerId]
        and now - runtime.lastStatePushAt >= STATE_PUSH_INTERVAL then
        runtime.lastStatePushAt = now
        stateUpdatedRemote:FireClient(
            player,
            decorateState(controller:getState(playerId, now))
        )
    end
end

RunService.Heartbeat:Connect(function()
    local now = os.clock()
    for playerId, runtime in pairs(runtimeByPlayerId) do
        stepRuntime(playerId, runtime, now)
    end
end)
