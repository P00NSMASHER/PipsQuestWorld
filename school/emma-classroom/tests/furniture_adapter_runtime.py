"""Execute the REAL furniture adapter in Luau with an isolated fake Roblox engine.

This tests atomic fallback/activation and primitive visibility. It does not
simulate Roblox asset moderation, MeshPart rendering or device frame rates.
"""
from pathlib import Path
import argparse
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[3]
SCHOOL=ROOT/"school"
SOURCES=SCHOOL/"emma-classroom"/"showroom"

def build_harness():
    fixture=(SCHOOL/"emma-classroom"/"tests"/"geometry_behavior.py").read_text()
    source=fixture.split("harness=r'''",1)[1].split("'''",1)[0]
    source=source.split("local assets=Instance.new",1)[0]
    adapter=(SOURCES/"FurnitureMeshAdapter.lua").read_text()
    return source + r'''
-- Roblox warns but does not abort on denied asset access.
local warn=function(...) end
-- Enhance the existing tested math/Instance stubs with just the Model
-- bbox, scale and pivot operations needed for inserted MeshParts.
function methods:GetBoundingBox()
    local low=Vector3.new(math.huge,math.huge,math.huge)
    local high=Vector3.new(-math.huge,-math.huge,-math.huge)
    local count=0
    for _,p in ipairs(self:GetDescendants()) do
        if p:IsA("BasePart") then
            count+=1
            local c=p.CFrame.Position
            local h=p.Size*.5
            low=Vector3.new(math.min(low.X,c.X-h.X),math.min(low.Y,c.Y-h.Y),math.min(low.Z,c.Z-h.Z))
            high=Vector3.new(math.max(high.X,c.X+h.X),math.max(high.Y,c.Y+h.Y),math.max(high.Z,c.Z+h.Z))
        end
    end
    assert(count>0,"Empty MeshPart model should not be activated")
    return CFrame.new((low+high)*.5),high-low
end
function methods:GetExtentsSize()
    local _,size=self:GetBoundingBox()
    return size
end
function methods:GetPivot()
    return self.props.PivotCF or CFrame.new()
end
function methods:ScaleTo(target)
    local scale=target/self.scale
    for _,p in ipairs(self:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Size=p.Size*scale
            p.CFrame=CFrame.new(p.CFrame.Position*scale)
        end
    end
    self.scale=target
end
function methods:PivotTo(target)
    local delta=target*self:GetPivot():Inverse()
    for _,p in ipairs(self:GetDescendants()) do
        if p:IsA("BasePart") then p.CFrame=delta*p.CFrame end
    end
    self.PivotCF=target
end

local Config={
    Enabled=false,
    ChairModelAssetId=101,
    DeskModelAssetId=202,
    MaxMeshPartsPerModel=8,
}
local failLoad=false
local badDescendant=false
local wrongAxis=false
local loadCalls=0
local function mockModel(width,height,depth)
    local model=Instance.new("Model")
    for i=1,2 do
        local mesh=Instance.new("MeshPart")
        mesh.Name="OriginalImportedGeometry"..i
        mesh.Size=Vector3.new(width,height*.5,depth)
        mesh.CFrame=CFrame.new(0,height*(i==1 and .25 or .75),0)
        mesh.Parent=model
    end
    if badDescendant then
        local scriptPart=Instance.new("Script")
        scriptPart.Parent=model
    end
    return model
end
local InsertService={
    LoadAsset=function(_,id)
        loadCalls+=1
        if failLoad then error("Simulated Roblox permissions denial") end
        if id==101 then
            return mockModel(2.46,wrongAxis and 2.365 or 3.774,wrongAxis and 3.774 or 2.365)
        end
        if id==202 then return mockModel(5.78,3.085,3.86) end
        error("Unknown test asset ID")
    end
}
local getService=game.GetService
game.GetService=function(self,name)
    if name=="InsertService" then return InsertService end
    return getService(self,name)
end
local module=Config
local script={Parent={WaitForChild=function(_,name)
    assert(name=="FurnitureMeshConfig")
    return module
end}}
local require=function(value)
    assert(value==Config)
    return Config
end
local function loadAdapter()
''' + adapter + r'''
end
local Adapter=loadAdapter()

local function newRoot()
    local root=Instance.new("Folder")
    root.Name="ABVMClassroomReplica"
    for i=1,16 do
        for _,name in ipairs({
            "Student chair seat",
            "Student chair contoured back collision",
            "Student desk edge",
            "Student desk edge center",
            "Student desk edge rounded corner",
            "Student desk top",
            "Student desk top rounded corner",
            "Desk tubular leg",
            "Student classroom artwork",
        }) do
            local p=Instance.new("Part")
            p.Name=name
            p.Transparency=name=="Student chair contoured back collision" and 1 or .12
            p.CanCollide=(name=="Student chair seat" or name=="Student desk edge")
            p.Parent=root
        end
    end
    return root
end
local function originalState(root,hidden)
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") and p.Name=="Student desk edge rounded corner" then
            assert((p.Transparency==1)==hidden, "Desk rounded pieces remained visible")
        elseif p:IsA("BasePart") and p.Name=="Student chair seat" then
            assert((p.Transparency==1)==hidden, "Chair original surface mismatched")
            assert(p.CanCollide, "Chair seat collision was disabled")
        elseif p:IsA("BasePart") and p.Name=="Student desk edge" then
            assert((p.Transparency==1)==hidden, "Desk original top edge mismatched")
            assert(p.CanCollide, "Desk collision was disabled")
        elseif p:IsA("BasePart") and p.Name=="Student classroom artwork" then
            assert(p.Transparency==.12,"Unrelated art must remain untouched")
        end
    end
end
local function isStaged(root)
    return root:FindFirstChild("OwnerVerifiedOriginalMeshFurniture")~=nil
end

local root=newRoot()
assert(Adapter.apply(root)==false,"Disabled loader must not try asset requests")
assert(loadCalls==0,"Disabled loader unexpectedly fetched Roblox assets")
originalState(root,false)
assert(not isStaged(root))
print("PASS_DISABLED_FALLBACK")

Config.Enabled=true
Config.DeskModelAssetId=Config.ChairModelAssetId
assert(not Adapter.apply(root))
assert(loadCalls==0,"Duplicate asset ID must fail before loading")
originalState(root,false)
Config.DeskModelAssetId=202
print("PASS_DUPLICATE_IDS_REJECTED")

failLoad=true
assert(not Adapter.apply(root))
originalState(root,false)
assert(not isStaged(root))
failLoad=false
print("PASS_PERMISSION_DENIED_FALLBACK")

badDescendant=true
assert(not Adapter.apply(root),"Script-containing model must be rejected")
originalState(root,false)
assert(not isStaged(root))
badDescendant=false
print("PASS_UNTRUSTED_MODEL_REJECTED")

wrongAxis=true
assert(not Adapter.apply(root),"Wrong model axes must abort staging")
originalState(root,false)
assert(not isStaged(root))
wrongAxis=false
print("PASS_DIMENSIONS_REJECTED")

-- Inject one rendering visibility exception to prove partial swaps are atomic.
local oldAssign=instanceMeta.__newindex
local throwOnce=true
instanceMeta.__newindex=function(t,k,v)
    if k=="Transparency" and t.Name=="Student desk top" and v==1 and throwOnce then
        throwOnce=false
        error("Injected one-time visibility transaction failure")
    end
    return oldAssign(t,k,v)
end
assert(not Adapter.apply(root),"Swap failure must be caught")
assert(not isStaged(root),"Partial imported meshes left behind after swap failure")
originalState(root,false)
assert(root:GetAttribute("FurnitureModelStatus")=="SwapFailed_PreservingOriginalFurniture")
instanceMeta.__newindex=oldAssign
print("PASS_PARTIAL_SWAP_ROLLBACK")

assert(Adapter.apply(root)==true,"Two approved models should activate in mock")
assert(isStaged(root))
originalState(root,true)
local container=root:FindFirstChild("OwnerVerifiedOriginalMeshFurniture")
assert(#container:GetChildren()==32,"Expected 16 chairs and 16 desks")
assert(root:GetAttribute("FurnitureModelStatus")=="ImportedOwnerModels_EngineVisualQARequired")
local meshParts=0
for _,item in ipairs(container:GetDescendants()) do
    if item:IsA("MeshPart") then
        meshParts+=1
        assert(item.Anchored and item.CanCollide==false and item.CanTouch==false)
    end
end
assert(meshParts==64,"Expected two MeshParts per staged model for test fixtures")
print("PASS_ATOMIC_ACTIVATION_AND_COLLIDER_PRESERVATION 16_DESKS 16_CHAIRS")
'''

def run(executable: str):
    with tempfile.TemporaryDirectory(prefix="abvm-mesh-runtime-") as directory:
        path=Path(directory)/"test.lua"
        path.write_text(build_harness())
        process=subprocess.run([executable,str(path)],capture_output=True,text=True,timeout=70)
    if process.returncode:
        raise RuntimeError("Furniture adapter behavioral test failed:\n"+process.stdout[-3500:]+"\n"+process.stderr[-3500:])
    expected=[
        "PASS_DISABLED_FALLBACK","PASS_DUPLICATE_IDS_REJECTED",
        "PASS_PERMISSION_DENIED_FALLBACK","PASS_UNTRUSTED_MODEL_REJECTED",
        "PASS_DIMENSIONS_REJECTED","PASS_PARTIAL_SWAP_ROLLBACK",
        "PASS_ATOMIC_ACTIVATION_AND_COLLIDER_PRESERVATION 16_DESKS 16_CHAIRS"
    ]
    for marker in expected:
        assert marker in process.stdout, "Missing actual behavior: "+marker
    print(process.stdout)

if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--luau",required=True)
    options=ap.parse_args()
    run(options.luau)
