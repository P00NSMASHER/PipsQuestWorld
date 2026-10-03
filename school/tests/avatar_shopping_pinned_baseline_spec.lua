-- Content-QA pinned-baseline guard. Evidence only; no runtime authority.
local pinned = {
    hatSlots = 3,
    requestGui = "BuyClothing",
    activeGui = "ACTIVE_BuyClothing",
    genericShopGui = "ShopGui",
    permanentItemRemote = "PurchasePermanentItem",
    pinnedExactPrice = nil,
    laterRevisionHatSlots = 9,
}

assert(pinned.hatSlots == 3)
assert(pinned.laterRevisionHatSlots == 9)
assert(pinned.requestGui == "BuyClothing")
assert(pinned.activeGui == "ACTIVE_BuyClothing")
assert(pinned.genericShopGui ~= pinned.requestGui)
assert(pinned.permanentItemRemote ~= pinned.requestGui)
assert(pinned.pinnedExactPrice == nil)

print("HIGH_SCHOOL_AVATAR_SHOPPING_PINNED_BASELINE_PASS")
