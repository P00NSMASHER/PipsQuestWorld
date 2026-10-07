--!strict
local Workspace=game:GetService("Workspace")
local Lighting=game:GetService("Lighting")
local World={}

local function part(parent,name,size,cf,color,material,collide)
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
    p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
    p.CanCollide=collide~=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end

local function label(partObject,text,face,textColor,bg)
    local gui=Instance.new("SurfaceGui");gui.Face=face or Enum.NormalId.Front;gui.CanvasSize=Vector2.new(900,300);gui.Parent=partObject
    local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundColor3=bg or Color3.fromRGB(245,238,208)
    t.BackgroundTransparency=.08;t.TextColor3=textColor or Color3.fromRGB(31,73,54);t.Font=Enum.Font.GothamBold
    t.TextScaled=true;t.TextWrapped=true;t.Text=text;t.Parent=gui
    local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,25);pad.PaddingRight=UDim.new(0,25);pad.PaddingTop=UDim.new(0,12);pad.PaddingBottom=UDim.new(0,12);pad.Parent=t
end

local function desk(parent,x,z)
    part(parent,"Student desk top",Vector3.new(6,.45,4),CFrame.new(x,2.9,z),Color3.fromRGB(171,126,83),Enum.Material.Wood)
    for _,dx in ipairs({-2.5,2.5}) do part(parent,"Desk leg",Vector3.new(.3,2.6,.3),CFrame.new(x+dx,1.4,z),Color3.fromRGB(72,78,83),Enum.Material.Metal) end
    part(parent,"Chair seat",Vector3.new(2.8,.45,2.5),CFrame.new(x,1.55,z+4),Color3.fromRGB(47,83,112),Enum.Material.SmoothPlastic)
    part(parent,"Chair back",Vector3.new(2.8,2.8,.4),CFrame.new(x,2.9,z+5.1),Color3.fromRGB(47,83,112),Enum.Material.SmoothPlastic)
end

