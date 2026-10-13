-- Client Play-mode physical walk for the perpendicular staff-hall route.
-- Historical filename retained for receipt continuity. No PivotTo/CFrame,
-- speed override, jumping, or teleportation.
local player=assert(game:GetService("Players").LocalPlayer,"CLIENT_CONTEXT_REQUIRED")
local character=assert(player.Character,"CHARACTER_MISSING")
local body=assert(character:FindFirstChild("HumanoidRootPart"),"ROOT_MISSING")
local humanoid=assert(character:FindFirstChildOfClass("Humanoid"),"HUMANOID_MISSING")
assert(body.Position.X>=38 and body.Position.X<=48
    and body.Position.Z>=8 and body.Position.Z<=24,
    "START_AT_STAFF_CROSS_CORRIDOR")
assert(humanoid.WalkSpeed==13 and humanoid.Health>0,"PLAYER_NOT_READY")
local y=body.Position.Y
local points={
    Vector3.new(45,y,29),
    Vector3.new(30,y,38),
    Vector3.new(-42,y,38),
    Vector3.new(43,y,38),
    Vector3.new(45,y,29),
    Vector3.new(43,y,15.5),
}
local report={};local began=os.clock();local reachedTurn=false
for i,target in ipairs(points) do
    local start=os.clock()
    humanoid:MoveTo(target)
    repeat
        task.wait(.1)
        assert(body.Position.Y>1 and humanoid.Health>0,"HALL_WALK_FALL_OR_DEATH")
        assert(os.clock()-start<14,"HALL_WALK_OBSTRUCTED_AT_"..i)
    until (Vector2.new(body.Position.X,body.Position.Z)
        -Vector2.new(target.X,target.Z)).Magnitude<1.2
    reachedTurn=reachedTurn or (body.Position.Z>=28 and body.Position.X>=37.5)
    table.insert(report,{x=math.round(body.Position.X*100)/100,
        z=math.round(body.Position.Z*100)/100})
end
assert(reachedTurn,"HALL_WALK_PERPENDICULAR_TURN_NOT_REACHED")
return {nativePlay=true,walkedBothDirections=true,perpendicularTurn=true,
    noTeleports=true,waypoints=report,seconds=os.clock()-began}
