local function read(path)
    local handle = assert(io.open(path, "r"))
    local source = handle:read("*a")
    handle:close()
    return source
end

local controller = read("school/src/server/MarketStockJobController.lua")
local server = read("school/src/server/MarketStockJob.server.lua")
local client = read("school/src/client/MarketStockJob.client.lua")

local function contains(source, fragment, label)
    if not source:find(fragment, 1, true) then
        error("missing market job contract: " .. (label or fragment), 2)
    end
end

local function excludes(source, fragment, label)
    if source:find(fragment, 1, true) then
        error("forbidden market job contract: " .. (label or fragment), 2)
    end
end

contains(server, "SchoolConfig.WorldLocations.Market", "Foundation Market seam")
contains(server, "MARKET_RADIUS", "spatial authority")
contains(server, "isAtMarket(player)", "server proximity checks")
contains(server, 'Instance.new("ProximityPrompt")', "discoverable world prompt")
contains(server, 'getOrCreateRemoteEvent(marketRoot, "OpenPanel")', "prompt-to-panel remote")
contains(server, "openPanelRemote:FireClient(player)", "server prompt dispatch")
contains(server, "EconomyRuntime.open(playerId, false)", "shared economy repository")
contains(server, "EconomyRuntime.release(player.UserId)", "rejoin-safe repository cleanup")
contains(server, "controller:clearPlayer(player.UserId)", "session cleanup")
contains(server, "Players.PlayerRemoving", "leave cleanup hook")
contains(server, 'getOrCreateRemoteFunction(marketRoot, "SubmitSort")', "sort remote")

contains(controller, "STEPS_PER_SHIFT = 3", "three-step shift")
contains(controller, "correctChoiceId", "server-held answers")
contains(controller, "MAX_REQUEST_ID_LENGTH", "bounded request identifiers")
contains(controller, "MAX_REQUEST_CACHE", "bounded replay cache")
contains(controller, "request_conflict", "idempotency conflict handling")
contains(controller, 'operationId = "job:market:" .. shiftId', "shift-scoped wage idempotency")
contains(controller, 'reason = "job:market-stock"', "market economy reason")
contains(controller, 'code = "try_again"', "retry-friendly wrong answer")

contains(client, 'Instance.new("UISizeConstraint")', "responsive panel bounds")
contains(client, 'Instance.new("ScrollingFrame")', "small-screen scrolling")
contains(client, "openPanelRemote.OnClientEvent", "prompt panel opening")
contains(client, "submitSortRemote:InvokeServer", "server answer submission")
contains(client, 'resultCard.Name = "ResultCard"', "clear result screen")
contains(client, "Connection hiccup", "retry guidance")
excludes(client, "correctChoiceId", "correct answer leaked to client")
excludes(client, "MarketplaceService", "monetization")
excludes(server, "MarketplaceService", "monetization")

print("HIGH_SCHOOL_MARKET_STOCK_JOB_RUNTIME_CONTRACT_PASS")
