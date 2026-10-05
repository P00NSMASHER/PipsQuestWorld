--!strict
-- Responsive, self-contained client presentation for the Market stock shift.
-- The client presents server-provided choices only; task order and answers stay server-side.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remoteRoot = ReplicatedStorage:WaitForChild("SchoolFoundation")
local marketRoot = remoteRoot:WaitForChild("FreeRoam"):WaitForChild("MarketStockJob")
local getStateRemote = marketRoot:WaitForChild("GetState")
local startShiftRemote = marketRoot:WaitForChild("StartShift")
local submitSortRemote = marketRoot:WaitForChild("SubmitSort")
local leaveShiftRemote = marketRoot:WaitForChild("LeaveShift")
local openPanelRemote = marketRoot:WaitForChild("OpenPanel")

local COLORS = {
    overlay = Color3.fromRGB(17, 25, 32),
    panel = Color3.fromRGB(247, 244, 232),
    header = Color3.fromRGB(53, 105, 72),
    headerDark = Color3.fromRGB(37, 75, 52),
    card = Color3.fromRGB(255, 253, 245),
    ink = Color3.fromRGB(37, 52, 47),
    muted = Color3.fromRGB(91, 105, 99),
    line = Color3.fromRGB(199, 207, 192),
    accent = Color3.fromRGB(241, 178, 62),
    accentDark = Color3.fromRGB(123, 77, 12),
    positive = Color3.fromRGB(48, 129, 78),
    softGreen = Color3.fromRGB(222, 241, 224),
    softGold = Color3.fromRGB(255, 241, 203),
    white = Color3.fromRGB(255, 255, 255),
}

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function addStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.Transparency = transparency or 0
    stroke.Parent = parent
    return stroke
end

local function styleButton(button, background, foreground)
    button.AutoButtonColor = true
    button.BackgroundColor3 = background
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = foreground
    button.TextSize = 15
    addCorner(button, 10)
    addStroke(button, Color3.fromRGB(31, 62, 44), 1, 0.7)
end

local gui = Instance.new("ScreenGui")
gui.Name = "MarketStockJobGui"
gui.DisplayOrder = 50
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = COLORS.overlay
overlay.BackgroundTransparency = 0.28
overlay.BorderSizePixel = 0
overlay.Size = UDim2.fromScale(1, 1)
overlay.Visible = false
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "StockPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = COLORS.panel
panel.BorderSizePixel = 0
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.92, 0, 0.82, 0)
panel.Parent = overlay
addCorner(panel, 18)
addStroke(panel, COLORS.headerDark, 2, 0.2)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(280, 220)
sizeConstraint.MaxSize = Vector2.new(540, 520)
sizeConstraint.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.BackgroundColor3 = COLORS.header
header.BorderSizePixel = 0
header.Size = UDim2.new(1, 0, 0, 62)
header.Parent = panel
addCorner(header, 18)

local headerMask = Instance.new("Frame")
headerMask.BackgroundColor3 = COLORS.header
headerMask.BorderSizePixel = 0
headerMask.Position = UDim2.new(0, 0, 1, -18)
headerMask.Size = UDim2.new(1, 0, 0, 18)
headerMask.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(20, 8)
title.Size = UDim2.new(1, -76, 0, 27)
title.Font = Enum.Font.GothamBold
title.Text = "MARKET STOCK SHIFT"
title.TextColor3 = COLORS.white
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(20, 34)
subtitle.Size = UDim2.new(1, -76, 0, 18)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Match each item to its best aisle"
subtitle.TextColor3 = Color3.fromRGB(221, 240, 225)
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.BackgroundColor3 = COLORS.headerDark
closeButton.BorderSizePixel = 0
closeButton.Position = UDim2.new(1, -14, 0.5, 0)
closeButton.Size = UDim2.fromOffset(38, 38)
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.white
closeButton.TextSize = 16
closeButton.Parent = header
addCorner(closeButton, 10)

