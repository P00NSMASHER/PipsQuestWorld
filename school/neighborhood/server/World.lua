--!strict
-- Assumption BVM-inspired school + residential neighborhood.
-- Exterior proportions and identity follow the user-authorized Pottsville references;
-- interior dimensions are deliberately widened/simplified for readable mobile play.
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Catalog=require(ReplicatedStorage.NeighborhoodShared.Catalog)

local World={rooms={},plots={},homes={},leaderboardParts={}}
local palette={
    navy=Color3.fromRGB(22,45,79),
    cream=Color3.fromRGB(239,234,221),
    wood=Color3.fromRGB(145,104,72),
    green=Color3.fromRGB(24,103,59),
    gold=Color3.fromRGB(223,177,60),
    brick=Color3.fromRGB(112,82,61),
    brickDark=Color3.fromRGB(79,59,48),
    tan=Color3.fromRGB(194,178,144),
    stone=Color3.fromRGB(174,170,158),
    glass=Color3.fromRGB(151,185,198),
    asphalt=Color3.fromRGB(64,68,72),
    metal=Color3.fromRGB(121,126,129),
}
local function color(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end

function World.part(parent,name,size,cf,tint,material,collide)
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Color=tint
    p.Anchored=true;p.Material=material or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.CanCollide=collide~=false;p.Parent=parent
    return p
end

local function sign(parent,text,cf,size,tint,textColor)
    local p=World.part(parent,"Sign",size or Vector3.new(20,4,.3),cf,tint or palette.navy,nil,false)
    local g=Instance.new("SurfaceGui")
    g.Face=Enum.NormalId.Front;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=30;g.LightInfluence=0;g.Parent=p
    local t=Instance.new("TextLabel")
    t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamBold
    t.TextColor3=textColor or palette.cream;t.TextScaled=true;t.TextWrapped=true;t.Text=text;t.Parent=g
    local pad=Instance.new("UIPadding")
    pad.PaddingLeft=UDim.new(0,10);pad.PaddingRight=UDim.new(0,10);pad.PaddingTop=UDim.new(0,6);pad.PaddingBottom=UDim.new(0,6);pad.Parent=t
    return p
end

local function crest(parent,name,cf,diameter)
    local d=diameter or 12
    local p=World.part(parent,name or "ABVM crest",Vector3.new(d,d,.35),cf,palette.navy,nil,false)
    local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=36;gui.LightInfluence=0;gui.Parent=p
    local outer=Instance.new("Frame");outer.Size=UDim2.fromScale(.94,.94);outer.Position=UDim2.fromScale(.03,.03);outer.BackgroundColor3=palette.navy;outer.BorderSizePixel=0;outer.Parent=gui
    local oc=Instance.new("UICorner");oc.CornerRadius=UDim.new(1,0);oc.Parent=outer
    local os=Instance.new("UIStroke");os.Color=palette.gold;os.Thickness=7;os.Parent=outer
    local green=Instance.new("Frame");green.Size=UDim2.fromScale(.72,.72);green.AnchorPoint=Vector2.new(.5,.5);green.Position=UDim2.fromScale(.5,.5);green.BackgroundColor3=palette.green;green.BorderSizePixel=0;green.Parent=outer
    local gc=Instance.new("UICorner");gc.CornerRadius=UDim.new(1,0);gc.Parent=green
    local gs=Instance.new("UIStroke");gs.Color=palette.gold;gs.Thickness=4;gs.Parent=green
    local center=Instance.new("Frame");center.Size=UDim2.fromScale(.9,.9);center.AnchorPoint=Vector2.new(.5,.5);center.Position=UDim2.fromScale(.5,.5);center.BackgroundColor3=Color3.fromRGB(247,246,241);center.BorderSizePixel=0;center.Parent=green
    local cc=Instance.new("UICorner");cc.CornerRadius=UDim.new(1,0);cc.Parent=center
    local a=Instance.new("TextLabel");a.BackgroundTransparency=1;a.Size=UDim2.fromScale(.7,.62);a.Position=UDim2.fromScale(.15,.23);a.Text="A";a.Font=Enum.Font.Garamond;a.TextScaled=true;a.TextColor3=palette.navy;a.Parent=center
    local cr=Instance.new("TextLabel");cr.BackgroundTransparency=1;cr.Size=UDim2.fromScale(.35,.3);cr.Position=UDim2.fromScale(.325,.06);cr.Text="✝";cr.Font=Enum.Font.GothamBold;cr.TextScaled=true;cr.TextColor3=palette.gold;cr.Parent=center
    local book=Instance.new("TextLabel");book.BackgroundTransparency=1;book.Size=UDim2.fromScale(.58,.25);book.Position=UDim2.fromScale(.21,.71);book.Text="▱  ▰";book.Font=Enum.Font.GothamBold;book.TextScaled=true;book.TextColor3=palette.navy;book.Parent=center
    local top=Instance.new("TextLabel");top.BackgroundTransparency=1;top.Size=UDim2.fromScale(.78,.16);top.Position=UDim2.fromScale(.11,.03);top.Text="ASSUMPTION BVM";top.Font=Enum.Font.GothamBold;top.TextScaled=true;top.TextColor3=palette.gold;top.Parent=outer
    local bottom=Instance.new("TextLabel");bottom.BackgroundTransparency=1;bottom.Size=UDim2.fromScale(.78,.15);bottom.Position=UDim2.fromScale(.11,.82);bottom.Text="CATHOLIC SCHOOL";bottom.Font=Enum.Font.GothamBold;bottom.TextScaled=true;bottom.TextColor3=palette.gold;bottom.Parent=outer
    return p
end

local function cross(parent,cf,scale,tint)
    local s=scale or 1
    World.part(parent,"Cross vertical",Vector3.new(1.1*s,6*s,.6*s),cf,tint or palette.gold,Enum.Material.SmoothPlastic,false)
    World.part(parent,"Cross horizontal",Vector3.new(4.2*s,1.1*s,.6*s),cf*CFrame.new(0,1.1*s,0),tint or palette.gold,Enum.Material.SmoothPlastic,false)
end

local function tree(parent,x,z,scale)
    local s=scale or 1
    World.part(parent,"Tree trunk",Vector3.new(1.6*s,7*s,1.6*s),CFrame.new(x,3.5*s,z),palette.wood,Enum.Material.Wood)
    local crown=World.part(parent,"Tree crown",Vector3.new(9*s,10*s,9*s),CFrame.new(x,10*s,z),Color3.fromRGB(72,124,72),Enum.Material.Grass,false)
    crown.Shape=Enum.PartType.Ball
end

local function windowPanel(parent,cf,width,height)
    World.part(parent,"Window stone frame",Vector3.new(width+1.2,height+1.2,.55),cf,palette.stone,Enum.Material.Concrete,false)
    local glass=World.part(parent,"Window glass",Vector3.new(width,height,.22),cf*CFrame.new(0,0,-.34),palette.glass,Enum.Material.Glass,false)
    glass.Transparency=.17
    World.part(parent,"Window mullion V",Vector3.new(.22,height,.28),cf*CFrame.new(0,0,-.5),palette.cream,nil,false)
    World.part(parent,"Window mullion H",Vector3.new(width,.22,.28),cf*CFrame.new(0,0,-.5),palette.cream,nil,false)
end

local function parkedCar(parent,x,z,rotation,tint)
    local cf=CFrame.new(x,1.05,z)*CFrame.Angles(0,rotation or 0,0)
    World.part(parent,"Parked car body",Vector3.new(6,1.4,11),cf,tint,Enum.Material.SmoothPlastic,false)
    local cabin=World.part(parent,"Parked car cabin",Vector3.new(5,1.8,5.2),cf*CFrame.new(0,1.35,-.2),Color3.fromRGB(111,143,154),Enum.Material.Glass,false)
    cabin.Transparency=.14
    for _,sx in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
        local wheel=World.part(parent,"Parked car wheel",Vector3.new(.8,1.8,1.8),cf*CFrame.new(sx*3,.05,sz*3.4),Color3.fromRGB(35,38,41),Enum.Material.SmoothPlastic,false)
        wheel.Shape=Enum.PartType.Cylinder;wheel.CFrame*=CFrame.Angles(0,0,math.pi/2)
    end end
end

local function fencePanel(parent,cf,size)
    local panel=World.part(parent,"Chain link fence",size,cf,palette.metal,Enum.Material.Metal,true)
    panel.Transparency=.58
end

local function rowHome(parent,x,z,tint,levels)
    local floors=levels or 3
    local height=10*floors
    World.part(parent,"Rowhome",Vector3.new(22,height,30),CFrame.new(x,height/2,z),tint,Enum.Material.Brick)
    World.part(parent,"Rowhome roof",Vector3.new(23,.8,31),CFrame.new(x,height+.45,z),Color3.fromRGB(55,57,58),Enum.Material.Slate)
    for floor=1,floors do
        local y=5+(floor-1)*10
        for _,dx in ipairs({-6,6}) do windowPanel(parent,CFrame.new(x+dx,y,z-15.15),5.4,5.2) end
    end
    World.part(parent,"Rowhome door",Vector3.new(5,7,.35),CFrame.new(x,3.5,z-15.3),Color3.fromRGB(69,87,98),Enum.Material.Wood,false)
end

local function desk(parent,x,y,z,tint)
    World.part(parent,"Desk top",Vector3.new(5,.45,3.2),CFrame.new(x,y+2.9,z),palette.wood,Enum.Material.Wood)
    for _,dx in ipairs({-2.1,2.1}) do World.part(parent,"Desk leg",Vector3.new(.3,2.6,.3),CFrame.new(x+dx,y+1.5,z),palette.navy) end
    World.part(parent,"Chair",Vector3.new(2.2,.35,2.1),CFrame.new(x,y+1.7,z+3.1),tint,Enum.Material.Fabric)
    World.part(parent,"Chair back",Vector3.new(2.2,2.4,.3),CFrame.new(x,y+2.6,z+4),tint,Enum.Material.Fabric)
end

local function npc(parent,name,position,suit,tint)
    local model=Instance.new("Model");model.Name=name;model.Parent=parent
    local skin=Color3.fromRGB(226,196,164)
    local torsoColor=suit and Color3.fromRGB(31,43,60) or (tint or Color3.fromRGB(80,112,145))
    World.part(model,"Torso",Vector3.new(3.2,4.2,1.8),CFrame.new(position+Vector3.new(0,4.5,0)),torsoColor,Enum.Material.Fabric,false)
    World.part(model,"Left leg",Vector3.new(1.2,3.5,1.2),CFrame.new(position+Vector3.new(-.8,1.4,0)),Color3.fromRGB(48,54,65),Enum.Material.Fabric,false)
    World.part(model,"Right leg",Vector3.new(1.2,3.5,1.2),CFrame.new(position+Vector3.new(.8,1.4,0)),Color3.fromRGB(48,54,65),Enum.Material.Fabric,false)
    World.part(model,"Left arm",Vector3.new(.9,3.7,.9),CFrame.new(position+Vector3.new(-2.05,4.4,0)),skin,Enum.Material.SmoothPlastic,false)
    World.part(model,"Right arm",Vector3.new(.9,3.7,.9),CFrame.new(position+Vector3.new(2.05,4.4,0)),skin,Enum.Material.SmoothPlastic,false)
    local head=World.part(model,"Head",Vector3.new(2.35,2.35,2.35),CFrame.new(position+Vector3.new(0,7.8,0)),skin,Enum.Material.SmoothPlastic,false)
    head.Shape=Enum.PartType.Ball
    if suit then
        World.part(model,"Suit shirt",Vector3.new(1.35,2.2,.18),CFrame.new(position+Vector3.new(0,5,-1)),Color3.fromRGB(245,245,242),nil,false)
        World.part(model,"Suit tie",Vector3.new(.35,2,.2),CFrame.new(position+Vector3.new(0,4.9,-1.12)),palette.gold,nil,false)
    end
    local gui=Instance.new("BillboardGui");gui.Name="Name";gui.AlwaysOnTop=true;gui.Size=UDim2.fromOffset(190,44);gui.StudsOffset=Vector3.new(0,2.1,0);gui.Parent=head
    local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=palette.navy;label.BackgroundTransparency=.08
    label.TextColor3=palette.cream;label.Font=Enum.Font.GothamBold;label.TextSize=14;label.Text=name;label.Parent=gui
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,9);corner.Parent=label
    return model
