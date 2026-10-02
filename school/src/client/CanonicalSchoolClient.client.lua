local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local root = ReplicatedStorage:WaitForChild("SchoolFoundation")
local stateSnapshot = root:WaitForChild("StateSnapshot")
local requestTravel = root:WaitForChild("RequestTravel")
local classRoot = root:WaitForChild("ClassEducation")
local getClassState = classRoot:WaitForChild("GetClassState")
local getProgressionState = classRoot:WaitForChild("GetProgressionState")
local enterClass = classRoot:WaitForChild("EnterClass")
local submitAnswer = classRoot:WaitForChild("SubmitAnswer")
local leaveClass = classRoot:WaitForChild("LeaveClass")

local gui = Instance.new("ScreenGui")
gui.Name = "PipHighCanonicalUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local palette = {
    navy = Color3.fromRGB(34, 73, 117),
    navyDark = Color3.fromRGB(24, 51, 84),
    navySoft = Color3.fromRGB(71, 116, 164),
    sky = Color3.fromRGB(224, 239, 250),
    skyHover = Color3.fromRGB(208, 230, 247),
    surface = Color3.fromRGB(248, 251, 254),
    surfaceWarm = Color3.fromRGB(255, 250, 244),
    text = Color3.fromRGB(31, 46, 65),
    muted = Color3.fromRGB(88, 105, 124),
    border = Color3.fromRGB(155, 179, 205),
    cafe = Color3.fromRGB(124, 83, 54),
    cafeHover = Color3.fromRGB(143, 96, 63),
    cafeBorder = Color3.fromRGB(193, 163, 137),
    option = Color3.fromRGB(235, 244, 252),
    optionHover = Color3.fromRGB(220, 236, 249),
}

local function round(target, px)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, px)
    corner.Parent = target
end

local function addStroke(target, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.Parent = target
    return stroke
end

local function addGradient(target, topColor, bottomColor)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, topColor),
        ColorSequenceKeypoint.new(1, bottomColor),
    })
    gradient.Rotation = 90
    gradient.Parent = target
    return gradient
end

local function polishButton(button, baseColor, hoverColor)
    button.AutoButtonColor = false
    button.BackgroundColor3 = baseColor

    if not UserInputService.TouchEnabled then
        button.MouseEnter:Connect(function()
            TweenService:Create(
                button,
                TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { BackgroundColor3 = hoverColor }
            ):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(
                button,
                TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { BackgroundColor3 = baseColor }
            ):Play()
        end)
    end
end

local scheduleBottomMargin = UserInputService.TouchEnabled and 122 or 18

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0, 1)
card.Position = UDim2.new(0, 16, 1, -scheduleBottomMargin)
card.Size = UDim2.new(0, 280, 0, 190)
card.BackgroundColor3 = palette.surface
card.BackgroundTransparency = 0.02
card.Parent = gui
round(card, 14)
addStroke(card, palette.border, 1, 0.08)
addGradient(card, Color3.fromRGB(255, 255, 255), Color3.fromRGB(237, 246, 253))

local cardHeader = Instance.new("Frame")
cardHeader.Position = UDim2.new(0, 0, 0, 0)
cardHeader.Size = UDim2.new(1, 0, 0, 38)
cardHeader.BackgroundColor3 = palette.navy
cardHeader.Parent = card
round(cardHeader, 14)
addGradient(cardHeader, palette.navySoft, palette.navyDark)

