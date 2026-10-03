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
has(project, '"src/server/HousingService.server.lua"', "HousingService project path")

has(client, 'local housingRoot = root:WaitForChild("FreeRoam"):WaitForChild("Housing")', "client housing root")
has(client, 'housingRoot:WaitForChild("GetState")', "GetState remote")
has(client, 'housingRoot:WaitForChild("BuyHouse")', "BuyHouse remote")
has(client, 'housingRoot:WaitForChild("TeleportToHouse")', "TeleportToHouse remote")
has(client, 'housingRoot:WaitForChild("SetEditMode")', "SetEditMode remote")
has(client, 'housingRoot:WaitForChild("SetStyle")', "SetStyle remote")

has(client, 'houseIcon.Name = "LegacyHouseButton"', "legacy House HUD button")
has(client, 'houseTitle.Text = "House"', "House menu title")
has(client, 'housePrimary.Text = "TELEPORT TO HOUSE"', "Teleport to House action")
has(client, 'houseEdit.Text = editing and "SAVE HOUSE" or "EDIT HOUSE"', "Edit House action")
has(client, '"BUY HOUSE  •  $"', "permanent house purchase action")
has(client, '"classic-blue"', "blue house style")
has(client, '"classic-tan"', "tan house style")
has(client, '"classic-red"', "red house style")
has(client, '"classic-green"', "green house style")

has(service, 'local HOUSE_PRICE = 50', "$50 Legacy house price")
has(service, 'local HOUSE_UNLOCK = { category = "house", itemId = "starter-house" }', "durable house ownership")
has(service, 'buyHouseRemote.OnServerInvoke', "server-authoritative purchase")
has(service, 'teleportRemote.OnServerInvoke', "server-authoritative teleport")
has(service, 'editModeRemote.OnServerInvoke', "server-authoritative edit mode")
has(service, 'styleRemote.OnServerInvoke', "server-authoritative style")
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

equals(editorReference.schemaVersion, 2, "reference schema version")
equals(editorReference.legacyExperience, "ROBLOX High School [Legacy]", "Legacy target identity")
equals(editorReference.visibleLabels.addFurniture, "Add Furni", "Add Furni label")
equals(editorReference.visibleLabels.hideWalls, "Hide Walls", "Hide Walls label")
equals(editorReference.furnitureCategories.complete, false, "category coverage must remain explicitly incomplete")

local verifiedCategories = {}
for _, label in ipairs(editorReference.furnitureCategories.verifiedExactLabels or {}) do
    if verifiedCategories[label] then
        error("invalid Housing Editor V2 reference: duplicate category label " .. label, 2)
    end
    verifiedCategories[label] = true
end
equals(verifiedCategories.Utilities, true, "Utilities category")
equals(verifiedCategories.Other, true, "Other category")
equals(#(editorReference.furnitureCategories.verifiedExactLabels or {}), 2, "do not infer unverified category labels")

local evidenceById = {}
for _, evidence in ipairs(editorReference.source.evidence or {}) do
    if type(evidence.id) ~= "string" or evidence.id == "" then
        error("invalid Housing Editor V2 reference: evidence missing id", 2)
    end
    if evidenceById[evidence.id] then
        error("invalid Housing Editor V2 reference: duplicate evidence id " .. evidence.id, 2)
    end
    if type(evidence.locator) ~= "string" or evidence.locator == "" then
        error("invalid Housing Editor V2 reference: evidence missing locator for " .. evidence.id, 2)
    end
    if evidence.use ~= "licensed_reference" and evidence.use ~= "corroboration_only" then
        error("invalid Housing Editor V2 reference: invalid evidence use for " .. evidence.id, 2)
    end
    evidenceById[evidence.id] = true
end

local function requiresEvidence(ids, label)
    if type(ids) ~= "table" or #ids == 0 then
        error("invalid Housing Editor V2 reference: missing claim provenance for " .. label, 2)
    end
    for _, evidenceId in ipairs(ids) do
        equals(evidenceById[evidenceId], true, "unknown evidence id for " .. label .. ": " .. tostring(evidenceId))
    end
end

requiresEvidence(editorReference.claimProvenance.visibleLabels["Add Furni"], "Add Furni")
requiresEvidence(editorReference.claimProvenance.visibleLabels["Hide Walls"], "Hide Walls")
requiresEvidence(editorReference.claimProvenance.furnitureCategories.Utilities, "Utilities")
requiresEvidence(editorReference.claimProvenance.furnitureCategories.Other, "Other")
requiresEvidence(editorReference.claimProvenance.housingInteractions.teleportToHouse, "teleportToHouse")
requiresEvidence(editorReference.claimProvenance.housingInteractions.editHouse, "editHouse")
requiresEvidence(editorReference.claimProvenance.housingInteractions.restrictVisitorsWhileEditing, "restrictVisitorsWhileEditing")
requiresEvidence(editorReference.claimProvenance.paintBuildBehavior.moveFurniture, "moveFurniture")
requiresEvidence(editorReference.claimProvenance.paintBuildBehavior.paintHouseItem, "paintHouseItem")
requiresEvidence(editorReference.claimProvenance.paintBuildBehavior.saveHouse, "saveHouse")

equals(editorReference.paintBuildTools.exactLabelCoverageComplete, false, "paint/build exact labels must remain explicitly incomplete")
equals(#(editorReference.paintBuildTools.exactVisibleLabels or {}), 0, "no invented paint/build labels")

local verifiedPaintBuildBehavior = {}
for _, actionName in ipairs(editorReference.paintBuildTools.verifiedBehavior or {}) do
    verifiedPaintBuildBehavior[actionName] = true
end
equals(verifiedPaintBuildBehavior.moveFurniture, true, "move behavior")
equals(verifiedPaintBuildBehavior.paintHouseItem, true, "paint behavior")
equals(verifiedPaintBuildBehavior.saveHouse, true, "save behavior")

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
    if editorSemantics[actionName] then
        error("invalid Housing Editor V2 reference: duplicate editor semantic " .. actionName, 2)
    end
    editorSemantics[actionName] = true
end
for _, actionName in ipairs(requiredEditorSemantics) do
    equals(editorSemantics[actionName], true, "missing editor semantic " .. actionName)
end

equals(#(editorReference.assetProvenance.referencedAssetIds or {}), 0, "no unproven asset IDs")
equals(editorReference.assetProvenance.publicCorroborationIsNotAssetAuthorization, true, "public evidence must not authorize assets")
equals(editorReference.boundaries.runtimeAuthority, false, "Content QA must not own runtime")
equals(editorReference.boundaries.economyAuthority, false, "Content QA must not own economy")
equals(editorReference.boundaries.persistenceAuthority, false, "Content QA must not own persistence")
equals(editorReference.boundaries.worldGeometryAuthority, false, "Content QA must not own world geometry")
equals(editorReference.boundaries.customizationMechanicsAuthority, false, "Content QA must not own customization mechanics")
equals(editorReference.boundaries.productCodeImportedFromLegacyRuntime, false, "no Legacy runtime product-code import")
equals(editorReference.boundaries.retiredRuntimeProductCodeAllowed, false, "retired runtime product code forbidden")
equals(editorReference.boundaries.rhs2ReferenceBleedAllowed, false, "RHS2 reference bleed forbidden")

print("HIGH_SCHOOL_HOUSING_UI_CONTRACT_PASS")
