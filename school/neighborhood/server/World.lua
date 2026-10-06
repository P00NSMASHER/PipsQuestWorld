--!strict
-- Purpose-built school + residential street. No clock, job, club or city systems.
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Catalog=require(ReplicatedStorage.NeighborhoodShared.Catalog)
local World={rooms={},plots={},homes={},leaderboardParts={}}
local palette={navy=Color3.fromRGB(40,58,79),cream=Color3.fromRGB(239,234,221),wood=Color3.fromRGB(170,132,96),green=Color3.fromRGB(115,163,137),gold=Color3.fromRGB(216,185,115)}
local function color(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
function World.part(parent,name,size,cf,tint,material,collide)
    local p=Instance.new("Part")
    p.Name=name; p.Size=size; p.CFrame=cf; p.Color=tint
    p.Anchored=true; p.Material=material or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
    p.CanCollide=collide~=false; p.Parent=parent
    return p
end
local function sign(parent,text,cf,size,tint)
    local p=World.part(parent,"Sign",size or Vector3.new(20,4,0.3),cf,tint or palette.navy,nil,false)
    local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=28;g.Parent=p
    local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamBold;t.TextColor3=palette.cream;t.TextScaled=true;t.Text=text;t.Parent=g
    local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,10);pad.PaddingRight=UDim.new(0,10);pad.PaddingTop=UDim.new(0,6);pad.PaddingBottom=UDim.new(0,6);pad.Parent=t
    return p
end
local function tree(parent,x,z)
    World.part(parent,"Tree trunk",Vector3.new(2,9,2),CFrame.new(x,4.5,z),palette.wood,Enum.Material.Wood)
    local crown=World.part(parent,"Tree crown",Vector3.new(12,13,12),CFrame.new(x,13,z),palette.green,Enum.Material.Grass,false)
    crown.Shape=Enum.PartType.Ball
end
local function desk(parent,x,z,tint)
    World.part(parent,"Desk top",Vector3.new(6,0.5,4),CFrame.new(x,3.6,z),palette.wood,Enum.Material.Wood)
    for _,dx in ipairs({-2.5,2.5}) do World.part(parent,"Desk leg",Vector3.new(.35,3,.35),CFrame.new(x+dx,1.8,z),palette.navy) end
    World.part(parent,"Chair",Vector3.new(2.4,.4,2.4),CFrame.new(x,2.2,z+4),tint)
    World.part(parent,"Chair back",Vector3.new(2.4,2.8,.3),CFrame.new(x,3.3,z+5),tint)
end
local function classroom(root,subject,x,z)
    local m=Instance.new("Model");m.Name=subject.id.."_classroom";m.Parent=root
    local tint=color(subject.color)
    World.part(m,"Floor",Vector3.new(62,.5,50),CFrame.new(x,.7,z),Color3.fromRGB(225,224,211),Enum.Material.WoodPlanks)
    World.part(m,"Outer wall",Vector3.new(1,17,50),CFrame.new(x+(x<0 and -31 or 31),8.5,z),palette.cream)
    for _,side in ipairs({-1,1}) do
        World.part(m,"End wall",Vector3.new(62,17,1),CFrame.new(x,8.5,z+side*25),palette.cream)
        World.part(m,"Hall wall",Vector3.new(1,17,18),CFrame.new(x+(x<0 and 31 or -31),8.5,z+side*16),palette.cream)
    end
    World.part(m,"Door lintel",Vector3.new(1,5,14),CFrame.new(x+(x<0 and 31 or -31),14.5,z),palette.cream)
    World.part(m,"Teaching wall",Vector3.new(36,8,.3),CFrame.new(x,9,z-24.35),palette.navy,nil,false)
    sign(m,subject.name.."\nWalk in. Learn. Earn.",CFrame.new(x,9,z-24.05)*CFrame.Angles(0,math.pi,0),Vector3.new(35,7,.1),tint)
    World.part(m,"Subject runner",Vector3.new(11,.08,48),CFrame.new(x,.99,z),tint,Enum.Material.Fabric,false)
    for _,dx in ipairs({-18,18}) do for _,dz in ipairs({-8,7}) do desk(m,x+dx,z+dz,tint) end end
    for _,dx in ipairs({-18,18}) do
        local light=World.part(m,"Ceiling light",Vector3.new(10,.3,2),CFrame.new(x+dx,16.3,z),Color3.fromRGB(248,241,211),Enum.Material.Neon,false)
        local glow=Instance.new("SurfaceLight");glow.Face=Enum.NormalId.Bottom;glow.Brightness=.7;glow.Range=24;glow.Angle=120;glow.Parent=light
    end
    -- Label faces the corridor on both sides; not dependent on a GUI prompt.
    local labelCF=CFrame.new(x+(x<0 and 30.4 or -30.4),12.3,z)*CFrame.Angles(0,x<0 and -math.pi/2 or math.pi/2,0)
    sign(m,subject.short,labelCF,Vector3.new(12,2.5,.2),tint)
    World.rooms[subject.id]={x=x,z=z,hx=29,hz=23}
