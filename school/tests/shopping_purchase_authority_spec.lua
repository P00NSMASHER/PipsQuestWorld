local Controller = assert(loadfile("school/src/server/ShoppingPurchaseController.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local empty = Controller.new({})

local forged = empty:requestPurchase(101, "fake-item", "req-1", {
    assetId = 999999,
    template = "ShirtTemplate",
    price = 1,
    currency = "RHS Cash",
    owned = true,
})
eq(forged.accepted, false, "forged request accepted")
eq(forged.code, "unknown_item", "unknown item code")
eq(forged.purchaseStarted, false, "unknown item started purchase")
eq(forged.purchaseConfirmed, false, "unknown item confirmed purchase")
eq(forged.successText, nil, "unknown item leaked success")

local replay = empty:requestPurchase(101, "fake-item", "req-1", {
    assetId = 999999,
    template = "ShirtTemplate",
    price = 1,
    currency = "RHS Cash",
    owned = true,
})
eq(replay.code, "unknown_item", "stable replay changed result")

local conflict = empty:requestPurchase(101, "different-item", "req-1", nil)
eq(conflict.accepted, false, "request-id conflict accepted")
eq(conflict.code, "request_id_conflict", "request-id conflict code")

local unknownCallback = empty:confirmPurchase(101, 999999, true)
eq(unknownCallback.accepted, false, "unknown callback accepted")
eq(unknownCallback.code, "unknown_asset", "unknown callback code")
eq(unknownCallback.successText, nil, "unknown callback leaked success")

-- Unit-only allowlist proves authority/callback behavior. Product catalog remains empty.
local authorized = Controller.new({
    verified = {
        kind = "shirt",
        assetId = 123,
        templateField = "ShirtTemplate",
    },
})
local requested = authorized:requestPurchase(101, "verified", "req-2", {
    assetId = 999,
    template = "PantsTemplate",
    price = 0,
    currency = "RHS Cash",
    owned = true,
})
eq(requested.accepted, true, "server allowlisted item rejected")
eq(requested.code, "purchase_confirmation_required", "pre-confirm code")
eq(requested.assetId, 123, "client asset claim overrode server catalog")
eq(requested.templateField, "ShirtTemplate", "client template claim overrode server catalog")
eq(requested.purchaseStarted, false, "controller auto-started purchase")
eq(requested.purchaseConfirmed, false, "controller auto-confirmed purchase")
eq(requested.successText, nil, "success leaked before callback")

local notPurchased = authorized:confirmPurchase(101, 123, false)
eq(notPurchased.accepted, false, "cancelled purchase accepted")
eq(notPurchased.code, "purchase_not_confirmed", "cancelled purchase code")
eq(notPurchased.successText, nil, "cancelled purchase leaked success")

local confirmed = authorized:confirmPurchase(101, 123, true)
eq(confirmed.accepted, true, "confirmed callback rejected")
eq(confirmed.code, "purchase_confirmed", "confirmed callback code")
eq(confirmed.purchaseConfirmed, true, "confirmed callback missing flag")
eq(
    confirmed.successText,
    "Item purchased successfully! You can wear it via the Character tab on the ROBLOX website.",
    "exact success text"
)

local duplicateConfirm = authorized:confirmPurchase(101, 123, true)
eq(duplicateConfirm.accepted, true, "duplicate confirmation rejected")
eq(duplicateConfirm.code, "purchase_already_confirmed", "duplicate confirmation idempotency")
eq(duplicateConfirm.successText, Controller.SUCCESS_TEXT, "duplicate exact success text")

eq(#Controller.REFERENCE_SIGNALS, 6, "verified signal count")
eq(Controller.REFERENCE_SIGNALS[1], "BuyClothing", "BuyClothing signal")
eq(Controller.REFERENCE_SIGNALS[2], "ShopGui", "ShopGui signal")
eq(Controller.REFERENCE_SIGNALS[3], "Clothing Display", "Clothing Display signal")
eq(Controller.REFERENCE_SIGNALS[4], "ShirtID", "ShirtID signal")
eq(Controller.REFERENCE_SIGNALS[5], "PantsID", "PantsID signal")
eq(Controller.REFERENCE_SIGNALS[6], "PurchasePermanentItem", "PurchasePermanentItem signal")
eq(Controller.TEMPLATE_FIELDS[1], "ShirtTemplate", "shirt template field")
eq(Controller.TEMPLATE_FIELDS[2], "PantsTemplate", "pants template field")
eq(Controller.CURRENCY, "Robux", "verified currency")

print("HIGH_SCHOOL_SHOPPING_PURCHASE_AUTHORITY_PASS")
