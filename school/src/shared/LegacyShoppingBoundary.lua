-- Exact-reference client request boundary for Legacy clothing purchase.
-- No catalog/UI is rendered because authorized clothing asset IDs and layout are unknown.
-- The client can request only; it never authorizes item, asset, price, ownership, currency, or success.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local function mount()
    local purchasePermanentItem = ReplicatedStorage:WaitForChild("SchoolFoundation")
        :WaitForChild("FreeRoam")
        :WaitForChild("PurchasePermanentItem")

    local pendingRequestIds = {}

    local api = {}

    function api.request(itemKey)
        if type(itemKey) ~= "string" or itemKey == "" then
            return { accepted = false, code = "invalid_item" }
        end
        local requestId = pendingRequestIds[itemKey]
        if requestId == nil then
            requestId = HttpService:GenerateGUID(false)
            pendingRequestIds[itemKey] = requestId
        end

        local ok, response = pcall(function()
            return purchasePermanentItem:InvokeServer(itemKey, requestId, nil)
        end)
        if not ok or type(response) ~= "table" then
            return { accepted = false, code = "shopping_service_unavailable", retryable = true }
        end
        if response.retryable ~= true then
            pendingRequestIds[itemKey] = nil
        end
        return response
    end

    return api
end

return mount
