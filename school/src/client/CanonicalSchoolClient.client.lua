local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")

local shared = ReplicatedStorage:WaitForChild("Shared")
local SchoolConfig = require(shared:WaitForChild("SchoolConfig"))
local LegacyOutfitEntry = require(shared:WaitForChild("LegacyOutfitEntry"))
local LegacyShoppingBoundary = require(shared:WaitForChild("LegacyShoppingBoundary"))
local ResponsiveHudLayout = require(shared:WaitForChild("ResponsiveHudLayout"))
local FeaturePanelController = require(shared:WaitForChild("FeaturePanelController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Pip High owns the compact top-right status surface. Roblox's stock player
-- list occupies the same space and can cover the status action and panel close
-- buttons, so keep that CoreGui surface disabled for this experience.
pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local outfitSurface = LegacyOutfitEntry(player, UserInputService)
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

local LEGACY_BLUE = Color3.fromRGB(48, 104, 148)
local LEGACY_BLUE_DARK = Color3.fromRGB(22, 73, 112)
local LEGACY_PANEL = Color3.fromRGB(193, 220, 238)
local LEGACY_BUTTON = Color3.fromRGB(235, 245, 250)
local auxiliaryPanelBottomMargin = UserInputService.TouchEnabled and 112 or 12

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
card.AnchorPoint = Vector2.new(0, 0)
card.Position = UDim2.fromOffset(0, 0)
card.Size = UDim2.fromOffset(118, 70)
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
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local cashLevelLabel = Instance.new("TextLabel")
cashLevelLabel.Name = "CashLevelLabel"
cashLevelLabel.BackgroundTransparency = 1
cashLevelLabel.Position = UDim2.new(0.55, 0, 0, 0)
cashLevelLabel.Size = UDim2.new(0.43, 0, 0, 24)
cashLevelLabel.Font = Enum.Font.ArialBold
cashLevelLabel.Text = "$--  •  LV 1"
cashLevelLabel.TextColor3 = Color3.fromRGB(255, 238, 171)
cashLevelLabel.TextSize = 10
cashLevelLabel.TextXAlignment = Enum.TextXAlignment.Right
cashLevelLabel.Parent = card

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

local quickSlotButtons = {}
for index, slot in ipairs({
    { label = "BAG", color = Color3.fromRGB(56, 177, 220) },
    { label = "JOBS", color = Color3.fromRGB(36, 45, 77) },
    { label = "PHONE", color = Color3.fromRGB(68, 195, 80) },
    { label = "ITEMS", color = Color3.fromRGB(210, 83, 188) },
}) do
    local quickSlot = Instance.new("TextButton")
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
    quickSlotButtons[index] = quickSlot
end

local featureController = FeaturePanelController.new({
    "shop",
    "avatar",
    "travel",
    "house",
    "bag",
    "jobs",
    "phone",
    "items",
    "job_result",
})
local featurePanels = {}
local educationModal = nil

local function registerFeaturePanel(name, panel, onOpen, onClose)
    featurePanels[name] = {
        panel = panel,
        onOpen = onOpen,
        onClose = onClose,
    }
    panel.Visible = false
end

local function renderFeaturePanels(snapshot)
    for name, descriptor in pairs(featurePanels) do
        local shouldShow = snapshot.active == name
        local wasVisible = descriptor.panel.Visible
        descriptor.panel.Visible = shouldShow
        if shouldShow and not wasVisible and descriptor.onOpen then
            descriptor.onOpen()
        elseif wasVisible and not shouldShow and descriptor.onClose then
            descriptor.onClose()
        end
    end
    gui:SetAttribute("ActiveFeaturePanel", snapshot.active or "")
end

local function closeFeaturePanels(reason)
    local result = featureController:reset(reason or "close_all")
    renderFeaturePanels(result)
    return result
end

local function openFeaturePanel(name, reason)
    if educationModal and educationModal.Visible then
        closeFeaturePanels("education_modal_active")
        statusLabel.Text = "Finish or leave the current class activity first."
        return { accepted = false, code = "education_modal_active" }
    end

    local result = featureController:open(name, reason or "feature_link")
    renderFeaturePanels(result)
    return result
end

local function toggleFeaturePanel(name, reason)
    if educationModal and educationModal.Visible then
        closeFeaturePanels("education_modal_active")
        statusLabel.Text = "Finish or leave the current class activity first."
        return { accepted = false, code = "education_modal_active" }
    end

    local result = featureController:toggle(name, reason or "rail")
    renderFeaturePanels(result)
    return result
end

local function makeFeaturePanel(name, heading)
    local panel = Instance.new("Frame")
    panel.Name = "FeaturePanel_" .. name
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    -- Leave a stable lane for the compact status card and right action rail.
    panel.Position = UDim2.fromScale(0.45, 0.52)
    panel.Size = UDim2.new(0.78, 0, 0.72, 0)
    panel.BackgroundColor3 = Color3.fromRGB(229, 241, 249)
    panel.BackgroundTransparency = 0.02
    panel.ZIndex = 20
    panel.Parent = gui
    round(panel, 10)
    local panelStroke = outline(panel, 2)
    panelStroke.Color = Color3.fromRGB(255, 255, 255)

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(280, 220)
    sizeConstraint.MaxSize = Vector2.new(560, 360)
    sizeConstraint.Parent = panel

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 46)
    header.BackgroundColor3 = LEGACY_BLUE
    header.BorderSizePixel = 0
    header.ZIndex = 21
    header.Parent = panel
    round(header, 10)

    local headerMask = Instance.new("Frame")
    headerMask.Name = "HeaderBottomMask"
    headerMask.Position = UDim2.new(0, 0, 1, -10)
    headerMask.Size = UDim2.new(1, 0, 0, 10)
    headerMask.BackgroundColor3 = LEGACY_BLUE
    headerMask.BorderSizePixel = 0
    headerMask.ZIndex = 21
    headerMask.Parent = header

    local headingLabel = Instance.new("TextLabel")
    headingLabel.Name = "Heading"
    headingLabel.BackgroundTransparency = 1
    headingLabel.Position = UDim2.fromOffset(16, 0)
    headingLabel.Size = UDim2.new(1, -70, 1, 0)
    headingLabel.Font = Enum.Font.GothamBold
    headingLabel.Text = heading
    headingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    headingLabel.TextSize = 20
    headingLabel.TextXAlignment = Enum.TextXAlignment.Left
    headingLabel.ZIndex = 22
    headingLabel.Parent = header

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "Close"
    closeButton.AnchorPoint = Vector2.new(1, 0.5)
    closeButton.Position = UDim2.new(1, -8, 0.5, 0)
    closeButton.Size = UDim2.fromOffset(34, 34)
    closeButton.BackgroundColor3 = Color3.fromRGB(216, 72, 72)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 16
    closeButton.ZIndex = 22
    closeButton.Parent = header
    round(closeButton, 8)

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundTransparency = 1
    body.Position = UDim2.fromOffset(14, 58)
    body.Size = UDim2.new(1, -28, 1, -72)
    body.ZIndex = 21
    body.Parent = panel

    closeButton.Activated:Connect(function()
        closeFeaturePanels("close_button")
    end)
    registerFeaturePanel(name, panel)
    return panel, body
end

ContextActionService:BindActionAtPriority(
    "ClosePipHighFeaturePanel",
    function(_, inputState)
        if inputState ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Pass
        end
        if featureController:snapshot().active == nil then
            return Enum.ContextActionResult.Pass
        end
        closeFeaturePanels("back")
        return Enum.ContextActionResult.Sink
    end,
    false,
    3000,
    Enum.KeyCode.Escape,
    Enum.KeyCode.ButtonB
)

player.CharacterAdded:Connect(function()
    closeFeaturePanels("respawn")
    if educationModal then
        educationModal.Visible = false
    end
end)

local currentHudLayout = nil
local viewportConnection = nil

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
    if not ResponsiveHudLayout.isSupportedViewport({
        width = viewport.X,
        height = viewport.Y,
    }) then
        -- Studio and device rotation can briefly expose a 1x1 camera. The
        -- viewport-change connection established by bindViewport will retry
        -- as soon as Roblox reports usable dimensions; never abort this
        -- LocalScript and strand every interaction that is mounted below.
        return
    end

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
    currentHudLayout = layout

    card.Position = UDim2.fromOffset(layout.status.x, layout.status.y)
    card.Size = UDim2.fromOffset(layout.status.width, layout.status.height)
    actionRail.Position = UDim2.fromOffset(layout.rail.x, layout.rail.y)
    actionRail.Size = UDim2.fromOffset(layout.rail.width, layout.rail.height)
    quickBar.Position = UDim2.fromOffset(layout.quick.x, layout.quick.y)
    quickBar.Size = UDim2.fromOffset(layout.quick.width, layout.quick.height)

    title.Position = UDim2.fromOffset(6, 0)
    title.Size = UDim2.new(0.54, -6, 0, 17)
    title.TextSize = 11
    cashLevelLabel.Position = UDim2.new(0.54, 0, 0, 0)
    cashLevelLabel.Size = UDim2.new(0.43, 0, 0, 17)
    cashLevelLabel.TextSize = 8
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

educationModal = Instance.new("Frame")
local modal = educationModal
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.45, 0.55)
modal.Size = UDim2.new(0.9, 0, 0, 390)
modal.BackgroundColor3 = LEGACY_PANEL
modal.Visible = false
modal.Parent = gui
round(modal, 2)
outline(modal, 2)
local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(280, 250)
constraint.MaxSize = Vector2.new(540, 430)
constraint.Parent = modal

