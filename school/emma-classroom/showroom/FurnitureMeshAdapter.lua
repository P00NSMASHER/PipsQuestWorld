--!strict
-- Asset-import boundary for original ABVM furniture GLBs.
-- Never load third-party scripts. Keep the existing part-built furniture as
-- a complete, playable fallback until BOTH owned models load successfully.
local InsertService = game:GetService("InsertService")
local Config = require(script.Parent:WaitForChild("FurnitureMeshConfig"))
local Adapter = {}

local function safelyLoadVisual(assetId: number, maxParts: number): Model?
    if assetId <= 0 then return nil end
    local ok, raw = pcall(function()
        return InsertService:LoadAsset(assetId)
    end)
    if not ok or not raw or not raw:IsA("Model") then
        if raw and raw:IsA("Instance") then raw:Destroy() end
        warn("ABVM premium furniture asset could not be loaded from Roblox owner library")
        return nil
    end
    local parts = {}
    local safe = true
    for _, descendant in ipairs(raw:GetDescendants()) do
        -- GLB models should only contain model/folder containers, MeshParts,
        -- and optional SurfaceAppearance material children. Reject scripts,
        -- remotes, prompts, constraints, sounds, extra Parts and unknown nodes
        -- rather than quietly copying unexpected executable/interactive data.
        if descendant:IsA("MeshPart") then
            table.insert(parts, descendant)
        elseif not (
            descendant:IsA("Model")
            or descendant:IsA("Folder")
            or descendant:IsA("SurfaceAppearance")
        ) then
            safe = false
            break
        end
    end
    if not safe or #parts < 2 or #parts > maxParts then
        raw:Destroy()
        warn("ABVM premium furniture model rejected: unexpected contents")
        return nil
    end
    local clean = Instance.new("Model")
    clean.Name = "ValidatedOriginalFurniture"
    for _,part in ipairs(parts) do
        local clone = part:Clone()
        for _,nested in ipairs(clone:GetDescendants()) do
            if not nested:IsA("SurfaceAppearance") then
                nested:Destroy()
            end
        end
        clone.Anchored = true
        clone.CanCollide = false
        clone.CanTouch = false
        clone.CanQuery = false
        clone.Parent = clean
    end
    raw:Destroy()
    local size = clean:GetExtentsSize()
    if size.X < .2 or size.X > 50
        or size.Y < .2 or size.Y > 50
        or size.Z < .2 or size.Z > 50 then
        clean:Destroy()
        return nil
    end
    return clean
end

local function placeVisual(
    template: Model,
    x: number,
    z: number,
    expected: Vector3,
    root: Instance
): Model
    local m = template:Clone()
    local current = m:GetExtentsSize()
    assert(current.X > .01, "Furniture GLB width must be positive")
    m:ScaleTo(expected.X / current.X)
    local cf, size = m:GetBoundingBox()
    -- A width match alone is insufficient: an upside-down or wrong-axis
    -- import could appear through walls or floors after scaling. Do not
    -- touch the current working furniture if aspect proportions disagree.
    assert(math.abs(size.X - expected.X) < .22, "Furniture width mismatch")
    assert(math.abs(size.Y - expected.Y) < .30, "Furniture height / axis mismatch")
    assert(math.abs(size.Z - expected.Z) < .30, "Furniture depth / axis mismatch")
    local delta = Vector3.new(
        x - cf.Position.X,
        size.Y / 2 - cf.Position.Y,
        z - cf.Position.Z
    )
    m:PivotTo(CFrame.new(delta) * m:GetPivot())
    m.Parent = root
    return m
end

