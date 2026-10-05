--!strict
-- Read-only lifestyle/inventory summaries plus server-backed vehicle controls.
-- This augments the canonical phone, backpack, and items panels without
-- replacing their existing quick-app buttons or authoring gameplay state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remoteRoot = ReplicatedStorage:WaitForChild("SchoolFoundation")
local freeRoam = remoteRoot:WaitForChild("FreeRoam")
local stateSnapshotRemote = remoteRoot:WaitForChild("StateSnapshot")

local gui = playerGui:WaitForChild("RobloxHighSchoolLegacyUI", 30)
if gui == nil then return end

local function panelBody(name)
    local panel = gui:WaitForChild("FeaturePanel_" .. name, 30)
    if panel == nil then return nil, nil end
    return panel, panel:WaitForChild("Body", 10)
end

local phonePanel, phoneBody = panelBody("phone")
local bagPanel, bagBody = panelBody("bag")
local itemsPanel, itemsBody = panelBody("items")
if phoneBody == nil or bagBody == nil or itemsBody == nil then return end
if phoneBody:GetAttribute("LifestyleStatusMounted") == true
    or bagBody:GetAttribute("LifestyleStatusMounted") == true
    or itemsBody:GetAttribute("LifestyleStatusMounted") == true then
    return
end
phoneBody:SetAttribute("LifestyleStatusMounted", true)
bagBody:SetAttribute("LifestyleStatusMounted", true)
itemsBody:SetAttribute("LifestyleStatusMounted", true)

local schoolStatusCard = gui:WaitForChild("CompactSchoolStatus", 10)
local cashLevelBadge = schoolStatusCard and schoolStatusCard:FindFirstChild("CashLevelLabel")

local BLUE_DARK = Color3.fromRGB(35, 67, 98)
local BLUE = Color3.fromRGB(55, 126, 168)
local PALE = Color3.fromRGB(245, 250, 253)
local MUTED = Color3.fromRGB(102, 125, 143)
local GREEN = Color3.fromRGB(71, 160, 101)
local RED = Color3.fromRGB(204, 80, 80)

