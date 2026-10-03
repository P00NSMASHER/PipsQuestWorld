-- Content-QA reference contract for the first Legacy avatar/customization/shopping slice.
-- Reference/provenance data only: no runtime authority and no copied Legacy product code.

return {
    schemaVersion = 1,
    target = "Roblox High School [Legacy] / Avatar Customization & Clothing Shopping V1",

    verified = {
        avatarCustomizationExists = true,
        outfitHatSlots = 9,
        clothingPurchase = {
            interaction = "click_item_to_purchase",
            wearPath = "roblox_website_avatar",
            typicalPriceRobux = 5,
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
        schoolSpirit = {
            priceRobux = 5,
            offersRhsUniformVariants = true,
            offersPeGear = true,
            offersRoleUniforms = true,
        },
    },

    evidence = {
        {
            id = "legacy-wiki-home",
            locator = "https://roblox-high-school.fandom.com/wiki/Roblox_High_School_Wiki",
            use = "corroboration_only",
            supports = "Legacy game supports avatar customization; 2024 reopening notes outfits have nine hat slots.",
        },
        {
            id = "legacy-update",
            locator = "https://roblox-high-school.fandom.com/wiki/Legacy_Update",
            use = "corroboration_only",
            supports = "2024 Legacy update: outfits have nine hat slots.",
        },
        {
            id = "legacy-mall",
            locator = "https://roblox-high-school.fandom.com/wiki/Category:The_Mall",
            use = "corroboration_only",
            supports = "The Mall is a clothing-shopping location and identifies the current eight stores.",
        },
        {
            id = "legacy-school-spirit",
            locator = "https://roblox-high-school.fandom.com/wiki/School_Spirit",
            use = "corroboration_only",
            supports = "School Spirit sells clothing for five Robux and includes RHS/role uniform variants.",
        },
        {
            id = "legacy-rose",
            locator = "https://roblox-high-school.fandom.com/wiki/Rose",
            use = "corroboration_only",
            supports = "Clothing purchase is initiated by clicking an item; purchased clothing is worn through the Roblox website avatar flow.",
        },
        {
            id = "legacy-jovani",
            locator = "https://roblox-high-school.fandom.com/wiki/Jovani",
            use = "corroboration_only",
            supports = "Mall clothing store example with five-Robux clothing purchases.",
        },
    },

    explicitUnknowns = {
        exactInGameAvatarEditorHierarchy = true,
        exactOutfitEditorVisibleLabels = true,
        exactOutfitCategoryLabels = true,
        exactClothingAssetIds = true,
        exactStoreItemCatalog = true,
        exactInGameTryOnFlow = true,
    },

    nonConflationRules = {
        "Do not present unverified avatar-editor labels/categories as Legacy-exact.",
        "Do not invent clothing asset IDs or exact store item catalogs.",
        "Do not treat the Game Pass Shop as the clothing-store purchase flow.",
        "Do not charge RHS Cash for the verified five-Robux clothing-store flow.",
        "Do not claim an in-game clothing equip/try-on flow when current evidence points to Roblox website avatar wear.",
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
