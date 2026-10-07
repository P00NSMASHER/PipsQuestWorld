--!strict
-- Assumption BVM-inspired school + residential neighborhood.
-- Exterior proportions and identity follow the user-authorized Pottsville references;
-- interior dimensions are deliberately widened/simplified for readable mobile play.
local Workspace=game:GetService("Workspace")
local Lighting=game:GetService("Lighting")
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

local function tree(parent,x,z,scale,baseY)
    local s=scale or 1
    local y0=baseY or 0
    -- Deliberately chunky canopy: the approved visual target reads as polished Roblox,
    -- not a photoreal mesh import. Five low-cost leaf blocks keep that silhouette.
    World.part(parent,"Tree trunk",Vector3.new(1.7*s,7.2*s,1.7*s),CFrame.new(x,y0+3.6*s,z),palette.wood,Enum.Material.Wood)
    local chunks={
        {0,10.1,0,6.8,Color3.fromRGB(69,126,70)},
        {-2.9,9.3,.4,5.4,Color3.fromRGB(79,137,76)},
        {2.8,9.4,-.3,5.2,Color3.fromRGB(62,116,64)},
        {-.8,12.6,-1.2,5.3,Color3.fromRGB(83,143,79)},
        {1.1,11.7,2.2,4.8,Color3.fromRGB(73,131,70)},
    }
    for _,c in ipairs(chunks) do
        local leaf=World.part(parent,"Tree canopy chunk",
            Vector3.new(c[4]*s,c[4]*.82*s,c[4]*s),
            CFrame.new(x+c[1]*s,y0+c[2]*s,z+c[3]*s),
            c[5],Enum.Material.Grass,false)
        leaf.CanQuery=false;leaf.CanTouch=false
    end
end

local function shrub(parent,x,z,scale)
    local s=scale or 1
    local bush=World.part(parent,"School shrub",Vector3.new(5*s,3.4*s,4.4*s),CFrame.new(x,1.7*s,z),Color3.fromRGB(55,116,62),Enum.Material.Grass,false)
    bush.Shape=Enum.PartType.Ball
    return bush
end

