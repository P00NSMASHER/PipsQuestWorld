local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SchoolRemotes")
local stateEvent = remotes:WaitForChild("State")
local answerEvent = remotes:WaitForChild("Answer")

local gui = Instance.new("ScreenGui")
gui.Name = "SchoolHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.fromScale(0.5, 0.035)
card.Size = UDim2.new(0.94, 0, 0, 230)
card.BackgroundTransparency = 0.12
card.BorderSizePixel = 0
card.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = card

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 14)
padding.PaddingBottom = UDim.new(0, 14)
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 16)
padding.Parent = card

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = card

local function makeLabel(name, height, textSize)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, 0, 0, height)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = textSize
    label.Text = ""
    label.Parent = card
    return label
end

local title = makeLabel("Title", 30, 22)
local status = makeLabel("Status", 24, 16)
local question = makeLabel("Question", 52, 18)
local points = makeLabel("Points", 22, 15)

local choicesFrame = Instance.new("Frame")
choicesFrame.Name = "Choices"
choicesFrame.Size = UDim2.new(1, 0, 0, 76)
choicesFrame.BackgroundTransparency = 1
choicesFrame.Parent = card

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.49, 0, 0, 34)
grid.CellPadding = UDim2.new(0.02, 0, 0, 6)
grid.Parent = choicesFrame

local buttons = {}
for i = 1, 4 do
    local button = Instance.new("TextButton")
    button.Name = "Choice" .. i
    button.Text = ""
    button.TextWrapped = true
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.AutoButtonColor = true
    button.Visible = false
    button.Parent = choicesFrame

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 10)
    bc.Parent = button

    buttons[i] = button
end

local currentState = nil
local currentToken = nil

local function clearChoices()
    currentToken = nil
    question.Text = ""
    for _, button in ipairs(buttons) do
        button.Visible = false
        button.Text = ""
        button.Active = false
    end
end

local function showQuestion(q)
    clearChoices()
    if not q then
        return
    end

    currentToken = q.token
    question.Text = q.prompt or ""

    for i, choiceText in ipairs(q.choices or {}) do
        local button = buttons[i]
        if button then
            button.Text = tostring(choiceText)
            button.Visible = true
            button.Active = true
        end
    end
end

for i, button in ipairs(buttons) do
    button.Activated:Connect(function()
        if currentToken == nil then
            return
        end
        for _, other in ipairs(buttons) do
            other.Active = false
        end
        answerEvent:FireServer(currentToken, i)
    end)
end

stateEvent.OnClientEvent:Connect(function(payload)
    currentState = payload
    points.Text = ("School Points: %d"):format(payload.points or 0)

    if payload.phase == "CLASS" then
        title.Text = ("%s • %s"):format(payload.className or "Class", payload.room or "")
        status.Text = payload.answerResult == "correct" and "Correct! +10 points"
            or payload.answerResult == "incorrect" and "Not quite. Next class question will be different."
            or "Class is in session"
        if payload.question then
            showQuestion(payload.question)
        elseif payload.answerResult then
            clearChoices()
        end
    elseif payload.phase == "PASSING" then
        title.Text = "Passing Period"
        status.Text = "Head to the next class."
        clearChoices()
    else
        title.Text = "School Day"
        status.Text = "Classes start soon."
        clearChoices()
    end
end)

RunService.RenderStepped:Connect(function()
    if not currentState or not currentState.endsAt then
        return
    end
    local remaining = math.max(0, currentState.endsAt - os.time())
    local minutes = math.floor(remaining / 60)
    local seconds = remaining % 60
    local timer = ("%d:%02d"):format(minutes, seconds)

    if currentState.phase == "CLASS" then
        status.Text = status.Text:gsub("%s+•%s+%d+:%d+$", "") .. " • " .. timer
    elseif currentState.phase == "PASSING" then
        status.Text = "Head to the next class. • " .. timer
    else
        status.Text = "Classes start soon. • " .. timer
    end
end)
