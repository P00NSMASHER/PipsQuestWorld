local reference = dofile("school/tests/fixtures/legacy_avatar_customization_shopping_reference.lua")

local function equals(actual, expected, label)
    if actual ~= expected then
        error("invalid avatar/customization reference: " .. label, 2)
    end
end

equals(reference.schemaVersion, 3, "schema version")
equals(reference.pinnedBaseline.gitBlobSha, "95ee3d762f419bb3572e18db57c03682651dc8c4", "pinned blob")
equals(reference.pinnedBaseline.sha256, "d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360", "pinned sha256")
equals(reference.pinnedBaseline.extractionRunId, 37117603516, "extraction run")
equals(reference.pinnedBaseline.extractionArtifactId, 11272277500, "extraction artifact")
equals(reference.pinnedBaseline.deepExtractionRunId, 37117831711, "deep extraction run")
equals(reference.pinnedBaseline.deepExtractionArtifactId, 11271783526, "deep extraction artifact")
equals(reference.pinnedBaseline.cloudArtifactMaterializationVerified, true, "cloud artifact materialization")

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

equals(reference.exactBaselineOutfit.entryGuis.desktop, "Outfits", "desktop outfit gui")
equals(reference.exactBaselineOutfit.entryGuis.mobile, "OutfitsMobile", "mobile outfit gui")
equals(reference.exactBaselineOutfit.entryGuis.console, "OutfitsConsole", "console outfit gui")

local events = setOf(reference.exactBaselineOutfit.eventNames, "event")
equals(events.LoadOutfit, true, "LoadOutfit")
equals(events.LoadOutfitPage, true, "LoadOutfitPage")
equals(events.WearOutfit, true, "WearOutfit")
equals(events.SaveOutfit, true, "SaveOutfit")

local hierarchy = setOf(reference.exactBaselineOutfit.hierarchyNames, "hierarchy name")
for _, name in ipairs({
    "OutfitInputs", "OutfitSlots", "OutfitPages",
    "Hat1", "Hat2", "Hat3", "Shirt", "Pants", "Face", "RemoveShirt", "OutfitName",
    "RPName", "RPDesc", "BaseSlot", "MorphsFrame",
}) do
    equals(hierarchy[name], true, "missing exact hierarchy name " .. name)
end

local labels = setOf(reference.exactBaselineOutfit.visibleLabels, "visible label")
for _, label in ipairs({
    "Wear Outfit", "Save Outfit:", "Hat 1:", "Hat 2:", "Hat 3:",
    "Shirt:", "Pants:", "Remove Shirt:", "Outfit Name:", "Empty",
    "Custom Outfits", "[Morphs only work with R6]",
}) do
    equals(labels[label], true, "missing exact visible label " .. label)
end

local persisted = setOf(reference.exactBaselineOutfit.persistedFields, "persisted outfit field")
for _, field in ipairs({
    "OutfitName", "Hat1", "Hat2", "Hat3", "Shirt", "Pants", "Face",
    "Package", "RPName", "RPDesc", "RemoveShirt",
}) do
    equals(persisted[field], true, "missing persisted outfit field " .. field)
end
equals(reference.exactBaselineOutfit.persistedDefaults.OutfitName, "", "outfit name default")
equals(reference.exactBaselineOutfit.persistedDefaults.Hat1, 0, "Hat1 default")
equals(reference.exactBaselineOutfit.persistedDefaults.Hat2, 0, "Hat2 default")
equals(reference.exactBaselineOutfit.persistedDefaults.Hat3, 0, "Hat3 default")
equals(reference.exactBaselineOutfit.persistedDefaults.Shirt, 0, "Shirt default")
equals(reference.exactBaselineOutfit.persistedDefaults.Pants, 0, "Pants default")
equals(reference.exactBaselineOutfit.persistedDefaults.Face, 0, "Face default")
equals(reference.exactBaselineOutfit.persistedDefaults.Package, 0, "Package default")
equals(reference.exactBaselineOutfit.persistedDefaults.RPName, "", "RPName default")
equals(reference.exactBaselineOutfit.persistedDefaults.RPDesc, "", "RPDesc default")
equals(reference.exactBaselineOutfit.persistedDefaults.RemoveShirt, false, "RemoveShirt default")
equals(#reference.exactBaselineOutfit.pageStartSlots, 4, "outfit page count")
for i, expected in ipairs({1, 4, 7, 10}) do
    equals(reference.exactBaselineOutfit.pageStartSlots[i], expected, "outfit page start slot " .. i)
end

equals(reference.exactBaselineOutfit.hatInputCount, 3, "pinned baseline hat inputs")
equals(reference.exactBaselineOutfit.savedOutfitSlotCount, 12, "pinned baseline outfit slots")
equals(reference.exactBaselineOutfit.serverAuthority.wearRemote, "WearOutfit", "wear server authority")
equals(reference.exactBaselineOutfit.serverAuthority.saveRemote, "SaveOutfit", "save server authority")
equals(reference.exactBaselineOutfit.serverAuthority.morphRemote, "ChangeBodyMorph", "morph server authority")
equals(reference.exactBaselineOutfit.morphsRequireR6, true, "pinned morph R6 rule")
local filteredFields = setOf(reference.exactBaselineOutfit.serverAuthority.filteredIdentityFields, "filtered identity field")
equals(filteredFields.OutfitName, true, "OutfitName filter")
equals(filteredFields.RPName, true, "RPName filter")
equals(filteredFields.RPDesc, true, "RPDesc filter")

equals(reference.verifiedShopping.clothingPurchase.interaction, "click_item_to_purchase", "clothing purchase interaction")
equals(reference.verifiedShopping.clothingPurchase.wearPath, "roblox_website_avatar", "clothing wear path")
equals(reference.verifiedShopping.clothingPurchase.currency, "Robux", "clothing currency")
equals(reference.verifiedShopping.clothingPurchase.typicalPriceRobux, 5, "verified clothing price")

local binarySignals = setOf(reference.verifiedShopping.exactBinarySignals, "binary signal")
for _, signal in ipairs({"BuyClothing", "ShopGui", "Clothing Display", "ShirtID", "PantsID", "PurchasePermanentItem"}) do
    equals(binarySignals[signal], true, "missing binary shopping signal " .. signal)
end

equals(reference.verifiedShopping.exactBinaryBehavior.purchaseRemote, "PurchasePermanentItem", "purchase remote")
equals(reference.verifiedShopping.exactBinaryBehavior.shirtTemplateField, "ShirtTemplate", "shirt template field")
equals(reference.verifiedShopping.exactBinaryBehavior.pantsTemplateField, "PantsTemplate", "pants template field")
equals(
    reference.verifiedShopping.exactBinaryBehavior.successNotification,
    "Item purchased successfully! You can wear it via the Character tab on the ROBLOX website.",
    "clothing purchase success notification"
)

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
equals(evidenceIds["licensed-binary-artifact-deep-inspection"], true, "deep licensed binary evidence")

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
