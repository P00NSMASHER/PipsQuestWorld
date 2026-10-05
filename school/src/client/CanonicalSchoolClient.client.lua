local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local SchoolConfig = require(shared:WaitForChild("SchoolConfig"))
local LegacyOutfitEntry = require(shared:WaitForChild("LegacyOutfitEntry"))
local LegacyShoppingBoundary = require(shared:WaitForChild("LegacyShoppingBoundary"))
local ResponsiveHudLayout = require(shared:WaitForChild("ResponsiveHudLayout"))
local Rhs2UiStyle = require(shared:WaitForChild("Rhs2UiStyle"))
local FeaturePanelController = require(shared:WaitForChild("FeaturePanelController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local legacyOutfitSurface = LegacyOutfitEntry(player, UserInputService)
legacyOutfitSurface.entry.Visible = false
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
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local featurePanels = FeaturePanelController.new()

local auxiliaryPanelBottomMargin = UserInputService.TouchEnabled and 112 or 12

local function round(target, px)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, px)
    corner.Parent = target
end

local function outline(target, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = Rhs2UiStyle.Palette.HeaderBlue
    stroke.Parent = target
    return stroke
end

-- Reference A recurring HUD: compact top-right school status beside a colored action rail.
local card = Instance.new("Frame")
card.Name = "CompactSchoolStatus"
card.AnchorPoint = Vector2.new(0, 0)
card.Position = UDim2.fromOffset(0, 0)
card.Size = UDim2.fromOffset(118, 70)
card.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
card.BackgroundTransparency = 0
card.Parent = gui
Rhs2UiStyle.applyPrimaryPanel(card)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 0
title.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
title.Position = UDim2.new(0, 0, 0, 0)
title.Size = UDim2.new(1, 0, 0, 24)
title.Font = Rhs2UiStyle.Font.Bold
title.Text = "SCHOOL DAY"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = card

local pointsLabel = Instance.new("TextLabel")
pointsLabel.BackgroundTransparency = 0
pointsLabel.BackgroundColor3 = Rhs2UiStyle.Palette.HeaderBlue
pointsLabel.Position = UDim2.new(0, 10, 0, 82)
pointsLabel.Size = UDim2.new(0, 82, 0, 28)
pointsLabel.Font = Rhs2UiStyle.Font.Bold
pointsLabel.Text = "Points: 0"
pointsLabel.TextColor3 = Rhs2UiStyle.Palette.White
pointsLabel.TextSize = 13
pointsLabel.TextXAlignment = Enum.TextXAlignment.Left
pointsLabel.Parent = card
Rhs2UiStyle.applyDarkRow(pointsLabel)
pointsLabel.BackgroundColor3 = Rhs2UiStyle.Palette.HeaderBlue

local periodLabel = Instance.new("TextLabel")
periodLabel.BackgroundTransparency = 1
periodLabel.Position = UDim2.new(0, 9, 0, 29)
periodLabel.Size = UDim2.new(1, -18, 0, 32)
periodLabel.Font = Rhs2UiStyle.Font.Medium
periodLabel.Text = "Loading school day..."
periodLabel.TextColor3 = Rhs2UiStyle.Palette.White
periodLabel.TextSize = 13
periodLabel.TextWrapped = true
periodLabel.TextXAlignment = Enum.TextXAlignment.Left
periodLabel.TextYAlignment = Enum.TextYAlignment.Top
periodLabel.Parent = card
Rhs2UiStyle.applyDarkRow(periodLabel)

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 9, 0, 61)
statusLabel.Size = UDim2.new(1, -18, 0, 22)
statusLabel.Font = Rhs2UiStyle.Font.Regular
statusLabel.Text = "Connecting..."
statusLabel.TextColor3 = Rhs2UiStyle.Palette.White
statusLabel.TextSize = 11
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = card
Rhs2UiStyle.applyDarkRow(statusLabel)

local action = Instance.new("TextButton")
action.Position = UDim2.new(0, 96, 0, 87)
action.Size = UDim2.new(1, -104, 0, 27)
action.BackgroundColor3 = Rhs2UiStyle.Palette.ProgressPurple
action.Font = Rhs2UiStyle.Font.Bold
action.Text = "CHECKING CLASS..."
action.TextColor3 = Rhs2UiStyle.Palette.White
action.TextSize = 13
action.Parent = card
Rhs2UiStyle.applyDarkRow(action)
action.BackgroundColor3 = Rhs2UiStyle.Palette.ProgressPurple

local actionRail = Instance.new("Frame")
actionRail.Name = "RHS2ActionRail"
actionRail.AnchorPoint = Vector2.new(0, 0)
actionRail.Position = UDim2.fromOffset(0, 0)
actionRail.Size = UDim2.fromOffset(48, 176)
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
    button.Font = Rhs2UiStyle.Font.Bold
    button.Text = label
    button.TextColor3 = Rhs2UiStyle.Palette.White
    button.TextSize = 12
    button.TextWrapped = true
    button.Parent = actionRail
    Rhs2UiStyle.applyPrimaryRailButton(button, color)
    return button
end

local shopRailButton = makeRailButton("RailShop", "SHOP", Color3.fromRGB(220, 66, 66), 1)
local avatarRailButton = makeRailButton("RailAvatar", "AVATAR", Color3.fromRGB(54, 174, 221), 2)
local travelRailButton = makeRailButton("RailTravel", "TRAVEL", Color3.fromRGB(235, 177, 49), 4)

-- Reference A also carries a small colorful utility strip below the four
-- primary rail actions. Exact semantics/assets are unverified, so these are
-- deliberately inert visual slots rather than invented gameplay controls.
local utilityRail = Instance.new("Frame")
utilityRail.Name = "RHS2UtilityRail"
utilityRail.AnchorPoint = Vector2.new(0, 0)
utilityRail.Position = UDim2.fromOffset(0, 0)
utilityRail.Size = UDim2.fromOffset(48, 14)
utilityRail.BackgroundTransparency = 1
utilityRail.Parent = gui

local utilityLayout = Instance.new("UIGridLayout")
utilityLayout.FillDirection = Enum.FillDirection.Horizontal
utilityLayout.FillDirectionMaxCells = 2
utilityLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
utilityLayout.VerticalAlignment = Enum.VerticalAlignment.Top
utilityLayout.CellPadding = UDim2.fromOffset(3, 3)
utilityLayout.CellSize = UDim2.fromOffset(20, 20)
utilityLayout.SortOrder = Enum.SortOrder.LayoutOrder
utilityLayout.Parent = utilityRail

for index, color in ipairs({
    Rhs2UiStyle.Palette.AvatarCyan,
    Rhs2UiStyle.Palette.TravelGold,
    Color3.fromRGB(218, 113, 201),
    Rhs2UiStyle.Palette.ProgressPurple,
    Color3.fromRGB(139, 159, 186),
    Rhs2UiStyle.Palette.ShopRed,
}) do
    local slot = Instance.new("Frame")
    slot.Name = "UtilitySlot" .. tostring(index)
    slot.LayoutOrder = index
    slot.Size = UDim2.fromOffset(20, 20)
    slot.BackgroundColor3 = color
    slot.Parent = utilityRail
    Rhs2UiStyle.applyQuickSlot(slot, color)
end

local quickBar = Instance.new("Frame")
quickBar.Name = "RHS2QuickBar"
quickBar.AnchorPoint = Vector2.new(0, 0)
quickBar.Position = UDim2.fromOffset(0, 0)
quickBar.Size = UDim2.fromOffset(216, 48)
quickBar.BackgroundTransparency = 1
quickBar.Parent = gui

local quickLayout = Instance.new("UIListLayout")
quickLayout.FillDirection = Enum.FillDirection.Horizontal
quickLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
quickLayout.Padding = UDim.new(0, 7)
quickLayout.Parent = quickBar

for index, slot in ipairs({
    { label = "", color = Color3.fromRGB(56, 177, 220) },
    { label = "", color = Color3.fromRGB(36, 45, 77) },
    { label = "", color = Color3.fromRGB(68, 195, 80) },
    { label = "", color = Color3.fromRGB(210, 83, 188) },
}) do
    local quickSlot = Instance.new("TextLabel")
    quickSlot.Name = "QuickSlot" .. tostring(index)
    quickSlot.Size = UDim2.fromOffset(52, 52)
    quickSlot.BackgroundColor3 = slot.color
    quickSlot.Font = Rhs2UiStyle.Font.Bold
    quickSlot.Text = slot.label
    quickSlot.TextColor3 = Color3.fromRGB(255, 255, 255)
    quickSlot.TextSize = 10
    quickSlot.Parent = quickBar
    Rhs2UiStyle.applyQuickSlot(quickSlot, slot.color)
end

local currentHudLayout = nil
local viewportConnection = nil
local housePanel
local editorPanel
local housePanelScale
local editorPanelScale
local modal
local modalScale
local outfitPanel = legacyOutfitSurface.panel
local outfitPanelScale = legacyOutfitSurface.panelScale
local shopPanel
local shopPanelScale
local travelPanel
local travelPanelScale
local cafeCard
local cafeCardScale
local vehicleCard
local vehicleCardScale

local function controlExclusionZones(viewportWidth, viewportHeight, insets)
    if not UserInputService.TouchEnabled then
        return {}
    end

    return ResponsiveHudLayout.touchExclusionZones(
        { width = viewportWidth, height = viewportHeight },
        insets
    )
end

local function applyResponsiveHudLayout()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    local viewport = camera.ViewportSize
    local insets = { left = 0, top = 0, right = 0, bottom = 0 }
    local insetOk, topLeftInset, bottomRightInset = pcall(function()
        return GuiService:GetGuiInset()
    end)
    if insetOk and topLeftInset and bottomRightInset then
        insets.left = topLeftInset.X
        insets.top = topLeftInset.Y
        insets.right = bottomRightInset.X
        insets.bottom = bottomRightInset.Y
    end

    local layout = ResponsiveHudLayout.compute(
        { width = viewport.X, height = viewport.Y },
        insets,
        controlExclusionZones(viewport.X, viewport.Y, insets)
    )
    local valid, reason = ResponsiveHudLayout.validate(layout)
    if not valid then
        warn("Compact HUD layout rejected: " .. tostring(reason))
        return
    end
    local auxiliaryPanels = ResponsiveHudLayout.computeAuxiliaryPanels(layout)
    local auxiliaryValid, auxiliaryReason = ResponsiveHudLayout.validateAuxiliaryPanels(layout, auxiliaryPanels)
    if not auxiliaryValid then
        warn("Auxiliary HUD layout rejected: " .. tostring(auxiliaryReason))
        return
    end
    local classModalLayout = ResponsiveHudLayout.computeCenteredModal(layout, {
        width = 540,
        height = 390,
    })
    local classModalValid, classModalReason = ResponsiveHudLayout.validateCenteredModal(layout, classModalLayout)
    if not classModalValid then
        warn("Class modal layout rejected: " .. tostring(classModalReason))
        return
    end
    local outfitModalLayout = ResponsiveHudLayout.computeCenteredModal(layout, {
        width = 286,
        height = 400,
    })
    local outfitModalValid, outfitModalReason = ResponsiveHudLayout.validateCenteredModal(layout, outfitModalLayout)
    if not outfitModalValid then
        warn("Outfit modal layout rejected: " .. tostring(outfitModalReason))
        return
    end
    local featureModalLayout = ResponsiveHudLayout.computeInteractionModal(layout, {
        width = 530,
        height = 354,
    })
    local featureModalValid, featureModalReason = ResponsiveHudLayout.validateInteractionModal(layout, featureModalLayout)
    if not featureModalValid then
        warn("Feature modal layout rejected: " .. tostring(featureModalReason))
        return
    end
    local cafeCardLayout = ResponsiveHudLayout.computeSafeFloatingCard(layout, {
        width = 260,
        height = 150,
    })
    local cafeCardValid, cafeCardReason = ResponsiveHudLayout.validateSafeFloatingCard(layout, cafeCardLayout)
    if not cafeCardValid then
        warn("Cafe card layout rejected: " .. tostring(cafeCardReason))
        return
    end
    local vehicleCardLayout = ResponsiveHudLayout.computeBottomCenteredCard(layout, {
        width = 260,
        height = 132,
    })
    local vehicleCardValid, vehicleCardReason = ResponsiveHudLayout.validateSafeFloatingCard(layout, vehicleCardLayout)
    if not vehicleCardValid then
        warn("Vehicle card layout rejected: " .. tostring(vehicleCardReason))
        return
    end
    currentHudLayout = layout

    card.Position = UDim2.fromOffset(layout.status.x, layout.status.y)
    card.Size = UDim2.fromOffset(layout.status.width, layout.status.height)
    actionRail.Position = UDim2.fromOffset(layout.rail.x, layout.rail.y)
    actionRail.Size = UDim2.fromOffset(layout.rail.width, layout.rail.height)
    quickBar.Position = UDim2.fromOffset(layout.quick.x, layout.quick.y)
    quickBar.Size = UDim2.fromOffset(layout.quick.width, layout.quick.height)

    if modal and modalScale then
        modal.Position = UDim2.fromOffset(classModalLayout.x, classModalLayout.y)
        modalScale.Scale = classModalLayout.scale
    end

    if outfitPanel and outfitPanelScale then
        outfitPanel.Position = UDim2.fromOffset(outfitModalLayout.x, outfitModalLayout.y)
        outfitPanelScale.Scale = outfitModalLayout.scale
    end

    if shopPanel and shopPanelScale then
        shopPanel.Position = UDim2.fromOffset(featureModalLayout.x, featureModalLayout.y)
        shopPanelScale.Scale = featureModalLayout.scale
    end
    if travelPanel and travelPanelScale then
        travelPanel.Position = UDim2.fromOffset(featureModalLayout.x, featureModalLayout.y)
        travelPanelScale.Scale = featureModalLayout.scale
    end

    if cafeCard and cafeCardScale then
        cafeCard.Position = UDim2.fromOffset(cafeCardLayout.x, cafeCardLayout.y)
        cafeCardScale.Scale = cafeCardLayout.scale
    end
    if vehicleCard and vehicleCardScale then
        vehicleCard.Position = UDim2.fromOffset(vehicleCardLayout.x, vehicleCardLayout.y)
        vehicleCardScale.Scale = vehicleCardLayout.scale
    end

    if housePanel and housePanelScale then
        housePanel.Position = UDim2.fromOffset(auxiliaryPanels.house.x, auxiliaryPanels.house.y)
        housePanelScale.Scale = auxiliaryPanels.house.scale
    end
    if editorPanel and editorPanelScale then
        editorPanel.Position = UDim2.fromOffset(auxiliaryPanels.editor.x, auxiliaryPanels.editor.y)
        editorPanelScale.Scale = auxiliaryPanels.editor.scale
    end

    title.Position = UDim2.fromOffset(0, 0)
    title.Size = UDim2.new(1, 0, 0, 17)
    title.TextSize = 11
    periodLabel.Position = UDim2.new(0, 6, 0, 18)
    periodLabel.Size = UDim2.new(1, -12, 0, 17)
    periodLabel.TextSize = 9
    statusLabel.Position = UDim2.new(0, 6, 0, 35)
    statusLabel.Size = UDim2.new(1, -12, 0, 15)
    statusLabel.TextSize = 8
    pointsLabel.Position = UDim2.new(0, 6, 0, 51)
    pointsLabel.Size = UDim2.new(0.42, -8, 0, 14)
    pointsLabel.TextSize = 8
    action.Position = UDim2.new(0.42, 0, 0, 50)
    action.Size = UDim2.new(0.58, -6, 0, 16)
    action.TextSize = 8

    actionRailLayout.Padding = UDim.new(0, layout.railGap)
    for _, child in ipairs(actionRail:GetChildren()) do
        if child:IsA("GuiButton") then
            child.Size = UDim2.fromOffset(layout.railButtonSize, layout.railButtonSize)
        end
    end

    local utilityGap = layout.railGap
    local utilityTileSize = math.floor((layout.rail.width - utilityGap) / 2)
    local utilityHeight = (utilityTileSize * 3) + (utilityGap * 2)
    local utilityY = layout.rail.bottom + utilityGap
    local utilityLimit = layout.quick.y - utilityGap
    for _, zone in ipairs(layout.exclusionZones or {}) do
        utilityLimit = math.min(utilityLimit, zone.y - utilityGap)
    end
    utilityRail.Position = UDim2.fromOffset(layout.rail.x, utilityY)
    utilityRail.Size = UDim2.fromOffset(layout.rail.width, utilityHeight)
    utilityRail.Visible = utilityY + utilityHeight <= utilityLimit
    utilityLayout.CellPadding = UDim2.fromOffset(utilityGap, utilityGap)
    utilityLayout.CellSize = UDim2.fromOffset(utilityTileSize, utilityTileSize)

    quickLayout.Padding = UDim.new(0, layout.quickGap)
    for _, child in ipairs(quickBar:GetChildren()) do
        if child:IsA("GuiObject") and child.Name:match("^QuickSlot") then
            child.Size = UDim2.fromOffset(layout.quickSlotSize, layout.quickSlotSize)
        end
    end
end

local function bindViewport(camera)
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveHudLayout)
    end
    applyResponsiveHudLayout()
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    bindViewport(Workspace.CurrentCamera)
end)
bindViewport(Workspace.CurrentCamera)

