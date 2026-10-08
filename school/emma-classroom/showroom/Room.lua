--!strict
-- ABVM classroom-only architectural room. Derived from the photo-guided room
-- without teacher/gameplay constructs, and compiled into a separate Rojo place.
local Workspace=game:GetService("Workspace")
local Lighting=game:GetService("Lighting")

local ArtPass=require(script.Parent:WaitForChild("ArtPass"))
local World={}

local P={
    wall=Color3.fromRGB(238,228,207),
    blue=Color3.fromRGB(52,73,108),
    blueSoft=Color3.fromRGB(101,132,147),
    green=Color3.fromRGB(28,82,59),
    gold=Color3.fromRGB(238,203,99),
    wood=Color3.fromRGB(137,96,62),
    woodDark=Color3.fromRGB(119,87,61),
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

-- Rounded laminate/plastic outlines with a shallow dark edge band.
-- Core collision stays simple; corner detail never obstructs an aisle.
local function roundedPanel(parent:Instance,name:string,size:Vector3,cf:CFrame,color:Color3,r:number,horizontal:boolean,collide:boolean?):Part
    local w=Vector3.new(size.X,horizontal and size.Z or size.Y,horizontal and size.Y or size.Z)
    local base=horizontal and cf*CFrame.Angles(-math.pi/2,0,0) or cf
    local core=part(parent,name,Vector3.new(w.X-2*r,w.Y,w.Z),base,color,Enum.Material.SmoothPlastic,collide)
    part(parent,name.." center",Vector3.new(w.X,w.Y-2*r,w.Z),base,color,Enum.Material.SmoothPlastic,false)
    for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do
        cylinder(parent,name.." rounded corner",Vector3.new(w.Z,r*2,r*2),base*CFrame.new(x*(w.X/2-r),y*(w.Y/2-r),0)*CFrame.Angles(0,math.pi/2,0),color,Enum.Material.SmoothPlastic,false)
    end end
    return core
end

local function surfaceText(target: BasePart,text: string,face: Enum.NormalId,textColor: Color3,bg: Color3,font: Enum.Font?): TextLabel
    local gui=Instance.new("SurfaceGui")
    gui.Name="Surface";gui.Face=face;local width=target.Size.X
    local height=face==Enum.NormalId.Top and target.Size.Z or target.Size.Y
    if face==Enum.NormalId.Left or face==Enum.NormalId.Right then width=target.Size.Z end
    gui.CanvasSize=Vector2.new(1000,math.max(80,math.floor(1000*height/width)));gui.LightInfluence=.15;gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;gui.Parent=target
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
    -- Actual ceiling fixtures use a recessed matte troffer and a small diffusing
    -- lens. Nine enormous Neon slabs looked like glowing television panels.
    part(parent,"Recessed light trim",Vector3.new(6.9,.12,2.03),CFrame.new(x,17.72,z),
        Color3.fromRGB(207,208,204),Enum.Material.Metal,false)
    local lens=part(parent,"Frosted fluorescent diffuser",Vector3.new(6.3,.08,1.52),
        CFrame.new(x,17.59,z),Color3.fromRGB(246,241,223),Enum.Material.Glass,false)
    lens.Transparency=.10;lens.Reflectance=.005
    local light=Instance.new("SurfaceLight")
    light.Face=Enum.NormalId.Bottom;light.Color=Color3.fromRGB(250,240,220)
    light.Brightness=.13;light.Range=25;light.Angle=115;light.Shadows=false;light.Parent=lens
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
    local cf=CFrame.new(x,y,z)*CFrame.Angles(0,rotation,0)
    roundedPanel(parent,"Classroom book",Vector3.new(2.15,.18,2.85),cf,color,.10,true,false)
    part(parent,"Book pages",Vector3.new(1.94,.12,2.65),cf*CFrame.new(.015,.14,0),P.cream,Enum.Material.SmoothPlastic,false)
    part(parent,"Notebook spine",Vector3.new(.12,.15,2.85),cf*CFrame.new(-1.04,.14,0),color:Lerp(P.ink,.14),Enum.Material.SmoothPlastic,false)
end

local function pencilCup(parent: Instance,x: number,y: number,z: number)
    cylinder(parent,"Pencil cup",Vector3.new(1.6,1.3,1.3),CFrame.new(x,y,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(187,192,194),Enum.Material.Metal,false)
    local colors={Color3.fromRGB(229,184,57),Color3.fromRGB(211,73,64),Color3.fromRGB(65,126,182),Color3.fromRGB(57,142,88)}
    for i,c in ipairs(colors) do
        part(parent,"Pencil",Vector3.new(.16,2.2,.16),CFrame.new(x-.35+i*.18,y+1.25,z),c,Enum.Material.Wood,false)
    end
end

local function schoolChair(parent: Instance,name: string,x: number,z: number,tint: Color3)
    -- Child-scale molded school seating. The v63 chair backs were towering blue
    -- rectangles, nearly as wide as the tabletop in iPhone screenshots.
    local seat=roundedPanel(parent,name.." seat",Vector3.new(2.5,.24,2.18),CFrame.new(x,1.62,z),
        tint,.23,true,true)
    seat.Reflectance=.015
    local backCF=CFrame.new(x,2.88,z+.93)*CFrame.Angles(math.rad(-8),0,0)
    -- An invisible single-part collision silhouette avoids thousands of
    -- collidable little pieces. The shell itself is visible, but decorative.
    local backCollider=part(parent,name.." contoured back collision",
        Vector3.new(2.38,1.90,.22),backCF,tint,Enum.Material.SmoothPlastic,true)
    backCollider.Transparency=1
    backCollider.CanQuery=false
    -- Four gently inclined molded bands form a shallow ergonomic curve.
    -- The two ends taper rather than presenting the old square plastic slab.
    local bandProfile={
        {-.69,2.03,.15,-8},
        {-.23,2.43,.045,-3},
        {.23,2.50,-.055,3},
        {.69,2.13,-.16,9},
    }
    for i,band in ipairs(bandProfile) do
        local frame=backCF*CFrame.new(0,band[1],band[3])*
            CFrame.Angles(math.rad(band[4]),0,0)
        local finish=tint:Lerp(P.cream,.11+i*.012)
        part(parent,name.." molded back panel",Vector3.new(band[2]-.17,.52,.17),
            frame,finish,Enum.Material.SmoothPlastic,false)
        for _,side in ipairs({-1,1}) do
            ball(parent,name.." molded side return",Vector3.new(.23,.54,.21),
                frame*CFrame.new(side*(band[2]/2-.12),0,0),
                finish,Enum.Material.SmoothPlastic,false)
        end
    end
    -- A small recessed grip, inset fasteners and visible chair-frame supports
    -- read as manufactured furniture rather than a colored rectangular wall.
    roundedPanel(parent,name.." hand grip",Vector3.new(.96,.14,.027),
        backCF*CFrame.new(0,.58,-.215),tint:Lerp(P.ink,.28),
        .055,false,false)
    for _,dx in ipairs({-.82,.82}) do
        for _,dz in ipairs({-.66,.66}) do
            cylinder(parent,name.." tubular leg",Vector3.new(1.43,.14,.14),
                CFrame.new(x+dx,.76,z+dz)*CFrame.Angles(0,0,math.pi/2),
                P.metal,Enum.Material.Metal,true)
            cylinder(parent,name.." rubber foot",Vector3.new(.19,.20,.20),
                CFrame.new(x+dx,.13,z+dz)*CFrame.Angles(0,0,math.pi/2),
                P.ink,Enum.Material.SmoothPlastic,false)
        end
        cylinder(parent,name.." back support",Vector3.new(2.20,.13,.13),
            CFrame.new(x+dx,2.47,z+.73)*CFrame.Angles(0,0,math.pi/2),
            P.metal,Enum.Material.Metal,false)
        -- Slim horizontal under-seat steel runners are aligned with the
        -- chair seat. These reinforce the real frame silhouette at eye level.
        cylinder(parent,name.." underseat frame runner",Vector3.new(1.65,.13,.13),
            CFrame.new(x+dx,1.41,z)*CFrame.Angles(0,math.pi/2,0),
            P.metal,Enum.Material.Metal,false)
        ball(parent,name.." backrest rivet",Vector3.new(.14,.14,.08),
            backCF*CFrame.new(dx,-.38,-.18),P.metal,Enum.Material.Metal,false)
    end
end
local function desk(parent: Instance,x: number,z: number,index: number,emma: boolean)
    -- Subtle laminate variation prevents an identical 16-copy furniture grid.
    -- Keep the collision silhouette unchanged for every student.
    local laminates={
        Color3.fromRGB(197,173,130), Color3.fromRGB(206,179,138),
        Color3.fromRGB(193,169,123), Color3.fromRGB(199,176,137),
    }
    roundedPanel(parent,"Student desk edge",Vector3.new(5.78,.16,3.86),CFrame.new(x,2.97,z),
        Color3.fromRGB(126,121,109),.21,true,true)
    roundedPanel(parent,"Student desk top",Vector3.new(5.72,.12,3.80),CFrame.new(x,3.11,z),
        laminates[(index-1)%#laminates+1],.23,true,false)
    for _,dx in ipairs({-2.22,2.22}) do
        cylinder(parent,"Desk tubular leg",Vector3.new(2.75,.23,.23),CFrame.new(x+dx,1.5,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(133,139,143),Enum.Material.Metal,true)
        part(parent,"Desk foot",Vector3.new(.52,.16,3.10),CFrame.new(x+dx,.18,z),Color3.fromRGB(76,82,86),Enum.Material.Metal)
    end
    -- Match an elementary school desk's thin rim and underdesk wire basket
    -- rather than a thick floating black platform. These details are non-solid
    -- and do not change desk collision or the aisle footprints.
    part(parent,"Desk laminated front bevel",Vector3.new(5.08,.105,.085),
        CFrame.new(x,3.01,z-1.88),Color3.fromRGB(146,129,107),
        Enum.Material.SmoothPlastic,false)
    part(parent,"Desk book tray",Vector3.new(4.75,.10,3.08),
        CFrame.new(x,2.30,z),Color3.fromRGB(103,109,111),
        Enum.Material.Metal,false)
    for _,dx in ipairs({-2.35,2.35}) do
        part(parent,"Book tray side",Vector3.new(.10,.42,3.08),
            CFrame.new(x+dx,2.49,z),P.metal,Enum.Material.Metal,false)
    end
    cylinder(parent,"Desk shelf front restraint",Vector3.new(4.56,.12,.12),
        CFrame.new(x,2.36,z-1.44),P.metal,Enum.Material.Metal,false)
    cylinder(parent,"Desk back steel stretcher",Vector3.new(4.44,.14,.14),
        CFrame.new(x,1.46,z+1.34),Color3.fromRGB(120,130,134),
        Enum.Material.Metal,false)
    book(parent,x,2.58,z,Color3.fromRGB(70,106,133),0)
    local upholstery={
        Color3.fromRGB(67,94,130),Color3.fromRGB(78,107,136),
        Color3.fromRGB(65,93,119),Color3.fromRGB(83,109,134),
    }
    schoolChair(parent,"Student chair",x,z+3.48,upholstery[(index-1)%#upholstery+1])
    local notebookColor=({Color3.fromRGB(217,91,104),Color3.fromRGB(63,130,181),Color3.fromRGB(98,150,101),Color3.fromRGB(220,173,66)})[(index-1)%4+1]
    -- Not every child leaves precisely the same notebook in precisely the
    -- same position; preserve the stationery count without uniform patterns.
    local shift=(index%3-1)*.24
    book(parent,x-1.2+shift,3.28,z-.2,notebookColor,math.rad(index%2==0 and 7 or -6))
    cylinder(parent,"Desk pencil",Vector3.new(1.75,.10,.10),CFrame.new(x+1.4,3.28,z-.6)*CFrame.Angles(0,math.rad(108),0),Color3.fromRGB(239,190,56),Enum.Material.Wood,false)
    local pencilCF=CFrame.new(x+1.4,3.28,z-.6)*CFrame.Angles(0,math.rad(18),0)
    part(parent,"Pencil ferrule",Vector3.new(.11,.11,.18),pencilCF*CFrame.new(0,0,.70),P.metal,Enum.Material.Metal,false)
    part(parent,"Pencil eraser",Vector3.new(.10,.10,.17),pencilCF*CFrame.new(0,0,.85),Color3.fromRGB(223,139,156),Enum.Material.SmoothPlastic,false)
    local nameStrip=part(parent,"Desk name strip",Vector3.new(2.7,.014,.43),CFrame.new(x+.35,3.183,z-1.40),P.cream,Enum.Material.SmoothPlastic,false)
    surfaceText(nameStrip,emma and "Emma" or "Grade 2",Enum.NormalId.Top,P.blue,P.cream)
    local notebookCF=CFrame.new(x-1.2+shift,3.28,z-.2)*CFrame.Angles(0,math.rad(index%2==0 and 7 or -6),0)
    local paper=part(parent,"Ruled notebook page",Vector3.new(1.86,.012,2.48),notebookCF*CFrame.new(.055,.165,0),Color3.fromRGB(253,250,237),Enum.Material.SmoothPlastic,false)
    -- Keep three readable rules spread over the page rather than seven
    -- hairline Parts concentrated into the same small strip on every desk.
    for line=0,2 do
        part(parent,"Notebook ruled line",Vector3.new(1.61,.004,.014),
            paper.CFrame*CFrame.new(.03,.010,-.75+line*.70),
            Color3.fromRGB(146,180,209),Enum.Material.SmoothPlastic,false)
    end
    part(parent,"Notebook red margin",Vector3.new(.014,.004,2.30),paper.CFrame*CFrame.new(-.59,.012,0),Color3.fromRGB(218,133,143),Enum.Material.SmoothPlastic,false)
    -- One fine steel binding rail reads crisply at phone scale; the former
    -- 96 microscopic rings bloated scene replication without visual benefit.
    part(parent,"Notebook binding rail",Vector3.new(.11,.075,2.40),
        notebookCF*CFrame.new(-.98,.17,0),P.metal,Enum.Material.Metal,false)
    for _,dx in ipairs({-2.22,2.22}) do
        ball(parent,"Desk assembly bolt",Vector3.new(.13,.13,.07),CFrame.new(x+dx,2.68,z-1.52),P.metal,Enum.Material.Metal,false)
        part(parent,"Desk rubber glide",Vector3.new(.63,.18,.58),CFrame.new(x+dx,.19,z-1.30),P.ink,Enum.Material.SmoothPlastic,false)
        part(parent,"Desk rubber glide",Vector3.new(.63,.18,.58),CFrame.new(x+dx,.19,z+1.30),P.ink,Enum.Material.SmoothPlastic,false)
    end
    if emma then
        local tag=part(parent,"Emma desk nameplate",Vector3.new(3.8,.55,.16),CFrame.new(x,3.42,z-1.98)*CFrame.Angles(math.rad(-10),0,0),P.green,Enum.Material.SmoothPlastic,false)
        surfaceText(tag,"★ EMMA ★",Enum.NormalId.Back,P.gold,P.green)
        cylinder(parent,"Emma pink water bottle",Vector3.new(1.10,.55,.55),
            CFrame.new(x+2.12,3.77,z+.45)*CFrame.Angles(0,0,math.pi/2),
            Color3.fromRGB(225,125,154),Enum.Material.SmoothPlastic,false)
        part(parent,"Water bottle cap",Vector3.new(.42,.17,.42),
            CFrame.new(x+2.12,4.38,z+.45),Color3.fromRGB(190,86,124),Enum.Material.SmoothPlastic,false)
    end
end

local function bulletinBoard(parent: Instance,name: string,x: number,y: number,z: number,width: number,height: number,title: string)
    local frame=part(parent,name.." wood frame",Vector3.new(width+.8,height+.8,.32),CFrame.new(x,y,z),Color3.fromRGB(105,73,48),Enum.Material.Wood,false)
    local cork=part(parent,name.." cork",Vector3.new(width,height,.18),CFrame.new(x,y,z-.19),Color3.fromRGB(168,122,75),Enum.Material.Fabric,false)
    local titleLabel=surfaceText(cork,title,Enum.NormalId.Back,P.cream,cork.Color,Enum.Font.GothamBold)
    titleLabel.Position=UDim2.fromScale(.08,.02);titleLabel.Size=UDim2.fromScale(.84,.18)
    titleLabel.BackgroundTransparency=1
    return frame
end

local function buildClassroomTexture(root: Instance)
    -- The real school photos are busy, old, warm and layered. This deliberately kills the sterile showroom look.
    -- Small pieces of work belong inside framed boards, with breathable margins.
    bulletinBoard(root,"Student work board",-26,9,-33.65,12,7.0,"OUR WORK")

    -- No oversized individual rules: GalleryPass owns a restrained framed
    -- values board and keeps this wall clear of overlapping flat panels.

    -- Pencil sharpener, trash bin, tissue box, storage cabinet, rolling cart.
    part(root,"Tall storage cabinet",Vector3.new(7,12,3.2),CFrame.new(31,6,22.7),Color3.fromRGB(124,102,79),Enum.Material.Wood)
    part(root,"Cabinet center seam",Vector3.new(.065,11.1,.06),CFrame.new(31,6,21.03),Color3.fromRGB(61,48,36),Enum.Material.Wood,false)
    for _,x in ipairs({29.3,32.7}) do
        part(root,"Cabinet door panel",Vector3.new(3.08,10.9,.10),CFrame.new(x,6,21.03),Color3.fromRGB(152,119,82),Enum.Material.Wood,false)
        for _,y in ipairs({3.2,8.4}) do
            part(root,"Cabinet inset panel",Vector3.new(2.60,4.4,.06),CFrame.new(x,y,20.94),Color3.fromRGB(135,105,74),Enum.Material.Wood,false)
            for _,dx in ipairs({-1.31,1.31}) do part(root,"Cabinet panel stile",Vector3.new(.055,4.55,.045),CFrame.new(x+dx,y,20.90),Color3.fromRGB(178,142,98),Enum.Material.Wood,false) end
        end
        part(root,"Cabinet door pull",Vector3.new(.13,1.15,.18),CFrame.new(x+(x<31 and .91 or -.91),6.2,20.79),Color3.fromRGB(180,176,158),Enum.Material.Metal,false)
        for _,y in ipairs({1.8,10.2}) do part(root,"Cabinet brass hinge",Vector3.new(.14,.42,.15),CFrame.new(x+(x<31 and -1.50 or 1.50),y,20.88),Color3.fromRGB(167,149,101),Enum.Material.Metal,false) end
    end
    local trash=cylinder(root,"Classroom trash can",Vector3.new(3.4,3.1,3.1),CFrame.new(32.8,1.7,-24)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(95,100,101),Enum.Material.Metal,false)
    trash.Transparency=0
    cylinder(root,"Trash can opening",Vector3.new(.035,2.76,2.76),CFrame.new(32.8,3.42,-24)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(32,36,38),Enum.Material.SmoothPlastic,false)
    for i=0,15 do
        local a=i*math.pi/8
        cylinder(root,"Trash can rib",Vector3.new(2.85,.055,.055),CFrame.new(32.8+math.cos(a)*1.55,1.75,-24+math.sin(a)*1.55)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(137,142,141),Enum.Material.Metal,false)
    end
    local tissues=part(root,"Tissue box",Vector3.new(2.3,1.2,1.7),CFrame.new(22.5,4.05,-23.6),Color3.fromRGB(116,177,193),Enum.Material.SmoothPlastic,false)
    surfaceText(tissues,"TISSUES",Enum.NormalId.Front,Color3.fromRGB(245,248,244),tissues.Color,Enum.Font.GothamBold)
    part(root,"Tissue box slot",Vector3.new(1.25,.015,.24),CFrame.new(22.5,4.66,-23.6),P.ink,Enum.Material.SmoothPlastic,false)
    part(root,"Folded tissue",Vector3.new(.80,.77,.018),CFrame.new(22.5,4.94,-23.6)*CFrame.Angles(math.rad(12),0,math.rad(-8)),P.cream,Enum.Material.Fabric,false)
    part(root,"Rolling cart top",Vector3.new(5.5,.4,3.2),CFrame.new(-29,3.5,22),Color3.fromRGB(71,105,125),Enum.Material.Metal)
    for _,y in ipairs({1.0,2.1,3.2}) do part(root,"Rolling cart shelf",Vector3.new(5.2,.22,3),CFrame.new(-29,y,22),Color3.fromRGB(82,119,139),Enum.Material.Metal,false) end
    for _,x in ipairs({-31.2,-26.8}) do
        for _,z in ipairs({20.8,23.2}) do cylinder(root,"Cart wheel",Vector3.new(.35,.75,.75),CFrame.new(x,.45,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(45,48,49),Enum.Material.SmoothPlastic,false) end
    end

    for _,x in ipairs({-31.2,-26.8}) do for _,z in ipairs({20.8,23.2}) do
        cylinder(root,"Cart vertical rail",Vector3.new(3.15,.12,.12),CFrame.new(x,1.9,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(150,165,170),Enum.Material.Metal,false)
    end end
    book(root,-29.8,3.82,21.7,P.blue,.05)
    book(root,-29.8,4.09,21.7,P.green,-.07)
    part(root,"Cart paper stack",Vector3.new(2.1,.24,2.5),CFrame.new(-27.6,2.35,21.9),P.cream,Enum.Material.SmoothPlastic,false)
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
    -- Place each basket on a REAL middle-row desktop; the old values were
    -- mid-gap between neighboring tables and the bins appeared to float.
    for i,x in ipairs({-24,-8,12}) do
        local color=basketColors[i]
        part(root,"Supply basket",Vector3.new(2.8,.11,1.8),CFrame.new(x,3.24,4.8),color,Enum.Material.SmoothPlastic,false)
        for _,dz in ipairs({-.83,.83}) do part(root,"Basket long rim",Vector3.new(2.8,.65,.13),CFrame.new(x,3.55,4.8+dz),color,Enum.Material.SmoothPlastic,false) end
        for _,dx in ipairs({-1.33,1.33}) do part(root,"Basket end rim",Vector3.new(.13,.65,1.6),CFrame.new(x+dx,3.55,4.8),color,Enum.Material.SmoothPlastic,false) end
        for j=0,3 do part(root,"Basket pencil",Vector3.new(.09,.09,2.2),CFrame.new(x-.75+j*.42,3.36,4.8)*CFrame.Angles(0,math.rad(75+j*7),0),P.gold,Enum.Material.SmoothPlastic,false) end
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
    -- Six synthetic artwork panels were duplicated on the front chalkboard.
    -- A dedicated single student gallery remains on the back wall.

end

local function buildCubbies(root: Instance)
    part(root,"Cubbies wood surround",Vector3.new(27,8,.24),CFrame.new(21,4.2,26.5),Color3.fromRGB(142,103,68),Enum.Material.Wood)
    for _,y in ipairs({.28,4.2,8.2}) do part(root,"Cubbie open shelf",Vector3.new(27,.22,3),CFrame.new(21,y,25.2),P.wood,Enum.Material.Wood,false) end
    for i=0,6 do part(root,"Cubbie divider",Vector3.new(.18,8,3),CFrame.new(7.5+i*4.5,4.2,25.2),P.wood,Enum.Material.Wood,false) end
    local binColors={
        Color3.fromRGB(67,129,183),Color3.fromRGB(229,112,103),Color3.fromRGB(97,150,90),
        Color3.fromRGB(233,182,67),Color3.fromRGB(157,105,176),Color3.fromRGB(74,155,148),
    }
    local n=0
    for row=0,1 do
        for col=0,5 do
            n+=1
            local x=9.75+col*4.5;local y=1.75+row*3.95
            local color=binColors[(n-1)%#binColors+1]
            local cf=CFrame.new(x,y-.2,24.8)
            part(root,"Cubbie bin",Vector3.new(3.55,.15,2.45),cf*CFrame.new(0,-.60,0),color,Enum.Material.SmoothPlastic,false)
            for _,dx in ipairs({-1.70,1.70}) do part(root,"Bin side",Vector3.new(.15,1.45,2.45),cf*CFrame.new(dx,0,0),color,Enum.Material.SmoothPlastic,false) end
            for _,dz in ipairs({-1.15,1.15}) do part(root,"Bin front and back",Vector3.new(3.4,1.45,.15),cf*CFrame.new(0,0,dz),color,Enum.Material.SmoothPlastic,false) end
            roundedPanel(root,"Bin label",Vector3.new(1.2,.43,.025),cf*CFrame.new(0,.18,-1.235),P.cream,.08,false,false)
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
        part(root,"Radiator body",Vector3.new(1.35,2.6,11.7),CFrame.new(-35.2,1.75,z),Color3.fromRGB(222,221,207),Enum.Material.Metal,false)
        for rz=-5,5,.5 do part(root,"Radiator fin",Vector3.new(1.48,2.7,.18),CFrame.new(-34.48,1.75,z+rz),Color3.fromRGB(201,204,196),Enum.Material.Metal,false) end
    end
    -- Warm sunlight washes the front-left classroom corner.
    local sunAnchor=part(root,"Window sun anchor",Vector3.new(.3,.3,.3),CFrame.new(-34,10,-10),Color3.new(1,1,1),Enum.Material.Neon,false);sunAnchor.Transparency=1
    local sun=Instance.new("PointLight");sun.Color=Color3.fromRGB(255,246,225);sun.Brightness=.50;sun.Range=48;sun.Shadows=true;sun.Parent=sunAnchor
end

local function buildFrontWall(root: Instance)
    -- Architectural teaching wall: a realistic separate chalkboard beside the
    -- existing smartboard, not a 44-stud black plate behind both displays.
    part(root,"Main chalkboard",Vector3.new(15.8,7.55,.30),CFrame.new(-13.7,8.1,-34.14),Color3.fromRGB(43,54,50),Enum.Material.SmoothPlastic,false)
    for _,y in ipairs({4.20,12.0}) do
        part(root,"Chalkboard hardwood horizontal",Vector3.new(16.5,.48,.60),CFrame.new(-13.7,y,-34.0),
            Color3.fromRGB(119,83,53),Enum.Material.Wood,false)
    end
    for _,x in ipairs({-21.95,-5.45}) do
        part(root,"Chalkboard hardwood stile",Vector3.new(.42,7.85,.58),CFrame.new(x,8.1,-34.0),
            Color3.fromRGB(119,83,53),Enum.Material.Wood,false)
    end
    part(root,"Chalk tray",Vector3.new(15.5,.18,.80),CFrame.new(-13.7,4.02,-33.63),Color3.fromRGB(129,92,57),Enum.Material.Wood,false)
    for i=0,3 do
        part(root,"Chalk stick",Vector3.new(.58,.095,.095),CFrame.new(-19+i*.66,4.16,-33.37),
            P.cream,Enum.Material.SmoothPlastic,false)
    end
    part(root,"Chalkboard eraser",Vector3.new(1.20,.28,.51),CFrame.new(-12,4.2,-33.38),P.ink,Enum.Material.Fabric,false)
    part(root,"Smartboard dark bezel",Vector3.new(24.05,7.35,.24),CFrame.new(7,8.2,-33.91),P.blue,Enum.Material.SmoothPlastic,false)
    part(root,"Smartboard pen tray",Vector3.new(13,.22,.65),CFrame.new(7,4.61,-33.26),Color3.fromRGB(208,211,209),Enum.Material.Metal,false)
    local smart=part(root,"Interactive smartboard",Vector3.new(23.5,6.8,.35),CFrame.new(7,8.2,-33.65),Color3.fromRGB(238,243,241),Enum.Material.Glass,false);smart.Transparency=.02
    -- Static architectural smartboard. GalleryPass supplies a non-interactive display.


    -- Cross, motto, alphabet strip and classroom values from the target concept.
    part(root,"Classroom cross vertical",Vector3.new(1,4.8,.45),CFrame.new(32,10,-33.9),Color3.fromRGB(104,72,46),Enum.Material.Wood,false)
    part(root,"Classroom cross horizontal",Vector3.new(3.5,1,.45),CFrame.new(32,10.7,-33.72),Color3.fromRGB(104,72,46),Enum.Material.Wood,false)
    sign(root,"Light banner","LET YOUR LIGHT SHINE  •  MATTHEW 5:16",Vector3.new(29,2.0,.2),CFrame.new(-6,15.0,-33.85),Color3.fromRGB(248,239,213),Color3.fromRGB(78,65,48))
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
    roundedPanel(root,"Teacher desk top",Vector3.new(12.5,.38,5.2),CFrame.new(25,3.1,-25),Color3.fromRGB(177,140,95),.26,true,true)
    part(root,"Teacher desk front",Vector3.new(11.75,3.4,.42),CFrame.new(25,1.65,-27.15),Color3.fromRGB(126,87,59),Enum.Material.Wood)
    for _,x in ipairs({19.2,30.8}) do part(root,"Teacher desk leg",Vector3.new(.55,3.2,.55),CFrame.new(x,1.55,-25),Color3.fromRGB(100,72,53),Enum.Material.Wood) end
    for _,x in ipairs({20.7,29.3}) do
        part(root,"Teacher drawer pedestal",Vector3.new(3.8,2.9,4.9),CFrame.new(x,1.65,-25),P.wood,Enum.Material.Wood,false)
        for row=0,2 do
            part(root,"Teacher inset drawer",Vector3.new(3.48,.78,.12),CFrame.new(x,.72+row*.88,-22.48),Color3.fromRGB(166,129,86),Enum.Material.Wood,false)
            part(root,"Teacher drawer handle",Vector3.new(1.02,.10,.18),CFrame.new(x,.84+row*.88,-22.29),P.metal,Enum.Material.Metal,false)
        end
    end
    local screenCF=CFrame.new(26,5.1,-26.1)*CFrame.Angles(math.rad(-8),0,0)
    roundedPanel(root,"Laptop display frame",Vector3.new(4.6,2.8,.20),screenCF,Color3.fromRGB(38,42,48),.12,false,false)
    local laptop=part(root,"Teacher laptop screen",Vector3.new(4.23,2.40,.025),screenCF*CFrame.new(0,.03,.12),Color3.fromRGB(225,238,236),Enum.Material.SmoothPlastic,false)
    local display=surfaceText(laptop,"TODAY'S LESSON\nReading • Math • Spelling",Enum.NormalId.Back,P.blue,Color3.fromRGB(225,238,236),Enum.Font.GothamMedium)
    display.BackgroundTransparency=0
    ball(root,"Laptop webcam",Vector3.new(.065,.065,.025),screenCF*CFrame.new(0,1.29,.12),P.ink,Enum.Material.Glass,false)
    roundedPanel(root,"Teacher laptop base",Vector3.new(4.8,.20,3.1),CFrame.new(26,3.55,-24.85),Color3.fromRGB(162,167,173),.14,true,false)
    local keyboardCF=CFrame.new(26,3.67,-25.20)
    for row=0,3 do for col=0,9 do
        part(root,"Laptop keyboard key",Vector3.new(.34,.045,.28),keyboardCF*CFrame.new(-1.82+col*.40,0,-.50+row*.34),Color3.fromRGB(48,51,58),Enum.Material.SmoothPlastic,false)
    end end
    part(root,"Laptop space bar",Vector3.new(1.7,.04,.23),CFrame.new(26,3.68,-24.32),P.ink,Enum.Material.SmoothPlastic,false)
    roundedPanel(root,"Laptop trackpad",Vector3.new(1.48,.016,.68),CFrame.new(26,3.68,-23.87),Color3.fromRGB(119,126,136),.06,true,false)
    cylinder(root,"Laptop hinge",Vector3.new(4.30,.16,.16),CFrame.new(26,3.69,-26.12),P.metal,Enum.Material.Metal,false)
    pencilCup(root,21.5,4.4,-24.2)
    book(root,29.5,3.62,-24.2,Color3.fromRGB(61,110,78),math.rad(8))
    book(root,29.5,3.95,-24.2,Color3.fromRGB(44,75,110),math.rad(8))
    -- Tilted globe: continents follow the sphere, with a meridian cradle and
    -- latitude lines. No rectangular land plate sticking off the sphere.
    local center=CFrame.new(20.55,5.87,-26.4)*CFrame.Angles(0,0,math.rad(-23))
    local radius=1.90
    ball(root,"Classroom globe",Vector3.new(radius*2,radius*2,radius*2),center,Color3.fromRGB(100,167,191),Enum.Material.SmoothPlastic,false)
    local function arc(name,r,tilt,color,thickness)
        local frame=center*CFrame.Angles(tilt,0,0)
        for i=0,23 do
            local a,b=i*math.pi/12,(i+1)*math.pi/12
            local u=(frame*CFrame.new(math.cos(a)*r,math.sin(a)*r,0)).Position
            local v=(frame*CFrame.new(math.cos(b)*r,math.sin(b)*r,0)).Position
            local midpoint=(u+v)*.5
            local cf=CFrame.lookAt(midpoint,v)*CFrame.Angles(0,math.pi/2,0)
            cylinder(root,name,Vector3.new((v-u).Magnitude+.015,thickness,thickness),cf,color,Enum.Material.Metal,false)
        end
    end
    arc("Globe meridian cradle",2.07,0,Color3.fromRGB(177,155,94),.065)
    arc("Globe equator",1.91,math.pi/2,Color3.fromRGB(208,219,191),.018)
    -- Small low-relief land patches: positions are latitude / longitude.
    for _,patch in ipairs({{48,-110,.83,.61},{28,-100,.60,.75},{-12,-62,.64,1.04},{-38,-67,.37,.65},{45,12,.61,.46},{9,22,.78,1.08},{51,76,1.18,.65},{20,109,.60,.66},{-25,135,.62,.45},{65,-40,.30,.47}}) do
        local lat,lon=math.rad(patch[1]),math.rad(patch[2])
        local normal=Vector3.new(math.cos(lat)*math.sin(lon),math.sin(lat),math.cos(lat)*math.cos(lon))
        local point=(center*CFrame.new(normal*1.83)).Position
        local cf=CFrame.lookAt(point,center.Position)
        ball(root,"Globe continent",Vector3.new(patch[3],patch[4],.24),cf,Color3.fromRGB(158,174,111),Enum.Material.SmoothPlastic,false)
    end
    cylinder(root,"Globe stand",Vector3.new(.73,.20,.20),CFrame.new(20.55,3.63,-26.4)*CFrame.Angles(0,0,math.pi/2),P.metal,Enum.Material.Metal,false)
    cylinder(root,"Globe base",Vector3.new(.18,2.7,2.7),CFrame.new(20.55,3.34,-26.4)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(69,74,73),Enum.Material.Metal,false)

end

local function buildBackDoorAndHall(root: Instance)
    -- Warm wood classroom doorway with tiny photo-inspired corridor beyond it.
    -- Existing lower back wall had an eighteen-stud opening and huge tilted
    -- door leaves. Frame a credible double-width school doorway in the same
    -- original opening, with permanent plastered piers and real paneling.
    for _,x in ipairs({-7.25,7.25}) do
        part(root,"Back doorway plaster infill",Vector3.new(3.5,12.8,1.0),
            CFrame.new(x,6.4,27.0),P.wall,Enum.Material.SmoothPlastic,true)
        part(root,"Back doorway blue wainscot",Vector3.new(3.56,3.65,.07),
            CFrame.new(x,1.83,26.45),P.blue,Enum.Material.Wood,false)
    end
    for _,x in ipairs({-5.54,5.54}) do
        part(root,"Door jamb timber stile",Vector3.new(.76,11.25,1.12),
            CFrame.new(x,5.63,26.91),Color3.fromRGB(113,78,50),Enum.Material.Wood,false)
    end
    part(root,"Door wood header",Vector3.new(11.55,.62,1.12),
        CFrame.new(0,10.94,26.90),Color3.fromRGB(113,78,50),Enum.Material.Wood,false)
    part(root,"Door transom glass",Vector3.new(10.22,1.55,.20),
        CFrame.new(0,12.05,26.70),Color3.fromRGB(207,221,218),Enum.Material.Glass,false).Transparency=.30
    for _,x in ipairs({-2.75,2.75}) do
        local door=part(root,"Open classroom door",Vector3.new(4.65,10,.36),
            CFrame.new(x,5.28,25.96)*CFrame.Angles(0,math.rad(x<0 and -48 or 48),0),
            Color3.fromRGB(128,91,60),Enum.Material.Wood,false)
        local glass=part(root,"Door glass",Vector3.new(2.54,4.38,.10),
            door.CFrame*CFrame.new(0,1.42,-.22),
            Color3.fromRGB(198,217,217),Enum.Material.Glass,false)
        glass.Transparency=.29
        for _,y in ipairs({-1.05,3.89}) do
            part(root,"Glazed door solid oak rail",Vector3.new(3.0,.22,.12),
                door.CFrame*CFrame.new(0,y,-.25),
                Color3.fromRGB(112,76,50),Enum.Material.Wood,false)
        end
        for _,dx in ipairs({-1.42,1.42}) do
            part(root,"Glazed door oak side stile",Vector3.new(.17,4.74,.12),
                door.CFrame*CFrame.new(dx,1.42,-.25),
                Color3.fromRGB(112,76,50),Enum.Material.Wood,false)
        end
        part(root,"Door lower raised panel",Vector3.new(3.7,2.85,.10),
            door.CFrame*CFrame.new(0,-2.72,-.24),
            Color3.fromRGB(142,105,73),Enum.Material.Wood,false)
    end
    sign(root,"Welcome over door","EMMA'S CLASSROOM",Vector3.new(10.7,1.20,.16),
        CFrame.new(0,15.6,26.40),Color3.fromRGB(247,237,207),P.blue)
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
    Lighting.ClockTime=10.25;Lighting.Brightness=1.48;Lighting.GlobalShadows=true;Lighting.ShadowSoftness=.63
    -- Soft is the current Roblox lighting-style API. Keep compatibility with
    -- engine versions where the enum is unavailable; no external assets.
    pcall(function() Lighting.LightingStyle=Enum.LightingStyle.Soft end)
    Lighting.Ambient=Color3.fromRGB(134,137,139);Lighting.OutdoorAmbient=Color3.fromRGB(161,173,181)
    Lighting.EnvironmentDiffuseScale=.66;Lighting.EnvironmentSpecularScale=.24;Lighting.ExposureCompensation=-.10
    local atmosphere=Lighting:FindFirstChild("EmmaClassroomAtmosphere") or Instance.new("Atmosphere")
    atmosphere.Name="EmmaClassroomAtmosphere";atmosphere.Density=.008;atmosphere.Offset=.08;atmosphere.Color=Color3.fromRGB(221,230,235);atmosphere.Decay=Color3.fromRGB(188,192,185);atmosphere.Haze=.15;atmosphere.Glare=.05;atmosphere.Parent=Lighting
    local bloom=Lighting:FindFirstChild("EmmaClassroomBloom") or Instance.new("BloomEffect")
    bloom.Name="EmmaClassroomBloom";bloom.Intensity=.03;bloom.Size=20;bloom.Threshold=1.25;bloom.Parent=Lighting
    local grade=Lighting:FindFirstChild("EmmaClassroomGrade") or Instance.new("ColorCorrectionEffect")
    -- Quiet contrast and slightly warmer whites reveal native clothing
    -- textures instead of flattening everything under bright ambient fill.
    grade.Name="EmmaClassroomGrade";grade.Brightness=.00;grade.Contrast=.065;grade.Saturation=.035;grade.TintColor=Color3.fromRGB(255,252,245);grade.Parent=Lighting
    local rays=Lighting:FindFirstChild("EmmaClassroomSunRays") or Instance.new("SunRaysEffect")
    rays.Name="EmmaClassroomSunRays";rays.Intensity=.025;rays.Spread=.8;rays.Parent=Lighting
end

function World.build()
    local old=Workspace:FindFirstChild("ABVMClassroomReplica");if old then old:Destroy() end
    local root=Instance.new("Folder");root.Name="ABVMClassroomReplica";root.Parent=Workspace
    root:SetAttribute("ArtDirection","EmmaRoomOriginalArtV9")
    applyLighting(root)

    -- Architectural shell.
    -- The engine's tiled wood-plank material is more natural at phone scale.
    -- Retire 300+ overlapping paper-thin floor boards that caused shimmer,
    -- tiny shadow edges and too many instances for one classroom.
    local floor=part(root,"Warm oak classroom floor",Vector3.new(74,1,62),
        CFrame.new(0,0,-4),Color3.fromRGB(157,122,88),Enum.Material.WoodPlanks)
    floor.Reflectance=.015

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

    -- Original room kit decorates the real Rojo place. No AI render or preview.
    -- Keep it separate from gameplay, board content and curriculum systems.
    ArtPass.decorate(root)

    -- Lived-in details.
    plant(root,-31,.1,20,.85)
    plant(root,-30,8.2,-29,.55)
    -- Small wall clock.
    local clock=cylinder(root,"Classroom wall clock",Vector3.new(.25,3.2,3.2),CFrame.new(31.5,15.1,-34)*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(242,242,237),Enum.Material.SmoothPlastic,false)
    cylinder(root,"Clock rim",Vector3.new(.34,3.55,3.55),clock.CFrame,Color3.fromRGB(61,63,63),Enum.Material.Metal,false)
    cylinder(root,"Clock visible dial",Vector3.new(.08,3.17,3.17),clock.CFrame*CFrame.new(-.22,0,0),Color3.fromRGB(242,242,237),Enum.Material.SmoothPlastic,false)
    part(root,"Clock minute hand",Vector3.new(.12,1.25,.12),CFrame.new(31.5,15.55,-33.78)*CFrame.Angles(0,0,math.rad(-20)),Color3.fromRGB(48,49,49),Enum.Material.Metal,false)
    part(root,"Clock hour hand",Vector3.new(.12,.85,.12),CFrame.new(31.5,15.25,-33.75)*CFrame.Angles(0,0,math.rad(45)),Color3.fromRGB(48,49,49),Enum.Material.Metal,false)

    -- Warm fluorescent lighting.
    for _,x in ipairs({-18,18}) do
        for _,z in ipairs({-22,0,19}) do ceilingLight(root,x,z) end
    end

    local spawn=Instance.new("SpawnLocation")
    spawn.Name="ClassroomReplicaSpawn";spawn.Size=Vector3.new(3,1,3);spawn.CFrame=CFrame.new(5,1.1,24)
    spawn.Transparency=1;spawn.CanCollide=false;spawn.Anchored=true;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=root

    World.Root=root
    World.Spawn=spawn.CFrame
    return World
end

-- No teachers, questions, quiz remotes, saved scores, or runtime UI in the replica build.
return World
