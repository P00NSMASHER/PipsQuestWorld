local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

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
gui.Parent = player:WaitForChild("PlayerGui")

local function round(target, px)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, px)
    corner.Parent = target
end

local card = Instance.new("Frame")
card.Position = UDim2.new(0, 12, 0, 12)
card.Size = UDim2.new(0, 312, 0, 162)
card.BackgroundColor3 = Color3.fromRGB(24, 29, 42)
card.BackgroundTransparency = 0.06
card.Parent = gui
round(card, 16)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 10)
title.Size = UDim2.new(1, -28, 0, 22)
title.Font = Enum.Font.GothamBold
title.Text = "PIP HIGH"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local pointsLabel = Instance.new("TextLabel")
pointsLabel.BackgroundTransparency = 1
pointsLabel.Position = UDim2.new(1, -100, 0, 10)
pointsLabel.Size = UDim2.new(0, 86, 0, 22)
pointsLabel.Font = Enum.Font.GothamMedium
pointsLabel.Text = "0 PTS"
pointsLabel.TextColor3 = Color3.fromRGB(190, 202, 225)
pointsLabel.TextSize = 13
pointsLabel.TextXAlignment = Enum.TextXAlignment.Right
pointsLabel.Parent = card

local periodLabel = Instance.new("TextLabel")
periodLabel.BackgroundTransparency = 1
periodLabel.Position = UDim2.new(0, 14, 0, 36)
periodLabel.Size = UDim2.new(1, -28, 0, 42)
periodLabel.Font = Enum.Font.GothamBold
periodLabel.Text = "Loading school day..."
periodLabel.TextColor3 = Color3.new(1, 1, 1)
periodLabel.TextSize = 19
periodLabel.TextWrapped = true
periodLabel.TextXAlignment = Enum.TextXAlignment.Left
periodLabel.Parent = card

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 14, 0, 78)
statusLabel.Size = UDim2.new(1, -28, 0, 26)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Connecting..."
statusLabel.TextColor3 = Color3.fromRGB(190, 202, 225)
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = card

local action = Instance.new("TextButton")
action.Position = UDim2.new(0, 14, 1, -48)
action.Size = UDim2.new(1, -28, 0, 38)
action.BackgroundColor3 = Color3.fromRGB(73, 122, 210)
action.Font = Enum.Font.GothamBold
action.Text = "CHECKING CLASS..."
action.TextColor3 = Color3.new(1, 1, 1)
action.TextSize = 13
action.Parent = card
round(action, 11)

local modal = Instance.new("Frame")
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.55)
modal.Size = UDim2.new(0.9, 0, 0, 390)
modal.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
modal.Visible = false
modal.Parent = gui
round(modal, 18)
local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(300, 360)
constraint.MaxSize = Vector2.new(540, 430)
constraint.Parent = modal

local question = Instance.new("TextLabel")
question.BackgroundTransparency = 1
question.Position = UDim2.new(0, 18, 0, 16)
question.Size = UDim2.new(1, -36, 0, 92)
question.Font = Enum.Font.GothamBold
question.Text = ""
question.TextColor3 = Color3.new(1, 1, 1)
question.TextSize = 19
question.TextWrapped = true
question.TextYAlignment = Enum.TextYAlignment.Top
question.Parent = modal

local choices = Instance.new("Frame")
choices.BackgroundTransparency = 1
choices.Position = UDim2.new(0, 18, 0, 112)
choices.Size = UDim2.new(1, -36, 0, 220)
choices.Parent = modal

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = choices

local feedback = Instance.new("TextLabel")
feedback.BackgroundTransparency = 1
feedback.Position = UDim2.new(0, 18, 1, -50)
feedback.Size = UDim2.new(1, -36, 0, 38)
feedback.Font = Enum.Font.GothamMedium
feedback.Text = ""
feedback.TextColor3 = Color3.fromRGB(215, 222, 237)
feedback.TextSize = 13
feedback.TextWrapped = true
feedback.Parent = modal

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

    question.Text = tostring(activeActivity.subject or "Class") .. "\n" .. tostring(activeActivity.prompt)
    feedback.Text = ""
    clearChoices()

    for index, choiceText in ipairs(activeActivity.choices or {}) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 48)
        button.BackgroundColor3 = Color3.fromRGB(48, 58, 79)
        button.Font = Enum.Font.GothamMedium
        button.Text = tostring(index) .. ".  " .. tostring(choiceText)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 15
        button.TextWrapped = true
        button.Parent = choices
        round(button, 10)

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
                    modal.Visible = false
                end)
            elseif result.completed then
                feedback.Text = tostring(result.explanation or result.feedback or "Activity complete.")
                activeActivity = nil
                task.delay(1.6, function()
                    modal.Visible = false
                end)
            elseif result.accepted == false then
                feedback.Text = tostring(result.message or result.code or "That action was not accepted.")
            else
                feedback.Text = tostring(result.feedback or result.hint or "Try again.")
            end
        end)
    end

    modal.Visible = true
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
