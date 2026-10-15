-- Native Client/Server regression: the owner's October 12 photo-match scope
-- explicitly excludes the gym/tumbling mat.
local root=assert(workspace:FindFirstChild("ABVMClassroomReplica"),"ROOM_MISSING")
local forbidden={}
for _,object in ipairs(root:GetDescendants()) do
    local name=string.lower(object.Name)
    if string.find(name,"tumbling mat",1,true)
        or string.find(name,"gym mat",1,true)
        or object.Name=="VinylStitchedBinding" then
        table.insert(forbidden,object:GetFullName())
    end
end
assert(#forbidden==0,"GYM_TUMBLING_MAT_MUST_NOT_SHIP: "..table.concat(forbidden,", "))
local count=0
for _,p in ipairs(root:GetDescendants()) do
    if p:IsA("BasePart") then count+=1 end
end
assert(count<=3050,"NO_MAT_CANDIDATE_EXCEEDS_MOBILE_PART_BUDGET")
return {native=true,gymMatExcluded=true,parts=count}