modal = Instance.new("Frame")
modal.Name = "ClassActivityModal"
modal.AnchorPoint = Vector2.new(0, 0)
modal.Position = UDim2.fromOffset(0, 0)
modal.Size = UDim2.fromOffset(540, 390)
modal.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
modal.Visible = false
modal.Parent = gui
Rhs2UiStyle.applyPrimaryPanel(modal)
modalScale = Instance.new("UIScale")
modalScale.Name = "ResponsiveScale"
modalScale.Scale = 1
modalScale.Parent = modal
applyResponsiveHudLayout()

local question = Instance.new("TextLabel")
question.BackgroundTransparency = 1
question.Position = UDim2.new(0, 18, 0, 16)
question.Size = UDim2.new(1, -36, 0, 92)
question.Font = Rhs2UiStyle.Font.Bold
question.Text = ""
question.TextColor3 = Rhs2UiStyle.Palette.White
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
feedback.Font = Rhs2UiStyle.Font.Regular
feedback.Text = ""
feedback.TextColor3 = Rhs2UiStyle.Palette.White
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
        button.BackgroundColor3 = Rhs2UiStyle.Palette.TabBlue
        button.Font = Rhs2UiStyle.Font.Bold
        button.Text = tostring(index) .. ".  " .. tostring(choiceText)
        button.TextColor3 = Rhs2UiStyle.Palette.White
        button.TextSize = 15
        button.TextWrapped = true
        button.Parent = choices
        Rhs2UiStyle.applyTab(button, false)

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