end

local function classroom(root,id,title,teacher,x,floorY,tint,active)
    local m=Instance.new("Model");m.Name=id.."_classroom";m.Parent=root
    local roomWidth=49;local roomDepth=58;local z=-109
    local hallX=x<0 and -23.5 or 23.5
    local outerX=x<0 and -74.5 or 74.5
    World.part(m,"Floor",Vector3.new(roomWidth,.45,roomDepth),CFrame.new(x,floorY+.25,z),Color3.fromRGB(210,199,176),Enum.Material.WoodPlanks)
    World.part(m,"Outer wall",Vector3.new(1,14,roomDepth),CFrame.new(outerX,floorY+7,z),palette.cream)
    World.part(m,"Back wall",Vector3.new(roomWidth,14,1),CFrame.new(x,floorY+7,z-roomDepth/2),palette.cream)
    World.part(m,"Front wall",Vector3.new(roomWidth,14,1),CFrame.new(x,floorY+7,z+roomDepth/2),palette.cream)
    -- Hall wall leaves a generous, camera-safe doorway centered on the room.
    World.part(m,"Hall wall north",Vector3.new(1,14,23),CFrame.new(hallX,floorY+7,z-17.5),palette.cream)
    World.part(m,"Hall wall south",Vector3.new(1,14,23),CFrame.new(hallX,floorY+7,z+17.5),palette.cream)
    World.part(m,"Door lintel",Vector3.new(1,4,12),CFrame.new(hallX,floorY+12,z),palette.cream)
    local boardCf=CFrame.new(x,floorY+8,z-roomDepth/2+.65)*CFrame.Angles(0,math.pi,0)
    sign(m,"ASSUMPTION BVM\n"..title.." — "..teacher,boardCf,Vector3.new(30,6,.25),tint,palette.cream)
    cross(m,CFrame.new(x+14,floorY+10,z-roomDepth/2+.45),.45,palette.gold)
    for _,dx in ipairs({-11,0,11}) do
        for _,dz in ipairs({-13,3,19}) do desk(m,x+dx,floorY,z+dz,tint) end
    end
    local teacherX=x+(x<0 and 13 or -13)
    npc(m,teacher,Vector3.new(teacherX,floorY,z-21),false,tint)
    local hallLabelCf=CFrame.new(hallX+(x<0 and .65 or -.65),floorY+9,z)*CFrame.Angles(0,x<0 and -math.pi/2 or math.pi/2,0)
    sign(m,title.."\n"..teacher,hallLabelCf,Vector3.new(14,4,.25),tint,palette.cream)
    if active then World.rooms[id]={x=x,z=z,hx=23,hz=27,minY=floorY,maxY=floorY+14} end
