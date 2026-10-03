local path = "school/src/client/CanonicalSchoolClient.client.lua"
local file = assert(io.open(path, "r"))
local source = file:read("*a")
file:close()

local function has(fragment, label)
    if not source:find(fragment, 1, true) then
        error("missing legacy HUD contract: " .. (label or fragment), 2)
    end
end

local function lacks(fragment, label)
    if source:find(fragment, 1, true) then
        error("forbidden legacy HUD regression: " .. (label or fragment), 2)
    end
end

has('gui.Name = "RobloxHighSchoolLegacyUI"', "legacy ScreenGui identity")
has('local bottomMargin = UserInputService.TouchEnabled and 112 or 12', "touch-safe bottom margin")
has('card.AnchorPoint = Vector2.new(0, 1)', "bottom-left HUD anchor")
has('card.Position = UDim2.new(0, 12, 1, -bottomMargin)', "bottom-left HUD position")
has('title.Text = "Menu"', "legacy Menu header")
has('local LEGACY_BLUE = Color3.fromRGB(48, 104, 148)', "legacy blue palette")
has('local LEGACY_PANEL = Color3.fromRGB(193, 220, 238)', "legacy panel palette")
has('Enum.Font.ArialBold', "legacy-era UI typography")
has('cafeCard.Name = "LegacyCafePanel"', "cafe visual parity panel")
has('vehicleCard.Name = "LegacyVehiclePanel"', "vehicle visual parity panel")
has('local function formatLegacyClock(state)', "school clock/day presentation")
has('ContextActionService:BindAction(', "mobile/keyboard vehicle controls preserved")
has('submitAnswer:InvokeServer(', "class interaction preserved")
has('startCafeShift:InvokeServer()', "cafe interaction preserved")
has('spawnVehicle:InvokeServer()', "vehicle interaction preserved")
lacks('title.Text = "PIP HIGH"', "modern Pip High title")
lacks('card.Position = UDim2.new(0, 12, 0, 12)', "top-left modern card position")

dofile("school/tests/avatar_customization_entry_spec.lua")
dofile("school/tests/avatar_customization_runtime_mount_spec.lua")

print("HIGH_SCHOOL_LEGACY_HUD_CONTRACT_PASS")
