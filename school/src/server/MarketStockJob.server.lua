--!strict
-- Runtime adapter for the original Pip High Market stock-sorting shift.
-- The server owns proximity, task order, answer checks, request idempotence, and pay.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))
local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local EconomyRuntime = require(schoolFoundation:WaitForChild("EconomyRuntime"))
local MarketStockJobController = require(
    schoolFoundation:WaitForChild("MarketStockJobController")
)

local MARKET_RADIUS = 38
local MARKET_WAGE = 45
local market = assert(
    SchoolConfig.WorldLocations.Market,
    "Foundation Market location is required"
)
local random = Random.new()

local controller = MarketStockJobController.new({
    wage = MARKET_WAGE,
    randomInteger = function(minimum, maximum)
        return random:NextInteger(minimum, maximum)
    end,
    shiftIdFactory = function(playerId)
        return "market:" .. tostring(playerId) .. ":" .. HttpService:GenerateGUID(false)
    end,
    taskTokenFactory = function(_playerId, shiftId, step)
        return shiftId
            .. ":"
            .. tostring(step)
            .. ":"
            .. HttpService:GenerateGUID(false)
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

local function isAtMarket(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return false
    end
    return (root.Position - market.position).Magnitude <= MARKET_RADIUS
end

local remoteRoot = ReplicatedStorage:WaitForChild(SchoolConfig.Interfaces.remoteFolder)
local freeRoamRoot = getOrCreateFolder(remoteRoot, "FreeRoam")
local marketRoot = getOrCreateFolder(freeRoamRoot, "MarketStockJob")
local getStateRemote = getOrCreateRemoteFunction(marketRoot, "GetState")
local startShiftRemote = getOrCreateRemoteFunction(marketRoot, "StartShift")
local submitSortRemote = getOrCreateRemoteFunction(marketRoot, "SubmitSort")
local leaveShiftRemote = getOrCreateRemoteFunction(marketRoot, "LeaveShift")
local openPanelRemote = getOrCreateRemoteEvent(marketRoot, "OpenPanel")

local function decorateState(player, state)
    state.available = true
    state.atMarket = isAtMarket(player)
    state.displayName = market.displayName
    return state
end

local function decorateResponse(player, response)
    response.atMarket = isAtMarket(player)
    response.displayName = market.displayName
    if type(response.state) == "table" then
        decorateState(player, response.state)
    end
    return response
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

local function buildStockStation()
    local existing = Workspace:FindFirstChild("PipHighMarketStockStation")
    if existing then
        assert(existing:IsA("Model"), "PipHighMarketStockStation must be a Model")
        local existingPrompt = existing:FindFirstChild("MarketStockPrompt", true)
        assert(
            existingPrompt and existingPrompt:IsA("ProximityPrompt"),
            "Market stock station prompt is required"
        )
        return existingPrompt
    end

    local model = Instance.new("Model")
    model.Name = "PipHighMarketStockStation"
    model:SetAttribute("OriginalContent", true)

    local stationCFrame = CFrame.new(market.position + Vector3.new(0, -0.55, 8))
    local counter = makeStationPart(
        model,
        "StockCounter",
        Vector3.new(12, 3.1, 3.6),
        stationCFrame * CFrame.new(0, 0, 0),
        Color3.fromRGB(76, 111, 78),
        Enum.Material.WoodPlanks
    )
    counter.CanCollide = true

    makeStationPart(
        model,
        "CounterTop",
        Vector3.new(12.8, 0.35, 4.2),
        stationCFrame * CFrame.new(0, 1.72, 0),
        Color3.fromRGB(232, 218, 179),
        Enum.Material.Wood
    )

    for index, crateSpec in ipairs({
        { x = -4.3, color = Color3.fromRGB(227, 114, 82) },
        { x = 0, color = Color3.fromRGB(238, 190, 75) },
        { x = 4.3, color = Color3.fromRGB(91, 151, 188) },
    }) do
        makeStationPart(
            model,
            "SortingBin" .. tostring(index),
            Vector3.new(3.2, 1.4, 2.4),
            stationCFrame * CFrame.new(crateSpec.x, 2.55, 0),
            crateSpec.color,
            Enum.Material.SmoothPlastic
        )
    end

    local promptAnchor = makeStationPart(
        model,
        "PromptAnchor",
        Vector3.new(2, 1, 2),
        stationCFrame * CFrame.new(0, 4.8, -1.5),
        Color3.fromRGB(255, 255, 255),
        Enum.Material.SmoothPlastic
    )
    promptAnchor.Transparency = 1
    promptAnchor.CanCollide = false

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "MarketStockPrompt"
    prompt.ActionText = "Open Stock Shift"
    prompt.ObjectText = market.displayName
    prompt.HoldDuration = 0.2
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 14
    prompt.RequiresLineOfSight = false
    prompt.Parent = promptAnchor

    local sign = Instance.new("BillboardGui")
    sign.Name = "StockStationSign"
    sign.Adornee = promptAnchor
    sign.AlwaysOnTop = true
    sign.Size = UDim2.fromOffset(220, 52)
    sign.StudsOffset = Vector3.new(0, 1.7, 0)
    sign.Parent = promptAnchor

    local signText = Instance.new("TextLabel")
    signText.BackgroundColor3 = Color3.fromRGB(44, 74, 52)
    signText.BackgroundTransparency = 0.08
    signText.BorderSizePixel = 0
    signText.Size = UDim2.fromScale(1, 1)
    signText.Font = Enum.Font.GothamBold
    signText.Text = "STOCK SORTING"
    signText.TextColor3 = Color3.fromRGB(255, 247, 218)
    signText.TextScaled = true
    signText.Parent = sign

    local signCorner = Instance.new("UICorner")
    signCorner.CornerRadius = UDim.new(0, 10)
    signCorner.Parent = signText

    model.PrimaryPart = counter
    model.Parent = Workspace
    return prompt
end

local prompt = buildStockStation()
prompt.Triggered:Connect(function(player)
    if isAtMarket(player) then
        openPanelRemote:FireClient(player)
    end
end)

getStateRemote.OnServerInvoke = function(player)
    return decorateState(player, controller:getState(player.UserId))
end

startShiftRemote.OnServerInvoke = function(player)
    return decorateResponse(
        player,
        controller:startShift(player.UserId, isAtMarket(player))
    )
end

submitSortRemote.OnServerInvoke = function(
    player,
    shiftId,
    taskToken,
    choiceId,
    requestId
)
    return decorateResponse(
        player,
        controller:submitSort(
            player.UserId,
            shiftId,
            taskToken,
            choiceId,
            requestId,
            isAtMarket(player)
        )
    )
end

leaveShiftRemote.OnServerInvoke = function(player)
    return decorateResponse(player, controller:leaveShift(player.UserId))
end

Players.PlayerRemoving:Connect(function(player)
    controller:clearPlayer(player.UserId)
    EconomyRuntime.release(player.UserId)
end)