local headerMask = Instance.new("Frame")
headerMask.BorderSizePixel = 0
headerMask.Position = UDim2.new(0, 0, 1, -14)
headerMask.Size = UDim2.new(1, 0, 0, 14)
headerMask.BackgroundColor3 = palette.navyDark
headerMask.Parent = cardHeader

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 0)
title.Size = UDim2.new(1, -104, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "PIP HIGH"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = cardHeader

local pointsBadge = Instance.new("Frame")
pointsBadge.AnchorPoint = Vector2.new(1, 0.5)
pointsBadge.Position = UDim2.new(1, -10, 0.5, 0)
pointsBadge.Size = UDim2.new(0, 82, 0, 24)
pointsBadge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
pointsBadge.BackgroundTransparency = 0.12
pointsBadge.Parent = cardHeader
round(pointsBadge, 12)
addStroke(pointsBadge, Color3.fromRGB(255, 255, 255), 1, 0.68)

local pointsLabel = Instance.new("TextLabel")
pointsLabel.BackgroundTransparency = 1
pointsLabel.Size = UDim2.fromScale(1, 1)
pointsLabel.Font = Enum.Font.GothamBold
pointsLabel.Text = "0 PTS"
pointsLabel.TextColor3 = Color3.new(1, 1, 1)
pointsLabel.TextSize = 12
pointsLabel.TextXAlignment = Enum.TextXAlignment.Center
pointsLabel.Parent = pointsBadge

local periodCaption = Instance.new("TextLabel")
periodCaption.BackgroundTransparency = 1
periodCaption.Position = UDim2.new(0, 14, 0, 48)
periodCaption.Size = UDim2.new(1, -28, 0, 14)
periodCaption.Font = Enum.Font.GothamBold
periodCaption.Text = "CURRENT PERIOD"
periodCaption.TextColor3 = palette.navySoft
periodCaption.TextSize = 10
periodCaption.TextXAlignment = Enum.TextXAlignment.Left
periodCaption.Parent = card

local periodLabel = Instance.new("TextLabel")
periodLabel.BackgroundTransparency = 1
periodLabel.Position = UDim2.new(0, 14, 0, 62)
periodLabel.Size = UDim2.new(1, -28, 0, 34)
periodLabel.Font = Enum.Font.GothamBold
periodLabel.Text = "Loading school day..."
periodLabel.TextColor3 = palette.text
periodLabel.TextSize = 18
periodLabel.TextWrapped = true
periodLabel.TextXAlignment = Enum.TextXAlignment.Left
periodLabel.Parent = card

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 14, 0, 98)
statusLabel.Size = UDim2.new(1, -28, 0, 34)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Connecting..."
statusLabel.TextColor3 = palette.muted
statusLabel.TextSize = 12
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = card

local action = Instance.new("TextButton")
action.Position = UDim2.new(0, 14, 1, -54)
action.Size = UDim2.new(1, -28, 0, 44)
action.Font = Enum.Font.GothamBold
action.Text = "CHECKING CLASS..."
action.TextColor3 = Color3.new(1, 1, 1)
action.TextSize = 13
action.Parent = card
round(action, 10)
addStroke(action, palette.navyDark, 1, 0.18)
polishButton(action, palette.navy, palette.navySoft)

local modalBackdrop = Instance.new("Frame")
modalBackdrop.Position = UDim2.fromScale(0, 0)
modalBackdrop.Size = UDim2.fromScale(1, 1)
modalBackdrop.BackgroundColor3 = Color3.fromRGB(10, 17, 26)
modalBackdrop.BackgroundTransparency = 0.42
modalBackdrop.Visible = false
modalBackdrop.Parent = gui

local modal = Instance.new("Frame")
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.52)
modal.Size = UDim2.new(0.9, 0, 0, 430)
modal.BackgroundColor3 = palette.surface
modal.Visible = false
modal.Parent = gui
round(modal, 16)
addStroke(modal, palette.border, 1, 0.05)
addGradient(modal, Color3.fromRGB(255, 255, 255), Color3.fromRGB(239, 247, 253))

local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(300, 390)
constraint.MaxSize = Vector2.new(520, 450)
constraint.Parent = modal

local modalHeader = Instance.new("Frame")
modalHeader.Position = UDim2.new(0, 0, 0, 0)
modalHeader.Size = UDim2.new(1, 0, 0, 52)
modalHeader.BackgroundColor3 = palette.navy
modalHeader.Parent = modal
round(modalHeader, 16)
addGradient(modalHeader, palette.navySoft, palette.navyDark)

local modalHeaderMask = Instance.new("Frame")
modalHeaderMask.BorderSizePixel = 0
modalHeaderMask.Position = UDim2.new(0, 0, 1, -16)
modalHeaderMask.Size = UDim2.new(1, 0, 0, 16)
modalHeaderMask.BackgroundColor3 = palette.navyDark
modalHeaderMask.Parent = modalHeader

