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

local shoppingFile = assert(io.open("school/src/server/AvatarShoppingContract.lua", "r"))
local shopping = shoppingFile:read("*a")
shoppingFile:close()

local function shoppingHas(fragment, label)
    if not shopping:find(fragment, 1, true) then
        error("missing verified avatar-shopping prep contract: " .. (label or fragment), 2)
    end
end

shoppingHas('Contract.PURCHASE_REMOTE = "PurchasePermanentItem"', "verified purchase seam")
shoppingHas('Contract.SHIRT_TEMPLATE_FIELD = "ShirtTemplate"', "verified shirt template field")
shoppingHas('Contract.PANTS_TEMPLATE_FIELD = "PantsTemplate"', "verified pants template field")
shoppingHas('"Item purchased successfully! You can wear it via the Character tab on the ROBLOX website."', "verified success notification")
shoppingHas('supportHead = "762e1d17e001635a8f0a8cc9bed66a36080ed68d"', "Content-QA provenance")
shoppingHas('fullCatalog = true', "catalog remains unverified")
shoppingHas('assetIds = true', "asset IDs remain unverified")
shoppingHas('purchasePayloadShape = true', "payload shape remains unverified")
shoppingHas('remoteContainerHierarchy = true', "remote hierarchy remains unverified")
shoppingHas('code = "UNVERIFIED_CATALOG"', "unknown catalog fails closed")
shoppingHas('spendAttempted = false', "prep contract never spends")

print("HIGH_SCHOOL_LEGACY_HUD_CONTRACT_PASS")
