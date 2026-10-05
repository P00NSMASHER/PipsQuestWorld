--!strict
-- Server-authoritative cash purchase and ownership boundary for the Style Shop.

local Controller = {}
Controller.__index = Controller

local MAX_REQUEST_ID_LENGTH = 64
local OWNERSHIP_CATEGORY = "style"

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function validIdentifier(value, maximumLength)
    return type(value) == "string"
        and #value > 0
        and #value <= maximumLength
        and value:match("^[%w_%-]+$") ~= nil
end

local function copyColor(color)
    return { color[1], color[2], color[3] }
end

local function publicItem(item)
    return {
        id = item.id,
        displayName = item.displayName,
        category = item.category,
        slot = item.slot,
        shape = item.shape,
        price = item.price,
        description = item.description,
        primary = copyColor(item.primary),
        secondary = copyColor(item.secondary),
        originalContent = true,
    }
end

local function validColor(color)
    if type(color) ~= "table" or #color ~= 3 then return false end
    for _, component in ipairs(color) do
        if not isInteger(component) or component < 0 or component > 255 then return false end
    end
    return true
end

local function validateItem(item)
    if type(item) ~= "table"
        or not validIdentifier(item.id, 48)
        or type(item.displayName) ~= "string"
        or item.displayName == ""
        or type(item.description) ~= "string"
        or item.description == ""
        or not isInteger(item.price)
        or item.price < 1
        or item.originalContent ~= true
        or not validColor(item.primary)
        or not validColor(item.secondary) then
        return false
    end
    if item.category ~= "Tops" and item.category ~= "Bottoms" and item.category ~= "Accessories" then
        return false
    end
    if item.slot ~= "top" and item.slot ~= "bottom" and item.slot ~= "accessory" then
        return false
    end
    if item.slot == "accessory"
        and item.shape ~= "backpack"
        and item.shape ~= "glasses"
        and item.shape ~= "headband" then
        return false
    end
    return true
end

local function ownedSet(state)
    local owned = {}
    for _, unlock in ipairs(state.ownership or {}) do
        if unlock.category == OWNERSHIP_CATEGORY then
            owned[unlock.itemId] = true
        end
    end
    return owned
end

function Controller.new(catalog, repositoryProvider)
    assert(type(catalog) == "table", "catalog is required")
    assert(type(repositoryProvider) == "function", "repository provider is required")

    local ordered = {}
    local byId = {}
    for index, item in ipairs(catalog) do
        assert(validateItem(item), "invalid style shop catalog item at index " .. tostring(index))
        assert(byId[item.id] == nil, "duplicate style shop item: " .. item.id)
        ordered[index] = item
        byId[item.id] = item
    end
    assert(#ordered > 0 and #ordered <= 24, "style shop catalog must contain 1-24 items")

    return setmetatable({
        _catalog = ordered,
        _byId = byId,
        _repositoryProvider = repositoryProvider,
    }, Controller)
end

function Controller:_open(playerId)
    if not isInteger(playerId) or playerId <= 0 then
        return nil, "invalid_player"
    end
    local repository, openError = self._repositoryProvider(playerId)
    if repository == nil then
        return nil, "economy_unavailable:" .. tostring(openError or "unknown")
    end
    return repository, nil
end

function Controller:_state(repository)
    local economy = repository:getState()
    local items = {}
    for index, item in ipairs(self._catalog) do
        items[index] = publicItem(item)
    end
    return {
        balance = economy.balance,
        revision = economy.revision,
        owned = ownedSet(economy),
        items = items,
    }
end

function Controller:getState(playerId)
    local repository, openError = self:_open(playerId)
    if repository == nil then
        return { accepted = false, code = openError }
    end
    local state = self:_state(repository)
    state.accepted = true
    state.code = "state_ready"
    return state
end

function Controller:purchase(playerId, itemId, requestId)
    if not validIdentifier(requestId, MAX_REQUEST_ID_LENGTH) then
        return { accepted = false, code = "invalid_request_id" }
    end
    if not validIdentifier(itemId, 48) then
        return { accepted = false, code = "invalid_item" }
    end

    local item = self._byId[itemId]
    if item == nil then
        return { accepted = false, code = "unknown_item" }
    end

    local repository, openError = self:_open(playerId)
    if repository == nil then
        return { accepted = false, code = openError, retryable = true }
    end

    local receipt = repository:record({
        operationId = "style-shop:" .. requestId,
        playerId = playerId,
        delta = -item.price,
        reason = "style-shop:purchase:" .. item.id,
        unlock = {
            category = OWNERSHIP_CATEGORY,
            itemId = item.id,
        },
    })

    if receipt.status == "applied" or receipt.status == "duplicate" then
        local state = self:_state(repository)
        state.accepted = true
        state.code = receipt.status == "applied" and "purchased" or "purchase_already_processed"
        state.itemId = item.id
        state.durable = receipt.durable == true
        return state
    end

    local code = "purchase_failed"
    if receipt.error == "INSUFFICIENT_FUNDS" then
        code = "insufficient_funds"
    elseif receipt.error == "ALREADY_OWNED" then
        code = "already_owned"
    elseif receipt.error == "OPERATION_ID_CONFLICT" then
        code = "request_id_conflict"
    elseif type(receipt.error) == "string" and receipt.error:find("SAVE_", 1, true) then
        code = "persistence_unavailable"
    end

    local state = self:_state(repository)
    state.accepted = code == "already_owned"
    state.code = code
    state.itemId = item.id
    state.retryable = code == "persistence_unavailable"
    return state
end

function Controller:authorizeEquip(playerId, itemId)
    if not validIdentifier(itemId, 48) then
        return { accepted = false, code = "invalid_item" }
    end
    local item = self._byId[itemId]
    if item == nil then
        return { accepted = false, code = "unknown_item" }
    end

    local repository, openError = self:_open(playerId)
    if repository == nil then
        return { accepted = false, code = openError }
    end
    if ownedSet(repository:getState())[itemId] ~= true then
        return { accepted = false, code = "not_owned" }
    end
    return {
        accepted = true,
        code = "equip_authorized",
        item = publicItem(item),
    }
end

Controller.MAX_REQUEST_ID_LENGTH = MAX_REQUEST_ID_LENGTH
Controller.OWNERSHIP_CATEGORY = OWNERSHIP_CATEGORY

return Controller