local modalTitle = Instance.new("TextLabel")
modalTitle.BackgroundTransparency = 1
modalTitle.Position = UDim2.new(0, 18, 0, 0)
modalTitle.Size = UDim2.new(1, -36, 1, 0)
modalTitle.Font = Enum.Font.GothamBold
modalTitle.Text = "CLASS ACTIVITY"
modalTitle.TextColor3 = Color3.new(1, 1, 1)
modalTitle.TextSize = 15
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.Parent = modalHeader

local question = Instance.new("TextLabel")
question.BackgroundTransparency = 1
question.Position = UDim2.new(0, 18, 0, 66)
question.Size = UDim2.new(1, -36, 0, 86)
question.Font = Enum.Font.GothamBold
question.Text = ""
question.TextColor3 = palette.text
question.TextSize = 18
question.TextWrapped = true
question.TextYAlignment = Enum.TextYAlignment.Top
question.TextXAlignment = Enum.TextXAlignment.Left
question.Parent = modal

local choices = Instance.new("Frame")
choices.BackgroundTransparency = 1
choices.Position = UDim2.new(0, 18, 0, 158)
choices.Size = UDim2.new(1, -36, 0, 208)
choices.Parent = modal

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = choices

local feedback = Instance.new("TextLabel")
feedback.BackgroundTransparency = 1
feedback.Position = UDim2.new(0, 18, 1, -54)
feedback.Size = UDim2.new(1, -36, 0, 40)
feedback.Font = Enum.Font.GothamMedium
feedback.Text = ""
feedback.TextColor3 = palette.muted
feedback.TextSize = 12
feedback.TextWrapped = true
feedback.TextXAlignment = Enum.TextXAlignment.Left
feedback.TextYAlignment = Enum.TextYAlignment.Center
feedback.Parent = modal

local function setModalVisible(visible)
    modalBackdrop.Visible = visible
    modal.Visible = visible
end

local latestClassState = nil
local activeClassKey = nil
local activeActivity = nil
local busy = false
local points = 0
local pendingProgression = nil

local function setPoints(value)
    if type(value) ~= "number" then return end
    points = value
    pointsLabel.Text = tostring(points) .. " PTS"
end

local function refreshProgression()
    local ok, response = pcall(function()
        return getProgressionState:InvokeServer()
    end)
    if ok and type(response) == "table"
        and response.available == true
        and type(response.state) == "table" then
        setPoints(response.state.totalPoints)
    end
end

task.spawn(refreshProgression)

local function clearChoices()
    for _, child in ipairs(choices:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function showActivity(response)
    activeClassKey = response.classKey or (latestClassState and latestClassState.classKey)
    activeActivity = response.activity
    pendingProgression = nil
    if not activeActivity then return end

    modalTitle.Text = string.upper(tostring(activeActivity.subject or "Class")) .. " ACTIVITY"\n    question.Text = tostring(activeActivity.prompt)
    feedback.Text = ""
    clearChoices()

    for index, choiceText in ipairs(activeActivity.choices or {}) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 45)
        button.Font = Enum.Font.GothamMedium
        button.Text = tostring(index) .. ".  " .. tostring(choiceText)
        button.TextColor3 = palette.text
        button.TextSize = 14
        button.TextWrapped = true
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = choices
        round(button, 10)
        addStroke(button, palette.border, 1, 0.18)
        polishButton(button, palette.option, palette.optionHover)

        local choicePadding = Instance.new("UIPadding")
        choicePadding.PaddingLeft = UDim.new(0, 14)
        choicePadding.PaddingRight = UDim.new(0, 12)
        choicePadding.Parent = button

        button.Activated:Connect(function()
            if busy or not activeActivity or not activeClassKey then return end

            local submissionId
            if pendingProgression then
                if pendingProgression.classKey ~= activeClassKey
                    or pendingProgression.activityId ~= activeActivity.id
                    or pendingProgression.choiceIndex ~= index then
                    feedback.Text = "Retry the same answer to finish saving progress."
                    return
                end
                submissionId = pendingProgression.submissionId
            else
                submissionId = HttpService:GenerateGUID(false)
            end

            busy = true
            local ok, result = pcall(function()
                return submitAnswer:InvokeServer(activeClassKey, activeActivity.id, submissionId, index)
            end)
            busy = false

            if not ok or type(result) ~= "table" then
                feedback.Text = "Could not submit that answer. Try again."
                return
            end

            if result.code == "progression_commit_failed" then
                pendingProgression = {
                    classKey = activeClassKey,
                    activityId = activeActivity.id,
                    choiceIndex = index,
                    submissionId = submissionId,
                }
                feedback.Text = "Progress save failed. Tap this same answer again to retry safely."
                return
            end

            pendingProgression = nil
            if result.progressionState and result.progressionState.totalPoints then
                setPoints(result.progressionState.totalPoints)
            end

            if result.classCompleted or result.completionAlreadyRecorded or result.progressionCommitted then
                feedback.Text = "Class complete! Progress saved. Points: " .. tostring(points)
                activeActivity = nil
                task.delay(1.4, function()
                    setModalVisible(false)
                end)
            elseif result.completed then
                feedback.Text = tostring(result.explanation or result.feedback or "Activity complete.")
                activeActivity = nil
                task.delay(1.6, function()
                    setModalVisible(false)
                end)
            elseif result.accepted == false then
                feedback.Text = tostring(result.message or result.code or "That action was not accepted.")
            else
                feedback.Text = tostring(result.feedback or result.hint or "Try again.")
            end
        end)
    end

    setModalVisible(true)