end

local function makeFrontArch(root,x)
    local z=-34.2
    local radius=5.25
    local springY=18
    -- Rectangular voussoirs approximate the real stone arch without a giant spherical cap.
    for i=0,10 do
        local theta=math.pi*i/10
        local px=x+math.cos(theta)*radius
        local py=springY+math.sin(theta)*radius
        World.part(root,"Arch stone segment",Vector3.new(3.1,1.25,1.35),
            CFrame.new(px,py,z)*CFrame.Angles(0,0,theta+math.pi/2),
            palette.stone,Enum.Material.Concrete,false)
    end
    World.part(root,"Arch left pier",Vector3.new(1.25,16.5,1.35),CFrame.new(x-radius,11.8,z),palette.stone,Enum.Material.Concrete)
    World.part(root,"Arch right pier",Vector3.new(1.25,16.5,1.35),CFrame.new(x+radius,11.8,z),palette.stone,Enum.Material.Concrete)
    local upperGlass=World.part(root,"Arched upper glazing",Vector3.new(9.1,5,.3),CFrame.new(x,19.2,z-.55),palette.glass,Enum.Material.Glass,false)
    upperGlass.Transparency=.12
    local lower=World.part(root,"Tall arched glazing",Vector3.new(9.1,10.2,.32),CFrame.new(x,12.2,z-.56),palette.glass,Enum.Material.Glass,false)
    lower.Transparency=.12
    -- Diamond-ish upper mullions plus rectangular lower mullions echo the reference window rhythm.
    for _,offset in ipairs({-2.8,0,2.8}) do
        World.part(root,"Arch vertical mullion",Vector3.new(.16,13,.18),CFrame.new(x+offset,14.8,z-.78),palette.cream,nil,false)
    end
    for _,y in ipairs({10.5,14,17.5}) do
        World.part(root,"Arch horizontal mullion",Vector3.new(9,.16,.18),CFrame.new(x,y,z-.78),palette.cream,nil,false)
    end
    World.part(root,"Entry double doors",Vector3.new(8.6,7.1,.3),CFrame.new(x,7.55,z-.72),Color3.fromRGB(218,214,198),Enum.Material.Metal,false)
    World.part(root,"Door split",Vector3.new(.18,7,.36),CFrame.new(x,7.55,z-.9),palette.stone,nil,false)
    for _,dx in ipairs({-2.25,2.25}) do
        World.part(root,"Door window",Vector3.new(1.25,2.5,.1),CFrame.new(x+dx,8.2,z-.94),Color3.fromRGB(73,95,105),Enum.Material.Glass,false)
    end
