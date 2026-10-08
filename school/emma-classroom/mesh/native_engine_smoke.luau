--!strict
-- This task runs inside a temporary Roblox Open Cloud Luau Execution session.
-- It does NOT parent anything into Workspace or save any place version.
-- IDs are resolved from the independently verified imported_models.json.
local InsertService = game:GetService("InsertService")

local candidates = {
    {
        name = "student_chair",
        id = __CHAIR_ASSET_ID__,
        expected = Vector3.new(2.460,3.774,2.365),
        width = 2.460,
    },
    {
        name = "student_desk",
        id = __DESK_ASSET_ID__,
        expected = Vector3.new(5.780,3.085,3.860),
        width = 5.780,
    },
}
local allowed = {
    Model = true,
    Folder = true,
    MeshPart = true,
    SurfaceAppearance = true,
}
local function close(a:number,b:number,tolerance:number)
    return math.abs(a-b)<=tolerance
end
local function boundsAccept(size:Vector3,expected:Vector3)
    return close(size.X,expected.X,.22)
       and close(size.Y,expected.Y,.30)
       and close(size.Z,expected.Z,.30)
end
local loaded = {}
for _,item in ipairs(candidates) do
    local okay,model = pcall(function()
        return InsertService:LoadAsset(item.id)
    end)
    assert(okay and typeof(model)=="Instance" and model:IsA("Model"),
        "Import failed for approved "..item.name.." model. Permissions/asset loading must be reviewed.")
    local count=0
    for _,descendant in ipairs(model:GetDescendants()) do
        assert(allowed[descendant.ClassName],
            "Importer inserted unexpected class "..descendant.ClassName.." in "..item.name)
        if descendant:IsA("MeshPart") then
            count+=1
            assert(descendant.Size.X>0 and descendant.Size.Y>0 and descendant.Size.Z>0,
                "Nonpositive MeshPart size")
        end
    end
    assert(count>=2 and count<=8,
        "Imported "..item.name.." has "..tostring(count).." MeshParts; runtime loader would reject")
    local original=model:GetExtentsSize()
    assert(original.X>.01, "Invalid imported model width")
    local visualScale=item.width/original.X
    local corrected=original*visualScale
    assert(boundsAccept(corrected,item.expected),
        "Imported "..item.name.." model axis/scale not compatible with classroom")
    print(string.format("NATIVE_ASSET_MODEL_VERIFIED %s %d parts=%d scaled=%.3f,%.3f,%.3f",
        item.name,item.id,count,corrected.X,corrected.Y,corrected.Z))
    loaded[item.name]=model
end

-- In-memory placement acceptance. The folder is never attached to Workspace.
local staged=Instance.new("Folder")
staged.Name="ABVM_HeadlessEngineTemporaryFurniture"
local rowCount=0
for row,z in ipairs({-12,4,19}) do
    for col,x in ipairs({-24,-16,-8,0,12,20}) do
        if row<3 or col>2 then
            for _,item in ipairs(candidates) do
                local m=loaded[item.name]:Clone()
                m:ScaleTo(item.width/m:GetExtentsSize().X)
                local cf,size=m:GetBoundingBox()
                assert(boundsAccept(size,item.expected),"Staged furniture bounds mismatch")
                local rz=z+(item.name=="student_chair" and 3.48 or 0)
                local translation=Vector3.new(x-cf.Position.X,size.Y/2-cf.Position.Y,rz-cf.Position.Z)
                m:PivotTo(CFrame.new(translation)*m:GetPivot())
                local after,sizeAfter=m:GetBoundingBox()
                assert(close(after.Position.X,x,.1)
                   and close(after.Position.Z,rz,.1)
                   and close(after.Position.Y,sizeAfter.Y/2,.1),
                   "Wrong model center, floor contact or facing after positioning")
                m.Parent=staged
            end
            rowCount+=1
        end
    end
end
assert(rowCount==16,"Existing classroom desk topology changed unexpectedly")
assert(#staged:GetChildren()==32,"Staging must contain exactly 16 model pairs")
assert(staged.Parent==nil,"Temporary engine models must not enter the live Workspace")
local clearRowX=8-5.780
local deskChairGap=3.48-(3.860/2+2.365/2)
assert(clearRowX>2 and deskChairGap>.25,"Unsafe desk and chair spacing")
print(string.format("NATIVE_ASSET_STAGING_VERIFIED pairs=%d models=%d desk_horizontal_gap=%.3f desk_chair_gap=%.3f",
    rowCount,#staged:GetChildren(),clearRowX,deskChairGap))
for _,m in pairs(loaded) do m:Destroy() end
staged:Destroy()
print("NATIVE_ASSET_ENGINE_NO_SAVE_NO_WORKSPACE_MUTATION")

-- Run the exact real showroom FurnitureMeshAdapter.lua in this disposable
-- engine task, with activation enabled ONLY in this in-memory test module.
-- The GitHub checkout and actual Roblox experience config remain disabled.
local function loadRealFurnitureAdapter()
__ACTUAL_ADAPTER_SOURCE__
end
local RealAdapter = loadRealFurnitureAdapter()
local testRoot = Instance.new("Folder")
testRoot.Name = "ABVM_EngineOnly_MeshAdapterTest"
local oldParts = {}
local untouched = {}
for row,z in ipairs({-12,4,19}) do
    for col,x in ipairs({-24,-16,-8,0,12,20}) do
        if row<3 or col>2 then
            for _,kind in ipairs({"Student chair seat","Student chair school back shell",
                                   "Student desk top","Student desk edge rounded corner"}) do
                local part = Instance.new("Part")
                part.Name = kind
                part.Size = Vector3.new(2,.15,2)
                part.Transparency = 0
                part.CanCollide = (kind=="Student chair seat" or kind=="Student desk top")
                part.Parent = testRoot
                table.insert(oldParts,part)
            end
            local art=Instance.new("Part")
            art.Name="Student classroom artwork"
            art.Transparency=.2
            art.CanCollide=false
            art.Parent=testRoot
            table.insert(untouched,art)
        end
    end
end
assert(testRoot.Parent==nil, "Engine test root must never be parented to Workspace")
assert(RealAdapter.apply(testRoot), "The real showroom adapter did not accept the real Roblox models")
assert(testRoot:GetAttribute("FurnitureModelStatus")=="ImportedOwnerModels_EngineVisualQARequired")
local meshFolder=testRoot:FindFirstChild("OwnerVerifiedOriginalMeshFurniture")
assert(meshFolder and #meshFolder:GetChildren()==32,"Actual adapter must stage all 16 pairs")
for _,part in ipairs(oldParts) do
    assert(part.Transparency==1,"Legacy furniture surface would visibly overlap approved meshes")
    if part.Name=="Student chair seat" or part.Name=="Student desk top" then
        assert(part.CanCollide==true,"Original classroom collision changed during visual swap")
    end
end
for _,part in ipairs(untouched) do
    assert(part.Transparency==.2,"Non-furniture artwork changed during visual swap")
end
assert(testRoot.Parent==nil,"Actual adapter illegally parented test models to Workspace")
print("NATIVE_ACTUAL_ADAPTER_ACCEPTED models=32 original_colliders_preserved=true")
testRoot:Destroy()
print("NATIVE_ASSET_ENGINE_NO_SAVE_NO_WORKSPACE_MUTATION_CONFIRMED")
return "ABVM_NATIVE_FURNITURE_ENGINE_ACCEPTED"
