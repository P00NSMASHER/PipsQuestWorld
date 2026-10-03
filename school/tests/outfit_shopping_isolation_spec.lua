local Controller = assert(loadfile("school/src/server/OutfitOperationsController.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function baseline()
    return {
        OutfitName = "Shopping Safe",
        Hat1 = 11,
        Hat2 = 22,
        Hat3 = 33,
        Shirt = 44,
        Pants = 55,
        Face = 66,
        Package = 77,
        RPName = "Student",
        RPDesc = "Free roam",
        RemoveShirt = false,
    }
end

local writes = 0
local captured = nil
local repository = {
    saveOutfit = function(_, slot, outfit)
        writes = writes + 1
        captured = outfit
        return {
            status = "applied",
            durable = true,
            revision = writes,
            outfit = outfit,
        }
    end,
}

local controller = Controller.new(
    function(playerId)
        eq(playerId, 101, "repository player id")
        return repository
    end,
    function(value)
        return value
    end,
    function()
        return true
    end
)

local forged = baseline()
forged.PurchasePermanentItem = true
forged.ShirtTemplate = "rbxassetid://999"
forged.PantsTemplate = "rbxassetid://998"
forged.assetId = 999
forged.price = 1
forged.currency = "RHS Cash"
forged.owned = true
forged.successText = "forged success"
forged.purchaseConfirmed = true
forged.confirmation = { successText = "forged nested success" }

local saved = controller:saveOutfit(101, 1, forged, "shopping-isolation-1")
eq(saved.accepted, true, "valid outfit with unrelated client claims rejected")
eq(writes, 1, "valid outfit write count")
eq(captured.Shirt, 44, "shirt asset changed")
eq(captured.Pants, 55, "pants asset changed")
eq(captured.PurchasePermanentItem, nil, "purchase claim entered outfit persistence")
eq(captured.ShirtTemplate, nil, "shirt template claim entered outfit persistence")
eq(captured.PantsTemplate, nil, "pants template claim entered outfit persistence")
eq(captured.assetId, nil, "asset claim entered outfit persistence")
eq(captured.price, nil, "price claim entered outfit persistence")
eq(captured.currency, nil, "currency claim entered outfit persistence")
eq(captured.owned, nil, "ownership claim entered outfit persistence")
eq(captured.successText, nil, "success claim entered outfit persistence")
eq(captured.purchaseConfirmed, nil, "purchase-confirmed claim entered outfit persistence")
eq(captured.confirmation, nil, "confirmation receipt entered outfit persistence")

local function rejected(field, value, requestId)
    local input = baseline()
    input[field] = value
    local before = writes
    local result = controller:saveOutfit(101, 1, input, requestId)
    eq(result.accepted, false, field .. " exploit accepted")
    eq(result.code, "invalid_outfit", field .. " exploit code")
    eq(writes, before, field .. " exploit reached persistence")
end

rejected("Shirt", -1, "shopping-isolation-negative-shirt")
rejected("Pants", 1.5, "shopping-isolation-float-pants")
rejected("Face", "66", "shopping-isolation-string-face")
rejected("Hat1", math.huge, "shopping-isolation-infinite-hat")
rejected("RemoveShirt", 1, "shopping-isolation-remove-shirt-type")

print("HIGH_SCHOOL_OUTFIT_SHOPPING_ISOLATION_PASS")