function World.build()
    local old=Workspace:FindFirstChild("EmmaStudyWorld");if old then old:Destroy() end
    local root=Instance.new("Folder");root.Name="EmmaStudyWorld";root.Parent=Workspace
    Lighting.ClockTime=10.5;Lighting.Brightness=2.35;Lighting.GlobalShadows=true;Lighting.ShadowSoftness=.35
    Lighting.Ambient=Color3.fromRGB(155,151,142);Lighting.OutdoorAmbient=Color3.fromRGB(184,185,178)

    local floor=part(root,"Dark wood classroom floor",Vector3.new(74,1,62),CFrame.new(0,0,-4),Color3.fromRGB(88,65,48),Enum.Material.WoodPlanks)
    part(root,"Front wall",Vector3.new(74,18,1),CFrame.new(0,9,-35),Color3.fromRGB(239,225,146))
    part(root,"Back wall left",Vector3.new(28,18,1),CFrame.new(-23,9,27),Color3.fromRGB(239,225,146))
    part(root,"Back wall right",Vector3.new(28,18,1),CFrame.new(23,9,27),Color3.fromRGB(239,225,146))
    part(root,"Door header",Vector3.new(18,8,1),CFrame.new(0,14,27),Color3.fromRGB(239,225,146))
    part(root,"Left wall",Vector3.new(1,18,62),CFrame.new(-37,9,-4),Color3.fromRGB(239,225,146))
    part(root,"Right wall",Vector3.new(1,18,62),CFrame.new(37,9,-4),Color3.fromRGB(239,225,146))
    part(root,"Ceiling",Vector3.new(74,.5,62),CFrame.new(0,18,-4),Color3.fromRGB(242,241,235),Enum.Material.SmoothPlastic)

    -- Blue trim and old-school built-ins from the real classroom photos.
    for _,z in ipairs({-34.3,26.3}) do part(root,"Blue baseboard",Vector3.new(73,.7,.35),CFrame.new(0,.55,z),Color3.fromRGB(55,73,108),Enum.Material.Wood,false) end
    for _,x in ipairs({-36.3,36.3}) do part(root,"Blue baseboard",Vector3.new(.35,.7,61),CFrame.new(x,.55,-4),Color3.fromRGB(55,73,108),Enum.Material.Wood,false) end
    part(root,"Built in cubbies",Vector3.new(30,7,2.5),CFrame.new(-19,3.7,25.3),Color3.fromRGB(141,102,67),Enum.Material.Wood)
    for i=0,6 do part(root,"Cubby dark opening",Vector3.new(3.2,2.4,.25),CFrame.new(-31+i*4,4.7,23.95),Color3.fromRGB(66,55,46),Enum.Material.SmoothPlastic,false) end

    -- Chalkboard + smartboard.
    part(root,"Chalkboard",Vector3.new(39,8,.4),CFrame.new(4,8.2,-34.25),Color3.fromRGB(43,47,45),Enum.Material.SmoothPlastic,false)
    part(root,"Chalkboard top wood",Vector3.new(40,.5,.6),CFrame.new(4,12.45,-34.15),Color3.fromRGB(112,78,50),Enum.Material.Wood,false)
    part(root,"Chalkboard tray",Vector3.new(28,.45,1),CFrame.new(4,4,-33.7),Color3.fromRGB(112,78,50),Enum.Material.Wood,false)
    local smart=part(root,"Smartboard",Vector3.new(22,6.2,.3),CFrame.new(8,8.2,-33.75),Color3.fromRGB(238,243,241),Enum.Material.Glass,false);smart.Transparency=.04
    label(smart,"EMMA'S STUDY CLASSROOM\nYou can do hard things!",Enum.NormalId.Front,Color3.fromRGB(33,64,94),Color3.fromRGB(240,244,242))
    local cross=part(root,"Classroom cross",Vector3.new(1.1,5,.45),CFrame.new(-28,10,-34),Color3.fromRGB(104,72,46),Enum.Material.Wood,false)
    part(root,"Classroom crossbar",Vector3.new(3.5,1,.45),CFrame.new(-28,10.8,-33.8),Color3.fromRGB(104,72,46),Enum.Material.Wood,false)

    -- Two big window bays, curtains, radiators.
    for _,z in ipairs({-17,5}) do
        local glass=part(root,"Window glass",Vector3.new(.25,7.5,13),CFrame.new(-36.45,9,z),Color3.fromRGB(202,226,234),Enum.Material.Glass,false);glass.Transparency=.15
        for _,dz in ipairs({-4.2,0,4.2}) do part(root,"Window mullion",Vector3.new(.35,7.8,.25),CFrame.new(-36.2,9,z+dz),Color3.fromRGB(106,76,52),Enum.Material.Wood,false) end
        part(root,"Window curtain",Vector3.new(.3,1.6,14),CFrame.new(-35.9,13,z),Color3.fromRGB(113,135,164),Enum.Material.Fabric,false)
        part(root,"Radiator",Vector3.new(1.5,3,11),CFrame.new(-35.2,1.7,z),Color3.fromRGB(176,180,177),Enum.Material.Metal,false)
    end

    -- Teacher desk and student desks. No giant map, no mall, no house, no vehicle circus.
    part(root,"Teacher desk",Vector3.new(12,3,5),CFrame.new(23,2,-26),Color3.fromRGB(151,109,72),Enum.Material.Wood)
    for _,x in ipairs({-22,-8,8,22}) do for _,z in ipairs({-15,2,19}) do desk(root,x,z) end end

    -- Colorful simple rugs.
    local rug=part(root,"Alphabet rug",Vector3.new(.18,18,18),CFrame.new(-19,.6,-25)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(61,111,163),Enum.Material.Fabric,false);rug.Shape=Enum.PartType.Cylinder
    for i=1,12 do
        local a=(i-1)*math.pi*2/12
        local d=part(root,"Rug color dot",Vector3.new(.12,2.2,2.2),CFrame.new(-19+math.cos(a)*6.6,.7,-25+math.sin(a)*6.6)*CFrame.Angles(0,0,math.pi/2),Color3.fromHSV((i-1)/12,.55,.95),Enum.Material.Fabric,false);d.Shape=Enum.PartType.Cylinder
    end

    -- Doorway and tiny hallway pocket. Teachers enter from here.
    part(root,"Hall floor",Vector3.new(18,.5,18),CFrame.new(0,.25,36),Color3.fromRGB(69,69,66),Enum.Material.Slate)
    part(root,"Hall left wall",Vector3.new(1,13,18),CFrame.new(-9,6.5,36),Color3.fromRGB(101,132,147))
    part(root,"Hall right wall",Vector3.new(1,13,18),CFrame.new(9,6.5,36),Color3.fromRGB(101,132,147))
    part(root,"Hall left brick",Vector3.new(1.1,4,18),CFrame.new(-8.5,2,36),Color3.fromRGB(177,122,63),Enum.Material.Brick,false)
    part(root,"Hall right brick",Vector3.new(1.1,4,18),CFrame.new(8.5,2,36),Color3.fromRGB(177,122,63),Enum.Material.Brick,false)
    part(root,"Hall ceiling",Vector3.new(18,.4,18),CFrame.new(0,13,36),Color3.fromRGB(224,226,223),Enum.Material.SmoothPlastic,false)

    for _,x in ipairs({-20,0,20}) do
        for _,z in ipairs({-20,5,20}) do
            local light=part(root,"Ceiling light",Vector3.new(7,.25,2),CFrame.new(x,17.7,z),Color3.fromRGB(248,244,218),Enum.Material.Neon,false)
            local glow=Instance.new("SurfaceLight");glow.Face=Enum.NormalId.Bottom;glow.Brightness=.55;glow.Range=18;glow.Parent=light
        end
    end

    local spawn=Instance.new("SpawnLocation");spawn.Name="EmmaSeatSpawn";spawn.Size=Vector3.new(6,1,6);spawn.CFrame=CFrame.new(0,1,14)*CFrame.Angles(0,math.pi,0)
    spawn.Transparency=1;spawn.CanCollide=false;spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=root

    World.Root=root
    World.Spawn=spawn.CFrame
    World.TeacherDoor=CFrame.new(0,4,41)
    World.TeacherFront=CFrame.new(0,4,-21)*CFrame.Angles(0,math.pi,0)
    return World
