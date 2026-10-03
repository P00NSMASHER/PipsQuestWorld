local reference = dofile("school/tests/fixtures/legacy_avatar_customization_shopping_reference.lua")

local function equals(actual, expected, label)
    if actual ~= expected then
        error("invalid avatar/customization reference: " .. label, 2)
    end
end

equals(reference.schemaVersion, 1, "schema version")
equals(reference.verified.avatarCustomizationExists, true, "avatar customization existence")
equals(reference.verified.outfitHatSlots, 9, "Legacy outfit hat slots")
equals(reference.verified.clothingPurchase.interaction, "click_item_to_purchase", "clothing purchase interaction")
equals(reference.verified.clothingPurchase.wearPath, "roblox_website_avatar", "clothing wear path")
equals(reference.verified.clothingPurchase.typicalPriceRobux, 5, "verified clothing price")
equals(reference.verified.locations.schoolSpirit, "School Spirit", "School Spirit label")
equals(reference.verified.locations.mall, "The Mall", "The Mall label")
equals(reference.verified.schoolSpirit.priceRobux, 5, "School Spirit price")

local expectedStores = {
    ["Nilvou"] = true,
    ["MrMudMan"] = true,
    ["Bad Ghoul RiRi"] = true,
    ["Pastelly"] = true,
    ["Jovani"] = true,
    ["Sheric"] = true,
    ["MissMudMan"] = true,
    ["SouledOut & SouledIn"] = true,
}

local seenStores = {}
for _, storeName in ipairs(reference.verified.mallStores or {}) do
    if seenStores[storeName] then
        error("invalid avatar/customization reference: duplicate mall store " .. storeName, 2)
    end
    seenStores[storeName] = true
end
equals(#(reference.verified.mallStores or {}), 8, "verified mall store count")
for storeName in pairs(expectedStores) do
    equals(seenStores[storeName], true, "missing verified mall store " .. storeName)
end

local evidenceIds = {}
for _, evidence in ipairs(reference.evidence or {}) do
    if type(evidence.id) ~= "string" or evidence.id == "" then
        error("invalid avatar/customization reference: evidence id missing", 2)
    end
    if evidenceIds[evidence.id] then
        error("invalid avatar/customization reference: duplicate evidence id " .. evidence.id, 2)
    end
    if type(evidence.locator) ~= "string" or evidence.locator == "" then
        error("invalid avatar/customization reference: evidence locator missing for " .. evidence.id, 2)
    end
    equals(evidence.use, "corroboration_only", "public evidence must remain corroboration only")
    evidenceIds[evidence.id] = true
end
equals(#(reference.evidence or {}), 6, "evidence source count")

for unknownName, isUnknown in pairs(reference.explicitUnknowns or {}) do
    equals(isUnknown, true, "unknown must remain explicit: " .. tostring(unknownName))
end

equals(#(reference.assetProvenance.referencedAssetIds or {}), 0, "no unverified clothing asset ids")
equals(reference.assetProvenance.publicCorroborationIsNotAssetAuthorization, true, "public evidence is not asset authorization")
equals(reference.boundaries.runtimeAuthority, false, "Content QA runtime authority")
equals(reference.boundaries.economyAuthority, false, "Content QA economy authority")
equals(reference.boundaries.persistenceAuthority, false, "Content QA persistence authority")
equals(reference.boundaries.worldAuthority, false, "Content QA world authority")
equals(reference.boundaries.productCodeImportedFromLegacyRuntime, false, "retired runtime import")
equals(reference.boundaries.phase2EducationAllowed, false, "Phase-2 education remains deferred")

print("HIGH_SCHOOL_AVATAR_CUSTOMIZATION_REFERENCE_PASS")
