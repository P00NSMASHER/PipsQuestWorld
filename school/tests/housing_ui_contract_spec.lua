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

print("HIGH_SCHOOL_HOUSING_UI_CONTRACT_PASS")
