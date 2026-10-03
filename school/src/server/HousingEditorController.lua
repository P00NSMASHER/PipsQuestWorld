--!strict
-- Server-authoritative Housing Editor V2 gameplay orchestration.
-- Durable layout/inventory remains owned by HousingLayoutRepository.
-- Money remains owned by EconomyRepository.

local Controller = {}
Controller.__index = Controller

-- Production catalog remains empty until exact furniture items/assets are
-- independently verified by Content QA. Tests inject non-production catalog
-- entries explicitly so behavior coverage remains complete without presenting
-- invented furniture as Legacy-exact.
local CATALOG = {}

local PAINTS = {
    ["default"] = true,
    ["legacy-blue"] = true,
    ["legacy-red"] = true,
    ["legacy-green"] = true,
    ["legacy-tan"] = true,
}

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function isFinite(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function nonEmpty(value)
    return type(value) == "string" and value ~= ""
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do
        result[copy(key)] = copy(child)
    end
    return result
end

local function committed(receipt)
    return type(receipt) == "table"
        and receipt.durable == true
        and (receipt.status == "applied" or receipt.status == "duplicate")
end

local function retryable(receipt)
    local err = receipt and receipt.error or ""
    return type(err) == "string"
        and (
            err:find("SAVE_FAILED", 1, true) ~= nil
            or err:find("LOAD_FAILED", 1, true) ~= nil
            or err == "STALE_WRITE_RETRY_EXHAUSTED"
        )
end

local function findPlacement(state, placementId)
    for _, placement in ipairs(state.placements or {}) do
        if placement.placementId == placementId then
            return placement
        end
    end
    return nil
end

local function normalizeRotation(value)
    local rotation = value % 360
    if rotation < 0 then rotation = rotation + 360 end
    return rotation
end

function Controller.new(options)
    options = options or {}
    assert(type(options.layoutRepositoryFactory) == "function", "layoutRepositoryFactory is required")
    assert(type(options.economyRepositoryFactory) == "function", "economyRepositoryFactory is required")
    assert(type(options.authorize) == "function", "authorize is required")

    local catalog = options.catalog or CATALOG
    local allowUnverifiedTestCatalog = options.allowUnverifiedTestCatalog == true
    local catalogById = {}
    local publicCatalog = {}
    for index, entry in ipairs(catalog) do
        assert(nonEmpty(entry.itemId), "catalog itemId is required")
        assert(nonEmpty(entry.displayName), "catalog displayName is required")
        assert(entry.referenceExact == true or allowUnverifiedTestCatalog, "catalog entries must carry verified reference provenance")
        assert(entry.category == "Utilities" or entry.category == "Other", "catalog category must be verified")
        assert(isInteger(entry.price) and entry.price >= 0, "catalog price must be a nonnegative integer")
        assert(isInteger(entry.sellPrice) and entry.sellPrice >= 0, "catalog sellPrice must be a nonnegative integer")
        assert(entry.sellPrice <= entry.price, "sellPrice must not exceed price")
        assert(catalogById[entry.itemId] == nil, "duplicate catalog item")
        catalogById[entry.itemId] = copy(entry)
        publicCatalog[index] = copy(entry)
    end

    return setmetatable({
        _layoutRepositoryFactory = options.layoutRepositoryFactory,
        _economyRepositoryFactory = options.economyRepositoryFactory,
        _authorize = options.authorize,
        _catalog = publicCatalog,
        _catalogById = catalogById,
        _maxX = options.maxX or 18,
        _maxZ = options.maxZ or 12,
        _minY = options.minY or 0,
        _maxY = options.maxY or 8,
    }, Controller)
end

function Controller:getCatalog()
    return copy(self._catalog)
end

function Controller:getCatalogEntry(itemId)
    local entry = self._catalogById[itemId]
    return entry and copy(entry) or nil
end

function Controller:_authorization(playerId, editingRequired)
    if not isInteger(playerId) or playerId <= 0 then
        return nil, { accepted = false, code = "invalid_player" }
    end
    local ok, authorization = pcall(self._authorize, playerId)
    if not ok or type(authorization) ~= "table" then
        return nil, { accepted = false, code = "housing_unavailable" }
    end
    if authorization.owned ~= true or not nonEmpty(authorization.plotId) then
        return nil, { accepted = false, code = "house_not_owned" }
    end
    if editingRequired and authorization.editing ~= true then
        return nil, { accepted = false, code = "edit_mode_required" }
    end
    return authorization, nil
end

function Controller:_layout(playerId)
    local ok, repository, err = pcall(self._layoutRepositoryFactory, playerId)
    if not ok or repository == nil or type(repository.commit) ~= "function" then
        return nil, tostring(err or "layout_repository_unavailable")
    end
    return repository, nil
end

function Controller:_economy(playerId)
    local ok, repository, err = pcall(self._economyRepositoryFactory, playerId)
    if not ok or repository == nil or type(repository.record) ~= "function" then
        return nil, tostring(err or "economy_repository_unavailable")
    end
    return repository, nil
end

function Controller:_response(playerId, authorization, repository)
    local state = repository:getState()
    return {
        accepted = true,
        code = "editor_state",
        owned = true,
        editing = authorization.editing == true,
        plotId = authorization.plotId,
        catalog = self:getCatalog(),
        houseStyleId = state.houseStyleId,
        hideWalls = state.hideWalls == true,
        inventory = copy(state.inventory),
        placements = copy(state.placements),
        revision = state.revision,
    }
end

function Controller:getState(playerId)
    local authorization, denied = self:_authorization(playerId, false)
    if denied then return denied end
    local repository, err = self:_layout(playerId)
    if not repository then
        return { accepted = false, code = "layout_unavailable", error = err }
    end
    return self:_response(playerId, authorization, repository)
end

function Controller:_validateRequest(requestId)
    return nonEmpty(requestId)
end

function Controller:_validateTransform(transform)
    if type(transform) ~= "table"
        or not isFinite(transform.x)
        or not isFinite(transform.y)
        or not isFinite(transform.z)
        or not isFinite(transform.rotation) then
        return false
    end
    return math.abs(transform.x) <= self._maxX
        and math.abs(transform.z) <= self._maxZ
        and transform.y >= self._minY
        and transform.y <= self._maxY
end

function Controller:purchase(playerId, itemId, requestId)
    local authorization, denied = self:_authorization(playerId, true)
    if denied then return denied end
    if not self:_validateRequest(requestId) then
        return { accepted = false, code = "invalid_request_id" }
    end
    local item = self._catalogById[itemId]
    if not item then return { accepted = false, code = "unknown_item" } end

    local economy, economyError = self:_economy(playerId)
    if not economy then
        return { accepted = false, code = "economy_unavailable", error = economyError, retryable = true }
    end
    local charge = economy:record({
        operationId = "housing:furni:buy:" .. requestId,
        playerId = playerId,
        delta = -item.price,
        reason = "housing:furniture:purchase",
    })
    if not committed(charge) then
        return {
            accepted = false,
            code = charge and charge.error == "INSUFFICIENT_FUNDS" and "insufficient_funds" or "purchase_failed",
            error = charge and charge.error or "purchase_failed",
            retryable = retryable(charge),
        }
    end

    local layout, layoutError = self:_layout(playerId)
    if not layout then
        return {
            accepted = false,
            code = "inventory_delivery_pending",
            error = layoutError,
            retryable = true,
            requestId = requestId,
        }
    end
    local delivery = layout:commit({
        operationId = "housing:furni:deliver:" .. requestId,
        kind = "add_inventory",
        itemId = itemId,
        quantity = 1,
    })
    if not committed(delivery) then
        return {
            accepted = false,
            code = "inventory_delivery_pending",
            error = delivery and delivery.error or "inventory_delivery_failed",
            retryable = retryable(delivery),
            requestId = requestId,
        }
    end

    local response = self:_response(playerId, authorization, layout)
    response.code = "furniture_purchased"
    response.itemId = itemId
    response.price = item.price
    response.replayed = charge.status == "duplicate" or delivery.status == "duplicate"
    return response
end

function Controller:place(playerId, itemId, transform, requestId)
    local authorization, denied = self:_authorization(playerId, true)
    if denied then return denied end
    if not self:_validateRequest(requestId) then
        return { accepted = false, code = "invalid_request_id" }
    end
    if not self._catalogById[itemId] then return { accepted = false, code = "unknown_item" } end
    if not self:_validateTransform(transform) then return { accepted = false, code = "invalid_transform" } end

    local layout, layoutError = self:_layout(playerId)
    if not layout then return { accepted = false, code = "layout_unavailable", error = layoutError, retryable = true } end

    local consume = layout:commit({
        operationId = "housing:furni:consume:" .. requestId,
        kind = "remove_inventory",
        itemId = itemId,
        quantity = 1,
    })
    if not committed(consume) then
        return {
            accepted = false,
            code = consume and consume.error == "INSUFFICIENT_INVENTORY" and "insufficient_inventory" or "placement_failed",
            error = consume and consume.error or "inventory_consume_failed",
            retryable = retryable(consume),
        }
    end

    local placementId = "furni:" .. tostring(playerId) .. ":" .. requestId
    local placed = layout:commit({
        operationId = "housing:furni:place:" .. requestId,
        kind = "place_furniture",
        placementId = placementId,
        itemId = itemId,
        x = transform.x,
        y = transform.y,
        z = transform.z,
        rotation = normalizeRotation(transform.rotation),
        paintId = "default",
    })
    if not committed(placed) then
        return {
            accepted = false,
            code = "placement_pending",
            error = placed and placed.error or "placement_failed",
            retryable = retryable(placed) or (placed and placed.status == "conflict"),
            requestId = requestId,
            placementId = placementId,
        }
    end

    local response = self:_response(playerId, authorization, layout)
    response.code = "furniture_placed"
    response.placementId = placementId
    response.replayed = consume.status == "duplicate" or placed.status == "duplicate"
    return response
end

function Controller:move(playerId, placementId, transform, requestId)
    local authorization, denied = self:_authorization(playerId, true)
    if denied then return denied end
    if not self:_validateRequest(requestId) or not nonEmpty(placementId) then
        return { accepted = false, code = "invalid_request" }
    end
    if not self:_validateTransform(transform) then return { accepted = false, code = "invalid_transform" } end

    local layout, err = self:_layout(playerId)
    if not layout then return { accepted = false, code = "layout_unavailable", error = err, retryable = true } end
    local moved = layout:commit({
        operationId = "housing:furni:move:" .. requestId,
        kind = "move_furniture",
        placementId = placementId,
        x = transform.x,
        y = transform.y,
        z = transform.z,
        rotation = normalizeRotation(transform.rotation),
    })
    if not committed(moved) then
        return { accepted = false, code = "move_failed", error = moved and moved.error, retryable = retryable(moved) }
    end
    local response = self:_response(playerId, authorization, layout)
    response.code = "furniture_moved"
    response.placementId = placementId
    return response
end

function Controller:rotate(playerId, placementId, deltaDegrees, requestId)
    local authorization, denied = self:_authorization(playerId, true)
    if denied then return denied end
    if not self:_validateRequest(requestId) or not nonEmpty(placementId) then
        return { accepted = false, code = "invalid_request" }
    end
    if deltaDegrees ~= 90 and deltaDegrees ~= -90 then
        return { accepted = false, code = "invalid_rotation" }
    end

    local layout, err = self:_layout(playerId)
    if not layout then return { accepted = false, code = "layout_unavailable", error = err, retryable = true } end
    local placement = findPlacement(layout:getState(), placementId)
    if not placement then return { accepted = false, code = "placement_not_found" } end

    local rotated = layout:commit({
        operationId = "housing:furni:rotate:" .. requestId,
        kind = "move_furniture",
        placementId = placementId,
        x = placement.x,
        y = placement.y,
        z = placement.z,
        rotation = normalizeRotation(placement.rotation + deltaDegrees),
    })
    if not committed(rotated) then
        return { accepted = false, code = "rotate_failed", error = rotated and rotated.error, retryable = retryable(rotated) }
    end
    local response = self:_response(playerId, authorization, layout)
    response.code = "furniture_rotated"
    response.placementId = placementId
    return response
end

function Controller:remove(playerId, placementId, itemId, requestId)
    local authorization, denied = self:_authorization(playerId, true)
    if denied then return denied end
    if not self:_validateRequest(requestId) or not nonEmpty(placementId) then
        return { accepted = false, code = "invalid_request" }
    end
    if not self._catalogById[itemId] then return { accepted = false, code = "unknown_item" } end

    local layout, err = self:_layout(playerId)
    if not layout then return { accepted = false, code = "layout_unavailable", error = err, retryable = true } end
    local currentPlacement = findPlacement(layout:getState(), placementId)
    if currentPlacement and currentPlacement.itemId ~= itemId then
        return { accepted = false, code = "placement_item_mismatch" }
    end

    local removed = layout:commit({
        operationId = "housing:furni:remove:" .. requestId,
        kind = "remove_furniture",
        placementId = placementId,
        itemId = itemId,
    })
    if not committed(removed) then
        return { accepted = false, code = "remove_failed", error = removed and removed.error, retryable = retryable(removed) }
    end
    local returned = layout:commit({
        operationId = "housing:furni:return:" .. requestId,
        kind = "add_inventory",
        itemId = itemId,
        quantity = 1,
    })
    if not committed(returned) then
        return {
            accepted = false,
            code = "inventory_return_pending",
            error = returned and returned.error,
            retryable = true,
            requestId = requestId,
        }
    end
    local response = self:_response(playerId, authorization, layout)
    response.code = "furniture_removed"
    response.itemId = itemId
    return response
end

function Controller:sellInventory(playerId, itemId, requestId)
    local authorization, denied = self:_authorization(playerId, true)
    if denied then return denied end
    if not self:_validateRequest(requestId) then
        return { accepted = false, code = "invalid_request_id" }
    end
    local item = self._catalogById[itemId]
    if not item then return { accepted = false, code = "unknown_item" } end

    local layout, layoutError = self:_layout(playerId)
    if not layout then return { accepted = false, code = "layout_unavailable", error = layoutError, retryable = true } end
    local removed = layout:commit({
        operationId = "housing:furni:sell-remove:" .. requestId,
        kind = "remove_inventory",
        itemId = itemId,
        quantity = 1,
    })
    if not committed(removed) then
        return {
            accepted = false,
            code = removed and removed.error == "INSUFFICIENT_INVENTORY" and "insufficient_inventory" or "sell_failed",
            error = removed and removed.error,
            retryable = retryable(removed),
        }
    end

    local economy, economyError = self:_economy(playerId)
    if not economy then
        return {
            accepted = false,
            code = "sell_credit_pending",
            error = economyError,
            retryable = true,
            requestId = requestId,
        }
    end
    local credit = economy:record({
        operationId = "housing:furni:sell-credit:" .. requestId,
        playerId = playerId,
        delta = item.sellPrice,
        reason = "housing:furniture:sell",
    })
    if not committed(credit) then
        return {
            accepted = false,
            code = "sell_credit_pending",
            error = credit and credit.error,
            retryable = retryable(credit),
            requestId = requestId,
        }
    end

    local response = self:_response(playerId, authorization, layout)
    response.code = "furniture_sold"
    response.itemId = itemId
    response.sellPrice = item.sellPrice
    response.balance = credit.state and credit.state.balance or nil
    response.replayed = removed.status == "duplicate" or credit.status == "duplicate"
    return response
end

function Controller:paint(playerId, placementId, paintId, requestId)
    local authorization, denied = self:_authorization(playerId, true)
    if denied then return denied end
    if not self:_validateRequest(requestId) or not nonEmpty(placementId) then
        return { accepted = false, code = "invalid_request" }
    end
    if PAINTS[paintId] ~= true then return { accepted = false, code = "invalid_paint" } end
    local layout, err = self:_layout(playerId)
    if not layout then return { accepted = false, code = "layout_unavailable", error = err, retryable = true } end
    local painted = layout:commit({
        operationId = "housing:furni:paint:" .. requestId,
        kind = "paint_furniture",
        placementId = placementId,
        paintId = paintId,
    })
    if not committed(painted) then
        return { accepted = false, code = "paint_failed", error = painted and painted.error, retryable = retryable(painted) }
    end
    local response = self:_response(playerId, authorization, layout)
    response.code = "furniture_painted"
    response.placementId = placementId
    return response
end

function Controller:setHideWalls(playerId, enabled, requestId)
    local authorization, denied = self:_authorization(playerId, true)
    if denied then return denied end
    if not self:_validateRequest(requestId) or type(enabled) ~= "boolean" then
        return { accepted = false, code = "invalid_request" }
    end
    local layout, err = self:_layout(playerId)
    if not layout then return { accepted = false, code = "layout_unavailable", error = err, retryable = true } end
    local receipt = layout:commit({
        operationId = "housing:walls:" .. requestId,
        kind = "set_hide_walls",
        enabled = enabled,
    })
    if not committed(receipt) then
        return { accepted = false, code = "hide_walls_failed", error = receipt and receipt.error, retryable = retryable(receipt) }
    end
    local response = self:_response(playerId, authorization, layout)
    response.code = enabled and "walls_hidden" or "walls_shown"
    return response
end

function Controller:setHouseStyle(playerId, styleId, requestId)
    local authorization, denied = self:_authorization(playerId, true)
    if denied then return denied end
    if not self:_validateRequest(requestId) or not nonEmpty(styleId) then
        return { accepted = false, code = "invalid_request" }
    end
    local layout, err = self:_layout(playerId)
    if not layout then return { accepted = false, code = "layout_unavailable", error = err, retryable = true } end
    local receipt = layout:commit({
        operationId = "housing:style:" .. requestId,
        kind = "set_house_style",
        styleId = styleId,
    })
    if not committed(receipt) then
        return { accepted = false, code = "style_failed", error = receipt and receipt.error, retryable = retryable(receipt) }
    end
    local response = self:_response(playerId, authorization, layout)
    response.code = "style_changed"
    return response
end

return Controller
