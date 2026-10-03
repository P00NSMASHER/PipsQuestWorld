--!strict
-- Runtime adapter for the verified PurchasePermanentItem seam.
-- This file never prompts or spends Robux. The server catalog is intentionally empty
-- until Content QA authorizes concrete clothing asset IDs.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local ShoppingPurchaseController = require(
    schoolFoundation:WaitForChild("ShoppingPurchaseController")
)

-- Zero entries by design: no clothing asset IDs are currently authorized.
local SERVER_CATALOG = {}
local controller = ShoppingPurchaseController.new(SERVER_CATALOG)

local remoteRoot = ReplicatedStorage:WaitForChild("SchoolFoundation")
local freeRoam = remoteRoot:FindFirstChild("FreeRoam")
if not freeRoam then
    freeRoam = Instance.new("Folder")
    freeRoam.Name = "FreeRoam"
    freeRoam.Parent = remoteRoot
end

local purchasePermanentItem = freeRoam:FindFirstChild("PurchasePermanentItem")
if purchasePermanentItem then
    assert(purchasePermanentItem:IsA("RemoteFunction"), "PurchasePermanentItem must be a RemoteFunction")
else
    purchasePermanentItem = Instance.new("RemoteFunction")
    purchasePermanentItem.Name = "PurchasePermanentItem"
    purchasePermanentItem.Parent = freeRoam
end

purchasePermanentItem.OnServerInvoke = function(player, itemKey, requestId, clientClaims)
    -- Client claims are accepted only as untrusted replay-fingerprint input.
    -- They can never create catalog authority, price, currency, ownership, or success.
    return controller:requestPurchase(player.UserId, itemKey, requestId, clientClaims)
end

MarketplaceService.PromptPurchaseFinished:Connect(function(player, assetId, purchased)
    local confirmation = controller:confirmPurchase(player.UserId, assetId, purchased)
    if confirmation.accepted == true
        and confirmation.code == "purchase_confirmed"
        and confirmation.purchaseConfirmed == true
        and type(confirmation.successText) == "string" then
        -- Reuse the verified PurchasePermanentItem seam; do not invent a reference transport.
        -- Only the purchasing player receives the first confirmed server result.
        pcall(function()
            purchasePermanentItem:InvokeClient(player, confirmation.successText)
        end)
    end
end)
