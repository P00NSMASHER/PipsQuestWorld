local clientPath = "school/src/client/CanonicalSchoolClient.client.lua"
local projectPath = "school/default.project.json"
local servicePath = "school/src/server/HousingService.server.lua"

local function read(path)
    local file = assert(io.open(path, "r"))
    local source = file:read("*a")
    file:close()
    return source
end

local client = read(clientPath)
local project = read(projectPath)
local service = read(servicePath)

local function has(source, fragment, label)
    if not source:find(fragment, 1, true) then
        error("missing housing contract: " .. (label or fragment), 2)
    end
end

local function lacks(source, fragment, label)
    if source:find(fragment, 1, true) then
        error("forbidden housing regression: " .. (label or fragment), 2)
    end
end

has(project, '"HousingLifecycle"', "HousingLifecycle mapped into canonical project")
has(project, '"src/server/HousingLifecycle.lua"', "HousingLifecycle project path")
has(project, '"HousingService"', "HousingService mapped into canonical project")
has(project, '"HousingEditorController"', "HousingEditorController mapped into canonical project")
has(project, '"src/server/HousingEditorController.lua"', "HousingEditorController project path")
has(project, '"src/server/HousingService.server.lua"', "HousingService project path")

has(client, 'local housingRoot = root:WaitForChild("FreeRoam"):WaitForChild("Housing")', "client housing root")
has(client, 'housingRoot:WaitForChild("GetState")', "GetState remote")
has(client, 'housingRoot:WaitForChild("BuyHouse")', "BuyHouse remote")
has(client, 'housingRoot:WaitForChild("TeleportToHouse")', "TeleportToHouse remote")
has(client, 'housingRoot:WaitForChild("SetEditMode")', "SetEditMode remote")
has(client, 'housingRoot:WaitForChild("SetStyle")', "SetStyle remote")
has(client, 'housingRoot:WaitForChild("GetEditorState")', "GetEditorState remote")
has(client, 'housingRoot:WaitForChild("PurchaseFurniture")', "PurchaseFurniture remote")
has(client, 'housingRoot:WaitForChild("PlaceFurniture")', "PlaceFurniture remote")
has(client, 'housingRoot:WaitForChild("MoveFurniture")', "MoveFurniture remote")
has(client, 'housingRoot:WaitForChild("RotateFurniture")', "RotateFurniture remote")
has(client, 'housingRoot:WaitForChild("RemoveFurniture")', "RemoveFurniture remote")
has(client, 'housingRoot:WaitForChild("SellFurniture")', "SellFurniture remote")
has(client, 'housingRoot:WaitForChild("PaintFurniture")', "PaintFurniture remote")
has(client, 'housingRoot:WaitForChild("SetHideWalls")', "SetHideWalls remote")

has(client, 'houseIcon.Name = "LegacyHouseButton"', "legacy House HUD button")
has(client, 'houseTitle.Text = "House"', "House menu title")
has(client, 'housePrimary.Text = "TELEPORT TO HOUSE"', "Teleport to House action")
has(client, 'houseEdit.Text = editing and "SAVE HOUSE" or "EDIT HOUSE"', "Edit House action")
has(client, '"BUY HOUSE  •  $"', "permanent house purchase action")
has(client, '"classic-blue"', "blue house style")
has(client, '"classic-tan"', "tan house style")
has(client, '"classic-red"', "red house style")
has(client, '"classic-green"', "green house style")
has(client, 'editorTitle.Text = "Add Furni"', "Add Furni exact label")
has(client, 'hideWallsButton.Text = "Hide Walls"', "Hide Walls exact label")
has(client, 'editorCategories.Text = "Utilities   |   Other"', "verified exact category labels")

has(service, 'local HOUSE_PRICE = 50', "$50 Legacy house price")
has(service, 'local HOUSE_UNLOCK = { category = "house", itemId = "starter-house" }', "durable house ownership")
has(service, 'buyHouseRemote.OnServerInvoke', "server-authoritative purchase")
has(service, 'teleportRemote.OnServerInvoke', "server-authoritative teleport")
has(service, 'editModeRemote.OnServerInvoke', "server-authoritative edit mode")
has(service, 'styleRemote.OnServerInvoke', "server-authoritative style")
has(service, 'getEditorStateRemote.OnServerInvoke', "server-authoritative editor state")
has(service, 'purchaseFurnitureRemote.OnServerInvoke', "server-authoritative furniture purchase")
has(service, 'placeFurnitureRemote.OnServerInvoke', "server-authoritative furniture placement")
has(service, 'moveFurnitureRemote.OnServerInvoke', "server-authoritative furniture movement")
has(service, 'rotateFurnitureRemote.OnServerInvoke', "server-authoritative furniture rotation")
has(service, 'removeFurnitureRemote.OnServerInvoke', "server-authoritative furniture removal")
has(service, 'sellFurnitureRemote.OnServerInvoke', "server-authoritative furniture sale")
has(service, 'paintFurnitureRemote.OnServerInvoke', "server-authoritative furniture paint")
has(service, 'hideWallsRemote.OnServerInvoke', "server-authoritative Hide Walls")
has(service, 'repository:record({', "central economy ledger use")
lacks(client, 'CFrame.new(', "client must not own house teleport transforms")
lacks(client, 'repository:record(', "client must not mutate economy")
lacks(client, 'DataStoreService', "client must not access persistence")


local editorReference = dofile("school/tests/fixtures/legacy_housing_editor_v2_reference.lua")

local function equals(actual, expected, label)
    if actual ~= expected then
        error("invalid Housing Editor V2 reference: " .. label, 2)
    end
end

equals(editorReference.visibleLabels.addFurniture, "Add Furni", "Add Furni label")
equals(editorReference.visibleLabels.hideWalls, "Hide Walls", "Hide Walls label")
equals(editorReference.furnitureCategories.complete, false, "category coverage must remain explicitly incomplete")

local verifiedCategories = {}
for _, label in ipairs(editorReference.furnitureCategories.verifiedExactLabels or {}) do
    verifiedCategories[label] = true
end
equals(verifiedCategories.Utilities, true, "Utilities category")
equals(verifiedCategories.Other, true, "Other category")

local requiredEditorSemantics = {
    "buyFurniture",
    "placeFurniture",
    "moveFurniture",
    "rotateFurniture",
    "removeFurniture",
    "sellFurniture",
    "paintHouseItem",
    "saveHouse",
    "reloadHouse",
    "hideWalls",
    "restrictVisitorsWhileEditing",
}
local editorSemantics = {}
for _, actionName in ipairs(editorReference.interactionSemantics or {}) do
    editorSemantics[actionName] = true
end
for _, actionName in ipairs(requiredEditorSemantics) do
    equals(editorSemantics[actionName], true, "missing editor semantic " .. actionName)
end

equals(#(editorReference.assetProvenance.referencedAssetIds or {}), 0, "no unproven asset IDs")
equals(editorReference.boundaries.runtimeAuthority, false, "Content QA must not own runtime")
equals(editorReference.boundaries.economyAuthority, false, "Content QA must not own economy")
equals(editorReference.boundaries.persistenceAuthority, false, "Content QA must not own persistence")
equals(editorReference.boundaries.worldGeometryAuthority, false, "Content QA must not own world geometry")
equals(editorReference.boundaries.customizationMechanicsAuthority, false, "Content QA must not own customization mechanics")
equals(editorReference.boundaries.productCodeImportedFromLegacyRuntime, false, "no Legacy runtime product-code import")

dofile("school/tests/housing_editor_controller_spec.lua")

print("HIGH_SCHOOL_HOUSING_UI_CONTRACT_PASS")
