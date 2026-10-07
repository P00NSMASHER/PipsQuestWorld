"""Run actual StaffModel/World constructors with math/service doubles; no render claim."""
from pathlib import Path
import argparse, subprocess
ap=argparse.ArgumentParser();ap.add_argument('--luau',required=True);args=ap.parse_args()
p=Path(__file__).resolve().parents[1]
harness=r'''
local V={}
V.__index=function(v,k)
    if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
    if k=="Unit" then return v/v.Magnitude end
    return V[k]
end
local Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},V) end}
V.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
V.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
V.__mul=function(a,b) if type(a)=="number" then a,b=b,a end;return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
V.__div=function(a,b) return a*(1/b) end
function V:Cross(b) return Vector3.new(self.Y*b.Z-self.Z*b.Y,self.Z*b.X-self.X*b.Z,self.X*b.Y-self.Y*b.X) end
function V:Lerp(b,t) return self+(b-self)*t end
local CF={}
local ident={1,0,0,0,1,0,0,0,1}
local function frame(p,m) return setmetatable({Position=p,m=m or table.clone(ident)},CF) end
local function rotate(m,v) return Vector3.new(m[1]*v.X+m[2]*v.Y+m[3]*v.Z,m[4]*v.X+m[5]*v.Y+m[6]*v.Z,m[7]*v.X+m[8]*v.Y+m[9]*v.Z) end
CF.__index=function(c,k) if k=="Rotation" then return frame(Vector3.new(),c.m) end;return CF[k] end
CF.__mul=function(a,b)
    local m={}
    for row=0,2 do for col=0,2 do local n=0;for i=0,2 do n+=a.m[row*3+i+1]*b.m[i*3+col+1] end;m[row*3+col+1]=n end end
    return frame(a.Position+rotate(a.m,b.Position),m)
end
function CF:Inverse()
    local a=self.m;local t={a[1],a[4],a[7],a[2],a[5],a[8],a[3],a[6],a[9]}
    return frame(rotate(t,self.Position*-1),t)
end
local CFrame={new=function(x,y,z) return frame(type(x)=="table" and x or Vector3.new(x,y,z)) end}
CFrame.Angles=function(x,y,z)
    local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
    return frame(Vector3.new(),{1,0,0,0,cx,-sx,0,sx,cx})*frame(Vector3.new(),{cy,0,sy,0,1,0,-sy,0,cy})*frame(Vector3.new(),{cz,-sz,0,sz,cz,0,0,0,1})
end
CFrame.lookAt=function(a,b)
    local back=(a-b).Unit;local right=Vector3.new(0,1,0):Cross(back)
    if right.Magnitude<.001 then right=Vector3.new(1,0,0) else right=right.Unit end
    local up=back:Cross(right)
    return frame(a,{right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z})
end
local Color={}
Color.__index=Color
function Color:Lerp(b,t) return setmetatable({R=self.R+(b.R-self.R)*t,G=self.G+(b.G-self.G)*t,B=self.B+(b.B-self.B)*t},Color) end
local Color3={new=function(r,g,b) return setmetatable({R=r,G=g,B=b},Color) end}
Color3.fromRGB=function(r,g,b) return Color3.new(r/255,g/255,b/255) end
local Enum=setmetatable({},{__index=function(t,k) local v=setmetatable({},{__index=function(_,name)return k.."."..name end});rawset(t,k,v);return v end})
local UDim={new=function(...) return {...} end}
local UDim2={new=function(...) return {...} end,fromScale=function(...) return {...} end,fromOffset=function(...)return {...}end}
local Vector2={new=function(...)return {...}end}
local methods={}
local instanceMeta={__index=function(t,k) return methods[k] or t.props[k] end,__newindex=function(t,k,v)
    if k=="Parent" then
        local old=t.props.Parent
        if old then local n=table.find(old.children,t);if n then table.remove(old.children,n) end end
        if v then table.insert(v.children,t) end
    end
    t.props[k]=v
end}
local Instance={new=function(class) return setmetatable({props={ClassName=class,Name=class,CFrame=CFrame.new(),Size=Vector3.new(1,1,1)},children={},attrs={},scale=1},instanceMeta) end}
function methods:IsA(k) return self.ClassName==k or (k=="BasePart" and (self.ClassName=="Part" or self.ClassName=="Seat" or self.ClassName=="SpawnLocation")) end
function methods:SetAttribute(k,v) self.attrs[k]=v end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:GetChildren() return table.clone(self.children) end
function methods:GetDescendants() local out={};for _,c in ipairs(self.children) do table.insert(out,c);for _,d in ipairs(c:GetDescendants()) do table.insert(out,d) end end;return out end
function methods:FindFirstChild(k) for _,c in ipairs(self.children) do if c.Name==k then return c end end end
function methods:WaitForChild(k) return self:FindFirstChild(k) end
function methods:Destroy() self.Parent=nil end
function methods:GetPivot() return self.PrimaryPart.CFrame end
function methods:GetScale() return self.scale end
function methods:ScaleTo(s)
    local ratio=s/self.scale;local pivot=self:GetPivot()
    for _,d in ipairs(self:GetDescendants()) do if d:IsA("BasePart") then local cf=pivot:Inverse()*d.CFrame;d.CFrame=pivot*CFrame.new(cf.Position*ratio)*cf.Rotation;d.Size=d.Size*ratio end end
    self.scale=s
end
function methods:PivotTo(target)
    local delta=target*self:GetPivot():Inverse()
    for _,d in ipairs(self:GetDescendants()) do if d:IsA("BasePart") then d.CFrame=delta*d.CFrame end end
end
local Workspace=Instance.new("Folder")
local Lighting=Instance.new("Folder")
local game={GetService=function(_,name) if name=="Workspace" then return Workspace elseif name=="Lighting" then return Lighting elseif name=="TweenService" then return {} end;error(name) end}
local function loadStaff()
'''
tests=r'''
end
local StaffModel=loadStaff()
local Data=require("../shared/Data")
local function near(a,b) assert((a-b).Magnitude<1e-6) end
local maxParts=0
for _,teacher in ipairs(Data.Teachers) do
    local m=StaffModel.create(teacher)
    assert(m.Name==teacher.name and m.PrimaryPart.Name=="HumanoidRootPart")
    assert(m:GetAttribute("StaffGeometryVersion")==3)
    local mask=m:FindFirstChild("Smile upper mask")
    local eye=m:FindFirstChild("Expressive oval eye")
    assert(mask.CFrame.Position.Y+mask.Size.Y/2<eye.CFrame.Position.Y-eye.Size.Y/2,"Smile mask must not clip the eyes")
    local head=m:FindFirstChild("Head")
    assert(head and head:FindFirstChild("Classic rounded head").MeshType==Enum.MeshType.Head)
    local n,groups,counts=0,{},{}
    local minY,maxY=math.huge,-math.huge
    for _,d in ipairs(m:GetDescendants()) do
        counts[d.Name]=(counts[d.Name] or 0)+1
        if d:IsA("BasePart") then
            n+=1
            assert(d.Anchored and not d.CanCollide and not d.CanTouch and not d.CanQuery,d.Name)
            assert(d.Size.X>0 and d.Size.Y>0 and d.Size.Z>0)
            for _,v in ipairs({d.CFrame.Position.X,d.CFrame.Position.Y,d.CFrame.Position.Z}) do assert(v==v and math.abs(v)<20) end
            minY=math.min(minY,d.CFrame.Position.Y-d.Size.Y/2);maxY=math.max(maxY,d.CFrame.Position.Y+d.Size.Y/2)
            local group=d:GetAttribute("PoseGroup")
            if group then groups[group]=(groups[group] or 0)+1;assert(d:GetAttribute("RestCF")) end
        end
    end
    assert(n<=180,"Staff part budget exceeded: "..teacher.name.." "..n)
    maxParts=math.max(maxParts,n)
    assert(minY+3.15>.44 and minY+3.15<.60,"Feet must meet the classroom floor")
    assert(maxY+3.15<7.6,"Staff must fit the classroom doorway")
    assert(counts["Torso rounded corner"]==4 and counts["Left Arm rounded corner"]==4 and counts["Left Leg rounded corner"]==4)
    assert(counts["C shaped hand"]==20 and counts["Expressive oval eye"]==2 and counts["Eye catchlight"]==2)
    assert(groups.leftArm>=14 and groups.rightArm>=14 and groups.leftLeg>=6 and groups.rightLeg>=6)
    assert(m.PrimaryPart:FindFirstChild("Speech").Enabled==false)
    assert(m.PrimaryPart:FindFirstChild("TeacherName").Size[1]==4.8, "World label must scale in studs rather than fixed pixels")
    if teacher.name=="Mr. Bolich" then assert(counts["Beard strand"]==7 and counts["Sneaker lace"]==6 and counts["Polo woven horizontal check"]==8) end
    if teacher.name=="Dr. McBreen" then assert(counts["Tie diagonal stripe"]==5 and counts["Notched jacket lapel"]==2) end
    if teacher.name=="Mrs. Boyer" then assert(counts["Pearl earring"]==2 and counts["Gold mission pin"]==1) end
    local arm=m:FindFirstChild("Left Arm")
    local cuff=m:FindFirstChild("Sleeve hem")
    local before=(arm.CFrame:Inverse()*cuff.CFrame).Position
    m:PivotTo(CFrame.new(29,3.15,15.5)*CFrame.Angles(0,math.pi,0))
    StaffModel.pose(m,1.2,true)
    near((arm.CFrame:Inverse()*cuff.CFrame).Position,before)
    local posed=arm.CFrame.Position
    StaffModel.pose(m,1.2,true);near(arm.CFrame.Position,posed)
    StaffModel.pose(m,0,false)
    near(arm.CFrame.Position,(m:GetPivot()*CFrame.new(arm:GetAttribute("RestCF").Position*m:GetScale())).Position)
end
local script={Parent={WaitForChild=function(_,name)assert(name=="StaffModel");return StaffModel end}}
local nativeRequire=require
local require=function(module) if module==StaffModel then return StaffModel end;return nativeRequire(module) end
local function loadWorld()
'''
finish=r'''
end
local World=loadWorld()
World.build()
local counts={}
assert(#World.Root:GetDescendants()<3000,"Classroom object budget exceeded")
for _,d in ipairs(World.Root:GetDescendants()) do
    counts[d.Name]=(counts[d.Name] or 0)+1
    if d:IsA("BasePart") then assert(d.Size.X>0 and d.Size.Y>0 and d.Size.Z>0,d.Name) end
end
assert(counts["Oak floor board"]>290 and counts["Teacher inset drawer"]==6)
assert(counts["Student desk top rounded corner"]==64 and counts["Student chair back rounded corner"]==64)
assert(counts["Cubbie divider"]==7 and counts["Bin side"]==24)
assert(counts["Student desk top"]==16 and counts["Emma desk nameplate"]==1)
assert(counts["Metal coat hook"]==8 and counts["Hanging school bag"]==8)
assert(counts["Reading rug alphabet border"]==26 and counts["Reading rug flower center"]==10)
assert(counts["Window blind slat"]==32 and counts["Blue curtain fold"]==12)
assert(counts["Color dot reading rug"]==nil,"Rug layers must not overlap")
assert(World.BoardQuestion.Parent.Parent.Face==Enum.NormalId.Back)
assert(World.BoardQuestion.Parent.Parent.CanvasSize[2]==math.floor(1200*6.8/23.5),"Smartboard text must retain its physical aspect ratio")
local alphabet=World.Root:FindFirstChild("Alphabet tile")
assert(alphabet:FindFirstChild("Surface").CanvasSize[2]==math.floor(1000*1.4/2.15),"Alphabet text must retain its physical aspect ratio")
-- The straight side aisle is clear of solid desk tops, chairs, and storage.
for _,d in ipairs(World.Root:GetChildren()) do
    if d:IsA("BasePart") and d.CanCollide and d.CFrame.Position.Y>1 and d.CFrame.Position.Y<8 then
        local p,s=d.CFrame.Position,d.Size
        if p.Z>-21 and p.Z<16 then assert(not(p.X-s.X/2<30.4 and p.X+s.X/2>27.6),"Blocked teacher aisle: "..d.Name) end
    end
end
print("PASS: actual constructors for 18 staff, max "..maxParts.." parts, floor/doorway fit, limb-detail poses, portrait-specific details; classroom 16 desks, storage, rugs, windows, board and teacher aisle")
'''
fixture=p/'tests/.geometry-runtime.generated.lua'
try:
    fixture.write_text(harness+(p/'server/StaffModel.lua').read_text()+tests+(p/'server/World.lua').read_text()+finish)
    subprocess.run([args.luau,str(fixture)],check=True)
finally:
    fixture.unlink(missing_ok=True)