end
function World.build()
    local old=Workspace:FindFirstChild("NeighborhoodWorld"); if old then old:Destroy() end
    local root=Instance.new("Folder");root.Name="NeighborhoodWorld";root.Parent=Workspace;World.root=root
    World.part(root,"Ground",Vector3.new(500,2,1450),CFrame.new(0,-1,480),Color3.fromRGB(145,180,138),Enum.Material.Grass)
    World.part(root,"School foundation",Vector3.new(176,1,142),CFrame.new(0,0,-94),palette.cream,Enum.Material.Concrete)
    World.part(root,"Hall runner",Vector3.new(27,.2,140),CFrame.new(0,.7,-94),palette.wood,Enum.Material.WoodPlanks)
    World.part(root,"North facade",Vector3.new(176,18,1),CFrame.new(0,9,-164),palette.cream)
    for _,x in ipairs({-53,53}) do World.part(root,"Front facade",Vector3.new(70,18,1),CFrame.new(x,9,-24),palette.cream) end
    World.part(root,"Entrance header",Vector3.new(36,5,1),CFrame.new(0,15.5,-24),palette.navy)
    World.part(root,"Roof",Vector3.new(180,1.2,147),CFrame.new(0,18.8,-94),palette.navy,Enum.Material.Slate)
    for _,x in ipairs({-86,86}) do World.part(root,"Facade edge",Vector3.new(2,18,142),CFrame.new(x,9,-94),palette.cream) end
    sign(root,"PIP HIGH",CFrame.new(0,16,-22)*CFrame.Angles(0,math.pi,0),Vector3.new(29,4,.4))
    -- Three permanent lobby boards: academic accuracy, total answers, and current money.
    -- Their SurfaceGuis are filled by the server Leaderboards module.
    World.leaderboardParts={
        accuracy=World.part(root,"Accuracy leaderboard",Vector3.new(48,13,.5),CFrame.new(-54,9.5,-163.2)*CFrame.Angles(0,math.pi,0),palette.navy,nil,false),
        questions=World.part(root,"Questions leaderboard",Vector3.new(48,13,.5),CFrame.new(0,9.5,-163.2)*CFrame.Angles(0,math.pi,0),palette.navy,nil,false),
        credits=World.part(root,"Money leaderboard",Vector3.new(48,13,.5),CFrame.new(54,9.5,-163.2)*CFrame.Angles(0,math.pi,0),palette.navy,nil,false),
    }
    for i,subject in ipairs(Catalog.Subjects) do classroom(root,subject,i%2==1 and -51 or 51,i<=2 and -124 or -64) end
    -- A small school store is the only non-residential destination.
    World.shopPosition=Vector3.new(0,2,-151)
    World.part(root,"Shop counter",Vector3.new(20,4,4),CFrame.new(0,2.6,-156),palette.wood,Enum.Material.Wood)
    local sp=sign(root,"CAMPUS SHOP",CFrame.new(0,8,-159)*CFrame.Angles(0,math.pi,0),Vector3.new(22,3,.2),palette.navy)
    local prompt=Instance.new("ProximityPrompt");prompt.ActionText="Browse";prompt.ObjectText="Campus shop";prompt.MaxActivationDistance=16;prompt.RequiresLineOfSight=false;prompt.HoldDuration=0;prompt.Parent=sp
    World.shopPrompt=prompt
    World.part(root,"School approach",Vector3.new(28,.3,52),CFrame.new(0,.2,0),Color3.fromRGB(219,212,194),Enum.Material.Cobblestone)
    World.part(root,"Main street",Vector3.new(28,.12,1110),CFrame.new(0,.04,580),Color3.fromRGB(69,78,85),Enum.Material.Asphalt)
    World.part(root,"School frontage road",Vector3.new(225,.1,22),CFrame.new(0,.04,39),Color3.fromRGB(69,78,85),Enum.Material.Asphalt)
    for _,x in ipairs({-21,21}) do World.part(root,"Sidewalk",Vector3.new(12,.3,1110),CFrame.new(x,.15,580),palette.cream,Enum.Material.Concrete) end
    for z=70,1090,28 do World.part(root,"Road marking",Vector3.new(.4,.03,9),CFrame.new(0,.12,z),Color3.fromRGB(236,221,156),nil,false) end
    for i=1,24 do
        local side=i%2==1 and -1 or 1
        local row=math.ceil(i/2)
        local x,z=side*72,72+(row-1)*90
        local cf=CFrame.new(x,0,z)*CFrame.Angles(0,side<0 and math.pi/2 or -math.pi/2,0)
        World.plots[i]={cf=cf,door=cf* CFrame.new(0,4,25),drive=CFrame.new(side*8,1.65,z+27),owner=nil}
        World.part(root,"Residential lot "..i,Vector3.new(79,.25,76),CFrame.new(x,.13,z),Color3.fromRGB(161,190,145),Enum.Material.Grass)
        tree(root,side*119,z-20)
    end
    for _,x in ipairs({-109,109}) do tree(root,x,-15);tree(root,x,-120) end
    local spawn=Instance.new("SpawnLocation");spawn.Name="SchoolArrival";spawn.Size=Vector3.new(8,1,8);spawn.CFrame=CFrame.new(0,1,12);spawn.Transparency=1;spawn.CanCollide=false;spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=root
    World.schoolDoor=CFrame.new(0,4,-4)*CFrame.Angles(0,math.pi,0)
    return World
