--!strict
local Workspace=game:GetService("Workspace")
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")

local StaffModel=require(script.Parent:WaitForChild("StaffModel"))
local World={}

local P={
    wall=Color3.fromRGB(232,222,173),
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
    surfaceText(p,text,cf.Position.Z>20 and Enum.NormalId.Front or Enum.NormalId.Back,fg,bg)
    return p
end

local function ceilingLight(parent: Instance,x: number,z: number)
    local box=part(parent,"Recessed ceiling light",Vector3.new(7.6,.22,2.4),CFrame.new(x,17.72,z),Color3.fromRGB(255,249,220),Enum.Material.Neon,false)
    local light=Instance.new("SurfaceLight");light.Face=Enum.NormalId.Bottom;light.Brightness=.3;light.Range=20;light.Angle=105;light.Shadows=false;light.Parent=box
    part(parent,"Light trim",Vector3.new(8,.10,2.8),CFrame.new(x,17.80,z),Color3.fromRGB(205,207,202),Enum.Material.Metal,false)
end

local function plant(parent: Instance,x: number,y: number,z: number,scale: number)
    local pot=cylinder(parent,"Plant pot",Vector3.new(1.8*scale,2.2*scale,2.2*scale),CFrame.new(x,y+.9*scale,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(166,113,74),Enum.Material.SmoothPlastic,false)

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
    cylinder(parent,"Pencil cup",Vector3.new(1.6,1.3,1.3),CFrame.new(x,y,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(187,192,194),Enum.Material.Metal,false)
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
    part(parent,"Student desk top",Vector3.new(7,.48,4.6),CFrame.new(x,3,z),Color3.fromRGB(191,158,107),Enum.Material.Wood)
    part(parent,"Desk front lip",Vector3.new(6.8,.58,.35),CFrame.new(x,2.7,z-2.12),Color3.fromRGB(49,49,46),Enum.Material.SmoothPlastic,false)
    for _,dx in ipairs({-2.8,2.8}) do
        part(parent,"Desk leg",Vector3.new(.28,2.75,.28),CFrame.new(x+dx,1.5,z),Color3.fromRGB(76,82,86),Enum.Material.Metal)
        part(parent,"Desk foot",Vector3.new(1.0,.18,3.6),CFrame.new(x+dx,.18,z),Color3.fromRGB(76,82,86),Enum.Material.Metal)
    end
    part(parent,"Desk book tray",Vector3.new(5.8,.12,3.6),CFrame.new(x,2.30,z),Color3.fromRGB(57,59,58),Enum.Material.Metal,false)
    for _,dx in ipairs({-2.9,2.9}) do part(parent,"Book tray side",Vector3.new(.10,.52,3.6),CFrame.new(x+dx,2.55,z),P.metal,Enum.Material.Metal,false) end
    book(parent,x,2.58,z,Color3.fromRGB(70,106,133),0)
    schoolChair(parent,"Student chair",x,z+3.9,Color3.fromRGB(47,50,50))
    local notebookColor=({Color3.fromRGB(217,91,104),Color3.fromRGB(63,130,181),Color3.fromRGB(98,150,101),Color3.fromRGB(220,173,66)})[(index-1)%4+1]
    book(parent,x-1.2,3.36,z-.2,notebookColor,math.rad(index%2==0 and 5 or -5))
    part(parent,"Desk pencil",Vector3.new(.14,.14,2.2),CFrame.new(x+1.4,3.42,z-.6)*CFrame.Angles(0,math.rad(18),0),Color3.fromRGB(239,190,56),Enum.Material.Wood,false)
    if emma then
        local tag=part(parent,"Emma desk nameplate",Vector3.new(3.8,.55,.16),CFrame.new(x,3.42,z-2.33)*CFrame.Angles(math.rad(-10),0,0),P.green,Enum.Material.SmoothPlastic,false)
        surfaceText(tag,"★ EMMA ★",Enum.NormalId.Back,P.gold,P.green)
        cylinder(parent,"Emma pink water bottle",Vector3.new(1.9,.75,.75),CFrame.new(x+2.45,4.23,z+.45)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(225,125,154),Enum.Material.SmoothPlastic,false)
        part(parent,"Water bottle cap",Vector3.new(.5,.20,.5),CFrame.new(x+2.45,5.25,z+.45),Color3.fromRGB(190,86,124),Enum.Material.SmoothPlastic,false)
    end
end

local function bulletinBoard(parent: Instance,name: string,x: number,y: number,z: number,width: number,height: number,title: string)
    local frame=part(parent,name.." wood frame",Vector3.new(width+.8,height+.8,.32),CFrame.new(x,y,z),Color3.fromRGB(105,73,48),Enum.Material.Wood,false)
    local cork=part(parent,name.." cork",Vector3.new(width,height,.18),CFrame.new(x,y,z-.19),Color3.fromRGB(168,122,75),Enum.Material.Fabric,false)
    surfaceText(cork,title,Enum.NormalId.Back,Color3.fromRGB(247,241,217),Color3.fromRGB(168,122,75),Enum.Font.GothamBold)
    return frame
end

local function buildClassroomTexture(root: Instance)
    -- The real school photos are busy, old, warm and layered. This deliberately kills the sterile showroom look.
    bulletinBoard(root,"Student work board",-21,12.0,-33.78,12,5.2,"OUR WORK\n★  ★  ★")
    bulletinBoard(root,"Reading board",-21,6.5,-33.78,12,4.2,"READING\ncharacters • setting • problem • solution")
    sign(root,"Prayer card","PRAY\nLEARN\nSERVE",Vector3.new(5.2,6.5,.18),CFrame.new(-32.7,9,-33.72),Color3.fromRGB(239,232,201),Color3.fromRGB(68,89,72))

    -- Classroom rules and paper chains on the side wall.
    local rules={"LISTEN","BE KIND","TRY YOUR BEST","HELP OTHERS","KEEP GOING"}
    for i,v in ipairs(rules) do
        sign(root,"Rule card "..i,v,Vector3.new(6.4,2.3,.18),CFrame.new(36.30,14.7-i*2.55,-6)*CFrame.Angles(0,-math.pi/2,0),
            i%2==0 and Color3.fromRGB(230,239,223) or Color3.fromRGB(244,229,205),P.blue)
    end

    -- Pencil sharpener, trash bin, tissue box, storage cabinet, rolling cart.
    part(root,"Tall storage cabinet",Vector3.new(7,12,3.2),CFrame.new(31,6,22.7),Color3.fromRGB(124,102,79),Enum.Material.Wood)
    for y=2,10,2 do
        part(root,"Cabinet shelf line",Vector3.new(6.4,.12,.18),CFrame.new(31,y,21.02),Color3.fromRGB(77,63,52),Enum.Material.Wood,false)
    end
    for _,x in ipairs({29.3,32.7}) do
        ball(root,"Cabinet knob",Vector3.new(.32,.32,.32),CFrame.new(x,6,21),Color3.fromRGB(191,178,145),Enum.Material.Metal,false)
    end
    local trash=cylinder(root,"Classroom trash can",Vector3.new(3.4,3.1,3.1),CFrame.new(32.8,1.7,-24)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(95,100,101),Enum.Material.Metal,false)
    trash.Transparency=.05
    local tissues=part(root,"Tissue box",Vector3.new(2.3,1.2,1.7),CFrame.new(22.5,4.05,-23.6),Color3.fromRGB(116,177,193),Enum.Material.SmoothPlastic,false)
    surfaceText(tissues,"TISSUES",Enum.NormalId.Front,Color3.fromRGB(245,248,244),tissues.Color,Enum.Font.GothamBold)
    part(root,"Rolling cart top",Vector3.new(5.5,.4,3.2),CFrame.new(-29,3.5,22),Color3.fromRGB(71,105,125),Enum.Material.Metal)
    for _,y in ipairs({1.0,2.1,3.2}) do part(root,"Rolling cart shelf",Vector3.new(5.2,.22,3),CFrame.new(-29,y,22),Color3.fromRGB(82,119,139),Enum.Material.Metal,false) end
    for _,x in ipairs({-31.2,-26.8}) do
        for _,z in ipairs({20.8,23.2}) do cylinder(root,"Cart wheel",Vector3.new(.35,.75,.75),CFrame.new(x,.45,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(45,48,49),Enum.Material.SmoothPlastic,false) end
    end

    -- A small prayer table / classroom faith corner.
    part(root,"Prayer table",Vector3.new(8,.5,3.5),CFrame.new(-28,3.2,-27),Color3.fromRGB(139,98,64),Enum.Material.Wood)
    for _,x in ipairs({-31,-25}) do part(root,"Prayer table leg",Vector3.new(.35,3,.35),CFrame.new(x,1.55,-27),Color3.fromRGB(104,72,50),Enum.Material.Wood) end
    local cloth=part(root,"Prayer table cloth",Vector3.new(7.4,.12,3.1),CFrame.new(-28,3.48,-27),Color3.fromRGB(64,104,77),Enum.Material.Fabric,false)
    cloth.Transparency=.03
    part(root,"Prayer cross vertical",Vector3.new(.45,3,.28),CFrame.new(-28,5.2,-27),Color3.fromRGB(112,77,48),Enum.Material.Wood,false)
    part(root,"Prayer cross horizontal",Vector3.new(1.8,.45,.28),CFrame.new(-28,5.7,-27),Color3.fromRGB(112,77,48),Enum.Material.Wood,false)
    book(root,-30,3.72,-27,Color3.fromRGB(92,61,42),0)

    -- Separate rug zones visible in IMG_2910: colored dots at the front,
    -- alphabet/flower reading carpet at the back. No overlapping rug surfaces.
    part(root,"Front teaching rug",Vector3.new(16,.10,9),CFrame.new(-25,.56,-20),Color3.fromRGB(47,58,66),Enum.Material.Fabric,false)
    local dots={Color3.fromRGB(208,85,91),Color3.fromRGB(96,151,179),Color3.fromRGB(218,182,81),Color3.fromRGB(145,127,165)}
    for row=0,2 do
        for col=0,4 do cylinder(root,"Front rug color dot",Vector3.new(.025,1.5,1.5),CFrame.new(-31+col*3,.63,-23+row*3)*CFrame.Angles(0,0,math.pi/2),dots[(row+col)%4+1],Enum.Material.Fabric,false) end
    end
    local rug=part(root,"Alphabet rug",Vector3.new(18,.10,12),CFrame.new(-25,.56,14),Color3.fromRGB(55,85,125),Enum.Material.Fabric,false)
    local letters="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for i=1,26 do
        local x,z
        if i<=8 then x=-32.8+(i-1)*2.22;z=8.9
        elseif i<=13 then x=-16.9;z=10.7+(i-9)*1.72
        elseif i<=21 then x=-17.2-(i-14)*2.22;z=19.1
        else x=-33.1;z=17.4-(i-22)*1.72 end
        local tile=part(root,"Reading rug alphabet border",Vector3.new(1.52,.02,1.52),CFrame.new(x,.63,z),Color3.fromRGB(192,199,150),Enum.Material.Fabric,false)
        surfaceText(tile,string.sub(letters,i,i),Enum.NormalId.Top,P.blue,tile.Color)
    end
    for row=0,1 do
        for col=0,4 do
            local x,z=-30+col*2.5,11.8+row*3.8
            for petal=0,5 do
                local t=petal*math.pi/3
                cylinder(root,"Reading rug flower petal",Vector3.new(.025,.82,.82),CFrame.new(x+math.cos(t)*.52,.64,z+math.sin(t)*.52)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(166,184,194),Enum.Material.Fabric,false)
            end
            cylinder(root,"Reading rug flower center",Vector3.new(.028,.62,.62),CFrame.new(x,.66,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(226,211,151),Enum.Material.Fabric,false)
        end
    end

    -- Student supply baskets on the center tables.
    local basketColors={Color3.fromRGB(221,91,86),Color3.fromRGB(75,142,190),Color3.fromRGB(86,154,96),Color3.fromRGB(231,181,63)}
    for i,x in ipairs({-20,-4,16}) do
        local b=part(root,"Supply basket",Vector3.new(2.8,.9,1.8),CFrame.new(x,3.72,4.8),basketColors[i],Enum.Material.SmoothPlastic,false)
        surfaceText(b,"PENCILS",Enum.NormalId.Front,Color3.fromRGB(248,245,232),b.Color,Enum.Font.GothamBold)
    end
end

local function buildReadingCorner(root:Instance)
    part(root,"Reading shelf back",Vector3.new(18,6,.3),CFrame.new(-22,3,24.4),P.wood,Enum.Material.Wood)
    for _,y in ipairs({.65,3.2,6.1}) do
        part(root,"Reading shelf",Vector3.new(18,.3,2.7),CFrame.new(-22,y,23.3),P.wood,Enum.Material.Wood)
    end
    for _,x in ipairs({-31,-22,-13}) do
        part(root,"Reading shelf upright",Vector3.new(.3,6,2.7),CFrame.new(x,3.2,23.3),P.wood,Enum.Material.Wood)
    end
    local colors={P.blue,Color3.fromRGB(174,74,82),P.green,P.gold}
    for row=0,1 do
        for i=1,20 do
            local x=-30.5+(i-1)*.85
            local height=1.6+(i%3)*.22
            part(root,"Reading book spine",Vector3.new(.55,height,1.5),CFrame.new(x,.95+row*2.55+height/2,23.3),colors[i%4+1],Enum.Material.SmoothPlastic,false)
            part(root,"Book spine label",Vector3.new(.3,.14,.03),CFrame.new(x,1.7+row*2.55,22.53),P.cream,Enum.Material.SmoothPlastic,false)
        end
    end
    for i=1,6 do
        local paper=part(root,"Student artwork paper",Vector3.new(1.5,2,.04),CFrame.new(-25+(i-1)*1.55,11.5,-33.4),P.cream,Enum.Material.SmoothPlastic,false)
        ball(root,"Artwork flower",Vector3.new(.65,.65,.06),paper.CFrame*CFrame.new(0,.1,.05),colors[i%4+1],Enum.Material.SmoothPlastic,false)
        part(root,"Artwork stem",Vector3.new(.07,.6,.06),paper.CFrame*CFrame.new(0,-.4,.05),P.green,Enum.Material.SmoothPlastic,false)
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
    part(root,"Wood coat rail",Vector3.new(26,.65,.38),CFrame.new(21,11.1,26.1),P.woodDark,Enum.Material.Wood,false)
    part(root,"Storage ledge",Vector3.new(27,.27,3.2),CFrame.new(21,8.35,25.1),P.woodDark,Enum.Material.Wood,false)
    for i=0,7 do
        local x=10.3+i*3.05
        part(root,"Metal coat hook",Vector3.new(.10,.55,.48),CFrame.new(x,10.83,25.76),P.metal,Enum.Material.Metal,false)
        local bag=ball(root,"Hanging school bag",Vector3.new(1.65,2.15,.80),CFrame.new(x,9.62,25.40),binColors[i%#binColors+1],Enum.Material.Fabric,false)
        part(root,"Backpack pocket",Vector3.new(1.22,.8,.12),bag.CFrame*CFrame.new(0,-.37,-.43),bag.Color:Lerp(Color3.new(0,0,0),.14),Enum.Material.Fabric,false)
        part(root,"Bag zipper",Vector3.new(1.04,.035,.06),bag.CFrame*CFrame.new(0,.03,-.50),P.cream,Enum.Material.Metal,false)
    end
    sign(root,"Cubbies label","READ • CREATE • GROW",Vector3.new(19,1.55,.2),CFrame.new(21,8.8,23.55),P.blue,P.cream)
end

local function buildWindows(root: Instance)
    -- Bright stylized outside view so the windows never stare into empty gray space.
    part(root,"Outdoor sky backdrop",Vector3.new(.35,14,45),CFrame.new(-39,9,-6),Color3.fromRGB(105,188,242),Enum.Material.SmoothPlastic,false)
    part(root,"Outdoor hill backdrop",Vector3.new(.5,5,45),CFrame.new(-38.7,3.2,-6),Color3.fromRGB(85,139,73),Enum.Material.Grass,false)
    for _,z in ipairs({-19,6}) do
        for _,dy in ipairs({-4.75,4.75}) do
            part(root,"Window wood horizontal frame",Vector3.new(.5,.45,15.5),CFrame.new(-36.5,9+dy,z),P.blue,Enum.Material.Wood,false)
        end
        for _,dz in ipairs({-7.6,7.6}) do
            part(root,"Window wood vertical frame",Vector3.new(.5,9.5,.45),CFrame.new(-36.5,9,z+dz),P.blue,Enum.Material.Wood,false)
        end
        part(root,"Deep window sill",Vector3.new(1.8,.35,15.5),CFrame.new(-35.8,4.4,z),P.blue,Enum.Material.Wood,false)
        local glass=part(root,"Window glass",Vector3.new(.22,8.4,14.2),CFrame.new(-36.18,9,z),Color3.fromRGB(213,233,238),Enum.Material.Glass,false);glass.Transparency=.35
        for _,dz in ipairs({-4.6,0,4.6}) do part(root,"Window vertical mullion",Vector3.new(.28,8.5,.24),CFrame.new(-36.03,9,z+dz),P.blue,Enum.Material.Wood,false) end
        part(root,"Window horizontal mullion",Vector3.new(.3,.30,14.2),CFrame.new(-36.02,9,z),P.blue,Enum.Material.Wood,false)
        part(root,"Blue curtain valance",Vector3.new(.4,1.8,15),CFrame.new(-35.6,13.5,z),Color3.fromRGB(108,131,162),Enum.Material.Fabric,false)
        for i=0,15 do
            local shade=part(root,"Window blind slat",Vector3.new(.14,.10,14.1),CFrame.new(-35.90,12.9-i*.15,z),Color3.fromRGB(221,217,199),Enum.Material.Fabric,false)
            shade.Transparency=.12
        end
        for _,dz in ipairs({-7.0,7.0}) do
            for fold=0,2 do
                part(root,"Blue curtain fold",Vector3.new(.24,8.35,.28),CFrame.new(-35.57+fold*.08,9,z+dz+fold*.23),Color3.fromRGB(112-fold*8,132-fold*8,159-fold*8),Enum.Material.Fabric,false)
            end
        end
        part(root,"Radiator body",Vector3.new(1.35,3.0,11.7),CFrame.new(-35.2,1.75,z),Color3.fromRGB(177,181,178),Enum.Material.Metal,false)
        for _,rz in ipairs({-4,-2,0,2,4}) do part(root,"Radiator fin",Vector3.new(1.48,2.7,.18),CFrame.new(-34.48,1.75,z+rz),Color3.fromRGB(150,156,155),Enum.Material.Metal,false) end
    end
    -- Warm sunlight washes the front-left classroom corner.
    local sunAnchor=part(root,"Window sun anchor",Vector3.new(.3,.3,.3),CFrame.new(-34,10,-10),Color3.new(1,1,1),Enum.Material.Neon,false);sunAnchor.Transparency=1
    local sun=Instance.new("PointLight");sun.Color=Color3.fromRGB(255,222,165);sun.Brightness=.45;sun.Range=28;sun.Shadows=true;sun.Parent=sunAnchor
end

local function buildFrontWall(root: Instance)
    part(root,"Main chalkboard",Vector3.new(44,8.8,.45),CFrame.new(4,8.1,-34.25),Color3.fromRGB(42,47,45),Enum.Material.SmoothPlastic,false)
    part(root,"Chalkboard wood top",Vector3.new(45,.55,.7),CFrame.new(4,12.75,-34.05),Color3.fromRGB(111,77,50),Enum.Material.Wood,false)
    part(root,"Chalkboard wood bottom",Vector3.new(45,.55,.9),CFrame.new(4,3.55,-33.85),Color3.fromRGB(111,77,50),Enum.Material.Wood,false)
    part(root,"Chalk tray",Vector3.new(29,.38,1.15),CFrame.new(4,3.35,-33.45),Color3.fromRGB(111,77,50),Enum.Material.Wood,false)

    for _,x in ipairs({-18.5,26.5}) do part(root,"Chalkboard wood side",Vector3.new(.5,9.4,.7),CFrame.new(x,8.1,-34.05),P.woodDark,Enum.Material.Wood,false) end
    for i=0,3 do part(root,"Chalk stick",Vector3.new(.85,.14,.14),CFrame.new(-4+i*1.3,3.59,-33.3),P.cream,Enum.Material.SmoothPlastic,false) end
    part(root,"Chalkboard eraser",Vector3.new(1.4,.35,.62),CFrame.new(-8,3.6,-33.4),P.ink,Enum.Material.Fabric,false)
    part(root,"Smartboard dark bezel",Vector3.new(24.05,7.35,.24),CFrame.new(7,8.2,-33.91),P.blue,Enum.Material.SmoothPlastic,false)
    part(root,"Smartboard pen tray",Vector3.new(13,.22,.65),CFrame.new(7,4.61,-33.26),Color3.fromRGB(208,211,209),Enum.Material.Metal,false)
    local smart=part(root,"Interactive smartboard",Vector3.new(23.5,6.8,.35),CFrame.new(7,8.2,-33.65),Color3.fromRGB(238,243,241),Enum.Material.Glass,false);smart.Transparency=.02
    local gui=Instance.new("SurfaceGui");gui.Name="QuestionBoard";gui.Face=Enum.NormalId.Back;gui.CanvasSize=Vector2.new(1200,700);gui.LightInfluence=.05;gui.Parent=smart
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
        surfaceText(tile,string.sub(letters,i,i)..string.lower(string.sub(letters,i,i)),Enum.NormalId.Back,P.blue,tile.Color,Enum.Font.GothamBold)
    end
end

local function buildRightWall(root: Instance)
    sign(root,"Class values","BE KIND\nBE RESPECTFUL\nBE RESPONSIBLE\nBE YOUR BEST\nBE A LIGHT",Vector3.new(7.5,13,.2),CFrame.new(36.45,9,-20)*CFrame.Angles(0,-math.pi/2,0),Color3.fromRGB(242,236,211),Color3.fromRGB(56,93,76))
    sign(root,"All loved sign","ALL ARE LOVED AT ABVM  ♥",Vector3.new(15,4.2,.2),CFrame.new(36.45,13.8,4)*CFrame.Angles(0,-math.pi/2,0),Color3.fromRGB(247,239,214),Color3.fromRGB(52,71,104))
    buildCubbies(root)
    plant(root,32.5,.1,18,.95)
    plant(root,31.5,8.2,-29,.62)
end

local function buildTeacherDesk(root: Instance)
    part(root,"Teacher desk top",Vector3.new(14,.65,6),CFrame.new(25,3.1,-25),Color3.fromRGB(151,109,72),Enum.Material.Wood)
    part(root,"Teacher desk front",Vector3.new(13,3.8,.65),CFrame.new(25,1.65,-27.7),Color3.fromRGB(126,87,59),Enum.Material.Wood)
    for _,x in ipairs({19.2,30.8}) do part(root,"Teacher desk leg",Vector3.new(.55,3.2,.55),CFrame.new(x,1.55,-25),Color3.fromRGB(100,72,53),Enum.Material.Wood) end
    local laptop=part(root,"Teacher laptop screen",Vector3.new(4.6,2.8,.22),CFrame.new(26,5.1,-26.1)*CFrame.Angles(math.rad(-8),0,0),Color3.fromRGB(50,70,82),Enum.Material.Glass,false)
    surfaceText(laptop,"ABVM\nGRADE 2",Enum.NormalId.Back,P.cream,Color3.fromRGB(50,70,82),Enum.Font.GothamBold)
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

local function buildTeacherEntry(root: Instance)
    -- Side staff door and a tiny continuation of the real blue-gray/tan-brick hallway.
    part(root,"Staff door jamb front",Vector3.new(1.3,11.5,1.0),CFrame.new(36.9,5.75,8.3),Color3.fromRGB(113,78,50),Enum.Material.Wood,false)
    part(root,"Staff door jamb back",Vector3.new(1.3,11.5,1.0),CFrame.new(36.9,5.75,22.7),Color3.fromRGB(113,78,50),Enum.Material.Wood,false)
    part(root,"Staff door header",Vector3.new(1.3,1.0,15.4),CFrame.new(36.9,11.25,15.5),Color3.fromRGB(113,78,50),Enum.Material.Wood,false)
    local door=part(root,"Open staff classroom door",Vector3.new(.55,10,6.6),CFrame.new(35.9,5.3,20.2)*CFrame.Angles(0,math.rad(58),0),Color3.fromRGB(124,87,57),Enum.Material.Wood,false)
    local glass=part(root,"Staff door glass",Vector3.new(.18,4.7,3.1),door.CFrame*CFrame.new(-.35,1.6,0),Color3.fromRGB(206,219,216),Enum.Material.Glass,false);glass.Transparency=.28
    part(root,"Side hall floor",Vector3.new(18,.5,20),CFrame.new(45.5,.25,15.5),Color3.fromRGB(67,68,66),Enum.Material.Slate)
    part(root,"Side hall far wall",Vector3.new(1,13,20),CFrame.new(54.5,6.5,15.5),P.blueSoft)
    part(root,"Side hall far brick",Vector3.new(1.1,4.3,20),CFrame.new(54.0,2.15,15.5),Color3.fromRGB(177,122,63),Enum.Material.Brick,false)
    part(root,"Side hall ceiling",Vector3.new(18,.4,20),CFrame.new(45.5,13,15.5),Color3.fromRGB(224,226,223),Enum.Material.SmoothPlastic,false)
    local hallLight=part(root,"Side hall fluorescent",Vector3.new(6,.22,2),CFrame.new(47,12.72,15.5),Color3.fromRGB(250,247,225),Enum.Material.Neon,false)
    local light=Instance.new("SurfaceLight");light.Face=Enum.NormalId.Bottom;light.Brightness=.5;light.Range=15;light.Parent=hallLight
    sign(root,"Staff entry sign","WELCOME  •  ABVM STAFF",Vector3.new(10,2.0,.20),CFrame.new(36.3,13.3,15.5)*CFrame.Angles(0,-math.pi/2,0),Color3.fromRGB(247,237,207),P.blue)
end

local function applyLighting(root: Instance)
    Lighting.ClockTime=10.25;Lighting.Brightness=1.8;Lighting.GlobalShadows=true;Lighting.ShadowSoftness=.3
    Lighting.Ambient=Color3.fromRGB(112,113,112);Lighting.OutdoorAmbient=Color3.fromRGB(183,185,178)
    Lighting.EnvironmentDiffuseScale=.55;Lighting.EnvironmentSpecularScale=.35;Lighting.ExposureCompensation=-.1
    local atmosphere=Lighting:FindFirstChild("EmmaClassroomAtmosphere") or Instance.new("Atmosphere")
    atmosphere.Name="EmmaClassroomAtmosphere";atmosphere.Density=.14;atmosphere.Offset=.15;atmosphere.Color=Color3.fromRGB(221,230,235);atmosphere.Decay=Color3.fromRGB(188,192,185);atmosphere.Haze=.8;atmosphere.Glare=.05;atmosphere.Parent=Lighting
    local bloom=Lighting:FindFirstChild("EmmaClassroomBloom") or Instance.new("BloomEffect")
    bloom.Name="EmmaClassroomBloom";bloom.Intensity=.03;bloom.Size=20;bloom.Threshold=1.25;bloom.Parent=Lighting
    local grade=Lighting:FindFirstChild("EmmaClassroomGrade") or Instance.new("ColorCorrectionEffect")
    grade.Name="EmmaClassroomGrade";grade.Brightness=0;grade.Contrast=.035;grade.Saturation=-.04;grade.TintColor=Color3.fromRGB(255,249,236);grade.Parent=Lighting
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
    part(root,"Left wall below windows",Vector3.new(1,4,62),CFrame.new(-37,2,-4),P.wall)
    part(root,"Left wall above windows",Vector3.new(1,4,62),CFrame.new(-37,16,-4),P.wall)
    for _,span in ipairs({{-30.75,8.5},{-6.5,9.5},{20.25,13.5}}) do
        part(root,"Left window wall pier",Vector3.new(1,10,span[2]),CFrame.new(-37,9,span[1]),P.wall)
    end
    -- Right wall is segmented around the staff entry so the walk-in is visible from Emma's camera.
    part(root,"Right wall front",Vector3.new(1,18,43),CFrame.new(37,9,-13.5),P.wall)
    part(root,"Right wall back",Vector3.new(1,18,4),CFrame.new(37,9,25),P.wall)
    part(root,"Right door header wall",Vector3.new(1,5,15),CFrame.new(37,15.5,15.5),P.wall)
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
    buildTeacherEntry(root)
    buildClassroomTexture(root)
    buildReadingCorner(root)

    -- Paired laminate desks from IMG_2913, with an open back-left reading zone.
    -- Emma remains at x=0 so the existing spawn/seat and study camera stay aligned.
    local index=0
    for row,z in ipairs({-12,4,19}) do
        for col,x in ipairs({-24,-16,-8,0,12,20}) do
            if row<3 or col>2 then
                index+=1;desk(root,x,z,index,row==2 and col==4)
            end
        end
    end

    -- Lived-in details.
    plant(root,-31,.1,20,.85)
    plant(root,-30,8.2,-29,.55)
    sign(root,"Today board","TODAY\n✓ Reading\n✓ Spelling\n✓ Grammar\n✓ Math\n✓ Religion",Vector3.new(8.5,10,.2),CFrame.new(-30,8,-33.82),Color3.fromRGB(49,53,57),Color3.fromRGB(230,229,218))
    sign(root,"Small mission poster","TEACH\nPRAY\nENCOURAGE\nBELONG",Vector3.new(6,7,.2),CFrame.new(33,7,-33.82),Color3.fromRGB(245,239,215),Color3.fromRGB(77,64,47))
    -- Small wall clock.
    local clock=cylinder(root,"Classroom wall clock",Vector3.new(.25,3.2,3.2),CFrame.new(31.5,15.1,-34)*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(242,242,237),Enum.Material.SmoothPlastic,false)
    cylinder(root,"Clock rim",Vector3.new(.34,3.55,3.55),clock.CFrame,Color3.fromRGB(61,63,63),Enum.Material.Metal,false)
    cylinder(root,"Clock visible dial",Vector3.new(.08,3.17,3.17),clock.CFrame*CFrame.new(-.22,0,0),Color3.fromRGB(242,242,237),Enum.Material.SmoothPlastic,false)
    part(root,"Clock minute hand",Vector3.new(.12,1.25,.12),CFrame.new(31.5,15.55,-33.78)*CFrame.Angles(0,0,math.rad(-20)),Color3.fromRGB(48,49,49),Enum.Material.Metal,false)
    part(root,"Clock hour hand",Vector3.new(.12,.85,.12),CFrame.new(31.5,15.25,-33.75)*CFrame.Angles(0,0,math.rad(45)),Color3.fromRGB(48,49,49),Enum.Material.Metal,false)

    -- Warm fluorescent lighting.
    for _,x in ipairs({-22,0,22}) do
        for _,z in ipairs({-22,0,20}) do ceilingLight(root,x,z) end
    end

    local spawn=Instance.new("SpawnLocation")
    spawn.Name="EmmaSeatSpawn";spawn.Size=Vector3.new(5,1,5);spawn.CFrame=CFrame.new(0,1,10)*CFrame.Angles(0,math.pi,0)
    spawn.Transparency=1;spawn.CanCollide=false;spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=root
    local seat=Instance.new("Seat")
    seat.Name="EmmaSeat";seat.Size=Vector3.new(2.6,.8,2.4);seat.CFrame=CFrame.new(0,1.9,8.4)*CFrame.Angles(0,math.pi,0)
    seat.Transparency=1;seat.CanCollide=false;seat.Anchored=true;seat.Parent=root

    World.Root=root
    World.Spawn=spawn.CFrame
    World.EmmaSeat=seat
    World.TeacherDoor=CFrame.new(45,3.15,15.5)*CFrame.Angles(0,math.pi,0)
    World.TeacherFront=CFrame.new(-10,3.15,-20)*CFrame.Angles(0,math.pi,0)
    World.TeacherPath={CFrame.new(29,3.15,15.5),CFrame.new(29,3.15,-20),World.TeacherFront}
    World.resetBoard()
    return World
end

function World.teacherModel(teacher)
    return StaffModel.create(teacher)
end

function World.poseTeacher(model: Model,phase: number,walking: boolean)
    StaffModel.pose(model,phase,walking)
end

function World.moveTeacher(model: Model,target: CFrame,duration: number)
    local start=model:GetPivot()
    local startPos=start.Position
    local targetPos=target.Position
    local direction=Vector3.new(targetPos.X-startPos.X,0,targetPos.Z-startPos.Z)
    local alpha=Instance.new("NumberValue");alpha.Value=0
    local conn=alpha:GetPropertyChangedSignal("Value"):Connect(function()
        if not model.Parent then return end
        local a=alpha.Value
        local pos=startPos:Lerp(targetPos,a)
        local base
        if direction.Magnitude>.05 and a<.94 then
            base=CFrame.lookAt(pos,pos+direction.Unit)
        else
            base=CFrame.new(pos)*target.Rotation
        end
        local bob=math.abs(math.sin(a*math.pi*8))*.08
        model:PivotTo(base*CFrame.new(0,bob,0))
        World.poseTeacher(model,a*direction.Magnitude*1.3,true)
    end)
    local tween=TweenService:Create(alpha,TweenInfo.new(duration,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value=1})
    tween:Play();tween.Completed:Wait();conn:Disconnect();alpha:Destroy()
    if model.Parent then model:PivotTo(target);World.poseTeacher(model,0,false) end
end

function World.walkTeacher(model:Model,entering:boolean)
    if entering then
        for _,point in ipairs(World.TeacherPath) do
            if not model.Parent then return end
            World.moveTeacher(model,point,math.max(.25,(model:GetPivot().Position-point.Position).Magnitude/16))
        end
    else
        for _,point in ipairs({World.TeacherPath[2],World.TeacherPath[1],World.TeacherDoor}) do
            if not model.Parent then return end
            World.moveTeacher(model,point,math.max(.25,(model:GetPivot().Position-point.Position).Magnitude/16))
        end
    end
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

function World.setBoardQuestion(subject: string,teacher: string,prompt: string,choices:{string}?)
    if World.BoardSubject then World.BoardSubject.Text=subject.."  •  "..teacher end
    if World.BoardQuestion then
        local lines={prompt}
        if choices then
            for i,choice in ipairs(choices) do
                lines[#lines+1]=string.char(64+i)..".  "..choice
            end
        end
        World.BoardQuestion.Text=table.concat(lines,"\n")
    end
    if World.BoardFooter then World.BoardFooter.Text="Choose A, B, C or D below. Take your time." end
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
