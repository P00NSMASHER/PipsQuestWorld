-- Native Client/Server test; no photographs or external assets.
local root=assert(workspace:FindFirstChild("ABVMClassroomReplica"),"ROOM_MISSING")
local panels={}
for _,object in ipairs(root:GetDescendants()) do
    if object.Name=="Blue folding tumbling mat panel" then
        assert(object:IsA("BasePart"),"MAT_PANEL_NOT_PART")
        assert(object.Anchored and not object.CanCollide,"MAT_CHANGES_NAVIGATION")
        assert(object.Size.Y<=.25 and object.Position.Y-object.Size.Y/2>=.499,"MAT_NOT_ON_FLOOR")
        assert(object.Color.B>object.Color.R*2 and object.Color.B>object.Color.G,"MAT_NOT_BLUE")
        assert(object:FindFirstChild("VinylStitchedBinding"),"MAT_BINDING_MISSING")
        table.insert(panels,object)
    end
end
assert(#panels==3,"THREE_FOLD_MAT_MISSING")
table.sort(panels,function(a,b)return a.Position.Z<b.Position.Z end)
for i=2,3 do
    local gap=panels[i].Position.Z-panels[i-1].Position.Z-panels[i].Size.Z
    assert(gap>=0 and gap<=.08,"MAT_FOLD_SEAM_INVALID")
end
local count=0
for _,p in ipairs(root:GetDescendants()) do if p:IsA("BasePart") then count+=1 end end
assert(count<=3050,"MAT_EXCEEDS_MOBILE_PART_BUDGET")
return {native=true,blueMatPanels=#panels,parts=count,deskLayoutUnchanged=true}
