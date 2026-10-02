local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))

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
gui.Name = "RobloxHighSchoolLegacyUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

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

local card = Instance.new("Frame")
card.Name = "LegacySchoolMenu"
card.AnchorPoint = Vector2.new(0, 1)
card.Position = UDim2.new(0, 12, 1, -bottomMargin)
card.Size = UDim2.new(0, 236, 0, 184)
card.BackgroundColor3 = LEGACY_PANEL
card.BackgroundTransparency = 0.02
card.Parent = gui
round(card, 2)
outline(card, 2)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 0
title.BackgroundColor3 = LEGACY_BLUE
title.Position = UDim2.new(0, 0, 0, 0)
title.Size = UDim2.new(1, 0, 0, 28)
title.Font = Enum.Font.ArialBold
title.Text = "Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = card

local pointsLabel = Instance.new("TextLabel")
pointsLabel.BackgroundTransparency = 1
pointsLabel.Position = UDim2.new(0, 10, 0, 121)
pointsLabel.Size = UDim2.new(1, -20, 0, 20)
pointsLabel.Font = Enum.Font.ArialBold
pointsLabel.Text = "Points: 0"
pointsLabel.TextColor3 = LEGACY_BLUE_DARK
pointsLabel.TextSize = 13
pointsLabel.TextXAlignment = Enum.TextXAlignment.Left
pointsLabel.Parent = card

local periodLabel = Instance.new("TextLabel")
periodLabel.BackgroundTransparency = 1
periodLabel.Position = UDim2.new(0, 10, 0, 35)
periodLabel.Size = UDim2.new(1, -20, 0, 43)
periodLabel.Font = Enum.Font.ArialBold
periodLabel.Text = "Loading school day..."
periodLabel.TextColor3 = LEGACY_BLUE_DARK
periodLabel.TextSize = 15
periodLabel.TextWrapped = true
periodLabel.TextXAlignment = Enum.TextXAlignment.Left
periodLabel.TextYAlignment = Enum.TextYAlignment.Top
periodLabel.Parent = card

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 10, 0, 78)
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Font = Enum.Font.Arial
statusLabel.Text = "Connecting..."
statusLabel.TextColor3 = Color3.fromRGB(31, 72, 102)
statusLabel.TextSize = 13
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = card

local action = Instance.new("TextButton")
action.Position = UDim2.new(0, 8, 1, -50)
action.Size = UDim2.new(1, -16, 0, 44)
action.BackgroundColor3 = LEGACY_BUTTON
action.Font = Enum.Font.ArialBold
action.Text = "CHECKING CLASS..."
action.TextColor3 = LEGACY_BLUE_DARK
action.TextSize = 13
action.Parent = card
round(action, 2)
outline(action, 1)

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
cafeCard.AnchorPoint = Vector2.new(1, 1)
cafeCard.Position = UDim2.new(1, -14, 1, -18)
cafeCard.Size = UDim2.new(0, 300, 0, 168)
cafeCard.BackgroundColor3 = Color3.fromRGB(247, 241, 228)
cafeCard.BackgroundTransparency = 0.03
cafeCard.Visible = false
cafeCard.Parent = gui
round(cafeCard, 16)

local cafeSizeConstraint = Instance.new("UISizeConstraint")
cafeSizeConstraint.MinSize = Vector2.new(270, 160)
cafeSizeConstraint.MaxSize = Vector2.new(330, 180)
cafeSizeConstraint.Parent = cafeCard

local cafeTitle = Instance.new("TextLabel")
cafeTitle.BackgroundTransparency = 1
cafeTitle.Position = UDim2.new(0, 14, 0, 10)
cafeTitle.Size = UDim2.new(1, -104, 0, 24)
cafeTitle.Font = Enum.Font.GothamBold
cafeTitle.Text = "CORNER CAFE"
cafeTitle.TextColor3 = Color3.fromRGB(58, 47, 38)
cafeTitle.TextSize = 17
cafeTitle.TextXAlignment = Enum.TextXAlignment.Left
cafeTitle.Parent = cafeCard