local classUi = {
    themes = {
        Math = { title = "MATH LAB", color = Color3.fromRGB(52, 122, 167) },
        Art = { title = "ART STUDIO", color = Color3.fromRGB(169, 83, 151) },
        PE = { title = "P.E. DODGEBALL", color = Color3.fromRGB(213, 91, 75) },
        ScienceEngineering = { title = "SCIENCE & ENGINEERING", color = Color3.fromRGB(67, 150, 124) },
        PerformanceArts = { title = "PERFORMANCE ARTS", color = Color3.fromRGB(113, 87, 166) },
        Cooking = { title = "CULINARY LAB", color = Color3.fromRGB(218, 145, 61) },
        Dance = { title = "DANCE STUDIO", color = Color3.fromRGB(62, 170, 190) },
    },
}

classUi.header = Instance.new("Frame")
classUi.header.Size = UDim2.new(1, 0, 0, 44)
classUi.header.BackgroundColor3 = LEGACY_BLUE
classUi.header.BorderSizePixel = 0
classUi.header.Parent = modal

classUi.title = Instance.new("TextLabel")
classUi.title.BackgroundTransparency = 1
-- Leave a clear title lane beside Roblox's persistent top-left controls.
classUi.title.Position = UDim2.new(0, 76, 0, 0)
classUi.title.Size = UDim2.new(0.52, 0, 1, 0)
classUi.title.Font = Enum.Font.GothamBold
classUi.title.Text = "CLASS CHALLENGE"
classUi.title.TextColor3 = Color3.new(1, 1, 1)
classUi.title.TextSize = 16
classUi.title.TextXAlignment = Enum.TextXAlignment.Left
classUi.title.Parent = classUi.header

classUi.round = Instance.new("TextLabel")
classUi.round.BackgroundTransparency = 1
classUi.round.Position = UDim2.new(0.64, 0, 0, 0)
classUi.round.Size = UDim2.new(0.25, 0, 1, 0)
classUi.round.Font = Enum.Font.GothamBold
classUi.round.Text = "ROUND 1 / 3"
classUi.round.TextColor3 = Color3.new(1, 1, 1)
classUi.round.TextSize = 12
classUi.round.TextXAlignment = Enum.TextXAlignment.Right
classUi.round.Parent = classUi.header

classUi.leave = Instance.new("TextButton")
classUi.leave.AnchorPoint = Vector2.new(1, 0.5)
classUi.leave.Position = UDim2.new(1, -8, 0.5, 0)
classUi.leave.Size = UDim2.fromOffset(30, 30)
classUi.leave.BackgroundColor3 = Color3.fromRGB(222, 70, 70)
classUi.leave.Font = Enum.Font.GothamBold
classUi.leave.Text = "X"
classUi.leave.TextColor3 = Color3.new(1, 1, 1)
classUi.leave.TextSize = 14
classUi.leave.Parent = classUi.header
round(classUi.leave, 5)

local question = Instance.new("TextLabel")
question.BackgroundTransparency = 1
question.Position = UDim2.new(0, 18, 0, 56)
question.Size = UDim2.new(1, -36, 0, 64)
question.Font = Enum.Font.ArialBold
question.Text = ""
question.TextColor3 = LEGACY_BLUE_DARK
question.TextSize = 19
question.TextWrapped = true
question.TextYAlignment = Enum.TextYAlignment.Top
question.Parent = modal

local choices = Instance.new("ScrollingFrame")
choices.BackgroundTransparency = 1
choices.BorderSizePixel = 0
choices.Position = UDim2.new(0, 18, 0, 126)
choices.Size = UDim2.new(1, -36, 0, 188)
choices.AutomaticCanvasSize = Enum.AutomaticSize.Y
choices.CanvasSize = UDim2.fromOffset(0, 0)
choices.ScrollingDirection = Enum.ScrollingDirection.Y
choices.ScrollBarThickness = 4
choices.Parent = modal

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = choices

local feedback = Instance.new("TextLabel")
feedback.BackgroundTransparency = 1
feedback.Position = UDim2.new(0, 18, 1, -72)
feedback.Size = UDim2.new(1, -36, 0, 58)
feedback.Font = Enum.Font.Arial
feedback.Text = ""
feedback.TextColor3 = Color3.fromRGB(31, 72, 102)
feedback.TextSize = 13
feedback.TextWrapped = true
feedback.Parent = modal

classUi.ok = Instance.new("TextButton")
classUi.ok.Position = UDim2.new(0, 18, 1, -50)
classUi.ok.Size = UDim2.new(1, -36, 0, 36)
classUi.ok.BackgroundColor3 = Color3.fromRGB(55, 175, 211)
classUi.ok.Font = Enum.Font.GothamBold
classUi.ok.Text = "OK"
classUi.ok.TextColor3 = Color3.new(1, 1, 1)
classUi.ok.TextSize = 14
classUi.ok.Visible = false
classUi.ok.Parent = modal
round(classUi.ok, 7)