end

function World.teacherModel(name,role,shirt)
    local m=Instance.new("Model");m.Name=name
    local c=Color3.fromRGB(shirt[1],shirt[2],shirt[3]);local skin=Color3.fromRGB(225,194,163)
    local root=part(m,"HumanoidRootPart",Vector3.new(2,2,1),CFrame.new(),Color3.new(1,1,1),Enum.Material.SmoothPlastic,false);root.Transparency=1
    part(m,"Torso",Vector3.new(3.5,4.4,2),CFrame.new(0,2.3,0),c,Enum.Material.Fabric,false)
    part(m,"Head",Vector3.new(2.5,2.5,2.5),CFrame.new(0,5.7,0),skin,Enum.Material.SmoothPlastic,false).Shape=Enum.PartType.Ball
    part(m,"Left Arm",Vector3.new(1,4,1),CFrame.new(-2.2,2.5,0),skin,Enum.Material.SmoothPlastic,false)
    part(m,"Right Arm",Vector3.new(1,4,1),CFrame.new(2.2,2.5,0),skin,Enum.Material.SmoothPlastic,false)
    part(m,"Left Leg",Vector3.new(1.2,3.8,1.2),CFrame.new(-.85,-1.6,0),Color3.fromRGB(53,57,62),Enum.Material.Fabric,false)
    part(m,"Right Leg",Vector3.new(1.2,3.8,1.2),CFrame.new(.85,-1.6,0),Color3.fromRGB(53,57,62),Enum.Material.Fabric,false)
    local gui=Instance.new("BillboardGui");gui.Name="TeacherName";gui.Size=UDim2.fromOffset(210,54);gui.StudsOffset=Vector3.new(0,7.8,0);gui.AlwaysOnTop=true;gui.Parent=root
    local txt=Instance.new("TextLabel");txt.Size=UDim2.fromScale(1,1);txt.BackgroundColor3=Color3.fromRGB(27,63,48);txt.BackgroundTransparency=.08
    txt.TextColor3=Color3.fromRGB(249,224,143);txt.TextScaled=true;txt.Text=name.."\n"..role;txt.Font=Enum.Font.GothamBold;txt.Parent=gui
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,10);corner.Parent=txt
    m.PrimaryPart=root
    return m
end

return World
