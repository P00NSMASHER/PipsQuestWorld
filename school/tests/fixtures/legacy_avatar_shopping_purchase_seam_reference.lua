return {
    schemaVersion = 1,
    evidence = {
        runId = 37117831711,
        artifactId = 11271783526,
        gitBlobSha = "95ee3d762f419bb3572e18db57c03682651dc8c4",
        sha256 = "d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360",
    },

    exactSignals = {
        "BuyClothing",
        "ShopGui",
        "Clothing Display",
        "ShirtID",
        "PantsID",
        "PurchasePermanentItem",
        "ShirtTemplate",
        "PantsTemplate",
    },

    clothingRobuxFlow = {
        requestGui = "BuyClothing",
        activeGui = "ACTIVE_BuyClothing",
        shirtTemplateField = "ShirtTemplate",
        pantsTemplateField = "PantsTemplate",
        shirtIdField = "ShirtID",
        pantsIdField = "PantsID",
        marketplaceService = "MarketplaceService",
        promptMethod = "PromptPurchase",
        currency = "Robux",
        currencyEnum = "Enum.CurrencyType.Robux",
        thumbnailWidth = 110,
        thumbnailHeight = 110,
        successNotification = "Item purchased successfully! You can wear it via the Character tab on the ROBLOX website.",
    },

    permanentItemFlow = {
        remote = "PurchasePermanentItem",
        separateFromClothingRobuxFlow = true,
        debitsRhsCash = true,
        priceField = "ItemCost",
    },

    locations = {
        "School Spirit",
        "The Mall",
    },

    storeLabels = {
        "Nilvou",
        "MrMudMan",
        "Bad Ghoul RiRi",
        "Pastelly",
        "Jovani",
        "Sheric",
        "MissMudMan",
        "SouledOut & SouledIn",
    },

    explicitUnknowns = {
        concreteClothingAssetIds = true,
        fullClothingCatalog = true,
        fixedClothingPrices = true,
        storeInteriorsAndLayout = true,
    },
}
