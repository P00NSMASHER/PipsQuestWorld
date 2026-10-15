--!strict
-- Fail-closed optional static teacher mesh replacement for ABVM Grade 2.
-- No public teacher photo/GLB is committed. Roblox R15 teacher always remains
-- visible if the private candidate fails import, policy, quality or preload.
local InsertService = game:GetService("InsertService")
local ContentProvider = game:GetService("ContentProvider")
local Config = require(script.Parent:WaitForChild("TeacherPortraitConfig"))
local TeacherPortraitAdapter = {}

local ALLOWED = {
    Model = true,
    Folder = true,
    MeshPart = true,
    SurfaceAppearance = true,
    Attachment = true,
}
local function inspect(asset: Model): (boolean, string)
    local count = 0
    for _, item in ipairs(asset:GetDescendants()) do
        if not ALLOWED[item.ClassName] then
            return false, "unsupported_" .. item.ClassName
        end
        if item:IsA("MeshPart") then
            count += 1
            if count > Config.MaximumMeshParts then
                return false, "too_many_meshparts"
            end
            local dim = item.Size
            if not (dim.X > 0 and dim.Y > 0 and dim.Z > 0)
                or dim.X > 6 or dim.Y > 8 or dim.Z > 6 then
                return false, "meshpart_dimensions"
            end
        end
    end
    if count < 8 then
        return false, "not_a_detailed_anatomical_character"
    end
    local size = asset:GetExtentsSize()
    if size.Y < 5.1 or size.Y > 6.8
        or size.X < 1.1 or size.X > 2.45
        or size.Z < .55 or size.Z > 2.0 then
        return false, "invalid_teacher_dimensions"
    end
    return true, "approved_geometry"
end

local function feetLevel(model: Model): number
    local lowest = math.huge
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") and string.find(item.Name, "Foot") then
            lowest = math.min(lowest, item.Position.Y - item.Size.Y / 2)
        end
    end
    if lowest == math.huge then
        local box, size = model:GetBoundingBox()
        lowest = box.Position.Y - size.Y / 2
    end
    return lowest
end

function TeacherPortraitAdapter.apply(root: Instance, fallback: Model): string
    if Config.Enabled ~= true then
        return "disabled"
    end
    -- Enabling by accident cannot publicly substitute an unverified portrait.
    if not (Config.CreatorOwnershipVerified == true
        and Config.NativeStudioVisualReviewed == true
        and Config.IPhoneVisualReviewed == true
        and Config.PublicLikenessPermissionConfirmed == true) then
        warn("Teacher portrait is held for ownership, likeness and native visual review.")
        return "awaiting_approvals"
    end
    local id = tonumber(Config.ModelAssetId)
    if not id or id <= 0 or id % 1 ~= 0 then
        return "no_verified_asset"
    end
    task.defer(function()
        local asset: Model? = nil
        local success, reason = pcall(function()
            local container = InsertService:LoadAsset(id)
            if not container or not container:IsA("Model") then
                error("invalid_roblox_model")
            end
            asset = container
            local valid, errorReason = inspect(container)
            if not valid then
                error("rejected_" .. errorReason)
            end
            -- Preserve original display while geometry and textures load.
            local missingTexture = false
            ContentProvider:PreloadAsync({container}, function(_, status)
                if status ~= Enum.AssetFetchStatus.Success then
                    missingTexture = true
                end
            end)
            if missingTexture then
                error("missing_model_texture")
            end
            if fallback.Parent ~= root then
                error("stale_teacher_display")
            end
            local original = fallback:GetPivot()
            local targetFoot = feetLevel(fallback)
            for _, item in ipairs(container:GetDescendants()) do
                if item:IsA("MeshPart") then
                    item.Anchored = true
                    item.CanCollide = false
                    item.CanTouch = false
                    item.CanQuery = false
                    item.Massless = true
                end
            end
            -- Align centre in X/Z and feet in Y independently of the
            -- arbitrary imported model pivot or child MeshPart origins.
            container:PivotTo(original)
            local bbox, dimensions = container:GetBoundingBox()
            local delta = Vector3.new(
                original.Position.X - bbox.Position.X,
                targetFoot + dimensions.Y / 2 - bbox.Position.Y,
                original.Position.Z - bbox.Position.Z
            )
            container:PivotTo(container:GetPivot() + delta)
            container.Name = "Mrs. Benulis - Portrait Mesh"
            container:SetAttribute("ShowroomStationaryTeacher", true)
            container:SetAttribute("TeacherPortraitAssetId", id)
            container.Parent = root
            fallback:Destroy()
        end)
        if not success then
            if asset then
                asset:Destroy()
            end
            warn("Teacher portrait retained as Roblox R15 fallback: " .. tostring(reason))
        end
    end)
    return "pending_reviewed_asset"
end

return TeacherPortraitAdapter