end

local function stairFlight(root,x,zStart,zEnd,yStart,yEnd)
    local steps=22
    for i=0,steps-1 do
        local t=i/(steps-1)
        local z=zStart+(zEnd-zStart)*t
        local y=yStart+(yEnd-yStart)*t
        World.part(root,"Interior stair",Vector3.new(11,.72,2.25),CFrame.new(x,y,z),palette.stone,Enum.Material.Concrete)
    end
end

function World.build()
    local old=Workspace:FindFirstChild("NeighborhoodWorld");if old then old:Destroy() end
    local root=Instance.new("Folder");root.Name="NeighborhoodWorld";root.Parent=Workspace;World.root=root
    World.rooms={};World.leaderboardParts={}

    -- Base neighborhood and school block.
    World.part(root,"Ground",Vector3.new(520,2,1450),CFrame.new(0,-1,480),Color3.fromRGB(118,153,106),Enum.Material.Grass)
    World.part(root,"School block",Vector3.new(195,1.2,150),CFrame.new(0,.1,-91),Color3.fromRGB(128,128,118),Enum.Material.Concrete)
    World.part(root,"Main street",Vector3.new(28,.12,1110),CFrame.new(0,.04,580),palette.asphalt,Enum.Material.Asphalt)
    World.part(root,"School frontage road",Vector3.new(240,.12,23),CFrame.new(0,.05,35),palette.asphalt,Enum.Material.Asphalt)
    for _,x in ipairs({-21,21}) do World.part(root,"Neighborhood sidewalk",Vector3.new(12,.3,1110),CFrame.new(x,.15,580),palette.cream,Enum.Material.Concrete) end
    for z=70,1090,28 do World.part(root,"Road marking",Vector3.new(.4,.03,9),CFrame.new(0,.12,z),Color3.fromRGB(236,221,156),nil,false) end

    -- Howard Avenue is intentionally tight and steep-looking: stepped grade, retaining walls and dense neighbors.
    for i=0,5 do
        World.part(root,"Howard Avenue",Vector3.new(27,.22,32),CFrame.new(173,.1+i*.42,-166+i*30),palette.asphalt,Enum.Material.Asphalt)
    end
    World.part(root,"Howard retaining wall",Vector3.new(4,14,170),CFrame.new(151,6,-88),palette.brickDark,Enum.Material.Brick)
    World.part(root,"West retaining wall",Vector3.new(5,10,145),CFrame.new(-108,4,-92),palette.brickDark,Enum.Material.Brick)

    -- Real-school-inspired exterior massing: tall, rectangular, flat-roofed, brown brick with tan infill.
    World.part(root,"School main floor",Vector3.new(150,.7,110),CFrame.new(0,4,-90),Color3.fromRGB(190,184,166),Enum.Material.Concrete)
    World.part(root,"Second floor slab",Vector3.new(148,.65,108),CFrame.new(0,20,-90),Color3.fromRGB(170,166,153),Enum.Material.Concrete)
    World.part(root,"Third floor slab",Vector3.new(148,.65,108),CFrame.new(0,36,-90),Color3.fromRGB(170,166,153),Enum.Material.Concrete)
    World.part(root,"Flat black roof",Vector3.new(154,1,114),CFrame.new(0,52.5,-90),Color3.fromRGB(45,47,48),Enum.Material.Slate)
    World.part(root,"Roof parapet front",Vector3.new(154,2.5,1.2),CFrame.new(0,53.5,-34.5),palette.brick,Enum.Material.Brick)
    World.part(root,"Roof parapet back",Vector3.new(154,2.5,1.2),CFrame.new(0,53.5,-145.5),palette.brick,Enum.Material.Brick)
    -- Reference-visible roofline rhythm, chimney stack and simple roof vents.
    for _,x in ipairs({-66,-44,-22,0,22,44,66}) do
        World.part(root,"Front parapet cap",Vector3.new(4.2,2.2,2.3),CFrame.new(x,55,-34.7),palette.stone,Enum.Material.Concrete,false)
    end
    World.part(root,"Brick chimney",Vector3.new(11,20,11),CFrame.new(62,62,-57),palette.brickDark,Enum.Material.Brick)
    World.part(root,"Chimney cap",Vector3.new(12.5,1.4,12.5),CFrame.new(62,72.4,-57),palette.stone,Enum.Material.Concrete)
    for _,entry in ipairs({{-45,-77},{-18,-114},{18,-69},{43,-118}}) do
        World.part(root,"Roof vent base",Vector3.new(5,.8,5),CFrame.new(entry[1],53.4,entry[2]),Color3.fromRGB(91,94,94),Enum.Material.Metal,false)
        World.part(root,"Roof vent",Vector3.new(2.2,3,2.2),CFrame.new(entry[1],55,entry[2]),Color3.fromRGB(132,136,136),Enum.Material.Metal,false)
    end

    -- Exterior side/back walls. East wall keeps a usable Howard Avenue doorway.
    World.part(root,"West brick wall",Vector3.new(1.4,48,110),CFrame.new(-75,28,-90),palette.brick,Enum.Material.Brick)
    World.part(root,"East brick wall back",Vector3.new(1.4,48,44),CFrame.new(75,28,-123),palette.brick,Enum.Material.Brick)
    World.part(root,"East brick wall front",Vector3.new(1.4,48,50),CFrame.new(75,28,-60),palette.brick,Enum.Material.Brick)
    World.part(root,"East entry header",Vector3.new(1.4,31,16),CFrame.new(75,36.5,-93),palette.brick,Enum.Material.Brick)
    World.part(root,"Back brick wall",Vector3.new(150,48,1.4),CFrame.new(0,28,-145),palette.brick,Enum.Material.Brick)
    World.part(root,"Exposed lower masonry",Vector3.new(150,6,1.5),CFrame.new(0,1,-145.2),palette.brickDark,Enum.Material.Brick)

    -- Formal front facade: heavy upper block with tan bays, brick pilasters and three arched entrance bays.
    World.part(root,"Front upper brick mass",Vector3.new(150,31,1.4),CFrame.new(0,37,-35),palette.brick,Enum.Material.Brick)
    World.part(root,"Front lower west",Vector3.new(55,17,1.4),CFrame.new(-47.5,12,-35),palette.brick,Enum.Material.Brick)
    World.part(root,"Front lower east",Vector3.new(55,17,1.4),CFrame.new(47.5,12,-35),palette.brick,Enum.Material.Brick)
    for _,x in ipairs({-68,-51,-34,-17,0,17,34,51,68}) do
        World.part(root,"Front brick pilaster",Vector3.new(2.3,48,2),CFrame.new(x,28,-34.2),palette.brickDark,Enum.Material.Brick)
    end
    for _,floorY in ipairs({29,44}) do
        for _,x in ipairs({-59.5,-42.5,-25.5,25.5,42.5,59.5}) do
            World.part(root,"Tan facade bay",Vector3.new(13.5,11,.55),CFrame.new(x,floorY,-34.1),palette.tan,Enum.Material.Concrete,false)
            windowPanel(root,CFrame.new(x,floorY,-33.7),8.5,5.8)
        end
    end
    for _,x in ipairs({-18,0,18}) do makeFrontArch(root,x) end
    sign(root,"ASSUMPTION BVM\nCATHOLIC SCHOOL",CFrame.new(0,27,-33.4)*CFrame.Angles(0,math.pi,0),Vector3.new(39,6,.35),palette.navy,palette.gold)
    crest(root,"Front ABVM crest",CFrame.new(0,38,-33.25)*CFrame.Angles(0,math.pi,0),10)
    cross(root,CFrame.new(0,49.2,-33.4),.72,palette.gold)
    sign(root,"1928",CFrame.new(-9,21.6,-33.15)*CFrame.Angles(0,math.pi,0),Vector3.new(5,2,.25),palette.stone,palette.brickDark)

    -- Repeating side windows and strong vertical brick rhythm visible in the reference photos.
    for _,side in ipairs({-1,1}) do
        local wallX=side*75.65
        local yaw=side<0 and -math.pi/2 or math.pi/2
        for _,floorY in ipairs({12,28,44}) do
            for _,z in ipairs({-132,-115,-77,-60}) do
                windowPanel(root,CFrame.new(wallX,floorY,z)*CFrame.Angles(0,yaw,0),8,5.4)
            end
        end
        for _,z in ipairs({-139,-122,-105,-71,-54,-37}) do
            World.part(root,"Side brick pilaster",Vector3.new(2,48,2.2),CFrame.new(side*74.9,28,z),palette.brickDark,Enum.Material.Brick)
        end
    end

    -- Broad formal stairs and landing, intentionally generous for mobile camera/movement.
    for i=0,7 do
        World.part(root,"Front broad stair",Vector3.new(57,.65,3.2),CFrame.new(0,.35+i*.52,-7-i*3.25),palette.stone,Enum.Material.Concrete)
    end
    World.part(root,"Front landing",Vector3.new(59,.7,8),CFrame.new(0,4.3,-31),palette.stone,Enum.Material.Concrete)
    -- Low masonry cheeks and center rails reproduce the formal stair approach without narrowing the playable lane.
    World.part(root,"Front stair west cheek",Vector3.new(3,5.2,30),CFrame.new(-31,2.55,-18.5),palette.brickDark,Enum.Material.Brick)
    World.part(root,"Front stair east cheek",Vector3.new(3,5.2,30),CFrame.new(31,2.55,-18.5),palette.brickDark,Enum.Material.Brick)
    for _,x in ipairs({-9,9}) do
        for step=0,4 do
            World.part(root,"Front stair rail post",Vector3.new(.28,3,.28),CFrame.new(x,1.6+step*.75,-8-step*5.2),palette.metal,Enum.Material.Metal,false)
        end
    end
    -- White low front additions flank the arched section in the real facade.
    World.part(root,"Front west low annex",Vector3.new(41,8,13),CFrame.new(-55,7,-27),Color3.fromRGB(215,218,207),Enum.Material.SmoothPlastic)
    World.part(root,"Front east low annex",Vector3.new(41,8,13),CFrame.new(55,7,-27),Color3.fromRGB(215,218,207),Enum.Material.SmoothPlastic)
    World.part(root,"School approach",Vector3.new(28,.3,40),CFrame.new(0,.2,13),Color3.fromRGB(204,198,184),Enum.Material.Cobblestone)

    -- Howard Avenue side entrance, cross, walk and green/gold roadside sign.
    World.part(root,"Howard entry landing",Vector3.new(14,.6,17),CFrame.new(82,4.2,-93),palette.stone,Enum.Material.Concrete)
    World.part(root,"Howard double doors",Vector3.new(.35,8,10),CFrame.new(75.45,8,-93),Color3.fromRGB(93,111,121),Enum.Material.Metal,false)
    World.part(root,"Howard arch left",Vector3.new(.7,12,1.2),CFrame.new(75.6,10,-99),palette.stone,Enum.Material.Concrete,false)
    World.part(root,"Howard arch right",Vector3.new(.7,12,1.2),CFrame.new(75.6,10,-87),palette.stone,Enum.Material.Concrete,false)
    local sideArch=World.part(root,"Howard arch crown",Vector3.new(.8,12,5),CFrame.new(75.6,16,-93),palette.stone,Enum.Material.Concrete,false)
    sideArch.Shape=Enum.PartType.Ball
    cross(root,CFrame.new(75.25,20,-93)*CFrame.Angles(0,math.pi/2,0),.55,palette.gold)
    World.part(root,"Howard walkway",Vector3.new(21,.35,17),CFrame.new(93,.25,-93),palette.stone,Enum.Material.Concrete)
    local roadSign=sign(root,"✝\nASSUMPTION\nBVM SCHOOL\n────────\nENTRANCE ON HOWARD AVENUE",CFrame.new(107,7,-78)*CFrame.Angles(0,-math.pi/2,0),Vector3.new(15,10,.45),palette.green,palette.gold)
    roadSign.Name="Assumption BVM Howard Avenue sign"

    -- Parking lot and simple perimeter fencing.
    World.part(root,"School parking lot",Vector3.new(67,.22,111),CFrame.new(116,.12,-100),Color3.fromRGB(78,78,75),Enum.Material.Asphalt)
    for z=-137,-62,15 do
        for x=91,139,12 do World.part(root,"Parking stripe",Vector3.new(.18,.04,10),CFrame.new(x,.25,z),Color3.fromRGB(225,220,198),nil,false) end
    end
    fencePanel(root,CFrame.new(149,4,-100),Vector3.new(.45,8,112))
    fencePanel(root,CFrame.new(116,4,-155),Vector3.new(67,8,.45))
    fencePanel(root,CFrame.new(116,4,-45),Vector3.new(67,8,.45))
    for _,entry in ipairs({
        {97,-137,0,Color3.fromRGB(221,222,218)},
        {113,-137,0,Color3.fromRGB(55,66,77)},
        {129,-137,0,Color3.fromRGB(165,177,183)},
        {97,-63,math.pi,Color3.fromRGB(61,83,109)},
        {113,-63,math.pi,Color3.fromRGB(210,208,197)},
        {129,-63,math.pi,Color3.fromRGB(87,91,94)},
    }) do parkedCar(root,entry[1],entry[2],entry[3],entry[4]) end

    -- Dense urban Pottsville context. These are backdrop buildings, not owned player homes.
    local rowColors={Color3.fromRGB(145,104,83),Color3.fromRGB(173,153,131),Color3.fromRGB(119,91,78),Color3.fromRGB(188,179,160)}
    for i,z in ipairs({-145,-92,-39}) do
        rowHome(root,-142,z,rowColors[(i-1)%#rowColors+1],3)
        rowHome(root,205,z,rowColors[i%#rowColors+1],3)
    end
    rowHome(root,-169,-118,rowColors[3],3);rowHome(root,-169,-63,rowColors[2],2)
    tree(root,-101,-28,.85);tree(root,-102,-145,.95);tree(root,88,-34,.7)

    -- Playable interior floors/halls. Exterior stays faithful; interior is wider/clearer than the real plan.
    for _,floorY in ipairs({4,20,36}) do
        World.part(root,"Central hall floor",Vector3.new(30,.4,104),CFrame.new(0,floorY+.25,-90),Color3.fromRGB(177,151,118),Enum.Material.WoodPlanks)
        World.part(root,"Hall left rail",Vector3.new(.4,2.3,92),CFrame.new(-14.5,floorY+2,-96),palette.stone,Enum.Material.Metal,false)
        World.part(root,"Hall right rail",Vector3.new(.4,2.3,92),CFrame.new(14.5,floorY+2,-96),palette.stone,Enum.Material.Metal,false)
    end

    local active={}
    for _,subject in ipairs(Catalog.Subjects) do active[subject.id]=subject end
    classroom(root,"math","Math","Mrs. Campion",-49,4,color((active.math and active.math.color) or {62,154,214}),active.math~=nil)
    classroom(root,"reading","Reading","Mrs. Russek",49,4,color((active.reading and active.reading.color) or {125,103,202}),active.reading~=nil)
    classroom(root,"grammar","Grammar","Mrs. Benulis",-49,20,color((active.grammar and active.grammar.color) or {137,105,170}),active.grammar~=nil)
    classroom(root,"religion","Religion","Mr. Bolich",49,20,color((active.religion and active.religion.color) or {196,147,58}),active.religion~=nil)
    classroom(root,"vocabulary","Vocabulary","Mr. Yordy",-49,36,color((active.vocabulary and active.vocabulary.color) or {58,135,118}),active.vocabulary~=nil)
    classroom(root,"spelling","Spelling","Mrs. Kochol",49,36,color((active.spelling and active.spelling.color) or {51,158,129}),active.spelling~=nil)

    -- Stairs connect all three playable academic floors.
    stairFlight(root,-7,-58,-101,5,19.4)
    World.part(root,"Second floor stair landing",Vector3.new(13,.6,9),CFrame.new(-7,20,-105),palette.stone,Enum.Material.Concrete)
    stairFlight(root,7,-118,-75,21,35.4)
    World.part(root,"Third floor stair landing",Vector3.new(13,.6,9),CFrame.new(7,36,-71),palette.stone,Enum.Material.Concrete)

    -- Main lobby/admin suite.
    sign(root,"ASSUMPTION BVM CATHOLIC SCHOOL\nFaith • Education • Community",CFrame.new(0,12,-39)*CFrame.Angles(0,math.pi,0),Vector3.new(42,7,.25),palette.navy,palette.gold)
    crest(root,"Lobby ABVM crest",CFrame.new(0,18,-39)*CFrame.Angles(0,math.pi,0),7)
    -- A compact but real admin suite rather than labels floating in the lobby.
    World.part(root,"Main Office rear wall",Vector3.new(51,11,1),CFrame.new(-49,9.5,-72),palette.cream)
    World.part(root,"Main Office west wall",Vector3.new(1,11,27),CFrame.new(-74,9.5,-58.5),palette.cream)
    World.part(root,"Principal partition",Vector3.new(1,11,18),CFrame.new(-45,9.5,-63),palette.cream)
    World.part(root,"Assistant partition",Vector3.new(1,11,18),CFrame.new(-29,9.5,-63),palette.cream)
    -- Keep broad openings on the lobby side for mobile traversal.
    World.part(root,"Main Office counter",Vector3.new(27,3.5,4),CFrame.new(-59,6,-48),palette.wood,Enum.Material.Wood)
    World.part(root,"Office waiting bench",Vector3.new(10,1.1,2.6),CFrame.new(-28,5,-49),Color3.fromRGB(103,117,130),Enum.Material.Fabric)
    World.part(root,"Principal desk",Vector3.new(10,2.2,4),CFrame.new(-37,5.3,-65),palette.wood,Enum.Material.Wood)
    World.part(root,"Assistant desk",Vector3.new(10,2.2,4),CFrame.new(-21,5.3,-65),palette.wood,Enum.Material.Wood)
    sign(root,"MAIN OFFICE",CFrame.new(-59,10,-45.8)*CFrame.Angles(0,math.pi,0),Vector3.new(20,3,.2),palette.green,palette.gold)
    sign(root,"Secretary — Mrs. Thompson",CFrame.new(-59,8.6,-53)*CFrame.Angles(0,math.pi,0),Vector3.new(19,2.5,.2),palette.navy,palette.cream)
    sign(root,"Principal — Dr. McBreen",CFrame.new(-37,9,-72.55)*CFrame.Angles(0,0,0),Vector3.new(16,2.6,.2),palette.navy,palette.cream)
    sign(root,"Assistant Principal — Mrs. Boyer",CFrame.new(-21,9,-72.55)*CFrame.Angles(0,0,0),Vector3.new(18,2.6,.2),palette.navy,palette.cream)
    cross(root,CFrame.new(-37,13,-71.5),.35,palette.gold)
    cross(root,CFrame.new(-21,13,-71.5),.35,palette.gold)
    npc(root,"Mrs. Thompson — Secretary",Vector3.new(-59,4,-52),false,Color3.fromRGB(86,125,143))
    npc(root,"Dr. McBreen — Principal",Vector3.new(-37,4,-61),true,palette.navy)
    npc(root,"Mrs. Boyer — Assistant Principal",Vector3.new(-21,4,-61),false,Color3.fromRGB(89,111,132))

    -- Three ABVM-branded leaderboard boards on the lobby's east wall.
    World.leaderboardParts={
        accuracy=World.part(root,"Accuracy leaderboard",Vector3.new(21,8,.45),CFrame.new(68.8,9,-47)*CFrame.Angles(0,-math.pi/2,0),palette.navy,nil,false),
        questions=World.part(root,"Questions leaderboard",Vector3.new(21,8,.45),CFrame.new(68.8,9,-58)*CFrame.Angles(0,-math.pi/2,0),palette.navy,nil,false),
        credits=World.part(root,"Money leaderboard",Vector3.new(21,8,.45),CFrame.new(68.8,9,-69)*CFrame.Angles(0,-math.pi/2,0),palette.navy,nil,false),
    }
    sign(root,"ASSUMPTION BVM\nLEADERBOARDS",CFrame.new(68.5,15.2,-58)*CFrame.Angles(0,-math.pi/2,0),Vector3.new(31,4,.3),palette.green,palette.gold)

    -- School shop remains one of the few non-class destinations and stays inside the school.
    World.shopPosition=Vector3.new(31,5,-49)
    World.part(root,"ABVM Shop counter",Vector3.new(28,3.5,4),CFrame.new(31,6,-48),palette.wood,Enum.Material.Wood)
    local sp=sign(root,"ABVM SCHOOL SHOP",CFrame.new(31,10,-45.8)*CFrame.Angles(0,math.pi,0),Vector3.new(25,3,.2),palette.green,palette.gold)
    local prompt=Instance.new("ProximityPrompt");prompt.ActionText="Browse";prompt.ObjectText="ABVM School Shop";prompt.MaxActivationDistance=16;prompt.RequiresLineOfSight=false;prompt.HoldDuration=0;prompt.Parent=sp
    World.shopPrompt=prompt

    -- Player-owned neighborhood lots continue south of the school.
    for i=1,24 do
        local side=i%2==1 and -1 or 1
        local row=math.ceil(i/2)
        local x,z=side*72,72+(row-1)*90
        local cf=CFrame.new(x,0,z)*CFrame.Angles(0,side<0 and math.pi/2 or -math.pi/2,0)
        World.plots[i]={cf=cf,door=cf*CFrame.new(0,4,25),drive=CFrame.new(side*8,1.65,z+27),owner=nil}
        World.part(root,"Residential lot "..i,Vector3.new(79,.25,76),CFrame.new(x,.13,z),Color3.fromRGB(141,171,127),Enum.Material.Grass)
        tree(root,side*119,z-20,.85)
    end

    local spawn=Instance.new("SpawnLocation")
    spawn.Name="SchoolArrival";spawn.Size=Vector3.new(8,1,8);spawn.CFrame=CFrame.new(0,1,-1);spawn.Transparency=1;spawn.CanCollide=false;spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=root
    World.schoolDoor=CFrame.new(0,3,-5)*CFrame.Angles(0,math.pi,0)
    return World
end

function World.subjectAt(position)
    for id,r in pairs(World.rooms) do
        if position.Y>=r.minY and position.Y<=r.maxY and math.abs(position.X-r.x)<=r.hx and math.abs(position.Z-r.z)<=r.hz then
            return id
        end
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
    if stage>=5 then
        -- Estate tier adds a visibly grander entrance and side wings without changing ownership logic.
        p("Estate left wing",Vector3.new(10,9,depth-8),Vector3.new(-width/2+4,5.2,-1),color(item.color))
        p("Estate right wing",Vector3.new(10,9,depth-8),Vector3.new(width/2-4,5.2,-1),color(item.color))
        p("Estate entry canopy",Vector3.new(15,.8,7),Vector3.new(0,10.5,depth/2+4),palette.cream,Enum.Material.Concrete)
        for _,x in ipairs({-6,6}) do
            p("Estate entry column",Vector3.new(1.1,10,1.1),Vector3.new(x,5.5,depth/2+5),palette.cream,Enum.Material.Concrete)
        end
        p("Estate double door",Vector3.new(8,8,.4),Vector3.new(0,4.7,depth/2+.7),palette.navy,Enum.Material.Wood,false)
        for _,x in ipairs({-width/2+8,width/2-8}) do
            p("Estate hedge",Vector3.new(10,3,4),Vector3.new(x,1.8,depth/2+10),Color3.fromRGB(76,120,74),Enum.Material.Grass,false)
        end
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