local function railInputKind()
    return UserInputService.TouchEnabled and "touch" or "mouse"
end

local function makeFeaturePanel(name, heading)
    local panel = Instance.new("Frame")
    panel.Name = name
    panel.AnchorPoint = Vector2.new(0, 0)
    panel.Position = UDim2.fromOffset(0, 0)
    panel.Size = UDim2.fromOffset(530, 354)
    panel.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
    panel.BackgroundTransparency = 0
    panel.Visible = false
    panel.Parent = gui
    Rhs2UiStyle.applyPrimaryPanel(panel)
    local panelScale = Instance.new("UIScale")
    panelScale.Name = "ResponsiveScale"
    panelScale.Scale = 1
    panelScale.Parent = panel
    local header = Instance.new("TextLabel")
    header.Name = "Heading"
    header.BackgroundColor3 = Rhs2UiStyle.Palette.HeaderBlue
    header.BorderSizePixel = 0
    header.Size = UDim2.new(0.78, 0, 0, 46)
    header.Font = Rhs2UiStyle.Font.Bold
    header.Text = "  " .. heading
    header.TextColor3 = Rhs2UiStyle.Palette.White
    header.TextSize = 20
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = panel
    Rhs2UiStyle.applyHeader(header)

    local headerTail = Instance.new("Frame")
    headerTail.Name = "HeaderTail"
    headerTail.AnchorPoint = Vector2.new(0.5, 0.5)
    headerTail.Position = UDim2.new(0.78, -8, 0, 23)
    headerTail.Size = UDim2.fromOffset(32, 32)
    headerTail.Rotation = 45
    headerTail.BorderSizePixel = 0
    headerTail.BackgroundColor3 = Rhs2UiStyle.Palette.HeaderBlue
    headerTail.Parent = panel
    Rhs2UiStyle.applyHeader(headerTail)

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -10, 0, 8)
    close.Size = UDim2.fromOffset(30, 30)
    close.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
    close.Font = Rhs2UiStyle.Font.Bold
    close.Text = "×"
    close.TextColor3 = Rhs2UiStyle.Palette.White
    close.TextSize = 19
    close.Parent = panel
    Rhs2UiStyle.applyCloseButton(close)

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(12, 58)
    body.Size = UDim2.new(1, -24, 1, -70)
    body.Parent = panel

    local back = Instance.new("TextButton")
    back.Name = "Back"
    back.AnchorPoint = Vector2.new(1, 0)
    back.Position = UDim2.new(1, -48, 0, 8)
    back.Size = UDim2.fromOffset(30, 30)
    back.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
    back.Font = Rhs2UiStyle.Font.Bold
    back.Text = "↩"
    back.TextColor3 = Rhs2UiStyle.Palette.White
    back.TextSize = 18
    back.Parent = panel
    Rhs2UiStyle.applyCloseButton(back)

    close.Activated:Connect(function()
        featurePanels:close("explicit_close")
    end)
    back.Activated:Connect(function()
        featurePanels:close("explicit_back")
    end)

    return panel, body, panelScale
