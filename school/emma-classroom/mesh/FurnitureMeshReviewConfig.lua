--!strict
-- REVIEW ONLY. This config belongs exclusively to
-- school/emma-mesh-review.project.json. The production release compiles
-- school/emma-showroom.project.json, which maps to the disabled config.
-- Both owned GLB Model IDs passed Open Cloud approval, metadata inspection,
-- and disposable native engine adapter loading at PR #339.
return {
    Enabled = true,
    ChairModelAssetId = 132417338693200,
    DeskModelAssetId = 75559376486007,
    MaxMeshPartsPerModel = 8,
}