local cafeStatus = Instance.new("TextLabel")
cafeStatus.BackgroundTransparency = 1
cafeStatus.Position = UDim2.new(0, 14, 0, 39)
cafeStatus.Size = UDim2.new(1, -28, 0, 44)
cafeStatus.Font = Enum.Font.Gotham
cafeStatus.Text = "Start a short cafe shift and serve one order."
cafeStatus.TextColor3 = Color3.fromRGB(92, 78, 65)
cafeStatus.TextSize = 13
cafeStatus.TextWrapped = true
cafeStatus.TextXAlignment = Enum.TextXAlignment.Left
cafeStatus.TextYAlignment = Enum.TextYAlignment.Top
cafeStatus.Parent = cafeCard

local cafeAction = Instance.new("TextButton")
cafeAction.Position = UDim2.new(0, 14, 1, -58)
cafeAction.Size = UDim2.new(1, -28, 0, 44)
cafeAction.BackgroundColor3 = Color3.fromRGB(124, 83, 54)
cafeAction.Font = Enum.Font.GothamBold
cafeAction.Text = "START SHIFT"
cafeAction.TextColor3 = Color3.new(1, 1, 1)
cafeAction.TextSize = 14
cafeAction.Parent = cafeCard
round(cafeAction, 11)

local cafeLeave = Instance.new("TextButton")
cafeLeave.AnchorPoint = Vector2.new(1, 0)
cafeLeave.Position = UDim2.new(1, -12, 0, 8)
cafeLeave.Size = UDim2.new(0, 82, 0, 30)
cafeLeave.BackgroundTransparency = 1
cafeLeave.Font = Enum.Font.GothamMedium
cafeLeave.Text = "LEAVE JOB"
cafeLeave.TextColor3 = Color3.fromRGB(117, 98, 82)
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
vehicleCard.AnchorPoint = Vector2.new(0.5, 1)
vehicleCard.Position = UDim2.new(0.5, 0, 1, -18)
vehicleCard.Size = UDim2.new(0, 310, 0, 138)
vehicleCard.BackgroundColor3 = Color3.fromRGB(31, 38, 51)
vehicleCard.BackgroundTransparency = 0.05
vehicleCard.Visible = false
vehicleCard.Parent = gui
round(vehicleCard, 16)

local vehicleTitle = Instance.new("TextLabel")
vehicleTitle.BackgroundTransparency = 1
vehicleTitle.Position = UDim2.new(0, 14, 0, 10)
vehicleTitle.Size = UDim2.new(1, -28, 0, 24)
vehicleTitle.Font = Enum.Font.GothamBold
vehicleTitle.Text = "AUTO SHOP"
vehicleTitle.TextColor3 = Color3.new(1, 1, 1)
vehicleTitle.TextSize = 17
vehicleTitle.TextXAlignment = Enum.TextXAlignment.Left
vehicleTitle.Parent = vehicleCard

local vehicleStatus = Instance.new("TextLabel")
vehicleStatus.BackgroundTransparency = 1
vehicleStatus.Position = UDim2.new(0, 14, 0, 39)
vehicleStatus.Size = UDim2.new(1, -28, 0, 38)
vehicleStatus.Font = Enum.Font.Gotham
vehicleStatus.Text = "Spawn the starter car."
vehicleStatus.TextColor3 = Color3.fromRGB(196, 205, 222)
vehicleStatus.TextSize = 13
vehicleStatus.TextWrapped = true
vehicleStatus.TextXAlignment = Enum.TextXAlignment.Left
vehicleStatus.TextYAlignment = Enum.TextYAlignment.Top
vehicleStatus.Parent = vehicleCard

local vehicleAction = Instance.new("TextButton")
vehicleAction.Position = UDim2.new(0, 14, 1, -52)
vehicleAction.Size = UDim2.new(1, -28, 0, 42)
vehicleAction.BackgroundColor3 = Color3.fromRGB(70, 124, 198)
vehicleAction.Font = Enum.Font.GothamBold
vehicleAction.Text = "SPAWN STARTER CAR"
vehicleAction.TextColor3 = Color3.new(1, 1, 1)
vehicleAction.TextSize = 14
vehicleAction.Parent = vehicleCard
round(vehicleAction, 11)

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