end

local shopBody
shopPanel, shopBody, shopPanelScale = makeFeaturePanel("VerifiedStyleShopPanel", "STYLE SHOP")
shopPanel:SetAttribute("CatalogAuthority", "server-only")

local shopBrowse = Instance.new("TextLabel")
shopBrowse.Name = "Browse"
shopBrowse.BackgroundColor3 = Rhs2UiStyle.Palette.HeaderBlue
shopBrowse.Size = UDim2.new(0.42, -5, 1, 0)
shopBrowse.Font = Rhs2UiStyle.Font.Bold
shopBrowse.Text = "BROWSE\n\nClothing Display"
shopBrowse.TextColor3 = Rhs2UiStyle.Palette.White
shopBrowse.TextSize = 14
shopBrowse.TextWrapped = true
shopBrowse.Parent = shopBody
Rhs2UiStyle.applyDarkRow(shopBrowse)
shopBrowse.BackgroundColor3 = Rhs2UiStyle.Palette.HeaderBlue

local shopDetails = Instance.new("TextLabel")
shopDetails.Name = "Details"
shopDetails.Position = UDim2.new(0.42, 7, 0, 0)
shopDetails.Size = UDim2.new(0.58, -7, 1, 0)
shopDetails.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
shopDetails.Font = Rhs2UiStyle.Font.Regular
shopDetails.Text = "DETAILS\n\nNo verified clothing items are available yet."
shopDetails.TextColor3 = Rhs2UiStyle.Palette.White
shopDetails.TextSize = 13
shopDetails.TextWrapped = true
shopDetails.Parent = shopBody
Rhs2UiStyle.applyDarkRow(shopDetails)

local travelBody
travelPanel, travelBody, travelPanelScale = makeFeaturePanel("CurrentClassTravelPanel", "Travel")
travelPanel:SetAttribute("DestinationAuthority", "server-current-room-only")
applyResponsiveHudLayout()

local travelLocationsTab = Instance.new("TextButton")
travelLocationsTab.Name = "LocationsTab"
travelLocationsTab.Position = UDim2.fromOffset(120, 0)
travelLocationsTab.Size = UDim2.fromOffset(116, 32)
travelLocationsTab.Text = "Locations"
travelLocationsTab.TextSize = 14
travelLocationsTab.Active = false
travelLocationsTab.Parent = travelBody
Rhs2UiStyle.applyTab(travelLocationsTab, true)

