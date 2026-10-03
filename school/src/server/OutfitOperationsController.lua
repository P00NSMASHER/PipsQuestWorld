--!strict
-- Server-authoritative pinned-baseline outfit operations.
-- Persistence remains owned by ProgressionRepository; this module only validates,
-- filters, and coordinates the verified Legacy outfit operation semantics.

local Controller = {}
Controller.__index = Controller

local LEGACY_PRESENTED_SLOT_COUNT = 12
local OUTFIT_NAME_MAX_LENGTH = 25
local INVALID_NAME = "INVALID_NAME"
local NOLOAD = "noload"
local PAGE_STARTS = { [1] = true, [4] = true, [7] = true, [10] = true }

local DEFAULTS = {
    OutfitName = "",
    Hat1 = 0,
    Hat2 = 0,
    Hat3 = 0,
    Shirt = 0,
    Pants = 0,
    Face = 0,
    Package = 0,
    RPName = "",
    RPDesc = "",
    RemoveShirt = false,
}

local FILTERED_FIELDS = {
    OutfitName = true,
    RPName = true,
    RPDesc = true,
}

local FILTERED_FALLBACKS = {
    OutfitName = "Saved Outfit",
    RPName = "RP Name Here",
    RPDesc = "RP Desc Here",
}

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function validPresentedSlot(slot)
    return isInteger(slot) and slot >= 1 and slot <= LEGACY_PRESENTED_SLOT_COUNT
end

local function isEmptyOutfit(outfit)
    if type(outfit) ~= "table" then return true end
    return outfit.OutfitName == ""
        and outfit.Hat1 == 0
        and outfit.Hat2 == 0
        and outfit.Hat3 == 0
        and outfit.Shirt == 0
        and outfit.Pants == 0
        and outfit.Face == 0
        and outfit.Package == 0
        and outfit.RPName == ""
        and outfit.RPDesc == ""
        and outfit.RemoveShirt == false
end

local function filterNames(input, filterIdentity)
    if type(input) ~= "table" then return nil, "INVALID_OUTFIT" end
    local rawName = input.OutfitName
    if rawName == nil then rawName = "" end
    if type(rawName) ~= "string" then return nil, "INVALID_OUTFIT_FIELD:OutfitName" end
    if #rawName > OUTFIT_NAME_MAX_LENGTH then return nil, INVALID_NAME end

    local filtered = {}
    for _, field in ipairs({ "OutfitName", "RPName", "RPDesc" }) do
        local value = input[field]
        if value == nil then value = "" end
        if type(value) ~= "string" then return nil, "INVALID_OUTFIT_FIELD:" .. field end
        local ok, result = pcall(filterIdentity, value, field)
        if not ok or type(result) ~= "string" then return nil, "FILTER_FAILED:" .. field end
        if result:match("^%s*$") then result = FILTERED_FALLBACKS[field] end
        filtered[field] = result
    end
    return filtered, nil
end

local function sanitizeOutfit(input, filterIdentity)
    if type(input) ~= "table" then return nil, "INVALID_OUTFIT" end
    local outfit = {}
    for field, defaultValue in pairs(DEFAULTS) do
        local value = input[field]
        if value == nil then value = defaultValue end

        if type(value) ~= type(defaultValue) then
            return nil, "INVALID_OUTFIT_FIELD:" .. field
        end
        if type(defaultValue) == "number" then
            if not isInteger(value) or value < 0 then
                return nil, "INVALID_OUTFIT_FIELD:" .. field
            end
        elseif FILTERED_FIELDS[field] then
            -- Applied in one server-owned batch below so verified fallbacks and
            -- OutfitName length semantics are consistent across the seam.
        end
        outfit[field] = value
    end

    local filtered, filterError = filterNames(input, filterIdentity)
    if not filtered then return nil, filterError end
    outfit.OutfitName = filtered.OutfitName
    outfit.RPName = filtered.RPName
    outfit.RPDesc = filtered.RPDesc
    return outfit, nil
end

function Controller.new(repositoryFactory, filterIdentity, applyOutfit)
    assert(type(repositoryFactory) == "function", "repositoryFactory is required")
    assert(type(filterIdentity) == "function", "filterIdentity is required")
    assert(type(applyOutfit) == "function", "applyOutfit is required")
    return setmetatable({
        _repositoryFactory = repositoryFactory,
        _filterIdentity = filterIdentity,
        _applyOutfit = applyOutfit,
    }, Controller)
end

