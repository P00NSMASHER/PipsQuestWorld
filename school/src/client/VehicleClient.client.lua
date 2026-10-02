local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local root = ReplicatedStorage:WaitForChild("SchoolFoundation")
local vehicleRoot = root:WaitForChild("FreeRoam"):WaitForChild("Vehicles")
local getState = vehicleRoot:WaitForChild("GetState")
local spawnVehicle = vehicleRoot:WaitForChild("Spawn")
local despawnVehicle = vehicleRoot:WaitForChild("Despawn")

local gui = Instance.new("ScreenGui")
gui.Name = "PipHighVehicleUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 1)
card.Position = UDim2.new(0.5, 0, 1, -18)
card.Size = UDim2.new(0, 310, 0, 138)
card.BackgroundColor3 = Color3.fromRGB(31, 38, 51)
card.BackgroundTransparency = 0.05
card.Visible = false
card.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = card

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 10)
title.Size = UDim2.new(1, -28, 0, 24)
title.Font = Enum.Font.GothamBold
title.Text = "AUTO SHOP"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 14, 0, 39)
status.Size = UDim2.new(1, -28, 0, 38)
status.Font = Enum.Font.Gotham
status.Text = "Spawn the starter car."
status.TextColor3 = Color3.fromRGB(196, 205, 222)
status.TextSize = 13
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = card

local action = Instance.new("TextButton")
action.Position = UDim2.new(0, 14, 1, -52)
action.Size = UDim2.new(1, -28, 0, 42)
action.BackgroundColor3 = Color3.fromRGB(70, 124, 198)
action.Font = Enum.Font.GothamBold
action.Text = "SPAWN STARTER CAR"
action.TextColor3 = Color3.new(1, 1, 1)
action.TextSize = 14
action.Parent = card

local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 11)
actionCorner.Parent = action

local latestState = nil
local busy = false
local messageUntil = 0

local function message(text)
    status.Text = text
    messageUntil = os.clock() + 2.6
end

local function applyState(state)
    if type(state) ~= "table" then
        return
    end

    latestState = state
    card.Visible = state.active == true or state.atAutoShop == true

    if state.active == true then
        title.Text = "STARTER CAR"
        action.Text = "DESPAWN VEHICLE"
        if os.clock() >= messageUntil then
            if state.driving == true then
                status.Text = "Drive with the seat controls. Jump to exit."
            else
                status.Text = "Walk to the driver seat to continue driving."
            end
        end
    else
        title.Text = tostring(state.autoShopDisplayName or "AUTO SHOP"):upper()
        action.Text = "SPAWN STARTER CAR"
        if os.clock() >= messageUntil then
            status.Text = "Spawn the starter car and drive around town."
        end
    end
end

local function refresh()
    local ok, state = pcall(function()
        return getState:InvokeServer()
    end)
    if ok and type(state) == "table" then
        applyState(state)
    end
end

action.Activated:Connect(function()
    if busy then
        return
    end

    busy = true
    action.Active = false
    action.Text = "WORKING..."

    local ok, response
    if latestState and latestState.active == true then
        ok, response = pcall(function()
            return despawnVehicle:InvokeServer()
        end)
    else
        ok, response = pcall(function()
            return spawnVehicle:InvokeServer()
        end)
    end

    busy = false
    action.Active = true

    if not ok or type(response) ~= "table" then
        message("Vehicle service unavailable. Try again.")
        refresh()
        return
    end

    if response.accepted ~= true then
        if response.code == "not_at_auto_shop" then
            message("Move closer to the Auto Shop first.")
        elseif response.code == "vehicle_already_active" then
            message("You already have an active vehicle.")
        else
            message("That vehicle action is not available right now.")
        end
    elseif response.code == "vehicle_spawned" then
        message("Starter car ready. Use the seat controls to drive.")
    elseif response.code == "vehicle_despawned"
        or response.code == "vehicle_already_despawned" then
        message("Vehicle returned.")
    end

    if response.state then
        applyState(response.state)
    else
        refresh()
    end
end)

task.spawn(function()
    while gui.Parent do
        refresh()
        task.wait(0.75)
    end
end)
