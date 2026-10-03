-- Static Content-QA reference contract for Housing Editor V2.
-- Test/provenance data only: no gameplay authority and no Legacy runtime import.

return {
    schemaVersion = 2,
    target = "Canonical High School / Housing Editor V2",
    legacyExperience = "ROBLOX High School [Legacy]",

    source = {
        rightsStatus = "USER_ASSERTED_LICENSE_COVERS_EXACT_CODE_BUILD",
        sourceRepository = "MisoNotSoupx/Old-Roblox-Place-Archive",
        sourceCommit = "b817aef0eaf77d3382acacdc8f22537e54c76822",
        sourcePath = "Created by Users/Cindering/ROBLOX High School.rbxl",
        sourceGitBlobSha = "95ee3d762f419bb3572e18db57c03682651dc8c4",
        legacyBaselineSha256 = "d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360",
        evidence = {
            {
                id = "licensed-baseline-metadata",
                kind = "repository_provenance",
                locator = "MisoNotSoupx/Old-Roblox-Place-Archive@b817aef0eaf77d3382acacdc8f22537e54c76822:Created by Users/Cindering/ROBLOX High School.rbxl",
                use = "licensed_reference",
                supports = "licensed Legacy reference identity",
            },
            {
                id = "legacy-house-editor-screenshot-2025-08-24",
                kind = "presentation_reference",
                locator = "https://www.lemon8-app.com/@pippirrupofficial1/7542245790052319758?region=us",
                use = "corroboration_only",
                supports = "exact visible labels Add Furni and Hide Walls",
            },
            {
                id = "legacy-furniture-wiki",
                kind = "category_reference",
                locator = "https://roblox-high-school.fandom.com/wiki/Furniture",
                use = "corroboration_only",
                supports = "verified exact category labels Utilities and Other",
            },
            {
                id = "legacy-housing-wiki",
                kind = "interaction_reference",
                locator = "https://roblox-high-school.fandom.com/wiki/Housing",
                use = "corroboration_only",
                supports = "house icon, Teleport to House, Edit House, fifty-cash ownership, edit visitor restriction",
            },
            {
                id = "legacy-landlord-lenny-dialogue",
                kind = "interaction_reference",
                locator = "https://roblox-high-school.fandom.com/wiki/Landlord_Lenny",
                use = "corroboration_only",
                supports = "Edit House, add furniture, move with building tools, paint walls, save",
            },
            {
                id = "legacy-house-static-contract",
                kind = "licensed_baseline_extraction",
                locator = "MisoNotSoupx/Old-Roblox-Place-Archive@b817aef0eaf77d3382acacdc8f22537e54c76822:Created by Users/Cindering/ROBLOX High School.rbxl",
                use = "licensed_reference",
                supports = "place/move/rotate/remove/sell/paint/save/reload/edit-mode semantics",
            },
        },
    },

    visibleLabels = {
        addFurniture = "Add Furni",
        hideWalls = "Hide Walls",
    },

    furnitureCategories = {
        -- Only independently verified exact labels belong here.
        verifiedExactLabels = {
            "Utilities",
            "Other",
        },
        complete = false,
        completenessRule = "Unverified category labels must not be presented as Legacy-exact.",
    },

    paintBuildTools = {
        verifiedBehavior = {
            "moveFurniture",
            "paintHouseItem",
            "saveHouse",
        },
        exactVisibleLabels = {},
        exactLabelCoverageComplete = false,
        completenessRule = "Do not invent Legacy-exact paint/build button text until licensed evidence establishes it.",
    },

    interactionSemantics = {
        "buyFurniture",
        "placeFurniture",
        "moveFurniture",
        "rotateFurniture",
        "removeFurniture",
        "sellFurniture",
        "paintHouseItem",
        "saveHouse",
        "reloadHouse",
        "hideWalls",
        "restrictVisitorsWhileEditing",
    },

    claimProvenance = {
        visibleLabels = {
            ["Add Furni"] = {
                "legacy-house-editor-screenshot-2025-08-24",
                "licensed-baseline-metadata",
            },
            ["Hide Walls"] = {
                "legacy-house-editor-screenshot-2025-08-24",
                "licensed-baseline-metadata",
            },
        },
        furnitureCategories = {
            Utilities = {
                "legacy-furniture-wiki",
            },
            Other = {
                "legacy-furniture-wiki",
            },
        },
        housingInteractions = {
            teleportToHouse = {
                "legacy-housing-wiki",
                "legacy-house-static-contract",
            },
            editHouse = {
                "legacy-housing-wiki",
                "legacy-landlord-lenny-dialogue",
                "legacy-house-static-contract",
            },
            restrictVisitorsWhileEditing = {
                "legacy-housing-wiki",
                "legacy-house-static-contract",
            },
        },
        paintBuildBehavior = {
            moveFurniture = {
                "legacy-landlord-lenny-dialogue",
                "legacy-house-static-contract",
            },
            paintHouseItem = {
                "legacy-landlord-lenny-dialogue",
                "legacy-house-static-contract",
            },
            saveHouse = {
                "legacy-landlord-lenny-dialogue",
                "legacy-house-static-contract",
            },
        },
    },

    assetProvenance = {
        referencedAssetIds = {},
        publicCorroborationIsNotAssetAuthorization = true,
        rule = "Any future model/image/audio asset must carry an authorized source object/path and licensed Legacy baseline provenance before use.",
    },

    boundaries = {
        runtimeAuthority = false,
        economyAuthority = false,
        persistenceAuthority = false,
        worldGeometryAuthority = false,
        customizationMechanicsAuthority = false,
        productCodeImportedFromLegacyRuntime = false,
        retiredRuntimeProductCodeAllowed = false,
        rhs2ReferenceBleedAllowed = false,
    },
}