end

action.Activated:Connect(function()
    if busy or not latestClassState then return end

    if latestClassState.active then
        local ok, result = pcall(function()
            return leaveClass:InvokeServer()
        end)
        if ok and result and result.returnToFreeRoam then
            statusLabel.Text = "Back in free roam."
        end
        return
    end

    if latestClassState.canEnter ~= true then
        if latestClassState.academic then
            busy = true
            local ok, response = pcall(function()
                return requestTravel:InvokeServer()
            end)
            busy = false

            if ok and type(response) == "table" and response.accepted then
                statusLabel.Text = "Heading to " .. tostring(latestClassState.roomDisplayName or "class") .. "..."
            else
                statusLabel.Text = "Could not travel to class."
            end
        end
        return
    end

    busy = true
    local ok, response = pcall(function()
        return enterClass:InvokeServer()
    end)
    busy = false
    if not ok or type(response) ~= "table" then
        statusLabel.Text = "Class service unavailable."
        return
    end

    if response.accepted and response.activity then
        showActivity(response)
    else
        statusLabel.Text = tostring(response.code or "Class is not available yet.")
    end
end)

task.spawn(function()
    while gui.Parent do
        local okState, state = pcall(function()
            return stateSnapshot:InvokeServer()
        end)
        local okClass, classState = pcall(function()
            return getClassState:InvokeServer()
        end)

        if okState and type(state) == "table" then
            local mins = math.floor((state.secondsRemaining or 0) / 60)
            local secs = (state.secondsRemaining or 0) % 60
            periodLabel.Text = string.format(
                "%s  %d:%02d",
                tostring(state.periodLabel),
                mins,
                secs
            )
        end

        if okClass and type(classState) == "table" then
            latestClassState = classState

            if classState.progressionPending then
                statusLabel.Text = "Saving class progress..."
                action.Text = "SAVING..."
                action.Active = false
            elseif classState.completedCurrentClass then
                statusLabel.Text = "Class complete • Free roam until the next bell."
                action.Text = "CLASS COMPLETE"
                action.Active = false
            elseif classState.active then
                statusLabel.Text = "Class active • " .. tostring(classState.roomDisplayName or "Classroom")
                action.Text = "LEAVE CLASS"
                action.Active = true
            elseif classState.academic and classState.canEnter then
                statusLabel.Text = "You are at " .. tostring(classState.roomDisplayName)
                action.Text = "START CLASS"
                action.Active = true
            elseif classState.academic then
                statusLabel.Text = "Go to " .. tostring(classState.roomDisplayName) .. " to attend."
                action.Text = "GO TO " .. string.upper(tostring(classState.roomDisplayName))
                action.Active = true
            else
                statusLabel.Text = "Free-roam period • Points: " .. tostring(points)
                action.Text = "FREE ROAM"
                action.Active = false
            end
        else
            statusLabel.Text = "Waiting for school services..."
            action.Active = false
        end

        task.wait(0.75)
    end
end)


-- Assigned Free-Roam slice: original Corner Cafe job UX.
-- This remains presentation-only; the server owns proximity, task state, and wage authority.

