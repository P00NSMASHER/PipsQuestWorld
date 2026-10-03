--!strict
-- Server-authoritative pinned-baseline outfit operations.
-- Persistence remains owned by ProgressionRepository; this module only validates,
-- filters, and coordinates the verified Legacy outfit operation semantics.

local Controller = {}
Controller.__index = Controller

local SLOT_COUNT = 12
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

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

local function validSlot(slot)
    return isInteger(slot) and slot >= 1 and slot <= SLOT_COUNT
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
            local ok, filtered = pcall(filterIdentity, value, field)
            if not ok or type(filtered) ~= "string" then
                return nil, "FILTER_FAILED:" .. field
            end
            value = filtered
        end
        outfit[field] = value
    end
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
    if not validSlot(slot) then
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
    return { accepted = true, slot = slot, outfit = outfit }
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
    return { accepted = true, startSlot = startSlot, outfits = page }
end

function Controller:saveOutfit(playerId, slot, input)
    if not validSlot(slot) then
        return { accepted = false, code = "invalid_outfit_slot" }
    end
    local outfit, validationError = sanitizeOutfit(input, self._filterIdentity)
    if not outfit then
        return { accepted = false, code = "invalid_outfit", error = validationError }
    end

    local repository, openError = self:_repo(playerId)
    if not repository then
        return { accepted = false, code = "outfit_persistence_unavailable", error = openError }
    end
    local receipt = repository:saveOutfit(slot, outfit)
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
    }
end

function Controller:wearOutfit(playerId, slot, player)
    local loaded = self:loadOutfit(playerId, slot)
    if loaded.accepted ~= true then return loaded end
    local ok, applyError = self._applyOutfit(player, loaded.outfit)
    if ok ~= true then
        return { accepted = false, code = "outfit_apply_failed", error = tostring(applyError or "unknown") }
    end
    return { accepted = true, slot = slot, outfit = loaded.outfit }
end

Controller.SLOT_COUNT = SLOT_COUNT
Controller.PAGE_STARTS = { 1, 4, 7, 10 }
Controller.DEFAULTS = DEFAULTS
Controller.FILTERED_FIELDS = { "OutfitName", "RPName", "RPDesc" }

return Controller
