--!strict
-- Original mobile-friendly cafe job UX for the assigned Pip High free-roam slice.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local SchoolConfig = require(shared:WaitForChild("SchoolConfig"))
local remoteRoot = ReplicatedStorage:WaitForChild(SchoolConfig.Interfaces.remoteFolder)
local cafeRoot = remoteRoot:WaitForChild("FreeRoam"):WaitForChild("CafeJob")
local getState = cafeRoot:WaitForChild("GetState")
local startShift = cafeRoot:WaitForChild("StartShift")
local completeTask = cafeRoot:WaitForChild("CompleteTask")
local leaveShift = cafeRoot:WaitForChild("LeaveShift")

local gui = Instance.new("ScreenGui")
gui.Name = "PipHighCafeJobUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 4
gui.Parent = player:WaitForChild("PlayerGui")

local function round(target, px)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, px)
    corner.Parent = target
end

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(1, 1)
card.Position = UDim2.new(1, -14, 1, -18)
card.Size = UDim2.new(0, 300, 0, 168)
card.BackgroundColor3 = Color3.fromRGB(247, 241, 228)
card.BackgroundTransparency = 0.03
card.Visible = false
card.Parent = gui
round(card, 16)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(270, 160)
sizeConstraint.MaxSize = Vector2.new(330, 180)
sizeConstraint.Parent = card

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 10)
title.Size = UDim2.new(1, -28, 0, 24)
title.Font = Enum.Font.GothamBold
title.Text = "CORNER CAFE"
title.TextColor3 = Color3.fromRGB(58, 47, 38)
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 14, 0, 39)
status.Size = UDim2.new(1, -28, 0, 44)
status.Font = Enum.Font.Gotham
status.Text = "Walk into the cafe to start a shift."
status.TextColor3 = Color3.fromRGB(92, 78, 65)
status.TextSize = 13
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = card

local action = Instance.new("TextButton")
action.Position = UDim2.new(0, 14, 1, -58)
action.Size = UDim2.new(1, -28, 0, 44)
action.BackgroundColor3 = Color3.fromRGB(124, 83, 54)
action.Font = Enum.Font.GothamBold
action.Text = "START SHIFT"
action.TextColor3 = Color3.new(1, 1, 1)
action.TextSize = 14
action.Parent = card
round(action, 11)

local leave = Instance.new("TextButton")
leave.AnchorPoint = Vector2.new(1, 0)
leave.Position = UDim2.new(1, -12, 0, 8)
leave.Size = UDim2.new(0, 82, 0, 30)
leave.BackgroundTransparency = 1
leave.Font = Enum.Font.GothamMedium
leave.Text = "LEAVE JOB"
leave.TextColor3 = Color3.fromRGB(117, 98, 82)
leave.TextSize = 11
leave.Visible = false
leave.Parent = card

local latest = nil
local busy = false
local messageUntil = 0

local function localNearCafe()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end
    local cafe = SchoolConfig.WorldLocations.Cafe
    return (root.Position - cafe.position).Magnitude <= 46
end

local function setMessage(text)
    status.Text = text
    messageUntil = os.clock() + 2.8
end

local function applyState(state)
    if type(state) ~= "table" then
        return
    end
    latest = state

    local active = state.active == true
    local nearby = state.atCafe == true or localNearCafe()
    card.Visible = active or nearby
    leave.Visible = active

    if active then
        action.Text = "SERVE ORDER  •  +$" .. tostring(state.wage or 25)
        if os.clock() >= messageUntil then
            status.Text = "Shift active. Serve the waiting order to finish this cafe shift."
        end
    else
        action.Text = "START SHIFT  •  +$" .. tostring(state.wage or 25)
        if os.clock() >= messageUntil then
            status.Text = nearby
                and "Start a short cafe shift and serve one order."
                or "Walk into the cafe to start a shift."
        end
    end
end

local function refresh()
    local ok, response = pcall(function()
        return getState:InvokeServer()
    end)
    if ok and type(response) == "table" then
        applyState(response)
    elseif latest == nil then
        card.Visible = localNearCafe()
        status.Text = "Cafe job service is unavailable."
    end
end

action.Activated:Connect(function()
    if busy then
        return
    end
    busy = true
    action.AutoButtonColor = false
    action.Text = "WORKING..."

    local ok, response
    if latest and latest.active == true then
        ok, response = pcall(function()
            return completeTask:InvokeServer(latest.shiftId, latest.taskId)
        end)
    else
        ok, response = pcall(function()
            return startShift:InvokeServer()
        end)
    end

    busy = false
    action.AutoButtonColor = true

    if not ok or type(response) ~= "table" then
        setMessage("Could not update the cafe job. Try again.")
        refresh()
        return
    end

    if response.accepted ~= true then
        if response.code == "not_at_cafe" then
            setMessage("Move closer to the cafe counter first.")
        elseif response.code == "economy_unavailable" or response.code == "wage_commit_failed" then
            setMessage("Your wage could not be saved yet. Try the same task again.")
        else
            setMessage("That cafe action is not available right now.")
        end
        refresh()
        return
    end

    if response.returnToFreeRoam == true then
        local balance = response.economyState and response.economyState.balance
        local balanceText = type(balance) == "number" and ("  •  Balance $" .. tostring(balance)) or ""
        setMessage("Shift complete! +$" .. tostring(response.wage or 25) .. balanceText)
    elseif response.code == "shift_started" or response.code == "shift_already_active" then
        setMessage("Shift started. Serve the waiting order.")
    end

    refresh()
end)

leave.Activated:Connect(function()
    if busy then
        return
    end
    busy = true
    local ok, response = pcall(function()
        return leaveShift:InvokeServer()
    end)
    busy = false

    if ok and type(response) == "table" and response.accepted == true then
        setMessage("Shift ended. Back to free roam.")
    else
        setMessage("Could not leave the shift yet.")
    end
    refresh()
end)

task.spawn(function()
    while gui.Parent do
        refresh()
        task.wait(0.75)
    end
end)
