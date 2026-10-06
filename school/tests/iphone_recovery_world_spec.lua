-- Execute the canonical builder and inspect generated structural geometry.
-- AABB checks cover the named axis-aligned structures, not engine physics.
local Stub=dofile('school/tests/support/roblox_client_stub.lua')
local c=Stub.new(852,393,58,true)
c:load('school/src/server/CampusBuilder.server.lua')
local campus=assert(c.services.Workspace:FindFirstChild('SchoolCampus'))
local config=c.env.require(c.shared:FindFirstChild('SchoolConfig'))
local function blocks(part,x,y,z,halfWidth,halfHeight)
    local p,s=part.Position,part.Size
    return part:IsA('BasePart') and part.CanCollide
        and math.abs(p.X-x) < s.X/2 + halfWidth
        and math.abs(p.Y-y) < s.Y/2 + halfHeight
        and math.abs(p.Z-z) < s.Z/2 + halfWidth
end
for _,roomName in ipairs({'Homeroom','Math','ELA','Science','SocialStudies','Library'}) do
    local position=config.Rooms[roomName].position
    local room=assert(campus:FindFirstChild(roomName,true))
    local doorX=position.X < 0 and position.X+29 or position.X-29
    for _,p in ipairs(room:GetChildren()) do
        assert(not blocks(p,doorX,4.5,position.Z,1.5,2.5),roomName..' hall entrance blocked by '..p.Name)
    end
    for _,p in ipairs(campus.Geometry:GetChildren()) do
        if p.Name=='Locker' then
            local side=position.X < 0 and -15.9 or 15.9
            assert(not blocks(p,side,4.5,position.Z,1.5,2.5),roomName..' doorway hidden behind lockers')
        end
    end
end
for _,plot in ipairs(config.HousingPlots) do
    local model=assert(campus.HousingPlots:FindFirstChild(plot.id))
    local walls=0
    for _,p in ipairs(model:GetChildren()) do
        if p.Name=='HouseBody' then
            walls=walls+1
            for _,zOffset in ipairs({-18,-15.5,-12,0,8}) do
                assert(not blocks(p,plot.houseOrigin.X,4.5,plot.houseOrigin.Z+zOffset,1.5,2.5),plot.id..' entry/interior is solid')
            end
        end
    end
    assert(walls==6,'Expected hollow house shell with six style-linked wall parts')
    assert(model:FindFirstChild('HouseFloor'),'House floor missing')
end
for _,p in ipairs(campus.Geometry:GetChildren()) do
    if p.Name:match('^UpperHallRail') then
        assert(not blocks(p,0,10,-115,2,2.5),'Landing rail crosses stair exit')
    end
    if p.Name:match('^Sign_') then
        assert(p.CanCollide==false and p.CanQuery==false,'Signs must not block avatars/camera')
    end
end
assert(campus:FindFirstChild('SchoolCeiling',true),'School roof missing')
assert(campus:FindFirstChild('HallSkylight',true),'Hall skylight missing')
for _,key in ipairs({'Cafe','StyleShop','AutoShop','Market'}) do
    local door=assert(campus:FindFirstChild(key..'Door',true))
    assert(door.Position.Z>config.WorldLocations[key].position.Z,'Store door must face the street')
    local back=assert(campus:FindFirstChild(key..'Back',true))
    assert(back.Position.Z<config.WorldLocations[key].position.Z,'Store back wall blocks street entrance')
end
local spawn=assert(campus:FindFirstChild('MainSpawn',true))
assert(spawn.CanCollide==false and spawn.Transparency==1,'Spawn pad obstructs entrance')
assert(campus:GetAttribute('RecoveryBuild')=='IPHONE-01','Build label absent')
print('IPHONE_RECOVERY_GENERATED_STRUCTURES_PASS__AABB_STUB_ONLY')
