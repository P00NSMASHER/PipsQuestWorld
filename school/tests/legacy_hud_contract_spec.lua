local path = "school/src/client/CanonicalSchoolClient.client.lua"
local file = assert(io.open(path, "r"))
local source = file:read("*a")
file:close()

local function has(fragment, label)
    if not source:find(fragment, 1, true) then
        error("missing compact HUD contract: " .. (label or fragment), 2)
    end
end

local function lacks(fragment, label)
    if source:find(fragment, 1, true) then
        error("forbidden compact HUD regression: " .. (label or fragment), 2)
    end
end

has('gui.Name = "RobloxHighSchoolLegacyUI"', "stable ScreenGui identity")
has('gui.IgnoreGuiInset = true', "safe-area inset ownership")
has('local ResponsiveHudLayout = require(shared:WaitForChild("ResponsiveHudLayout"))', "shared responsive layout contract")
has('card.Name = "CompactSchoolStatus"', "compact school status")
has('card.AnchorPoint = Vector2.new(0, 0)', "geometry contract status anchor")
has('title.Text = "SCHOOL DAY"', "compact status header")
has('actionRail.Name = "RHS2ActionRail"', "right-side action rail")
has('makeRailButton("RailShop", "SHOP"', "shop rail entry")
has('makeRailButton("RailAvatar", "AVATAR"', "avatar rail entry")
has('houseIcon.Parent = actionRail', "house rail entry")
has('makeRailButton("RailTravel", "TRAVEL"', "travel rail entry")
has('quickBar.Name = "RHS2QuickBar"', "bottom quick slots")
has('quickSlot.Name = "QuickSlot" .. tostring(index)', "quick-slot identity")
has('local function applyResponsiveHudLayout()', "responsive HUD reflow")
has('local camera = Workspace.CurrentCamera', "active viewport source")
has('return GuiService:GetGuiInset()', "device safe-area source")
has('ResponsiveHudLayout.compute(', "responsive geometry computation")
has('ResponsiveHudLayout.validate(layout)', "runtime geometry validation")
has('camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveHudLayout)', "viewport resize listener")
has('local LEGACY_BLUE = Color3.fromRGB(48, 104, 148)', "shared school palette")
has('cafeCard.Name = "LegacyCafePanel"', "cafe presentation preserved")
has('vehicleCard.Name = "LegacyVehiclePanel"', "vehicle presentation preserved")
has('local function formatLegacyClock(state)', "school clock/day presentation")
has('ContextActionService:BindAction(', "mobile/keyboard vehicle controls preserved")
has('submitAnswer:InvokeServer(', "class interaction preserved")
has('startCafeShift:InvokeServer()', "cafe interaction preserved")
has('spawnVehicle:InvokeServer()', "vehicle interaction preserved")
has('buyHouse:InvokeServer()', "housing server authority preserved")
has('requestTravel:InvokeServer()', "travel server authority preserved")
lacks('card.Position = UDim2.new(0, 12, 1, -bottomMargin)', "large bottom-left status card")
lacks('card.Position = UDim2.new(1, -76, 0, 12)', "fixed desktop status position")
lacks('actionRail.Position = UDim2.new(1, -12, 0, 12)', "fixed desktop rail position")
lacks('quickBar.Position = UDim2.new(0.5, 0, 1, -12)', "fixed desktop quickbar position")
lacks('houseIcon.Parent = gui', "detached house control")

dofile("school/tests/responsive_hud_layout_spec.lua")
dofile("school/tests/avatar_customization_entry_spec.lua")
dofile("school/tests/avatar_customization_runtime_mount_spec.lua")
dofile("school/tests/outfit_operations_spec.lua")
dofile("school/tests/outfit_operations_runtime_spec.lua")
dofile("school/tests/shopping_purchase_authority_spec.lua")
dofile("school/tests/shopping_runtime_authority_spec.lua")

print("HIGH_SCHOOL_COMPACT_HUD_CONTRACT_PASS")