local body = Instance.new("ScrollingFrame")
body.Name = "Content"
body.Active = true
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.CanvasSize = UDim2.fromOffset(0, 370)
body.Position = UDim2.fromOffset(0, 62)
body.ScrollBarImageColor3 = COLORS.header
body.ScrollBarThickness = 5
body.Size = UDim2.new(1, 0, 1, -128)
body.Parent = panel

local progressLabel = Instance.new("TextLabel")
progressLabel.BackgroundColor3 = COLORS.softGold
progressLabel.BorderSizePixel = 0
progressLabel.Position = UDim2.fromOffset(16, 14)
progressLabel.Size = UDim2.new(1, -32, 0, 30)
progressLabel.Font = Enum.Font.GothamBold
progressLabel.Text = "READY FOR A 3-ITEM SHIFT"
progressLabel.TextColor3 = COLORS.accentDark
progressLabel.TextSize = 13
progressLabel.Parent = body
addCorner(progressLabel, 9)

local taskCard = Instance.new("Frame")
taskCard.Name = "TaskCard"
taskCard.BackgroundColor3 = COLORS.card
taskCard.BorderSizePixel = 0
taskCard.Position = UDim2.fromOffset(16, 56)
taskCard.Size = UDim2.new(1, -32, 0, 104)
taskCard.Parent = body
addCorner(taskCard, 12)
addStroke(taskCard, COLORS.line, 1, 0.15)

local itemLabel = Instance.new("TextLabel")
itemLabel.BackgroundTransparency = 1
itemLabel.Position = UDim2.fromOffset(16, 12)
itemLabel.Size = UDim2.new(1, -32, 0, 32)
itemLabel.Font = Enum.Font.GothamBold
itemLabel.Text = "Ready to help?"
itemLabel.TextColor3 = COLORS.ink
itemLabel.TextSize = 22
itemLabel.TextWrapped = true
itemLabel.TextXAlignment = Enum.TextXAlignment.Left
itemLabel.Parent = taskCard

local promptLabel = Instance.new("TextLabel")
promptLabel.BackgroundTransparency = 1
promptLabel.Position = UDim2.fromOffset(16, 50)
promptLabel.Size = UDim2.new(1, -32, 0, 42)
promptLabel.Font = Enum.Font.Gotham
promptLabel.Text = "Start a short shift and sort three items. Wrong answers only give a helpful hint."
promptLabel.TextColor3 = COLORS.muted
promptLabel.TextSize = 14
promptLabel.TextWrapped = true
promptLabel.TextXAlignment = Enum.TextXAlignment.Left
promptLabel.TextYAlignment = Enum.TextYAlignment.Top
promptLabel.Parent = taskCard

local choicesFrame = Instance.new("Frame")
choicesFrame.Name = "AisleChoices"
choicesFrame.BackgroundTransparency = 1
choicesFrame.Position = UDim2.fromOffset(16, 172)
choicesFrame.Size = UDim2.new(1, -32, 0, 150)
choicesFrame.Parent = body

local choicesLayout = Instance.new("UIListLayout")
choicesLayout.Padding = UDim.new(0, 8)
choicesLayout.SortOrder = Enum.SortOrder.LayoutOrder
choicesLayout.Parent = choicesFrame

local choiceButtons = {}
for index = 1, 3 do
    local button = Instance.new("TextButton")
    button.Name = "AisleChoice" .. tostring(index)
    button.LayoutOrder = index
    button.Size = UDim2.new(1, 0, 0, 44)
    button.Text = "AISLE"
    button.Visible = false
    button.Parent = choicesFrame
    styleButton(button, Color3.fromRGB(235, 241, 229), COLORS.headerDark)
    choiceButtons[index] = button
end

