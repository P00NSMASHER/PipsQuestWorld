local function read(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a")
    file:close()
    return text
end

local client = read("school/src/client/LifestyleInventory.client.lua")

local function has(fragment, label)
    if not client:find(fragment, 1, true) then
        error("missing lifestyle remote contract: " .. (label or fragment), 2)
    end
end

local function lacks(fragment, label)
    if client:find(fragment, 1, true) then
        error("forbidden lifestyle remote contract: " .. (label or fragment), 2)
    end
end

has(':WaitForChild("StateSnapshot")', "server schedule snapshot")
has('remoteFunction("StyleShop", "GetState")', "server style/economy state")
has('remoteFunction("Housing", "GetState")', "server housing state")
has('remoteFunction("Vehicles", "GetState")', "server vehicle state")
has('vehicles:FindFirstChild(actionName)', "server vehicle action lookup")
has('and "Despawn" or "Spawn"', "bounded vehicle actions")
has('return remote:InvokeServer()', "minimal no-claim remote payload")
has("pcall(function()", "transport failure boundary")

has("ownedStyleCount()", "owned style summary")
has("furnitureCount()", "furniture inventory summary")
has("placementCount()", "placed furniture summary")
has("remainingSeconds()", "local schedule clock")
has("secondsSinceRefresh >= 5", "bounded recurring HUD economy refresh")
has('response.code == "not_at_auto_shop"', "spawn proximity feedback")
has('response.code == "vehicle_already_active"', "idempotent spawn convergence")
has('response.code == "vehicle_already_despawned"', "idempotent despawn convergence")
has("No change confirmed. Refresh before retrying.", "unknown mutation result feedback")
has("Mutating actions are never guessed or automatically replayed.", "no automatic mutation replay")

lacks("MarketplaceService", "marketplace dependency")
lacks("PromptPurchase", "purchase prompt")
lacks("Robux", "premium currency")
lacks("DataStoreService", "client persistence authority")
lacks('Instance.new("RemoteFunction")', "client-created remote")
lacks("FireServer", "unbounded event mutation")
lacks("requestId", "invented mutation id")
lacks("price =", "client-authored price")

print("HIGH_SCHOOL_LIFESTYLE_INVENTORY_REMOTE_CONTRACT_PASS")
