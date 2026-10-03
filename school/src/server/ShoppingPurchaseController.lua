--!strict
-- Server-authoritative clothing purchase boundary for the verified Legacy shopping seam.
-- The authorized catalog intentionally starts empty: Content QA has authorized zero clothing asset IDs.

local Controller = {}
Controller.__index = Controller

local SUCCESS_TEXT = "Item purchased successfully! You can wear it via the Character tab on the ROBLOX website."

local function isNonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

local function clone(result)
    local copy = {}
    for key, value in pairs(result) do copy[key] = value end
    return copy
end

local function fingerprint(itemKey, request)
    return table.concat({
        tostring(itemKey),
        tostring(request and request.assetId),
        tostring(request and request.template),
        tostring(request and request.price),
        tostring(request and request.currency),
        tostring(request and request.owned),
    }, "|")
end

function Controller.new(serverCatalog)
    assert(type(serverCatalog) == "table", "server catalog is required")
    return setmetatable({
        _catalog = serverCatalog,
        _requests = {},
        _confirmedAssets = {},
    }, Controller)
end

function Controller:getCatalog()
    local items = {}
    for key, item in pairs(self._catalog) do
        items[#items + 1] = {
            key = key,
            kind = item.kind,
            assetId = item.assetId,
            templateField = item.templateField,
        }
    end
    table.sort(items, function(a, b) return a.key < b.key end)
    return items
end

function Controller:requestPurchase(playerId, itemKey, requestId, clientClaims)
    if type(playerId) ~= "number" or playerId <= 0 then
        return { accepted = false, code = "invalid_player" }
    end
    if not isNonEmptyString(requestId) then
        return { accepted = false, code = "invalid_request_id" }
    end
    if not isNonEmptyString(itemKey) then
        return { accepted = false, code = "invalid_item" }
    end

    local requestKey = tostring(playerId) .. "|" .. requestId
    local requestFingerprint = fingerprint(itemKey, clientClaims)
    local prior = self._requests[requestKey]
    if prior then
        if prior.fingerprint ~= requestFingerprint then
            return { accepted = false, code = "request_id_conflict" }
        end
        return clone(prior.result)
    end

    local item = self._catalog[itemKey]
    local result
    if item == nil then
        result = {
            accepted = false,
            code = "unknown_item",
            retryable = false,
            purchaseStarted = false,
            purchaseConfirmed = false,
        }
    elseif type(item.assetId) ~= "number"
        or item.assetId <= 0
        or (item.templateField ~= "ShirtTemplate" and item.templateField ~= "PantsTemplate") then
        result = {
            accepted = false,
            code = "catalog_entry_invalid",
            retryable = false,
            purchaseStarted = false,
            purchaseConfirmed = false,
        }
    else
        -- A catalog entry authorizes only the server-known item identity.
        -- Client asset/template/price/ownership/currency claims never authorize purchase.
        result = {
            accepted = true,
            code = "purchase_confirmation_required",
            retryable = false,
            purchaseStarted = false,
            purchaseConfirmed = false,
            itemKey = itemKey,
            assetId = item.assetId,
            templateField = item.templateField,
        }
    end

    self._requests[requestKey] = {
        fingerprint = requestFingerprint,
        result = clone(result),
    }
    return result
end

function Controller:confirmPurchase(playerId, assetId, purchased)
    if type(playerId) ~= "number" or playerId <= 0
        or type(assetId) ~= "number" or assetId <= 0
        or purchased ~= true then
        return { accepted = false, code = "purchase_not_confirmed" }
    end

    local authorized = false
    for _, item in pairs(self._catalog) do
        if item.assetId == assetId then
            authorized = true
            break
        end
    end
    if not authorized then
        return { accepted = false, code = "unknown_asset" }
    end

    local key = tostring(playerId) .. "|" .. tostring(assetId)
    if self._confirmedAssets[key] then
        return {
            accepted = true,
            code = "purchase_already_confirmed",
            purchaseConfirmed = true,
            successText = SUCCESS_TEXT,
        }
    end

    self._confirmedAssets[key] = true
    return {
        accepted = true,
        code = "purchase_confirmed",
        purchaseConfirmed = true,
        successText = SUCCESS_TEXT,
    }
end

Controller.SUCCESS_TEXT = SUCCESS_TEXT
Controller.CURRENCY = "Robux"
Controller.SERVER_CATALOG_STARTS_EMPTY = true

return Controller