local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.Name = "Feedback"
feedbackLabel.BackgroundColor3 = COLORS.softGreen
feedbackLabel.BorderSizePixel = 0
feedbackLabel.Position = UDim2.fromOffset(16, 330)
feedbackLabel.Size = UDim2.new(1, -32, 0, 40)
feedbackLabel.Font = Enum.Font.Gotham
feedbackLabel.Text = "Use the stock station prompt whenever you want to work."
feedbackLabel.TextColor3 = COLORS.headerDark
feedbackLabel.TextSize = 13
feedbackLabel.TextWrapped = true
feedbackLabel.Parent = body
addCorner(feedbackLabel, 9)

local resultCard = Instance.new("Frame")
resultCard.Name = "ResultCard"
resultCard.BackgroundColor3 = COLORS.softGreen
resultCard.BorderSizePixel = 0
resultCard.Position = UDim2.fromOffset(16, 56)
resultCard.Size = UDim2.new(1, -32, 0, 266)
resultCard.Visible = false
resultCard.Parent = body
addCorner(resultCard, 14)
addStroke(resultCard, COLORS.positive, 2, 0.45)

local resultTitle = Instance.new("TextLabel")
resultTitle.BackgroundTransparency = 1
resultTitle.Position = UDim2.fromOffset(18, 20)
resultTitle.Size = UDim2.new(1, -36, 0, 38)
resultTitle.Font = Enum.Font.GothamBold
resultTitle.Text = "STOCK STAR!"
resultTitle.TextColor3 = COLORS.positive
resultTitle.TextSize = 26
resultTitle.Parent = resultCard

local resultMessage = Instance.new("TextLabel")
resultMessage.BackgroundTransparency = 1
resultMessage.Position = UDim2.fromOffset(24, 68)
resultMessage.Size = UDim2.new(1, -48, 0, 62)
resultMessage.Font = Enum.Font.Gotham
resultMessage.Text = "You sorted all three items and helped the Market run smoothly."
resultMessage.TextColor3 = COLORS.ink
resultMessage.TextSize = 15
resultMessage.TextWrapped = true
resultMessage.Parent = resultCard

local rewardLabel = Instance.new("TextLabel")
rewardLabel.BackgroundColor3 = COLORS.accent
rewardLabel.BorderSizePixel = 0
rewardLabel.Position = UDim2.new(0.5, -110, 0, 146)
rewardLabel.Size = UDim2.fromOffset(220, 48)
rewardLabel.Font = Enum.Font.GothamBold
rewardLabel.Text = "+$45 SHIFT PAY"
rewardLabel.TextColor3 = COLORS.accentDark
rewardLabel.TextSize = 19
rewardLabel.Parent = resultCard
addCorner(rewardLabel, 12)

local balanceLabel = Instance.new("TextLabel")
balanceLabel.BackgroundTransparency = 1
balanceLabel.Position = UDim2.fromOffset(18, 208)
balanceLabel.Size = UDim2.new(1, -36, 0, 28)
balanceLabel.Font = Enum.Font.GothamBold
balanceLabel.Text = "New balance: --"
balanceLabel.TextColor3 = COLORS.headerDark
balanceLabel.TextSize = 15
balanceLabel.Parent = resultCard

local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.AnchorPoint = Vector2.new(0, 1)
footer.BackgroundColor3 = Color3.fromRGB(237, 234, 220)
footer.BorderSizePixel = 0
footer.Position = UDim2.fromScale(0, 1)
footer.Size = UDim2.new(1, 0, 0, 66)
footer.Parent = panel

local footerLine = Instance.new("Frame")
footerLine.BackgroundColor3 = COLORS.line
footerLine.BorderSizePixel = 0
footerLine.Size = UDim2.new(1, 0, 0, 1)
footerLine.Parent = footer

local leaveButton = Instance.new("TextButton")
leaveButton.Name = "LeaveShift"
leaveButton.Position = UDim2.fromOffset(14, 12)
leaveButton.Size = UDim2.new(0.38, -7, 0, 42)
leaveButton.Text = "LEAVE SHIFT"
leaveButton.Visible = false
leaveButton.Parent = footer
styleButton(leaveButton, Color3.fromRGB(222, 224, 218), COLORS.muted)

