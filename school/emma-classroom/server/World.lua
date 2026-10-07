--!strict
local Workspace=game:GetService("Workspace")
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")

local World={}

local P={
    wall=Color3.fromRGB(241,226,150),
    blue=Color3.fromRGB(52,73,108),
    blueSoft=Color3.fromRGB(101,132,147),
    green=Color3.fromRGB(28,82,59),
    gold=Color3.fromRGB(238,203,99),
    wood=Color3.fromRGB(137,96,62),
    woodDark=Color3.fromRGB(83,61,47),
    ink=Color3.fromRGB(39,44,43),
    cream=Color3.fromRGB(248,245,232),
    metal=Color3.fromRGB(120,126,129),
}

local function part(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material?,collide: boolean?): Part
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
    p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
    p.CanCollide=collide~=false;p.CanTouch=collide~=false
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end

local function ball(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material?,collide: boolean?): Part
    local p=part(parent,name,size,cf,color,material,collide);p.Shape=Enum.PartType.Ball;return p
end

local function cylinder(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material?,collide: boolean?): Part
    local p=part(parent,name,size,cf,color,material,collide);p.Shape=Enum.PartType.Cylinder;return p
end

local function surfaceText(target: BasePart,text: string,face: Enum.NormalId,textColor: Color3,bg: Color3,font: Enum.Font?): TextLabel
    local gui=Instance.new("SurfaceGui")
    gui.Name="Surface";gui.Face=face;gui.CanvasSize=Vector2.new(1000,500);gui.LightInfluence=.15;gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;gui.Parent=target
    local t=Instance.new("TextLabel")
    t.Size=UDim2.fromScale(1,1);t.BackgroundColor3=bg;t.BackgroundTransparency=.04
    t.TextColor3=textColor;t.Font=font or Enum.Font.GothamBold;t.TextScaled=true;t.TextWrapped=true;t.Text=text;t.Parent=gui
    local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,32);pad.PaddingRight=UDim.new(0,32);pad.PaddingTop=UDim.new(0,18);pad.PaddingBottom=UDim.new(0,18);pad.Parent=t
    return t
end

local function sign(parent: Instance,name: string,text: string,size: Vector3,cf: CFrame,bg: Color3,fg: Color3): Part
    local p=part(parent,name,size,cf,bg,Enum.Material.SmoothPlastic,false)
    surfaceText(p,text,Enum.NormalId.Front,fg,bg)
    return p
end

local function ceilingLight(parent: Instance,x: number,z: number)
    local box=part(parent,"Recessed ceiling light",Vector3.new(7.6,.22,2.4),CFrame.new(x,17.72,z),Color3.fromRGB(255,249,220),Enum.Material.Neon,false)
    local light=Instance.new("SurfaceLight");light.Face=Enum.NormalId.Bottom;light.Brightness=.7;light.Range=20;light.Angle=105;light.Shadows=false;light.Parent=box
    part(parent,"Light trim",Vector3.new(8,.10,2.8),CFrame.new(x,17.80,z),Color3.fromRGB(205,207,202),Enum.Material.Metal,false)
end

