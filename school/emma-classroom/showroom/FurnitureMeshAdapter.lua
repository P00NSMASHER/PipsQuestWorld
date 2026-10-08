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
        warn("ABVM premium furniture asset could not be loaded from Roblox owner library")
        return nil
    end
    local parts = {}
    local safe = true
    for _, descendant in ipairs(raw:GetDescendants()) do
        if descendant:IsA("LuaSourceContainer")
            or descendant:IsA("RemoteEvent")
            or descendant:IsA("RemoteFunction")
            or descendant:IsA("ModuleScript") then
            safe = false
            break
        end
        if descendant:IsA("BasePart") then
            if not descendant:IsA("MeshPart") then
                safe = false
                break
            end
            table.insert(parts, descendant)
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
            if nested:IsA("LuaSourceContainer") then nested:Destroy() end
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

local function placeVisual(template: Model, x: number, z: number, desiredWidth: number, root: Instance)
    local m = template:Clone()
    local currentWidth = m:GetExtentsSize().X
    m:ScaleTo(desiredWidth / currentWidth)
    local cf, size = m:GetBoundingBox()
    local delta = Vector3.new(x - cf.Position.X, size.Y / 2 - cf.Position.Y, z - cf.Position.Z)
    m:PivotTo(CFrame.new(delta) * m:GetPivot())
    m.Parent = root
    return m
end

local HIDE_CHAIR = {
    ["Student chair seat"] = true,
    ["Student chair back"] = true,
}
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
    ["Student chair contoured back collision"] = false,
}
local function shouldHide(name: string, hasChair: boolean, hasDesk: boolean): boolean
    if hasChair and string.sub(name,1,13)=="Student chair" then
        -- Keep physics primitives hidden, but retain collision and walkability.
        return true
    end
    return hasDesk and HIDE_DESK[name] == true
end

function Adapter.apply(root: Instance): boolean
    if not Config.Enabled then
        root:SetAttribute("FurnitureModelStatus", "AwaitingVerifiedRobloxModelAssetIds")
        return false
    end
    if Config.ChairModelAssetId <= 0 or Config.DeskModelAssetId <= 0 then
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
                    placeVisual(chair, x, z+3.48, 2.46, container)
                    placeVisual(desk, x, z, 5.78, container)
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
    container.Parent = root
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") and not p:IsDescendantOf(container) then
            if shouldHide(p.Name, true, true) then
                p.Transparency = 1
            end
        end
    end
    root:SetAttribute("FurnitureModelStatus", "ImportedOwnerModels_EngineVisualQARequired")
    return true
end

return Adapter