local primaryButton = Instance.new("TextButton")
primaryButton.Name = "PrimaryAction"
primaryButton.Position = UDim2.fromOffset(14, 12)
primaryButton.Size = UDim2.new(1, -28, 0, 42)
primaryButton.Text = "START 3-ITEM SHIFT"
primaryButton.Parent = footer
styleButton(primaryButton, COLORS.accent, COLORS.accentDark)

-- Keep the fixed header and footer reachable on the minimum 480x300 phone
-- viewport. The task cards stay in the scrolling middle region, while larger
-- windows retain the original desktop proportions.
local viewportConnection = nil
local function applyResponsiveLayout()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    if viewport.X <= 0 or viewport.Y <= 0 then return end

    local compact = viewport.Y < 380 or viewport.X < 420
    if compact then
        panel.Size = UDim2.new(1, -24, 1, -16)
        sizeConstraint.MinSize = Vector2.new(280, 220)
        header.Size = UDim2.new(1, 0, 0, 54)
        headerMask.Position = UDim2.new(0, 0, 1, -18)
        title.Position = UDim2.fromOffset(16, 5)
        title.Size = UDim2.new(1, -72, 0, 23)
        title.TextSize = 17
        subtitle.Position = UDim2.fromOffset(16, 29)
        subtitle.Size = UDim2.new(1, -72, 0, 16)
        subtitle.TextSize = 11
        closeButton.Position = UDim2.new(1, -8, 0.5, 0)
        closeButton.Size = UDim2.fromOffset(40, 40)
        body.Position = UDim2.fromOffset(0, 54)
        body.Size = UDim2.new(1, 0, 1, -112)
        body.ScrollBarThickness = 7
        footer.Size = UDim2.new(1, 0, 0, 58)
        leaveButton.Position = UDim2.fromOffset(10, 8)
        leaveButton.Size = UDim2.new(0.38, -5, 0, 42)
        primaryButton.Position = UDim2.fromOffset(10, 8)
        primaryButton.Size = UDim2.new(1, -20, 0, 42)
    else
        panel.Size = UDim2.new(0.92, 0, 0.82, 0)
        sizeConstraint.MinSize = Vector2.new(300, 310)
        header.Size = UDim2.new(1, 0, 0, 62)
        headerMask.Position = UDim2.new(0, 0, 1, -18)
        title.Position = UDim2.fromOffset(20, 8)
        title.Size = UDim2.new(1, -76, 0, 27)
        title.TextSize = 20
        subtitle.Position = UDim2.fromOffset(20, 34)
        subtitle.Size = UDim2.new(1, -76, 0, 18)
        subtitle.TextSize = 12
        closeButton.Position = UDim2.new(1, -14, 0.5, 0)
        closeButton.Size = UDim2.fromOffset(38, 38)
        body.Position = UDim2.fromOffset(0, 62)
        body.Size = UDim2.new(1, 0, 1, -128)
        body.ScrollBarThickness = 5
        footer.Size = UDim2.new(1, 0, 0, 66)
        leaveButton.Position = UDim2.fromOffset(14, 12)
        leaveButton.Size = UDim2.new(0.38, -7, 0, 42)
        primaryButton.Position = UDim2.fromOffset(14, 12)
        primaryButton.Size = UDim2.new(1, -28, 0, 42)
    end
end

local function bindViewport(camera)
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize")
            :Connect(applyResponsiveLayout)
    end
    applyResponsiveLayout()
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    bindViewport(Workspace.CurrentCamera)
end)
bindViewport(Workspace.CurrentCamera)

local latestState = nil
local latestChoices = {}
local pendingRequest = nil
local primaryMode = "start"
local busy = false

local function setFeedback(text, positive)
    feedbackLabel.Text = text
    feedbackLabel.BackgroundColor3 = positive and COLORS.softGreen or COLORS.softGold
    feedbackLabel.TextColor3 = positive and COLORS.headerDark or COLORS.accentDark