local function plant(parent: Instance,x: number,y: number,z: number,scale: number)
    local pot=cylinder(parent,"Plant pot",Vector3.new(2.2*scale,1.8*scale,2.2*scale),CFrame.new(x,y+.9*scale,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(166,113,74),Enum.Material.SmoothPlastic,false)
    pot.CFrame*=CFrame.Angles(0,0,math.pi/2)
    for _,o in ipairs({
        Vector3.new(0,2.6,0),Vector3.new(-.8,2.3,.2),Vector3.new(.8,2.4,-.2),
        Vector3.new(-.45,3.1,-.2),Vector3.new(.4,3.25,.3),
    }) do
        local leaf=ball(parent,"Plant leaf",Vector3.new(1.5,2.3,.75)*scale,CFrame.new(x,y,z)*CFrame.new(o*scale),Color3.fromRGB(62,126,72),Enum.Material.Grass,false)
        leaf.CFrame*=CFrame.Angles(0,0,math.rad((o.X or 0)*20))
    end
end

local function book(parent: Instance,x: number,y: number,z: number,color: Color3,rotation: number)
    part(parent,"Classroom book",Vector3.new(2.4,.32,3.2),CFrame.new(x,y,z)*CFrame.Angles(0,rotation,0),color,Enum.Material.SmoothPlastic,false)
    part(parent,"Book pages",Vector3.new(2.15,.16,2.95),CFrame.new(x,y+.18,z)*CFrame.Angles(0,rotation,0),Color3.fromRGB(238,232,211),Enum.Material.SmoothPlastic,false)
end

local function pencilCup(parent: Instance,x: number,y: number,z: number)
    cylinder(parent,"Pencil cup",Vector3.new(1.3,1.6,1.3),CFrame.new(x,y,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(187,192,194),Enum.Material.Metal,false)
    local colors={Color3.fromRGB(229,184,57),Color3.fromRGB(211,73,64),Color3.fromRGB(65,126,182),Color3.fromRGB(57,142,88)}
    for i,c in ipairs(colors) do
        part(parent,"Pencil",Vector3.new(.16,2.2,.16),CFrame.new(x-.35+i*.18,y+1.25,z),c,Enum.Material.Wood,false)
    end
end

local function schoolChair(parent: Instance,name: string,x: number,z: number,tint: Color3)
    part(parent,name.." seat",Vector3.new(2.9,.42,2.55),CFrame.new(x,1.55,z),tint,Enum.Material.SmoothPlastic)
    part(parent,name.." back",Vector3.new(2.9,2.65,.38),CFrame.new(x,2.9,z+1.05),tint,Enum.Material.SmoothPlastic)
    for _,dx in ipairs({-.95,.95}) do
        part(parent,name.." leg",Vector3.new(.22,1.55,.22),CFrame.new(x+dx,.78,z),P.metal,Enum.Material.Metal)
        part(parent,name.." back support",Vector3.new(.20,2.75,.20),CFrame.new(x+dx,2.65,z+.82),P.metal,Enum.Material.Metal,false)
    end
end

local function desk(parent: Instance,x: number,z: number,index: number,emma: boolean)
    part(parent,"Student desk top",Vector3.new(7,.48,4.6),CFrame.new(x,3,z),Color3.fromRGB(177,132,85),Enum.Material.Wood)
    part(parent,"Desk front lip",Vector3.new(6.8,.75,.35),CFrame.new(x,2.7,z-2.12),Color3.fromRGB(137,96,65),Enum.Material.Wood,false)
    for _,dx in ipairs({-2.8,2.8}) do
        part(parent,"Desk leg",Vector3.new(.28,2.75,.28),CFrame.new(x+dx,1.5,z),Color3.fromRGB(76,82,86),Enum.Material.Metal)
        part(parent,"Desk foot",Vector3.new(1.0,.18,3.6),CFrame.new(x+dx,.18,z),Color3.fromRGB(76,82,86),Enum.Material.Metal)
    end
    schoolChair(parent,"Student chair",x,z+4.4,emma and Color3.fromRGB(55,90,127) or Color3.fromRGB(48,77,107))
    local notebookColor=({Color3.fromRGB(217,91,104),Color3.fromRGB(63,130,181),Color3.fromRGB(98,150,101),Color3.fromRGB(220,173,66)})[(index-1)%4+1]
    book(parent,x-1.2,3.36,z-.2,notebookColor,math.rad(index%2==0 and 5 or -5))
    part(parent,"Desk pencil",Vector3.new(.14,.14,2.2),CFrame.new(x+1.4,3.42,z-.6)*CFrame.Angles(0,math.rad(18),0),Color3.fromRGB(239,190,56),Enum.Material.Wood,false)
    if emma then
        local tag=part(parent,"Emma desk nameplate",Vector3.new(3.8,.55,.16),CFrame.new(x,3.42,z-2.33)*CFrame.Angles(math.rad(-10),0,0),P.green,Enum.Material.SmoothPlastic,false)
        surfaceText(tag,"★ EMMA ★",Enum.NormalId.Front,P.gold,P.green)
        cylinder(parent,"Emma pink water bottle",Vector3.new(1.3,3.2,1.3),CFrame.new(x+2.45,4.55,z+.45)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(225,125,154),Enum.Material.SmoothPlastic,false)
        part(parent,"Water bottle cap",Vector3.new(.75,.35,.75),CFrame.new(x+2.45,6.2,z+.45),Color3.fromRGB(190,86,124),Enum.Material.SmoothPlastic,false)
    end
end

local function buildCubbies(root: Instance)
    part(root,"Cubbies wood surround",Vector3.new(27,8,3),CFrame.new(21,4.2,25.2),Color3.fromRGB(142,103,68),Enum.Material.Wood)
    local binColors={
        Color3.fromRGB(67,129,183),Color3.fromRGB(229,112,103),Color3.fromRGB(97,150,90),
        Color3.fromRGB(233,182,67),Color3.fromRGB(157,105,176),Color3.fromRGB(74,155,148),
    }
    local n=0
    for row=0,1 do
        for col=0,5 do
            n+=1
            local x=10.8+col*4.1;local y=2.25+row*3.15
            part(root,"Cubbie opening",Vector3.new(3.4,2.55,.35),CFrame.new(x,y,23.55),Color3.fromRGB(71,57,46),Enum.Material.SmoothPlastic,false)
            part(root,"Cubbie bin",Vector3.new(2.85,1.55,2.1),CFrame.new(x,y-.2,23.05),binColors[(n-1)%#binColors+1],Enum.Material.SmoothPlastic,false)
        end
    end
    sign(root,"Cubbies label","READ • CREATE • GROW",Vector3.new(19,1.55,.2),CFrame.new(21,8.8,23.55),P.blue,P.cream)
end

local function buildWindows(root: Instance)
    -- Bright stylized outside view so the windows never stare into empty gray space.
    part(root,"Outdoor sky backdrop",Vector3.new(.35,14,45),CFrame.new(-39,9,-6),Color3.fromRGB(105,188,242),Enum.Material.SmoothPlastic,false)
    part(root,"Outdoor hill backdrop",Vector3.new(.5,5,45),CFrame.new(-38.7,3.2,-6),Color3.fromRGB(85,139,73),Enum.Material.Grass,false)
    for _,z in ipairs({-19,6}) do
        part(root,"Window wood surround",Vector3.new(.5,9.5,15.5),CFrame.new(-36.5,9,z),Color3.fromRGB(105,75,53),Enum.Material.Wood,false)
        local glass=part(root,"Window glass",Vector3.new(.22,8.4,14.2),CFrame.new(-36.18,9,z),Color3.fromRGB(213,233,238),Enum.Material.Glass,false);glass.Transparency=.35
        for _,dz in ipairs({-4.6,0,4.6}) do part(root,"Window vertical mullion",Vector3.new(.28,8.5,.24),CFrame.new(-36.03,9,z+dz),Color3.fromRGB(105,75,53),Enum.Material.Wood,false) end
        part(root,"Window horizontal mullion",Vector3.new(.3,.30,14.2),CFrame.new(-36.02,9,z),Color3.fromRGB(105,75,53),Enum.Material.Wood,false)
        part(root,"Blue curtain valance",Vector3.new(.4,1.8,15),CFrame.new(-35.6,13.5,z),Color3.fromRGB(108,131,162),Enum.Material.Fabric,false)
        part(root,"Radiator body",Vector3.new(1.35,3.0,11.7),CFrame.new(-35.2,1.75,z),Color3.fromRGB(177,181,178),Enum.Material.Metal,false)
        for _,rz in ipairs({-4,-2,0,2,4}) do part(root,"Radiator fin",Vector3.new(1.48,2.7,.18),CFrame.new(-34.48,1.75,z+rz),Color3.fromRGB(150,156,155),Enum.Material.Metal,false) end
    end
    -- Warm sunlight washes the front-left classroom corner.
    local sunAnchor=part(root,"Window sun anchor",Vector3.new(.3,.3,.3),CFrame.new(-34,10,-10),Color3.new(1,1,1),Enum.Material.Neon,false);sunAnchor.Transparency=1
    local sun=Instance.new("PointLight");sun.Color=Color3.fromRGB(255,222,165);sun.Brightness=1.1;sun.Range=28;sun.Shadows=true;sun.Parent=sunAnchor
end

local function buildFrontWall(root: Instance)
    part(root,"Main chalkboard",Vector3.new(44,8.8,.45),CFrame.new(4,8.1,-34.25),Color3.fromRGB(42,47,45),Enum.Material.SmoothPlastic,false)
    part(root,"Chalkboard wood top",Vector3.new(45,.55,.7),CFrame.new(4,12.75,-34.05),Color3.fromRGB(111,77,50),Enum.Material.Wood,false)
    part(root,"Chalkboard wood bottom",Vector3.new(45,.55,.9),CFrame.new(4,3.55,-33.85),Color3.fromRGB(111,77,50),Enum.Material.Wood,false)
    part(root,"Chalk tray",Vector3.new(29,.38,1.15),CFrame.new(4,3.35,-33.45),Color3.fromRGB(111,77,50),Enum.Material.Wood,false)

    local smart=part(root,"Interactive smartboard",Vector3.new(23.5,6.8,.35),CFrame.new(7,8.2,-33.65),Color3.fromRGB(238,243,241),Enum.Material.Glass,false);smart.Transparency=.02
    local gui=Instance.new("SurfaceGui");gui.Name="QuestionBoard";gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(1200,700);gui.LightInfluence=.05;gui.Parent=smart
    local bg=Instance.new("Frame");bg.Size=UDim2.fromScale(1,1);bg.BackgroundColor3=Color3.fromRGB(245,248,247);bg.BorderSizePixel=0;bg.Parent=gui
    local header=Instance.new("TextLabel");header.Name="Header";header.Position=UDim2.fromScale(.04,.05);header.Size=UDim2.fromScale(.92,.14);header.BackgroundColor3=P.green;header.TextColor3=P.gold;header.Text="EMMA'S SCHOOLWORK";header.Font=Enum.Font.GothamBold;header.TextScaled=true;header.Parent=bg
    local hc=Instance.new("UICorner");hc.CornerRadius=UDim.new(0,20);hc.Parent=header
    local subject=Instance.new("TextLabel");subject.Name="Subject";subject.Position=UDim2.fromScale(.06,.23);subject.Size=UDim2.fromScale(.88,.10);subject.BackgroundTransparency=1;subject.TextColor3=P.blue;subject.Text="Ready for the next teacher…";subject.Font=Enum.Font.GothamBold;subject.TextScaled=true;subject.Parent=bg
    local q=Instance.new("TextLabel");q.Name="Question";q.Position=UDim2.fromScale(.06,.35);q.Size=UDim2.fromScale(.88,.43);q.BackgroundTransparency=1;q.TextColor3=Color3.fromRGB(34,39,42);q.Text="You can do hard things, Emma.";q.TextWrapped=true;q.Font=Enum.Font.GothamBold;q.TextScaled=true;q.Parent=bg
    local footer=Instance.new("TextLabel");footer.Name="Footer";footer.Position=UDim2.fromScale(.06,.82);footer.Size=UDim2.fromScale(.88,.10);footer.BackgroundTransparency=1;footer.TextColor3=Color3.fromRGB(91,98,99);footer.Text="Think it through. Take your time.";footer.Font=Enum.Font.GothamMedium;footer.TextScaled=true;footer.Parent=bg
    World.BoardSubject=subject;World.BoardQuestion=q;World.BoardFooter=footer

    -- Cross, motto, alphabet strip and classroom values from the target concept.
    part(root,"Classroom cross vertical",Vector3.new(1,4.8,.45),CFrame.new(-28,10,-33.9),Color3.fromRGB(104,72,46),Enum.Material.Wood,false)
    part(root,"Classroom cross horizontal",Vector3.new(3.5,1,.45),CFrame.new(-28,10.7,-33.72),Color3.fromRGB(104,72,46),Enum.Material.Wood,false)
    sign(root,"Light banner","LET YOUR LIGHT SHINE  •  MATTHEW 5:16",Vector3.new(29,2.0,.2),CFrame.new(-6,15.0,-33.85),Color3.fromRGB(248,239,213),Color3.fromRGB(78,65,48))
    sign(root,"Kindness panel","FAITH  +  LEARNING  +  KINDNESS",Vector3.new(16,4.6,.2),CFrame.new(28,10.8,-33.85),Color3.fromRGB(47,57,64),Color3.fromRGB(238,230,198))
    local letters="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for i=1,26 do
        local x=-31.2+(i-1)*2.38
        local tile=part(root,"Alphabet tile",Vector3.new(2.15,1.4,.18),CFrame.new(x,13.4,-33.78),i%2==0 and Color3.fromRGB(228,231,226) or Color3.fromRGB(213,225,229),Enum.Material.SmoothPlastic,false)
        surfaceText(tile,string.sub(letters,i,i)..string.lower(string.sub(letters,i,i)),Enum.NormalId.Front,P.blue,tile.Color,Enum.Font.GothamBold)
    end
end

local function buildRightWall(root: Instance)
    sign(root,"Class values","BE KIND\nBE RESPECTFUL\nBE RESPONSIBLE\nBE YOUR BEST\nBE A LIGHT",Vector3.new(.2,13,7.5),CFrame.new(36.45,9,-20)*CFrame.Angles(0,-math.pi/2,0),Color3.fromRGB(242,236,211),Color3.fromRGB(56,93,76))
    sign(root,"All loved sign","ALL ARE LOVED AT ABVM  ♥",Vector3.new(.2,4.2,15),CFrame.new(36.45,13.8,4)*CFrame.Angles(0,-math.pi/2,0),Color3.fromRGB(247,239,214),Color3.fromRGB(52,71,104))
    buildCubbies(root)
    plant(root,32.5,.1,18,.95)
    plant(root,31.5,8.2,-29,.62)
end

local function buildTeacherDesk(root: Instance)
    part(root,"Teacher desk top",Vector3.new(14,.65,6),CFrame.new(25,3.1,-25),Color3.fromRGB(151,109,72),Enum.Material.Wood)
    part(root,"Teacher desk front",Vector3.new(13,3.8,.65),CFrame.new(25,1.65,-27.7),Color3.fromRGB(126,87,59),Enum.Material.Wood)
    for _,x in ipairs({19.2,30.8}) do part(root,"Teacher desk leg",Vector3.new(.55,3.2,.55),CFrame.new(x,1.55,-25),Color3.fromRGB(100,72,53),Enum.Material.Wood) end
    local laptop=part(root,"Teacher laptop screen",Vector3.new(4.6,2.8,.22),CFrame.new(26,5.1,-26.1)*CFrame.Angles(math.rad(-8),0,0),Color3.fromRGB(50,70,82),Enum.Material.Glass,false)
    surfaceText(laptop,"ABVM\nGRADE 2",Enum.NormalId.Front,P.cream,Color3.fromRGB(50,70,82),Enum.Font.GothamBold)
    part(root,"Teacher laptop base",Vector3.new(4.8,.2,3.1),CFrame.new(26,3.6,-24.9),Color3.fromRGB(88,93,95),Enum.Material.Metal,false)
    pencilCup(root,21.5,4.4,-24.2)
    book(root,29.5,3.62,-24.2,Color3.fromRGB(61,110,78),math.rad(8))
    book(root,29.5,3.95,-24.2,Color3.fromRGB(44,75,110),math.rad(8))
    -- Globe.
    ball(root,"Classroom globe",Vector3.new(4.5,4.5,4.5),CFrame.new(18.2,6.1,-29),Color3.fromRGB(72,148,192),Enum.Material.SmoothPlastic,false)
    part(root,"Globe land",Vector3.new(.25,2.5,1.4),CFrame.new(17,6.4,-31.0)*CFrame.Angles(0,math.rad(20),math.rad(12)),Color3.fromRGB(104,155,76),Enum.Material.Grass,false)
    part(root,"Globe stand",Vector3.new(.35,3,.35),CFrame.new(18.2,3.8,-29),P.metal,Enum.Material.Metal,false)
    cylinder(root,"Globe base",Vector3.new(.35,3.2,3.2),CFrame.new(18.2,2.5,-29)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(87,89,88),Enum.Material.Metal,false)
end

local function buildBackDoorAndHall(root: Instance)
    -- Warm wood classroom doorway with tiny photo-inspired corridor beyond it.
    part(root,"Door jamb left",Vector3.new(1.1,11.5,1.3),CFrame.new(-8.4,5.75,27.0),Color3.fromRGB(113,78,50),Enum.Material.Wood,false)
    part(root,"Door jamb right",Vector3.new(1.1,11.5,1.3),CFrame.new(8.4,5.75,27.0),Color3.fromRGB(113,78,50),Enum.Material.Wood,false)
    part(root,"Door wood header",Vector3.new(17.9,1.1,1.3),CFrame.new(0,11.25,27.0),Color3.fromRGB(113,78,50),Enum.Material.Wood,false)
    part(root,"Door transom glass",Vector3.new(15.4,2.4,.24),CFrame.new(0,13.0,26.7),Color3.fromRGB(207,221,218),Enum.Material.Glass,false).Transparency=.32
    for _,x in ipairs({-4,4}) do
        local door=part(root,"Open classroom door",Vector3.new(6.5,10,.55),CFrame.new(x,5.3,25.7)*CFrame.Angles(0,math.rad(x<0 and -52 or 52),0),Color3.fromRGB(124,87,57),Enum.Material.Wood,false)
        local glass=part(root,"Door glass",Vector3.new(3.1,4.6,.18),door.CFrame*CFrame.new(0,1.6,-.35),Color3.fromRGB(206,219,216),Enum.Material.Glass,false);glass.Transparency=.27
    end
    sign(root,"Welcome over door","WELCOME  •  EMMA'S CLASSROOM",Vector3.new(16,1.6,.2),CFrame.new(0,12.5,25.8),Color3.fromRGB(247,237,207),P.blue)
    part(root,"Hall floor",Vector3.new(18,.5,23),CFrame.new(0,.25,38),Color3.fromRGB(67,68,66),Enum.Material.Slate)
    part(root,"Hall left wall",Vector3.new(1,13,23),CFrame.new(-9,6.5,38),P.blueSoft)
    part(root,"Hall right wall",Vector3.new(1,13,23),CFrame.new(9,6.5,38),P.blueSoft)
    part(root,"Hall left brick",Vector3.new(1.1,4.3,23),CFrame.new(-8.5,2.15,38),Color3.fromRGB(177,122,63),Enum.Material.Brick,false)
    part(root,"Hall right brick",Vector3.new(1.1,4.3,23),CFrame.new(8.5,2.15,38),Color3.fromRGB(177,122,63),Enum.Material.Brick,false)
    part(root,"Hall ceiling",Vector3.new(18,.4,23),CFrame.new(0,13,38),Color3.fromRGB(224,226,223),Enum.Material.SmoothPlastic,false)
    local hallLight=part(root,"Hall fluorescent light",Vector3.new(6,.22,2),CFrame.new(0,12.72,36),Color3.fromRGB(250,247,225),Enum.Material.Neon,false)
    local light=Instance.new("SurfaceLight");light.Face=Enum.NormalId.Bottom;light.Brightness=.55;light.Range=16;light.Parent=hallLight
end

local function applyLighting(root: Instance)
    Lighting.ClockTime=10.25;Lighting.Brightness=2.5;Lighting.GlobalShadows=true;Lighting.ShadowSoftness=.3
    Lighting.Ambient=Color3.fromRGB(150,147,139);Lighting.OutdoorAmbient=Color3.fromRGB(183,185,178)
    Lighting.EnvironmentDiffuseScale=.55;Lighting.EnvironmentSpecularScale=.35;Lighting.ExposureCompensation=.08
    local atmosphere=Lighting:FindFirstChild("EmmaClassroomAtmosphere") or Instance.new("Atmosphere")
    atmosphere.Name="EmmaClassroomAtmosphere";atmosphere.Density=.14;atmosphere.Offset=.15;atmosphere.Color=Color3.fromRGB(221,230,235);atmosphere.Decay=Color3.fromRGB(188,192,185);atmosphere.Haze=.8;atmosphere.Glare=.05;atmosphere.Parent=Lighting
    local bloom=Lighting:FindFirstChild("EmmaClassroomBloom") or Instance.new("BloomEffect")
    bloom.Name="EmmaClassroomBloom";bloom.Intensity=.12;bloom.Size=20;bloom.Threshold=1.25;bloom.Parent=Lighting
    local grade=Lighting:FindFirstChild("EmmaClassroomGrade") or Instance.new("ColorCorrectionEffect")
    grade.Name="EmmaClassroomGrade";grade.Brightness=.025;grade.Contrast=.055;grade.Saturation=.08;grade.TintColor=Color3.fromRGB(255,249,236);grade.Parent=Lighting
    local rays=Lighting:FindFirstChild("EmmaClassroomSunRays") or Instance.new("SunRaysEffect")
    rays.Name="EmmaClassroomSunRays";rays.Intensity=.025;rays.Spread=.8;rays.Parent=Lighting
end

function World.build()
    local old=Workspace:FindFirstChild("EmmaStudyWorld");if old then old:Destroy() end
    local root=Instance.new("Folder");root.Name="EmmaStudyWorld";root.Parent=Workspace
    applyLighting(root)

    -- Architectural shell.
    part(root,"Dark varnished classroom floor",Vector3.new(74,1,62),CFrame.new(0,0,-4),P.woodDark,Enum.Material.WoodPlanks)
    part(root,"Front wall",Vector3.new(74,18,1),CFrame.new(0,9,-35),P.wall)
    part(root,"Back wall left",Vector3.new(28,18,1),CFrame.new(-23,9,27),P.wall)
    part(root,"Back wall right",Vector3.new(28,18,1),CFrame.new(23,9,27),P.wall)
    part(root,"Door header wall",Vector3.new(18,5,1),CFrame.new(0,15.5,27),P.wall)
    part(root,"Left wall",Vector3.new(1,18,62),CFrame.new(-37,9,-4),P.wall)
    part(root,"Right wall",Vector3.new(1,18,62),CFrame.new(37,9,-4),P.wall)
    part(root,"Acoustic ceiling",Vector3.new(74,.48,62),CFrame.new(0,18,-4),Color3.fromRGB(241,241,235),Enum.Material.SmoothPlastic,false)
    for _,x in ipairs({-24,-12,0,12,24}) do part(root,"Ceiling grid line",Vector3.new(.07,.07,61),CFrame.new(x,17.7,-4),Color3.fromRGB(195,198,195),Enum.Material.Metal,false) end
    for _,z in ipairs({-28,-16,-4,8,20}) do part(root,"Ceiling grid cross",Vector3.new(73,.07,.07),CFrame.new(0,17.7,z),Color3.fromRGB(195,198,195),Enum.Material.Metal,false) end
    for _,x in ipairs({-36.35,36.35}) do part(root,"Blue baseboard",Vector3.new(.35,.72,61),CFrame.new(x,.55,-4),P.blue,Enum.Material.Wood,false) end
    for _,z in ipairs({-34.35,26.35}) do part(root,"Blue baseboard",Vector3.new(73,.72,.35),CFrame.new(0,.55,z),P.blue,Enum.Material.Wood,false) end
    part(root,"Blue chair rail right",Vector3.new(.35,.35,61),CFrame.new(36.32,5.3,-4),P.blue,Enum.Material.Wood,false)

    buildWindows(root)
    buildFrontWall(root)
    buildRightWall(root)
    buildTeacherDesk(root)
    buildBackDoorAndHall(root)

    -- Student desks. The center-middle desk is Emma's, with her name and water bottle.
    local index=0
    for row,z in ipairs({-12,4,19}) do
        for col,x in ipairs({-18,0,18}) do
            index+=1;desk(root,x,z,index,row==2 and col==2)
        end
    end

    -- Lived-in details.
    plant(root,-31,.1,20,.85)
    plant(root,-30,8.2,-29,.55)
    sign(root,"Today board","TODAY\n✓ Reading\n✓ Spelling\n✓ Grammar\n✓ Math\n✓ Religion",Vector3.new(8.5,10,.2),CFrame.new(-30,8,-33.82),Color3.fromRGB(49,53,57),Color3.fromRGB(230,229,218))
    sign(root,"Small mission poster","TEACH\nPRAY\nENCOURAGE\nBELONG",Vector3.new(6,7,.2),CFrame.new(33,7,-33.82),Color3.fromRGB(245,239,215),Color3.fromRGB(77,64,47))
    -- Small wall clock.
    local clock=cylinder(root,"Classroom wall clock",Vector3.new(.25,3.2,3.2),CFrame.new(31.5,15.1,-34)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(242,242,237),Enum.Material.SmoothPlastic,false)
    cylinder(root,"Clock rim",Vector3.new(.34,3.55,3.55),clock.CFrame,Color3.fromRGB(61,63,63),Enum.Material.Metal,false)
    part(root,"Clock minute hand",Vector3.new(.12,1.25,.12),CFrame.new(31.3,15.55,-34.25)*CFrame.Angles(0,0,math.rad(-20)),Color3.fromRGB(48,49,49),Enum.Material.Metal,false)
    part(root,"Clock hour hand",Vector3.new(.12,.85,.12),CFrame.new(31.3,15.25,-34.28)*CFrame.Angles(0,0,math.rad(45)),Color3.fromRGB(48,49,49),Enum.Material.Metal,false)

    -- Warm fluorescent lighting.
    for _,x in ipairs({-22,0,22}) do
        for _,z in ipairs({-22,0,20}) do ceilingLight(root,x,z) end
    end

    local spawn=Instance.new("SpawnLocation")
    spawn.Name="EmmaSeatSpawn";spawn.Size=Vector3.new(5,1,5);spawn.CFrame=CFrame.new(0,1,13)*CFrame.Angles(0,math.pi,0)
    spawn.Transparency=1;spawn.CanCollide=false;spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=root

    World.Root=root
    World.Spawn=spawn.CFrame
    World.TeacherDoor=CFrame.new(0,4,45)*CFrame.Angles(0,math.pi,0)
    World.TeacherFront=CFrame.new(0,4,-22)*CFrame.Angles(0,math.pi,0)
    World.resetBoard()
    return World
end

local function rigPart(model: Model,root: BasePart,name: string,size: Vector3,localCF: CFrame,color: Color3,material: Enum.Material?,kind: string?): Part
    local p=part(model,name,size,root.CFrame*localCF,color,material,false)
    p.Massless=true
    if kind then p:SetAttribute("RigKind",kind);p:SetAttribute("LocalCF",localCF) end
    return p
end

local function faceFeature(model: Model,root: BasePart,name: string,size: Vector3,localCF: CFrame,color: Color3)
    local p=rigPart(model,root,name,size,localCF,color,Enum.Material.SmoothPlastic,nil)
    p.CanQuery=false
    return p
end

local function glasses(model: Model,root: BasePart)
    local frame=Color3.fromRGB(69,62,58)
    for _,x in ipairs({-.53,.53}) do
        faceFeature(model,root,"Glasses top",Vector3.new(.8,.08,.08),CFrame.new(x,5.98,-1.27),frame)
        faceFeature(model,root,"Glasses bottom",Vector3.new(.8,.08,.08),CFrame.new(x,5.48,-1.27),frame)
        faceFeature(model,root,"Glasses outer",Vector3.new(.08,.55,.08),CFrame.new(x+(x<0 and -.38 or .38),5.73,-1.27),frame)
        faceFeature(model,root,"Glasses inner",Vector3.new(.08,.55,.08),CFrame.new(x+(x<0 and .38 or -.38),5.73,-1.27),frame)
    end
    faceFeature(model,root,"Glasses bridge",Vector3.new(.3,.08,.08),CFrame.new(0,5.75,-1.27),frame)
end

local function hairPieces(model: Model,root: BasePart,hairColor: Color3,style: string)
    ball(model,"Hair crown",Vector3.new(2.55,1.5,2.35),root.CFrame*CFrame.new(0,6.55,.12),hairColor,Enum.Material.SmoothPlastic,false)
    if style=="short" then
        ball(model,"Hair front",Vector3.new(2.35,.9,1.25),root.CFrame*CFrame.new(0,6.55,-.7)*CFrame.Angles(math.rad(-8),0,0),hairColor,Enum.Material.SmoothPlastic,false)
    elseif style=="bob" then
        for _,x in ipairs({-1.05,1.05}) do ball(model,"Bob hair",Vector3.new(.95,2.55,1.1),root.CFrame*CFrame.new(x,5.8,.15),hairColor,Enum.Material.SmoothPlastic,false) end
        ball(model,"Bob back",Vector3.new(2.25,2.3,.85),root.CFrame*CFrame.new(0,5.8,1.0),hairColor,Enum.Material.SmoothPlastic,false)
    elseif style=="ponytail" then
        for _,x in ipairs({-.95,.95}) do ball(model,"Side hair",Vector3.new(.85,2.3,.9),root.CFrame*CFrame.new(x,5.85,.2),hairColor,Enum.Material.SmoothPlastic,false) end
        ball(model,"Ponytail",Vector3.new(1.35,2.8,1.35),root.CFrame*CFrame.new(0,5.5,1.55)*CFrame.Angles(math.rad(18),0,0),hairColor,Enum.Material.SmoothPlastic,false)
        ball(model,"Ponytail tie",Vector3.new(.65,.65,.65),root.CFrame*CFrame.new(0,6.15,1.15),Color3.fromRGB(48,81,107),Enum.Material.SmoothPlastic,false)
    elseif style=="waves" then
        for _,x in ipairs({-1.18,1.18}) do
            for y=3.9,6.0,.7 do
                ball(model,"Wavy hair curl",Vector3.new(.8,.9,.82),root.CFrame*CFrame.new(x,y,.25+math.sin(y*2)*.22),hairColor,Enum.Material.SmoothPlastic,false)
            end
        end
        ball(model,"Wavy hair back",Vector3.new(2.25,3.4,1.0),root.CFrame*CFrame.new(0,5.1,1.1),hairColor,Enum.Material.SmoothPlastic,false)
    else
        for _,x in ipairs({-1.0,1.0}) do ball(model,"Long hair",Vector3.new(.9,3.8,1.0),root.CFrame*CFrame.new(x,4.9,.35),hairColor,Enum.Material.SmoothPlastic,false) end
        ball(model,"Long hair back",Vector3.new(2.2,3.4,.95),root.CFrame*CFrame.new(0,5.0,1.0),hairColor,Enum.Material.SmoothPlastic,false)
    end
end

function World.teacherModel(teacher)
    local m=Instance.new("Model");m.Name=teacher.name
    local root=part(m,"HumanoidRootPart",Vector3.new(2,2,1),CFrame.new(),Color3.new(1,1,1),Enum.Material.SmoothPlastic,false);root.Transparency=1;root.CanQuery=false
    m.PrimaryPart=root

    local shirt=Color3.fromRGB(teacher.shirt[1],teacher.shirt[2],teacher.shirt[3])
    local skin=Color3.fromRGB(teacher.skin[1],teacher.skin[2],teacher.skin[3])
    local hair=Color3.fromRGB(teacher.hair[1],teacher.hair[2],teacher.hair[3])
    local accent=Color3.fromRGB(teacher.accent[1],teacher.accent[2],teacher.accent[3])
    local pants=Color3.fromRGB(52,57,64)

    rigPart(m,root,"Torso",Vector3.new(3.7,4.4,2.15),CFrame.new(0,2.45,0),shirt,Enum.Material.Fabric,nil)
    rigPart(m,root,"Shirt front",Vector3.new(3.15,3.6,.16),CFrame.new(0,2.55,-1.13),shirt:Lerp(Color3.new(1,1,1),.05),Enum.Material.Fabric,nil)
    local logo=rigPart(m,root,"ABVM shirt badge",Vector3.new(2.3,.9,.10),CFrame.new(0,3.1,-1.23),shirt,Enum.Material.SmoothPlastic,nil)
    surfaceText(logo,"ASSUMPTION\nBVM SCHOOL",Enum.NormalId.Front,Color3.fromRGB(246,238,211),shirt,Enum.Font.GothamBold)

    local head=ball(m,"Head",Vector3.new(2.55,2.55,2.55),root.CFrame*CFrame.new(0,5.65,0),skin,Enum.Material.SmoothPlastic,false)
    -- Friendly native face.
    for _,x in ipairs({-.48,.48}) do
        ball(m,"Eye white",Vector3.new(.46,.40,.18),root.CFrame*CFrame.new(x,5.9,-1.22),Color3.fromRGB(249,247,238),Enum.Material.SmoothPlastic,false)
        ball(m,"Pupil",Vector3.new(.18,.20,.10),root.CFrame*CFrame.new(x,5.88,-1.34),Color3.fromRGB(46,38,34),Enum.Material.SmoothPlastic,false)
        faceFeature(m,root,"Eyebrow",Vector3.new(.54,.08,.10),CFrame.new(x,6.27,-1.28)*CFrame.Angles(0,0,math.rad(x<0 and -6 or 6)),hair)
    end
    faceFeature(m,root,"Smile",Vector3.new(.85,.11,.11),CFrame.new(0,5.25,-1.31)*CFrame.Angles(0,0,math.rad(3)),Color3.fromRGB(113,55,49))
    ball(m,"Cheek",Vector3.new(.28,.18,.09),root.CFrame*CFrame.new(-.75,5.38,-1.28),Color3.fromRGB(231,142,135),Enum.Material.SmoothPlastic,false)
    ball(m,"Cheek",Vector3.new(.28,.18,.09),root.CFrame*CFrame.new(.75,5.38,-1.28),Color3.fromRGB(231,142,135),Enum.Material.SmoothPlastic,false)
    hairPieces(m,root,hair,teacher.hairStyle)
    if teacher.glasses then glasses(m,root) end

    -- Arms and hands, stored with local CFrames so the walk tween can swing them.
    rigPart(m,root,"Left Arm",Vector3.new(1.0,3.7,1.0),CFrame.new(-2.25,2.6,0),skin,Enum.Material.SmoothPlastic,"leftArm")
    rigPart(m,root,"Right Arm",Vector3.new(1.0,3.7,1.0),CFrame.new(2.25,2.6,0),skin,Enum.Material.SmoothPlastic,"rightArm")
    ball(m,"Left Hand",Vector3.new(1.05,1.05,1.05),root.CFrame*CFrame.new(-2.25,.62,0),skin,Enum.Material.SmoothPlastic,false)
    ball(m,"Right Hand",Vector3.new(1.05,1.05,1.05),root.CFrame*CFrame.new(2.25,.62,0),skin,Enum.Material.SmoothPlastic,false)
    rigPart(m,root,"Left Leg",Vector3.new(1.25,3.8,1.35),CFrame.new(-.85,-1.65,0),pants,Enum.Material.Fabric,"leftLeg")
    rigPart(m,root,"Right Leg",Vector3.new(1.25,3.8,1.35),CFrame.new(.85,-1.65,0),pants,Enum.Material.Fabric,"rightLeg")
    rigPart(m,root,"Left Shoe",Vector3.new(1.45,.72,2.1),CFrame.new(-.85,-3.75,-.35),Color3.fromRGB(241,239,231),Enum.Material.SmoothPlastic,"leftShoe")
    rigPart(m,root,"Right Shoe",Vector3.new(1.45,.72,2.1),CFrame.new(.85,-3.75,-.35),Color3.fromRGB(241,239,231),Enum.Material.SmoothPlastic,"rightShoe")

    -- Collar, lanyard, badge and small folder sell the staff silhouette.
    faceFeature(m,root,"Collar left",Vector3.new(1.0,.42,.16),CFrame.new(-.5,4.3,-1.2)*CFrame.Angles(0,0,math.rad(-18)),accent)
    faceFeature(m,root,"Collar right",Vector3.new(1.0,.42,.16),CFrame.new(.5,4.3,-1.2)*CFrame.Angles(0,0,math.rad(18)),accent)
    faceFeature(m,root,"Lanyard left",Vector3.new(.12,2.2,.12),CFrame.new(-.28,3.15,-1.26)*CFrame.Angles(0,0,math.rad(-8)),accent)
    faceFeature(m,root,"Lanyard right",Vector3.new(.12,2.2,.12),CFrame.new(.28,3.15,-1.26)*CFrame.Angles(0,0,math.rad(8)),accent)
    local badge=rigPart(m,root,"Staff badge",Vector3.new(1.1,1.35,.10),CFrame.new(0,2.05,-1.28),Color3.fromRGB(245,244,236),Enum.Material.SmoothPlastic,nil)
    surfaceText(badge,teacher.name,Enum.NormalId.Front,P.blue,Color3.fromRGB(245,244,236),Enum.Font.GothamBold)
    local folder=rigPart(m,root,"Teacher folder",Vector3.new(1.8,2.6,.20),CFrame.new(1.72,1.4,-1.25)*CFrame.Angles(0,0,math.rad(-8)),accent:Lerp(Color3.new(1,1,1),.2),Enum.Material.SmoothPlastic,nil)
    surfaceText(folder,"★",Enum.NormalId.Front,P.green,folder.Color,Enum.Font.GothamBold)

    -- Nameplate and speech bubble.
    local nameGui=Instance.new("BillboardGui");nameGui.Name="TeacherName";nameGui.Size=UDim2.fromOffset(230,58);nameGui.StudsOffset=Vector3.new(0,7.8,0);nameGui.AlwaysOnTop=false;nameGui.MaxDistance=45;nameGui.Parent=root
    local nameLabel=Instance.new("TextLabel");nameLabel.Size=UDim2.fromScale(1,1);nameLabel.BackgroundColor3=P.green;nameLabel.BackgroundTransparency=.03;nameLabel.TextColor3=P.gold;nameLabel.TextScaled=true;nameLabel.Text=teacher.name.."\n"..teacher.role;nameLabel.Font=Enum.Font.GothamBold;nameLabel.Parent=nameGui
    local nc=Instance.new("UICorner");nc.CornerRadius=UDim.new(0,14);nc.Parent=nameLabel
    local ns=Instance.new("UIStroke");ns.Color=P.gold;ns.Transparency=.25;ns.Thickness=1.2;ns.Parent=nameLabel

    local speech=Instance.new("BillboardGui");speech.Name="Speech";speech.Size=UDim2.fromOffset(310,105);speech.StudsOffset=Vector3.new(3.8,8.6,0);speech.AlwaysOnTop=true;speech.MaxDistance=55;speech.Enabled=false;speech.Parent=root
    local bubble=Instance.new("TextLabel");bubble.Name="Text";bubble.Size=UDim2.fromScale(1,1);bubble.BackgroundColor3=Color3.fromRGB(253,251,243);bubble.TextColor3=Color3.fromRGB(39,44,43);bubble.TextWrapped=true;bubble.TextScaled=true;bubble.Font=Enum.Font.GothamBold;bubble.Text="";bubble.Parent=speech
    local bc=Instance.new("UICorner");bc.CornerRadius=UDim.new(0,18);bc.Parent=bubble
    local bs=Instance.new("UIStroke");bs.Color=P.green;bs.Transparency=.35;bs.Thickness=1.2;bs.Parent=bubble
    local bp=Instance.new("UIPadding");bp.PaddingLeft=UDim.new(0,14);bp.PaddingRight=UDim.new(0,14);bp.PaddingTop=UDim.new(0,10);bp.PaddingBottom=UDim.new(0,10);bp.Parent=bubble

    return m
end

function World.poseTeacher(model: Model,phase: number,walking: boolean)
    local pivot=model:GetPivot()
    local swing=walking and math.sin(phase)*math.rad(22) or 0
    for _,obj in ipairs(model:GetChildren()) do
        if obj:IsA("BasePart") then
            local kind=obj:GetAttribute("RigKind")
            local localCF=obj:GetAttribute("LocalCF")
            if kind and typeof(localCF)=="CFrame" then
                local rot=CFrame.new()
                if kind=="leftArm" then rot=CFrame.Angles(swing,0,0)
                elseif kind=="rightArm" then rot=CFrame.Angles(-swing,0,0)
                elseif kind=="leftLeg" or kind=="leftShoe" then rot=CFrame.Angles(-swing*.65,0,0)
                elseif kind=="rightLeg" or kind=="rightShoe" then rot=CFrame.Angles(swing*.65,0,0) end
                obj.CFrame=pivot*(localCF :: CFrame)*rot
            end
        end
    end
end

function World.moveTeacher(model: Model,target: CFrame,duration: number)
    local start=model:GetPivot()
    local alpha=Instance.new("NumberValue");alpha.Value=0
    local conn=alpha:GetPropertyChangedSignal("Value"):Connect(function()
        if not model.Parent then return end
        local a=alpha.Value
        local base=start:Lerp(target,a)
        local bob=math.abs(math.sin(a*math.pi*8))*.08
        model:PivotTo(base*CFrame.new(0,bob,0))
        World.poseTeacher(model,a*math.pi*8,true)
    end)
    local tween=TweenService:Create(alpha,TweenInfo.new(duration,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value=1})
    tween:Play();tween.Completed:Wait();conn:Disconnect();alpha:Destroy()
    if model.Parent then model:PivotTo(target);World.poseTeacher(model,0,false) end
end

function World.setTeacherSpeech(model: Model?,text: string?)
    if not model or not model.Parent then return end
    local root=model:FindFirstChild("HumanoidRootPart")
    local speech=root and root:FindFirstChild("Speech")
    if speech and speech:IsA("BillboardGui") then
        local label=speech:FindFirstChild("Text")
        if label and label:IsA("TextLabel") then label.Text=text or "" end
        speech.Enabled=text~=nil and text~=""
    end
end

function World.setBoardQuestion(subject: string,teacher: string,prompt: string)
    if World.BoardSubject then World.BoardSubject.Text=subject.."  •  "..teacher end
    if World.BoardQuestion then World.BoardQuestion.Text=prompt end
    if World.BoardFooter then World.BoardFooter.Text="Think it through, Emma. Take your time." end
end

function World.setBoardHint(hint: string)
    if World.BoardFooter then World.BoardFooter.Text="Hint: "..hint end
end

function World.setBoardCorrect(explanation: string)
    if World.BoardSubject then World.BoardSubject.Text="✓ CORRECT!  NICE WORK, EMMA!" end
    if World.BoardQuestion then World.BoardQuestion.Text=explanation end
    if World.BoardFooter then World.BoardFooter.Text="Another teacher is on the way…" end
end

function World.resetBoard()
    if World.BoardSubject then World.BoardSubject.Text="Ready for the next teacher…" end
    if World.BoardQuestion then World.BoardQuestion.Text="You can do hard things, Emma." end
    if World.BoardFooter then World.BoardFooter.Text="Real schoolwork. One question at a time." end
end

return World
