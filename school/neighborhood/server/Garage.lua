--!strict
-- Adapted from canonical VehicleService: one owner, bounded inputs, control expiry.
-- Kinematic low-speed vehicles now stop on blockcasts instead of crossing walls.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local World=require(script.Parent.World)
local Garage={active={}}
local function finite(x) return type(x)=="number" and x==x and math.abs(x)<=1 end
function Garage.remove(player)
    local r=Garage.active[player.UserId]
    if not r then return end
    if r.seat.Occupant then r.seat.Occupant.Sit=false end
    r.model:Destroy(); Garage.active[player.UserId]=nil;player:SetAttribute("NeighborhoodDriving",false)
end
function Garage.spawn(player,item,cf)
    local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then return false end
    Garage.remove(player)
    local model=Instance.new("Model");model.Name="Ride_"..player.UserId;model:SetAttribute("OwnerUserId",player.UserId)
    local tint=Color3.fromRGB(table.unpack(item.color))
    local function p(n,s,o,c,collide)
        return World.part(model,n,s,cf*CFrame.new(o),c,nil,collide)
    end
    local length=item.style==4 and 12 or (item.style==1 and 8 or 10)
    local roofY=item.style==3 and 2.8 or 3.5
    local body=p("Chassis",Vector3.new(6.7,1.3,length),Vector3.zero,tint,true)
    model.PrimaryPart=body
    p("Bonnet",Vector3.new(6.3,.6,2.7),Vector3.new(0,.9,-3),tint,false)
    p("Rear",Vector3.new(6.3,.7,2),Vector3.new(0,1,3.7),tint,false)
    p("Roof",Vector3.new(6.1,.35,4.7),Vector3.new(0,roofY,.5),item.style>=3 and Color3.fromRGB(47,60,76) or tint,false)
    for _,x in ipairs({-2.8,2.8}) do
        for _,z in ipairs({-1.7,2.4}) do p("Pillar",Vector3.new(.3,roofY-.7,.3),Vector3.new(x,(roofY+.7)/2,z),tint,false) end
    end
    local windshield=p("Windshield",Vector3.new(5.5,roofY-1.6,.15),Vector3.new(0,roofY-1.2,-1.7),Color3.fromRGB(178,217,225),false)
    windshield.Material=Enum.Material.Glass;windshield.Transparency=.55
    p("Headlight L",Vector3.new(1.4,.5,.12),Vector3.new(-2,.3,-length/2-.08),Color3.fromRGB(245,232,184),false).Material=Enum.Material.Neon
    p("Headlight R",Vector3.new(1.4,.5,.12),Vector3.new(2,.3,-length/2-.08),Color3.fromRGB(245,232,184),false).Material=Enum.Material.Neon
    if item.style>=3 then
        p("Signature stripe",Vector3.new(.5,.05,length),Vector3.new(0,.68,0),Color3.fromRGB(220,185,116),false)
    end
    for _,x in ipairs({-3.35,3.35}) do for _,z in ipairs({-3.2,3.2}) do
        local wheel=p("Wheel",Vector3.new(.7,2.1,2.1),Vector3.new(x,-.55,z),Color3.fromRGB(38,45,54),false);wheel.Shape=Enum.PartType.Cylinder
        local hub=p("Wheel hub",Vector3.new(.72,1.1,1.1),Vector3.new(x,-.55,z),item.style==4 and Color3.fromRGB(214,180,111) or Color3.fromRGB(186,196,201),false);hub.Shape=Enum.PartType.Cylinder
    end end
    local seat=Instance.new("VehicleSeat");seat.Name="DriverSeat";seat.Size=Vector3.new(2.5,.7,2.6);seat.CFrame=cf*CFrame.new(0,1.2,.5);seat.Anchored=true;seat.Torque=0;seat.MaxSpeed=0;seat.TurnSpeed=0;seat.Color=Color3.fromRGB(56,68,80);seat.Parent=model
    model.Parent=Workspace
    local r={model=model,seat=seat,cf=cf,throttle=0,steer=0,at=0,speed=item.speed}
    Garage.active[player.UserId]=r
    seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local occupant=seat.Occupant
        if occupant and Players:GetPlayerFromCharacter(occupant.Parent)~=player then occupant.Sit=false;return end
        player:SetAttribute("NeighborhoodDriving",occupant~=nil)
        if not occupant then r.throttle=0;r.steer=0 end
    end)
    seat:Sit(hum)
    return true
end
function Garage.controls(player,throttle,steer)
    local r=Garage.active[player.UserId]
    if not r or not r.seat.Occupant or r.seat.Occupant.Parent~=player.Character then return end
    if not finite(throttle) or not finite(steer) then r.throttle=0;r.steer=0;return end
    r.throttle=math.clamp(throttle,-1,1);r.steer=math.clamp(steer,-1,1);r.at=os.clock()
end
RunService.Heartbeat:Connect(function(dt)
    dt=math.min(dt,.05)
    for id,r in pairs(Garage.active) do
        local player=Players:GetPlayerByUserId(id)
        if not player or not r.model.Parent then continue end
        if not r.seat.Occupant or r.seat.Occupant.Parent~=player.Character then continue end
        local throttle,steer=r.throttle,r.steer
        if os.clock()-r.at>.4 then throttle=0;steer=0 end
        if throttle==0 then continue end
        local nextCf=r.cf*CFrame.Angles(0,-steer*math.rad(60)*dt*throttle,0)
        local delta=nextCf.LookVector*throttle*r.speed*dt
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={r.model,player.Character};params.RespectCanCollide=true
        local hit=Workspace:Blockcast(nextCf,Vector3.new(6.8,1.5,10.5),delta,params)
        local pos=nextCf.Position+delta
        if not hit and math.abs(pos.X)<=215 and pos.Z>=-12 and pos.Z<=1140 then
            r.cf=nextCf+delta;r.model:PivotTo(r.cf)
        end
    end
end)
return Garage
