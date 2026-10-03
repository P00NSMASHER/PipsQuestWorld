local function read(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a")
    file:close()
    return text
end

local project = read("school/default.project.json")
local service = read("school/src/server/ShoppingPurchase.server.lua")
local controller = read("school/src/server/ShoppingPurchaseController.lua")
local clientBoundary = read("school/src/shared/LegacyShoppingBoundary.lua")
local canonicalClient = read("school/src/client/CanonicalSchoolClient.client.lua")

local function has(text, fragment, label)
    if not text:find(fragment, 1, true) then
        error("missing shopping runtime contract: " .. (label or fragment), 2)
    end
end

local function lacks(text, fragment, label)
    if text:find(fragment, 1, true) then
        error("forbidden shopping runtime contract: " .. (label or fragment), 2)
    end
end

has(project, '"ShoppingPurchaseController"', "shopping controller project mapping")
has(project, '"ShoppingPurchase"', "shopping service project mapping")
has(project, '"LegacyShoppingBoundary"', "shopping client boundary mapping")
has(service, 'local SERVER_CATALOG = {}', "authorized product catalog starts empty")
has(service, 'purchasePermanentItem.Name = "PurchasePermanentItem"', "verified purchase remote")
has(service, 'MarketplaceService.PromptPurchaseFinished:Connect', "server purchase confirmation callback")
has(service, 'local confirmation = controller:confirmPurchase(player.UserId, assetId, purchased)', "callback result consumed")
has(service, 'confirmation.code == "purchase_confirmed"', "first-confirm delivery gate")
has(service, 'purchasePermanentItem:InvokeClient(player, confirmation.successText)', "purchaser-only callback delivery")
has(controller, 'local SUCCESS_TEXT = "Item purchased successfully! You can wear it via the Character tab on the ROBLOX website."', "exact success text")
has(controller, 'code = "unknown_item"', "unknown item fail closed")
has(controller, 'code = "unknown_asset"', "unknown callback asset fail closed")
has(controller, 'code = "request_id_conflict"', "request id conflict")
has(controller, 'purchaseStarted = false', "no automatic spend")
has(clientBoundary, ':WaitForChild("PurchasePermanentItem")', "client binds verified remote")
has(clientBoundary, 'purchasePermanentItem:InvokeServer(itemKey, requestId, nil)', "client request has no authority claims")
has(clientBoundary, 'purchasePermanentItem.OnClientInvoke = function(message)', "server confirmation reaches purchasing client")
has(clientBoundary, 'function api.consumeServerConfirmation()', "server confirmation remains server-authored")
has(canonicalClient, 'require(shared:WaitForChild("LegacyShoppingBoundary"))', "canonical client requires shopping boundary")
has(canonicalClient, 'local shoppingBoundary = LegacyShoppingBoundary()', "canonical client mounts shopping boundary")

lacks(service, "FireAllClients", "purchase success must never broadcast")
lacks(service, "GetPlayers(", "purchase success must not iterate recipients")
lacks(service, "PromptPurchase(", "service must not trigger a Robux purchase")
lacks(service, "PromptProductPurchase(", "service must not trigger developer product purchase")
lacks(service, "EconomyRepository", "shopping must not debit RHS economy")
lacks(service, "RHS Cash", "shopping service must not use RHS Cash")
lacks(clientBoundary, "Item purchased successfully!", "client must not author exact success")
lacks(clientBoundary, "ShirtID", "client must not invent item identity")
lacks(clientBoundary, "PantsID", "client must not invent item identity")
lacks(clientBoundary, "price =", "client must not authorize price")
lacks(clientBoundary, "currency =", "client must not authorize currency")
lacks(clientBoundary, "owned =", "client must not authorize ownership")

print("HIGH_SCHOOL_SHOPPING_RUNTIME_AUTHORITY_PASS")