local travelServersTab = Instance.new("TextButton")
travelServersTab.Name = "ServersTab"
travelServersTab.Position = UDim2.fromOffset(242, 0)
travelServersTab.Size = UDim2.fromOffset(116, 32)
travelServersTab.Text = "Servers"
travelServersTab.TextSize = 14
travelServersTab.Active = false
travelServersTab.AutoButtonColor = false
travelServersTab.Parent = travelBody
Rhs2UiStyle.applyTab(travelServersTab, false)

local travelGrid = Instance.new("Frame")
travelGrid.Name = "TravelDestinationGrid"
travelGrid.BackgroundTransparency = 1
travelGrid.Position = UDim2.fromOffset(0, 42)
travelGrid.Size = UDim2.new(1, 0, 0, 178)
travelGrid.Parent = travelBody

local travelGridLayout = Instance.new("UIGridLayout")
travelGridLayout.CellSize = UDim2.new(0.32, -4, 0, 82)
travelGridLayout.CellPadding = UDim2.new(0.02, 0, 0, 10)
travelGridLayout.FillDirectionMaxCells = 3
travelGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
travelGridLayout.Parent = travelGrid

local travelDestination = Instance.new("TextButton")
travelDestination.Name = "ServerCurrentRoom"
travelDestination.LayoutOrder = 1
travelDestination.BackgroundColor3 = Rhs2UiStyle.Palette.TabBlue
travelDestination.Font = Rhs2UiStyle.Font.Bold
travelDestination.Text = "CHECKING CURRENT CLASS..."
travelDestination.TextColor3 = Rhs2UiStyle.Palette.White
travelDestination.TextSize = 14
travelDestination.TextWrapped = true
travelDestination.Parent = travelGrid
Rhs2UiStyle.applyDarkRow(travelDestination)
travelDestination.BackgroundColor3 = Rhs2UiStyle.Palette.TabBlue
local travelDestinationStroke = outline(travelDestination, 2)
travelDestinationStroke.Color = Rhs2UiStyle.Palette.HeaderBlue

for index = 2, 6 do
    local placeholder = Instance.new("TextLabel")
    placeholder.Name = "UnavailableDestination" .. tostring(index)
    placeholder.LayoutOrder = index
    placeholder.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
    placeholder.Font = Rhs2UiStyle.Font.Medium
    placeholder.Text = "UNAVAILABLE"
    placeholder.TextColor3 = Color3.fromRGB(145, 163, 194)
    placeholder.TextSize = 11
    placeholder.Parent = travelGrid
    Rhs2UiStyle.applyDarkRow(placeholder)
    local placeholderStroke = outline(placeholder, 1)
    placeholderStroke.Color = Rhs2UiStyle.Palette.TabBlue
end

local travelStatus = Instance.new("TextLabel")
travelStatus.Name = "TravelStatus"
travelStatus.BackgroundTransparency = 1
travelStatus.Position = UDim2.new(0, 0, 0, 228)
travelStatus.Size = UDim2.new(1, 0, 1, -228)
travelStatus.Font = Rhs2UiStyle.Font.Regular
travelStatus.Text = "Select the server-provided current room to travel."
travelStatus.TextColor3 = Rhs2UiStyle.Palette.White
travelStatus.TextSize = 12
travelStatus.TextWrapped = true
travelStatus.Parent = travelBody

local function refreshTravelDestination()
    local roomName = latestClassState and latestClassState.roomDisplayName
    local available = latestClassState ~= nil and latestClassState.academic == true and roomName ~= nil
    travelDestination.Active = available
    travelDestination.AutoButtonColor = available
    if available then
        travelDestination.Text = tostring(roomName) .. "\nCURRENT CLASS"
        travelStatus.Text = "Current class is the only server-authorized destination in this build."
    else
        travelDestination.Text = "NO CURRENT CLASS\nUNAVAILABLE"
        travelStatus.Text = "Travel is unavailable outside a scheduled class."
    end
end

featurePanels:register("shop", {
    show = function()
        local confirmation = shoppingBoundary.consumeServerConfirmation()
        shopDetails.Text = confirmation and ("DETAILS\n\n" .. confirmation)
            or "DETAILS\n\nNo verified clothing items are available yet."
        shopPanel.Visible = true
        return true
    end,
    hide = function()
        shopPanel.Visible = false
    end,
})

local function ensureOutfitPanelControls(panel)
    if panel:FindFirstChild("FeaturePanelClose") then
        return
    end

    local close = Instance.new("TextButton")
    close.Name = "FeaturePanelClose"
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -4, 0, 4)
    close.Size = UDim2.fromOffset(28, 28)
    close.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
    close.Font = Rhs2UiStyle.Font.Bold
    close.Text = "×"
    close.TextColor3 = Rhs2UiStyle.Palette.White
    close.Parent = panel
    Rhs2UiStyle.applyCloseButton(close)

    local back = Instance.new("TextButton")
    back.Name = "FeaturePanelBack"
    back.AnchorPoint = Vector2.new(0.5, 1)
    back.Position = UDim2.new(0.5, 0, 1, -6)
    back.Size = UDim2.new(1, -12, 0, 30)
    back.BackgroundColor3 = Rhs2UiStyle.Palette.TabBlue
    back.Font = Rhs2UiStyle.Font.Bold
    back.Text = "↩  BACK"
    back.TextColor3 = Rhs2UiStyle.Palette.White
    back.Parent = panel
    Rhs2UiStyle.applyTab(back, false)

    close.Activated:Connect(function()
        featurePanels:close("explicit_close")
    end)
    back.Activated:Connect(function()
        featurePanels:close("explicit_back")
    end)
end

featurePanels:register("avatar", {
    show = function()
        local outfitPanel = findOutfitPanel()
        if not outfitPanel then
            statusLabel.Text = "Avatar controls are still loading."
            return false
        end
        ensureOutfitPanelControls(outfitPanel)
        outfitPanel.Visible = true
        return true
    end,
    hide = function()
        local outfitPanel = findOutfitPanel()
        if outfitPanel then
            outfitPanel.Visible = false
        end
    end,
})

featurePanels:register("travel", {
    show = function()
        refreshTravelDestination()
        travelPanel.Visible = true
        return true
    end,
    hide = function()
        travelPanel.Visible = false
    end,
})

