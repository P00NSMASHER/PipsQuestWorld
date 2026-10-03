--!strict
-- Free-Roam prep contract for verified Legacy clothing-shopping seams only.
-- Provenance: Content-QA PR #150 head 762e1d17e001635a8f0a8cc9bed66a36080ed68d,
-- verified binary run 37117831711 / artifact 11271783526.
--
-- This module deliberately does not create a RemoteFunction, prompt a purchase,
-- invent catalog entries, infer asset IDs, or own currency/economy state.

local Contract = {}

Contract.PROVENANCE = {
    supportHead = "762e1d17e001635a8f0a8cc9bed66a36080ed68d",
    binaryGitBlobSha = "95ee3d762f419bb3572e18db57c03682651dc8c4",
    binarySha256 = "d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360",
    extractionRunId = 37117831711,
    extractionArtifactId = 11271783526,
}

Contract.PURCHASE_REMOTE = "PurchasePermanentItem"
Contract.SHIRT_TEMPLATE_FIELD = "ShirtTemplate"
Contract.PANTS_TEMPLATE_FIELD = "PantsTemplate"
Contract.SUCCESS_NOTIFICATION =
    "Item purchased successfully! You can wear it via the Character tab on the ROBLOX website."

Contract.INTERACTION = "click_item_to_purchase"
Contract.WEAR_PATH = "roblox_website_avatar"
Contract.CURRENCY = "Robux"

Contract.EXPLICIT_UNVERIFIED = {
    fullCatalog = true,
    assetIds = true,
    exactItemPrices = true,
    purchasePayloadShape = true,
    remoteContainerHierarchy = true,
    shopLayout = true,
}

local VERIFIED_TEMPLATE_FIELDS = {
    [Contract.SHIRT_TEMPLATE_FIELD] = true,
    [Contract.PANTS_TEMPLATE_FIELD] = true,
}

function Contract.isVerifiedTemplateField(fieldName: any): boolean
    return type(fieldName) == "string" and VERIFIED_TEMPLATE_FIELDS[fieldName] == true
end

function Contract.unverifiedCatalogResult()
    return {
        accepted = false,
        code = "UNVERIFIED_CATALOG",
        spendAttempted = false,
    }
end

return Contract
