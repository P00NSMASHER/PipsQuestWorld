-- Run in the Client DataModel during a playtest of the exported candidate.
local root=assert(workspace:FindFirstChild("ABVMClassroomReplica"),"RUNTIME_ROOM_MISSING")
local player=assert(game:GetService("Players").LocalPlayer,"CLIENT_CONTEXT_REQUIRED")
local character=assert(player.Character,"PLAYER_NOT_SPAWNED")
local humanoid=assert(character:FindFirstChildOfClass("Humanoid"),"HUMANOID_MISSING")
local floor=assert(root:FindFirstChild("Warm oak classroom floor"),"FLOOR_MISSING")
assert(humanoid.Health>0 and humanoid.WalkSpeed==13,"SERVER_STARTUP_DID_NOT_COMPLETE")
assert(floor.MaterialVariant=="EmmaClassroomOak","RUNTIME_FLOOR_FINISH_NOT_CONFIGURED")
assert(root:GetAttribute("FloorFinishStatus")=="ConfiguredForTextureStreaming","RUNTIME_FINISH_STATUS_INVALID")
local desks,parts=0,0
for _,object in ipairs(root:GetDescendants()) do
    if object:IsA("BasePart") then
        parts+=1
        if object.Name=="Student desk top" then desks+=1 end
    end
end
assert(desks==16 and parts<=3050,"RUNTIME_GEOMETRY_REGRESSION")
return {nativePlay=true,startupCompleted=true,deskCount=desks,parts=parts,materialConfigured=true}