-- The class activity keeps its Legacy desktop composition, but reflows below
-- the height at which that composition would leave the screen. Answer rows
-- remain full-size touch targets and become vertically scrollable instead.
classUi.applyResponsiveLayout = function()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    if viewport.X <= 0 or viewport.Y <= 0 then return end

    if viewport.Y < 440 then
        local modalWidth
        local modalX
        if viewport.X < 386 then
            modalWidth = math.max(280, math.min(540, viewport.X - 20))
            modalX = 0.5
        else
            modalWidth = math.max(300, math.min(540, viewport.X - 86))
            modalX = 0.43
        end
        local modalHeight = math.max(250, math.min(390, viewport.Y - 20))

        modal.Position = UDim2.fromScale(modalX, 0.5)
        modal.Size = UDim2.fromOffset(modalWidth, modalHeight)
        classUi.header.Size = UDim2.new(1, 0, 0, 40)
        if modalWidth < 340 then
            classUi.title.Position = UDim2.new(0, 46, 0, 0)
            classUi.title.Size = UDim2.new(0.44, 0, 1, 0)
            classUi.title.TextSize = 11
            classUi.title.TextTruncate = Enum.TextTruncate.AtEnd
            classUi.round.Position = UDim2.new(0.62, 0, 0, 0)
            classUi.round.Size = UDim2.new(0.18, 0, 1, 0)
        else
            classUi.title.Position = UDim2.new(0, 54, 0, 0)
            classUi.title.Size = UDim2.new(0.52, 0, 1, 0)
            classUi.title.TextSize = 13
            classUi.title.TextTruncate = Enum.TextTruncate.None
            classUi.round.Position = UDim2.new(0.66, 0, 0, 0)
            classUi.round.Size = UDim2.new(0.2, 0, 1, 0)
        end
        classUi.round.TextSize = 10
        classUi.leave.Position = UDim2.new(1, -6, 0.5, 0)
        classUi.leave.Size = UDim2.fromOffset(38, 38)

        question.Position = UDim2.new(0, 12, 0, 48)
        question.Size = UDim2.new(1, -24, 0, classUi.ok.Visible and 64 or 52)
        question.TextSize = 14
        layout.Padding = UDim.new(0, 6)
        feedback.TextSize = 12

        if classUi.ok.Visible then
            choices.Visible = false
            feedback.Position = UDim2.new(0, 12, 0, 120)
            feedback.Size = UDim2.new(
                1,
                -24,
                0,
                math.max(68, math.min(120, modalHeight - 178))
            )
            classUi.ok.Position = UDim2.new(0, 12, 1, -48)
            classUi.ok.Size = UDim2.new(1, -24, 0, 38)
        else
            choices.Visible = true
            choices.Position = UDim2.new(0, 12, 0, 106)
            choices.Size = UDim2.new(1, -24, 0, math.max(72, modalHeight - 170))
            feedback.Position = UDim2.new(0, 12, 1, -56)
            feedback.Size = UDim2.new(1, -24, 0, 44)
            classUi.ok.Position = UDim2.new(0, 12, 1, -48)
            classUi.ok.Size = UDim2.new(1, -24, 0, 38)
        end
    else
        modal.Position = UDim2.fromScale(0.45, 0.55)
        modal.Size = UDim2.new(0.9, 0, 0, 390)
        classUi.header.Size = UDim2.new(1, 0, 0, 44)
        classUi.title.Position = UDim2.new(0, 76, 0, 0)
        classUi.title.Size = UDim2.new(0.52, 0, 1, 0)
        classUi.title.TextSize = 16
        classUi.title.TextTruncate = Enum.TextTruncate.None
        classUi.round.Position = UDim2.new(0.64, 0, 0, 0)
        classUi.round.Size = UDim2.new(0.25, 0, 1, 0)
        classUi.round.TextSize = 12
        classUi.leave.Position = UDim2.new(1, -8, 0.5, 0)
        classUi.leave.Size = UDim2.fromOffset(30, 30)
        question.Position = UDim2.new(0, 18, 0, 56)
        question.Size = UDim2.new(1, -36, 0, 64)
        question.TextSize = 19
        layout.Padding = UDim.new(0, 8)
        feedback.TextSize = 13
        classUi.ok.Position = UDim2.new(0, 18, 1, -50)
        classUi.ok.Size = UDim2.new(1, -36, 0, 36)

        if classUi.ok.Visible then
            choices.Visible = false
            feedback.Position = UDim2.new(0, 18, 0, 184)
            feedback.Size = UDim2.new(1, -36, 0, 120)
        else
            choices.Visible = true
            choices.Position = UDim2.new(0, 18, 0, 126)
            choices.Size = UDim2.new(1, -36, 0, 188)
            feedback.Position = UDim2.new(0, 18, 1, -72)
            feedback.Size = UDim2.new(1, -36, 0, 58)
        end
    end

    local choiceRightInset = viewport.Y < 440 and -6 or 0
    for _, child in ipairs(choices:GetChildren()) do
        if child:IsA("TextButton") then
            child.Size = UDim2.new(1, choiceRightInset, 0, 40)
        end
    end
end

classUi.bindViewport = function(camera)
    if classUi.viewportConnection then
        classUi.viewportConnection:Disconnect()
        classUi.viewportConnection = nil
    end
    if camera then
        classUi.viewportConnection = camera:GetPropertyChangedSignal("ViewportSize")
            :Connect(classUi.applyResponsiveLayout)
    end
    classUi.applyResponsiveLayout()
end

