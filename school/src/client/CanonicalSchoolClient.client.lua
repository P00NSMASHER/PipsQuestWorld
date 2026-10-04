local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local SchoolConfig = require(shared:WaitForChild("SchoolConfig"))
local LegacyOutfitEntry = require(shared:WaitForChild("LegacyOutfitEntry"))
local LegacyShoppingBoundary = require(shared:WaitForChild("LegacyShoppingBoundary"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
LegacyOutfitEntry(player, UserInputService)
local shoppingBoundary = LegacyShoppingBoundary()
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
gui.Name = "RobloxHighSchoolLegacyUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = playerGui

local LEGACY_BLUE = Color3.fromRGB(48, 104, 148)
local LEGACY_BLUE_DARK = Color3.fromRGB(22, 73, 112)
local LEGACY_PANEL = Color3.fromRGB(193, 220, 238)
local LEGACY_BUTTON = Color3.fromRGB(235, 245, 250)
local bottomMargin = UserInputService.TouchEnabled and 112 or 12

local function round(target, px)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, px)
    corner.Parent = target
end

local function outline(target, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = LEGACY_BLUE
    stroke.Parent = target
    return stroke
end

-- Reference A recurring HUD: compact top-right school status beside a colored action rail.
local card = Instance.new("Frame")
card.Name = "CompactSchoolStatus"
card.AnchorPoint = Vector2.new(1, 0)
card.Position = UDim2.new(1, -76, 0, 12)
card.Size = UDim2.new(0, 226, 0, 122)
card.BackgroundColor3 = LEGACY_PANEL
card.BackgroundTransparency = 0.02
card.Parent = gui
round(card, 2)
outline(card, 2)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 0
title.BackgroundColor3 = LEGACY_BLUE
title.Position = UDim2.new(0, 0, 0, 0)
title.Size = UDim2.new(1, 0, 0, 24)
title.Font = Enum.Font.ArialBold
title.Text = "SCHOOL DAY"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = card

local pointsLabel = Instance.new("TextLabel")
pointsLabel.BackgroundTransparency = 1
pointsLabel.Position = UDim2.new(0, 10, 0, 82)
pointsLabel.Size = UDim2.new(0, 82, 0, 28)
pointsLabel.Font = Enum.Font.ArialBold
pointsLabel.Text = "Points: 0"
pointsLabel.TextColor3 = LEGACY_BLUE_DARK
pointsLabel.TextSize = 13
pointsLabel.TextXAlignment = Enum.TextXAlignment.Left
pointsLabel.Parent = card

local periodLabel = Instance.new("TextLabel")
periodLabel.BackgroundTransparency = 1
periodLabel.Position = UDim2.new(0, 9, 0, 29)
periodLabel.Size = UDim2.new(1, -18, 0, 32)
periodLabel.Font = Enum.Font.ArialBold
periodLabel.Text = "Loading school day..."
periodLabel.TextColor3 = LEGACY_BLUE_DARK
periodLabel.TextSize = 13
periodLabel.TextWrapped = true
periodLabel.TextXAlignment = Enum.TextXAlignment.Left
periodLabel.TextYAlignment = Enum.TextYAlignment.Top
periodLabel.Parent = card

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 9, 0, 61)
statusLabel.Size = UDim2.new(1, -18, 0, 22)
statusLabel.Font = Enum.Font.Arial
statusLabel.Text = "Connecting..."
statusLabel.TextColor3 = Color3.fromRGB(31, 72, 102)
statusLabel.TextSize = 11
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = card

local action = Instance.new("TextButton")
action.Position = UDim2.new(0, 96, 0, 87)
action.Size = UDim2.new(1, -104, 0, 27)
action.BackgroundColor3 = LEGACY_BUTTON
action.Font = Enum.Font.ArialBold
action.Text = "CHECKING CLASS..."
action.TextColor3 = LEGACY_BLUE_DARK
action.TextSize = 13
action.Parent = card
round(action, 2)
outline(action, 1)

local actionRail = Instance.new("Frame")
actionRail.Name = "RHS2ActionRail"
actionRail.AnchorPoint = Vector2.new(1, 0)
actionRail.Position = UDim2.new(1, -10, 0, 142)
actionRail.Size = UDim2.new(0, 56, 0, 226)
actionRail.BackgroundTransparency = 1
actionRail.Parent = gui

local actionRailLayout = Instance.new("UIListLayout")
actionRailLayout.Padding = UDim.new(0, 5)
actionRailLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionRailLayout.SortOrder = Enum.SortOrder.LayoutOrder
actionRailLayout.Parent = actionRail

local function makeRailButton(name, label, color, order)
    local button = Instance.new("TextButton")
    button.Name = name
    button.LayoutOrder = order
    button.Size = UDim2.fromOffset(52, 52)
    button.BackgroundColor3 = color
    button.Font = Enum.Font.ArialBold
    button.Text = label
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    button.TextWrapped = true
    button.Parent = actionRail
    round(button, 10)
    local railStroke = outline(button, 2)
    railStroke.Color = Color3.fromRGB(255, 255, 255)
    return button
end

local shopRailButton = makeRailButton("RailShop", "SHOP", Color3.fromRGB(220, 66, 66), 1)
local avatarRailButton = makeRailButton("RailAvatar", "AVATAR", Color3.fromRGB(54, 174, 221), 2)
local travelRailButton = makeRailButton("RailTravel", "TRAVEL", Color3.fromRGB(235, 177, 49), 4)

local quickBar = Instance.new("Frame")
quickBar.Name = "RHS2QuickBar"
quickBar.AnchorPoint = Vector2.new(0.5, 1)
quickBar.Position = UDim2.new(0.5, 0, 1, -bottomMargin)
quickBar.Size = UDim2.new(0, 238, 0, 54)
quickBar.BackgroundTransparency = 1
quickBar.Parent = gui

local quickLayout = Instance.new("UIListLayout")
quickLayout.FillDirection = Enum.FillDirection.Horizontal
quickLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
quickLayout.Padding = UDim.new(0, 7)
quickLayout.Parent = quickBar

for index, slot in ipairs({
    { label = "BAG", color = Color3.fromRGB(56, 177, 220) },
    { label = "", color = Color3.fromRGB(36, 45, 77) },
    { label = "PHONE", color = Color3.fromRGB(68, 195, 80) },
    { label = "ITEMS", color = Color3.fromRGB(210, 83, 188) },
}) do
    local quickSlot = Instance.new("TextLabel")
    quickSlot.Name = "QuickSlot" .. tostring(index)
    quickSlot.Size = UDim2.fromOffset(52, 52)
    quickSlot.BackgroundColor3 = slot.color
    quickSlot.Font = Enum.Font.ArialBold
    quickSlot.Text = slot.label
    quickSlot.TextColor3 = Color3.fromRGB(255, 255, 255)
    quickSlot.TextSize = 10
    quickSlot.Parent = quickBar
    round(quickSlot, 10)
    local quickStroke = outline(quickSlot, 2)
    quickStroke.Color = Color3.fromRGB(236, 243, 250)
end

local modal = Instance.new("Frame")
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.55)
modal.Size = UDim2.new(0.9, 0, 0, 390)
modal.BackgroundColor3 = LEGACY_PANEL
modal.Visible = false
modal.Parent = gui
round(modal, 2)
outline(modal, 2)
local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(300, 360)
constraint.MaxSize = Vector2.new(540, 430)
constraint.Parent = modal

