local reference = dofile("school/tests/fixtures/legacy_avatar_customization_shopping_reference.lua")

local function equals(actual, expected, label)
    if actual ~= expected then
        error("invalid avatar/customization reference: " .. label, 2)
    end
end

equals(reference.schemaVersion, 2, "schema version")
equals(reference.pinnedBaseline.gitBlobSha, "95ee3d762f419bb3572e18db57c03682651dc8c4", "pinned blob")
equals(reference.pinnedBaseline.sha256, "d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360", "pinned sha256")
equals(reference.pinnedBaseline.extractionRunId, 37117603516, "extraction run")
equals(reference.pinnedBaseline.extractionArtifactId, 11272277500, "extraction artifact")

local function setOf(values, label)
    local result = {}
    for _, value in ipairs(values or {}) do
        if result[value] then
            error("invalid avatar/customization reference: duplicate " .. label .. " " .. tostring(value), 2)
        end
        result[value] = true
    end
    return result
end

local events = setOf(reference.exactBaselineOutfit.eventNames, "event")
equals(events.LoadOutfit, true, "LoadOutfit")
equals(events.LoadOutfitPage, true, "LoadOutfitPage")
equals(events.WearOutfit, true, "WearOutfit")
equals(events.SaveOutfit, true, "SaveOutfit")

local hierarchy = setOf(reference.exactBaselineOutfit.hierarchyNames, "hierarchy name")
for _, name in ipairs({
    "OutfitInputs", "OutfitSlots", "OutfitPages",
    "Hat1", "Hat2", "Hat3", "Shirt", "Pants", "RemoveShirt", "OutfitName",
}) do
    equals(hierarchy[name], true, "missing exact hierarchy name " .. name)
end

local labels = setOf(reference.exactBaselineOutfit.visibleLabels, "visible label")
for _, label in ipairs({
    "Wear Outfit", "Save Outfit:", "Hat 1:", "Hat 2:", "Hat 3:",
    "Shirt:", "Pants:", "Remove Shirt:", "Outfit Name:", "Empty",
}) do
    equals(labels[label], true, "missing exact visible label " .. label)
end

equals(reference.exactBaselineOutfit.hatInputCount, 3, "pinned baseline hat inputs")
equals(reference.exactBaselineOutfit.savedOutfitSlotCount, 12, "pinned baseline outfit slots")
equals(reference.exactBaselineOutfit.serverAuthority.wearRemote, "WearOutfit", "wear server authority")
equals(reference.exactBaselineOutfit.serverAuthority.saveRemote, "SaveOutfit", "save server authority")

equals(reference.verifiedShopping.clothingPurchase.interaction, "click_item_to_purchase", "clothing purchase interaction")
equals(reference.verifiedShopping.clothingPurchase.wearPath, "roblox_website_avatar", "clothing wear path")
equals(reference.verifiedShopping.clothingPurchase.currency, "Robux", "clothing currency")
equals(reference.verifiedShopping.clothingPurchase.typicalPriceRobux, 5, "verified clothing price")

local binarySignals = setOf(reference.verifiedShopping.exactBinarySignals, "binary signal")
for _, signal in ipairs({"BuyClothing", "ShopGui", "Clothing Display", "ShirtID", "PantsID"}) do
    equals(binarySignals[signal], true, "missing binary shopping signal " .. signal)
end

equals(reference.verifiedShopping.locations.schoolSpirit, "School Spirit", "School Spirit label")
equals(reference.verifiedShopping.locations.mall, "The Mall", "The Mall label")
equals(#(reference.verifiedShopping.mallStores or {}), 8, "verified mall store count")

equals(reference.laterLegacyChange.publicOutfitHatSlots, 9, "later public Legacy hat slots")
equals(reference.laterLegacyChange.appliesToPinnedBaseline, false, "later Legacy revision must not override pinned baseline")

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
    if evidence.use ~= "licensed_reference" and evidence.use ~= "corroboration_only" then
        error("invalid avatar/customization reference: invalid evidence use " .. evidence.id, 2)
    end
    evidenceIds[evidence.id] = true
end
equals(evidenceIds["licensed-binary-extraction"], true, "licensed binary evidence")

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
