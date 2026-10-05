local function read(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a")
    file:close()
    return text
end

local client = read("school/src/client/LifestyleInventory.client.lua")
local canonical = read("school/src/client/CanonicalSchoolClient.client.lua")

local function has(text, fragment, label)
    if not text:find(fragment, 1, true) then
        error("missing lifestyle UI contract: " .. (label or fragment), 2)
    end
end

local function lacks(text, fragment, label)
    if text:find(fragment, 1, true) then
        error("forbidden lifestyle UI contract: " .. (label or fragment), 2)
    end
end

has(client, ':WaitForChild("RobloxHighSchoolLegacyUI", 30)', "canonical UI wait")
has(client, 'panelBody("phone")', "phone augmentation")
has(client, 'panelBody("bag")', "backpack augmentation")
has(client, 'panelBody("items")', "items augmentation")
has(client, 'schoolStatusCard:FindFirstChild("CashLevelLabel")', "recurring HUD economy badge")
has(client, 'tonumber(player:GetAttribute("SchoolPoints"))', "server-derived school level")
has(client, 'panel:WaitForChild("Body", 10)', "existing body reuse")
has(client, 'GetAttribute("LifestyleStatusMounted")', "duplicate mount guard")

has(client, 'createStatusCard(phoneBody, "LifestylePhoneCard", 184, 72)', "phone lower status card")
has(client, 'createStatusCard(bagBody, "BagInventoryCard", 150, 76)', "bag lower status card")
has(client, 'createStatusCard(itemsBody, "ItemsVehicleCard", 164, 78)', "items lower status card")
has(client, 'card.Visible = body.AbsoluteSize.Y >= offsetY + minimumHeight', "short-screen overlap guard")
has(client, 'GetPropertyChangedSignal("AbsoluteSize")', "responsive resize")
has(client, 'card.ClipsDescendants = true', "responsive content clipping")
has(client, 'GetPropertyChangedSignal("Visible")', "refresh on panel open")
has(client, 'task.wait(1)', "local clock cadence")

-- The underlying app and shortcut controls remain canonical and are not rebuilt.
has(canonical, '"Phone_" .. spec.key', "canonical phone apps")
has(canonical, '"ClosetShortcut"', "canonical closet shortcut")
has(canonical, '"HouseShortcut"', "canonical house shortcut")
has(canonical, '"TravelAutoShop"', "canonical Auto Shop shortcut")
lacks(client, "ClearAllChildren", "existing controls cleared")
lacks(client, ":Destroy()", "existing controls destroyed")
lacks(client, 'Instance.new("ScreenGui")', "duplicate ScreenGui")

print("HIGH_SCHOOL_LIFESTYLE_INVENTORY_UI_CONTRACT_PASS")
