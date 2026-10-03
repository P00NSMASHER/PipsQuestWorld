local Controller = assert(loadfile("school/src/server/OutfitOperationsController.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

local saved = {}
local requestIds = {}
local filterCalls = {}
local applied = nil

local repository = {
    loadOutfit = function(_, slot)
        return copy(saved[slot] or Controller.DEFAULTS), nil
    end,
    loadOutfitPage = function(_, startSlot)
        local page = {}
        for slot = startSlot, math.min(startSlot + 2, 12) do
            page[#page + 1] = { slot = slot, outfit = copy(saved[slot] or Controller.DEFAULTS) }
        end
        return page, nil
    end,
    saveOutfit = function(_, slot, outfit, requestId)
        if requestIds[slot] == requestId then
            local same = true
            for field, value in pairs(outfit) do
                if saved[slot][field] ~= value then same = false break end
            end
            if same then
                return { status = "duplicate", durable = true, revision = 1, outfit = copy(saved[slot]) }
            end
            return { status = "conflict", durable = false, error = "OUTFIT_REQUEST_ID_CONFLICT" }
        end
        requestIds[slot] = requestId
        saved[slot] = copy(outfit)
        return { status = "applied", durable = true, revision = 1, outfit = copy(outfit) }
    end,
}

local controller = Controller.new(
    function(playerId)
        eq(playerId, 101, "repository player id")
        return repository
    end,
    function(value, field)
        filterCalls[#filterCalls + 1] = field
        if value == "" then return "" end
        return "[filtered]" .. value
    end,
    function(player, outfit)
        applied = { player = player, outfit = outfit }
        return true
    end
)

eq(Controller.LEGACY_PRESENTED_SLOT_COUNT, 12, "legacy presented slot count")
eq(Controller.OUTFIT_NAME_MAX_LENGTH, 25, "outfit name max")
eq(Controller.INVALID_NAME, "INVALID_NAME", "invalid-name sentinel")
eq(Controller.NOLOAD, "noload", "empty asset status")

local invalidSlot = controller:loadOutfit(101, 13)
eq(invalidSlot.accepted, false, "slot 13 presentation rejected")
eq(invalidSlot.code, "invalid_outfit_slot", "slot 13 presentation code")

local empty = controller:loadOutfit(101, 1)
eq(empty.accepted, true, "empty slot load accepted")
eq(empty.status, "noload", "empty slot noload")

local invalidPage = controller:loadOutfitPage(101, 2)
eq(invalidPage.accepted, false, "page 2 rejected")
eq(invalidPage.code, "invalid_outfit_page", "page 2 code")

local tooLong = controller:getFilteredNamesForOutfit({
    OutfitName = string.rep("x", 26),
    RPName = "",
    RPDesc = "",
})
eq(tooLong.accepted, false, "long name accepted")
eq(tooLong.code, "INVALID_NAME", "long name sentinel")

local fallbacks = controller:getFilteredNamesForOutfit({
    OutfitName = "",
    RPName = "",
    RPDesc = "",
})
eq(fallbacks.accepted, true, "fallback filtering accepted")
eq(fallbacks.OutfitName, "Saved Outfit", "outfit fallback")
eq(fallbacks.RPName, "RP Name Here", "rp name fallback")
eq(fallbacks.RPDesc, "RP Desc Here", "rp desc fallback")

filterCalls = {}
local input = {
    OutfitName = "Hero",
    Hat1 = 11,
    Hat2 = 22,
    Hat3 = 33,
    Shirt = 44,
    Pants = 55,
    Face = 66,
    Package = 77,
    RPName = "Alex",
    RPDesc = "Student",
    RemoveShirt = false,
}
local save = controller:saveOutfit(101, 12, input, "req-12")
eq(save.accepted, true, "save accepted")
eq(save.outfit.OutfitName, "[filtered]Hero", "outfit name filtered")
eq(save.outfit.RPName, "[filtered]Alex", "rp name filtered")
eq(save.outfit.RPDesc, "[filtered]Student", "rp desc filtered")
eq(save.outfit.Hat1, 11, "hat1 preserved")
eq(save.outfit.Hat3, 33, "three-hat baseline preserved")
eq(#filterCalls, 3, "exact filtered field count")

local duplicate = controller:saveOutfit(101, 12, input, "req-12")
eq(duplicate.accepted, true, "duplicate retry accepted")
eq(duplicate.duplicate, true, "duplicate retry marked")

local conflictInput = copy(input)
conflictInput.Hat1 = 999
local conflictingRetry = controller:saveOutfit(101, 12, conflictInput, "req-12")
eq(conflictingRetry.accepted, false, "conflicting request reuse accepted")
eq(conflictingRetry.error, "OUTFIT_REQUEST_ID_CONFLICT", "conflicting request reuse code")

local page = controller:loadOutfitPage(101, 10)
eq(page.accepted, true, "page 10 accepted")
eq(#page.outfits, 3, "last presented page size")
eq(page.outfits[3].slot, 12, "last presented page reaches slot 12")

local player = { UserId = 101 }
local wear = controller:wearOutfit(101, 12, player)
eq(wear.accepted, true, "wear accepted")
eq(applied.player, player, "server apply receives player")
eq(applied.outfit.OutfitName, "[filtered]Hero", "wear uses durable filtered outfit")

local defaults = controller:saveOutfit(101, 1, {}, "req-default")
eq(defaults.accepted, true, "defaults accepted")
eq(defaults.outfit.OutfitName, "Saved Outfit", "default outfit fallback")
eq(defaults.outfit.RPName, "RP Name Here", "default RP name fallback")
eq(defaults.outfit.RPDesc, "RP Desc Here", "default RP desc fallback")
eq(defaults.outfit.Hat1, 0, "default Hat1")
eq(defaults.outfit.Hat2, 0, "default Hat2")
eq(defaults.outfit.Hat3, 0, "default Hat3")
eq(defaults.outfit.RemoveShirt, false, "default RemoveShirt")

print("HIGH_SCHOOL_OUTFIT_OPERATIONS_PASS")