classUi.cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    classUi.bindViewport(Workspace.CurrentCamera)
end)
classUi.bindViewport(Workspace.CurrentCamera)

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
    local periodCount = tonumber(state.periodCount) or #SchoolConfig.Periods
    local totalDay = math.max(1, periodCount * SchoolConfig.PERIOD_SECONDS)
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
    player:SetAttribute("SchoolPoints", points)
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
    closeFeaturePanels("class_activity")
    activeClassKey = response.classKey or (latestClassState and latestClassState.classKey)
    activeActivity = response.activity
    pendingProgression = nil
    if not activeActivity then return end

    local theme = classUi.themes[activeActivity.subject] or {
        title = tostring(activeActivity.subject or "CLASS CHALLENGE"):upper(),
        color = LEGACY_BLUE,
    }
    classUi.header.BackgroundColor3 = theme.color
    classUi.title.Text = theme.title
    classUi.round.Text = string.format(
        "ROUND %d / %d",
        tonumber(response.round) or 1,
        tonumber(response.totalRounds) or 1
    )
    classUi.ok.Visible = false
    choices.Visible = true
    feedback.Position = UDim2.new(0, 18, 1, -72)
    feedback.Size = UDim2.new(1, -36, 0, 58)
    feedback.TextYAlignment = Enum.TextYAlignment.Center
    question.Text = tostring(activeActivity.prompt)
    feedback.Text = ""
    clearChoices()

    for index, choiceText in ipairs(activeActivity.choices or {}) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 40)
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
                activeActivity = nil
                clearChoices()
                choices.Visible = false
                classUi.round.Text = "COMPLETE"
                question.Text = string.format(
                    "%s COMPLETE\nFINAL GRADE: %s",
                    theme.title,
                    tostring(result.grade or "PASS")
                )
                feedback.Position = UDim2.new(0, 18, 0, 184)
                feedback.Size = UDim2.new(1, -36, 0, 120)
                feedback.TextYAlignment = Enum.TextYAlignment.Top
                feedback.Text = string.format(
                    "%d of %d challenges correct  •  +%d school points\nProgress saved • Total points: %d",
                    tonumber(result.correctCount) or (result.correct and 1 or 0),
                    tonumber(result.roundCount) or 1,
                    tonumber(result.awardedPoints) or 0,
                    points
                )
                classUi.ok.Visible = true
                classUi.applyResponsiveLayout()
            elseif result.nextActivity then
                feedback.Text = tostring(result.feedback or "Round complete!")
                busy = true
                task.delay(0.8, function()
                    showActivity({
                        classKey = activeClassKey,
                        activity = result.nextActivity,
                        round = result.round,
                        totalRounds = result.totalRounds,
                    })
                    busy = false
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

    classUi.applyResponsiveLayout()
    modal.Visible = true
end

classUi.ok.Activated:Connect(function()
    modal.Visible = false
end)

classUi.leave.Activated:Connect(function()
    if busy then return end
    busy = true
    local ok, result = pcall(function()
        leaveClass:InvokeServer()
    end)
    busy = false
    if not ok or type(result) ~= "table" then
        feedback.Text = "Could not leave class. Try again."
        return
    end
    if result.accepted == false then
        if result.code == "progression_pending" then
            feedback.Text = "Progress is still saving. Retry the same answer before leaving."
        else
            feedback.Text = tostring(result.message or result.code or "Could not leave class.")
        end
        return
    end
    activeActivity = nil
    modal.Visible = false
    statusLabel.Text = "Back in free roam."
end)

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
    if outfitSurface and outfitSurface.panel then
        if outfitSurface.entry then
            outfitSurface.entry.Visible = false
        end
        return outfitSurface.panel
    end
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

local function addPanelLabel(parent, name, text, position, size, textSize, bold)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Position = position
    label.Size = size
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = LEGACY_BLUE_DARK
    label.TextSize = textSize or 15
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.ZIndex = 22
    label.Parent = parent
    return label
end

local function addPanelAction(parent, name, text, position, size, color, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = color or LEGACY_BUTTON
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = color and Color3.fromRGB(255, 255, 255) or LEGACY_BLUE_DARK
    button.TextSize = 14
    button.TextWrapped = true
    button.ZIndex = 22
    button.Parent = parent
    round(button, 8)
    local buttonStroke = outline(button, 1)
    buttonStroke.Color = Color3.fromRGB(255, 255, 255)
    button.Activated:Connect(callback)
    return button
end

local shopPanel, shopBody = makeFeaturePanel("shop", "STYLE SHOP")
local shopStatus = addPanelLabel(
    shopBody,
    "Status",
    "Visit the Style Shop, then open your closet to manage saved outfits.",
    UDim2.fromOffset(8, 6),
    UDim2.new(1, -16, 0, 70),
    16,
    false
)
addPanelAction(
    shopBody,
    "VisitStyleShop",
    "VISIT STYLE SHOP",
    UDim2.new(0, 8, 0, 86),
    UDim2.new(0.48, -12, 0, 54),
    Color3.fromRGB(220, 66, 66),
    function()
        if busy then return end
        busy = true
        local ok, response = pcall(function()
            return requestTravel:InvokeServer("StyleShop")
        end)
        busy = false
        if ok and type(response) == "table" and response.accepted == true then
            shopStatus.Text = "Welcome to the Style Shop."
            statusLabel.Text = "Traveling to Style Shop"
            task.delay(0.25, function()
                closeFeaturePanels("travel_complete")
            end)
        else
            shopStatus.Text = "The Style Shop route is unavailable right now."
        end
    end
)
addPanelAction(
    shopBody,
    "OpenCloset",
    "OPEN AVATAR CLOSET",
    UDim2.new(0.52, 4, 0, 86),
    UDim2.new(0.48, -12, 0, 54),
    Color3.fromRGB(54, 174, 221),
    function()
        openFeaturePanel("avatar", "shop_link")
    end
)
addPanelLabel(
    shopBody,
    "CatalogNotice",
    "Only server-authorized clothing can appear here. No automatic purchases or hidden charges are performed.",
    UDim2.new(0, 8, 1, -64),
    UDim2.new(1, -16, 0, 54),
    12,
    false
)

local travelPanel, travelBody = makeFeaturePanel("travel", "TRAVEL")
addPanelLabel(
    travelBody,
    "Instruction",
    "Choose a destination",
    UDim2.fromOffset(8, 0),
    UDim2.new(1, -16, 0, 28),
    16,
    true
)
local travelGrid = Instance.new("Frame")
travelGrid.Name = "DestinationTiles"
travelGrid.BackgroundTransparency = 1
travelGrid.Position = UDim2.fromOffset(6, 32)
travelGrid.Size = UDim2.new(1, -12, 1, -66)
travelGrid.ZIndex = 22
travelGrid.Parent = travelBody
local destinationLayout = Instance.new("UIGridLayout")
destinationLayout.CellPadding = UDim2.fromOffset(8, 8)
destinationLayout.CellSize = UDim2.new(0.333, -6, 0.333, -6)
destinationLayout.FillDirectionMaxCells = 3
destinationLayout.SortOrder = Enum.SortOrder.LayoutOrder
destinationLayout.Parent = travelGrid
local travelStatus = addPanelLabel(
    travelBody,
    "TravelStatus",
    "",
    UDim2.new(0, 8, 1, -26),
    UDim2.new(1, -16, 0, 24),
    12,
    false
)
local destinationSpecs = {
    { key = "CurrentClass", label = "CURRENT CLASS", badge = "NOW", color = Color3.fromRGB(57, 126, 168) },
    { key = "SchoolEntrance", label = "PIP HIGH", badge = "PH", color = Color3.fromRGB(199, 62, 67) },
    { key = "TownCenter", label = "TOWN CENTER", badge = "TC", color = Color3.fromRGB(68, 152, 185) },
    { key = "Cafe", label = "CORNER CAFE", badge = "CF", color = Color3.fromRGB(194, 129, 58) },
    { key = "StyleShop", label = "STYLE SHOP", badge = "ST", color = Color3.fromRGB(151, 92, 173) },
    { key = "AutoShop", label = "AUTO SHOP", badge = "AU", color = Color3.fromRGB(74, 105, 142) },
    { key = "Market", label = "MARKET", badge = "MK", color = Color3.fromRGB(83, 161, 104) },
    { key = "Neighborhood", label = "NEIGHBORHOOD", badge = "HM", color = Color3.fromRGB(187, 99, 83) },
    { key = "TownPark", label = "TOWN PARK", badge = "PK", color = Color3.fromRGB(75, 144, 91) },
}
for index, spec in ipairs(destinationSpecs) do
    local tile = Instance.new("TextButton")
    tile.Name = "Destination_" .. spec.key
    tile.LayoutOrder = index
    tile.BackgroundColor3 = spec.color
    tile.Font = Enum.Font.GothamBold
    tile.Text = spec.label
    tile.TextColor3 = Color3.fromRGB(255, 255, 255)
    tile.TextSize = 12
    tile.TextWrapped = true
    tile.TextXAlignment = Enum.TextXAlignment.Left
    tile.TextYAlignment = Enum.TextYAlignment.Bottom
    tile.ZIndex = 23
    tile:SetAttribute("DestinationKey", spec.key)
    tile:SetAttribute("UsesOriginalGeneratedArtwork", true)
    tile.Parent = travelGrid
    round(tile, 9)
    local tilePadding = Instance.new("UIPadding")
    tilePadding.PaddingLeft = UDim.new(0, 9)
    tilePadding.PaddingBottom = UDim.new(0, 6)
    tilePadding.Parent = tile
    local tileGradient = Instance.new("UIGradient")
    tileGradient.Color = ColorSequence.new(
        spec.color:Lerp(Color3.new(1, 1, 1), 0.18),
        spec.color:Lerp(Color3.new(0, 0, 0), 0.12)
    )
    tileGradient.Rotation = 90
    tileGradient.Parent = tile
    local badge = Instance.new("TextLabel")
    badge.Name = "DestinationBadge"
    badge.Position = UDim2.fromOffset(8, 7)
    badge.Size = UDim2.fromOffset(spec.badge == "NOW" and 38 or 28, 22)
    badge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    badge.BackgroundTransparency = 0.78
    badge.Font = Enum.Font.GothamBold
    badge.Text = spec.badge
    badge.TextColor3 = Color3.fromRGB(255, 255, 255)
    badge.TextSize = 10
    badge.ZIndex = 24
    badge.Parent = tile
    round(badge, 6)
    tile.Activated:Connect(function()
        if busy then return end
        busy = true
        travelStatus.Text = "Traveling..."
        local ok, response = pcall(function()
            return requestTravel:InvokeServer(spec.key)
        end)
        busy = false
        if ok and type(response) == "table" and response.accepted == true then
            local destinationName = response.destinationDisplayName or spec.label
            statusLabel.Text = "Traveling to " .. tostring(destinationName)
            task.delay(0.2, function()
                closeFeaturePanels("travel_complete")
            end)
        else
            travelStatus.Text = "That destination is unavailable. Try again."
        end
    end)
end

local bagPanel, bagBody = makeFeaturePanel("bag", "BACKPACK")
addPanelLabel(
    bagBody,
    "BackpackCopy",
    "Your saved outfits, house furniture, and equipped vehicle stay in their verified feature menus.",
    UDim2.fromOffset(10, 8),
    UDim2.new(1, -20, 0, 68),
    16,
    false
)
addPanelAction(bagBody, "ClosetShortcut", "AVATAR CLOSET", UDim2.new(0, 10, 0, 86), UDim2.new(0.47, -10, 0, 52), Color3.fromRGB(54, 174, 221), function()
    openFeaturePanel("avatar", "backpack_link")
end)
addPanelAction(bagBody, "HouseShortcut", "HOUSE ITEMS", UDim2.new(0.53, 0, 0, 86), UDim2.new(0.47, -10, 0, 52), Color3.fromRGB(83, 188, 77), function()
    openFeaturePanel("house", "backpack_link")
end)

local jobsPanel, jobsBody = makeFeaturePanel("jobs", "AFTER-SCHOOL JOBS")
addPanelLabel(
    jobsBody,
    "JobsCopy",
    "Earn play-cash through short, replayable shifts. Travel to a workplace, then use its on-site controls.",
    UDim2.fromOffset(10, 8),
    UDim2.new(1, -20, 0, 66),
    15,
    false
)
addPanelAction(jobsBody, "CafeJobShortcut", "CORNER CAFE  •  $25", UDim2.new(0, 10, 0, 82), UDim2.new(1, -20, 0, 52), Color3.fromRGB(194, 129, 58), function()
    if busy then return end
    busy = true
    local ok, response = pcall(function()
        return requestTravel:InvokeServer("Cafe")
    end)
    busy = false
    if ok and type(response) == "table" and response.accepted == true then
        statusLabel.Text = "Traveling to the Corner Cafe"
        closeFeaturePanels("job_travel")
    end
end)
addPanelAction(jobsBody, "MarketJobShortcut", "MARKET STOCK  •  $45", UDim2.new(0, 10, 0, 146), UDim2.new(1, -20, 0, 52), Color3.fromRGB(83, 161, 104), function()
    if busy then return end
    busy = true
    local ok, response = pcall(function()
        return requestTravel:InvokeServer("Market")
    end)
    busy = false
    if ok and type(response) == "table" and response.accepted == true then
        statusLabel.Text = "Traveling to the Market stock station"
        closeFeaturePanels("job_travel")
    end
end)

local phonePanel, phoneBody = makeFeaturePanel("phone", "PHONE")
addPanelLabel(phoneBody, "PhoneCopy", "Quick access", UDim2.fromOffset(10, 6), UDim2.new(1, -20, 0, 30), 16, true)
for index, spec in ipairs({
    { key = "travel", label = "TRAVEL", color = Color3.fromRGB(235, 177, 49) },
    { key = "avatar", label = "AVATAR", color = Color3.fromRGB(54, 174, 221) },
    { key = "house", label = "HOUSE", color = Color3.fromRGB(83, 188, 77) },
    { key = "shop", label = "SHOP", color = Color3.fromRGB(220, 66, 66) },
}) do
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)
    addPanelAction(
        phoneBody,
        "Phone_" .. spec.key,
        spec.label,
        UDim2.new(column * 0.5, 10 - (column * 2), 0, 48 + (row * 68)),
        UDim2.new(0.5, -18, 0, 56),
        spec.color,
        function()
            openFeaturePanel(spec.key, "phone_link")
        end
    )
end

local itemsPanel, itemsBody = makeFeaturePanel("items", "ITEMS")
addPanelLabel(
    itemsBody,
    "ItemsCopy",
    "No quick item is equipped. Furniture can be placed from Edit House mode; vehicles are managed at the Auto Shop.",
    UDim2.fromOffset(10, 8),
    UDim2.new(1, -20, 0, 82),
    16,
    false
)
addPanelAction(itemsBody, "TravelAutoShop", "GO TO AUTO SHOP", UDim2.new(0, 10, 0, 100), UDim2.new(1, -20, 0, 52), Color3.fromRGB(74, 105, 142), function()
    if busy then return end
    busy = true
    local ok, response = pcall(function()
        return requestTravel:InvokeServer("AutoShop")
    end)
    busy = false
    if ok and type(response) == "table" and response.accepted == true then
        statusLabel.Text = "Traveling to Auto Shop"
        closeFeaturePanels("travel_complete")
    end
end)

local jobResultPanel, jobResultBody = makeFeaturePanel("job_result", "SHIFT COMPLETE")
local jobResultSummary = addPanelLabel(
    jobResultBody,
    "Performance",
    "ORDER SERVED",
    UDim2.fromOffset(10, 4),
    UDim2.new(1, -20, 0, 42),
    20,
    true
)
local jobResultDetails = addPanelLabel(
    jobResultBody,
    "Rewards",
    "",
    UDim2.fromOffset(10, 54),
    UDim2.new(1, -20, 0, 116),
    15,
    false
)
addPanelAction(
    jobResultBody,
    "DismissResult",
    "OK",
    UDim2.new(0, 10, 1, -58),
    UDim2.new(1, -20, 0, 48),
    Color3.fromRGB(54, 174, 221),
    function()
        closeFeaturePanels("job_result_ok")
    end
)

local function showCafeJobResult(response)
    local wage = tonumber(response and response.wage) or 25
    local balance = response and response.economyState and response.economyState.balance
    jobResultSummary.Text = "ORDER SERVED  •  GREAT WORK!"
    jobResultDetails.Text = string.format(
        "EARNINGS\n+$%d%s\n\nSCHOOL POINTS\n%d\n\nBONUS GIFT\nNone this shift",
        wage,
        type(balance) == "number" and ("  •  Balance $" .. tostring(balance)) or "",
        points
    )
    openFeaturePanel("job_result", "cafe_complete")
end

local outfitPanel = findOutfitPanel()
if outfitPanel then
    local outfitGui = outfitPanel:FindFirstAncestorOfClass("ScreenGui")
    if outfitGui then
        outfitGui.DisplayOrder = 20
    end
    outfitPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    outfitPanel.Position = UDim2.fromScale(0.45, 0.52)
    outfitPanel.Size = UDim2.new(0.78, 0, 0.72, 0)
    outfitPanel.BackgroundColor3 = Color3.fromRGB(229, 241, 249)
    -- The legacy outfit controls use their default child ZIndex. Keep the
    -- panel itself at the default layer and raise the ScreenGui instead;
    -- otherwise the panel background covers its own controls.
    outfitPanel.ZIndex = 1
    local outfitConstraint = Instance.new("UISizeConstraint")
    outfitConstraint.MinSize = Vector2.new(280, 260)
    outfitConstraint.MaxSize = Vector2.new(560, 430)
    outfitConstraint.Parent = outfitPanel
    local outfitClose = Instance.new("TextButton")
    outfitClose.Name = "Close"
    outfitClose.AnchorPoint = Vector2.new(1, 0)
    outfitClose.Position = UDim2.new(1, -8, 0, 8)
    outfitClose.Size = UDim2.fromOffset(34, 34)
    outfitClose.BackgroundColor3 = Color3.fromRGB(216, 72, 72)
    outfitClose.Font = Enum.Font.GothamBold
    outfitClose.Text = "X"
    outfitClose.TextColor3 = Color3.fromRGB(255, 255, 255)
    outfitClose.TextSize = 16
    outfitClose.ZIndex = 30
    outfitClose.Parent = outfitPanel
    round(outfitClose, 8)
    outfitClose.Activated:Connect(function()
        closeFeaturePanels("avatar_close")
    end)
    registerFeaturePanel("avatar", outfitPanel, function()
        if outfitSurface and outfitSurface.refresh then
            outfitSurface.refresh()
        end
    end)
end

shopRailButton.Activated:Connect(function()
    local confirmation = shoppingBoundary.consumeServerConfirmation()
    if confirmation then
        shopStatus.Text = confirmation
    end
    toggleFeaturePanel("shop", "rail")
end)

avatarRailButton.Activated:Connect(function()
    if findOutfitPanel() then
        toggleFeaturePanel("avatar", "rail")
    else
        statusLabel.Text = "Avatar controls are still loading."
    end
end)

travelRailButton.Activated:Connect(function()
    travelStatus.Text = ""
    toggleFeaturePanel("travel", "rail")
end)

quickSlotButtons[1].Activated:Connect(function()
    toggleFeaturePanel("bag", "quick_slot")
end)
quickSlotButtons[2].Activated:Connect(function()
    toggleFeaturePanel("jobs", "quick_slot")
end)
quickSlotButtons[3].Activated:Connect(function()
    toggleFeaturePanel("phone", "quick_slot")
end)
quickSlotButtons[4].Activated:Connect(function()
    toggleFeaturePanel("items", "quick_slot")
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
cafeCard.Name = "LegacyCafePanel"
cafeCard.AnchorPoint = Vector2.new(1, 1)
cafeCard.Position = UDim2.new(1, -12, 1, -auxiliaryPanelBottomMargin)
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
cafeLeave.AnchorPoint = Vector2.new(1, 0.5)
cafeLeave.Position = UDim2.new(1, -6, 0, 13)
cafeLeave.Size = UDim2.new(0, 72, 0, 20)
cafeLeave.BackgroundTransparency = 1
cafeLeave.Font = Enum.Font.Arial
cafeLeave.Text = "LEAVE JOB"
cafeLeave.TextColor3 = Color3.fromRGB(255, 255, 255)
cafeLeave.TextSize = 9
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
    cafeCard.Visible = (active or atCafe)
        and featureController:snapshot().active == nil
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
        cafeCard.Visible = featureController:snapshot().active == nil
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
        showCafeJobResult(response)
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
vehicleCard.AnchorPoint = Vector2.new(0.5, 0.5)
vehicleCard.Position = UDim2.fromScale(0.45, 0.52)
vehicleCard.Size = UDim2.new(0.72, 0, 0.64, 0)
vehicleCard.BackgroundColor3 = LEGACY_PANEL
vehicleCard.BackgroundTransparency = 0.02
vehicleCard.Visible = false
vehicleCard.Parent = gui
round(vehicleCard, 2)
outline(vehicleCard, 2)

local vehicleShowroom = (function()
    local surface = Instance.new("Frame")
    surface.Name = "DealerView"
    surface.BackgroundTransparency = 1
    surface.Position = UDim2.fromOffset(14, 54)
    surface.Size = UDim2.new(1, -28, 1, -70)
    surface.Parent = vehicleCard

    local preview = Instance.new("Frame")
    preview.Name = "VehiclePreview"
    preview.Size = UDim2.new(0.49, -6, 1, 0)
    preview.BackgroundColor3 = Color3.fromRGB(241, 246, 250)
    preview.Parent = surface
    round(preview, 8)

    local floor = Instance.new("Frame")
    floor.AnchorPoint = Vector2.new(0.5, 1)
    floor.Position = UDim2.fromScale(0.5, 0.9)
    floor.Size = UDim2.new(0.86, 0, 0, 10)
    floor.BackgroundColor3 = Color3.fromRGB(185, 204, 216)
    floor.BorderSizePixel = 0
    floor.Parent = preview
    round(floor, 5)

    local carBody = Instance.new("Frame")
    carBody.AnchorPoint = Vector2.new(0.5, 0.5)
    carBody.Position = UDim2.fromScale(0.5, 0.64)
    carBody.Size = UDim2.new(0.68, 0, 0, 48)
    carBody.BackgroundColor3 = Color3.fromRGB(220, 66, 66)
    carBody.BorderSizePixel = 0
    carBody.Parent = preview
    round(carBody, 12)

    local roof = Instance.new("Frame")
    roof.AnchorPoint = Vector2.new(0.5, 1)
    roof.Position = UDim2.fromScale(0.5, 0.18)
    roof.Size = UDim2.new(0.48, 0, 0, 28)
    roof.BackgroundColor3 = Color3.fromRGB(57, 126, 168)
    roof.BorderSizePixel = 0
    roof.Parent = carBody
    round(roof, 8)

    for _, xScale in ipairs({ 0.22, 0.78 }) do
        local wheel = Instance.new("Frame")
        wheel.AnchorPoint = Vector2.new(0.5, 0.5)
        wheel.Position = UDim2.fromScale(xScale, 0.96)
        wheel.Size = UDim2.fromOffset(24, 24)
        wheel.BackgroundColor3 = Color3.fromRGB(35, 44, 53)
        wheel.BorderSizePixel = 0
        wheel.Parent = carBody
        round(wheel, 12)
    end

    local details = Instance.new("TextLabel")
    details.Name = "BrowseDetails"
    details.Position = UDim2.new(0.51, 6, 0, 0)
    details.Size = UDim2.new(0.49, -6, 1, 0)
    details.BackgroundColor3 = Color3.fromRGB(57, 126, 168)
    details.Font = Enum.Font.Gotham
    details.Text = "BROWSE VEHICLES\n\nSTARTER CAR\nReliable town runabout\n\nPRICE\nFREE"
    details.TextColor3 = Color3.fromRGB(255, 255, 255)
    details.TextSize = 14
    details.TextWrapped = true
    details.TextYAlignment = Enum.TextYAlignment.Top
    details.Parent = surface
    round(details, 8)

    return surface
end)()

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

local vehicleClose = Instance.new("TextButton")
vehicleClose.Name = "CloseDealer"
vehicleClose.AnchorPoint = Vector2.new(1, 0.5)
vehicleClose.Position = UDim2.new(1, -7, 0, 23)
vehicleClose.Size = UDim2.fromOffset(34, 34)
vehicleClose.BackgroundColor3 = Color3.fromRGB(216, 72, 72)
vehicleClose.Font = Enum.Font.GothamBold
vehicleClose.Text = "X"
vehicleClose.TextColor3 = Color3.fromRGB(255, 255, 255)
vehicleClose.TextSize = 16
vehicleClose.Parent = vehicleCard
round(vehicleClose, 8)

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
local vehicleShopDismissed = false

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

    -- Keep the four touch buttons in the center lane.  Roblox reserves the
    -- lower corners for its movement stick and camera controls, so placing
    -- drive controls there makes steering unreliable on a phone.
    ContextActionService:SetPosition(VEHICLE_FORWARD, UDim2.new(0.5, -30, 1, -220))
    ContextActionService:SetPosition(VEHICLE_REVERSE, UDim2.new(0.5, -30, 1, -96))
    ContextActionService:SetPosition(VEHICLE_LEFT, UDim2.new(0.5, -92, 1, -158))
    ContextActionService:SetPosition(VEHICLE_RIGHT, UDim2.new(0.5, 32, 1, -158))

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

vehicleClose.Activated:Connect(function()
    vehicleShopDismissed = true
    vehicleCard.Visible = false
    actionRail.Visible = true
    quickBar.Visible = true
end)

local function applyVehicleState(state)
    if type(state) ~= "table" then
        return
    end

    latestVehicleState = state
    if state.atAutoShop ~= true then
        vehicleShopDismissed = false
    end
    local dealershipOpen = state.atAutoShop == true
        and state.active ~= true
        and vehicleShopDismissed ~= true
    vehicleCard.Visible = (state.active == true or dealershipOpen)
        and featureController:snapshot().active == nil
    actionRail.Visible = not dealershipOpen
    quickBar.Visible = not dealershipOpen
    -- Driving gets a dedicated, unobstructed control mode.  Hiding the
    -- free-roam HUD leaves the center lane clear for the touch controls above.
    if state.driving == true then
        actionRail.Visible = false
        quickBar.Visible = false
    end
    vehicleShowroom.Visible = dealershipOpen
    vehicleClose.Visible = dealershipOpen

    if dealershipOpen then
        local camera = Workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(909, 483)
        local compactDealer = viewport.X < 620 or viewport.Y < 440

        vehicleCard.AnchorPoint = Vector2.new(0.5, 0.5)
        if compactDealer then
            vehicleCard.Position = UDim2.fromScale(0.5, 0.5)
            vehicleCard.Size = UDim2.fromOffset(
                math.max(280, math.min(560, viewport.X - 24)),
                math.max(250, math.min(380, viewport.Y - 16))
            )
            vehicleTitle.Size = UDim2.new(1, 0, 0, 40)
            vehicleTitle.TextSize = 15
        else
            vehicleCard.Position = UDim2.fromScale(0.45, 0.52)
            vehicleCard.Size = UDim2.new(0.72, 0, 0.64, 0)
            vehicleTitle.Size = UDim2.new(1, 0, 0, 46)
            vehicleTitle.TextSize = 18
        end
        vehicleTitle.Font = Enum.Font.GothamBold
        -- The preview/details area ends above a dedicated status/action lane;
        -- this prevents the dealer CTA from covering the vehicle details.
        vehicleShowroom.Position = UDim2.fromOffset(14, 54)
        vehicleShowroom.Size = UDim2.new(1, -28, 1, -150)
        local browseDetails = vehicleShowroom:FindFirstChild("BrowseDetails")
        if browseDetails and browseDetails:IsA("TextLabel") then
            browseDetails.TextSize = compactDealer and 11 or 14
        end
        vehicleStatus.Position = UDim2.new(0, 18, 1, -96)
        vehicleStatus.Size = UDim2.new(1, -36, 0, 32)
        vehicleStatus.Font = Enum.Font.Gotham
        vehicleStatus.TextSize = compactDealer and 11 or 13
        vehicleStatus.TextYAlignment = Enum.TextYAlignment.Center
        vehicleAction.Position = UDim2.new(0, 18, 1, -52)
        vehicleAction.Size = UDim2.new(1, -36, 0, 44)
        vehicleAction.Font = Enum.Font.GothamBold
        vehicleAction.TextSize = compactDealer and 12 or 14
    else
        vehicleCard.AnchorPoint = Vector2.new(0.5, 1)
        vehicleCard.Position = UDim2.new(0.5, 0, 1, -auxiliaryPanelBottomMargin)
        vehicleCard.Size = UDim2.fromOffset(300, 148)
        vehicleTitle.Size = UDim2.new(1, 0, 0, 26)
        vehicleTitle.Font = Enum.Font.ArialBold
        vehicleTitle.TextSize = 14
        vehicleShowroom.Position = UDim2.fromOffset(14, 54)
        vehicleShowroom.Size = UDim2.new(1, -28, 1, -70)
        vehicleStatus.Position = UDim2.new(0, 10, 0, 34)
        vehicleStatus.Size = UDim2.new(1, -20, 0, 48)
        vehicleStatus.Font = Enum.Font.Arial
        vehicleStatus.TextSize = 13
        vehicleStatus.TextYAlignment = Enum.TextYAlignment.Top
        vehicleAction.Position = UDim2.new(0, 8, 1, -46)
        vehicleAction.Size = UDim2.new(1, -16, 0, 38)
        vehicleAction.Font = Enum.Font.ArialBold
        vehicleAction.TextSize = 14
    end

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
            vehicleStatus.Text = dealershipOpen
                and "Preview the free starter car, then spawn it on the street."
                or "Spawn the starter car and drive around town."
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
        vehicleCard.Visible = featureController:snapshot().active == nil
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
applyResponsiveHudLayout()

local housePanel = Instance.new("Frame")
housePanel.Name = "LegacyHousePanel"
housePanel.AnchorPoint = Vector2.new(0.5, 0.5)
housePanel.Position = UDim2.fromScale(0.5, 0.52)
housePanel.Size = UDim2.fromOffset(300, 280)
housePanel.BackgroundColor3 = LEGACY_PANEL
housePanel.BackgroundTransparency = 0.02
housePanel.Visible = false
housePanel.Parent = gui
round(housePanel, 2)
outline(housePanel, 2)

local houseTitle = Instance.new("TextLabel")
houseTitle.BackgroundColor3 = LEGACY_BLUE
houseTitle.BorderSizePixel = 0
houseTitle.Size = UDim2.new(1, 0, 0, 36)
houseTitle.Font = Enum.Font.ArialBold
houseTitle.Text = "House"
houseTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
houseTitle.TextSize = 15
houseTitle.Parent = housePanel

local houseClose = Instance.new("TextButton")
houseClose.Name = "Close"
houseClose.AnchorPoint = Vector2.new(1, 0.5)
houseClose.Position = UDim2.new(1, -6, 0, 18)
houseClose.Size = UDim2.fromOffset(28, 28)
houseClose.BackgroundColor3 = Color3.fromRGB(216, 72, 72)
houseClose.Font = Enum.Font.GothamBold
houseClose.Text = "X"
houseClose.TextColor3 = Color3.fromRGB(255, 255, 255)
houseClose.TextSize = 14
houseClose.Parent = housePanel
round(houseClose, 7)
houseClose.Activated:Connect(function()
    closeFeaturePanels("house_close")
end)

local editorPanel = nil

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

registerFeaturePanel("house", housePanel, refreshHousing, function()
    if editorPanel then
        editorPanel.Visible = false
    end
end)

houseIcon.Activated:Connect(function()
    toggleFeaturePanel("house", "rail")
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
-- Keep the editor in its own function scope so the main client bootstrap stays
-- comfortably below Luau's 200-local register limit.
local function mountHousingEditor()
editorPanel = Instance.new("Frame")
editorPanel.Name = "LegacyHousingEditorV2"
editorPanel.AnchorPoint = Vector2.new(0.5, 1)
editorPanel.Position = UDim2.new(0.5, -24, 1, -(auxiliaryPanelBottomMargin + 66))
editorPanel.Size = UDim2.new(1, -32, 0, 346)
editorPanel.BackgroundColor3 = LEGACY_PANEL
editorPanel.BackgroundTransparency = 0.02
editorPanel.Visible = false
editorPanel:SetAttribute("ReferenceExactLayout", false)
editorPanel:SetAttribute("ReferenceCoverage", "original-functional-catalog")
editorPanel.Parent = gui
local editorSizeConstraint = Instance.new("UISizeConstraint")
editorSizeConstraint.MinSize = Vector2.new(240, 260)
editorSizeConstraint.MaxSize = Vector2.new(330, 346)
editorSizeConstraint.Parent = editorPanel
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
editorCategories.Text = "Seating  •  Tables  •  Decor  •  Lights  •  Storage  •  Beds"
editorCategories.TextColor3 = LEGACY_BLUE_DARK
editorCategories.TextSize = 12
editorCategories.TextXAlignment = Enum.TextXAlignment.Left
editorCategories.Parent = editorPanel

local editorCatalog = Instance.new("ScrollingFrame")
editorCatalog.BackgroundTransparency = 1
editorCatalog.Position = UDim2.new(0, 10, 0, 58)
editorCatalog.Size = UDim2.new(1, -20, 0, 98)
editorCatalog.AutomaticCanvasSize = Enum.AutomaticSize.Y
editorCatalog.CanvasSize = UDim2.fromOffset(0, 0)
editorCatalog.ScrollBarThickness = 5
editorCatalog.BorderSizePixel = 0
editorCatalog.Parent = editorPanel

local editorCatalogLayout = Instance.new("UIListLayout")
editorCatalogLayout.Padding = UDim.new(0, 4)
editorCatalogLayout.Parent = editorCatalog

local editorStatus = Instance.new("TextLabel")
editorStatus.BackgroundTransparency = 1
editorStatus.Position = UDim2.new(0, 10, 0, 160)
editorStatus.Size = UDim2.new(1, -20, 0, 38)
editorStatus.Font = Enum.Font.Arial
editorStatus.Text = ""
editorStatus.Visible = true
editorStatus.TextColor3 = LEGACY_BLUE_DARK
editorStatus.TextSize = 12
editorStatus.TextWrapped = true
editorStatus.TextXAlignment = Enum.TextXAlignment.Left
editorStatus.TextYAlignment = Enum.TextYAlignment.Top
editorStatus.Parent = editorPanel

local editorActions = Instance.new("Frame")
editorActions.BackgroundTransparency = 1
editorActions.Position = UDim2.new(0, 10, 0, 204)
editorActions.Size = UDim2.new(1, -20, 0, 112)
editorActions.Visible = true
editorActions:SetAttribute("ReferenceExact", false)
editorActions:SetAttribute("OriginalControls", true)
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

local buyFurni = editorButton("BuyFurniture", "BUY +1")
local placeFurni = editorButton("PlaceFurniture", "PLACE")
local moveFurni = editorButton("MoveFurniture", "MOVE")
local rotateFurni = editorButton("RotateFurniture", "ROTATE")
local removeFurni = editorButton("RemoveFurniture", "REMOVE")
local sellFurni = editorButton("SellFurniture", "SELL")
local paintFurni = editorButton("PaintFurniture", "PAINT")
-- The editor deliberately owns its own save control. On compact layouts the
-- catalog can overlap the House panel, so a player must never lose the way
-- to leave edit mode and preserve their changes.
local saveHouseEdit = editorButton("SaveHouse", "SAVE HOUSE")

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

-- On a short phone screen, keep every editor action inside the viewport and
-- leave a right-hand lane to the underlying House panel's Save/Close controls.
-- Taller desktop windows retain the verified two-column composition above.
local editorViewportConnection = nil
local function applyEditorResponsiveLayout()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    if viewport.X <= 0 or viewport.Y <= 0 then return end

    local compact = viewport.Y < 380
        or viewport.X < 420
        or (UserInputService.TouchEnabled and viewport.Y < 560)
    if compact then
        local portrait = viewport.Y >= viewport.X
        local panelWidth = portrait
            and math.max(240, math.min(280, viewport.X - 80))
            or math.max(260, math.min(330, viewport.X - 212))
        local panelHeight = math.max(260, math.min(320, viewport.Y - 16))
        local catalogHeight = math.max(48, math.min(72, panelHeight - 220))
        local statusY = 52 + catalogHeight + 4
        local actionsY = statusY + 34

        editorPanel.AnchorPoint = Vector2.new(0.5, 0.5)
        editorPanel.Position = UDim2.fromOffset(8 + (panelWidth / 2), viewport.Y / 2)
        editorPanel.Size = UDim2.fromOffset(panelWidth, panelHeight)
        editorTitle.Size = UDim2.new(1, 0, 0, 28)
        editorCategories.Position = UDim2.new(0, 10, 0, 32)
        editorCategories.Size = UDim2.new(1, -20, 0, 16)
        editorCategories.TextScaled = true
        editorCatalog.Position = UDim2.new(0, 10, 0, 52)
        editorCatalog.Size = UDim2.new(1, -20, 0, catalogHeight)
        editorCatalog.ScrollBarThickness = 6
        editorStatus.Position = UDim2.new(0, 10, 0, statusY)
        editorStatus.Size = UDim2.new(1, -20, 0, 30)
        editorStatus.TextSize = 11
        editorActions.Position = UDim2.new(0, 10, 0, actionsY)
        editorActions.Size = UDim2.new(1, -20, 0, 76)
        editorGrid.CellSize = UDim2.new(0.25, -4, 0, 36)
        editorGrid.CellPadding = UDim2.new(0, 4, 0, 4)
        hideWallsButton.Position = UDim2.new(0, 10, 1, -42)
        hideWallsButton.Size = UDim2.new(1, -20, 0, 34)
    else
        editorPanel.AnchorPoint = Vector2.new(0.5, 1)
        editorPanel.Position = UDim2.new(0.5, -24, 1, -(auxiliaryPanelBottomMargin + 66))
        editorPanel.Size = UDim2.new(1, -32, 0, 346)
        editorTitle.Size = UDim2.new(1, 0, 0, 28)
        editorCategories.Position = UDim2.new(0, 10, 0, 34)
        editorCategories.Size = UDim2.new(1, -20, 0, 20)
        editorCategories.TextScaled = false
        editorCategories.TextSize = 12
        editorCatalog.Position = UDim2.new(0, 10, 0, 58)
        editorCatalog.Size = UDim2.new(1, -20, 0, 98)
        editorCatalog.ScrollBarThickness = 5
        editorStatus.Position = UDim2.new(0, 10, 0, 160)
        editorStatus.Size = UDim2.new(1, -20, 0, 38)
        editorStatus.TextSize = 12
        editorActions.Position = UDim2.new(0, 10, 0, 204)
        editorActions.Size = UDim2.new(1, -20, 0, 112)
        editorGrid.CellSize = UDim2.new(0, 96, 0, 32)
        editorGrid.CellPadding = UDim2.new(0, 5, 0, 5)
        hideWallsButton.Position = UDim2.new(0, 10, 1, -40)
        hideWallsButton.Size = UDim2.new(1, -20, 0, 30)
    end
end

local function bindEditorViewport(camera)
    if editorViewportConnection then
        editorViewportConnection:Disconnect()
        editorViewportConnection = nil
    end
    if camera then
        editorViewportConnection = camera:GetPropertyChangedSignal("ViewportSize")
            :Connect(applyEditorResponsiveLayout)
    end
    applyEditorResponsiveLayout()
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    bindEditorViewport(Workspace.CurrentCamera)
end)
bindEditorViewport(Workspace.CurrentCamera)

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
        if item.itemId == itemId
            and (item.originalContent == true or item.referenceExact == true) then
            return item
        end
    end
    return nil
end

local function firstExactCatalogItemId(state)
    for _, item in ipairs((state and state.catalog) or {}) do
        if item.originalContent == true or item.referenceExact == true then
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
    -- A missing response is transport-uncertain: retain the same idempotency
    -- key so a retry cannot double-charge or duplicate furniture.
    if type(response) == "table" and response.retryable ~= true then
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
    for itemIndex, item in ipairs(state.catalog or {}) do
        if item.originalContent == true or item.referenceExact == true then
        local button = Instance.new("TextButton")
        button.Name = "Catalog_" .. tostring(item.itemId)
        button.LayoutOrder = itemIndex
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

    hideWallsButton.Text = state.hideWalls == true and "SHOW WALLS" or "HIDE WALLS"
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
    elseif response.code == "placement_limit_reached" then
        editorStatus.Text = "Your house is full. Remove an item before placing another."
    elseif response.code == "insufficient_funds" then
        editorStatus.Text = "Earn more play-cash before buying this item."
    elseif response.code == "insufficient_inventory" then
        editorStatus.Text = "Buy this item before placing or selling it."
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

saveHouseEdit.Activated:Connect(function()
    if editorBusy or not latestHousingState or latestHousingState.editing ~= true then
        return
    end

    editorBusy = true
    saveHouseEdit.Active = false
    local ok, response = pcall(function()
        return setHouseEditMode:InvokeServer(false)
    end)
    editorBusy = false
    saveHouseEdit.Active = true

    if ok and type(response) == "table" and response.accepted == true then
        setHousingMessage("House saved.")
        applyHousingState(response)
        editorPanel.Visible = false
    else
        editorStatus.Text = "Could not save house right now."
    end
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
        task.wait(2.0)
    end
end)
end

mountHousingEditor()
