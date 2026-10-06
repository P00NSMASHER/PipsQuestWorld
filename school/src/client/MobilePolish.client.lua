local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not UserInputService.TouchEnabled then
    return
end

pcall(function()
    player.CameraMinZoomDistance = 7
    player.CameraMaxZoomDistance = 18
    player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("RobloxHighSchoolLegacyUI", 15)
if not gui then
    warn("MobilePolish: canonical school UI did not mount")
    return
end

local function ensureCorner(target, radius)
    local corner = target:FindFirstChild("MobilePolishCorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Name = "MobilePolishCorner"
        corner.Parent = target
    end
    corner.CornerRadius = UDim.new(0, radius)
end

local function ensureStroke(target, transparency)
    local stroke = target:FindFirstChild("MobilePolishStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Name = "MobilePolishStroke"
        stroke.Parent = target
    end
    stroke.Thickness = 1
    stroke.Transparency = transparency or 0.55
    stroke.Color = Color3.fromRGB(255, 255, 255)
end

local dock = Instance.new("Frame")
dock.Name = "PipHighMobileDock"
dock.AnchorPoint = Vector2.new(0.5, 1)
dock.Size = UDim2.fromOffset(342, 56)
dock.BackgroundColor3 = Color3.fromRGB(17, 23, 37)
dock.BackgroundTransparency = 0.08
dock.BorderSizePixel = 0
dock.ZIndex = 100
dock.Parent = gui
ensureCorner(dock, 18)
ensureStroke(dock, 0.72)

local dockPadding = Instance.new("UIPadding")
dockPadding.PaddingLeft = UDim.new(0, 8)
dockPadding.PaddingRight = UDim.new(0, 8)
dockPadding.PaddingTop = UDim.new(0, 6)
dockPadding.PaddingBottom = UDim.new(0, 6)
dockPadding.Parent = dock

local dockLayout = Instance.new("UIListLayout")
dockLayout.FillDirection = Enum.FillDirection.Horizontal
dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
dockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
dockLayout.Padding = UDim.new(0, 6)
dockLayout.SortOrder = Enum.SortOrder.LayoutOrder
dockLayout.Parent = dock

local function styleDockButton(button, order)
    button.Parent = dock
    button.LayoutOrder = order
    button.AnchorPoint = Vector2.new(0, 0)
    button.Position = UDim2.fromOffset(0, 0)
    button.Size = UDim2.fromOffset(60, 44)
    button.ZIndex = 101
    button.TextSize = 10
    button.TextWrapped = true
    button.AutoButtonColor = true
    ensureCorner(button, 13)
    ensureStroke(button, 0.72)
end

local moved = {}
local function moveCanonicalButtons()
    local actionRail = gui:FindFirstChild("RHS2ActionRail")
    if actionRail then
        actionRail.Visible = false
    end

    local specs = {
        { name = "RailShop", order = 1 },
        { name = "RailAvatar", order = 2 },
        { name = "LegacyHouseButton", order = 3 },
        { name = "RailTravel", order = 4 },
    }
    for _, spec in ipairs(specs) do
        local button = gui:FindFirstChild(spec.name, true)
        if button and button:IsA("GuiButton") and not moved[button] then
            moved[button] = true
            styleDockButton(button, spec.order)
        end
    end

    local statusCard = gui:FindFirstChild("CompactSchoolStatus")
    if statusCard then
        local classAction = statusCard:FindFirstChildOfClass("TextButton")
        if classAction and not moved[classAction] then
            moved[classAction] = true
            classAction.Name = "MobileClassAction"
            styleDockButton(classAction, 5)
        end
    end
end

local function safeInsets()
    local left, top, right, bottom = 47, 12, 47, 21
    local ok, topLeft, bottomRight = pcall(function()
        return GuiService:GetGuiInset()
    end)
    if ok and topLeft and bottomRight then
        left = math.max(left, topLeft.X)
        top = math.max(top, topLeft.Y)
        right = math.max(right, bottomRight.X)
        bottom = math.max(bottom, bottomRight.Y)
    end
    return left, top, right, bottom
end

local function polishPanel(panel)
    if not panel or not panel:IsA("GuiObject") then
        return
    end
    ensureCorner(panel, 14)
    ensureStroke(panel, 0.72)
    panel.ClipsDescendants = true
end

local panelNames = {
    "ClassActivityModal",
    "VerifiedStyleShopPanel",
    "CurrentClassTravelPanel",
    "LegacyHousePanel",
    "LegacyHousingEditorV2",
    "LegacyVehiclePanel",
}

local function applyMobileLayout()
    moveCanonicalButtons()

    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    pcall(function()
        camera.FieldOfView = 72
    end)

    local viewport = camera.ViewportSize
    local _, topInset, rightInset, bottomInset = safeInsets()

    dock.Position = UDim2.fromOffset(
        math.floor(viewport.X * 0.5),
        viewport.Y - bottomInset - 8
    )

    local utilityRail = gui:FindFirstChild("RHS2UtilityRail")
    if utilityRail then
        utilityRail.Visible = false
    end
    local quickBar = gui:FindFirstChild("RHS2QuickBar")
    if quickBar then
        quickBar.Visible = false
    end

    local card = gui:FindFirstChild("CompactSchoolStatus")
    if card then
        card.AnchorPoint = Vector2.new(0, 0)
        card.Position = UDim2.fromOffset(
            viewport.X - rightInset - 188,
            topInset + 8
        )
        card.Size = UDim2.fromOffset(180, 58)
        card.ZIndex = 90
        ensureCorner(card, 14)
        ensureStroke(card, 0.74)

        local schoolTitle = card:FindFirstChildWhichIsA("TextLabel")
        if schoolTitle then
            schoolTitle.Text = "PIP HIGH"
            schoolTitle.Position = UDim2.fromOffset(8, 4)
            schoolTitle.Size = UDim2.fromOffset(164, 16)
            schoolTitle.TextSize = 11
        end

        for _, child in ipairs(card:GetChildren()) do
            if child:IsA("TextLabel") and child ~= schoolTitle then
                child.TextSize = math.min(child.TextSize, 10)
            end
        end
    end

    for _, name in ipairs(panelNames) do
        polishPanel(gui:FindFirstChild(name, true))
    end
end

local cameraConnection
local function bindCamera(camera)
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
    if camera then
        cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            task.defer(applyMobileLayout)
        end)
    end
    task.defer(applyMobileLayout)
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    bindCamera(Workspace.CurrentCamera)
end)

gui.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("GuiButton") or descendant:IsA("Frame") then
        task.defer(applyMobileLayout)
    end
end)

bindCamera(Workspace.CurrentCamera)

task.spawn(function()
    for _ = 1, 20 do
        applyMobileLayout()
        task.wait(0.25)
    end
end)

RunService.Heartbeat:Connect(function()
    if Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView ~= 72 then
        Workspace.CurrentCamera.FieldOfView = 72
    end
end)
