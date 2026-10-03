-- Content-QA reference contract for Legacy avatar/customization/shopping parity.
-- Reference/provenance data only: no runtime authority and no copied Legacy product code.

return {
    schemaVersion = 3,
    target = "ROBLOX High School [Legacy] pinned authorized baseline",

    pinnedBaseline = {
        gitBlobSha = "95ee3d762f419bb3572e18db57c03682651dc8c4",
        sha256 = "d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360",
        extractionRunId = 37117603516,
        extractionJobId = 111187324599,
        extractionArtifactId = 11272277500,
        deepExtractionRunId = 37117831711,
        deepExtractionJobId = 111187960403,
        deepExtractionArtifactId = 11271783526,
        cloudArtifactMaterializationVerified = true,
        verifiedBytes = 2283775,
    },

    exactBaselineOutfit = {
        entryGuis = {
            desktop = "Outfits",
            mobile = "OutfitsMobile",
            console = "OutfitsConsole",
        },
        eventNames = {
            "LoadOutfit",
            "LoadOutfitPage",
            "WearOutfit",
            "SaveOutfit",
        },
        hierarchyNames = {
            "OutfitInputs",
            "OutfitSlots",
            "OutfitPages",
            "Hat1",
            "Hat2",
            "Hat3",
            "Shirt",
            "Pants",
            "Face",
            "RemoveShirt",
            "OutfitName",
            "RPName",
            "RPDesc",
            "BaseSlot",
            "MorphsFrame",
        },
        visibleLabels = {
            "Wear Outfit",
            "Save Outfit:",
            "Hat 1:",
            "Hat 2:",
            "Hat 3:",
            "Shirt:",
            "Pants:",
            "Remove Shirt:",
            "Outfit Name:",
            "Empty",
            "Custom Outfits",
            "[Morphs only work with R6]",
        },
        persistedFields = {
            "OutfitName",
            "Hat1",
            "Hat2",
            "Hat3",
            "Shirt",
            "Pants",
            "Face",
            "Package",
            "RPName",
            "RPDesc",
            "RemoveShirt",
        },
        persistedDefaults = {
            OutfitName = "",
            Hat1 = 0,
            Hat2 = 0,
            Hat3 = 0,
            Shirt = 0,
            Pants = 0,
            Face = 0,
            Package = 0,
            RPName = "",
            RPDesc = "",
            RemoveShirt = false,
        },
        pageStartSlots = { 1, 4, 7, 10 },
        hatInputCount = 3,
        savedOutfitSlotCount = 12,
        morphsRequireR6 = true,
        serverAuthority = {
            wearRemote = "WearOutfit",
            saveRemote = "SaveOutfit",
            morphRemote = "ChangeBodyMorph",
            filteredIdentityFields = { "OutfitName", "RPName", "RPDesc" },
        },
    },

    verifiedShopping = {
        clothingPurchase = {
            interaction = "click_item_to_purchase",
            wearPath = "roblox_website_avatar",
            currency = "Robux",
            typicalPriceRobux = 5,
        },
        exactBinarySignals = {
            "BuyClothing",
            "ShopGui",
            "Clothing Display",
            "ShirtID",
            "PantsID",
            "PurchasePermanentItem",
        },
        exactBinaryBehavior = {
            purchaseRemote = "PurchasePermanentItem",
            shirtTemplateField = "ShirtTemplate",
            pantsTemplateField = "PantsTemplate",
            successNotification = "Item purchased successfully! You can wear it via the Character tab on the ROBLOX website.",
        },
        locations = {
            schoolSpirit = "School Spirit",
            mall = "The Mall",
        },
        mallStores = {
            "Nilvou",
            "MrMudMan",
            "Bad Ghoul RiRi",
            "Pastelly",
            "Jovani",
            "Sheric",
            "MissMudMan",
            "SouledOut & SouledIn",
        },
    },

    laterLegacyChange = {
        -- Public 2024 Legacy documentation describes a later revision than the
        -- pinned binary baseline. Do not mix this into exact-baseline parity.
        publicOutfitHatSlots = 9,
        appliesToPinnedBaseline = false,
    },

    evidence = {
        {
            id = "licensed-binary-extraction",
            kind = "authorized_binary_reference",
            locator = "GitHub Actions run 37117603516 / artifact 11272277500",
            use = "licensed_reference",
            supports = "exact outfit hierarchy/event names/visible labels, three pinned-baseline hat inputs, twelve outfit slots, clothing/shop binary signals",
        },
        {
            id = "licensed-binary-artifact-deep-inspection",
            kind = "authorized_binary_reference",
            locator = "GitHub Actions run 37117831711 / job 111187960403 / artifact 11271783526",
            use = "licensed_reference",
            supports = "device-specific outfit entry GUIs, persisted outfit field schema/defaults, page start slots, R6 morph warning, WearOutfit/SaveOutfit/ChangeBodyMorph server seams, filtered identity fields, PurchasePermanentItem and clothing-template extraction behavior",
        },
        {
            id = "legacy-wiki-home",
            kind = "public_corroboration",
            locator = "https://roblox-high-school.fandom.com/wiki/Roblox_High_School_Wiki",
            use = "corroboration_only",
            supports = "avatar customization exists; later 2024 revision documents nine hat slots",
        },
        {
            id = "legacy-mall",
            kind = "public_corroboration",
            locator = "https://roblox-high-school.fandom.com/wiki/Category:The_Mall",
            use = "corroboration_only",
            supports = "The Mall is a clothing-shopping location and identifies eight current stores",
        },
        {
            id = "legacy-school-spirit",
            kind = "public_corroboration",
            locator = "https://roblox-high-school.fandom.com/wiki/School_Spirit",
            use = "corroboration_only",
            supports = "School Spirit clothing examples cost five Robux",
        },
        {
            id = "legacy-rose",
            kind = "public_corroboration",
            locator = "https://roblox-high-school.fandom.com/wiki/Rose",
            use = "corroboration_only",
            supports = "click-item clothing purchase and Roblox website avatar wear path",
        },
    },

    explicitUnknowns = {
        exactClothingAssetIdsForFirstSlice = true,
        exactFullStoreItemCatalog = true,
        exactMallStoreInteriorHierarchy = true,
        exactLater2024OutfitEditorHierarchy = true,
    },

    nonConflationRules = {
        "Pinned authorized binary baseline governs exact clone parity when later public Legacy documentation conflicts.",
        "Do not present later nine-hat 2024 behavior as exact for the pinned three-hat baseline.",
        "Do not invent clothing asset IDs or full store item catalogs.",
        "Do not treat the Game Pass Shop as the clothing-store purchase flow.",
        "Do not charge RHS Cash for the verified clothing-store flow that uses Robux.",
    },

    assetProvenance = {
        referencedAssetIds = {},
        publicCorroborationIsNotAssetAuthorization = true,
    },

    boundaries = {
        runtimeAuthority = false,
        economyAuthority = false,
        persistenceAuthority = false,
        worldAuthority = false,
        productCodeImportedFromLegacyRuntime = false,
        phase2EducationAllowed = false,
    },
}
