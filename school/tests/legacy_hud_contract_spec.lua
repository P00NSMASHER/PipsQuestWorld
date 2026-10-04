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
has('local bottomMargin = UserInputService.TouchEnabled and 112 or 12', "touch-safe bottom margin")
has('card.Name = "CompactSchoolStatus"', "compact school status")
has('card.AnchorPoint = Vector2.new(1, 0)', "top-right status anchor")
has('card.Position = UDim2.new(1, -76, 0, 12)', "status position beside rail")
has('title.Text = "SCHOOL DAY"', "compact status header")
has('actionRail.Name = "RHS2ActionRail"', "right-side action rail")
has('makeRailButton("RailShop", "SHOP"', "shop rail entry")
has('makeRailButton("RailAvatar", "AVATAR"', "avatar rail entry")
has('houseIcon.Parent = actionRail', "house rail entry")
has('makeRailButton("RailTravel", "TRAVEL"', "travel rail entry")
has('quickBar.Name = "RHS2QuickBar"', "bottom quick slots")
has('quickSlot.Name = "QuickSlot" .. tostring(index)', "quick-slot identity")
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
lacks('houseIcon.Parent = gui', "detached house control")

dofile("school/tests/avatar_customization_entry_spec.lua")
dofile("school/tests/avatar_customization_runtime_mount_spec.lua")
dofile("school/tests/outfit_operations_spec.lua")
dofile("school/tests/outfit_operations_runtime_spec.lua")
dofile("school/tests/shopping_purchase_authority_spec.lua")
dofile("school/tests/shopping_runtime_authority_spec.lua")

print("HIGH_SCHOOL_COMPACT_HUD_CONTRACT_PASS")