local HIDE_DESK = {
    ["Student desk edge"] = true,
    ["Student desk top"] = true,
    ["Desk tubular leg"] = true,
    ["Desk foot"] = true,
    ["Desk book tray"] = true,
    ["Book tray side"] = true,
    ["Desk laminated front bevel"] = true,
    ["Desk shelf front restraint"] = true,
    ["Desk back steel stretcher"] = true,
    ["Desk assembly bolt"] = true,
    ["Desk rubber glide"] = true,
    ["Inlaid laminate grain"] = true,
    ["Desk apron bracket"] = true,
    ["Desk fixing bolt"] = true,
}
local function shouldHide(name: string, hasChair: boolean, hasDesk: boolean): boolean
    if hasChair and string.sub(name,1,13)=="Student chair" then
        -- Keep physics primitives hidden, but retain collision and walkability.
        return true
    end
    if hasDesk then
        -- RoundedPanel creates separate center and corner parts. Hiding only
        -- the named core left primitive desk rims floating around the new
        -- mesh. Match the complete surface family but preserve its colliders.
        if string.sub(name,1,#"Student desk edge") == "Student desk edge"
            or string.sub(name,1,#"Student desk top") == "Student desk top" then
            return true
        end
        return HIDE_DESK[name] == true
    end
    return false
end

function Adapter.apply(root: Instance): boolean
    if not Config.Enabled then
        root:SetAttribute("FurnitureModelStatus", "AwaitingVerifiedRobloxModelAssetIds")
        return false
    end
    if Config.ChairModelAssetId <= 0 or Config.DeskModelAssetId <= 0
        or Config.ChairModelAssetId == Config.DeskModelAssetId then
        warn("ABVM model activation requires TWO approved Roblox model IDs")
        root:SetAttribute("FurnitureModelStatus", "MissingApprovedModelAssetIds")
        return false
    end

    local chair = safelyLoadVisual(Config.ChairModelAssetId, Config.MaxMeshPartsPerModel)
    local desk = safelyLoadVisual(Config.DeskModelAssetId, Config.MaxMeshPartsPerModel)
    if not chair or not desk then
        if chair then chair:Destroy() end
        if desk then desk:Destroy() end
        root:SetAttribute("FurnitureModelStatus", "AssetLoadFailed_PreservingOriginalFurniture")
        return false
    end

    local container = Instance.new("Folder")
    container.Name = "OwnerVerifiedOriginalMeshFurniture"
    local instances = 0
    local ok, err = pcall(function()
        for row,z in ipairs({-12,4,19}) do
            for col,x in ipairs({-24,-16,-8,0,12,20}) do
                if row<3 or col>2 then
                    placeVisual(chair, x, z+3.48, Vector3.new(2.46,3.774,2.365), container)
                    placeVisual(desk, x, z, Vector3.new(5.78,3.085,3.86), container)
                    instances += 1
                end
            end
        end
    end)
    chair:Destroy()
    desk:Destroy()
    if not ok or instances ~= 16 then
        container:Destroy()
        root:SetAttribute("FurnitureModelStatus", "ValidationFailed_PreservingOriginalFurniture")
        warn("ABVM premium meshes failed complete 16-seat staging: "..tostring(err))
        return false
    end
    -- This only runs after all 32 model clones are verified and constructed.
    -- Preserve colliders even when original parts are visually hidden.
    local originals = {}
    local previous = {}
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") and shouldHide(p.Name, true, true) then
            table.insert(originals, p)
            table.insert(previous, p.Transparency)
        end
    end
    -- Only promote the staged, complete set of 32 visuals. If any step in
    -- the swap errors, remove the mesh set and restore original visibility;
    -- leave the original physics and camera behavior untouched throughout.
    local swapped, reason = pcall(function()
        container.Parent = root
        for _,p in ipairs(originals) do p.Transparency = 1 end
    end)
    if not swapped then
        container:Destroy()
        for i,p in ipairs(originals) do
            pcall(function() p.Transparency = previous[i] end)
        end
        root:SetAttribute("FurnitureModelStatus", "SwapFailed_PreservingOriginalFurniture")
        warn("ABVM furniture visual swap rolled back: "..tostring(reason))
        return false
    end
    root:SetAttribute("FurnitureModelStatus", "ImportedOwnerModels_EngineVisualQARequired")
    return true
end

return Adapter
