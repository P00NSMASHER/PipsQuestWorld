local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SchoolRemotes")

local stateRemote = remotes:WaitForChild("SchoolState")
local requestTravelRemote = remotes:WaitForChild("RequestTravel")
local requestQuestionRemote = remotes:WaitForChild("RequestQuestion")
local submitAnswerRemote = remotes:WaitForChild("SubmitAnswer")
local questionPromptRemote = remotes:WaitForChild("QuestionPrompt")
local answerFeedbackRemote = remotes:WaitForChild("AnswerFeedback")

local latestState = nil
local activeQuestionId = nil

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PipHighHud"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
end

local function addStroke(instance, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Transparency = transparency or 0.75
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = instance
end

local card = Instance.new("Frame")
card.Name = "ScheduleCard"
card.AnchorPoint = Vector2.new(0, 0)
card.Position = UDim2.new(0, 14, 0, 14)
card.Size = UDim2.new(0, 300, 0, 174)
card.BackgroundColor3 = Color3.fromRGB(25, 31, 45)
card.BackgroundTransparency = 0.08
card.Parent = screenGui
addCorner(card, 18)
addStroke(card, 0.82)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 16, 0, 12)
title.Size = UDim2.new(1, -32, 0, 24)
title.Font = Enum.Font.GothamBold
title.Text = "PIP HIGH"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local currentLabel = Instance.new("TextLabel")
currentLabel.BackgroundTransparency = 1
currentLabel.Position = UDim2.new(0, 16, 0, 42)
currentLabel.Size = UDim2.new(1, -32, 0, 42)
currentLabel.Font = Enum.Font.GothamBold
currentLabel.Text = "Loading schedule..."
currentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
currentLabel.TextSize = 21
currentLabel.TextWrapped = true
currentLabel.TextXAlignment = Enum.TextXAlignment.Left
currentLabel.Parent = card

local nextLabel = Instance.new("TextLabel")
nextLabel.BackgroundTransparency = 1
nextLabel.Position = UDim2.new(0, 16, 0, 82)
nextLabel.Size = UDim2.new(1, -32, 0, 22)
nextLabel.Font = Enum.Font.Gotham
nextLabel.Text = "Next: --"
nextLabel.TextColor3 = Color3.fromRGB(190, 202, 225)
nextLabel.TextSize = 14
nextLabel.TextXAlignment = Enum.TextXAlignment.Left
nextLabel.Parent = card

local pointsLabel = Instance.new("TextLabel")
pointsLabel.BackgroundTransparency = 1
pointsLabel.Position = UDim2.new(0, 16, 0, 106)
pointsLabel.Size = UDim2.new(1, -32, 0, 20)
pointsLabel.Font = Enum.Font.GothamMedium
pointsLabel.Text = "Points: 0"
pointsLabel.TextColor3 = Color3.fromRGB(255, 221, 119)
pointsLabel.TextSize = 14
pointsLabel.TextXAlignment = Enum.TextXAlignment.Left
pointsLabel.Parent = card

local buttonRow = Instance.new("Frame")
buttonRow.BackgroundTransparency = 1
buttonRow.Position = UDim2.new(0, 14, 1, -48)
buttonRow.Size = UDim2.new(1, -28, 0, 38)
buttonRow.Parent = card

local goButton = Instance.new("TextButton")
goButton.Size = UDim2.new(0.5, -5, 1, 0)
goButton.BackgroundColor3 = Color3.fromRGB(73, 122, 210)
goButton.Font = Enum.Font.GothamBold
goButton.Text = "GO TO CLASS"
goButton.TextColor3 = Color3.fromRGB(255, 255, 255)
goButton.TextSize = 13
goButton.Parent = buttonRow
addCorner(goButton, 11)

local questionButton = Instance.new("TextButton")
questionButton.AnchorPoint = Vector2.new(1, 0)
questionButton.Position = UDim2.new(1, 0, 0, 0)
questionButton.Size = UDim2.new(0.5, -5, 1, 0)
questionButton.BackgroundColor3 = Color3.fromRGB(124, 85, 181)
questionButton.Font = Enum.Font.GothamBold
questionButton.Text = "CLASS QUESTION"
questionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
questionButton.TextSize = 12
questionButton.Parent = buttonRow
addCorner(questionButton, 11)

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -24)
toast.Size = UDim2.new(0.9, 0, 0, 46)
toast.BackgroundColor3 = Color3.fromRGB(25, 31, 45)
toast.BackgroundTransparency = 0.08
toast.Font = Enum.Font.GothamMedium
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.TextSize = 14
toast.TextWrapped = true
toast.Visible = false
toast.Parent = screenGui
addCorner(toast, 14)