local function planter(parent,x,z,width)
    local w=width or 10
    World.part(parent,"Stone planter",Vector3.new(w,1.4,4.2),CFrame.new(x,.75,z),Color3.fromRGB(169,164,151),Enum.Material.Concrete)
    World.part(parent,"Planter soil",Vector3.new(w-.8,.35,3.4),CFrame.new(x,1.48,z),Color3.fromRGB(82,62,46),Enum.Material.Ground,false)
    local flowerColors={
        Color3.fromRGB(224,85,108),
        Color3.fromRGB(245,190,72),
        Color3.fromRGB(240,236,228),
        Color3.fromRGB(133,93,178),
    }
    local count=math.max(4,math.floor(w/1.7))
    for i=1,count do
        local offset=(i-(count+1)/2)*(w-1.6)/math.max(1,count-1)
        local stem=World.part(parent,"Flower stem",Vector3.new(.16,.95,.16),CFrame.new(x+offset,2.05,z),Color3.fromRGB(62,118,63),Enum.Material.Grass,false)
        stem.CanQuery=false;stem.CanTouch=false
        local bloom=World.part(parent,"Flower bloom",Vector3.new(.62,.62,.62),CFrame.new(x+offset,2.55,z),flowerColors[(i-1)%#flowerColors+1],Enum.Material.SmoothPlastic,false)
        bloom.Shape=Enum.PartType.Ball;bloom.CanQuery=false;bloom.CanTouch=false
    end
end

local function windowPanel(parent,cf,width,height)
    World.part(parent,"Window stone frame",Vector3.new(width+1.2,height+1.2,.55),cf,palette.stone,Enum.Material.Concrete,false)
    local glass=World.part(parent,"Window glass",Vector3.new(width,height,.22),cf*CFrame.new(0,0,-.34),palette.glass,Enum.Material.Glass,false)
    glass.Transparency=.17
    World.part(parent,"Window mullion V",Vector3.new(.22,height,.28),cf*CFrame.new(0,0,-.5),palette.cream,nil,false)
    World.part(parent,"Window mullion H",Vector3.new(width,.22,.28),cf*CFrame.new(0,0,-.5),palette.cream,nil,false)
end

local function schoolWindowPanel(parent,cf,width,height)
    -- Layered frame + inset glass + soft warm backing gives the same readable window depth
    -- as the approved Roblox render without textures or expensive mesh windows.
    World.part(parent,"School window stone frame",Vector3.new(width+1.15,height+1.15,.58),cf,palette.stone,Enum.Material.Concrete,false)
    local glass=World.part(parent,"School window glass",Vector3.new(width,height,.22),cf*CFrame.new(0,0,-.34),palette.glass,Enum.Material.Glass,false)
    glass.Transparency=.13
    local warm=World.part(parent,"School window warm glow",Vector3.new(width-.45,height-.45,.08),
        cf*CFrame.new(0,0,-.57),Color3.fromRGB(255,229,176),Enum.Material.Neon,false)
    warm.Transparency=.72;warm.CanQuery=false;warm.CanTouch=false
    for _,fraction in ipairs({-.3,0,.3}) do
        World.part(parent,"School window mullion V",Vector3.new(.17,height,.28),cf*CFrame.new(width*fraction,0,-.5),palette.cream,nil,false)
    end
    World.part(parent,"School window mullion H",Vector3.new(width,.18,.28),cf*CFrame.new(0,0,-.5),palette.cream,nil,false)
    World.part(parent,"School window sash",Vector3.new(width,.13,.3),cf*CFrame.new(0,-height*.28,-.52),palette.cream,nil,false)
    World.part(parent,"School window sill",Vector3.new(width+1.45,.32,.8),cf*CFrame.new(0,-height/2-.62,-.08),palette.stone,Enum.Material.Concrete,false)
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

local function cable(parent,a,b,thickness)
    local delta=b-a
    local length=delta.Magnitude
    if length<.1 then return nil end
    local p=World.part(parent,"Utility cable",Vector3.new(thickness or .18,thickness or .18,length),
        CFrame.lookAt((a+b)/2,b),Color3.fromRGB(42,43,43),Enum.Material.SmoothPlastic,false)
    p.CanQuery=false;p.CanTouch=false
    return p
end

local function utilityPole(parent,x,z,height)
    local h=height or 31
    World.part(parent,"Utility pole",Vector3.new(1.1,h,1.1),CFrame.new(x,h/2,z),Color3.fromRGB(91,70,52),Enum.Material.Wood)
    World.part(parent,"Utility crossarm",Vector3.new(10,.65,.65),CFrame.new(x,h-4,z),Color3.fromRGB(91,70,52),Enum.Material.Wood,false)
    for _,dx in ipairs({-4,0,4}) do
        local ins=World.part(parent,"Utility insulator",Vector3.new(.5,.8,.5),CFrame.new(x+dx,h-3.3,z),Color3.fromRGB(185,183,171),Enum.Material.SmoothPlastic,false)
        ins.Shape=Enum.PartType.Cylinder
    end
    return Vector3.new(x,h-2.8,z)
end

local function distantWaterTower(parent,x,z)
    local baseY=22
    for _,dx in ipairs({-4,4}) do
        for _,dz in ipairs({-4,4}) do
            World.part(parent,"Distant water tower leg",Vector3.new(.55,24,.55),CFrame.new(x+dx,baseY+12,z+dz),palette.metal,Enum.Material.Metal,false)
        end
    end
    local tank=World.part(parent,"Distant water tower tank",Vector3.new(14,8,14),CFrame.new(x,baseY+27,z),Color3.fromRGB(168,177,181),Enum.Material.Metal,false)
    tank.Shape=Enum.PartType.Cylinder;tank.CFrame*=CFrame.Angles(0,0,math.pi/2)
    local cap=World.part(parent,"Distant water tower cap",Vector3.new(14.8,1.2,14.8),CFrame.new(x,baseY+31,z),Color3.fromRGB(185,191,193),Enum.Material.Metal,false)
    cap.Shape=Enum.PartType.Cylinder;cap.CFrame*=CFrame.Angles(0,0,math.pi/2)
end

local function distantRadioMast(parent,x,z)
    local h=74
    for _,dx in ipairs({-2.2,2.2}) do
        World.part(parent,"Distant radio mast leg",Vector3.new(.42,h,.42),CFrame.new(x+dx,24+h/2,z),Color3.fromRGB(104,111,114),Enum.Material.Metal,false)
    end
    for y=28,94,7 do
        World.part(parent,"Distant radio mast crossbar",Vector3.new(5.4,.3,.3),CFrame.new(x,y,z),Color3.fromRGB(104,111,114),Enum.Material.Metal,false)
    end
    World.part(parent,"Distant radio mast antenna",Vector3.new(.28,10,.28),CFrame.new(x,103,z),Color3.fromRGB(82,87,90),Enum.Material.Metal,false)
end

local function rowHome(parent,x,z,tint,levels,baseY)
    local floors=levels or 3
    local base=baseY or 0
    local height=10*floors
    if base>0 then
        World.part(parent,"Rowhome retaining base",Vector3.new(24,base,32),CFrame.new(x,base/2,z),palette.brickDark,Enum.Material.Brick)
    end
    World.part(parent,"Rowhome",Vector3.new(22,height,30),CFrame.new(x,base+height/2,z),tint,Enum.Material.Brick)
    World.part(parent,"Rowhome roof",Vector3.new(23,.8,31),CFrame.new(x,base+height+.45,z),Color3.fromRGB(55,57,58),Enum.Material.Slate)
    for floor=1,floors do
        local y=base+5+(floor-1)*10
        for _,dx in ipairs({-6,6}) do windowPanel(parent,CFrame.new(x+dx,y,z-15.15),5.4,5.2) end
    end
    World.part(parent,"Rowhome door",Vector3.new(5,7,.35),CFrame.new(x,base+3.5,z-15.3),Color3.fromRGB(69,87,98),Enum.Material.Wood,false)
    if base>0 then
        for step=0,math.floor(base/1.2) do
            World.part(parent,"Rowhome hill stair",Vector3.new(5,.45,2),CFrame.new(x,step*1.2+.25,z-18-step*1.8),palette.stone,Enum.Material.Concrete)
        end
    end
end

local function desk(parent,x,y,z,tint)
    local metal=Color3.fromRGB(82,89,95)
    World.part(parent,"Desk top",Vector3.new(5,.45,3.2),CFrame.new(x,y+2.9,z),Color3.fromRGB(171,126,83),Enum.Material.Wood)
    World.part(parent,"Desk modesty panel",Vector3.new(4.35,1.2,.18),CFrame.new(x,y+2.05,z+1.35),Color3.fromRGB(137,96,66),Enum.Material.Wood,false)
    for _,dx in ipairs({-2.05,2.05}) do
        World.part(parent,"Desk leg",Vector3.new(.26,2.65,.26),CFrame.new(x+dx,y+1.5,z),metal,Enum.Material.Metal)
        World.part(parent,"Desk foot",Vector3.new(.9,.18,2.4),CFrame.new(x+dx,y+.22,z+.2),metal,Enum.Material.Metal)
    end
    World.part(parent,"Chair seat",Vector3.new(2.3,.4,2.15),CFrame.new(x,y+1.55,z+3.05),tint,Enum.Material.SmoothPlastic)
    World.part(parent,"Chair back",Vector3.new(2.3,2.45,.35),CFrame.new(x,y+2.7,z+4),tint,Enum.Material.SmoothPlastic)
    for _,dx in ipairs({-.85,.85}) do
        World.part(parent,"Chair leg",Vector3.new(.22,1.55,.22),CFrame.new(x+dx,y+.8,z+3.2),metal,Enum.Material.Metal)
    end
end

local function ceilingLight(parent,position,size,brightness,range)
    local fixture=World.part(parent,"Ceiling light",size or Vector3.new(6,.25,2.2),CFrame.new(position),Color3.fromRGB(247,240,211),Enum.Material.Neon,false)
    local light=Instance.new("PointLight")
    light.Brightness=brightness or .65
    light.Range=range or 20
    light.Color=Color3.fromRGB(255,235,195)
    light.Shadows=false
    light.Parent=fixture
    return fixture
end

local function interiorPlant(parent,name,position)
    local pot=World.part(parent,name.." pot",Vector3.new(2.4,1.8,2.4),CFrame.new(position+Vector3.new(0,.9,0)),Color3.fromRGB(147,103,72),Enum.Material.SmoothPlastic,false)
    pot.Shape=Enum.PartType.Cylinder
    for _,offset in ipairs({
        Vector3.new(0,2.6,0),Vector3.new(-.75,2.3,.15),Vector3.new(.75,2.3,-.1),Vector3.new(0,3.3,.35)
    }) do
        local leaf=World.part(parent,name.." leaf",Vector3.new(1.55,2.15,.75),CFrame.new(position+offset),Color3.fromRGB(63,126,78),Enum.Material.Grass,false)
        leaf.Shape=Enum.PartType.Ball
    end
end

local function hallBench(parent,name,position)
    local navy=Color3.fromRGB(49,67,88)
    World.part(parent,name.." seat",Vector3.new(8,.55,2.25),CFrame.new(position+Vector3.new(0,1.55,0)),navy,Enum.Material.Wood)
    World.part(parent,name.." back",Vector3.new(8,2.1,.45),CFrame.new(position+Vector3.new(0,2.55,1)),navy,Enum.Material.Wood)
    for _,x in ipairs({-3.3,3.3}) do
        World.part(parent,name.." leg",Vector3.new(.35,1.55,.35),CFrame.new(position+Vector3.new(x,.75,0)),palette.metal,Enum.Material.Metal)
    end
end

local function lockerBank(parent,name,position,inward,tint)
    local body=World.part(parent,name.." body",Vector3.new(.92,6.5,12.2),CFrame.new(position+Vector3.new(0,3.4,0)),tint,Enum.Material.Metal,false)
    body.CanQuery=false;body.CanTouch=false
    local frontX=position.X+inward*.53
    for i=1,5 do
        local z=position.Z-4.8+(i-1)*2.4
        local door=World.part(parent,name.." door",Vector3.new(.12,5.7,2.12),CFrame.new(frontX,position.Y+3.45,z),tint:Lerp(Color3.fromRGB(245,245,242),.08),Enum.Material.Metal,false)
        door.CanQuery=false;door.CanTouch=false
        World.part(parent,name.." vent",Vector3.new(.07,.14,.72),CFrame.new(frontX+inward*.08,position.Y+5.35,z),Color3.fromRGB(78,84,90),Enum.Material.Metal,false)
        World.part(parent,name.." handle",Vector3.new(.08,.52,.12),CFrame.new(frontX+inward*.09,position.Y+3.25,z+.72),palette.gold,Enum.Material.Metal,false)
    end
    World.part(parent,name.." top cap",Vector3.new(1.12,.28,12.5),CFrame.new(position.X,position.Y+6.72,position.Z),palette.wood,Enum.Material.Wood,false)
    World.part(parent,name.." toe kick",Vector3.new(1.02,.38,12.35),CFrame.new(position.X,position.Y+.22,position.Z),Color3.fromRGB(62,68,73),Enum.Material.Metal,false)
end

local function framedHallPanel(parent,name,text,cf,size,tint)
    local frame=World.part(parent,name.." frame",size+Vector3.new(.8,.8,.22),cf,palette.wood,Enum.Material.Wood,false)
    frame.CanQuery=false;frame.CanTouch=false
    local face=sign(parent,text,cf*CFrame.new(0,0,-.18),size,tint,palette.cream)
    face.Name=name
    return face
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
    local gui=Instance.new("BillboardGui");gui.Name="Name";gui.AlwaysOnTop=false;gui.Size=UDim2.fromOffset(62,15);gui.StudsOffset=Vector3.new(0,1.15,0);gui.MaxDistance=10;gui.Parent=head
    local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=palette.navy;label.BackgroundTransparency=.55
    label.TextColor3=palette.cream;label.Font=Enum.Font.GothamBold;label.TextSize=7;label.Text=name;label.TextTruncate=Enum.TextTruncate.AtEnd;label.Parent=gui
    local stroke=Instance.new("UIStroke");stroke.Color=palette.gold;stroke.Transparency=.88;stroke.Thickness=.7;stroke.Parent=label
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(1,0);corner.Parent=label
    return model
end

local function classroom(root,id,title,teacher,x,floorY,tint,active)
    local m=Instance.new("Model");m.Name=id.."_classroom";m.Parent=root
    local roomWidth=49;local roomDepth=58;local z=-109
    local hallX=x<0 and -23.5 or 23.5
    local outerX=x<0 and -74.5 or 74.5
    local warmFloor=Color3.fromRGB(203,186,157)
    local trim=Color3.fromRGB(128,104,78)
    local wallInset=x<0 and -.55 or .55
    local outerInset=x<0 and .55 or -.55

    World.part(m,"Floor",Vector3.new(roomWidth,.45,roomDepth),CFrame.new(x,floorY+.25,z),warmFloor,Enum.Material.WoodPlanks)
    World.part(m,"Outer wall",Vector3.new(1,14,roomDepth),CFrame.new(outerX,floorY+7,z),Color3.fromRGB(242,239,230))
    World.part(m,"Back wall",Vector3.new(roomWidth,14,1),CFrame.new(x,floorY+7,z-roomDepth/2),Color3.fromRGB(242,239,230))
    World.part(m,"Front wall",Vector3.new(roomWidth,14,1),CFrame.new(x,floorY+7,z+roomDepth/2),Color3.fromRGB(242,239,230))
    World.part(m,"Hall wall north",Vector3.new(1,14,23),CFrame.new(hallX,floorY+7,z-17.5),Color3.fromRGB(242,239,230))
    World.part(m,"Hall wall south",Vector3.new(1,14,23),CFrame.new(hallX,floorY+7,z+17.5),Color3.fromRGB(242,239,230))
    World.part(m,"Door lintel",Vector3.new(1,4,12),CFrame.new(hallX,floorY+12,z),Color3.fromRGB(242,239,230))

    -- Real school finish language: wood baseboards, framed doorway and a restrained chair rail.
    World.part(m,"Outer baseboard",Vector3.new(.18,.7,roomDepth-1),CFrame.new(outerX+outerInset,floorY+.58,z),trim,Enum.Material.Wood,false)
    World.part(m,"Back baseboard",Vector3.new(roomWidth-1,.7,.18),CFrame.new(x,floorY+.58,z-roomDepth/2+.55),trim,Enum.Material.Wood,false)
    World.part(m,"Front baseboard",Vector3.new(roomWidth-1,.7,.18),CFrame.new(x,floorY+.58,z+roomDepth/2-.55),trim,Enum.Material.Wood,false)
    for _,doorZ in ipairs({z-6.35,z+6.35}) do
        World.part(m,"Classroom doorway jamb",Vector3.new(.42,10,.5),CFrame.new(hallX+wallInset,floorY+5.2,doorZ),trim,Enum.Material.Wood,false)
    end
    World.part(m,"Classroom doorway header",Vector3.new(.42,.55,13.1),CFrame.new(hallX+wallInset,floorY+10.15,z),trim,Enum.Material.Wood,false)

    -- Finished paired classroom doors: visible glass, hardware and school-blue panels without blocking touch navigation.
    local doorX=hallX+wallInset*1.18
    for _,offset in ipairs({-3.25,3.25}) do
        local door=World.part(m,"Classroom door leaf",Vector3.new(.3,9.15,5.5),CFrame.new(doorX,floorY+5,z+offset),Color3.fromRGB(67,88,108),Enum.Material.Wood,false)
        door.CanQuery=false;door.CanTouch=false
        local vision=World.part(m,"Classroom vision glass",Vector3.new(.12,3.45,2.55),CFrame.new(doorX-wallInset*.25,floorY+7.25,z+offset),Color3.fromRGB(159,188,198),Enum.Material.Glass,false)
        vision.Transparency=.22;vision.CanQuery=false;vision.CanTouch=false
        World.part(m,"Classroom door kick plate",Vector3.new(.12,1.05,4.9),CFrame.new(doorX-wallInset*.26,floorY+1.05,z+offset),palette.metal,Enum.Material.Metal,false)
        World.part(m,"Classroom door handle",Vector3.new(.16,.65,.16),CFrame.new(doorX-wallInset*.32,floorY+4.5,z+offset+(offset<0 and 1.8 or -1.8)),palette.gold,Enum.Material.Metal,false)
    end

    -- A finished acoustic ceiling keeps rooms from reading like open boxes while preserving the full playable height.
    World.part(m,"Classroom acoustic ceiling",Vector3.new(roomWidth-.9,.28,roomDepth-.9),CFrame.new(x,floorY+13.76,z),Color3.fromRGB(246,244,237),Enum.Material.SmoothPlastic,false)
    for _,dx in ipairs({-16,-8,0,8,16}) do
        World.part(m,"Classroom ceiling grid V",Vector3.new(.06,.06,roomDepth-1.2),CFrame.new(x+dx,floorY+13.58,z),Color3.fromRGB(202,203,199),Enum.Material.Metal,false)
    end
    for _,dz in ipairs({-20,-10,0,10,20}) do
        World.part(m,"Classroom ceiling grid H",Vector3.new(roomWidth-1.2,.06,.06),CFrame.new(x,floorY+13.58,z+dz),Color3.fromRGB(202,203,199),Enum.Material.Metal,false)
    end

    -- A proper whiteboard and teaching wall replace the giant floating-looking room sign.
    World.part(m,"Classroom whiteboard",Vector3.new(33,7,.32),CFrame.new(x,floorY+8,z-roomDepth/2+.6),Color3.fromRGB(248,248,243),Enum.Material.SmoothPlastic,false)
    World.part(m,"Whiteboard top frame",Vector3.new(34,.32,.42),CFrame.new(x,floorY+11.6,z-roomDepth/2+.35),palette.metal,Enum.Material.Metal,false)
    World.part(m,"Whiteboard bottom frame",Vector3.new(34,.32,.42),CFrame.new(x,floorY+4.4,z-roomDepth/2+.35),palette.metal,Enum.Material.Metal,false)
    World.part(m,"Whiteboard tray",Vector3.new(20,.32,.8),CFrame.new(x,floorY+4.15,z-roomDepth/2+1),palette.metal,Enum.Material.Metal,false)
    local boardCf=CFrame.new(x,floorY+8,z-roomDepth/2+.82)*CFrame.Angles(0,math.pi,0)
    sign(m,"ASSUMPTION BVM  •  "..title.."\n"..teacher,boardCf,Vector3.new(27,4,.18),palette.navy,palette.cream)
    cross(m,CFrame.new(x+20,floorY+10,z-roomDepth/2+.45),.38,palette.gold)
    World.part(m,"Whiteboard marker blue",Vector3.new(1.1,.12,.14),CFrame.new(x-3,floorY+4.42,z-roomDepth/2+.9),palette.navy,nil,false)
    World.part(m,"Whiteboard marker green",Vector3.new(1.1,.12,.14),CFrame.new(x-1.5,floorY+4.42,z-roomDepth/2+.9),palette.green,nil,false)
    World.part(m,"Whiteboard eraser",Vector3.new(1.5,.24,.55),CFrame.new(x+1,floorY+4.42,z-roomDepth/2+.92),Color3.fromRGB(75,79,83),Enum.Material.Fabric,false)
    framedHallPanel(m,"Classroom mission panel","FAITH • LEARNING • SERVICE",CFrame.new(x-18,floorY+10,z-roomDepth/2+.62)*CFrame.Angles(0,math.pi,0),Vector3.new(9,3,.16),palette.green)

    -- Teacher zone, rug, storage and small lived-in details.
    local teacherDeskX=x+(x<0 and -13 or 13)
    World.part(m,"Teacher desk top",Vector3.new(10,.6,4),CFrame.new(teacherDeskX,floorY+3,z-22),palette.wood,Enum.Material.Wood)
    for _,dx in ipairs({-4.2,4.2}) do
        World.part(m,"Teacher desk leg",Vector3.new(.45,2.8,.45),CFrame.new(teacherDeskX+dx,floorY+1.45,z-22),palette.metal,Enum.Material.Metal)
    end
    World.part(m,"Teacher laptop base",Vector3.new(3.2,.18,2.2),CFrame.new(teacherDeskX,floorY+3.45,z-22),Color3.fromRGB(75,82,88),Enum.Material.Metal,false)
    World.part(m,"Teacher laptop screen",Vector3.new(3.2,2.1,.18),CFrame.new(teacherDeskX,floorY+4.45,z-22.9)*CFrame.Angles(math.rad(-8),0,0),Color3.fromRGB(69,94,108),Enum.Material.Glass,false)

    local rugColor=tint:Lerp(Color3.fromRGB(236,232,220),.38)
    World.part(m,"Classroom area rug",Vector3.new(18,.12,9),CFrame.new(x,floorY+.52,z-22),rugColor,Enum.Material.Fabric,false)
    World.part(m,"Classroom rug stripe A",Vector3.new(16,.04,.28),CFrame.new(x,floorY+.59,z-25.1),palette.gold,nil,false)
    World.part(m,"Classroom rug stripe B",Vector3.new(16,.04,.28),CFrame.new(x,floorY+.59,z-18.9),palette.navy,nil,false)

    local cabinetX=x+(x<0 and -14 or 14)
    World.part(m,"Classroom storage cabinet",Vector3.new(15,6,2.1),CFrame.new(cabinetX,floorY+3.3,z+26.6),Color3.fromRGB(184,153,113),Enum.Material.Wood)
    for shelf=1,2 do
        World.part(m,"Classroom cabinet shelf",Vector3.new(14.4,.2,2.25),CFrame.new(cabinetX,floorY+1.4+shelf*1.8,z+26.4),Color3.fromRGB(126,97,69),Enum.Material.Wood,false)
    end
    for _,dx in ipairs({-5,-1.7,1.7,5}) do
        World.part(m,"Classroom cubby bin",Vector3.new(2.7,1.25,1.4),CFrame.new(cabinetX+dx,floorY+1.2,z+25.3),tint:Lerp(palette.cream,.45),Enum.Material.SmoothPlastic,false)
    end

    local outerDisplayX=outerX+outerInset
    local studentWorkCf=CFrame.new(outerDisplayX,floorY+8,z+6)*CFrame.Angles(0,x<0 and math.pi/2 or -math.pi/2,0)
    local studentWork=sign(m,"STUDENT WORK\n★  CREATE  •  TRY  •  GROW  ★",studentWorkCf,Vector3.new(16,6,.22),tint,palette.cream)
    studentWork.Name="Student work board"
    interiorPlant(m,"Classroom plant",Vector3.new(x+(x<0 and -20 or 20),floorY,z+23))
    World.part(m,"Classroom reading bench",Vector3.new(10,1.15,3),CFrame.new(x+(x<0 and 15 or -15),floorY+1,z+22.5),tint:Lerp(palette.cream,.35),Enum.Material.Fabric,false)
    World.part(m,"Classroom reading bench back",Vector3.new(10,2.3,.45),CFrame.new(x+(x<0 and 15 or -15),floorY+2.25,z+23.8),tint:Lerp(palette.cream,.25),Enum.Material.Fabric,false)
    local trash=World.part(m,"Classroom trash bin",Vector3.new(2.1,2.7,2.1),CFrame.new(x+(x<0 and 20 or -20),floorY+1.4,z-23),Color3.fromRGB(92,101,105),Enum.Material.Metal,false)
    trash.Shape=Enum.PartType.Cylinder
    framedHallPanel(m,"Classroom values panel","BE KIND\nBE CURIOUS\nDO YOUR BEST",CFrame.new(outerDisplayX,floorY+8,z-10)*CFrame.Angles(0,x<0 and math.pi/2 or -math.pi/2,0),Vector3.new(12,6,.18),palette.navy)

    -- Nine student stations remain roomy enough for mobile navigation.
    for _,dx in ipairs({-11,0,11}) do
        for _,dz in ipairs({-13,3,19}) do desk(m,x+dx,floorY,z+dz,tint) end
    end

    -- Warm, even classroom lighting without the old over-lit duplicate fixture look.
    for _,dx in ipairs({-12,0,12}) do
        for _,dz in ipairs({-10,12}) do
            local fixture=ceilingLight(m,Vector3.new(x+dx,floorY+13.2,z+dz),Vector3.new(7.5,.22,2.1),.58,19)
            fixture.Name="Classroom ceiling light"
        end
    end

    -- One clear subject-specific visual cue per room; decorative only, never another learning authority.
    if id=="math" then
        sign(m,"NUMBER SENSE\n2 + 3 = 5   •   10 − 4 = 6",CFrame.new(x,floorY+9,z+28.35),Vector3.new(27,4.5,.2),tint,palette.cream)
    elseif id=="reading" then
        World.part(m,"Reading bookcase",Vector3.new(16,8,2),CFrame.new(x+12,floorY+4.5,z+27),palette.wood,Enum.Material.Wood)
        for i=1,12 do
            World.part(m,"Reading book",Vector3.new(.8,3,1.2),CFrame.new(x+5+i*1.05,floorY+6,z+25.8),
                color(Catalog.Subjects[(i-1)%#Catalog.Subjects+1].color),nil,false)
        end
        sign(m,"READ • IMAGINE • DISCOVER",CFrame.new(x-8,floorY+10,z+28.35),Vector3.new(20,3,.2),tint,palette.cream)
    elseif id=="grammar" then
        sign(m,"WHO?  +  DOES WHAT?\nBuild a complete sentence.",CFrame.new(x,floorY+9,z+28.35),Vector3.new(30,5,.2),tint,palette.cream)
    elseif id=="religion" then
        cross(m,CFrame.new(x,floorY+10,z+28.25)*CFrame.Angles(0,math.pi,0),.8,palette.gold)
        sign(m,"FAITH  •  HOPE  •  LOVE",CFrame.new(x,floorY+5.5,z+28.3),Vector3.new(25,2.6,.2),palette.navy,palette.gold)
    elseif id=="vocabulary" then
        sign(m,"WORD  →  MEANING  →  CONTEXT",CFrame.new(x,floorY+9,z+28.35),Vector3.new(31,3,.2),tint,palette.cream)
    elseif id=="spelling" then
        for i,letter in ipairs({"A","B","V","M","S","P","E","L","L"}) do
            local tx=x-15+(i-1)*3.7
            local tile=sign(m,letter,CFrame.new(tx,floorY+9,z+28.35),Vector3.new(3,3,.18),i%2==0 and palette.navy or tint,palette.cream)
            tile.Name="Spelling letter tile"
        end
    end

    local teacherX=x+(x<0 and 13 or -13)
    npc(m,teacher,Vector3.new(teacherX,floorY,z-21),false,tint)
    local hallLabelCf=CFrame.new(hallX+(x<0 and .65 or -.65),floorY+9,z)*CFrame.Angles(0,x<0 and -math.pi/2 or math.pi/2,0)
    sign(m,title.."\n"..teacher,hallLabelCf,Vector3.new(14,4,.25),tint,palette.cream)
    if active then World.rooms[id]={x=x,z=z,hx=23,hz=27,minY=floorY,maxY=floorY+14} end
end

local function makeFrontArch(root,x,hasDoor)
    local z=-34.2
    local radius=6.35
    local springY=17.4
    local glassWidth=11.2
    -- Three large segmented arches define the approved Roblox facade. Native blocks keep
    -- the silhouette crisp and cheap while the cream tracery carries the church-school character.
    for i=0,14 do
        local theta=math.pi*i/14
        local px=x+math.cos(theta)*radius
        local py=springY+math.sin(theta)*radius
        World.part(root,"Arch stone segment",Vector3.new(2.7,1.25,1.4),
            CFrame.new(px,py,z)*CFrame.Angles(0,0,theta+math.pi/2),
            palette.stone,Enum.Material.Concrete,false)
    end
    World.part(root,"Arch left pier",Vector3.new(1.35,16.8,1.4),CFrame.new(x-radius,11.6,z),palette.stone,Enum.Material.Concrete)
    World.part(root,"Arch right pier",Vector3.new(1.35,16.8,1.4),CFrame.new(x+radius,11.6,z),palette.stone,Enum.Material.Concrete)
    World.part(root,"Arch keystone",Vector3.new(2.2,1.55,1.7),CFrame.new(x,24.05,z-.05),Color3.fromRGB(196,191,179),Enum.Material.Concrete,false)

    -- Stepped native-glass strips follow the arch curve so the window actually reads as arched
    -- from gameplay distance. This avoids a rectangular glass slab peeking through the corners.
    for _,offset in ipairs({-5.4,-3.6,-1.8,0,1.8,3.6,5.4}) do
        local arcHeight=math.sqrt(math.max(.2,radius*radius-offset*offset))
        local panelHeight=math.max(1.1,arcHeight)
        local upperGlass=World.part(root,"Arch segmented glazing",Vector3.new(1.62,panelHeight,.3),
            CFrame.new(x+offset,springY+panelHeight/2,z-.55),Color3.fromRGB(91,118,133),Enum.Material.Glass,false)
        upperGlass.Transparency=.1
        local upperGlow=World.part(root,"Arch segmented warm backlight",Vector3.new(1.38,math.max(.8,panelHeight-.35),.08),
            CFrame.new(x+offset,springY+panelHeight/2,z-.77),Color3.fromRGB(255,222,159),Enum.Material.Neon,false)
        upperGlow.Transparency=.78;upperGlow.CanQuery=false;upperGlow.CanTouch=false
    end
    for _,offset in ipairs({-3.8,-1.9,0,1.9,3.8}) do
        local mullionHeight=math.sqrt(math.max(.2,radius*radius-offset*offset))
        World.part(root,"Arch upper mullion",Vector3.new(.14,mullionHeight+.35,.17),
            CFrame.new(x+offset,springY+mullionHeight/2,z-.8)*CFrame.Angles(0,0,offset*.045),palette.cream,nil,false)
    end
    for _,dx in ipairs({-3.15,0,3.15}) do
        World.part(root,"Arch tracery left",Vector3.new(4.6,.14,.18),
            CFrame.new(x+dx-.82,20.15,z-.82)*CFrame.Angles(0,0,math.rad(54)),palette.cream,nil,false)
        World.part(root,"Arch tracery right",Vector3.new(4.6,.14,.18),
            CFrame.new(x+dx+.82,20.15,z-.82)*CFrame.Angles(0,0,math.rad(-54)),palette.cream,nil,false)
    end

    if hasDoor then
        local transom=World.part(root,"Door transom glazing",Vector3.new(glassWidth,4.2,.3),CFrame.new(x,14.45,z-.56),Color3.fromRGB(93,118,129),Enum.Material.Glass,false)
        transom.Transparency=.11
        World.part(root,"Entry double doors",Vector3.new(10.5,7.4,.34),CFrame.new(x,8,z-.72),Color3.fromRGB(224,219,201),Enum.Material.Metal,false)
        World.part(root,"Door split",Vector3.new(.2,7.2,.4),CFrame.new(x,8,z-.92),palette.stone,nil,false)
        for _,dx in ipairs({-2.7,2.7}) do
            World.part(root,"Door window",Vector3.new(1.45,2.45,.12),CFrame.new(x+dx,8.5,z-.96),Color3.fromRGB(67,88,98),Enum.Material.Glass,false)
            World.part(root,"Door handle",Vector3.new(.22,1.05,.28),CFrame.new(x+dx*.25,6.9,z-1.02),palette.metal,Enum.Material.Metal,false)
        end
    else
        local lower=World.part(root,"Tall lower glazing",Vector3.new(glassWidth,10.8,.32),CFrame.new(x,12,z-.56),Color3.fromRGB(86,112,124),Enum.Material.Glass,false)
        lower.Transparency=.1
        local lowerGlow=World.part(root,"Arch lower warm backlight",Vector3.new(glassWidth-.5,10.2,.08),CFrame.new(x,12,z-.78),Color3.fromRGB(255,225,171),Enum.Material.Neon,false)
        lowerGlow.Transparency=.82;lowerGlow.CanQuery=false;lowerGlow.CanTouch=false
        for _,offset in ipairs({-3.7,0,3.7}) do
            World.part(root,"Lower vertical mullion",Vector3.new(.16,10.3,.18),CFrame.new(x+offset,12,z-.8),palette.cream,nil,false)
        end
        for _,y in ipairs({9.3,12.7,16}) do
            World.part(root,"Lower horizontal mullion",Vector3.new(glassWidth,.16,.18),CFrame.new(x,y,z-.8),palette.cream,nil,false)
        end
    end

    World.part(root,"Arch hood left",Vector3.new(4.7,.9,1.15),
        CFrame.new(x-2.45,25,z)*CFrame.Angles(0,0,math.rad(-38)),palette.stone,Enum.Material.Concrete,false)
    World.part(root,"Arch hood right",Vector3.new(4.7,.9,1.15),
        CFrame.new(x+2.45,25,z)*CFrame.Angles(0,0,math.rad(38)),palette.stone,Enum.Material.Concrete,false)
end

local function stairFlight(root,x,zStart,zEnd,yStart,yEnd)
    local steps=22
    for i=0,steps-1 do
        local t=i/(steps-1)
        local z=zStart+(zEnd-zStart)*t
        local y=yStart+(yEnd-yStart)*t
        World.part(root,"Interior stair",Vector3.new(11,.72,2.25),CFrame.new(x,y,z),palette.stone,Enum.Material.Concrete)
        if i%4==0 then
            for _,sx in ipairs({-5.2,5.2}) do
                World.part(root,"Interior stair rail post",Vector3.new(.25,3,.25),CFrame.new(x+sx,y+1.8,z),palette.metal,Enum.Material.Metal,false)
            end
        end
    end
    local dz=zEnd-zStart
    local dy=yEnd-yStart
    local railLength=math.sqrt(dz*dz+dy*dy)
    local midZ=(zStart+zEnd)/2
    local midY=(yStart+yEnd)/2+2.7
    local pitch=math.atan2(dy,dz)
    for _,sx in ipairs({-5.2,5.2}) do
        World.part(root,"Interior stair handrail",Vector3.new(.28,.28,railLength),
            CFrame.new(x+sx,midY,midZ)*CFrame.Angles(pitch,0,0),palette.metal,Enum.Material.Metal,false)
    end
end

function World.build()
    local old=Workspace:FindFirstChild("NeighborhoodWorld");if old then old:Destroy() end
    local root=Instance.new("Folder");root.Name="NeighborhoodWorld";root.Parent=Workspace;World.root=root
    World.rooms={};World.leaderboardParts={}

    -- Bright, warm daytime presentation from the authoritative gold-standard board.
    Lighting.ClockTime=10.4
    Lighting.Brightness=2.4
    Lighting.EnvironmentDiffuseScale=.45
    Lighting.EnvironmentSpecularScale=.35
    Lighting.Ambient=Color3.fromRGB(122,126,132)
    Lighting.OutdoorAmbient=Color3.fromRGB(165,169,176)
    Lighting.ColorShift_Top=Color3.fromRGB(255,244,221)
    Lighting.GlobalShadows=true
    Lighting.ShadowSoftness=.28
    Lighting.ExposureCompensation=.08
    Lighting.GeographicLatitude=40.68
    local atmosphere=Lighting:FindFirstChild("ABVMAtmosphere")
    if not atmosphere then
        atmosphere=Instance.new("Atmosphere");atmosphere.Name="ABVMAtmosphere";atmosphere.Parent=Lighting
    end
    atmosphere.Density=.22
    atmosphere.Offset=.12
    atmosphere.Color=Color3.fromRGB(210,226,239)
    atmosphere.Decay=Color3.fromRGB(168,186,204)
    atmosphere.Glare=.08
    atmosphere.Haze=1.35

    -- Native post-processing for the bright blue-sky / warm-brick gold-standard look.
    -- Keep it restrained so mobile devices get polish without an overprocessed screenshot effect.
    local bloom=Lighting:FindFirstChild("ABVMGoldBloom")
    if not bloom then bloom=Instance.new("BloomEffect");bloom.Name="ABVMGoldBloom";bloom.Parent=Lighting end
    bloom.Intensity=.11;bloom.Size=18;bloom.Threshold=1.05
    local grade=Lighting:FindFirstChild("ABVMGoldGrade")
    if not grade then grade=Instance.new("ColorCorrectionEffect");grade.Name="ABVMGoldGrade";grade.Parent=Lighting end
    grade.Brightness=.025;grade.Contrast=.055;grade.Saturation=.08
    local rays=Lighting:FindFirstChild("ABVMSunRays")
    if not rays then rays=Instance.new("SunRaysEffect");rays.Name="ABVMSunRays";rays.Parent=Lighting end
    rays.Intensity=.025;rays.Spread=.72
    local clouds=Workspace.Terrain:FindFirstChild("GoldStandardClouds")
    if not clouds then clouds=Instance.new("Clouds");clouds.Name="GoldStandardClouds";clouds.Parent=Workspace.Terrain end
    clouds.Cover=.22;clouds.Density=.38;clouds.Color=Color3.fromRGB(248,250,255)

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
    -- Upper classrooms and halls already provide walkable floors. Full upper slabs would cap the stairwells.
    World.part(root,"Flat black roof",Vector3.new(154,1,114),CFrame.new(0,52.5,-90),Color3.fromRGB(45,47,48),Enum.Material.Slate)
    World.part(root,"Roof parapet front",Vector3.new(154,2.5,1.2),CFrame.new(0,53.5,-34.5),palette.brick,Enum.Material.Brick)
    World.part(root,"Roof parapet back",Vector3.new(154,2.5,1.2),CFrame.new(0,53.5,-145.5),palette.brick,Enum.Material.Brick)
    -- Reference-visible roofline rhythm, chimney stack and simple roof vents.
    for _,x in ipairs({-66,-44,-22,0,22,44,66}) do
        World.part(root,"Front parapet cap",Vector3.new(4.2,2.2,2.3),CFrame.new(x,55,-34.7),palette.stone,Enum.Material.Concrete,false)
    end
    for _,x in ipairs({-66,-34,0,34,66}) do
        World.part(root,"Gold standard parapet pier",Vector3.new(4.4,4.6,2.5),CFrame.new(x,55.7,-34.65),palette.brickDark,Enum.Material.Brick,false)
        World.part(root,"Gold standard parapet pier cap",Vector3.new(5.4,1.05,3.2),CFrame.new(x,58.45,-34.65),palette.stone,Enum.Material.Concrete,false)
    end
    World.part(root,"Brick chimney",Vector3.new(11,20,11),CFrame.new(62,62,-57),palette.brickDark,Enum.Material.Brick)
    World.part(root,"Chimney cap",Vector3.new(12.5,1.4,12.5),CFrame.new(62,72.4,-57),palette.stone,Enum.Material.Concrete)
    World.part(root,"Roof center finial base",Vector3.new(2.4,5,2.4),CFrame.new(0,57.2,-34.8),palette.stone,Enum.Material.Concrete,false)
    cross(root,CFrame.new(0,61.2,-34.8),.48,palette.gold)
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

    -- Formal front facade: four upper window bays, then the three large arches from the approved render
    -- aligned beneath the final three bays. The lower wall is segmented so the arches are real openings,
    -- not decorative glass stuck onto a solid brick collision wall.
    World.part(root,"Front upper brick mass",Vector3.new(150,31,1.4),CFrame.new(0,37,-35),palette.brick,Enum.Material.Brick)
    World.part(root,"Front lower far west",Vector3.new(45,17,1.4),CFrame.new(-52.5,12,-35),palette.brick,Enum.Material.Brick)
    World.part(root,"Front lower interbay west",Vector3.new(7.5,17,1.4),CFrame.new(0,12,-35),palette.brick,Enum.Material.Brick)
    World.part(root,"Front lower interbay east",Vector3.new(7.5,17,1.4),CFrame.new(34,12,-35),palette.brick,Enum.Material.Brick)
    World.part(root,"Front lower far east",Vector3.new(16,17,1.4),CFrame.new(67,12,-35),palette.brick,Enum.Material.Brick)
    for _,x in ipairs({-68,-34,0,34,68}) do
        World.part(root,"Front brick pilaster",Vector3.new(2.8,48,2.2),CFrame.new(x,28,-34.2),palette.brickDark,Enum.Material.Brick)
        World.part(root,"Front pilaster stone cap",Vector3.new(4.2,1.25,2.7),CFrame.new(x,52.2,-34.15),palette.stone,Enum.Material.Concrete,false)
    end
    -- The reference render has a noticeably heavier east/front corner pier that visually anchors
    -- the vertical green banner and the side elevation.
    World.part(root,"Gold standard east corner tower",Vector3.new(6.6,50,5.4),CFrame.new(71.6,28,-36.2),palette.brickDark,Enum.Material.Brick)
    World.part(root,"East corner tower stone cap",Vector3.new(7.6,1.4,6.3),CFrame.new(71.6,53.1,-36.2),palette.stone,Enum.Material.Concrete,false)
    for _,floorY in ipairs({29,44}) do
        for _,x in ipairs({-51,-17,17,51}) do
            World.part(root,"Tan facade bay",Vector3.new(27.2,11.8,.58),CFrame.new(x,floorY,-34.1),palette.tan,Enum.Material.Concrete,false)
            local facadeWindowWidth=x==-51 and 9.6 or 15.2
            schoolWindowPanel(root,CFrame.new(x,floorY,-33.68),facadeWindowWidth,5.9)
        end
    end
    -- Horizontal stone/concrete belts and cornice create the layered facade depth visible in the target.
    World.part(root,"Front stone belt",Vector3.new(148,1.1,1.2),CFrame.new(0,26.1,-33.8),palette.stone,Enum.Material.Concrete,false)
    World.part(root,"Gold standard front cornice",Vector3.new(150,1.15,1.6),CFrame.new(0,51.25,-33.95),Color3.fromRGB(194,190,178),Enum.Material.Concrete,false)
    World.part(root,"Front foundation west",Vector3.new(43,3.1,1.8),CFrame.new(-53,5,-33.75),Color3.fromRGB(76,68,61),Enum.Material.Slate,false)
    World.part(root,"Front foundation east",Vector3.new(43,3.1,1.8),CFrame.new(53,5,-33.75),Color3.fromRGB(76,68,61),Enum.Material.Slate,false)
    makeFrontArch(root,-17,false)
    makeFrontArch(root,17,true)
    makeFrontArch(root,51,true)
    -- The real facade is mostly architecture, not signage. Identity is carried by the Howard sign,
    -- lobby crest and a small restrained roofline cross.
    cross(root,CFrame.new(0,49.2,-33.4),.72,palette.gold)
    sign(root,"1928",CFrame.new(0,10.6,-33.15)*CFrame.Angles(0,math.pi,0),Vector3.new(5,2,.25),palette.stone,palette.brickDark)

    -- The approved Roblox gold standard adds one restrained vertical identity banner on the
    -- east/front corner. It is built from native Parts + SurfaceGui so it is cheap, crisp and
    -- reproducible in Studio instead of depending on an external photoreal texture.
    local facadeBanner=sign(root,"✝\nFAITH\nFAMILY\nACADEMICS\nSERVICE",
        CFrame.new(75.75,35,-56)*CFrame.Angles(0,-math.pi/2,0),
        Vector3.new(9,22,.42),palette.green,palette.gold)
    facadeBanner.Name="Gold standard facade banner"
    World.part(root,"Facade banner gold top trim",Vector3.new(.48,.45,9.7),
        CFrame.new(75.95,46.2,-56),palette.gold,Enum.Material.Metal,false)
    World.part(root,"Facade banner gold bottom trim",Vector3.new(.48,.45,9.7),
        CFrame.new(75.95,23.8,-56),palette.gold,Enum.Material.Metal,false)

    -- Repeating side windows and strong vertical brick rhythm visible in the reference photos.
    for _,side in ipairs({-1,1}) do
        local wallX=side*75.65
        local yaw=side<0 and -math.pi/2 or math.pi/2
        for _,floorY in ipairs({12,28,44}) do
            for _,z in ipairs({-132,-115,-77,-60}) do
                World.part(root,"Side tan facade bay",Vector3.new(.52,11.2,13.4),CFrame.new(side*75.1,floorY,z),palette.tan,Enum.Material.Concrete,false)
                schoolWindowPanel(root,CFrame.new(wallX,floorY,z)*CFrame.Angles(0,yaw,0),8,5.4)
            end
        end
        -- Smaller lower/service windows sell the partially exposed basement on the hill side.
        for _,z in ipairs({-127,-103,-79,-55}) do
            local basement=World.part(root,"Basement window",Vector3.new(.3,3.8,6.3),CFrame.new(wallX,5.9,z)*CFrame.Angles(0,yaw,0),Color3.fromRGB(88,109,116),Enum.Material.Glass,false)
            basement.Transparency=.28
            for _,offset in ipairs({-2,0,2}) do
                World.part(root,"Basement window bar",Vector3.new(.32,4.2,.25),CFrame.new(side*75.85,5.9,z+offset),palette.metal,Enum.Material.Metal,false)
            end
        end
        for _,z in ipairs({-139,-122,-105,-71,-54,-37}) do
            World.part(root,"Side brick pilaster",Vector3.new(2,48,2.2),CFrame.new(side*74.9,28,z),palette.brickDark,Enum.Material.Brick)
        end
        for _,z in ipairs({-137,-42}) do
            World.part(root,"Rain downspout",Vector3.new(.55,44,.55),CFrame.new(side*76.1,27,z),Color3.fromRGB(193,194,188),Enum.Material.Metal,false)
        end
    end

    -- Broad formal stairs are biased east to sit under the three gold-standard arches, matching
    -- the target composition where the freestanding sign and garden occupy the left foreground.
    local stairCenterX=17
    local frontSteps=14
    local startZ=-1.5
    local endZ=-31
    local startY=.25
    local endY=4.3
    for i=0,frontSteps-1 do
        local t=i/(frontSteps-1)
        local z=startZ+(endZ-startZ)*t
        local y=startY+(endY-startY)*t
        World.part(root,"Front broad stair",Vector3.new(75,.58,2.45),CFrame.new(stairCenterX,y,z),palette.stone,Enum.Material.Concrete)
    end
    World.part(root,"Front lower landing",Vector3.new(77,.45,9),CFrame.new(stairCenterX,.1,3),palette.stone,Enum.Material.Concrete)
    World.part(root,"Front landing",Vector3.new(77,.7,8),CFrame.new(stairCenterX,4.3,-31),palette.stone,Enum.Material.Concrete)
    for _,side in ipairs({-1,1}) do
        for tier=0,2 do
            local z=4-tier*8.5
            local y=.8+tier*.75
            local wall=World.part(root,"Gold standard stair planter wall",Vector3.new(12,1.6+tier*.35,5.2),
                CFrame.new(stairCenterX+side*(45-tier*2.6),y,z),palette.stone,Enum.Material.Concrete)
            wall.CanQuery=false
            shrub(root,stairCenterX+side*(45-tier*2.6),z,0.62+tier*.08)
        end
    end

    -- Low masonry cheeks and paired rails match the broad ceremonial stair in the target.
    World.part(root,"Front stair west cheek",Vector3.new(3,5.2,35),CFrame.new(stairCenterX-40,2.55,-15),palette.brickDark,Enum.Material.Brick)
    World.part(root,"Front stair east cheek",Vector3.new(3,5.2,35),CFrame.new(stairCenterX+40,2.55,-15),palette.brickDark,Enum.Material.Brick)
    local stairDz=endZ-startZ
    local stairDy=endY-startY
    local stairLength=math.sqrt(stairDz*stairDz+stairDy*stairDy)
    local stairPitch=math.atan2(stairDy,stairDz)
    for _,x in ipairs({stairCenterX-18,stairCenterX+18}) do
        for step=0,6 do
            local t=step/6
            World.part(root,"Front stair rail post",Vector3.new(.3,3,.3),
                CFrame.new(x,startY+1.6+(endY-startY)*t,startZ+(endZ-startZ)*t),palette.metal,Enum.Material.Metal,false)
        end
        World.part(root,"Front stair handrail",Vector3.new(.32,.32,stairLength),
            CFrame.new(x,(startY+endY)/2+2.7,(startZ+endZ)/2)*CFrame.Angles(stairPitch,0,0),
            palette.metal,Enum.Material.Metal,false)
    end

    -- White low front additions flank the arched section in the real facade.
    for _,x in ipairs({-44,44}) do
        World.part(root,"Front low annex",Vector3.new(23,8.5,12.5),CFrame.new(x,7.25,-27),Color3.fromRGB(219,221,211),Enum.Material.SmoothPlastic)
        World.part(root,"Front low annex roof",Vector3.new(24.5,.7,14),CFrame.new(x,11.55,-27),Color3.fromRGB(63,65,65),Enum.Material.Slate)
        for _,y in ipairs({4.7,6.35,8,9.65}) do
            World.part(root,"Front annex siding line",Vector3.new(22,.12,.2),CFrame.new(x,y,-20.72),Color3.fromRGB(184,189,183),nil,false)
        end
    end
    World.part(root,"School approach",Vector3.new(45,.3,28),CFrame.new(17,.2,19),Color3.fromRGB(204,198,184),Enum.Material.Cobblestone)

    -- Street-level identity from the approved Roblox render. The two-panel sign and arched crown
    -- intentionally echo the generated target while staying entirely native Roblox geometry/UI.
    local frontSignZ=14.5
    for _,x in ipairs({-64,-46}) do
        World.part(root,"Front school sign post",Vector3.new(1,13.6,1),CFrame.new(x,6.8,frontSignZ),palette.green,Enum.Material.Wood,false)
        local cap=World.part(root,"Front school sign post cap",Vector3.new(1.55,1.55,1.55),CFrame.new(x,13.8,frontSignZ),palette.gold,nil,false)
        cap.Shape=Enum.PartType.Ball
    end
    World.part(root,"Front school sign gold backing",Vector3.new(20,8.8,.76),
        CFrame.new(-55,8.5,frontSignZ-.1)*CFrame.Angles(0,math.pi,0),palette.gold,Enum.Material.Metal,false)
    local frontSchoolSign=sign(root,"ASSUMPTION\nBVM SCHOOL",
        CFrame.new(-55,8.5,frontSignZ-.5)*CFrame.Angles(0,math.pi,0),
        Vector3.new(19.2,8,.48),palette.green,palette.gold)
    frontSchoolSign.Name="Gold standard front school sign"
    local frontGui=frontSchoolSign:FindFirstChildOfClass("SurfaceGui")
    local frontLabel=frontGui and frontGui:FindFirstChildOfClass("TextLabel")
    if frontLabel then frontLabel.Font=Enum.Font.Garamond;frontLabel.TextStrokeTransparency=.78;frontLabel.TextStrokeColor3=Color3.fromRGB(107,75,20) end
    for _,entry in ipairs({
        {-63.2,8.4,math.rad(-24),"left"},
        {-46.8,8.4,math.rad(24),"right"},
    }) do
        World.part(root,"Gold standard sign flourish "..entry[4],Vector3.new(.22,3.2,.18),
            CFrame.new(entry[1],entry[2],frontSignZ-.82)*CFrame.Angles(0,0,entry[3]),palette.gold,Enum.Material.Metal,false)
        for dy=-1,1 do
            local leaf=World.part(root,"Gold standard sign leaf "..entry[4],Vector3.new(.58,.34,.2),
                CFrame.new(entry[1]+(entry[4]=="left" and -.55 or .55),entry[2]+dy*.78,frontSignZ-.86),palette.gold,Enum.Material.Metal,false)
            leaf.CFrame*=CFrame.Angles(0,0,entry[3]*.7)
        end
    end
    for i=-2,2 do
        local rise=(2-math.abs(i))*.62
        World.part(root,"Front school sign arched crown",Vector3.new(3.6,1.25,.74),
            CFrame.new(-55+i*3.45,12.55+rise,frontSignZ-.1)*CFrame.Angles(0,math.pi,0),
            i==0 and palette.green or Color3.fromRGB(20,91,52),Enum.Material.Wood,false)
    end
    cross(root,CFrame.new(-55,13.45,frontSignZ-.8)*CFrame.Angles(0,math.pi,0),.36,palette.gold)
    World.part(root,"Gold standard entrance strip backing",Vector3.new(20,2.45,.74),
        CFrame.new(-55,3.35,frontSignZ-.1)*CFrame.Angles(0,math.pi,0),palette.gold,Enum.Material.Metal,false)
    local entranceStrip=sign(root,"ENTRANCE ON HOWARD AVENUE",
        CFrame.new(-55,3.35,frontSignZ-.5)*CFrame.Angles(0,math.pi,0),
        Vector3.new(19.2,1.72,.48),palette.green,palette.gold)
    entranceStrip.Name="Gold standard entrance strip"

    -- Tiered masonry and greenery make the uphill arrival read clearly at Roblox camera distance.
    World.part(root,"Front garden terrace west",Vector3.new(34,2.6,6.2),CFrame.new(-50,1.3,1.4),palette.stone,Enum.Material.Concrete)
    World.part(root,"Front garden terrace east",Vector3.new(34,2.6,6.2),CFrame.new(50,1.3,1.4),palette.stone,Enum.Material.Concrete)
    World.part(root,"Front garden terrace west upper",Vector3.new(28,1.8,4.8),CFrame.new(-49,2.3,-4.2),palette.stone,Enum.Material.Concrete)
    World.part(root,"Front garden terrace east upper",Vector3.new(28,1.8,4.8),CFrame.new(49,2.3,-4.2),palette.stone,Enum.Material.Concrete)

    -- Gold-standard arrival landscaping: clipped shrubs and bright flower beds frame the stairs.
    for _,x in ipairs({-43,43}) do
        shrub(root,x,-8,1.1)
        shrub(root,x,7,.95)
        planter(root,x,-18,11)
    end
    for _,x in ipairs({-67,-61,-49,-41,41,49,59,67}) do
        shrub(root,x,x<0 and 4.8 or 2.6,(math.abs(x)>60) and .78 or .92)
    end
    for _,x in ipairs({-59,59}) do
        tree(root,x,16,.72)
    end
    tree(root,-88,-7,1.18)
    tree(root,-108,-17,1.05)
    planter(root,-24,12,9)
    planter(root,24,12,9)
    planter(root,-55,8.5,17)
    -- Chain-link edge behind the sign is a strong cue in both the real reference and approved render.
    fencePanel(root,CFrame.new(-84,4,-3),Vector3.new(28,8,.4))
    for x=-97,-71,13 do
        World.part(root,"Front west fence post",Vector3.new(.65,9,.65),CFrame.new(x,4.4,-3),palette.metal,Enum.Material.Metal,true)
    end
    for _,x in ipairs({-31,0,34,65}) do
        World.part(root,"Entrance lamp stone hood",Vector3.new(3.2,.8,1.1),
            CFrame.new(x,25,-33.15)*CFrame.Angles(0,0,math.rad(x<17 and -38 or 38)),palette.stone,Enum.Material.Concrete,false)
        local lamp=World.part(root,"Formal entrance wall lamp",Vector3.new(.8,2.1,.7),CFrame.new(x,12,-33.1),Color3.fromRGB(241,220,163),Enum.Material.Neon,false)
        local glow=Instance.new("PointLight");glow.Brightness=.55;glow.Range=15;glow.Color=Color3.fromRGB(255,225,170);glow.Parent=lamp
    end

    -- Howard Avenue side entrance, cross, walk and green/gold roadside sign.
    -- A continuous sidewalk hugs the side wall in the gold standard and makes the long east elevation
    -- read as a city school rather than a freestanding campus object.
    World.part(root,"Gold standard east sidewalk",Vector3.new(12,.36,112),CFrame.new(82,.22,-90),Color3.fromRGB(205,201,190),Enum.Material.Concrete)
    World.part(root,"Gold standard east curb",Vector3.new(1.4,.72,118),CFrame.new(88.6,.36,-90),palette.stone,Enum.Material.Concrete)
    World.part(root,"Howard entry landing",Vector3.new(14,.6,17),CFrame.new(82,4.2,-93),palette.stone,Enum.Material.Concrete)
    World.part(root,"Howard double doors",Vector3.new(.35,8,10),CFrame.new(75.45,8,-93),Color3.fromRGB(83,103,117),Enum.Material.Metal,false)
    World.part(root,"Howard door split",Vector3.new(.45,7.8,.18),CFrame.new(75.15,8,-93),palette.stone,nil,false)
    for _,z in ipairs({-96,-90}) do
        local slit=World.part(root,"Howard door window",Vector3.new(.15,2.7,1.3),CFrame.new(75.12,8.5,z),Color3.fromRGB(39,54,63),Enum.Material.Glass,false)
        slit.Transparency=.2
    end

    -- Brick outer arch and lighter inner stone ring match the real recessed doorway.
    for i=0,12 do
        local theta=math.pi*i/12
        local z=-93+math.cos(theta)*7.25
        local y=16+math.sin(theta)*7.25
        World.part(root,"Howard outer brick arch",Vector3.new(1.45,3.6,1.25),
            CFrame.new(75.9,y,z)*CFrame.Angles(theta+math.pi/2,0,0),
            palette.brickDark,Enum.Material.Brick,false)
    end
    World.part(root,"Howard arch left",Vector3.new(1.15,12,1.25),CFrame.new(75.6,10,-99),palette.stone,Enum.Material.Concrete,false)
    World.part(root,"Howard arch right",Vector3.new(1.15,12,1.25),CFrame.new(75.6,10,-87),palette.stone,Enum.Material.Concrete,false)
    for i=0,12 do
        local theta=math.pi*i/12
        local z=-93+math.cos(theta)*6
        local y=16+math.sin(theta)*6
        World.part(root,"Howard inner stone arch",Vector3.new(1.35,3.05,1.15),
            CFrame.new(75.55,y,z)*CFrame.Angles(theta+math.pi/2,0,0),
            palette.stone,Enum.Material.Concrete,false)
    end

    local transom=World.part(root,"Howard dark transom",Vector3.new(.22,5,9.2),CFrame.new(75.28,14,-93),Color3.fromRGB(37,48,51),Enum.Material.Glass,false)
    transom.Transparency=.18
    cross(root,CFrame.new(75.05,14.4,-93)*CFrame.Angles(0,math.pi/2,0),.42,Color3.fromRGB(112,186,174))

    for _,z in ipairs({-101.5,-84.5}) do
        World.part(root,"Howard wall light mount",Vector3.new(.55,2.4,1.15),CFrame.new(75.18,11,z),palette.stone,Enum.Material.Concrete,false)
        local lamp=World.part(root,"Howard wall light",Vector3.new(.6,1.1,.8),CFrame.new(74.82,11,z),Color3.fromRGB(232,221,181),Enum.Material.Neon,false)
        local glow=Instance.new("PointLight");glow.Brightness=.45;glow.Range=11;glow.Color=Color3.fromRGB(255,226,171);glow.Parent=lamp
    end

    World.part(root,"Howard walkway",Vector3.new(21,.35,17),CFrame.new(93,.25,-93),palette.stone,Enum.Material.Concrete)
    -- Freestanding green/gold Howard Avenue sign with posts and caps like the user's reference.
    for _,z in ipairs({-84.5,-71.5}) do
        World.part(root,"Howard sign post",Vector3.new(.85,17,.85),CFrame.new(107,5.7,z),palette.green,Enum.Material.Wood,false)
        local cap=World.part(root,"Howard sign post cap",Vector3.new(1.3,1.3,1.3),CFrame.new(107,14.2,z),palette.gold,nil,false)
        cap.Shape=Enum.PartType.Ball
    end
    local signBacking=World.part(root,"Howard sign gold backing",Vector3.new(.6,10.8,15.8),CFrame.new(107,9,-78),palette.gold,Enum.Material.Metal,false)
    signBacking.CFrame*=CFrame.Angles(0,-math.pi/2,0)
    local roadSign=sign(root,"✝\nASSUMPTION\nBVM SCHOOL\n────────\nENTRANCE ON HOWARD AVENUE",CFrame.new(106.65,9,-78)*CFrame.Angles(0,-math.pi/2,0),Vector3.new(15,10,.45),palette.green,palette.gold)
    roadSign.Name="Assumption BVM Howard Avenue sign"

    -- Parking lot and simple perimeter fencing.
    World.part(root,"School parking lot",Vector3.new(67,.22,111),CFrame.new(116,.12,-100),Color3.fromRGB(78,78,75),Enum.Material.Asphalt)
    for z=-137,-62,15 do
        for x=91,139,12 do World.part(root,"Parking stripe",Vector3.new(.18,.04,10),CFrame.new(x,.25,z),Color3.fromRGB(225,220,198),nil,false) end
    end
    fencePanel(root,CFrame.new(149,4,-100),Vector3.new(.45,8,112))
    fencePanel(root,CFrame.new(116,4,-155),Vector3.new(67,8,.45))
    fencePanel(root,CFrame.new(116,4,-45),Vector3.new(67,8,.45))
    for z=-154,-46,18 do World.part(root,"Parking fence post",Vector3.new(.65,9,.65),CFrame.new(149,4.4,z),palette.metal,Enum.Material.Metal,true) end
    for x=84,148,12 do
        World.part(root,"Parking fence post",Vector3.new(.65,9,.65),CFrame.new(x,4.4,-155),palette.metal,Enum.Material.Metal,true)
        World.part(root,"Parking fence post",Vector3.new(.65,9,.65),CFrame.new(x,4.4,-45),palette.metal,Enum.Material.Metal,true)
    end
    -- Side-lot service details visible in the real-school references.
    for _,z in ipairs({-121,-108}) do
        World.part(root,"Wall HVAC unit",Vector3.new(2.8,4.5,5.4),CFrame.new(77,7,z),Color3.fromRGB(167,170,166),Enum.Material.Metal,false)
        for y=5.8,8.2,2.4 do World.part(root,"HVAC grille",Vector3.new(.15,.25,4.4),CFrame.new(78.45,y,z),palette.metal,Enum.Material.Metal,false) end
    end
    World.part(root,"Utility cabinet",Vector3.new(3.2,6,4.5),CFrame.new(78,3.2,-132),Color3.fromRGB(116,120,119),Enum.Material.Metal,false)
    local hydrant=World.part(root,"Red fire hydrant",Vector3.new(2.1,4,2.1),CFrame.new(162,2,-52),Color3.fromRGB(185,47,37),Enum.Material.Metal,false)
    hydrant.Shape=Enum.PartType.Cylinder
    World.part(root,"Hydrant crossbar",Vector3.new(4,.9,.9),CFrame.new(162,2.7,-52),Color3.fromRGB(185,47,37),Enum.Material.Metal,false)
    local hydrantTop=World.part(root,"Hydrant cap",Vector3.new(2.8,1.3,2.8),CFrame.new(162,4.3,-52),Color3.fromRGB(185,47,37),Enum.Material.Metal,false)
    hydrantTop.Shape=Enum.PartType.Ball
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
        rowHome(root,-142,z,rowColors[(i-1)%#rowColors+1],3,(i-1)*3)
        rowHome(root,205,z,rowColors[i%#rowColors+1],3,2+(i-1)*3)
    end
    rowHome(root,-169,-118,rowColors[3],3,8)
    rowHome(root,-169,-63,rowColors[2],2,5)
    tree(root,-101,-28,.85);tree(root,-102,-145,.95);tree(root,88,-34,.7)

    -- The approved hero image has a green hill line plus tiny civic/utility silhouettes in the far
    -- background. Keep these extremely simple because they are scenery, not gameplay geometry.
    World.part(root,"Gold standard distant ridge",Vector3.new(430,22,95),CFrame.new(35,8,-248),Color3.fromRGB(87,126,75),Enum.Material.Grass,false)
    for _,entry in ipairs({
        {-165,-228,1.35,19},{-130,-240,1.2,19},{-92,-230,1.3,19},{-55,-246,1.05,19},
        {5,-232,1.3,19},{48,-242,1.18,19},{95,-230,1.35,19},{140,-244,1.22,19},{183,-232,1.35,19},
    }) do tree(root,entry[1],entry[2],entry[3],entry[4]) end
    distantWaterTower(root,210,-252)
    distantRadioMast(root,276,-270)

    -- Sparse overhead utilities are a strong Pottsville/Howard Avenue cue in the reference photos.
    local poleA=utilityPole(root,157,-154,34)
    local poleB=utilityPole(root,157,-94,33)
    local poleC=utilityPole(root,157,-35,32)
    local poleD=utilityPole(root,-116,-142,32)
    local poleE=utilityPole(root,-116,-54,31)
    for _,offset in ipairs({-3.6,0,3.6}) do
        cable(root,poleA+Vector3.new(offset,0,0),poleB+Vector3.new(offset,0,0),.14)
        cable(root,poleB+Vector3.new(offset,0,0),poleC+Vector3.new(offset,0,0),.14)
    end
    cable(root,poleD+Vector3.new(-3,0,0),poleE+Vector3.new(-3,0,0),.14)
    cable(root,poleD+Vector3.new(3,0,0),poleE+Vector3.new(3,0,0),.14)

    -- Hard urban edges replace the generic-campus feel around the school block.
    World.part(root,"Front west retaining cap",Vector3.new(46,.65,2.4),CFrame.new(-57,.7,-3),palette.stone,Enum.Material.Concrete)
    World.part(root,"Front east retaining cap",Vector3.new(46,.65,2.4),CFrame.new(57,.7,-3),palette.stone,Enum.Material.Concrete)
    World.part(root,"Howard curb",Vector3.new(2.2,.55,176),CFrame.new(158,.35,-88),palette.stone,Enum.Material.Concrete)

    -- Polished interior halls: full-width corridors, vinyl/terrazzo-like floors, wainscot and framed doors.
    for index,floorY in ipairs({4,20,36}) do
        local floorColor=Color3.fromRGB(220,216,204)
        local floorMaterial=Enum.Material.SmoothPlastic
        if index==1 then
            World.part(root,"Central hall floor",Vector3.new(47,.42,104),CFrame.new(0,floorY+.25,-90),floorColor,floorMaterial)
            World.part(root,"Hall navy inlay",Vector3.new(3.4,.05,102),CFrame.new(0,floorY+.49,-90),palette.navy,nil,false)
            for _,x in ipairs({-2.05,2.05}) do World.part(root,"Hall gold inlay",Vector3.new(.22,.055,102),CFrame.new(x,floorY+.5,-90),palette.gold,nil,false) end
        elseif index==2 then
            World.part(root,"Central hall floor back",Vector3.new(47,.42,28),CFrame.new(0,floorY+.25,-128),floorColor,floorMaterial)
            World.part(root,"Central hall floor front",Vector3.new(47,.42,50),CFrame.new(0,floorY+.25,-63),floorColor,floorMaterial)
            World.part(root,"Central hall floor stair side",Vector3.new(24,.42,26),CFrame.new(11.5,floorY+.25,-101),floorColor,floorMaterial)
            World.part(root,"Hall navy inlay",Vector3.new(3.4,.05,27),CFrame.new(0,floorY+.49,-128),palette.navy,nil,false)
            World.part(root,"Hall navy inlay",Vector3.new(3.4,.05,49),CFrame.new(0,floorY+.49,-63),palette.navy,nil,false)
            World.part(root,"Stair opening side guard",Vector3.new(.35,3.3,26),CFrame.new(-.35,floorY+1.9,-101),palette.navy,Enum.Material.Metal,false)
            World.part(root,"Stair opening back guard",Vector3.new(13.5,3.3,.35),CFrame.new(-7,floorY+1.9,-114),palette.navy,Enum.Material.Metal,false)
            World.part(root,"Stair guard wood cap",Vector3.new(.55,.25,26),CFrame.new(-.35,floorY+3.55,-101),palette.wood,Enum.Material.Wood,false)
        else
            World.part(root,"Central hall floor back",Vector3.new(47,.42,58),CFrame.new(0,floorY+.25,-113),floorColor,floorMaterial)
            World.part(root,"Central hall floor front",Vector3.new(47,.42,18),CFrame.new(0,floorY+.25,-47),floorColor,floorMaterial)
            World.part(root,"Central hall floor stair side",Vector3.new(24,.42,28),CFrame.new(-11.5,floorY+.25,-75),floorColor,floorMaterial)
            World.part(root,"Hall navy inlay",Vector3.new(3.4,.05,57),CFrame.new(0,floorY+.49,-113),palette.navy,nil,false)
            World.part(root,"Hall navy inlay",Vector3.new(3.4,.05,17),CFrame.new(0,floorY+.49,-47),palette.navy,nil,false)
            World.part(root,"Stair opening side guard",Vector3.new(.35,3.3,28),CFrame.new(.35,floorY+1.9,-75),palette.navy,Enum.Material.Metal,false)
            World.part(root,"Stair opening front guard",Vector3.new(13.5,3.3,.35),CFrame.new(7,floorY+1.9,-61),palette.navy,Enum.Material.Metal,false)
            World.part(root,"Stair guard wood cap",Vector3.new(.55,.25,28),CFrame.new(.35,floorY+3.55,-75),palette.wood,Enum.Material.Wood,false)
        end

        -- Hall-side lower wall finish: navy wainscot with a gold chair rail, broken cleanly at classroom doors.
        for _,side in ipairs({-1,1}) do
            local wallX=side*23.05
            for _,segment in ipairs({{-128.5,27},{-72,62}}) do
                World.part(root,"Hall wainscot",Vector3.new(.28,3.3,segment[2]),CFrame.new(wallX,floorY+1.9,segment[1]),Color3.fromRGB(37,57,82),Enum.Material.SmoothPlastic,false)
                World.part(root,"Hall gold chair rail",Vector3.new(.34,.24,segment[2]),CFrame.new(wallX,floorY+3.55,segment[1]),palette.gold,Enum.Material.Metal,false)
            end
            for _,doorZ in ipairs({-115.35,-102.65}) do
                World.part(root,"Hall classroom door jamb",Vector3.new(.38,10,.55),CFrame.new(wallX,floorY+5.2,doorZ),Color3.fromRGB(124,91,63),Enum.Material.Wood,false)
            end
            World.part(root,"Hall classroom door header",Vector3.new(.38,.55,13.2),CFrame.new(wallX,floorY+10.15,-109),Color3.fromRGB(124,91,63),Enum.Material.Wood,false)
        end

        -- Practical school details keep the corridor from reading like an empty tunnel.
        hallBench(root,"Hall bench",Vector3.new(-18,floorY,-48))
        local storageTint=index==1 and Color3.fromRGB(161,123,86) or Color3.fromRGB(62,83,105)
        lockerBank(root,index==1 and "Lower hall cubby bank" or "Upper hall locker bank",Vector3.new(22.2,floorY,-126),-1,storageTint)
        lockerBank(root,index==1 and "Lower hall cubby bank" or "Upper hall locker bank",Vector3.new(-22.2,floorY,-56),1,storageTint)
        framedHallPanel(root,index==1 and "Hall welcome gallery" or "Hall student gallery",
            index==1 and "WELCOME\nYOU BELONG HERE" or index==2 and "STUDENT WORK\nEFFORT • GROWTH • KINDNESS" or "ABVM VALUES\nLEAD • SERVE • BELIEVE",
            CFrame.new(22.78,floorY+8,-87)*CFrame.Angles(0,-math.pi/2,0),Vector3.new(15,6,.18),index==2 and palette.green or palette.navy)
        World.part(root,"Hall baseboard west",Vector3.new(.24,.55,95),CFrame.new(-22.82,floorY+.48,-92),Color3.fromRGB(117,88,65),Enum.Material.Wood,false)
        World.part(root,"Hall baseboard east",Vector3.new(.24,.55,95),CFrame.new(22.82,floorY+.48,-92),Color3.fromRGB(117,88,65),Enum.Material.Wood,false)
        World.part(root,"Water fountain body",Vector3.new(2.8,3.4,1.5),CFrame.new(20.9,floorY+1.8,-51),Color3.fromRGB(173,181,184),Enum.Material.Metal,false)
        World.part(root,"Water fountain basin",Vector3.new(2.5,.35,2.1),CFrame.new(20.9,floorY+3.45,-50.6),Color3.fromRGB(206,213,214),Enum.Material.Metal,false)
        local hallArt=sign(root,index==1 and "WELCOME TO ABVM\nFAITH • LEARNING • SERVICE" or index==2 and "STUDENT SPOTLIGHT\nCREATE • LEARN • GROW" or "LEAD WITH KINDNESS\nWORK HARD • SERVE OTHERS",
            CFrame.new(-22.85,floorY+8,-88)*CFrame.Angles(0,math.pi/2,0),Vector3.new(17,6,.2),index==2 and palette.green or palette.navy,palette.gold)
        hallArt.Name="Hall framed display"

        for _,zPos in ipairs({-130,-108,-86,-64,-44}) do
            local hallLight=World.part(root,"Hall ceiling light",Vector3.new(8,.24,1.4),CFrame.new(0,floorY+13.2,zPos),Color3.fromRGB(248,241,211),Enum.Material.Neon,false)
            local hallGlow=Instance.new("SurfaceLight");hallGlow.Face=Enum.NormalId.Bottom;hallGlow.Brightness=.52;hallGlow.Range=20;hallGlow.Angle=120;hallGlow.Parent=hallLight
        end
        sign(root,"FLOOR "..tostring(index),CFrame.new(0,floorY+8,-141.6),Vector3.new(12,2.5,.2),palette.navy,palette.gold)
        if index==1 then
            sign(root,"MAIN OFFICE  ←\nMATH  ←     →  READING",CFrame.new(0,floorY+9,-78),Vector3.new(22,4,.2),palette.green,palette.cream)
        elseif index==2 then
            sign(root,"GRAMMAR  ←     →  RELIGION",CFrame.new(0,floorY+9,-78),Vector3.new(22,3,.2),palette.green,palette.cream)
        else
            sign(root,"VOCABULARY  ←     →  SPELLING",CFrame.new(0,floorY+9,-78),Vector3.new(24,3,.2),palette.green,palette.cream)
        end
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
    World.part(root,"Second floor stair guard",Vector3.new(13,3,.3),CFrame.new(-7,21.7,-109.3),palette.metal,Enum.Material.Metal,false)
    stairFlight(root,7,-118,-75,21,35.4)
    World.part(root,"Third floor stair landing",Vector3.new(13,.6,9),CFrame.new(7,36,-71),palette.stone,Enum.Material.Concrete)
    World.part(root,"Third floor stair guard",Vector3.new(13,3,.3),CFrame.new(7,37.7,-66.7),palette.metal,Enum.Material.Metal,false)
    World.part(root,"Second stair landing mat",Vector3.new(11,.12,7),CFrame.new(-7,20.38,-105),palette.navy,Enum.Material.Fabric,false)
    World.part(root,"Third stair landing mat",Vector3.new(11,.12,7),CFrame.new(7,36.38,-71),palette.navy,Enum.Material.Fabric,false)
    local stairLight2=ceilingLight(root,Vector3.new(-7,31.8,-105),Vector3.new(5,.24,1.5),.6,17);stairLight2.Name="Stair landing light"
    local stairLight3=ceilingLight(root,Vector3.new(7,47.8,-71),Vector3.new(5,.24,1.5),.6,17);stairLight3.Name="Stair landing light"

    -- Main lobby/admin suite.
    sign(root,"ASSUMPTION BVM CATHOLIC SCHOOL\nFaith • Education • Community",CFrame.new(0,12,-39)*CFrame.Angles(0,math.pi,0),Vector3.new(42,7,.25),palette.navy,palette.gold)
    crest(root,"Lobby ABVM crest",CFrame.new(0,18,-39)*CFrame.Angles(0,math.pi,0),7)

    -- Lobby now reads as a finished school entrance instead of exposed base geometry.
    World.part(root,"Lobby acoustic ceiling",Vector3.new(136,.3,37),CFrame.new(0,17.85,-56),Color3.fromRGB(245,243,236),Enum.Material.SmoothPlastic,false)
    for _,x in ipairs({-48,-24,0,24,48}) do
        World.part(root,"Lobby ceiling beam",Vector3.new(.12,.08,36),CFrame.new(x,17.65,-56),Color3.fromRGB(203,204,200),Enum.Material.Metal,false)
    end
    World.part(root,"Lobby terrazzo floor",Vector3.new(136,.14,38),CFrame.new(0,4.43,-56),Color3.fromRGB(228,225,216),Enum.Material.SmoothPlastic,false)
    World.part(root,"Lobby navy inlay",Vector3.new(4,.05,36),CFrame.new(0,4.52,-56),palette.navy,nil,false)
    for _,x in ipairs({-2.35,2.35}) do World.part(root,"Lobby gold inlay",Vector3.new(.24,.055,36),CFrame.new(x,4.53,-56),palette.gold,nil,false) end
    World.part(root,"Lobby welcome rug",Vector3.new(24,.14,7.5),CFrame.new(0,4.57,-42.5),palette.navy,Enum.Material.Fabric,false)
    World.part(root,"Lobby rug gold stripe",Vector3.new(21,.04,.32),CFrame.new(0,4.66,-42.5),palette.gold,nil,false)
    for _,x in ipairs({-13,0,13}) do
        local fixture=ceilingLight(root,Vector3.new(x,17.7,-52),Vector3.new(5.5,.3,2.1),.7,22)
        fixture.Name="Lobby ceiling light"
    end
    -- A compact but real admin suite rather than labels floating in the lobby.
    World.part(root,"Main Office rear wall",Vector3.new(51,11,1),CFrame.new(-49,9.5,-72),palette.cream)
    World.part(root,"Main Office west wall",Vector3.new(1,11,27),CFrame.new(-74,9.5,-58.5),palette.cream)
    World.part(root,"Principal partition",Vector3.new(1,11,18),CFrame.new(-45,9.5,-63),palette.cream)
    World.part(root,"Assistant partition",Vector3.new(1,11,18),CFrame.new(-29,9.5,-63),palette.cream)
    -- Keep broad openings on the lobby side for mobile traversal.
    World.part(root,"Main Office counter",Vector3.new(27,3.5,4),CFrame.new(-59,6,-48),palette.wood,Enum.Material.Wood)
    World.part(root,"Lobby reception front",Vector3.new(24,2.65,.28),CFrame.new(-59,6.1,-45.85),palette.navy,Enum.Material.SmoothPlastic,false)
    World.part(root,"Lobby reception gold band",Vector3.new(24,.2,.34),CFrame.new(-59,6.95,-45.68),palette.gold,Enum.Material.Metal,false)
    crest(root,"Reception crest",CFrame.new(-59,6.1,-45.5)*CFrame.Angles(0,math.pi,0),3.4)
    World.part(root,"Office waiting bench",Vector3.new(10,1.1,2.6),CFrame.new(-28,5,-49),Color3.fromRGB(103,117,130),Enum.Material.Fabric)
    World.part(root,"Office waiting bench back",Vector3.new(10,2.2,.42),CFrame.new(-28,6,-50.1),Color3.fromRGB(91,105,119),Enum.Material.Fabric,false)
    World.part(root,"Principal desk",Vector3.new(10,2.2,4),CFrame.new(-37,5.3,-65),palette.wood,Enum.Material.Wood)
    World.part(root,"Assistant desk",Vector3.new(10,2.2,4),CFrame.new(-21,5.3,-65),palette.wood,Enum.Material.Wood)
    World.part(root,"Main Office runner",Vector3.new(43,.12,18),CFrame.new(-49,4.55,-60),Color3.fromRGB(54,72,95),Enum.Material.Fabric,false)
    World.part(root,"Office coffee table",Vector3.new(6,1.6,3.2),CFrame.new(-28,5,-54),palette.wood,Enum.Material.Wood)
    World.part(root,"Office magazine stack",Vector3.new(2.8,.45,2),CFrame.new(-28,6.05,-54),palette.gold,Enum.Material.SmoothPlastic,false)
    for _,entry in ipairs({{-37,-65},{-21,-65},{-59,-50}}) do
        World.part(root,"Office monitor base",Vector3.new(3.2,.18,1.8),CFrame.new(entry[1],6.55,entry[2]),Color3.fromRGB(75,81,87),Enum.Material.Metal,false)
        World.part(root,"Office monitor",Vector3.new(3.3,2.3,.2),CFrame.new(entry[1],7.7,entry[2]-.8),Color3.fromRGB(73,100,113),Enum.Material.Glass,false)
    end
    interiorPlant(root,"Office plant",Vector3.new(-69,4,-68))
    sign(root,"MAIN OFFICE",CFrame.new(-59,10,-45.8)*CFrame.Angles(0,math.pi,0),Vector3.new(20,3,.2),palette.green,palette.gold)
    sign(root,"Secretary — Mrs. Thompson",CFrame.new(-59,8.6,-53)*CFrame.Angles(0,math.pi,0),Vector3.new(19,2.5,.2),palette.navy,palette.cream)
    sign(root,"Principal — Dr. McBreen",CFrame.new(-37,9,-72.55)*CFrame.Angles(0,0,0),Vector3.new(16,2.6,.2),palette.navy,palette.cream)
    sign(root,"Assistant Principal — Mrs. Boyer",CFrame.new(-21,9,-72.55)*CFrame.Angles(0,0,0),Vector3.new(18,2.6,.2),palette.navy,palette.cream)
    cross(root,CFrame.new(-37,13,-71.5),.35,palette.gold)
    cross(root,CFrame.new(-21,13,-71.5),.35,palette.gold)
    npc(root,"Mrs. Thompson — Secretary",Vector3.new(-59,4,-52),false,Color3.fromRGB(86,125,143))
    npc(root,"Dr. McBreen — Principal",Vector3.new(-37,4,-61),true,palette.navy)
    npc(root,"Mrs. Boyer — Assistant Principal",Vector3.new(-21,4,-61),false,Color3.fromRGB(89,111,132))

    -- Small lobby identity details: trophy case and bulletin board keep the entry recognizably school-like.
    local trophyGlass=World.part(root,"Lobby trophy case glass",Vector3.new(17,8,.7),CFrame.new(25,8,-42),Color3.fromRGB(153,184,193),Enum.Material.Glass,false)
    trophyGlass.Transparency=.45
    World.part(root,"Lobby trophy case base",Vector3.new(18,1.2,2),CFrame.new(25,4.7,-42),palette.wood,Enum.Material.Wood)
    World.part(root,"Trophy case backing",Vector3.new(18,8,.28),CFrame.new(25,8,-42.5),palette.navy,Enum.Material.SmoothPlastic,false)
    World.part(root,"Trophy case top frame",Vector3.new(18.8,.55,1.2),CFrame.new(25,12.1,-42),palette.wood,Enum.Material.Wood,false)
    for _,x in ipairs({15.8,34.2}) do World.part(root,"Trophy case side frame",Vector3.new(.55,8.6,1.2),CFrame.new(x,8,-42),palette.wood,Enum.Material.Wood,false) end
    for _,y in ipairs({6.5,9.2}) do World.part(root,"Trophy case shelf",Vector3.new(17.4,.2,1.3),CFrame.new(25,y,-41.7),palette.wood,Enum.Material.Wood,false) end
    local trophyLight=ceilingLight(root,Vector3.new(25,12.5,-41.2),Vector3.new(7,.22,1),.5,10);trophyLight.Name="Trophy case light"
    for _,x in ipairs({20,25,30}) do
        World.part(root,"Trophy stem",Vector3.new(.4,2,.4),CFrame.new(x,7,-41.5),palette.gold,nil,false)
        local cup=World.part(root,"Trophy cup",Vector3.new(1.7,1.4,1.2),CFrame.new(x,8.5,-41.5),palette.gold,nil,false)
        cup.Shape=Enum.PartType.Ball
    end
    sign(root,"ASSUMPTION BVM\nFAITH • SERVICE • LEARNING",CFrame.new(-17,9,-41.8)*CFrame.Angles(0,math.pi,0),Vector3.new(24,5,.2),palette.green,palette.gold)
    framedHallPanel(root,"Lobby mission frame","SMALL SCHOOL\nBIG MISSION",CFrame.new(8,9,-41.75)*CFrame.Angles(0,math.pi,0),Vector3.new(14,5,.18),palette.navy)
    interiorPlant(root,"Lobby east plant",Vector3.new(63,4,-43))
    interiorPlant(root,"Lobby west plant",Vector3.new(-66,4,-43))
    sign(root,"SCHOOL INFO",CFrame.new(44,13.1,-41.8)*CFrame.Angles(0,math.pi,0),Vector3.new(17,2.4,.2),palette.navy,palette.gold)
    sign(root,"1  MAIN OFFICE • MATH • READING",CFrame.new(44,10.4,-41.8)*CFrame.Angles(0,math.pi,0),Vector3.new(31,2.2,.2),palette.green,palette.cream)
    sign(root,"2  GRAMMAR • RELIGION",CFrame.new(44,8,-41.8)*CFrame.Angles(0,math.pi,0),Vector3.new(31,2.2,.2),palette.navy,palette.cream)
    sign(root,"3  VOCABULARY • SPELLING",CFrame.new(44,5.6,-41.8)*CFrame.Angles(0,math.pi,0),Vector3.new(31,2.2,.2),palette.navy,palette.cream)

    -- Three framed ABVM leaderboards on the lobby's east wall.
    World.leaderboardParts={
        accuracy=World.part(root,"Accuracy leaderboard",Vector3.new(23,9,.45),CFrame.new(68.8,9.5,-46)*CFrame.Angles(0,-math.pi/2,0),palette.navy,nil,false),
        questions=World.part(root,"Questions leaderboard",Vector3.new(23,9,.45),CFrame.new(68.8,9.5,-58)*CFrame.Angles(0,-math.pi/2,0),palette.navy,nil,false),
        credits=World.part(root,"Credits leaderboard",Vector3.new(23,9,.45),CFrame.new(68.8,9.5,-70)*CFrame.Angles(0,-math.pi/2,0),palette.navy,nil,false),
    }
    for _,z in ipairs({-46,-58,-70}) do
        World.part(root,"Leaderboard gold top trim",Vector3.new(.5,.35,23.7),CFrame.new(68.55,14.15,z)*CFrame.Angles(0,-math.pi/2,0),palette.gold,Enum.Material.Metal,false)
        World.part(root,"Leaderboard gold bottom trim",Vector3.new(.5,.35,23.7),CFrame.new(68.55,4.85,z)*CFrame.Angles(0,-math.pi/2,0),palette.gold,Enum.Material.Metal,false)
    end
    sign(root,"★  ABVM SCHOOL LEADERS  ★",CFrame.new(68.45,16.5,-58)*CFrame.Angles(0,-math.pi/2,0),Vector3.new(34,3,.3),palette.green,palette.gold)

    -- School shop remains one of the few non-class destinations and stays inside the school.
    World.shopPosition=Vector3.new(31,5,-49)
    World.part(root,"ABVM Shop counter",Vector3.new(28,3.5,4),CFrame.new(31,6,-48),palette.wood,Enum.Material.Wood)
    local sp=sign(root,"ABVM SCHOOL SHOP",CFrame.new(31,10,-45.8)*CFrame.Angles(0,math.pi,0),Vector3.new(25,3,.2),palette.green,palette.gold)
    local prompt=Instance.new("ProximityPrompt");prompt.ActionText="Browse";prompt.ObjectText="ABVM School Shop";prompt.MaxActivationDistance=16;prompt.RequiresLineOfSight=false;prompt.HoldDuration=0;prompt.Parent=sp
    World.shopPrompt=prompt

    -- Physical display cues mirror the four shop tabs without creating a second purchase authority.
    World.part(root,"Shop back wall",Vector3.new(42,11,1),CFrame.new(40,9.5,-62),palette.cream)
    sign(root,"CLOTHES",CFrame.new(23,12,-61.4),Vector3.new(12,2.4,.2),palette.navy,palette.gold)
    World.part(root,"Shop clothes rail",Vector3.new(12,.35,.35),CFrame.new(23,8,-60),palette.metal,Enum.Material.Metal,false)
    for _,x in ipairs({19,23,27}) do
        World.part(root,"Shop jacket",Vector3.new(3,4,.7),CFrame.new(x,6.2,-60),x==23 and palette.green or palette.navy,Enum.Material.Fabric,false)
        World.part(root,"Shop jacket trim",Vector3.new(.2,3.8,.78),CFrame.new(x,6.2,-60.4),palette.gold,nil,false)
    end

    sign(root,"HOME",CFrame.new(35,12,-61.4),Vector3.new(10,2.4,.2),palette.navy,palette.gold)
    World.part(root,"Shop home pedestal",Vector3.new(10,1,8),CFrame.new(35,4.7,-58),palette.stone,Enum.Material.Concrete)
    World.part(root,"Shop home model",Vector3.new(7,4,6),CFrame.new(35,7,-58),Color3.fromRGB(215,205,183),Enum.Material.SmoothPlastic,false)
    World.part(root,"Shop home roof",Vector3.new(7.8,.5,6.8),CFrame.new(35,9.2,-58),palette.navy,Enum.Material.Slate,false)

    sign(root,"ITEMS",CFrame.new(47,12,-61.4),Vector3.new(10,2.4,.2),palette.navy,palette.gold)
    World.part(root,"Shop item shelf",Vector3.new(10,4,.8),CFrame.new(47,6.2,-60),palette.wood,Enum.Material.Wood)
    World.part(root,"Shop display lamp",Vector3.new(.45,3,.45),CFrame.new(44.5,8,-59.3),palette.gold,nil,false)
    World.part(root,"Shop display books",Vector3.new(3.8,2.3,.8),CFrame.new(48,7.5,-59.3),palette.green,Enum.Material.SmoothPlastic,false)

    sign(root,"RIDES",CFrame.new(58,12,-61.4),Vector3.new(10,2.4,.2),palette.navy,palette.gold)
    World.part(root,"Shop ride poster",Vector3.new(9,5,.2),CFrame.new(58,8,-61.2),palette.navy,nil,false)
    World.part(root,"Shop ride body",Vector3.new(6,.9,.35),CFrame.new(58,8,-61),palette.gold,nil,false)
    for _,x in ipairs({55.5,60.5}) do
        local wheel=World.part(root,"Shop ride wheel",Vector3.new(.45,1.4,1.4),CFrame.new(x,6.9,-60.8),Color3.fromRGB(40,45,50),nil,false)
        wheel.Shape=Enum.PartType.Cylinder
    end

    -- Player-owned neighborhood lots continue south of the school.
    for i=1,24 do
        local side=i%2==1 and -1 or 1
        local row=math.ceil(i/2)
        local x,z=side*72,72+(row-1)*90
        local cf=CFrame.new(x,0,z)*CFrame.Angles(0,side<0 and math.pi/2 or -math.pi/2,0)
        World.plots[i]={cf=cf,door=cf*CFrame.new(0,4,25),drive=CFrame.new(side*8,1.65,z+27),owner=nil}
        World.part(root,"Residential lot "..i,Vector3.new(79,.25,76),CFrame.new(x,.13,z),Color3.fromRGB(141,171,127),Enum.Material.Grass)
        sign(root,string.format("%02d",i),cf*CFrame.new(-31,3.2,31)*CFrame.Angles(0,math.pi,0),Vector3.new(5,3,.25),palette.navy,palette.gold)
        tree(root,side*119,z-20,.85)
    end

    local spawn=Instance.new("SpawnLocation")
    local arrivalPosition=Vector3.new(59,3,30)
    local arrivalFocus=Vector3.new(17,12,-36)
    local arrivalCf=CFrame.lookAt(arrivalPosition,arrivalFocus)
    spawn.Name="SchoolArrival";spawn.Size=Vector3.new(8,1,8);spawn.CFrame=arrivalCf;spawn.Transparency=1;spawn.CanCollide=false;spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=root
    -- School travel intentionally lands at the same front-right hero angle as the approved render:
    -- facade centered, sign on the left, east corner/side elevation visible on the right.
    World.schoolDoor=arrivalCf
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
        for _,x in ipairs({-width/2+3,width/2-3}) do
            p("Terrace trim",Vector3.new(.5,2.5,depth-2),Vector3.new(x,16,0),palette.gold,nil,false)
        end
        for step=0,14 do
            p("Terrace stair",Vector3.new(5,.55,2.2),Vector3.new(width/2+4,1+step*.96,14-step*2),palette.cream)
        end
        p("Terrace access",Vector3.new(10,.6,5),Vector3.new(width/2+.5,14.5,-14),palette.cream)
    end
    if stage==3 then
        local upperWidth=width-12
        local upperDepth=depth-12
        p("Suburban upper floor",Vector3.new(upperWidth,8.5,upperDepth),Vector3.new(0,18.8,-2),color(item.color))
        p("Suburban upper roof",Vector3.new(upperWidth+2,.8,upperDepth+2),Vector3.new(0,23.5,-2),palette.navy,Enum.Material.Slate)
        for _,x in ipairs({-upperWidth/4,upperWidth/4}) do
            local upperWindow=p("Suburban upper window",Vector3.new(7,4,.18),Vector3.new(x,19.1,-2+upperDepth/2+.12),Color3.fromRGB(150,198,210),Enum.Material.Glass,false)
            upperWindow.Transparency=.18
            p("Suburban upper window trim",Vector3.new(7.8,.35,.35),Vector3.new(x,16.9,-2+upperDepth/2+.3),palette.cream,nil,false)
        end
    elseif stage>=4 then
        p("Upper pavilion",Vector3.new(width-12,8,depth-14),Vector3.new(0,18,-3),palette.cream)
        local glazing=p("Pavilion glazing",Vector3.new(width-16,5,.3),Vector3.new(0,18,(depth-14)/2-2.7),Color3.fromRGB(147,187,201),Enum.Material.Glass,false)
        glazing.Transparency=.15
        p("Upper roof",Vector3.new(width-9,.7,depth-11),Vector3.new(0,22.4,-3),palette.navy)
        for _,x in ipairs({-width/2+8,width/2-8}) do
            p("Modern upper column",Vector3.new(.6,8,.6),Vector3.new(x,18,(depth-14)/2-2.5),palette.gold,nil,false)
        end
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