end

local function setBusy(nextBusy)
    busy = nextBusy
    primaryButton.Active = not nextBusy
    leaveButton.Active = not nextBusy
    primaryButton.AutoButtonColor = not nextBusy
    leaveButton.AutoButtonColor = not nextBusy
    for _, button in ipairs(choiceButtons) do
        button.Active = not nextBusy
        button.AutoButtonColor = not nextBusy
    end
end

local function showPrimary(mode, text)
    primaryMode = mode
    primaryButton.Text = text
    primaryButton.Visible = true
end

local function renderState(state, feedback, feedbackPositive)
    if type(state) ~= "table" then
        return
    end
    latestState = state
    resultCard.Visible = false
    taskCard.Visible = true
    feedbackLabel.Visible = true

    if state.active == true and type(state.task) == "table" then
        local completedSteps = tonumber(state.completedSteps) or 0
        local totalSteps = tonumber(state.totalSteps) or 3
        progressLabel.Text = string.format(
            "ITEM %d OF %d  |  $%d SHIFT PAY",
            completedSteps + 1,
            totalSteps,
            tonumber(state.wage) or 0
        )
        itemLabel.Text = tostring(state.task.itemLabel or "Stock item")
        promptLabel.Text = tostring(state.task.prompt or "Choose the best aisle.")
        latestChoices = type(state.task.choices) == "table" and state.task.choices or {}
        choicesFrame.Visible = true
        for index, button in ipairs(choiceButtons) do
            local choice = latestChoices[index]
            button.Visible = type(choice) == "table"
            button.Text = choice and tostring(choice.label or "AISLE"):upper() or "AISLE"
        end
        leaveButton.Visible = true
        primaryButton.Visible = false
        setFeedback(
            feedback or "Pick the aisle that makes the most sense. You can retry any miss.",
            feedbackPositive ~= false
        )
    else
        progressLabel.Text = "READY FOR A 3-ITEM SHIFT"
        itemLabel.Text = "Ready to help?"
        promptLabel.Text = "Start a short shift and sort three items. Wrong answers only give a helpful hint."
        latestChoices = {}
        choicesFrame.Visible = false
        for _, button in ipairs(choiceButtons) do
            button.Visible = false
        end
        leaveButton.Visible = false
        showPrimary("start", "START 3-ITEM SHIFT")
        setFeedback(
            feedback or "Complete all three items to earn the listed shift pay.",
            feedbackPositive ~= false
        )
    end
end

local function renderResult(result)
    latestState = nil
    latestChoices = {}
    pendingRequest = nil
    taskCard.Visible = false
    choicesFrame.Visible = false
    feedbackLabel.Visible = false
    resultCard.Visible = true
    progressLabel.Text = "3 OF 3 ITEMS SORTED"
    resultTitle.Text = tostring(result.title or "Stock star!"):upper()
    resultMessage.Text = tostring(
        result.message or "You completed the stock shift."
    )
    rewardLabel.Text = string.format(
        "+$%d SHIFT PAY",
        tonumber(result.wage) or 0
    )
    if result.balance ~= nil then
        balanceLabel.Text = string.format("New balance: $%d", tonumber(result.balance) or 0)
    else
        balanceLabel.Text = "Shift pay saved"
    end
    leaveButton.Visible = false
    showPrimary("done", "DONE")
end

local function friendlyFailure(code)
    if code == "not_at_market" then
        return "Stay near the Market stock station to work this shift."
    elseif code == "stale_task" or code == "stale_shift" then
        return "The shift moved ahead. Your current item has been refreshed."
    elseif code == "request_conflict" then
        return "That tap was already used. Please choose the aisle again."
    elseif code == "economy_unavailable" or code == "wage_commit_failed" then
        return "Your work is still here. Try the final aisle again in a moment."
    elseif code == "no_active_shift" then
        return "That shift has ended. Start a fresh shift when you are ready."
    end
    return "The stock desk could not process that yet. Please try again."
