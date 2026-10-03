local Controller = assert(loadfile("school/src/server/OutfitOperationsController.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local saved = {}
local filterCalls = {}
local applied = nil

local repository = {
    loadOutfit = function(_, slot)
        return saved[slot] or Controller.DEFAULTS, nil
    end,
    loadOutfitPage = function(_, startSlot)
        local page = {}
        for slot = startSlot, math.min(startSlot + 2, 12) do
            page[#page + 1] = { slot = slot, outfit = saved[slot] or Controller.DEFAULTS }
        end
        return page, nil
    end,
    saveOutfit = function(_, slot, outfit)
        saved[slot] = outfit
        return { durable = true, revision = 1, outfit = outfit }
    end,
}

local controller = Controller.new(
    function(playerId)
        eq(playerId, 101, "repository player id")
        return repository
    end,
    function(value, field)
        filterCalls[#filterCalls + 1] = field
        return "[filtered]" .. value
    end,
    function(player, outfit)
        applied = { player = player, outfit = outfit }
        return true
    end
)

local invalidSlot = controller:loadOutfit(101, 13)
eq(invalidSlot.accepted, false, "slot 13 rejected")
eq(invalidSlot.code, "invalid_outfit_slot", "slot 13 code")

local invalidPage = controller:loadOutfitPage(101, 2)
eq(invalidPage.accepted, false, "page 2 rejected")
eq(invalidPage.code, "invalid_outfit_page", "page 2 code")

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
local save = controller:saveOutfit(101, 12, input)
eq(save.accepted, true, "save accepted")
eq(save.outfit.OutfitName, "[filtered]Hero", "outfit name filtered")
eq(save.outfit.RPName, "[filtered]Alex", "rp name filtered")
eq(save.outfit.RPDesc, "[filtered]Student", "rp desc filtered")
eq(save.outfit.Hat1, 11, "hat1 preserved")
eq(save.outfit.Hat3, 33, "three-hat baseline preserved")
eq(#filterCalls, 3, "exact filtered field count")

local page = controller:loadOutfitPage(101, 10)
eq(page.accepted, true, "page 10 accepted")
eq(#page.outfits, 3, "last page size")
eq(page.outfits[3].slot, 12, "last page reaches slot 12")

local player = { UserId = 101 }
local wear = controller:wearOutfit(101, 12, player)
eq(wear.accepted, true, "wear accepted")
eq(applied.player, player, "server apply receives player")
eq(applied.outfit.OutfitName, "[filtered]Hero", "wear uses durable filtered outfit")

local defaults = controller:saveOutfit(101, 1, {})
eq(defaults.accepted, true, "defaults accepted")
eq(defaults.outfit.Hat1, 0, "default Hat1")
eq(defaults.outfit.Hat2, 0, "default Hat2")
eq(defaults.outfit.Hat3, 0, "default Hat3")
eq(defaults.outfit.RemoveShirt, false, "default RemoveShirt")

print("HIGH_SCHOOL_OUTFIT_OPERATIONS_PASS")
