--!strict
-- Movement-safe HUD for the server-authoritative P.E. dodgeball drill.
-- It displays public timer/hit state and provides only a safe leave action.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remoteRoot = ReplicatedStorage:WaitForChild("SchoolFoundation")
local drillRoot = remoteRoot:WaitForChild("FreeRoam"):WaitForChild("PEDodgeballDrill")
local getStateRemote = drillRoot:WaitForChild("GetState")
local leaveRemote = drillRoot:WaitForChild("Leave")
local sessionStartedRemote = drillRoot:WaitForChild("SessionStarted")
local stateUpdatedRemote = drillRoot:WaitForChild("StateUpdated")
local sessionEndedRemote = drillRoot:WaitForChild("SessionEnded")

local COLORS = {
    navy = Color3.fromRGB(34, 62, 103),
    blue = Color3.fromRGB(61, 112, 171),
    paleBlue = Color3.fromRGB(221, 235, 249),
    coral = Color3.fromRGB(238, 102, 89),
    gold = Color3.fromRGB(243, 184, 66),
    ink = Color3.fromRGB(35, 47, 61),
    muted = Color3.fromRGB(91, 103, 116),
    white = Color3.fromRGB(255, 255, 255),
    card = Color3.fromRGB(249, 250, 247),
    line = Color3.fromRGB(199, 210, 219),
    overlay = Color3.fromRGB(15, 24, 36),
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
    button.TextSize = 14
    addCorner(button, 9)
end

local gui = Instance.new("ScreenGui")
gui.Name = "PEDodgeballDrillGui"
gui.DisplayOrder = 45
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local activePanel = Instance.new("Frame")
activePanel.Name = "ActiveDrillHud"
activePanel.AnchorPoint = Vector2.new(0.5, 0)
activePanel.BackgroundColor3 = COLORS.card
activePanel.BorderSizePixel = 0
activePanel.Position = UDim2.new(0.5, 0, 0, 14)
activePanel.Size = UDim2.new(0.92, 0, 0, 142)
activePanel.Visible = false
activePanel.Parent = gui
addCorner(activePanel, 16)
addStroke(activePanel, COLORS.navy, 2, 0.2)

local activeConstraint = Instance.new("UISizeConstraint")
activeConstraint.MinSize = Vector2.new(280, 142)
activeConstraint.MaxSize = Vector2.new(520, 142)
activeConstraint.Parent = activePanel

local activeHeader = Instance.new("Frame")
activeHeader.BackgroundColor3 = COLORS.blue
activeHeader.BorderSizePixel = 0
activeHeader.Size = UDim2.new(1, 0, 0, 42)
activeHeader.Parent = activePanel
addCorner(activeHeader, 16)

local activeHeaderMask = Instance.new("Frame")
activeHeaderMask.BackgroundColor3 = COLORS.blue
activeHeaderMask.BorderSizePixel = 0
activeHeaderMask.Position = UDim2.new(0, 0, 1, -16)
activeHeaderMask.Size = UDim2.new(1, 0, 0, 16)
activeHeaderMask.Parent = activeHeader

local activeTitle = Instance.new("TextLabel")
activeTitle.BackgroundTransparency = 1
activeTitle.Position = UDim2.fromOffset(14, 0)
activeTitle.Size = UDim2.new(1, -130, 1, 0)
activeTitle.Font = Enum.Font.GothamBold
activeTitle.Text = "P.E. DODGEBALL"
activeTitle.TextColor3 = COLORS.white
activeTitle.TextSize = 17
activeTitle.TextXAlignment = Enum.TextXAlignment.Left
activeTitle.Parent = activeHeader

local timerLabel = Instance.new("TextLabel")
timerLabel.AnchorPoint = Vector2.new(1, 0.5)
timerLabel.BackgroundColor3 = COLORS.navy
timerLabel.BorderSizePixel = 0
timerLabel.Position = UDim2.new(1, -10, 0.5, 0)
timerLabel.Size = UDim2.fromOffset(98, 30)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Text = "15.0s"
timerLabel.TextColor3 = COLORS.white
timerLabel.TextSize = 18
timerLabel.Parent = activeHeader
addCorner(timerLabel, 8)

local instructionLabel = Instance.new("TextLabel")
instructionLabel.BackgroundTransparency = 1
instructionLabel.Position = UDim2.fromOffset(14, 49)
instructionLabel.Size = UDim2.new(1, -126, 0, 28)
instructionLabel.Font = Enum.Font.GothamBold
instructionLabel.Text = "MOVE NORMALLY - DODGE THE FOAM BALLS!"
instructionLabel.TextColor3 = COLORS.ink
instructionLabel.TextSize = 13
instructionLabel.TextWrapped = true
instructionLabel.TextXAlignment = Enum.TextXAlignment.Left
instructionLabel.Parent = activePanel

local statsLabel = Instance.new("TextLabel")
statsLabel.BackgroundTransparency = 1
statsLabel.Position = UDim2.fromOffset(14, 78)
statsLabel.Size = UDim2.new(1, -126, 0, 22)
statsLabel.Font = Enum.Font.Gotham
statsLabel.Text = "Hits: 0   |   Balls: 0 / 11"
statsLabel.TextColor3 = COLORS.muted
statsLabel.TextSize = 13
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.Parent = activePanel

local progressTrack = Instance.new("Frame")
progressTrack.BackgroundColor3 = COLORS.paleBlue
progressTrack.BorderSizePixel = 0
progressTrack.Position = UDim2.fromOffset(14, 111)
progressTrack.Size = UDim2.new(1, -126, 0, 12)
progressTrack.Parent = activePanel
addCorner(progressTrack, 6)

local progressFill = Instance.new("Frame")
progressFill.BackgroundColor3 = COLORS.gold
progressFill.BorderSizePixel = 0
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.Parent = progressTrack
addCorner(progressFill, 6)

local leaveButton = Instance.new("TextButton")
leaveButton.Name = "LeaveDrill"
leaveButton.AnchorPoint = Vector2.new(1, 1)
leaveButton.Position = UDim2.new(1, -12, 1, -13)
leaveButton.Size = UDim2.fromOffset(100, 40)
leaveButton.Text = "LEAVE"
leaveButton.Parent = activePanel
styleButton(leaveButton, COLORS.coral, COLORS.white)

local resultOverlay = Instance.new("Frame")
resultOverlay.Name = "ResultOverlay"
resultOverlay.BackgroundColor3 = COLORS.overlay
resultOverlay.BackgroundTransparency = 0.28
resultOverlay.BorderSizePixel = 0
resultOverlay.Size = UDim2.fromScale(1, 1)
resultOverlay.Visible = false
resultOverlay.Parent = gui

local resultCard = Instance.new("Frame")
resultCard.Name = "DodgeballResultCard"
resultCard.AnchorPoint = Vector2.new(0.5, 0.5)
resultCard.BackgroundColor3 = COLORS.card
resultCard.BorderSizePixel = 0
resultCard.Position = UDim2.fromScale(0.5, 0.5)
resultCard.Size = UDim2.new(0.9, 0, 0.7, 0)
resultCard.Parent = resultOverlay
addCorner(resultCard, 18)
addStroke(resultCard, COLORS.navy, 2, 0.25)

local resultConstraint = Instance.new("UISizeConstraint")
resultConstraint.MinSize = Vector2.new(280, 290)
resultConstraint.MaxSize = Vector2.new(500, 410)
resultConstraint.Parent = resultCard

local resultHeader = Instance.new("TextLabel")
resultHeader.BackgroundColor3 = COLORS.blue
resultHeader.BorderSizePixel = 0
resultHeader.Size = UDim2.new(1, 0, 0, 56)
resultHeader.Font = Enum.Font.GothamBold
resultHeader.Text = "DRILL COMPLETE!"
resultHeader.TextColor3 = COLORS.white
resultHeader.TextSize = 21
resultHeader.Parent = resultCard
addCorner(resultHeader, 18)

local resultHeaderMask = Instance.new("Frame")
resultHeaderMask.BackgroundColor3 = COLORS.blue
resultHeaderMask.BorderSizePixel = 0
resultHeaderMask.Position = UDim2.new(0, 0, 1, -18)
resultHeaderMask.Size = UDim2.new(1, 0, 0, 18)
resultHeaderMask.Parent = resultHeader

local gradeBadge = Instance.new("TextLabel")
gradeBadge.AnchorPoint = Vector2.new(0.5, 0)
gradeBadge.BackgroundColor3 = COLORS.gold
gradeBadge.BorderSizePixel = 0
gradeBadge.Position = UDim2.new(0.5, 0, 0, 66)
gradeBadge.Size = UDim2.fromOffset(100, 64)
gradeBadge.Font = Enum.Font.GothamBold
gradeBadge.Text = "A+"
gradeBadge.TextColor3 = COLORS.navy
gradeBadge.TextSize = 38
gradeBadge.Parent = resultCard
addCorner(gradeBadge, 18)

local resultStats = Instance.new("TextLabel")
resultStats.BackgroundTransparency = 1
resultStats.Position = UDim2.new(0, 18, 0, 140)
resultStats.Size = UDim2.new(1, -36, 0, 24)
resultStats.Font = Enum.Font.GothamBold
resultStats.Text = "10 dodged  |  1 foam hit"
resultStats.TextColor3 = COLORS.ink
resultStats.TextSize = 16
resultStats.Parent = resultCard

local resultMessage = Instance.new("TextLabel")
resultMessage.BackgroundTransparency = 1
resultMessage.Position = UDim2.new(0, 24, 0, 172)
resultMessage.Size = UDim2.new(1, -48, 1, -238)
resultMessage.Font = Enum.Font.Gotham
resultMessage.Text = "Great movement! One tap could not slow you down."
resultMessage.TextColor3 = COLORS.muted
resultMessage.TextSize = 14
resultMessage.TextWrapped = true
resultMessage.TextYAlignment = Enum.TextYAlignment.Top
resultMessage.Parent = resultCard

local doneButton = Instance.new("TextButton")
doneButton.Name = "Done"
doneButton.AnchorPoint = Vector2.new(0.5, 1)
doneButton.Position = UDim2.new(0.5, 0, 1, -16)
doneButton.Size = UDim2.new(1, -36, 0, 44)
doneButton.Text = "DONE"
doneButton.Parent = resultCard
styleButton(doneButton, COLORS.gold, COLORS.navy)

local busy = false
local lastHits = 0

local function renderActiveState(state)
    if type(state) ~= "table" or state.active ~= true then
        activePanel.Visible = false
        return
    end
    resultOverlay.Visible = false
    activePanel.Visible = true

    local remaining = math.max(0, tonumber(state.remainingSeconds) or 0)
    local duration = math.max(0.01, tonumber(state.duration) or 15)
    local hits = math.max(0, math.floor(tonumber(state.hits) or 0))
    local thrown = math.max(0, math.floor(tonumber(state.ballsThrown) or 0))
    local total = math.max(1, math.floor(tonumber(state.totalBalls) or 1))
    timerLabel.Text = string.format("%.1fs", remaining)
    statsLabel.Text = string.format("Hits: %d   |   Balls: %d / %d", hits, thrown, total)
    progressFill.Size = UDim2.fromScale(
        math.clamp(1 - remaining / duration, 0, 1),
        1
    )
    if hits > lastHits then
        instructionLabel.Text = "FOAM TAP - KEEP MOVING, YOU'VE GOT THIS!"
        instructionLabel.TextColor3 = COLORS.coral
    else
        instructionLabel.Text = "MOVE NORMALLY - DODGE THE FOAM BALLS!"
        instructionLabel.TextColor3 = COLORS.ink
    end
    lastHits = hits
end

local function renderResult(result)
    if type(result) ~= "table" then
        return
    end
    activePanel.Visible = false
    resultOverlay.Visible = true
    local completed = result.completed == true
    resultHeader.Text = tostring(
        result.title or (completed and "Drill complete!" or "Drill ended safely")
    ):upper()
    gradeBadge.Text = completed and tostring(result.grade or "C") or "SAFE"
    gradeBadge.BackgroundColor3 = completed and COLORS.gold or COLORS.paleBlue

    local hits = math.max(0, math.floor(tonumber(result.hits) or 0))
    local dodged = math.max(0, math.floor(tonumber(result.dodged) or 0))
    if completed then
        resultStats.Text = string.format(
            "%d dodged  |  %d foam hit%s",
            dodged,
            hits,
            hits == 1 and "" or "s"
        )
    else
        resultStats.Text = "No penalty - normal movement restored"
    end
    resultMessage.Text = tostring(
        result.message
            or "Return to the gym prompt whenever you want another try."
    )
    lastHits = 0
end

local function renderNotice(titleText, messageText)
    renderResult({
        completed = false,
        title = titleText,
        message = messageText,
        hits = 0,
        dodged = 0,
    })
end

leaveButton.Activated:Connect(function()
    if busy then
        return
    end
    busy = true
    leaveButton.Active = false
    leaveButton.Text = "LEAVING..."
    local ok, outcome = pcall(function()
        return leaveRemote:InvokeServer()
    end)
    busy = false
    leaveButton.Active = true
    leaveButton.Text = "LEAVE"
    if not ok or type(outcome) ~= "table" then
        instructionLabel.Text = "COULDN'T LEAVE YET - KEEP MOVING AND RETRY"
        instructionLabel.TextColor3 = COLORS.coral
        return
    end
    if type(outcome.result) == "table" then
        renderResult(outcome.result)
    else
        activePanel.Visible = false
    end
end)

doneButton.Activated:Connect(function()
    resultOverlay.Visible = false
end)

sessionStartedRemote.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end
    if type(payload.state) == "table" and payload.state.active == true then
        lastHits = tonumber(payload.state.hits) or 0
        renderActiveState(payload.state)
    elseif payload.code == "start_rate_limited" then
        renderNotice(
            "Ready in a moment",
            "The prior prompt tap is still clearing. Use it again right away."
        )
    elseif payload.code ~= "session_already_active" then
        renderNotice(
            "Drill unavailable",
            "Stand near the gym drill station and try again."
        )
    end
end)

stateUpdatedRemote.OnClientEvent:Connect(function(state)
    renderActiveState(state)
end)

sessionEndedRemote.OnClientEvent:Connect(function(payload)
    if type(payload) == "table" then
        renderResult(payload.result)
    end
end)

task.defer(function()
    local ok, state = pcall(function()
        return getStateRemote:InvokeServer()
    end)
    if ok and type(state) == "table" and state.active == true then
        lastHits = tonumber(state.hits) or 0
        renderActiveState(state)
    end
end)