local cafeJobRoot = root:WaitForChild("FreeRoam"):WaitForChild("CafeJob")
local getCafeJobState = cafeJobRoot:WaitForChild("GetState")
local startCafeShift = cafeJobRoot:WaitForChild("StartShift")
local completeCafeTask = cafeJobRoot:WaitForChild("CompleteTask")
local leaveCafeShift = cafeJobRoot:WaitForChild("LeaveShift")

local cafeBottomMargin = UserInputService.TouchEnabled and 116 or 18

local cafeCard = Instance.new("Frame")
cafeCard.AnchorPoint = Vector2.new(1, 1)
cafeCard.Position = UDim2.new(1, -16, 1, -cafeBottomMargin)
cafeCard.Size = UDim2.new(0, 312, 0, 178)
cafeCard.BackgroundColor3 = palette.surfaceWarm
cafeCard.BackgroundTransparency = 0.02
cafeCard.Visible = false
cafeCard.Parent = gui
round(cafeCard, 14)
addStroke(cafeCard, palette.cafeBorder, 1, 0.08)
addGradient(cafeCard, Color3.fromRGB(255, 253, 249), Color3.fromRGB(250, 241, 230))

local cafeSizeConstraint = Instance.new("UISizeConstraint")
cafeSizeConstraint.MinSize = Vector2.new(276, 168)
cafeSizeConstraint.MaxSize = Vector2.new(340, 190)
cafeSizeConstraint.Parent = cafeCard

local cafeHeader = Instance.new("Frame")
cafeHeader.Position = UDim2.new(0, 0, 0, 0)
cafeHeader.Size = UDim2.new(1, 0, 0, 38)
cafeHeader.BackgroundColor3 = palette.cafe
cafeHeader.Parent = cafeCard
round(cafeHeader, 14)
addGradient(cafeHeader, palette.cafeHover, palette.cafe)

local cafeHeaderMask = Instance.new("Frame")
cafeHeaderMask.BorderSizePixel = 0
cafeHeaderMask.Position = UDim2.new(0, 0, 1, -14)
cafeHeaderMask.Size = UDim2.new(1, 0, 0, 14)
cafeHeaderMask.BackgroundColor3 = palette.cafe
cafeHeaderMask.Parent = cafeHeader

local cafeTitle = Instance.new("TextLabel")
cafeTitle.BackgroundTransparency = 1
cafeTitle.Position = UDim2.new(0, 14, 0, 0)
cafeTitle.Size = UDim2.new(1, -110, 1, 0)
cafeTitle.Font = Enum.Font.GothamBold
cafeTitle.Text = "CORNER CAFE"
cafeTitle.TextColor3 = Color3.new(1, 1, 1)
cafeTitle.TextSize = 15
cafeTitle.TextXAlignment = Enum.TextXAlignment.Left
cafeTitle.Parent = cafeHeader

local cafeStatus = Instance.new("TextLabel")
cafeStatus.BackgroundTransparency = 1
cafeStatus.Position = UDim2.new(0, 14, 0, 50)
cafeStatus.Size = UDim2.new(1, -28, 0, 54)
cafeStatus.Font = Enum.Font.Gotham
cafeStatus.Text = "Start a short cafe shift and serve one order."
cafeStatus.TextColor3 = Color3.fromRGB(92, 78, 65)
cafeStatus.TextSize = 12
cafeStatus.TextWrapped = true
cafeStatus.TextXAlignment = Enum.TextXAlignment.Left
cafeStatus.TextYAlignment = Enum.TextYAlignment.Top
cafeStatus.Parent = cafeCard

local cafeAction = Instance.new("TextButton")
cafeAction.Position = UDim2.new(0, 14, 1, -58)
cafeAction.Size = UDim2.new(1, -28, 0, 44)
cafeAction.Font = Enum.Font.GothamBold
cafeAction.Text = "START SHIFT"
cafeAction.TextColor3 = Color3.new(1, 1, 1)
cafeAction.TextSize = 13
cafeAction.Parent = cafeCard
round(cafeAction, 10)
addStroke(cafeAction, palette.cafe, 1, 0.15)
polishButton(cafeAction, palette.cafe, palette.cafeHover)

