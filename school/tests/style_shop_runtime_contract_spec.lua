local function read(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a")
    file:close()
    return text
end

local project = read("school/default.project.json")
local catalog = read("school/src/server/StyleShopCatalog.lua")
local controller = read("school/src/server/StyleShopController.lua")
local service = read("school/src/server/StyleShopService.server.lua")
local client = read("school/src/client/StyleShopCatalog.client.lua")

local function has(text, fragment, label)
    if not text:find(fragment, 1, true) then
        error("missing Style Shop contract: " .. (label or fragment), 2)
    end
end

local function lacks(text, fragment, label)
    if text:find(fragment, 1, true) then
        error("forbidden Style Shop contract: " .. (label or fragment), 2)
    end
end

has(project, '"StyleShopCatalog"', "catalog mapping")
has(project, '"StyleShopController"', "controller mapping")
has(project, '"StyleShopService"', "service mapping")
has(project, '"src/client/StyleShopCatalog.client.lua"', "client mapping")

has(catalog, "originalContent = true", "original content provenance")
lacks(catalog, "assetId", "catalog asset ids")
lacks(catalog, "rbxassetid", "catalog Roblox asset URI")
lacks(catalog, "Roblox High School", "protected branding")

has(controller, "MAX_REQUEST_ID_LENGTH = 64", "bounded request ids")
has(controller, 'operationId = "style-shop:" .. requestId', "durable idempotency key")
has(controller, "delta = -item.price", "server-known price debit")
has(controller, 'category = OWNERSHIP_CATEGORY', "durable ownership")
has(controller, 'code = "request_id_conflict"', "idempotency conflict")
has(controller, 'code = "insufficient_funds"', "insufficient funds result")
lacks(controller, "clientPrice", "client price authority")
lacks(controller, "_requests", "unbounded replay cache")

has(service, 'EconomyRuntime.open(playerId, false)', "shared economy runtime")
has(service, 'remoteFunction("GetState")', "state remote")
has(service, 'remoteFunction("PurchaseItem")', "purchase remote")
has(service, 'remoteFunction("EquipItem")', "equip remote")
has(service, "controller:purchase(player.UserId, itemId, requestId)", "server purchase authority")
has(service, "controller:authorizeEquip(player.UserId, itemId)", "server equip authority")
has(service, 'folder.Name = "PipHighStyle"', "equipped wardrobe geometry")
has(service, 'local function applyWhenCharacterReady', "respawn-safe style restoration")
has(service, 'character:WaitForChild("Humanoid", 10)', "character rig readiness")
has(service, 'if player.Character then', "existing character restoration")
lacks(service, "MarketplaceService", "premium marketplace dependency")
lacks(service, "PromptPurchase", "purchase prompt")
lacks(service, "Robux", "premium currency")
lacks(service, "FireAllClients", "broadcast purchase result")

has(client, ':WaitForChild("FeaturePanel_shop", 30)', "canonical shop augmentation")
has(client, "body:ClearAllChildren()", "shell replacement")
has(client, "HttpService:GenerateGUID(false)", "client request identity")
has(client, "purchaseItem:InvokeServer(item.id, requestId)", "minimal purchase payload")
has(client, "equipItem:InvokeServer(item.id)", "minimal equip payload")
has(client, "pendingRequestIds[item.id]", "transport retry id reuse")
has(client, "local function applyResponsiveCatalogLayout()", "compact catalog layout")
has(client, "body.AbsoluteSize.Y > 0 and body.AbsoluteSize.Y < 190", "short detail-pane breakpoint")
has(client, "detailName.Position = UDim2.fromOffset(68, 7)", "horizontal compact item name")
has(client, "action.Position = UDim2.new(0, 68, 1, -8)", "horizontal compact purchase action")
has(client, 'body:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyResponsiveCatalogLayout)', "live catalog resize listener")
lacks(client, "price =", "client-authored price claim")
lacks(client, "MarketplaceService", "client marketplace dependency")

print("HIGH_SCHOOL_STYLE_SHOP_RUNTIME_CONTRACT_PASS")