shopRailButton.Activated:Connect(function()
    featurePanels:activate("shop", railInputKind())
end)

avatarRailButton.Activated:Connect(function()
    featurePanels:activate("avatar", railInputKind())
end)

travelRailButton.Activated:Connect(function()
    featurePanels:activate("travel", railInputKind())
end)

travelDestination.Activated:Connect(function()
    if busy or travelDestination.Active ~= true then return end
    busy = true
    travelDestination.Active = false
    travelStatus.Text = "Requesting travel..."
    local ok, response = pcall(function()
        -- The existing server boundary accepts no destination argument and owns
        -- the only supported destination: the current scheduled class room.
        return requestTravel:InvokeServer()
    end)
    busy = false
    if ok and type(response) == "table" and response.accepted == true then
        statusLabel.Text = "Traveling to " .. tostring(
            (latestClassState and latestClassState.roomDisplayName) or response.room or "current class"
        )
        featurePanels:close("travel_accepted")
    else
        featurePanels:restore("travel", "travel_denied")
        travelStatus.Text = "Travel is unavailable. You stayed in place; try again."
        refreshTravelDestination()
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
            title.Text = string.format("%s  %s", string.upper(string.sub(weekday, 1, 3)), timeText)
            periodLabel.Text = tostring(state.periodLabel)
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

cafeCard = Instance.new("Frame")
cafeCard.Name = "LegacyCafePanel"
cafeCard.AnchorPoint = Vector2.new(0, 0)
cafeCard.Position = UDim2.fromOffset(0, 0)
cafeCard.Size = UDim2.new(0, 260, 0, 150)
cafeCard.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
cafeCard.BackgroundTransparency = 0
cafeCard.Visible = false
cafeCard.Parent = gui
Rhs2UiStyle.applyPrimaryPanel(cafeCard)
cafeCardScale = Instance.new("UIScale")
cafeCardScale.Name = "ResponsiveScale"
cafeCardScale.Scale = 1
cafeCardScale.Parent = cafeCard

local cafeSizeConstraint = Instance.new("UISizeConstraint")
cafeSizeConstraint.MinSize = Vector2.new(260, 150)
cafeSizeConstraint.MaxSize = Vector2.new(330, 180)
cafeSizeConstraint.Parent = cafeCard
applyResponsiveHudLayout()

local cafeTitle = Instance.new("TextLabel")
cafeTitle.BackgroundTransparency = 0
cafeTitle.BackgroundColor3 = Rhs2UiStyle.Palette.HeaderBlue
cafeTitle.Position = UDim2.new(0, 0, 0, 0)
cafeTitle.Size = UDim2.new(1, 0, 0, 26)
cafeTitle.Font = Rhs2UiStyle.Font.Bold
cafeTitle.Text = "Corner Cafe"
cafeTitle.TextColor3 = Rhs2UiStyle.Palette.White
cafeTitle.TextSize = 14
cafeTitle.TextXAlignment = Enum.TextXAlignment.Center
cafeTitle.Parent = cafeCard
Rhs2UiStyle.applyHeader(cafeTitle)

local cafeStatus = Instance.new("TextLabel")
cafeStatus.BackgroundTransparency = 1
cafeStatus.Position = UDim2.new(0, 10, 0, 34)
cafeStatus.Size = UDim2.new(1, -20, 0, 48)
cafeStatus.Font = Rhs2UiStyle.Font.Regular
cafeStatus.Text = "Start a short cafe shift and serve one order."
cafeStatus.TextColor3 = Rhs2UiStyle.Palette.White
cafeStatus.TextSize = 13
cafeStatus.TextWrapped = true
cafeStatus.TextXAlignment = Enum.TextXAlignment.Left
cafeStatus.TextYAlignment = Enum.TextYAlignment.Top
cafeStatus.Parent = cafeCard

local cafeAction = Instance.new("TextButton")
cafeAction.Position = UDim2.new(0, 8, 1, -48)
cafeAction.Size = UDim2.new(1, -16, 0, 40)
cafeAction.BackgroundColor3 = Rhs2UiStyle.Palette.ActiveGold
cafeAction.Font = Rhs2UiStyle.Font.Bold
cafeAction.Text = "START SHIFT"
cafeAction.TextColor3 = Rhs2UiStyle.Palette.White
cafeAction.TextSize = 14
cafeAction.Parent = cafeCard
Rhs2UiStyle.applyTab(cafeAction, true)

local cafeLeave = Instance.new("TextButton")
cafeLeave.AnchorPoint = Vector2.new(1, 0)
cafeLeave.Position = UDim2.new(1, -8, 0, 28)
cafeLeave.Size = UDim2.new(0, 82, 0, 30)
cafeLeave.BackgroundTransparency = 1
cafeLeave.Font = Rhs2UiStyle.Font.Medium
cafeLeave.Text = "LEAVE JOB"
cafeLeave.TextColor3 = Rhs2UiStyle.Palette.White
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

vehicleCard = Instance.new("Frame")
vehicleCard.Name = "LegacyVehiclePanel"
vehicleCard.AnchorPoint = Vector2.new(0, 0)
vehicleCard.Position = UDim2.fromOffset(0, 0)
vehicleCard.Size = UDim2.new(0, 260, 0, 132)
vehicleCard.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
vehicleCard.BackgroundTransparency = 0
vehicleCard.Visible = false
vehicleCard.Parent = gui
Rhs2UiStyle.applyPrimaryPanel(vehicleCard)
vehicleCardScale = Instance.new("UIScale")
vehicleCardScale.Name = "ResponsiveScale"
vehicleCardScale.Scale = 1
vehicleCardScale.Parent = vehicleCard
applyResponsiveHudLayout()

local vehicleTitle = Instance.new("TextLabel")
vehicleTitle.BackgroundTransparency = 0
vehicleTitle.BackgroundColor3 = Rhs2UiStyle.Palette.HeaderBlue
vehicleTitle.Position = UDim2.new(0, 0, 0, 0)
vehicleTitle.Size = UDim2.new(1, 0, 0, 26)
vehicleTitle.Font = Rhs2UiStyle.Font.Bold
vehicleTitle.Text = "Auto Shop"
vehicleTitle.TextColor3 = Rhs2UiStyle.Palette.White
vehicleTitle.TextSize = 14
vehicleTitle.TextXAlignment = Enum.TextXAlignment.Center
vehicleTitle.Parent = vehicleCard
Rhs2UiStyle.applyHeader(vehicleTitle)

local vehicleStatus = Instance.new("TextLabel")
vehicleStatus.BackgroundTransparency = 1
vehicleStatus.Position = UDim2.new(0, 10, 0, 34)
vehicleStatus.Size = UDim2.new(1, -20, 0, 38)
vehicleStatus.Font = Rhs2UiStyle.Font.Regular
vehicleStatus.Text = "Spawn the starter car."
vehicleStatus.TextColor3 = Rhs2UiStyle.Palette.White
vehicleStatus.TextSize = 13
vehicleStatus.TextWrapped = true
vehicleStatus.TextXAlignment = Enum.TextXAlignment.Left
vehicleStatus.TextYAlignment = Enum.TextYAlignment.Top
vehicleStatus.Parent = vehicleCard

local vehicleAction = Instance.new("TextButton")
vehicleAction.Position = UDim2.new(0, 8, 1, -46)
vehicleAction.Size = UDim2.new(1, -16, 0, 38)
vehicleAction.BackgroundColor3 = Rhs2UiStyle.Palette.ActiveGold
vehicleAction.Font = Rhs2UiStyle.Font.Bold
vehicleAction.Text = "SPAWN STARTER CAR"
vehicleAction.TextColor3 = Rhs2UiStyle.Palette.White
vehicleAction.TextSize = 14
vehicleAction.Parent = vehicleCard
Rhs2UiStyle.applyTab(vehicleAction, true)

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
houseIcon.BackgroundColor3 = Rhs2UiStyle.Palette.HouseGreen
houseIcon.Font = Rhs2UiStyle.Font.Bold
houseIcon.Text = "HOUSE"
houseIcon.TextColor3 = Rhs2UiStyle.Palette.White
houseIcon.TextSize = 12
houseIcon.Parent = actionRail
Rhs2UiStyle.applyPrimaryRailButton(houseIcon, Rhs2UiStyle.Palette.HouseGreen)
applyResponsiveHudLayout()

housePanel = Instance.new("Frame")
housePanel.Name = "LegacyHousePanel"
housePanel.AnchorPoint = Vector2.new(0, 0)
housePanel.Position = UDim2.fromOffset(0, 0)
housePanel.Size = UDim2.new(0, 248, 0, 292)
housePanel.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
housePanel.BackgroundTransparency = 0
housePanel.Visible = false
housePanel.Parent = gui
Rhs2UiStyle.applyPrimaryPanel(housePanel)
housePanelScale = Instance.new("UIScale")
housePanelScale.Name = "ResponsiveScale"
housePanelScale.Scale = 1
housePanelScale.Parent = housePanel
local houseTitle = Instance.new("TextLabel")
houseTitle.BackgroundColor3 = Rhs2UiStyle.Palette.HeaderBlue
houseTitle.BorderSizePixel = 0
houseTitle.Size = UDim2.new(0.78, 0, 0, 28)
houseTitle.Font = Rhs2UiStyle.Font.Bold
houseTitle.Text = "  House"
houseTitle.TextColor3 = Rhs2UiStyle.Palette.White
houseTitle.TextSize = 15
houseTitle.TextXAlignment = Enum.TextXAlignment.Left
houseTitle.Parent = housePanel
Rhs2UiStyle.applyHeader(houseTitle)

local houseHeaderTail = Instance.new("Frame")
houseHeaderTail.Name = "HouseHeaderTail"
houseHeaderTail.AnchorPoint = Vector2.new(0.5, 0.5)
houseHeaderTail.Position = UDim2.new(0.78, -5, 0, 14)
houseHeaderTail.Size = UDim2.fromOffset(20, 20)
houseHeaderTail.Rotation = 45
houseHeaderTail.BorderSizePixel = 0
houseHeaderTail.BackgroundColor3 = Rhs2UiStyle.Palette.HeaderBlue
houseHeaderTail.Parent = housePanel
Rhs2UiStyle.applyHeader(houseHeaderTail)

local houseClose = Instance.new("TextButton")
houseClose.Name = "HouseClose"
houseClose.AnchorPoint = Vector2.new(1, 0)
houseClose.Position = UDim2.new(1, -3, 0, 2)
houseClose.Size = UDim2.fromOffset(26, 24)
houseClose.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
houseClose.Font = Rhs2UiStyle.Font.Bold
houseClose.Text = "×"
houseClose.TextColor3 = Rhs2UiStyle.Palette.White
houseClose.TextSize = 13
houseClose.Parent = housePanel
Rhs2UiStyle.applyCloseButton(houseClose)

local houseBack = Instance.new("TextButton")
houseBack.Name = "HouseBack"
houseBack.AnchorPoint = Vector2.new(0.5, 1)
houseBack.Position = UDim2.new(0.5, 0, 1, -5)
houseBack.Size = UDim2.new(1, -20, 0, 30)
houseBack.BackgroundColor3 = Rhs2UiStyle.Palette.TabBlue
houseBack.Font = Rhs2UiStyle.Font.Bold
houseBack.Text = "↩  BACK"
houseBack.TextColor3 = Rhs2UiStyle.Palette.White
houseBack.TextSize = 12
houseBack.Parent = housePanel
Rhs2UiStyle.applyTab(houseBack, false)

local houseStatus = Instance.new("TextLabel")
houseStatus.BackgroundTransparency = 1
houseStatus.Position = UDim2.new(0, 10, 0, 36)
houseStatus.Size = UDim2.new(1, -20, 0, 52)
houseStatus.Font = Rhs2UiStyle.Font.Regular
houseStatus.Text = "Loading house..."
houseStatus.TextColor3 = Rhs2UiStyle.Palette.White
houseStatus.TextSize = 13
houseStatus.TextWrapped = true
houseStatus.TextXAlignment = Enum.TextXAlignment.Left
houseStatus.TextYAlignment = Enum.TextYAlignment.Top
houseStatus.Parent = housePanel

local housePrimary = Instance.new("TextButton")
housePrimary.Name = "HousePrimaryAction"
housePrimary.Position = UDim2.new(0, 10, 0, 94)
housePrimary.Size = UDim2.new(1, -20, 0, 38)
housePrimary.BackgroundColor3 = Rhs2UiStyle.Palette.ActiveGold
housePrimary.Font = Rhs2UiStyle.Font.Bold
housePrimary.Text = "BUY HOUSE  •  $50"
housePrimary.TextColor3 = Rhs2UiStyle.Palette.White
housePrimary.TextSize = 13
housePrimary.Parent = housePanel
Rhs2UiStyle.applyTab(housePrimary, true)

local houseEdit = Instance.new("TextButton")
houseEdit.Name = "HouseEditAction"
houseEdit.Position = UDim2.new(0, 10, 0, 138)
houseEdit.Size = UDim2.new(1, -20, 0, 38)
houseEdit.BackgroundColor3 = Rhs2UiStyle.Palette.TabBlue
houseEdit.Font = Rhs2UiStyle.Font.Bold
houseEdit.Text = "EDIT HOUSE"
houseEdit.TextColor3 = Rhs2UiStyle.Palette.White
houseEdit.TextSize = 13
houseEdit.Visible = false
houseEdit.Parent = housePanel
Rhs2UiStyle.applyTab(houseEdit, false)

local houseColorLabel = Instance.new("TextLabel")
houseColorLabel.BackgroundTransparency = 1
houseColorLabel.Position = UDim2.new(0, 10, 0, 181)
houseColorLabel.Size = UDim2.new(1, -20, 0, 18)
houseColorLabel.Font = Rhs2UiStyle.Font.Bold
houseColorLabel.Text = "HOUSE COLOR"
houseColorLabel.TextColor3 = Rhs2UiStyle.Palette.White
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
    button.Font = Rhs2UiStyle.Font.Bold
    button.Text = spec.label
    button.TextColor3 = Rhs2UiStyle.Palette.Ink
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

featurePanels:register("house", {
    show = function()
        housePanel.Visible = true
        refreshHousing()
        return true
    end,
    hide = function()
        housePanel.Visible = false
        if editorPanel then
            editorPanel.Visible = false
        end
    end,
})

houseIcon.Activated:Connect(function()
    featurePanels:activate("house", railInputKind())
end)

houseClose.Activated:Connect(function()
    featurePanels:close("explicit_close")
end)

houseBack.Activated:Connect(function()
    featurePanels:close("explicit_back")
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or featurePanels:activeId() == nil then
        return
    end
    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
        featurePanels:close("input_back")
    end
end)

player.CharacterAdded:Connect(function()
    featurePanels:reset("respawn")
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
editorPanel = Instance.new("Frame")
editorPanel.Name = "LegacyHousingEditorV2"
editorPanel.AnchorPoint = Vector2.new(0, 0)
editorPanel.Position = UDim2.fromOffset(0, 0)
editorPanel.Size = UDim2.new(0, 330, 0, 346)
editorPanel.BackgroundColor3 = Rhs2UiStyle.Palette.ShellNavy
editorPanel.BackgroundTransparency = 0
editorPanel.Visible = false
editorPanel:SetAttribute("ReferenceExactLayout", false)
editorPanel:SetAttribute("ReferenceCoverage", "verified-labels-only")
editorPanel.Parent = gui
Rhs2UiStyle.applyPrimaryPanel(editorPanel)
editorPanelScale = Instance.new("UIScale")
editorPanelScale.Name = "ResponsiveScale"
editorPanelScale.Scale = 1
editorPanelScale.Parent = editorPanel
applyResponsiveHudLayout()

local editorTitle = Instance.new("TextLabel")
editorTitle.BackgroundColor3 = Rhs2UiStyle.Palette.HeaderBlue
editorTitle.BorderSizePixel = 0
editorTitle.Size = UDim2.new(1, 0, 0, 28)
editorTitle.Font = Rhs2UiStyle.Font.Bold
editorTitle.Text = "Add Furni"
editorTitle.TextColor3 = Rhs2UiStyle.Palette.White
editorTitle.TextSize = 15
editorTitle.Parent = editorPanel
Rhs2UiStyle.applyHeader(editorTitle)

local editorCategories = Instance.new("TextLabel")
editorCategories.BackgroundTransparency = 1
editorCategories.Position = UDim2.new(0, 10, 0, 34)
editorCategories.Size = UDim2.new(1, -20, 0, 20)
editorCategories.Font = Rhs2UiStyle.Font.Bold
editorCategories.Text = "Utilities   |   Other"
editorCategories.TextColor3 = Rhs2UiStyle.Palette.White
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
editorStatus.Font = Rhs2UiStyle.Font.Regular
editorStatus.Text = ""
editorStatus.Visible = false
editorStatus.TextColor3 = Rhs2UiStyle.Palette.White
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
    button.BackgroundColor3 = Rhs2UiStyle.Palette.TabBlue
    button.Font = Rhs2UiStyle.Font.Bold
    button.Text = label
    button.TextColor3 = Rhs2UiStyle.Palette.White
    button.TextSize = 11
    button.Parent = editorActions
    Rhs2UiStyle.applyTab(button, false)
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
hideWallsButton.BackgroundColor3 = Rhs2UiStyle.Palette.TabBlue
hideWallsButton.Font = Rhs2UiStyle.Font.Bold
hideWallsButton.Text = "Hide Walls"
hideWallsButton.TextColor3 = Rhs2UiStyle.Palette.White
hideWallsButton.TextSize = 11
hideWallsButton.Parent = editorPanel
Rhs2UiStyle.applyTab(hideWallsButton, false)

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
            and Rhs2UiStyle.Palette.ActiveGold
            or Rhs2UiStyle.Palette.TabBlue
        button.Font = Rhs2UiStyle.Font.Bold
        button.TextColor3 = Rhs2UiStyle.Palette.White
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
        Rhs2UiStyle.applyTab(button, item.itemId == selectedFurnitureItemId)
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