function Controller:_repo(playerId)
    local repository, openError = self._repositoryFactory(playerId)
    if not repository then
        return nil, tostring(openError or "OUTFIT_REPOSITORY_UNAVAILABLE")
    end
    return repository, nil
end

function Controller:loadOutfit(playerId, slot)
    if not validPresentedSlot(slot) then
        return { accepted = false, code = "invalid_outfit_slot" }
    end
    local repository, openError = self:_repo(playerId)
    if not repository then
        return { accepted = false, code = "outfit_persistence_unavailable", error = openError }
    end
    local outfit, loadError = repository:loadOutfit(slot)
    if not outfit then
        return { accepted = false, code = "outfit_load_failed", error = loadError }
    end
    if isEmptyOutfit(outfit) then
        return { accepted = true, slot = slot, status = NOLOAD, outfit = outfit }
    end
    return { accepted = true, slot = slot, status = "load", outfit = outfit }
end

function Controller:loadOutfitPage(playerId, startSlot)
    if PAGE_STARTS[startSlot] ~= true then
        return { accepted = false, code = "invalid_outfit_page" }
    end
    local repository, openError = self:_repo(playerId)
    if not repository then
        return { accepted = false, code = "outfit_persistence_unavailable", error = openError }
    end
    local page, loadError = repository:loadOutfitPage(startSlot)
    if not page then
        return { accepted = false, code = "outfit_page_load_failed", error = loadError }
    end
    for _, item in ipairs(page) do
        item.status = isEmptyOutfit(item.outfit) and NOLOAD or "load"
    end
    return { accepted = true, startSlot = startSlot, outfits = page }
end

function Controller:getFilteredNamesForOutfit(input)
    local filtered, filterError = filterNames(input, self._filterIdentity)
    if not filtered then
        return {
            accepted = false,
            code = filterError == INVALID_NAME and INVALID_NAME or "invalid_outfit_names",
            status = filterError == INVALID_NAME and INVALID_NAME or nil,
            error = filterError,
        }
    end
    return {
        accepted = true,
        OutfitName = filtered.OutfitName,
        RPName = filtered.RPName,
        RPDesc = filtered.RPDesc,
    }
end

function Controller:saveOutfit(playerId, slot, input, requestId)
    if not validPresentedSlot(slot) then
        return { accepted = false, code = "invalid_outfit_slot" }
    end
    local outfit, validationError = sanitizeOutfit(input, self._filterIdentity)
    if not outfit then
        return {
            accepted = false,
            code = validationError == INVALID_NAME and INVALID_NAME or "invalid_outfit",
            status = validationError == INVALID_NAME and INVALID_NAME or nil,
            error = validationError,
        }
    end

    local repository, openError = self:_repo(playerId)
    if not repository then
        return { accepted = false, code = "outfit_persistence_unavailable", error = openError }
    end
    local receipt = repository:saveOutfit(slot, outfit, requestId)
    if receipt.durable ~= true then
        return {
            accepted = false,
            code = "outfit_save_failed",
            error = receipt.error,
            retryable = receipt.error == "STALE_WRITE_RETRY_EXHAUSTED"
                or (type(receipt.error) == "string" and receipt.error:find("SAVE_FAILED:", 1, true) == 1),
        }
    end
    return {
        accepted = true,
        slot = slot,
        outfit = receipt.outfit,
        revision = receipt.revision,
        duplicate = receipt.status == "duplicate",
    }
end

function Controller:wearOutfit(playerId, slot, player)
    local loaded = self:loadOutfit(playerId, slot)
    if loaded.accepted ~= true then return loaded end
    if loaded.status == NOLOAD then
        return { accepted = false, code = NOLOAD, status = NOLOAD, slot = slot }
    end
    local ok, applyError = self._applyOutfit(player, loaded.outfit)
    if ok ~= true then
        return { accepted = false, code = "outfit_apply_failed", error = tostring(applyError or "unknown") }
    end
    return { accepted = true, slot = slot, outfit = loaded.outfit }
end

Controller.LEGACY_PRESENTED_SLOT_COUNT = LEGACY_PRESENTED_SLOT_COUNT
Controller.OUTFIT_NAME_MAX_LENGTH = OUTFIT_NAME_MAX_LENGTH
Controller.INVALID_NAME = INVALID_NAME
Controller.NOLOAD = NOLOAD
Controller.PAGE_STARTS = { 1, 4, 7, 10 }
Controller.DEFAULTS = DEFAULTS
Controller.FILTERED_FIELDS = { "OutfitName", "RPName", "RPDesc" }
Controller.FILTERED_FALLBACKS = FILTERED_FALLBACKS

return Controller
