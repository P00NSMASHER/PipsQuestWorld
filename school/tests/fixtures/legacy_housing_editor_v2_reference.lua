-- Static Content-QA reference contract for Housing Editor V2.
-- This file is test/provenance data only. It contains no gameplay authority and
-- imports no Legacy runtime code.

return {
    schemaVersion = 1,
    target = "Canonical High School / Housing Editor V2",
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
                supports = "licensed Legacy reference identity",
            },
            {
                id = "legacy-house-editor-screenshot-2025-08-24",
                kind = "presentation_reference",
                supports = "exact visible labels Add Furni and Hide Walls",
            },
            {
                id = "legacy-furniture-wiki",
                kind = "category_reference",
                supports = "verified exact category labels Utilities and Other",
            },
            {
                id = "legacy-house-static-contract",
                kind = "interaction_reference",
                supports = "place/move/rotate/remove/sell/paint/save/reload/edit-mode semantics",
            },
        },
    },

    visibleLabels = {
        addFurniture = "Add Furni",
        hideWalls = "Hide Walls",
    },

    furnitureCategories = {
        -- These are the only category labels independently verified by the
        -- current Content-QA evidence set. Do not infer the remaining labels.
        verifiedExactLabels = {
            "Utilities",
            "Other",
        },
        complete = false,
        completenessRule = "Unverified category labels must not be presented as Legacy-exact.",
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

    assetProvenance = {
        referencedAssetIds = {},
        rule = "Any future model/image/audio asset must carry an authorized source object/path and Legacy baseline provenance before use.",
    },

    boundaries = {
        runtimeAuthority = false,
        economyAuthority = false,
        persistenceAuthority = false,
        worldGeometryAuthority = false,
        customizationMechanicsAuthority = false,
        productCodeImportedFromLegacyRuntime = false,
    },
}