local cafeLeave = Instance.new("TextButton")
cafeLeave.AnchorPoint = Vector2.new(1, 0.5)
cafeLeave.Position = UDim2.new(1, -10, 0.5, 0)
cafeLeave.Size = UDim2.new(0, 86, 0, 26)
cafeLeave.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
cafeLeave.BackgroundTransparency = 0.86
cafeLeave.Font = Enum.Font.GothamBold
cafeLeave.Text = "LEAVE JOB"
cafeLeave.TextColor3 = Color3.new(1, 1, 1)
cafeLeave.TextSize = 10
cafeLeave.Visible = false
cafeLeave.Parent = cafeHeader
round(cafeLeave, 8)
addStroke(cafeLeave, Color3.fromRGB(255, 255, 255), 1, 0.6)

local latestCafeJob = nil
local cafeBusy = false
local cafeMessageUntil = 0

local function setCafeMessage(text)
    cafeStatus.Text = text
    cafeMessageUntil = os.clock() + 2.8
end

local function applyCafeState(state)
    if type(state) ~= "table" then
        return
    end

    latestCafeJob = state
    local active = state.active == true
    local atCafe = state.atCafe == true
    cafeCard.Visible = active or atCafe
    cafeLeave.Visible = active

    if active then
        cafeAction.Text = "SERVE ORDER  •  +$" .. tostring(state.wage or 25)
        if os.clock() >= cafeMessageUntil then
            cafeStatus.Text = "Shift active. Serve the waiting order to finish this cafe shift."
        end
    else
        cafeAction.Text = "START SHIFT  •  +$" .. tostring(state.wage or 25)
        if os.clock() >= cafeMessageUntil then
            cafeStatus.Text = "Start a short cafe shift and serve one order."
        end
    end
end

local function refreshCafeJob()
    local ok, response = pcall(function()
        return getCafeJobState:InvokeServer()
    end)
    if ok and type(response) == "table" then
        applyCafeState(response)
    elseif latestCafeJob ~= nil and latestCafeJob.active == true then
        cafeCard.Visible = true
        cafeStatus.Text = "Cafe job service is unavailable."
    end
end

cafeAction.Activated:Connect(function()
    if cafeBusy then
        return
    end

    cafeBusy = true
    cafeAction.AutoButtonColor = false
    cafeAction.Text = "WORKING..."

    local ok, response
    if latestCafeJob and latestCafeJob.active == true then
        ok, response = pcall(function()
            return completeCafeTask:InvokeServer(
                latestCafeJob.shiftId,
                latestCafeJob.taskId
            )
        end)
    else
        ok, response = pcall(function()
            return startCafeShift:InvokeServer()
        end)
    end

    cafeBusy = false
    cafeAction.AutoButtonColor = true

    if not ok or type(response) ~= "table" then
        setCafeMessage("Could not update the cafe job. Try again.")
        refreshCafeJob()
        return
    end

    if response.accepted ~= true then
        if response.code == "not_at_cafe" then
            setCafeMessage("Move closer to the cafe counter first.")
        elseif response.code == "economy_unavailable"
            or response.code == "wage_commit_failed" then
            setCafeMessage("Your wage could not be saved yet. Try the same task again.")
        else
            setCafeMessage("That cafe action is not available right now.")
        end
        refreshCafeJob()
        return
    end

    if response.returnToFreeRoam == true then
        local balance = response.economyState and response.economyState.balance
        local balanceText = type(balance) == "number"
            and ("  •  Balance $" .. tostring(balance))
            or ""
        setCafeMessage(
            "Shift complete! +$" .. tostring(response.wage or 25) .. balanceText
        )
    elseif response.code == "shift_started"
        or response.code == "shift_already_active" then
        setCafeMessage("Shift started. Serve the waiting order.")
    end

    refreshCafeJob()
end)

cafeLeave.Activated:Connect(function()
    if cafeBusy then
        return
    end

    cafeBusy = true
    local ok, response = pcall(function()
        return leaveCafeShift:InvokeServer()
    end)
    cafeBusy = false

    if ok and type(response) == "table" and response.accepted == true then
        setCafeMessage("Shift ended. Back to free roam.")
    else
        setCafeMessage("Could not leave the shift yet.")
    end
    refreshCafeJob()
end)

task.spawn(function()
    while gui.Parent do
        refreshCafeJob()
        task.wait(0.75)
    end
end)