end

local function applyResponse(response)
    if type(response) ~= "table" then
        setFeedback("The stock desk sent an unexpected response. Please try again.", false)
        return
    end
    if type(response.result) == "table" and response.accepted == true then
        renderResult(response.result)
        return
    end

    local feedback = response.feedback
    if type(feedback) ~= "string" or feedback == "" then
        feedback = response.accepted == true
            and "Shift updated."
            or friendlyFailure(response.code)
    end
    if type(response.state) == "table" then
        local feedbackPositive = response.accepted == true
            and response.code ~= "try_again"
        renderState(response.state, feedback, feedbackPositive)
    else
        setFeedback(feedback, response.accepted == true)
    end
end

local function refreshState()
    setBusy(true)
    local ok, state = pcall(function()
        return getStateRemote:InvokeServer()
    end)
    setBusy(false)
    if not ok or type(state) ~= "table" then
        setFeedback("Connection hiccup. Close and use the stock prompt to retry.", false)
        return
    end
    renderState(state)
end

local function startShift()
    if busy then
        return
    end
    setBusy(true)
    primaryButton.Text = "STARTING..."
    local ok, response = pcall(function()
        return startShiftRemote:InvokeServer()
    end)
    setBusy(false)
    if not ok then
        showPrimary("start", "TRY START AGAIN")
        setFeedback("Connection hiccup. Your shift did not start; please retry.", false)
        return
    end
    applyResponse(response)
end

local function submitChoice(choice)
    if busy
        or type(latestState) ~= "table"
        or latestState.active ~= true
        or type(latestState.task) ~= "table"
        or type(choice) ~= "table" then
        return
    end

    local shiftId = tostring(latestState.shiftId or "")
    local taskToken = tostring(latestState.task.token or "")
    local choiceId = tostring(choice.id or "")
    local signature = shiftId .. "|" .. taskToken .. "|" .. choiceId
    if not pendingRequest or pendingRequest.signature ~= signature then
        pendingRequest = {
            signature = signature,
            requestId = "market:" .. HttpService:GenerateGUID(false),
        }
    end

    setBusy(true)
    setFeedback("Checking that aisle...", true)
    local requestId = pendingRequest.requestId
    local ok, response = pcall(function()
        return submitSortRemote:InvokeServer(
            shiftId,
            taskToken,
            choiceId,
            requestId
        )
    end)
    setBusy(false)
    if not ok then
        setFeedback("Connection hiccup. Tap the same aisle to safely retry.", false)
        return
    end

    local transient = type(response) == "table"
        and (response.code == "economy_unavailable" or response.code == "wage_commit_failed")
    if not transient then
        pendingRequest = nil
    end
    applyResponse(response)
end

local function leaveShift()
    if busy then
        return
    end
    setBusy(true)
    leaveButton.Text = "LEAVING..."
    local ok, response = pcall(function()
        return leaveShiftRemote:InvokeServer()
    end)
    leaveButton.Text = "LEAVE SHIFT"
    setBusy(false)
    if not ok then
        setFeedback("Connection hiccup. Your shift is still available to continue.", false)
        return
    end
    pendingRequest = nil
    applyResponse(response)
end

for index, button in ipairs(choiceButtons) do
    button.Activated:Connect(function()
        submitChoice(latestChoices[index])
    end)
end

primaryButton.Activated:Connect(function()
    if primaryMode == "done" then
        overlay.Visible = false
    else
        startShift()
    end
end)

leaveButton.Activated:Connect(leaveShift)

closeButton.Activated:Connect(function()
    overlay.Visible = false
end)

openPanelRemote.OnClientEvent:Connect(function()
    overlay.Visible = true
    resultCard.Visible = false
    feedbackLabel.Visible = true
    setFeedback("Opening the stock desk...", true)
    refreshState()
end)