local modal = Instance.new("Frame")
modal.Name = "QuestionModal"
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.56)
modal.Size = UDim2.new(0.9, 0, 0, 360)
modal.SizeConstraint = Enum.SizeConstraint.RelativeXX
modal.BackgroundColor3 = Color3.fromRGB(21, 26, 38)
modal.Visible = false
modal.Parent = screenGui
addCorner(modal, 20)
addStroke(modal, 0.75)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(560, 430)
sizeConstraint.MinSize = Vector2.new(300, 340)
sizeConstraint.Parent = modal

local questionLabel = Instance.new("TextLabel")
questionLabel.BackgroundTransparency = 1
questionLabel.Position = UDim2.new(0, 20, 0, 18)
questionLabel.Size = UDim2.new(1, -40, 0, 94)
questionLabel.Font = Enum.Font.GothamBold
questionLabel.Text = ""
questionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
questionLabel.TextSize = 20
questionLabel.TextWrapped = true
questionLabel.TextYAlignment = Enum.TextYAlignment.Top
questionLabel.Parent = modal

local choicesFrame = Instance.new("Frame")
choicesFrame.BackgroundTransparency = 1
choicesFrame.Position = UDim2.new(0, 20, 0, 116)
choicesFrame.Size = UDim2.new(1, -40, 0, 208)
choicesFrame.Parent = modal

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = choicesFrame

local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.BackgroundTransparency = 1
feedbackLabel.Position = UDim2.new(0, 20, 1, -48)
feedbackLabel.Size = UDim2.new(1, -40, 0, 34)
feedbackLabel.Font = Enum.Font.GothamMedium
feedbackLabel.Text = ""
feedbackLabel.TextColor3 = Color3.fromRGB(206, 215, 232)
feedbackLabel.TextSize = 13
feedbackLabel.TextWrapped = true
feedbackLabel.Parent = modal

local function showToast(message)
    toast.Text = message
    toast.Visible = true
    local expected = message
    task.delay(2.4, function()
        if toast.Text == expected then
            toast.Visible = false
        end
    end)
end

local function clearChoices()
    for _, child in ipairs(choicesFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function openQuestion(payload)
    activeQuestionId = payload.id
    questionLabel.Text = payload.subject .. "\n" .. payload.prompt
    feedbackLabel.Text = ""
    clearChoices()

    for index, choice in ipairs(payload.choices) do
        local button = Instance.new("TextButton")
        button.Name = "Choice" .. tostring(index)
        button.Size = UDim2.new(1, 0, 0, 44)
        button.BackgroundColor3 = Color3.fromRGB(48, 58, 79)
        button.Font = Enum.Font.GothamMedium
        button.Text = tostring(index) .. ".  " .. choice
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 15
        button.TextWrapped = true
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = choicesFrame
        addCorner(button, 10)

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 14)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = button

        button.Activated:Connect(function()
            if activeQuestionId then
                submitAnswerRemote:FireServer(activeQuestionId, index)
            end
        end)
    end

    modal.Visible = true
end

goButton.Activated:Connect(function()
    if latestState then
        requestTravelRemote:FireServer(latestState.periodIndex)
    end
end)

questionButton.Activated:Connect(function()
    requestQuestionRemote:FireServer()
end)

stateRemote.OnClientEvent:Connect(function(state)
    latestState = state

    local minutes = math.floor(state.secondsRemaining / 60)
    local seconds = state.secondsRemaining % 60
    currentLabel.Text = string.format("%s  %d:%02d", state.label, minutes, seconds)
    nextLabel.Text = "Next: " .. state.nextLabel .. "  •  Room: " .. state.room
    pointsLabel.Text = "Points: " .. tostring(state.points)

    questionButton.Visible = state.canQuestion == true
    if not state.canQuestion then
        goButton.Size = UDim2.new(1, 0, 1, 0)
        goButton.Text = "GO TO " .. string.upper(state.label)
    else
        goButton.Size = UDim2.new(0.5, -5, 1, 0)
        goButton.Text = "GO TO CLASS"
    end
end)

questionPromptRemote.OnClientEvent:Connect(openQuestion)

answerFeedbackRemote.OnClientEvent:Connect(function(payload)
    if payload.kind == "answer" and modal.Visible then
        feedbackLabel.Text = payload.message or ""

        if payload.completed then
            activeQuestionId = nil
            task.delay(1.8, function()
                modal.Visible = false
            end)
        end
    else
        showToast(payload.message or "")
    end
end)