local question = Instance.new("TextLabel")
question.BackgroundTransparency = 1
question.Position = UDim2.new(0, 18, 0, 16)
question.Size = UDim2.new(1, -36, 0, 92)
question.Font = Enum.Font.ArialBold
question.Text = ""
question.TextColor3 = LEGACY_BLUE_DARK
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
feedback.Font = Enum.Font.Arial
feedback.Text = ""
feedback.TextColor3 = Color3.fromRGB(31, 72, 102)
feedback.TextSize = 13
feedback.TextWrapped = true
feedback.Parent = modal

local latestClassState = nil
local activeClassKey = nil
local activeActivity = nil
local busy = false
local points = 0
local pendingProgression = nil

local WEEKDAYS = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday" }

local function formatLegacyClock(state)
    local schoolDay = tonumber(state.schoolDay) or 1
    local periodIndex = tonumber(state.periodIndex) or 1
    local secondsRemaining = tonumber(state.secondsRemaining) or SchoolConfig.PERIOD_SECONDS
    local elapsedInPeriod = math.max(0, SchoolConfig.PERIOD_SECONDS - secondsRemaining)
    local elapsedDay = ((periodIndex - 1) * SchoolConfig.PERIOD_SECONDS) + elapsedInPeriod
    local totalDay = math.max(1, #SchoolConfig.Periods * SchoolConfig.PERIOD_SECONDS)
    local minutesFromSeven = math.floor((elapsedDay / totalDay) * (8 * 60))
    local absoluteMinutes = (7 * 60) + minutesFromSeven
    local hour24 = math.floor(absoluteMinutes / 60) % 24
    local minute = absoluteMinutes % 60
    local suffix = hour24 >= 12 and "PM" or "AM"
    local hour12 = hour24 % 12
    if hour12 == 0 then hour12 = 12 end
    local weekday = WEEKDAYS[((schoolDay - 1) % #WEEKDAYS) + 1]
    return string.format("%d:%02d %s", hour12, minute, suffix), weekday
end

local function setPoints(value)
    if type(value) ~= "number" then return end
    points = value
    pointsLabel.Text = "Points: " .. tostring(points)
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
        button.BackgroundColor3 = LEGACY_BUTTON
        button.Font = Enum.Font.ArialBold
        button.Text = tostring(index) .. ".  " .. tostring(choiceText)
        button.TextColor3 = LEGACY_BLUE_DARK
        button.TextSize = 15
        button.TextWrapped = true
        button.Parent = choices
        round(button, 2)
        outline(button, 1)

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

local function findOutfitPanel()
    for _, guiName in ipairs({ "Outfits", "OutfitsMobile", "OutfitsConsole" }) do
        local outfitGui = playerGui:FindFirstChild(guiName)
        if outfitGui then
            local internalEntry = outfitGui:FindFirstChild("OutfitEntryInternal")
            if internalEntry then
                internalEntry.Visible = false
            end
            local panel = outfitGui:FindFirstChild("OutfitInputs")
            if panel then
                return panel
            end
        end
    end
    return nil
end

shopRailButton.Activated:Connect(function()
    local confirmation = shoppingBoundary.consumeServerConfirmation()
    statusLabel.Text = confirmation or "Visit the Style Shop to browse verified items."
end)

avatarRailButton.Activated:Connect(function()
    local outfitPanel = findOutfitPanel()
    if outfitPanel then
        outfitPanel.Visible = not outfitPanel.Visible
    else
        statusLabel.Text = "Avatar controls are still loading."
    end
end)

travelRailButton.Activated:Connect(function()
    if busy then return end
    busy = true
    local ok, response = pcall(function()
        return requestTravel:InvokeServer()
    end)
    busy = false
    if ok and type(response) == "table" and response.accepted == true then
        statusLabel.Text = "Traveling to " .. tostring(response.destination or response.roomDisplayName or "school")
    else
        statusLabel.Text = "Travel becomes available with the next destination."
    end
end)

findOutfitPanel()

task.spawn(function()
    while gui.Parent do
        local okState, state = pcall(function()
            return stateSnapshot:InvokeServer()
        end)
        local okClass, classState = pcall(function()
            return getClassState:InvokeServer()
        end)

        if okState and type(state) == "table" then
            local timeText, weekday = formatLegacyClock(state)
            periodLabel.Text = string.format(
                "%s  %s\n%s",
                timeText,
                weekday,
                tostring(state.periodLabel)
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

local cafeCard = Instance.new("Frame")
cafeCard.Name = "LegacyCafePanel"
cafeCard.AnchorPoint = Vector2.new(1, 1)
cafeCard.Position = UDim2.new(1, -12, 1, -bottomMargin)
cafeCard.Size = UDim2.new(0, 260, 0, 150)
cafeCard.BackgroundColor3 = LEGACY_PANEL
cafeCard.BackgroundTransparency = 0.02
cafeCard.Visible = false
cafeCard.Parent = gui
round(cafeCard, 2)
outline(cafeCard, 2)

local cafeSizeConstraint = Instance.new("UISizeConstraint")
cafeSizeConstraint.MinSize = Vector2.new(270, 160)
cafeSizeConstraint.MaxSize = Vector2.new(330, 180)
cafeSizeConstraint.Parent = cafeCard

local cafeTitle = Instance.new("TextLabel")
cafeTitle.BackgroundTransparency = 0
cafeTitle.BackgroundColor3 = LEGACY_BLUE
cafeTitle.Position = UDim2.new(0, 0, 0, 0)
cafeTitle.Size = UDim2.new(1, 0, 0, 26)
cafeTitle.Font = Enum.Font.ArialBold
cafeTitle.Text = "Corner Cafe"
cafeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
cafeTitle.TextSize = 14
cafeTitle.TextXAlignment = Enum.TextXAlignment.Center
cafeTitle.Parent = cafeCard

local cafeStatus = Instance.new("TextLabel")
cafeStatus.BackgroundTransparency = 1
cafeStatus.Position = UDim2.new(0, 10, 0, 34)
cafeStatus.Size = UDim2.new(1, -20, 0, 48)
cafeStatus.Font = Enum.Font.Arial
cafeStatus.Text = "Start a short cafe shift and serve one order."
cafeStatus.TextColor3 = LEGACY_BLUE_DARK
cafeStatus.TextSize = 13
cafeStatus.TextWrapped = true
cafeStatus.TextXAlignment = Enum.TextXAlignment.Left
cafeStatus.TextYAlignment = Enum.TextYAlignment.Top
cafeStatus.Parent = cafeCard

local cafeAction = Instance.new("TextButton")
cafeAction.Position = UDim2.new(0, 8, 1, -48)
cafeAction.Size = UDim2.new(1, -16, 0, 40)
cafeAction.BackgroundColor3 = LEGACY_BUTTON
cafeAction.Font = Enum.Font.ArialBold
cafeAction.Text = "START SHIFT"
cafeAction.TextColor3 = LEGACY_BLUE_DARK
cafeAction.TextSize = 14
cafeAction.Parent = cafeCard
round(cafeAction, 2)
outline(cafeAction, 1)

local cafeLeave = Instance.new("TextButton")
cafeLeave.AnchorPoint = Vector2.new(1, 0)
cafeLeave.Position = UDim2.new(1, -8, 0, 28)
cafeLeave.Size = UDim2.new(0, 82, 0, 30)
cafeLeave.BackgroundTransparency = 1
cafeLeave.Font = Enum.Font.Arial
cafeLeave.Text = "LEAVE JOB"
cafeLeave.TextColor3 = LEGACY_BLUE_DARK
cafeLeave.TextSize = 11
cafeLeave.Visible = false
cafeLeave.Parent = cafeCard

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


-- Assigned Free-Roam vehicle slice. The server owns spawn placement,
-- active vehicle identity, seat authorization, and movement authority.
local vehicleRoot = root:WaitForChild("FreeRoam"):WaitForChild("Vehicles")
local getVehicleState = vehicleRoot:WaitForChild("GetState")
local spawnVehicle = vehicleRoot:WaitForChild("Spawn")
local despawnVehicle = vehicleRoot:WaitForChild("Despawn")
local setVehicleControls = vehicleRoot:WaitForChild("SetControls")

local vehicleCard = Instance.new("Frame")
vehicleCard.Name = "LegacyVehiclePanel"
vehicleCard.AnchorPoint = Vector2.new(0.5, 1)
vehicleCard.Position = UDim2.new(0.5, 0, 1, -bottomMargin)
vehicleCard.Size = UDim2.new(0, 260, 0, 132)
vehicleCard.BackgroundColor3 = LEGACY_PANEL
vehicleCard.BackgroundTransparency = 0.02
vehicleCard.Visible = false
vehicleCard.Parent = gui
round(vehicleCard, 2)
outline(vehicleCard, 2)

local vehicleTitle = Instance.new("TextLabel")
vehicleTitle.BackgroundTransparency = 0
vehicleTitle.BackgroundColor3 = LEGACY_BLUE
vehicleTitle.Position = UDim2.new(0, 0, 0, 0)
vehicleTitle.Size = UDim2.new(1, 0, 0, 26)
vehicleTitle.Font = Enum.Font.ArialBold
vehicleTitle.Text = "Auto Shop"
vehicleTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
vehicleTitle.TextSize = 14
vehicleTitle.TextXAlignment = Enum.TextXAlignment.Center
vehicleTitle.Parent = vehicleCard

local vehicleStatus = Instance.new("TextLabel")
vehicleStatus.BackgroundTransparency = 1
vehicleStatus.Position = UDim2.new(0, 10, 0, 34)
vehicleStatus.Size = UDim2.new(1, -20, 0, 38)
vehicleStatus.Font = Enum.Font.Arial
vehicleStatus.Text = "Spawn the starter car."
vehicleStatus.TextColor3 = LEGACY_BLUE_DARK
vehicleStatus.TextSize = 13
vehicleStatus.TextWrapped = true
vehicleStatus.TextXAlignment = Enum.TextXAlignment.Left
vehicleStatus.TextYAlignment = Enum.TextYAlignment.Top
vehicleStatus.Parent = vehicleCard

local vehicleAction = Instance.new("TextButton")
vehicleAction.Position = UDim2.new(0, 8, 1, -46)
vehicleAction.Size = UDim2.new(1, -16, 0, 38)
vehicleAction.BackgroundColor3 = LEGACY_BUTTON
vehicleAction.Font = Enum.Font.ArialBold
vehicleAction.Text = "SPAWN STARTER CAR"
vehicleAction.TextColor3 = LEGACY_BLUE_DARK
vehicleAction.TextSize = 14
vehicleAction.Parent = vehicleCard
round(vehicleAction, 2)
outline(vehicleAction, 1)

local latestVehicleState = nil
local vehicleBusy = false
local vehicleMessageUntil = 0

local VEHICLE_FORWARD = "PipHighVehicleForward"
local VEHICLE_REVERSE = "PipHighVehicleReverse"
local VEHICLE_LEFT = "PipHighVehicleLeft"
local VEHICLE_RIGHT = "PipHighVehicleRight"
local vehicleControlsBound = false
local vehicleControlState = {
    forward = false,
    reverse = false,
    left = false,
    right = false,
}

local function currentVehicleControls()
    local throttle = (vehicleControlState.forward and 1 or 0)
        - (vehicleControlState.reverse and 1 or 0)
    local steer = (vehicleControlState.right and 1 or 0)
        - (vehicleControlState.left and 1 or 0)
    return throttle, steer
end

local function sendVehicleControls()
    if not vehicleControlsBound then
        return
    end
    local throttle, steer = currentVehicleControls()
    setVehicleControls:FireServer(throttle, steer)
end

local function vehicleControlHandler(key)
    return function(_, inputState)
        if not vehicleControlsBound then
            return Enum.ContextActionResult.Pass
        end

        if inputState == Enum.UserInputState.Begin then
            vehicleControlState[key] = true
        elseif inputState == Enum.UserInputState.End
            or inputState == Enum.UserInputState.Cancel then
            vehicleControlState[key] = false
        else
            return Enum.ContextActionResult.Sink
        end

        sendVehicleControls()
        return Enum.ContextActionResult.Sink
    end
end

local function resetVehicleControlState()
    vehicleControlState.forward = false
    vehicleControlState.reverse = false
    vehicleControlState.left = false
    vehicleControlState.right = false
end

local function bindVehicleControls()
    if vehicleControlsBound then
        return
    end

    resetVehicleControlState()
    vehicleControlsBound = true

    ContextActionService:BindAction(
        VEHICLE_FORWARD,
        vehicleControlHandler("forward"),
        true,
        Enum.KeyCode.W,
        Enum.KeyCode.Up
    )
    ContextActionService:BindAction(
        VEHICLE_REVERSE,
        vehicleControlHandler("reverse"),
        true,
        Enum.KeyCode.S,
        Enum.KeyCode.Down
    )
    ContextActionService:BindAction(
        VEHICLE_LEFT,
        vehicleControlHandler("left"),
        true,
        Enum.KeyCode.A,
        Enum.KeyCode.Left
    )
    ContextActionService:BindAction(
        VEHICLE_RIGHT,
        vehicleControlHandler("right"),
        true,
        Enum.KeyCode.D,
        Enum.KeyCode.Right
    )

    ContextActionService:SetTitle(VEHICLE_FORWARD, "FWD")
    ContextActionService:SetTitle(VEHICLE_REVERSE, "REV")
    ContextActionService:SetTitle(VEHICLE_LEFT, "LEFT")
    ContextActionService:SetTitle(VEHICLE_RIGHT, "RIGHT")

    ContextActionService:SetPosition(VEHICLE_FORWARD, UDim2.new(0, 80, 1, -190))
    ContextActionService:SetPosition(VEHICLE_REVERSE, UDim2.new(0, 80, 1, -70))
    ContextActionService:SetPosition(VEHICLE_LEFT, UDim2.new(0, 20, 1, -130))
    ContextActionService:SetPosition(VEHICLE_RIGHT, UDim2.new(0, 140, 1, -130))

    sendVehicleControls()
end

local function unbindVehicleControls()
    if not vehicleControlsBound then
        return
    end

    resetVehicleControlState()
    setVehicleControls:FireServer(0, 0)
    vehicleControlsBound = false

    ContextActionService:UnbindAction(VEHICLE_FORWARD)
    ContextActionService:UnbindAction(VEHICLE_REVERSE)
    ContextActionService:UnbindAction(VEHICLE_LEFT)
    ContextActionService:UnbindAction(VEHICLE_RIGHT)
end

local function setVehicleMessage(text)
    vehicleStatus.Text = text
    vehicleMessageUntil = os.clock() + 2.6
end

local function applyVehicleState(state)
    if type(state) ~= "table" then
        return
    end

    latestVehicleState = state
    vehicleCard.Visible = state.active == true or state.atAutoShop == true

    if state.driving == true then
        bindVehicleControls()
    else
        unbindVehicleControls()
    end

    if state.active == true then
        vehicleTitle.Text = "STARTER CAR"
        vehicleAction.Text = "DESPAWN VEHICLE"
        if os.clock() >= vehicleMessageUntil then
            if state.driving == true then
                vehicleStatus.Text = "Drive with the controls. Jump to exit."
            else
                vehicleStatus.Text = "Walk to the driver seat to continue driving."
            end
        end
    else
        vehicleTitle.Text = tostring(state.autoShopDisplayName or "AUTO SHOP"):upper()
        vehicleAction.Text = "SPAWN STARTER CAR"
        if os.clock() >= vehicleMessageUntil then
            vehicleStatus.Text = "Spawn the starter car and drive around town."
        end
    end
end

local function refreshVehicle()
    local ok, state = pcall(function()
        return getVehicleState:InvokeServer()
    end)
    if ok and type(state) == "table" then
        applyVehicleState(state)
    elseif latestVehicleState and latestVehicleState.active == true then
        vehicleCard.Visible = true
        vehicleStatus.Text = "Vehicle service unavailable."
    end
end

vehicleAction.Activated:Connect(function()
    if vehicleBusy then
        return
    end

    vehicleBusy = true
    vehicleAction.Active = false
    vehicleAction.Text = "WORKING..."

    local ok, response
    if latestVehicleState and latestVehicleState.active == true then
        ok, response = pcall(function()
            return despawnVehicle:InvokeServer()
        end)
    else
        ok, response = pcall(function()
            return spawnVehicle:InvokeServer()
        end)
    end

    vehicleBusy = false
    vehicleAction.Active = true

    if not ok or type(response) ~= "table" then
        setVehicleMessage("Vehicle service unavailable. Try again.")
        refreshVehicle()
        return
    end

    if response.accepted ~= true then
        if response.code == "not_at_auto_shop" then
            setVehicleMessage("Move closer to the Auto Shop first.")
        elseif response.code == "vehicle_already_active" then
            setVehicleMessage("You already have an active vehicle.")
        else
            setVehicleMessage("That vehicle action is not available right now.")
        end
    elseif response.code == "vehicle_spawned" then
        setVehicleMessage("Starter car ready. Use the driving controls.")
    elseif response.code == "vehicle_despawned"
        or response.code == "vehicle_already_despawned" then
        setVehicleMessage("Vehicle returned.")
    end

    if response.state then
        applyVehicleState(response.state)
    else
        refreshVehicle()
    end
end)

task.spawn(function()
    while gui.Parent do
        refreshVehicle()
        task.wait(0.75)
    end
    unbindVehicleControls()
end)

task.spawn(function()
    while gui.Parent do
        if vehicleControlsBound then
            sendVehicleControls()
        end
        task.wait(0.12)
    end
end)


-- Legacy House menu. The original experience exposed this from the lower-left
-- HUD and used it for permanent house purchase, teleport, and edit mode.
-- Server authority remains in HousingService; this client only presents state
-- and requests actions.
local housingRoot = root:WaitForChild("FreeRoam"):WaitForChild("Housing")
local getHousingState = housingRoot:WaitForChild("GetState")
local buyHouse = housingRoot:WaitForChild("BuyHouse")
local teleportToHouse = housingRoot:WaitForChild("TeleportToHouse")
local setHouseEditMode = housingRoot:WaitForChild("SetEditMode")
local setHouseStyle = housingRoot:WaitForChild("SetStyle")
local getHousingEditorState = housingRoot:WaitForChild("GetEditorState")
local purchaseFurniture = housingRoot:WaitForChild("PurchaseFurniture")
local placeFurniture = housingRoot:WaitForChild("PlaceFurniture")
local moveFurniture = housingRoot:WaitForChild("MoveFurniture")
local rotateFurniture = housingRoot:WaitForChild("RotateFurniture")
local removeFurniture = housingRoot:WaitForChild("RemoveFurniture")
local sellFurniture = housingRoot:WaitForChild("SellFurniture")
local paintFurniture = housingRoot:WaitForChild("PaintFurniture")
local setHousingWalls = housingRoot:WaitForChild("SetHideWalls")

local houseIcon = Instance.new("TextButton")
houseIcon.Name = "LegacyHouseButton"
houseIcon.LayoutOrder = 3
houseIcon.Size = UDim2.fromOffset(52, 52)
houseIcon.BackgroundColor3 = Color3.fromRGB(83, 188, 77)
houseIcon.Font = Enum.Font.ArialBold
houseIcon.Text = "HOUSE"
houseIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
houseIcon.TextSize = 12
houseIcon.Parent = actionRail
round(houseIcon, 10)
local houseRailStroke = outline(houseIcon, 2)
houseRailStroke.Color = Color3.fromRGB(255, 255, 255)

local housePanel = Instance.new("Frame")
housePanel.Name = "LegacyHousePanel"
housePanel.AnchorPoint = Vector2.new(0, 1)
housePanel.Position = UDim2.new(0, 256, 1, -(bottomMargin + 66))
housePanel.Size = UDim2.new(0, 248, 0, 252)
housePanel.BackgroundColor3 = LEGACY_PANEL
housePanel.BackgroundTransparency = 0.02
housePanel.Visible = false
housePanel.Parent = gui
round(housePanel, 2)
outline(housePanel, 2)

local houseTitle = Instance.new("TextLabel")
houseTitle.BackgroundColor3 = LEGACY_BLUE
houseTitle.BorderSizePixel = 0
houseTitle.Size = UDim2.new(1, 0, 0, 28)
houseTitle.Font = Enum.Font.ArialBold
houseTitle.Text = "House"
houseTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
houseTitle.TextSize = 15
houseTitle.Parent = housePanel

local houseStatus = Instance.new("TextLabel")
houseStatus.BackgroundTransparency = 1
houseStatus.Position = UDim2.new(0, 10, 0, 36)
houseStatus.Size = UDim2.new(1, -20, 0, 52)
houseStatus.Font = Enum.Font.Arial
houseStatus.Text = "Loading house..."
houseStatus.TextColor3 = LEGACY_BLUE_DARK
houseStatus.TextSize = 13
houseStatus.TextWrapped = true
houseStatus.TextXAlignment = Enum.TextXAlignment.Left
houseStatus.TextYAlignment = Enum.TextYAlignment.Top
houseStatus.Parent = housePanel

local housePrimary = Instance.new("TextButton")
housePrimary.Name = "HousePrimaryAction"
housePrimary.Position = UDim2.new(0, 10, 0, 94)
housePrimary.Size = UDim2.new(1, -20, 0, 38)
housePrimary.BackgroundColor3 = LEGACY_BUTTON
housePrimary.Font = Enum.Font.ArialBold
housePrimary.Text = "BUY HOUSE  •  $50"
housePrimary.TextColor3 = LEGACY_BLUE_DARK
housePrimary.TextSize = 13
housePrimary.Parent = housePanel
round(housePrimary, 2)
outline(housePrimary, 1)

local houseEdit = Instance.new("TextButton")
houseEdit.Name = "HouseEditAction"
houseEdit.Position = UDim2.new(0, 10, 0, 138)
houseEdit.Size = UDim2.new(1, -20, 0, 38)
houseEdit.BackgroundColor3 = LEGACY_BUTTON
houseEdit.Font = Enum.Font.ArialBold
houseEdit.Text = "EDIT HOUSE"
houseEdit.TextColor3 = LEGACY_BLUE_DARK
houseEdit.TextSize = 13
houseEdit.Visible = false
houseEdit.Parent = housePanel
round(houseEdit, 2)
outline(houseEdit, 1)

local houseColorLabel = Instance.new("TextLabel")
houseColorLabel.BackgroundTransparency = 1
houseColorLabel.Position = UDim2.new(0, 10, 0, 181)
houseColorLabel.Size = UDim2.new(1, -20, 0, 18)
houseColorLabel.Font = Enum.Font.ArialBold
houseColorLabel.Text = "HOUSE COLOR"
houseColorLabel.TextColor3 = LEGACY_BLUE_DARK
houseColorLabel.TextSize = 12
houseColorLabel.TextXAlignment = Enum.TextXAlignment.Left
houseColorLabel.Visible = false
houseColorLabel.Parent = housePanel

local colorRow = Instance.new("Frame")
colorRow.BackgroundTransparency = 1
colorRow.Position = UDim2.new(0, 10, 0, 202)
colorRow.Size = UDim2.new(1, -20, 0, 38)
colorRow.Visible = false
colorRow.Parent = housePanel

local colorLayout = Instance.new("UIListLayout")
colorLayout.FillDirection = Enum.FillDirection.Horizontal
colorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
colorLayout.Padding = UDim.new(0, 6)
colorLayout.Parent = colorRow

local HOUSE_STYLES = {
    { id = "classic-blue", label = "BLUE", color = Color3.fromRGB(176, 190, 199) },
    { id = "classic-tan", label = "TAN", color = Color3.fromRGB(191, 177, 155) },
    { id = "classic-red", label = "RED", color = Color3.fromRGB(183, 127, 119) },
    { id = "classic-green", label = "GREEN", color = Color3.fromRGB(145, 171, 132) },
}

local latestHousingState = nil
local housingBusy = false
local housingMessageUntil = 0

local function setHousingMessage(message)
    houseStatus.Text = message
    housingMessageUntil = os.clock() + 2.8
end

local function applyHousingState(state)
    if type(state) ~= "table" then
        return
    end

    latestHousingState = state
    local owned = state.owned == true
    local editing = state.editing == true

    if owned then
        housePrimary.Text = "TELEPORT TO HOUSE"
        houseEdit.Visible = true
        houseEdit.Text = editing and "SAVE HOUSE" or "EDIT HOUSE"
        houseColorLabel.Visible = editing
        colorRow.Visible = editing

        if os.clock() >= housingMessageUntil then
            local plotText = state.plotId and ("  •  " .. tostring(state.plotId)) or ""
            houseStatus.Text = "Your permanent house" .. plotText
                .. "\nBalance: $" .. tostring(state.balance or 0)
        end
    else
        housePrimary.Text = "BUY HOUSE  •  $" .. tostring(state.price or 50)
        houseEdit.Visible = false
        houseColorLabel.Visible = false
        colorRow.Visible = false

        if os.clock() >= housingMessageUntil then
            houseStatus.Text = "Buy your own permanent customizable house."
                .. "\nBalance: $" .. tostring(state.balance or 0)
        end
    end

    housePrimary.Active = state.available ~= false
    houseEdit.Active = owned and state.plotId ~= nil
end

local function refreshHousing()
    local ok, state = pcall(function()
        return getHousingState:InvokeServer()
    end)
    if ok and type(state) == "table" then
        applyHousingState(state)
    else
        setHousingMessage("House service unavailable. Try again.")
    end
end

for _, spec in ipairs(HOUSE_STYLES) do
    local button = Instance.new("TextButton")
    button.Name = "HouseColor_" .. spec.id
    button.Size = UDim2.new(0, 50, 1, 0)
    button.BackgroundColor3 = spec.color
    button.Font = Enum.Font.ArialBold
    button.Text = spec.label
    button.TextColor3 = Color3.fromRGB(35, 55, 69)
    button.TextSize = 10
    button.Parent = colorRow
    round(button, 2)
    outline(button, 1)

    button.Activated:Connect(function()
        if housingBusy or not latestHousingState or latestHousingState.editing ~= true then
            return
        end

        housingBusy = true
        local ok, response = pcall(function()
            return setHouseStyle:InvokeServer(spec.id, HttpService:GenerateGUID(false))
        end)
        housingBusy = false

        if ok and type(response) == "table" and response.accepted == true then
            setHousingMessage("House color updated.")
            applyHousingState(response)
        else
            setHousingMessage("Could not change house color.")
            refreshHousing()
        end
    end)
end

houseIcon.Activated:Connect(function()
    housePanel.Visible = not housePanel.Visible
    if housePanel.Visible then
        refreshHousing()
    end
end)

housePrimary.Activated:Connect(function()
    if housingBusy then
        return
    end

    housingBusy = true
    housePrimary.Active = false

    local ok, response
    if latestHousingState and latestHousingState.owned == true then
        housePrimary.Text = "TELEPORTING..."
        ok, response = pcall(function()
            return teleportToHouse:InvokeServer()
        end)
    else
        housePrimary.Text = "BUYING..."
        ok, response = pcall(function()
            return buyHouse:InvokeServer()
        end)
    end

    housingBusy = false
    housePrimary.Active = true

    if not ok or type(response) ~= "table" then
        setHousingMessage("House service unavailable. Try again.")
        refreshHousing()
        return
    end

    if response.accepted ~= true then
        if response.code == "insufficient_funds" then
            setHousingMessage("You need $50 RHS Cash to buy this house.")
        elseif response.code == "no_plot_available" then
            setHousingMessage("No house plot is available in this server.")
        else
            setHousingMessage("That house action is not available right now.")
        end
    elseif response.code == "house_purchased" then
        setHousingMessage("House purchased! Use Teleport to House to find it.")
    elseif response.code == "teleported_to_house" then
        setHousingMessage("Teleported to your house.")
    end

    applyHousingState(response)
end)

houseEdit.Activated:Connect(function()
    if housingBusy or not latestHousingState or latestHousingState.owned ~= true then
        return
    end

    housingBusy = true
    houseEdit.Active = false
    local nextEditing = latestHousingState.editing ~= true
    local ok, response = pcall(function()
        return setHouseEditMode:InvokeServer(nextEditing)
    end)
    housingBusy = false
    houseEdit.Active = true

    if ok and type(response) == "table" and response.accepted == true then
        setHousingMessage(nextEditing and "Edit House mode enabled." or "House saved.")
        applyHousingState(response)
    else
        setHousingMessage("Could not update Edit House mode.")
        refreshHousing()
    end
end)

task.spawn(function()
    while gui.Parent do
        if housePanel.Visible then
            refreshHousing()
        end
        task.wait(1.0)
    end
end)


-- Housing Editor V2. Visible only while the owner is in Edit House mode.
-- Exact verified Legacy labels retained: Add Furni, Hide Walls, Utilities, Other.
local editorPanel = Instance.new("Frame")
editorPanel.Name = "LegacyHousingEditorV2"
editorPanel.AnchorPoint = Vector2.new(0, 1)
editorPanel.Position = UDim2.new(0, 512, 1, -(bottomMargin + 66))
editorPanel.Size = UDim2.new(0, 330, 0, 346)
editorPanel.BackgroundColor3 = LEGACY_PANEL
editorPanel.BackgroundTransparency = 0.02
editorPanel.Visible = false
editorPanel:SetAttribute("ReferenceExactLayout", false)
editorPanel:SetAttribute("ReferenceCoverage", "verified-labels-only")
editorPanel.Parent = gui
round(editorPanel, 2)
outline(editorPanel, 2)

local editorTitle = Instance.new("TextLabel")
editorTitle.BackgroundColor3 = LEGACY_BLUE
editorTitle.BorderSizePixel = 0
editorTitle.Size = UDim2.new(1, 0, 0, 28)
editorTitle.Font = Enum.Font.ArialBold
editorTitle.Text = "Add Furni"
editorTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
editorTitle.TextSize = 15
editorTitle.Parent = editorPanel

local editorCategories = Instance.new("TextLabel")
editorCategories.BackgroundTransparency = 1
editorCategories.Position = UDim2.new(0, 10, 0, 34)
editorCategories.Size = UDim2.new(1, -20, 0, 20)
editorCategories.Font = Enum.Font.ArialBold
editorCategories.Text = "Utilities   |   Other"
editorCategories.TextColor3 = LEGACY_BLUE_DARK
editorCategories.TextSize = 12
editorCategories.TextXAlignment = Enum.TextXAlignment.Left
editorCategories.Parent = editorPanel

local editorCatalog = Instance.new("Frame")
editorCatalog.BackgroundTransparency = 1
editorCatalog.Position = UDim2.new(0, 10, 0, 58)
editorCatalog.Size = UDim2.new(1, -20, 0, 82)
editorCatalog.Parent = editorPanel

local editorCatalogLayout = Instance.new("UIListLayout")
editorCatalogLayout.Padding = UDim.new(0, 4)
editorCatalogLayout.Parent = editorCatalog

local editorStatus = Instance.new("TextLabel")
editorStatus.BackgroundTransparency = 1
editorStatus.Position = UDim2.new(0, 10, 0, 144)
editorStatus.Size = UDim2.new(1, -20, 0, 38)
editorStatus.Font = Enum.Font.Arial
editorStatus.Text = ""
editorStatus.Visible = false
editorStatus.TextColor3 = LEGACY_BLUE_DARK
editorStatus.TextSize = 12
editorStatus.TextWrapped = true
editorStatus.TextXAlignment = Enum.TextXAlignment.Left
editorStatus.TextYAlignment = Enum.TextYAlignment.Top
editorStatus.Parent = editorPanel

local editorActions = Instance.new("Frame")
editorActions.BackgroundTransparency = 1
editorActions.Position = UDim2.new(0, 10, 0, 188)
editorActions.Size = UDim2.new(1, -20, 0, 112)
editorActions.Visible = false
editorActions:SetAttribute("ReferenceExact", false)
editorActions.Parent = editorPanel

local editorGrid = Instance.new("UIGridLayout")
editorGrid.CellSize = UDim2.new(0, 96, 0, 32)
editorGrid.CellPadding = UDim2.new(0, 5, 0, 5)
editorGrid.Parent = editorActions

local function editorButton(name, label)
    local button = Instance.new("TextButton")
    button.Name = name
    button.BackgroundColor3 = LEGACY_BUTTON
    button.Font = Enum.Font.ArialBold
    button.Text = label
    button.TextColor3 = LEGACY_BLUE_DARK
    button.TextSize = 11
    button.Parent = editorActions
    round(button, 2)
    outline(button, 1)
    return button
end

local buyFurni = editorButton("BuyFurniture", "")
local placeFurni = editorButton("PlaceFurniture", "")
local moveFurni = editorButton("MoveFurniture", "")
local rotateFurni = editorButton("RotateFurniture", "")
local removeFurni = editorButton("RemoveFurniture", "")
local sellFurni = editorButton("SellFurniture", "")
local paintFurni = editorButton("PaintFurniture", "")

local hideWallsButton = Instance.new("TextButton")
hideWallsButton.Name = "HideWalls"
hideWallsButton.Position = UDim2.new(0, 10, 1, -40)
hideWallsButton.Size = UDim2.new(1, -20, 0, 30)
hideWallsButton.BackgroundColor3 = LEGACY_BUTTON
hideWallsButton.Font = Enum.Font.ArialBold
hideWallsButton.Text = "Hide Walls"
hideWallsButton.TextColor3 = LEGACY_BLUE_DARK
hideWallsButton.TextSize = 11
hideWallsButton.Parent = editorPanel
round(hideWallsButton, 2)
outline(hideWallsButton, 1)

local latestEditorState = nil
local selectedFurnitureItemId = nil
local selectedPlacementId = nil
local editorBusy = false
local pendingEditorRequests = {}
local paintSequence = { "default", "legacy-blue", "legacy-red", "legacy-green", "legacy-tan" }
local paintIndex = 1

local function inventoryQuantity(state, itemId)
    for _, entry in ipairs((state and state.inventory) or {}) do
        if entry.itemId == itemId then
            return entry.quantity or 0
        end
    end
    return 0
end

local function placementById(state, placementId)
    for _, placement in ipairs((state and state.placements) or {}) do
        if placement.placementId == placementId then
            return placement
        end
    end
    return nil
end

local function catalogById(state, itemId)
    for _, item in ipairs((state and state.catalog) or {}) do
        if item.itemId == itemId and item.referenceExact == true then
            return item
        end
    end
    return nil
end

local function firstExactCatalogItemId(state)
    for _, item in ipairs((state and state.catalog) or {}) do
        if item.referenceExact == true then
            return item.itemId
        end
    end
    return nil
end

local function editorRequestId(key)
    if pendingEditorRequests[key] == nil then
        pendingEditorRequests[key] = HttpService:GenerateGUID(false)
    end
    return pendingEditorRequests[key]
end

local function finishEditorRequest(key, response)
    if type(response) ~= "table" or response.retryable ~= true then
        pendingEditorRequests[key] = nil
    end
end

local function clearEditorCatalogButtons()
    for _, child in ipairs(editorCatalog:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
end

local function applyEditorState(state)
    if type(state) ~= "table" or state.accepted ~= true then return end
    latestEditorState = state

    if not catalogById(state, selectedFurnitureItemId) then
        selectedFurnitureItemId = firstExactCatalogItemId(state)
    end
    if selectedPlacementId and not placementById(state, selectedPlacementId) then
        selectedPlacementId = nil
    end
    if not selectedPlacementId and state.placements and state.placements[1] then
        selectedPlacementId = state.placements[1].placementId
    end

    clearEditorCatalogButtons()
    for _, item in ipairs(state.catalog or {}) do
        if item.referenceExact == true then
        local button = Instance.new("TextButton")
        button.Name = "Catalog_" .. tostring(item.itemId)
        button.Size = UDim2.new(1, 0, 0, 36)
        button.BackgroundColor3 = item.itemId == selectedFurnitureItemId
            and Color3.fromRGB(210, 225, 240)
            or LEGACY_BUTTON
        button.Font = Enum.Font.ArialBold
        button.TextColor3 = LEGACY_BLUE_DARK
        button.TextSize = 11
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Text = string.format(
            "  [%s] %s  $%d  x%d",
            tostring(item.category),
            tostring(item.displayName),
            tonumber(item.price) or 0,
            inventoryQuantity(state, item.itemId)
        )
        button.Parent = editorCatalog
        round(button, 2)
        outline(button, 1)
        button.Activated:Connect(function()
            selectedFurnitureItemId = item.itemId
            applyEditorState(latestEditorState)
        end)
        end
    end

    local selected = catalogById(state, selectedFurnitureItemId)
    local placement = placementById(state, selectedPlacementId)
    local itemText = selected and selected.displayName or "No furniture selected"
    local placementText = placement and (" • Selected placed " .. tostring(placement.itemId)) or ""
    editorStatus.Text = itemText .. " • Inventory x"
        .. tostring(selected and inventoryQuantity(state, selected.itemId) or 0)
        .. placementText

    hideWallsButton.Text = "Hide Walls"
end

local function refreshHousingEditor()
    if not latestHousingState
        or latestHousingState.owned ~= true
        or latestHousingState.editing ~= true then
        editorPanel.Visible = false
        return
    end

    editorPanel.Visible = housePanel.Visible
    if not editorPanel.Visible or editorBusy then return end

    local ok, response = pcall(function()
        return getHousingEditorState:InvokeServer()
    end)
    if ok and type(response) == "table" and response.accepted == true then
        applyEditorState(response)
    end
end

local function handleEditorResponse(key, ok, response, successText)
    editorBusy = false
    finishEditorRequest(key, response)
    if not ok or type(response) ~= "table" then
        editorStatus.Text = "Housing editor service unavailable."
        return
    end
    if response.accepted == true then
        if response.placementId then selectedPlacementId = response.placementId end
        applyEditorState(response)
        editorStatus.Text = successText
    else
        editorStatus.Text = tostring(response.code or response.error or "Editor action unavailable.")
    end
end

buyFurni.Activated:Connect(function()
    if editorBusy or not selectedFurnitureItemId then return end
    editorBusy = true
    local key = "buy:" .. selectedFurnitureItemId
    local ok, response = pcall(function()
        return purchaseFurniture:InvokeServer(selectedFurnitureItemId, editorRequestId(key))
    end)
    handleEditorResponse(key, ok, response, "Furniture added to inventory.")
end)

placeFurni.Activated:Connect(function()
    if editorBusy or not selectedFurnitureItemId or not latestEditorState then return end
    editorBusy = true
    local slot = #(latestEditorState.placements or {})
    local transform = {
        x = ((slot % 3) - 1) * 5,
        y = 0,
        z = (math.floor(slot / 3) % 3 - 1) * 4,
        rotation = 0,
    }
    local key = "place:" .. selectedFurnitureItemId
    local ok, response = pcall(function()
        return placeFurniture:InvokeServer(
            selectedFurnitureItemId,
            transform,
            editorRequestId(key)
        )
    end)
    handleEditorResponse(key, ok, response, "Furniture placed.")
end)

moveFurni.Activated:Connect(function()
    local placement = placementById(latestEditorState, selectedPlacementId)
    if editorBusy or not placement then return end
    editorBusy = true
    local nextX = placement.x + 3
    if nextX > 12 then nextX = -12 end
    local transform = {
        x = nextX,
        y = placement.y,
        z = placement.z,
        rotation = placement.rotation,
    }
    local key = "move:" .. placement.placementId
    local ok, response = pcall(function()
        return moveFurniture:InvokeServer(placement.placementId, transform, editorRequestId(key))
    end)
    handleEditorResponse(key, ok, response, "Furniture moved.")
end)

rotateFurni.Activated:Connect(function()
    local placement = placementById(latestEditorState, selectedPlacementId)
    if editorBusy or not placement then return end
    editorBusy = true
    local key = "rotate:" .. placement.placementId
    local ok, response = pcall(function()
        return rotateFurniture:InvokeServer(placement.placementId, 90, editorRequestId(key))
    end)
    handleEditorResponse(key, ok, response, "Furniture rotated.")
end)

removeFurni.Activated:Connect(function()
    local placement = placementById(latestEditorState, selectedPlacementId)
    if editorBusy or not placement then return end
    editorBusy = true
    local key = "remove:" .. placement.placementId
    local ok, response = pcall(function()
        return removeFurniture:InvokeServer(
            placement.placementId,
            placement.itemId,
            editorRequestId(key)
        )
    end)
    handleEditorResponse(key, ok, response, "Furniture returned to inventory.")
end)

sellFurni.Activated:Connect(function()
    if editorBusy or not selectedFurnitureItemId then return end
    editorBusy = true
    local key = "sell:" .. selectedFurnitureItemId
    local ok, response = pcall(function()
        return sellFurniture:InvokeServer(selectedFurnitureItemId, editorRequestId(key))
    end)
    handleEditorResponse(key, ok, response, "Furniture sold.")
end)

paintFurni.Activated:Connect(function()
    local placement = placementById(latestEditorState, selectedPlacementId)
    if editorBusy or not placement then return end
    editorBusy = true
    paintIndex = (paintIndex % #paintSequence) + 1
    local paintId = paintSequence[paintIndex]
    local key = "paint:" .. placement.placementId
    local ok, response = pcall(function()
        return paintFurniture:InvokeServer(
            placement.placementId,
            paintId,
            editorRequestId(key)
        )
    end)
    handleEditorResponse(key, ok, response, "Furniture paint updated.")
end)

hideWallsButton.Activated:Connect(function()
    if editorBusy or not latestEditorState then return end
    editorBusy = true
    local enabled = latestEditorState.hideWalls ~= true
    local key = "walls:" .. tostring(enabled)
    local ok, response = pcall(function()
        return setHousingWalls:InvokeServer(enabled, editorRequestId(key))
    end)
    handleEditorResponse(key, ok, response, enabled and "Walls hidden." or "Walls shown.")
end)

task.spawn(function()
    while gui.Parent do
        refreshHousingEditor()
        task.wait(0.75)
    end
end)
