local reference = dofile("school/tests/fixtures/legacy_outfit_persistence_reference.lua")

local function equals(actual, expected, label)
    if actual ~= expected then
        error("invalid outfit persistence reference: " .. label, 2)
    end
end

equals(reference.schemaVersion, 1, "schema version")
equals(reference.extractionRunId, 37117831711, "extraction run")
equals(reference.artifactId, 11271783526, "artifact")
equals(reference.storageSlotCount, 24, "storage slots")
equals(reference.legacyStoredSlotCount, 12, "legacy stored slots")
equals(reference.migrationExtends12To24, true, "12-to-24 migration")
equals(reference.outfitNameMaxLength, 25, "outfit-name limit")
equals(reference.invalidSentinel, "INVALID_NAME", "invalid sentinel")
equals(reference.emptyAssetStatus, "noload", "empty asset status")
equals(reference.maxWornHats, 3, "max worn hats")
equals(reference.filteredFallbacks.OutfitName, "Saved Outfit", "outfit fallback")
equals(reference.filteredFallbacks.RPName, "RP Name Here", "RP-name fallback")
equals(reference.filteredFallbacks.RPDesc, "RP Desc Here", "RP-desc fallback")
equals(reference.serverSeams.filter, "GetFilteredNamesForOutfit", "filter seam")
equals(reference.serverSeams.save, "SaveOutfit", "save seam")
equals(reference.serverSeams.wear, "WearOutfit", "wear seam")
equals(reference.serverSeams.morph, "ChangeBodyMorph", "morph seam")
equals(reference.unknowns.exactMorphCatalog, true, "morph catalog remains unknown")
equals(reference.unknowns.slots13To24Presentation, true, "slots 13-24 presentation remains unknown")

print("HIGH_SCHOOL_OUTFIT_PERSISTENCE_REFERENCE_PASS")
