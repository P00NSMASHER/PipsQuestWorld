-- Content-QA reference validator. Pinned extraction run 37117831711, artifact 11271783526.
local ref = {
    requestGui = "BuyClothing",
    activeGui = "ACTIVE_BuyClothing",
    shirtId = "ShirtID",
    pantsId = "PantsID",
    shirtTemplate = "ShirtTemplate",
    pantsTemplate = "PantsTemplate",
    currency = "Robux",
    genericShopGui = "ShopGui",
    permanentItemRemote = "PurchasePermanentItem",
    success = "Item purchased successfully! You can wear it via the Character tab on the ROBLOX website.",
}

assert(ref.requestGui == "BuyClothing")
assert(ref.activeGui == "ACTIVE_BuyClothing")
assert(ref.currency == "Robux")
assert(ref.genericShopGui ~= ref.requestGui)
assert(ref.permanentItemRemote ~= ref.requestGui)
assert(ref.shirtId == "ShirtID" and ref.pantsId == "PantsID")
assert(ref.shirtTemplate == "ShirtTemplate" and ref.pantsTemplate == "PantsTemplate")

print("HIGH_SCHOOL_AVATAR_SHOPPING_NONCONFLATION_PASS")
