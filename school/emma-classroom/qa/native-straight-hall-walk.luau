-- Client Play-mode physical walk. Start through the staff doorway first.
-- No PivotTo/CFrame assignment, speed override, jumping, or teleportation.
local player=assert(game:GetService("Players").LocalPlayer,"CLIENT_CONTEXT_REQUIRED")
local character=assert(player.Character,"CHARACTER_MISSING")
local body=assert(character:FindFirstChild("HumanoidRootPart"),"ROOT_MISSING")
local humanoid=assert(character:FindFirstChildOfClass("Humanoid"),"HUMANOID_MISSING")
assert(body.Position.X>=38 and body.Position.X<=48,"START_AT_STAFF_HALL_ENTRANCE")
assert(humanoid.WalkSpeed==13 and humanoid.Health>0,"PLAYER_NOT_READY")
local points={60,100,142,100,60,43}
local report={};local lateral=0;local began=os.clock()
for _,x in ipairs(points) do
    local start=os.clock()
    humanoid:MoveTo(Vector3.new(x,body.Position.Y,15.5))
    repeat
        task.wait(.1)
        lateral=math.max(lateral,math.abs(body.Position.Z-15.5))
        assert(body.Position.Y>1 and humanoid.Health>0,"HALL_WALK_FALL_OR_DEATH")
        assert(os.clock()-start<12,"HALL_WALK_OBSTRUCTED_AT_"..x)
    until (Vector2.new(body.Position.X,body.Position.Z)-Vector2.new(x,15.5)).Magnitude<1.2
    table.insert(report,{x=math.round(body.Position.X*100)/100,z=math.round(body.Position.Z*100)/100})
end
assert(lateral<1.6,"HALL_WALK_REQUIRED_DETOUR")
return {nativePlay=true,walkedBothDirections=true,noTeleports=true,waypoints=report,
    maxLateralDeviation=lateral,seconds=os.clock()-began}