local function round(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
end

local function outline(instance)
    local line = Instance.new("UIStroke")
    line.Color = Color3.fromRGB(184, 210, 225)
    line.Thickness = 1
    line.Transparency = 0.08
    line.Parent = instance
end

local function createStatusCard(body, name, offsetY, minimumHeight)
    local existing = body:FindFirstChild(name)
    if existing and existing:IsA("Frame") then return existing end

    local card = Instance.new("Frame")
    card.Name = name
    card.Position = UDim2.fromOffset(8, offsetY)
    card.Size = UDim2.new(1, -16, 1, -offsetY - 4)
    card.BackgroundColor3 = PALE
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.ZIndex = 24
    card.Parent = body
    round(card, 9)
    outline(card)

    local function fit()
        -- Never cover the canonical controls above this card on very short screens.
        card.Visible = body.AbsoluteSize.Y >= offsetY + minimumHeight
    end
    body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    fit()
    return card
end

local function label(parent, name, position, size, textSize, bold)
    local text = Instance.new("TextLabel")
    text.Name = name
    text.Position = position
    text.Size = size
    text.BackgroundTransparency = 1
    text.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    text.Text = ""
    text.TextColor3 = BLUE_DARK
    text.TextSize = textSize
    text.TextWrapped = true
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.ZIndex = 25
    text.Parent = parent
    return text
end

local function button(parent, name, text, position, size, color)
    local control = Instance.new("TextButton")
    control.Name = name
    control.Position = position
    control.Size = size
    control.BackgroundColor3 = color
    control.BorderSizePixel = 0
    control.Font = Enum.Font.GothamBold
    control.Text = text
    control.TextColor3 = Color3.new(1, 1, 1)
    control.TextSize = 10
    control.TextWrapped = true
    control.ZIndex = 26
    control.Parent = parent
    round(control, 7)
    return control
end

-- Phone: compact live schedule and whole-life snapshot below the four app tiles.
local phoneCard = createStatusCard(phoneBody, "LifestylePhoneCard", 184, 72)
local phoneTitle = label(phoneCard, "Title", UDim2.fromOffset(10, 7), UDim2.new(1, -86, 0, 18), 11, true)
local phoneSchedule = label(phoneCard, "Schedule", UDim2.fromOffset(10, 29), UDim2.new(0.49, -12, 1, -34), 11, false)
local phoneLifestyle = label(phoneCard, "Lifestyle", UDim2.new(0.49, 2, 0, 29), UDim2.new(0.51, -12, 1, -34), 11, false)
local phoneRefresh = button(phoneCard, "Refresh", "REFRESH", UDim2.new(1, -74, 0, 6), UDim2.fromOffset(64, 24), BLUE)

-- Backpack: inventory totals below the existing closet and house shortcuts.
local bagCard = createStatusCard(bagBody, "BagInventoryCard", 150, 76)
local bagTitle = label(bagCard, "Title", UDim2.fromOffset(10, 8), UDim2.new(1, -86, 0, 18), 11, true)
local bagSummary = label(bagCard, "Summary", UDim2.fromOffset(10, 31), UDim2.new(1, -20, 1, -36), 12, false)
local bagRefresh = button(bagCard, "Refresh", "REFRESH", UDim2.new(1, -74, 0, 6), UDim2.fromOffset(64, 24), BLUE)

-- Items: active vehicle status/control below the existing Auto Shop travel action.
local itemsCard = createStatusCard(itemsBody, "ItemsVehicleCard", 164, 78)
local itemsTitle = label(itemsCard, "Title", UDim2.fromOffset(10, 8), UDim2.new(1, -86, 0, 18), 11, true)
local vehicleSummary = label(itemsCard, "VehicleSummary", UDim2.fromOffset(10, 33), UDim2.new(0.61, -14, 1, -38), 11, false)
local itemsRefresh = button(itemsCard, "Refresh", "REFRESH", UDim2.new(1, -74, 0, 6), UDim2.fromOffset(64, 24), BLUE)
local vehicleAction = button(itemsCard, "VehicleAction", "CHECKING...", UDim2.new(0.62, 0, 0, 34), UDim2.new(0.38, -10, 0, 38), GREEN)

local snapshot = nil
local styleState = nil
local housingState = nil
local vehicleState = nil
local refreshBusy = false
local vehicleBusy = false
local lastRefreshAt = 0
local refreshMessage = "Connecting to campus services..."
local vehicleMessage = "Checking your vehicle..."

local function ownedStyleCount()
    local count = 0
    if styleState and type(styleState.owned) == "table" then
        for _, owned in pairs(styleState.owned) do
            if owned == true then count = count + 1 end
        end
    end
    return count
end

local function furnitureCount()
    local count = 0
    if housingState and type(housingState.inventory) == "table" then
        for _, entry in ipairs(housingState.inventory) do
            if type(entry) == "table" and type(entry.quantity) == "number" then
                count = count + math.max(0, math.floor(entry.quantity))
            end
        end
    end
    return count
end

local function placementCount()
    return housingState and type(housingState.placements) == "table" and #housingState.placements or 0
end

local function balance()
    if styleState and type(styleState.balance) == "number" then return styleState.balance end
    if housingState and type(housingState.balance) == "number" then return housingState.balance end
    return nil
end

local function remainingSeconds()
    if not snapshot or type(snapshot.secondsRemaining) ~= "number" then return nil end
    local elapsed = math.max(0, math.floor(os.clock() - lastRefreshAt))
    return math.max(0, math.floor(snapshot.secondsRemaining) - elapsed)
end

local function clockText()
    local remaining = remainingSeconds()
    if remaining == nil then return "--:--" end
    return string.format("%d:%02d", math.floor(remaining / 60), remaining % 60)
end

local function render()
    local periodLabel = snapshot and tostring(snapshot.periodLabel or snapshot.periodId or "School Day") or "School Day"
    local day = snapshot and tonumber(snapshot.schoolDay) or 1
    local periodIndex = snapshot and tonumber(snapshot.periodIndex) or 0
    local periodCount = snapshot and tonumber(snapshot.periodCount) or 0
    local money = balance()
    local schoolPoints = tonumber(player:GetAttribute("SchoolPoints")) or 0
    local level = math.max(1, math.floor(schoolPoints / 100) + 1)
    local styles = ownedStyleCount()
    local homeOwned = housingState and housingState.owned == true
    local activeVehicle = vehicleState and vehicleState.active == true
    local driving = vehicleState and vehicleState.driving == true

    if cashLevelBadge and cashLevelBadge:IsA("TextLabel") then
        cashLevelBadge.Text = string.format(
            "%s  •  LV %d",
            money and "$" .. tostring(money) or "$--",
            level
        )
    end

    phoneTitle.Text = "LIVE CAMPUS  •  " .. clockText()
    phoneSchedule.Text = string.format(
        "Day %d\nPeriod %d/%d\n%s",
        day,
        periodIndex,
        periodCount,
        periodLabel
    )
    phoneLifestyle.Text = string.format(
        "%s cash\n%d styles\n%s • %s",
        money and "$" .. tostring(money) or "$--",
        styles,
        homeOwned and "Home owned" or "No home yet",
        activeVehicle and "Car active" or "Car stored"
    )

    bagTitle.Text = refreshBusy and "INVENTORY  •  UPDATING" or "INVENTORY  •  LIVE"
    bagSummary.Text = string.format(
        "%s PLAY-EARNED CASH   •   %d OWNED STYLES\n%s   •   %d FURNITURE   •   %d PLACED\n%s",
        money and "$" .. tostring(money) or "$--",
        styles,
        homeOwned and "HOME OWNED" or "HOME NOT OWNED",
        furnitureCount(),
        placementCount(),
        refreshMessage
    )

    itemsTitle.Text = refreshBusy and "VEHICLE  •  UPDATING" or "VEHICLE  •  SERVER STATUS"
    if activeVehicle then
        vehicleSummary.Text = (driving and "Starter Sedan • driving" or "Starter Sedan • active") .. "\n" .. vehicleMessage
        vehicleAction.Text = vehicleBusy and "WORKING..." or "RETURN CAR"
        vehicleAction.BackgroundColor3 = RED
    else
        local atShop = vehicleState and vehicleState.atAutoShop == true
        vehicleSummary.Text = (atShop and "At Auto Shop • ready" or "Car stored • visit Auto Shop") .. "\n" .. vehicleMessage
        vehicleAction.Text = vehicleBusy and "WORKING..." or "SPAWN CAR"
        vehicleAction.BackgroundColor3 = GREEN
    end
    vehicleAction.Active = not vehicleBusy and not refreshBusy
    vehicleAction.AutoButtonColor = vehicleAction.Active

    local refreshText = refreshBusy and "..." or "REFRESH"
    for _, control in ipairs({ phoneRefresh, bagRefresh, itemsRefresh }) do
        control.Text = refreshText
        control.Active = not refreshBusy and not vehicleBusy
        control.AutoButtonColor = control.Active
    end
end

local function remoteFunction(folderName, remoteName)
    local folder = freeRoam:FindFirstChild(folderName)
    if folder == nil then return nil end
    local remote = folder:FindFirstChild(remoteName)
    if remote and remote:IsA("RemoteFunction") then return remote end
    return nil
end

local function invoke(remote)
    if remote == nil then return false, nil end
    local ok, response = pcall(function()
        return remote:InvokeServer()
    end)
    return ok and type(response) == "table", response
end

local function refreshAll()
    if refreshBusy or vehicleBusy then return end
    refreshBusy = true
    refreshMessage = "Refreshing..."
    render()

    local successes = 0
    local okSchedule, nextSnapshot = invoke(stateSnapshotRemote)
    if okSchedule then
        snapshot = nextSnapshot
        successes = successes + 1
    end

    local okStyle, nextStyle = invoke(remoteFunction("StyleShop", "GetState"))
    if okStyle and nextStyle.accepted == true then
        styleState = nextStyle
        successes = successes + 1
    end

    local okHousing, nextHousing = invoke(remoteFunction("Housing", "GetState"))
    if okHousing and nextHousing.available == true then
        housingState = nextHousing
        successes = successes + 1
    end

    local okVehicle, nextVehicle = invoke(remoteFunction("Vehicles", "GetState"))
    if okVehicle then
        vehicleState = nextVehicle
        vehicleMessage = nextVehicle.active == true and "Ready to drive or return." or "Spawn from the Auto Shop."
        successes = successes + 1
    end

    lastRefreshAt = os.clock()
    refreshBusy = false
    refreshMessage = successes == 4 and "All services updated." or "Some services unavailable • refresh to retry."
    render()
end

local function refreshVehicleOnly()
    local ok, nextVehicle = invoke(remoteFunction("Vehicles", "GetState"))
    if ok then vehicleState = nextVehicle end
    return ok
end

vehicleAction.Activated:Connect(function()
    if vehicleBusy or refreshBusy then return end
    vehicleBusy = true
    vehicleMessage = "Waiting for the server..."
    render()

    local vehicles = freeRoam:FindFirstChild("Vehicles")
    local actionName = vehicleState and vehicleState.active == true and "Despawn" or "Spawn"
    local remote = vehicles and vehicles:FindFirstChild(actionName)
    local ok, response = invoke(remote)

    if ok and response.state then vehicleState = response.state end
    if not ok then
        -- Mutating actions are never guessed or automatically replayed.
        vehicleMessage = "No change confirmed. Refresh before retrying."
        refreshVehicleOnly()
    elseif response.accepted == true and response.code == "vehicle_spawned" then
        vehicleMessage = "Starter Sedan spawned and ready."
    elseif response.accepted == true
        and (response.code == "vehicle_despawned" or response.code == "vehicle_already_despawned") then
        vehicleMessage = "Vehicle safely returned."
    elseif response.code == "not_at_auto_shop" then
        vehicleMessage = "Travel to the Auto Shop, then spawn."
    elseif response.code == "vehicle_already_active" then
        vehicleMessage = "Your active vehicle is already ready."
        refreshVehicleOnly()
    else
        vehicleMessage = "Action unavailable. Refresh before retrying."
        refreshVehicleOnly()
    end

    vehicleBusy = false
    render()
end)

for _, refresh in ipairs({ phoneRefresh, bagRefresh, itemsRefresh }) do
    refresh.Activated:Connect(function()
        task.spawn(refreshAll)
    end)
end

for _, panel in ipairs({ phonePanel, bagPanel, itemsPanel }) do
    panel:GetPropertyChangedSignal("Visible"):Connect(function()
        if panel.Visible then task.spawn(refreshAll) end
    end)
end

task.spawn(function()
    refreshAll()
    while gui.Parent do
        render()
        local remaining = remainingSeconds()
        local secondsSinceRefresh = os.clock() - lastRefreshAt
        if not refreshBusy and not vehicleBusy and secondsSinceRefresh >= 5 then
            refreshAll()
        elseif remaining == 0 and not refreshBusy and secondsSinceRefresh > 2 then
            refreshAll()
        end
        task.wait(1)
    end
end)
