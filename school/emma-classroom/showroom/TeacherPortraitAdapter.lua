--!strict
-- Optional, fail-closed, static portrait Model replacement for the stationary
-- Mrs. Benulis showroom display. Never blocks player spawn and never loads UI.
-- The portrait photograph itself is deliberately NOT stored in this repo.
local InsertService = game:GetService("InsertService")
local Config = require(script.Parent:WaitForChild("TeacherPortraitConfig"))

local TeacherPortraitAdapter = {}

local function vetted(model: Model): (boolean, string)
    local meshCount = 0
    for _,node in ipairs(model:GetDescendants()) do
        if node:IsA("MeshPart") then
            meshCount += 1
            if meshCount > Config.MaximumMeshParts then
                return false, "too_many_mesh_parts"
            end
        elseif node:IsA("Model") or node:IsA("Folder")
            or node:IsA("SurfaceAppearance") or node:IsA("Attachment") then
            -- Texture and hierarchy only. Absolutely no executable content,
            -- restraints, click detectors, sounds, or other descendants.
        else
            return false, "unexpected_asset_class_" .. node.ClassName
        end
    end
    if meshCount == 0 then
        return false, "no_mesh_parts"
    end
    local size = model:GetExtentsSize()
    if size.Y < 4.3 or size.Y > 7.5 or size.X > 4 or size.Z > 4
        or size.X < 0.6 or size.Z < 0.4 then
        return false, "invalid_teacher_dimensions"
    end
    return true, "approved_geometry"
end

local function fallbackFloor(model: Model): number
    local bottom = math.huge
    for _,node in ipairs(model:GetDescendants()) do
        if node:IsA("BasePart") and string.find(node.Name, "Foot") then
            bottom = math.min(bottom, node.Position.Y - node.Size.Y/2)
        end
    end
    if bottom == math.huge then
        local cf,sz = model:GetBoundingBox()
        bottom = cf.Position.Y-sz.Y/2
    end
    return bottom
end

function TeacherPortraitAdapter.apply(root: Instance, fallback: Model): string
    if Config.Enabled ~= true then
        return "disabled"
    end
    local id = tonumber(Config.ModelAssetId)
    if not id or id <= 0 or id % 1 ~= 0 then
        warn("Teacher portrait retained: no verified creator-owned Model asset ID.")
        return "no_verified_asset"
    end

    -- Keep the original visible until the new asset is fully loaded, vetted,
    -- positioned and parented. Import errors must never remove the teacher.
    task.defer(function()
        local loaded, asset = pcall(function()
            return InsertService:LoadAsset(id)
        end)
        if not loaded or not asset or not asset:IsA("Model") then
            warn("Teacher portrait retained: Roblox Model asset could not load.")
            return
        end
        local ok, reason = vetted(asset)
        if not ok then
            asset:Destroy()
            warn("Teacher portrait retained: " .. reason)
            return
        end

        local originalPose = fallback:GetPivot()
        local floor = fallbackFloor(fallback)
        for _,node in ipairs(asset:GetDescendants()) do
            if node:IsA("MeshPart") then
                node.Anchored = true
                node.CanCollide = false
                node.CanTouch = false
                node.CanQuery = false
                node.Massless = true
            end
        end
        asset.Name = "Mrs. Benulis - Portrait Mesh"
        asset:SetAttribute("ShowroomStationaryTeacher", true)
        asset:SetAttribute("TeacherPortraitAssetId", id)
        asset:PivotTo(CFrame.new(originalPose.Position) * originalPose.Rotation)
        local box,size = asset:GetBoundingBox()
        local shift = floor - (box.Position.Y - size.Y/2)
        asset:PivotTo(CFrame.new(0,shift,0) * asset:GetPivot())
        asset.Parent = root
        fallback:Destroy()
    end)
    return "pending_review_asset"
end

return TeacherPortraitAdapter
