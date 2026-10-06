-- Native-scale mobile presentation. No remotes, purchases or durable state.
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))
local Style = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Rhs2UiStyle"))
local Shell = {}

local function label(parent, name, text, size, position)
    local item = Instance.new("TextLabel")
    item.Name = name
    item.BackgroundTransparency = 1
    item.Text = text
    item.TextColor3 = Style.Palette.White
    item.Font = Style.Font.Bold
    item.TextSize = 16
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Size = size
    item.Position = position
    item.Parent = parent
    return item
end

local function closeButton(parent, callback)
    local button = Instance.new("TextButton")
    button.Name = "RecoveryClose"
    button.AnchorPoint = Vector2.new(1, 0)
    button.Position = UDim2.new(1, -6, 0, 4)
    button.Size = UDim2.fromOffset(44, 44)
    button.Text = "×"
    button.TextSize = 24
    button.ZIndex = 30
    button.Parent = parent
    Style.applyCloseButton(button)
    button.Activated:Connect(callback)
    return button
end

function Shell.mount(options)
    local api = { entries = {}, layout = nil, reflowing = false }
    local gui, player = options.gui, options.player
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local waypoint, waypointGui, waypointText, waypointLocation
    local elapsed = 0

    function api:guideTo(key)
        if waypoint then waypoint:Destroy() end
        if waypointGui then waypointGui:Destroy() end
        waypoint, waypointGui, waypointText, waypointLocation = nil, nil, nil, nil
        local location = SchoolConfig.WorldLocations[key]
        if not location then return end
        waypointLocation = location
        waypoint = Instance.new("Part")
        waypoint.Name = "LocalNavigationMarker"
        waypoint.Size = Vector3.new(1, 1, 1)
        waypoint.Anchored = true
        waypoint.CanCollide = false
        waypoint.CanQuery = false
        waypoint.CanTouch = false
        waypoint.Transparency = 1
        waypoint.Position = location.position + Vector3.new(0, 10, 0)
        waypoint.Parent = Workspace
        waypointGui = Instance.new("BillboardGui")
        waypointGui.Name = "NavigationMarker"
        waypointGui.Adornee = waypoint
        waypointGui.AlwaysOnTop = true
        waypointGui.Size = UDim2.fromOffset(190, 42)
        waypointGui.Parent = player:WaitForChild("PlayerGui")
        waypointText = label(waypointGui, "Destination", location.displayName, UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0))
        waypointText.TextXAlignment = Enum.TextXAlignment.Center
        waypointText.BackgroundColor3 = Style.Palette.ShellNavy
        waypointText.BackgroundTransparency = 0.08
        Style.applyDarkRow(waypointText)
    end

    local function restoreCamera(character)
        task.spawn(function()
            local humanoid = character:WaitForChild("Humanoid", 10)
            if character ~= player.Character or not humanoid then return end
            local camera = Workspace.CurrentCamera
            if camera then
                camera.CameraSubject = humanoid
                camera.CameraType = Enum.CameraType.Custom
                camera.FieldOfView = 70
            end
        end)
    end
    player.CameraMode = Enum.CameraMode.Classic
    player.CameraMinZoomDistance = 4
    player.CameraMaxZoomDistance = 20
    if options.touch then
        player:WaitForChild("PlayerGui").ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
    end
    local characterConnection = player.CharacterAdded:Connect(restoreCamera)
    if player.Character then restoreCamera(player.Character) end
    local cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if player.Character then restoreCamera(player.Character) end
    end)

    function api:reflow(layout)
        if self.reflowing then return end
        self.layout = layout or self.layout
        if not self.layout then return end
        self.reflowing = true
        local active
        for _, entry in ipairs(self.entries) do
            if entry.panel.Visible then active = entry end
        end
        for _, entry in ipairs(self.entries) do
            local safe = self.layout.safe
            local width = math.min(entry.width + 24, safe.width - 16)
            local bottom = safe.bottom
            for _, zone in ipairs(self.layout.exclusionZones or {}) do
                if zone.x < safe.x + (safe.width + width) / 2 and zone.right > safe.x + (safe.width - width) / 2 then
                    bottom = math.min(bottom, zone.y)
                end
            end
            local height = math.min(entry.height + 72, bottom - safe.y - 16)
            entry.shell.Position = UDim2.fromOffset(safe.x + (safe.width - width) / 2, safe.y + (bottom - safe.y - height) / 2)
            entry.shell.Size = UDim2.fromOffset(width, height)
            entry.shell.Visible = entry == active
            if entry == active then
                for _, card in ipairs(options.cards) do card.Visible = false end
            end
            entry.panel.AnchorPoint = Vector2.new(0, 0)
            entry.panel.Position = UDim2.fromOffset(8, 8)
            entry.scale.Scale = 1
            entry.scroll.CanvasSize = UDim2.fromOffset(entry.width + 16, entry.height + 16)
            entry.scroll.ScrollBarThickness = 5
            entry.hint.Visible = entry.height + 16 > height - 74
        end
        if options.touch then
            for _, item in ipairs(options.hud) do item.Visible = active == nil end
            local rail = gui:FindFirstChild("RHS2ActionRail")
            if rail and self.layout.railButtonSize < 44 then
                local bottom = self.layout.safe.bottom - 8
                for _, zone in ipairs(self.layout.exclusionZones or {}) do bottom = math.min(bottom, zone.y - 4) end
                rail.Size = UDim2.fromOffset(48, 188)
                rail.Position = UDim2.fromOffset(self.layout.safe.right - 56, math.max(self.layout.safe.y + 8, bottom - 188))
                local list = rail:FindFirstChildOfClass("UIListLayout")
                if list then list.Padding = UDim.new(0, 4) end
                for _, child in ipairs(rail:GetChildren()) do
                    if child:IsA("GuiButton") then child.Size = UDim2.fromOffset(44, 44) end
                end
            end
            local status = options.status
            if status then
                status.card.Position = UDim2.fromOffset(self.layout.safe.x + 8, self.layout.safe.y + 8)
                status.card.Size = UDim2.fromOffset(210, 96)
                status.title.Size = UDim2.new(1, 0, 0, 20)
                status.title.TextSize = 12
                status.period.Position = UDim2.fromOffset(8, 23)
                status.period.Size = UDim2.new(1, -16, 0, 20)
                status.period.TextSize = 14
                status.detail.Position = UDim2.fromOffset(8, 45)
                status.detail.Size = UDim2.new(1, -16, 0, 27)
                status.detail.TextSize = 11
                status.points.Position = UDim2.fromOffset(8, 76)
                status.points.Size = UDim2.new(1, -16, 0, 16)
                status.points.TextSize = 11
                status.action.Visible = false -- The 48px CLASS quick action is the touch entry.
            end
        end
        self.reflowing = false
    end

    if options.touch then
        for _, spec in ipairs(options.panels) do
            local panel = spec.panel
            local originalGui = panel:FindFirstAncestorOfClass("ScreenGui")
            if originalGui then originalGui.ScreenInsets = Enum.ScreenInsets.None end
            local outer = Instance.new("Frame")
            outer.Name = panel.Name .. "MobileShell"
            outer.Visible = false
            outer.ZIndex = 20
            outer.Active = true
            outer.ClipsDescendants = true
            outer.Parent = gui
            Style.applyPrimaryPanel(outer)
            label(outer, "ShellHeading", spec.title, UDim2.new(1, -70, 0, 44), UDim2.fromOffset(14, 4))
            local scroll = Instance.new("ScrollingFrame")
            scroll.Name = "NativeScaleContent"
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.Position = UDim2.fromOffset(4, 50)
            scroll.Size = UDim2.new(1, -8, 1, -74)
            scroll.ScrollingDirection = Enum.ScrollingDirection.XY
            scroll.Active = true
            scroll.Parent = outer
            local hint = label(outer, "ScrollHint", "Swipe to see more", UDim2.new(1, -24, 0, 16), UDim2.new(0, 12, 1, -20))
            hint.TextSize = 11
            hint.TextXAlignment = Enum.TextXAlignment.Center
            local entry = {
                panel = panel, scale = spec.scale, shell = outer,
                scroll = scroll, hint = hint,
                width = panel.Size.X.Offset, height = panel.Size.Y.Offset,
            }
            panel.Parent = scroll
            closeButton(outer, function()
                if spec.classPanel then options.classClose()
                else options.controller:close("explicit_close") end
                api:reflow()
            end)
            table.insert(api.entries, entry)
            panel:GetPropertyChangedSignal("Visible"):Connect(function()
                api:reflow()
            end)
        end
    end

    for _, card in ipairs(options.cards) do
        card:GetPropertyChangedSignal("Visible"):Connect(function()
            if not card.Visible then
                if api.focusedCard == card then api.focusedCard = nil end
                return
            end
            if card:GetAttribute("Dismissed") == true and card:GetAttribute("ManuallyOpened") ~= true then
                card.Visible = false
                return
            end
            if card:GetAttribute("ManuallyOpened") == true then card:SetAttribute("Dismissed", false) end
            for _, entry in ipairs(api.entries) do
                if entry.shell.Visible then card.Visible = false; return end
            end
            if api.focusedCard and api.focusedCard ~= card and card:GetAttribute("ManuallyOpened") ~= true then
                card.Visible = false
                return
            end
            api.focusedCard = card
            for _, other in ipairs(options.cards) do
                if other ~= card then
                    other:SetAttribute("ManuallyOpened", false)
                    other.Visible = false
                end
            end
        end)
        closeButton(card, function()
            card:SetAttribute("Dismissed", true)
            card:SetAttribute("ManuallyOpened", false)
            card.Visible = false
        end)
    end
    local connection = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < 0.5 or not waypointText or not waypointLocation then return end
        elapsed = 0
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            local distance = math.floor((root.Position - waypointLocation.position).Magnitude)
            waypointText.Text = waypointLocation.displayName .. "  ·  " .. tostring(distance) .. " studs"
        end
    end)
    gui.Destroying:Connect(function()
        connection:Disconnect()
        characterConnection:Disconnect()
        cameraConnection:Disconnect()
        if waypoint then waypoint:Destroy() end
        if waypointGui then waypointGui:Destroy() end
    end)
    return api
end
return Shell