end
function World.subjectAt(position)
    if position.Y<0 or position.Y>17 then return nil end
    for id,r in pairs(World.rooms) do
        if math.abs(position.X-r.x)<=r.hx and math.abs(position.Z-r.z)<=r.hz then return id end
    end
    return nil
end
function World.allocate(player)
    for i,p in ipairs(World.plots) do
        if not p.owner then p.owner=player.UserId;return i end
    end
    return nil
end
function World.house(player,plotId,profile)
    if not plotId then return end
    local plot=World.plots[plotId]; if not plot or plot.owner~=player.UserId then return end
    if World.homes[player.UserId] then World.homes[player.UserId]:Destroy() end
    local item=Catalog.ById[profile.equipped.home] or Catalog.ById.home_starter
    local stage=item.style
    local width=30+4*stage;local depth=26+2*stage
    local model=Instance.new("Model");model.Name="Home_"..player.UserId;model:SetAttribute("OwnerUserId",player.UserId);model.Parent=World.root
    World.homes[player.UserId]=model
    local function p(name,size,xyz,tint,material,collide)
        return World.part(model,name,size,plot.cf*CFrame.new(xyz),tint,material,collide)
    end
    p("Floor",Vector3.new(width,1,depth),Vector3.new(0,.5,0),palette.wood,Enum.Material.WoodPlanks)
    p("Back",Vector3.new(width,12,1),Vector3.new(0,6.8,-depth/2),color(item.color))
    for _,side in ipairs({-1,1}) do
        p("Side",Vector3.new(1,12,depth),Vector3.new(side*width/2,6.8,0),color(item.color))
        p("Front",Vector3.new((width-9)/2,12,1),Vector3.new(side*(width+9)/4,6.8,depth/2),color(item.color))
        local windowWidth=stage>=3 and 9 or 7
        local window=p("Front window",Vector3.new(windowWidth,5,.12),Vector3.new(side*(width+9)/4,7,depth/2+.6),Color3.fromRGB(158,200,210),Enum.Material.Glass,false)
        window.Transparency=.18
        if stage>=2 then
            for _,offset in ipairs({-windowWidth/2-.65,windowWidth/2+.65}) do
                p("Window shutter",Vector3.new(1,5.8,.25),Vector3.new(side*(width+9)/4+offset,7,depth/2+.65),palette.navy)
            end
        end
        p("Window ledge",Vector3.new(8,.4,1),Vector3.new(side*(width+9)/4,4.3,depth/2+.6),palette.cream)
    end
    p("Door header",Vector3.new(9,3,1),Vector3.new(0,11.3,depth/2),palette.cream)
    p("Roof",Vector3.new(width+3,1,depth+4),Vector3.new(0,13.5,0),stage>=3 and palette.navy or palette.wood,Enum.Material.Slate)
    p("Porch",Vector3.new(width,.5,7),Vector3.new(0,.6,depth/2+3.5),palette.cream,Enum.Material.Concrete)
    p("Path",Vector3.new(8,.2,26-depth/2),Vector3.new(0,.2,(26+depth/2)/2),palette.cream,Enum.Material.Cobblestone)
    local sofaColor=profile.owned.item_sofa and color(Catalog.ById.item_sofa.color) or Color3.fromRGB(184,181,166)
    p("Sofa base",Vector3.new(10,2,4),Vector3.new(-8,2,-5),sofaColor,Enum.Material.Fabric)
    p("Sofa back",Vector3.new(10,3.2,1),Vector3.new(-8,3,-7),sofaColor,Enum.Material.Fabric)
    p("Bed",Vector3.new(6,1.4,9),Vector3.new(width/2-6,2,-depth/2+7),palette.cream,Enum.Material.Fabric)
    p("Bed blanket",Vector3.new(6,.3,6),Vector3.new(width/2-6,2.9,-depth/2+8),Color3.fromRGB(125,164,179),Enum.Material.Fabric)
    p("Coffee table",Vector3.new(7,2,3.5),Vector3.new(-8,2,1),palette.wood,Enum.Material.Wood)
    if stage>=2 then
        for _,x in ipairs({-width/2+2,width/2-2}) do
            p("Porch column",Vector3.new(1,12,1),Vector3.new(x,6.7,depth/2+6),palette.cream)
            p("Planter",Vector3.new(5,2,3),Vector3.new(x,1.5,depth/2+9),palette.wood)
            p("Flowers",Vector3.new(4,1,2),Vector3.new(x,3,depth/2+9),Color3.fromRGB(223,153,171),nil,false)
        end
    end
    if stage>=3 then
        p("Terrace",Vector3.new(width-5,1,depth-2),Vector3.new(0,14.5,0),palette.cream)
        for _,x in ipairs({-width/2+3,width/2-3}) do p("Terrace trim",Vector3.new(.5,2.5,depth-2),Vector3.new(x,16,0),palette.gold,nil,false) end
    end
    if stage>=3 then
        for step=0,14 do
            p("Terrace stair",Vector3.new(5,.55,2.2),Vector3.new(width/2+4,1+step*.96,14-step*2),palette.cream)
        end
        p("Terrace access",Vector3.new(10,.6,5),Vector3.new(width/2+.5,14.5,-14),palette.cream)
    end
    if stage>=4 then
        p("Upper pavilion",Vector3.new(width-12,8,depth-14),Vector3.new(0,18,-3),palette.cream)
        p("Pavilion glazing",Vector3.new(width-16,5,.3),Vector3.new(0,18,(depth-14)/2-2.7),Color3.fromRGB(147,187,201),Enum.Material.Glass,false)
        p("Upper roof",Vector3.new(width-9,.7,depth-11),Vector3.new(0,22.4,-3),palette.navy)
    end
    if profile.owned.item_rug then p("Sunrise rug",Vector3.new(14,.06,10),Vector3.new(-6,1.05,1),color(Catalog.ById.item_rug.color),Enum.Material.Fabric,false) end
    if profile.owned.item_lamp then
        p("Lamp stem",Vector3.new(.35,5,.35),Vector3.new(-width/2+3,3.4,-6),palette.gold,nil,false)
        local lamp=p("Lamp shade",Vector3.new(3,2,3),Vector3.new(-width/2+3,6.4,-6),palette.cream,Enum.Material.Neon,false)
        local light=Instance.new("PointLight");light.Color=Color3.fromRGB(255,222,170);light.Brightness=.65;light.Range=14;light.Parent=lamp
    end
    if profile.owned.item_books then
        p("Bookcase",Vector3.new(8,8,2),Vector3.new(0,5,-depth/2+2),palette.wood,Enum.Material.Wood)
        for i=1,8 do p("Book",Vector3.new(.7,2.3,.9),Vector3.new(-3.6+i*.8,6,-depth/2+3.2),color(Catalog.Subjects[(i-1)%4+1].color),nil,false) end
    end
    if profile.owned.item_fountain then
        local basin=p("Fountain basin",Vector3.new(1.5,8,8),Vector3.new(width/2-6,1.3,depth/2+10),Color3.fromRGB(214,219,218))
        basin.Shape=Enum.PartType.Cylinder;basin.CFrame *= CFrame.Angles(0,0,math.pi/2)
        p("Fountain water",Vector3.new(6,.1,6),Vector3.new(width/2-6,2.1,depth/2+10),Color3.fromRGB(117,185,202),Enum.Material.Glass,false)
    end
    sign(model,player.DisplayName.."'s home\n"..item.name,plot.cf*CFrame.new(-width/2+4,4,depth/2+8)*CFrame.Angles(0,math.pi,0),Vector3.new(13,4,.3))
end
function World.release(player)
    if World.homes[player.UserId] then World.homes[player.UserId]:Destroy();World.homes[player.UserId]=nil end
    for _,p in ipairs(World.plots) do if p.owner==player.UserId then p.owner=nil end end
end
return World
