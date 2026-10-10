--!strict
-- ABVM classroom-only architectural room. Derived from the photo-guided room
-- without teacher/gameplay constructs, and compiled into a separate Rojo place.
local Workspace=game:GetService("Workspace")
local Lighting=game:GetService("Lighting")

local ArtPass=require(script.Parent:WaitForChild("ArtPass"))
local World={}

local P={
    wall=Color3.fromRGB(248,233,183),
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
local function roundedPanel(parent:Instance,name:string,size:Vector3,cf:CFrame,color:Color3,r:number,horizontal:boolean,collide:boolean?,material:Enum.Material?):Part
    local w=Vector3.new(size.X,horizontal and size.Z or size.Y,horizontal and size.Y or size.Z)
    local base=horizontal and cf*CFrame.Angles(-math.pi/2,0,0) or cf
    local finish=material or Enum.Material.SmoothPlastic
    local core=part(parent,name,Vector3.new(w.X-2*r,w.Y,w.Z),base,color,finish,collide)
    part(parent,name.." center",Vector3.new(w.X,w.Y-2*r,w.Z),base,color,finish,false)
    for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do
        cylinder(parent,name.." rounded corner",Vector3.new(w.Z,r*2,r*2),base*CFrame.new(x*(w.X/2-r),y*(w.Y/2-r),0)*CFrame.Angles(0,math.pi/2,0),color,finish,false)
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

-- The October 9 native iPhone recording showed carpet lettering as tiny
-- marks. The generic SurfaceGui uses a 1,000px canvas: 3D text then shrinks
-- heavily on a child-height screen. Limit this exclusively to carpet labels,
-- with a deliberate font size and a transparent numeral background.
local function emphasizeRugText(label: TextLabel,transparent: boolean)
    local gui=label.Parent
    if gui and gui:IsA("SurfaceGui") then
        gui.CanvasSize=Vector2.new(180,120)
        gui.LightInfluence=0
    end
    label.BackgroundTransparency=transparent and 1 or .04
    label.TextScaled=false
    label.TextWrapped=false
    -- In the newer native v71 walkthrough the pale cloud numbering still
    -- disappears at grazing child-eye angles, although Luau UI exists.
    -- Keep the current letters at 92px; enlarge only the 10 cloud numerals.
    label.TextSize=transparent and 104 or 92
    label.TextStrokeColor3=Color3.fromRGB(248,244,231)
    label.TextStrokeTransparency=.45
    for _,child in ipairs(label:GetChildren()) do
        if child:IsA("UIPadding") then
            child.PaddingLeft=UDim.new(0,4)
            child.PaddingRight=UDim.new(0,4)
            child.PaddingTop=UDim.new(0,2)
            child.PaddingBottom=UDim.new(0,2)
        end
    end
end

local function sign(parent: Instance,name: string,text: string,size: Vector3,cf: CFrame,bg: Color3,fg: Color3): Part
    local p=part(parent,name,size,cf,bg,Enum.Material.SmoothPlastic,false)
    surfaceText(p,text,cf.Position.Z>20 and Enum.NormalId.Front or Enum.NormalId.Back,fg,bg)
    return p
end

local function ceilingLight(parent: Instance,x: number,z: number)
    -- Photos IMG_2903-2910 show broad ~2:1 recessed fluorescent panels,
    -- not narrow luminous strips. Preserve the six measured fixture centers
    -- and established ceiling plane; only correct the manufactured profile.
    -- A frosted inset lens and visible metal reveal read as real troffers.
    -- Never return to the nine oversized emissive Neon ceiling slabs.
    part(parent,"Recessed light trim",Vector3.new(6.90,.12,3.56),
        CFrame.new(x,17.72,z),
        Color3.fromRGB(209,211,207),Enum.Material.Metal,false)
    local lens=part(parent,"Frosted fluorescent diffuser",Vector3.new(6.24,.08,3.08),
        CFrame.new(x,17.59,z),Color3.fromRGB(249,246,238),
        Enum.Material.Glass,false)
    lens.Transparency=.075;lens.Reflectance=.005
    local light=Instance.new("SurfaceLight")
    light.Face=Enum.NormalId.Bottom;light.Color=Color3.fromRGB(250,246,237)
    -- Light from the actual broad frosted panels, rather than a dim slab.
    -- Preserve fixture count, range, shadows, and mobile rendering cost.
    light.Brightness=.24;light.Range=25;light.Angle=115;light.Shadows=false;light.Parent=lens
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

local function book(parent: Instance,x: number,y: number,z: number,color: Color3,rotation: number,compact: boolean?)
    local cf=CFrame.new(x,y,z)*CFrame.Angles(0,rotation,0)
    -- Exposed notebooks keep their premium rounded cover. The sixteen very
    -- thin underdesk workbooks are largely hidden behind their wire shelf:
    -- six rounded-panel pieces did not improve their manufactured silhouette.
    -- A single square-cut cover is closer to a real .18-stud exercise book
    -- while retaining the same footprint, visible pages and spine.
    if compact then
        part(parent,"Classroom book",Vector3.new(2.15,.18,2.85),cf,
            color,Enum.Material.SmoothPlastic,false)
    else
        roundedPanel(parent,"Classroom book",Vector3.new(2.15,.18,2.85),
            cf,color,.10,true,false)
    end
    part(parent,"Book pages",Vector3.new(1.94,.12,2.65),
        cf*CFrame.new(.015,.14,0),P.cream,Enum.Material.SmoothPlastic,false)
    part(parent,"Notebook spine",Vector3.new(.12,.15,2.85),
        cf*CFrame.new(-1.04,.14,0),color:Lerp(P.ink,.14),
        Enum.Material.SmoothPlastic,false)
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
    -- The previous seamless ellipsoid looked like an office stool back, not
    -- a molded elementary classroom chair. Instead, form a gently rounded
    -- RECTANGULAR school back with broad shoulders and a single unsegmented
    -- center. RoundedPanel makes curved corners without horizontal plate seams.
    -- The existing invisible collider remains the only collidable back piece.
    local shell=roundedPanel(parent,name.." school back shell",
        Vector3.new(2.48,1.87,.25),backCF*CFrame.new(0,.04,-.015),
        tint:Lerp(P.cream,.075),.40,false,false)
    shell.Reflectance=.015
    -- A very shallow curved return on each lateral edge prevents a chair
    -- viewed from the side from reading as a flat rectangular board. These
    -- two same-material wings follow the existing tilted backrest and use
    -- NO collision; the single established chair collider remains authoritative.
    -- Premium owned meshes, when approved, hide the entire Student chair family.
    for _,side in ipairs({-1,1}) do
        local wing=part(parent,name.." molded side return",
            Vector3.new(.34,1.54,.34),
            backCF*CFrame.new(side*1.08,-.13,.065)*
                CFrame.Angles(0,math.rad(side*21),0),
            tint:Lerp(P.cream,.12),Enum.Material.SmoothPlastic,false)
        wing.Reflectance=.015
    end
    -- A continuous shallow front rollover turns the primitive seat slab into
    -- a believable one-piece molded child-seat profile. It meets the existing
    -- front edge, cannot block movement, and belongs to the "Student chair"
    -- family so a future approved mesh swap hides it transactionally.
    local nose=part(parent,name.." molded front seat roll",
        Vector3.new(2.16,.13,.19),CFrame.new(x,1.515,z-1.012),
        tint:Lerp(P.cream,.085),Enum.Material.SmoothPlastic,false)
    nose.CanQuery=false
    nose.CastShadow=false
    -- Reference photographs show elongated vertical ventilation details on
    -- molded blue school-chair backs. The old flattened Ball (.18,.65,.034)
    -- actually renders as a 0.034-stud SPHERE in native Roblox, even though
    -- independent source renderers draw a tall ellipsoid. Thus every slot
    -- becomes a nearly invisible dot on real iPhones. Keep the SAME three
    -- parts per chair but use visible, thin, tall molded-shadow Block insets.
    -- These simulate recesses, not real through-holes; the existing single
    -- invisible back collider and all furniture placement remain unchanged.
    for _,dx in ipairs({-.54,0,.54}) do
        local vent=part(parent,name.." ventilation inset",
            Vector3.new(.18,.65,.034),backCF*CFrame.new(dx,.40,.139),
            tint:Lerp(P.ink,.53),Enum.Material.SmoothPlastic,false)
        vent.Shape=Enum.PartType.Block
        vent.CanQuery=false
        vent.Reflectance=.005
        vent.CastShadow=false
    end
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
        -- The original T-foot Part remains the EXACT collidable physical
        -- footprint for all sixteen student desks. At y=.18 it is buried
        -- under the finished floor (top y=.5), so it was not a believable
        -- visible base. Replace only its artwork with a rounded steel tube
        -- resting ON the finished floor. No navigation/collision change.
        local physicalFoot=part(parent,"Desk foot",
            Vector3.new(.52,.16,3.10),CFrame.new(x+dx,.18,z),
            Color3.fromRGB(76,82,86),Enum.Material.Metal)
        physicalFoot.Transparency=1
        physicalFoot.CanQuery=false
        physicalFoot.CastShadow=false
        local runner=cylinder(parent,"Desk contoured base runner",
            Vector3.new(3.10,.20,.20),
            CFrame.new(x+dx,.60,z)*CFrame.Angles(0,math.pi/2,0),
            Color3.fromRGB(133,142,146),Enum.Material.Metal,false)
        runner.CastShadow=false
    end
    -- Match an elementary school desk's thin rim and underdesk wire basket
    -- rather than a thick floating black platform. These details are non-solid
    -- and do not change desk collision or the aisle footprints.
    part(parent,"Desk laminated front bevel",Vector3.new(5.08,.105,.085),
        CFrame.new(x,3.01,z-1.88),Color3.fromRGB(146,129,107),
        Enum.Material.SmoothPlastic,false)
    -- A full solid sheet made every open student desk look as though it had a
    -- second steel tabletop underneath. Use a sparse cross-welded wire shelf
    -- instead. It is visible from a child's eye height but has no collision.
    -- Four transverse rods retain a realistic open basket at child eye height
    -- without filling the view with wires. Across 16 desks, six instead of
    -- eight crossing rods recovers 32 low-value Parts for mobile headroom.
    for _,dz in ipairs({-1.28,-.43,.43,1.28}) do
        cylinder(parent,"Desk basket cross wire",Vector3.new(4.58,.085,.085),
            CFrame.new(x,2.29,z+dz),
            Color3.fromRGB(135,141,143),Enum.Material.Metal,false)
    end
    for _,dx in ipairs({-1.78,1.78}) do
        cylinder(parent,"Desk basket longitudinal wire",Vector3.new(2.88,.085,.085),
            CFrame.new(x+dx,2.27,z)*CFrame.Angles(0,math.pi/2,0),
            Color3.fromRGB(135,141,143),Enum.Material.Metal,false)
    end
    for _,dx in ipairs({-2.35,2.35}) do
        -- An open bent-steel lip, not the old opaque 0.42-stud side slab,
        -- so a child can see through the underdesk wire storage basket.
        -- Keep the original part name for the optional mesh-swap allowlist.
        cylinder(parent,"Book tray side",Vector3.new(3.06,.095,.095),
            CFrame.new(x+dx,2.49,z)*CFrame.Angles(0,math.pi/2,0),
            P.metal,Enum.Material.Metal,false)
    end
    cylinder(parent,"Desk shelf front restraint",Vector3.new(4.56,.12,.12),
        CFrame.new(x,2.36,z-1.44),P.metal,Enum.Material.Metal,false)
    cylinder(parent,"Desk back steel stretcher",Vector3.new(4.44,.14,.14),
        CFrame.new(x,1.46,z+1.34),Color3.fromRGB(120,130,134),
        Enum.Material.Metal,false)
    -- The basket wire top is y=2.3325; the book underside now sits
    -- at y=2.31 instead of visibly hovering above its shelf.
    -- Compact ONLY the workbook inside the basket; desktop books stay rounded.
    book(parent,x,2.40,z,Color3.fromRGB(70,106,133),0,true)
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
    cylinder(parent,"Desk pencil",Vector3.new(1.75,.10,.10),CFrame.new(x+1.4,3.225,z-.6)*CFrame.Angles(0,math.rad(108),0),Color3.fromRGB(239,190,56),Enum.Material.Wood,false)
    -- The original ferrule and eraser were rotated 90 degrees away from
    -- the pencil's local-X cylinder shaft and floated beside the desk.
    -- One aligned cap keeps the visible silhouette and saves 16 mobile Parts.
    local pencilCF=CFrame.new(x+1.4,3.225,z-.6)*CFrame.Angles(0,math.rad(108),0)
    part(parent,"Desk pencil eraser cap",Vector3.new(.15,.13,.13),
        pencilCF*CFrame.new(.82,0,0),
        Color3.fromRGB(223,139,156),Enum.Material.SmoothPlastic,false)
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
        part(parent,"Desk rubber glide",Vector3.new(.49,.17,.42),CFrame.new(x+dx,.59,z-1.30),P.ink,Enum.Material.SmoothPlastic,false)
        part(parent,"Desk rubber glide",Vector3.new(.49,.17,.42),CFrame.new(x+dx,.59,z+1.30),P.ink,Enum.Material.SmoothPlastic,false)
    end
    if emma then
        local tag=part(parent,"Emma desk nameplate",Vector3.new(3.8,.55,.16),CFrame.new(x,3.42,z-1.98)*CFrame.Angles(math.rad(-10),0,0),P.green,Enum.Material.SmoothPlastic,false)
        surfaceText(tag,"★ EMMA ★",Enum.NormalId.Back,P.gold,P.green)
        -- A child-height reusable bottle rather than the oversized hot-pink
        -- cylinder visible in close-up renders. Body rests on y=3.17 desktop;
        -- shoulder and screw cap interlock without floating or intersecting
        -- neighboring schoolwork.
        local bottleX,bottleZ=x+2.12,z+.45
        cylinder(parent,"Emma pink water bottle",Vector3.new(.82,.51,.51),
            CFrame.new(bottleX,3.60,bottleZ)*CFrame.Angles(0,0,math.pi/2),
            Color3.fromRGB(214,128,154),Enum.Material.SmoothPlastic,false)
        cylinder(parent,"Water bottle tapered shoulder",Vector3.new(.20,.37,.37),
            CFrame.new(bottleX,4.03,bottleZ)*CFrame.Angles(0,0,math.pi/2),
            Color3.fromRGB(220,139,162),Enum.Material.SmoothPlastic,false)
        part(parent,"Water bottle cap",Vector3.new(.29,.14,.29),
            CFrame.new(bottleX,4.19,bottleZ),
            Color3.fromRGB(169,91,124),Enum.Material.SmoothPlastic,false)
    end
end

local function bulletinBoard(parent: Instance,name: string,x: number,y: number,z: number,width: number,height: number,title: string)
    -- The old "frame" was a SOLID brown slab in front of the cork, hiding
    -- the bulletin board from every player-eye camera. Make a real recessed
    -- cork field, with four narrow hardwood rails that leave its face exposed.
    local backing=part(parent,name.." thin wood backing",
        Vector3.new(width+.48,height+.48,.13),CFrame.new(x,y,z-.17),
        Color3.fromRGB(105,73,48),Enum.Material.Wood,false)
    local cork=part(parent,name.." exposed cork",
        Vector3.new(width,height,.11),CFrame.new(x,y,z+.055),
        Color3.fromRGB(171,132,92),Enum.Material.Fabric,false)
    local border=Color3.fromRGB(109,77,51)
    for _,dy in ipairs({-height/2-.15,height/2+.15}) do
        part(parent,name.." horizontal wood rail",
            Vector3.new(width+.50,.28,.19),CFrame.new(x,y+dy,z+.14),
            border,Enum.Material.Wood,false)
    end
    for _,dx in ipairs({-width/2-.15,width/2+.15}) do
        part(parent,name.." vertical wood rail",
            Vector3.new(.28,height+.56,.19),CFrame.new(x+dx,y,z+.14),
            border,Enum.Material.Wood,false)
    end
    local titleLabel=surfaceText(cork,title,Enum.NormalId.Back,P.cream,cork.Color,Enum.Font.GothamBold)
    titleLabel.Position=UDim2.fromScale(.08,.02);titleLabel.Size=UDim2.fromScale(.84,.18)
    titleLabel.BackgroundTransparency=1
    return backing
end

local function buildClassroomTexture(root: Instance)
    -- The real school photos are busy, old, warm and layered. This deliberately kills the sterile showroom look.
    -- Small pieces of work belong inside framed boards, with breathable margins.
    bulletinBoard(root,"Student work board",-26.3,9,-33.65,9.4,5.65,"OUR WORK")
    -- Paper slips are PHYSICAL classroom artifacts, not screen-facing UI.
    -- In the independent renderer SurfaceGui letters are not visible, but
    -- paper pinned in front of exposed cork still reads as a lived-in room.
    local paperColors={
        Color3.fromRGB(246,244,229),
        Color3.fromRGB(225,235,237),
        Color3.fromRGB(247,229,217),
    }
    local headingColors={
        Color3.fromRGB(90,125,154),
        Color3.fromRGB(107,140,107),
        Color3.fromRGB(184,124,88),
    }
    for i,x in ipairs({-29.3,-26.3,-23.3}) do
        local y=8.72+(i%2)*.20
        part(root,"Pinned student work sheet",
            Vector3.new(2.16,2.90,.055),CFrame.new(x,y,-33.45),
            paperColors[i],Enum.Material.SmoothPlastic,false)
        part(root,"Student work colored heading",
            Vector3.new(1.70,.15,.038),CFrame.new(x,y+.83,-33.40),
            headingColors[i],Enum.Material.SmoothPlastic,false)
        for line=1,3 do
            part(root,"Student work pencil line",
                Vector3.new(1.54,.045,.037),
                CFrame.new(x,y+.41-line*.40,-33.40),
                Color3.fromRGB(155,161,160),Enum.Material.SmoothPlastic,false)
        end
        ball(root,"Bulletin board brass pushpin",
            Vector3.new(.18,.18,.08),CFrame.new(x,y+1.34,-33.39),
            Color3.fromRGB(184,155,83),Enum.Material.Metal,false)
    end

    -- No oversized individual rules: GalleryPass owns a restrained framed
    -- values board and keeps this wall clear of overlapping flat panels.

    -- Pencil sharpener, trash bin, tissue box, storage cabinet, rolling cart.
    part(root,"Tall storage cabinet",Vector3.new(7,12,3.2),CFrame.new(31,6,22.7),Color3.fromRGB(96,65,45),Enum.Material.Wood)
    part(root,"Cabinet center seam",Vector3.new(.065,11.1,.06),CFrame.new(31,6,21.03),Color3.fromRGB(61,48,36),Enum.Material.Wood,false)
    for _,x in ipairs({29.3,32.7}) do
        part(root,"Cabinet door panel",Vector3.new(3.08,10.9,.10),CFrame.new(x,6,21.03),Color3.fromRGB(119,81,55),Enum.Material.Wood,false)
        for _,y in ipairs({3.2,8.4}) do
            part(root,"Cabinet inset panel",Vector3.new(2.60,4.4,.06),CFrame.new(x,y,20.94),Color3.fromRGB(135,105,74),Enum.Material.Wood,false)
            for _,dx in ipairs({-1.31,1.31}) do part(root,"Cabinet panel stile",Vector3.new(.055,4.55,.045),CFrame.new(x+dx,y,20.90),Color3.fromRGB(178,142,98),Enum.Material.Wood,false) end
        end
        part(root,"Cabinet door pull",Vector3.new(.13,1.15,.18),CFrame.new(x+(x<31 and .91 or -.91),6.2,20.79),Color3.fromRGB(180,176,158),Enum.Material.Metal,false)
        for _,y in ipairs({1.8,10.2}) do part(root,"Cabinet brass hinge",Vector3.new(.14,.42,.15),CFrame.new(x+(x<31 and -1.50 or 1.50),y,20.88),Color3.fromRGB(167,149,101),Enum.Material.Metal,false) end
    end
    -- The photographed cabinetry is older school carpentry: deep walnut
    -- framed, raised doors, not one large flat brown box. Build routed panel
    -- rails against the EXISTING two doors without moving their footprints.
    local cabinetRim=Color3.fromRGB(94,62,40)
    local cabinetWarmEdge=Color3.fromRGB(153,111,75)
    for _,doorX in ipairs({29.3,32.7}) do
        for _,centerY in ipairs({3.2,8.4}) do
            for _,dy in ipairs({-2.08,2.08}) do
                part(root,"Tall cabinet recessed panel cross rail",
                    Vector3.new(2.76,.17,.075),
                    CFrame.new(doorX,centerY+dy,20.853),
                    cabinetRim,Enum.Material.Wood,false)
            end
        end
        part(root,"Tall cabinet antiqued keyhole",
            Vector3.new(.085,.23,.045),
            CFrame.new(doorX+(doorX<31 and .90 or -.90),5.38,20.692),
            Color3.fromRGB(97,76,48),Enum.Material.Metal,false)
    end
    part(root,"Tall cabinet hardwood cornice",
        Vector3.new(7.35,.41,.50),CFrame.new(31,12.25,20.96),
        cabinetRim,Enum.Material.Wood,false)
    part(root,"Tall cabinet cornice routed lip",
        Vector3.new(7.54,.11,.44),CFrame.new(31,12.50,20.77),
        cabinetWarmEdge,Enum.Material.Wood,false)
    part(root,"Tall cabinet recessed toe kick",
        Vector3.new(6.78,.42,.18),CFrame.new(31,.51,20.91),
        Color3.fromRGB(72,50,37),Enum.Material.Wood,false)
    local trash=cylinder(root,"Classroom trash can",Vector3.new(3.4,3.1,3.1),CFrame.new(32.8,1.7,-24)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(95,100,101),Enum.Material.Metal,false)
    trash.Transparency=0
    cylinder(root,"Trash can opening",Vector3.new(.035,2.76,2.76),CFrame.new(32.8,3.42,-24)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(32,36,38),Enum.Material.SmoothPlastic,false)
    for i=0,15 do
        local a=i*math.pi/8
        cylinder(root,"Trash can rib",Vector3.new(2.85,.055,.055),CFrame.new(32.8+math.cos(a)*1.55,1.75,-24+math.sin(a)*1.55)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(137,142,141),Enum.Material.Metal,false)
    end
    local tissues=part(root,"Tissue box",Vector3.new(2.3,1.2,1.7),CFrame.new(22.5,3.89,-23.6),Color3.fromRGB(116,177,193),Enum.Material.SmoothPlastic,false)
    surfaceText(tissues,"TISSUES",Enum.NormalId.Front,Color3.fromRGB(245,248,244),tissues.Color,Enum.Font.GothamBold)
    part(root,"Tissue box slot",Vector3.new(1.25,.015,.24),CFrame.new(22.5,4.50,-23.6),P.ink,Enum.Material.SmoothPlastic,false)
    part(root,"Folded tissue",Vector3.new(.80,.77,.018),CFrame.new(22.5,4.78,-23.6)*CFrame.Angles(math.rad(12),0,math.rad(-8)),P.cream,Enum.Material.Fabric,false)
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


    -- Photo-grounded IMG_2904/2905/2908/2910: black polka dots and round
    -- alphabet/sun/cloud carpet. Preserve both established center positions:
    -- the event photos cannot establish daily desk and carpet locations.
    part(root,"Front teaching rug",Vector3.new(16,.10,9),CFrame.new(-25,.56,-20),
        Color3.fromRGB(35,38,43),Enum.Material.Fabric,false)
    local dotTints={
        Color3.fromRGB(219,105,102),Color3.fromRGB(109,163,200),
        Color3.fromRGB(238,204,89),Color3.fromRGB(157,139,187),
        Color3.fromRGB(148,199,168),Color3.fromRGB(231,164,95),
    }
    for row=0,4 do
        for col=0,4 do
            cylinder(root,"Front rug color dot",Vector3.new(.026,1.32,1.32),
                CFrame.new(-31+col*3,.632,-23.6+row*1.70)*
                    CFrame.Angles(0,0,math.pi/2),
                dotTints[(row*3+col)%#dotTints+1],Enum.Material.Fabric,false)
        end
    end
    local flat=CFrame.Angles(0,0,math.pi/2)
    -- A Cylinder Part uses local X as the axis; rotate it to lie on the floor.
    -- Native iPhone v71 showed this Fabric rug nearly black (#1d2b36
    -- in a centered video sample), although the source RGB was medium blue
    -- and the independent renderer showed a much brighter carpet. Raise
    -- its dye while retaining the photographed diameter and Fabric finish.
    -- Do not substitute a glossy plastic sheet or add an overlapping decal.
    cylinder(root,"Alphabet rug",Vector3.new(.10,14.2,14.2),
        CFrame.new(-25,.56,14)*flat,Color3.fromRGB(107,165,222),
        Enum.Material.Fabric,false)
    local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local edgeColors={
        Color3.fromRGB(224,150,96),Color3.fromRGB(239,198,96),
        Color3.fromRGB(148,185,165),Color3.fromRGB(142,176,203),
        Color3.fromRGB(186,151,185),Color3.fromRGB(214,122,108),
    }
    for i=1,26 do
        local angle=-math.pi/2+(i-1)*2*math.pi/26
        local x=-25+math.cos(angle)*6.13
        local z=14+math.sin(angle)*6.13
        -- The photo's A-Z ring is a near-continuous segmented circular band,
        -- not twenty-six disconnected radial stamp squares. The long axis
        -- runs tangent to the letter orbit; neighboring centers are 1.48
        -- studs apart at radius 6.13, so each 1.56-stud section nearly joins.
        -- Reuse the exact original 26 noncolliding Parts and SurfaceGuis.
        local tile=part(root,"Reading rug alphabet border",
            Vector3.new(1.56,.022,1.17),
            CFrame.new(x,.621,z)*CFrame.Angles(0,-angle-math.pi/2,0),
            edgeColors[(i-1)%#edgeColors+1],Enum.Material.Fabric,false)
        local letter=surfaceText(tile,string.sub(alphabet,i,i),
            Enum.NormalId.Top,P.ink,tile.Color)
        emphasizeRugText(letter,false)
    end
    cylinder(root,"Photo rug sun center",Vector3.new(.034,2.05,2.05),
        CFrame.new(-25,.640,14)*flat,Color3.fromRGB(249,190,68),
        Enum.Material.SmoothPlastic,false)
    -- The real carpet's sunshine is an orange-and-gold irregular sunburst,
    -- not eight flat rectangular ruler bars. Reuse the existing radial art
    -- family with two alternating fabric ellipsoid profiles (16 total).
    -- These remain noncolliding and leave the real sun and numbered clouds
    -- exposed; no texture/photo of any child is distributed.

    -- NATIVE ROBLOX CORRECTION (October 9 iPhone):
    -- Shape=Ball renders a TRUE SPHERE whose actual diameter is the MINIMUM
    -- Size axis. Flattened 1.70 x .22 x .98 "clouds" therefore become .22
    -- stud dots; increasing the wide dimensions does NOT fix this. Roblox
    -- documented this behavior in "Improvements to Part Shape & Size".
    -- Use real horizontal Block/Cylinder solids with normal Y thickness.
    -- The existing Fabric rug, its 26 SurfaceGui letters, radial design and
    -- every student desk remain unchanged. All relief is noncolliding.
    for i=0,15 do
        local angle=i*math.pi/8
        local broad=i%2==0
        local radius=broad and 1.31 or 1.52
        local length=broad and .94 or .79
        local width=broad and .30 or .24
        local tint=broad and Color3.fromRGB(255,211,84)
            or Color3.fromRGB(239,140,52)
        local x=-25+math.cos(angle)*radius
        local z=14+math.sin(angle)*radius
        -- Elongated stable ray with a true round cap at its outer end:
        -- 1 Block + 1 flat Cylinder; avoids non-uniform Ball primitives.
        local ray=part(root,"Photo rug sun ray",
            Vector3.new(length,.10,width),
            CFrame.new(x,.685,z)*CFrame.Angles(0,-angle,0),
            tint,Enum.Material.SmoothPlastic,false)
        -- Explicit native Block shape also makes the constructed-Luau
        -- fixture test the same shape the Roblox engine will actually use.
        ray.Shape=Enum.PartType.Block
        ray.CastShadow=false
        local tipRadius=radius+length/2-.04
        local tip=cylinder(root,"Photo rug sun ray rounded tip",
            Vector3.new(.10,width,width),
            CFrame.new(-25+math.cos(angle)*tipRadius,.685,
                14+math.sin(angle)*tipRadius)*flat,
            tint,Enum.Material.SmoothPlastic,false)
        tip.CastShadow=false
    end
    for i=1,10 do
        local angle=i*math.pi/5
        local x=-25+math.cos(angle)*3.62
        local z=14+math.sin(angle)*3.62
        local cloudTint=Color3.fromRGB(253,252,246)
        -- Center block joins two truly ROUND, horizontal cylinders.
        -- 3 original Parts per cloud, no paper-thin Ball dimensions.
        local body=part(root,"Photo rug number cloud body",
            Vector3.new(1.14,.12,.65),CFrame.new(x,.690,z),
            cloudTint,Enum.Material.SmoothPlastic,false)
        body.Shape=Enum.PartType.Block
        body.CastShadow=false
        for _,side in ipairs({-1,1}) do
            local lobe=cylinder(root,"Photo rug number cloud lobe",
                Vector3.new(.12,.94,.94),
                CFrame.new(x+side*.39,.690,z+side*.055)*flat,
                cloudTint,Enum.Material.SmoothPlastic,false)
            lobe.CastShadow=false
        end
        -- A transparent, noncolliding number anchor stays CLEAR of the
        -- actual cylinder faces, not an opaque white rectangular sticker.
        local numeralAnchor=part(root,"Photo rug number cloud numeral",
            Vector3.new(.80,.016,.58),CFrame.new(x,.820,z),
            Color3.fromRGB(250,248,237),Enum.Material.SmoothPlastic,false)
        numeralAnchor.Shape=Enum.PartType.Block
        numeralAnchor.Transparency=1
        local numeral=surfaceText(numeralAnchor,tostring(i),
            Enum.NormalId.Top,Color3.fromRGB(15,44,79),
            numeralAnchor.Color)
        emphasizeRugText(numeral,true)
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
    -- Frame the original 18-stud wooden bookcase in the aged oak language
    -- seen in the reference photos. The thin face trim surrounds existing
    -- shelves instead of overlaying the individual book faces or changing
    -- reading-corner collision.
    local caseFace=Color3.fromRGB(103,72,49)
    local caseEdge=Color3.fromRGB(148,108,74)
    for _,x in ipairs({-30.98,-22,-13.02}) do
        part(root,"Library hardwood front pilaster",
            Vector3.new(.26,6.02,.19),CFrame.new(x,3.17,21.83),
            caseFace,Enum.Material.Wood,false)
    end
    for _,y in ipairs({.69,3.21,6.19}) do
        part(root,"Library shelf front fascia",
            Vector3.new(18.08,.18,.19),CFrame.new(-22,y,21.82),
            caseFace,Enum.Material.Wood,false)
    end
    part(root,"Library upper molded cornice",
        Vector3.new(18.42,.32,.50),CFrame.new(-22,6.43,22.05),
        caseFace,Enum.Material.Wood,false)
    part(root,"Library cornice highlight",
        Vector3.new(18.5,.055,.34),CFrame.new(-22,6.62,21.89),
        caseEdge,Enum.Material.Wood,false)
    -- Source-camera review exposed a suspended yellow-wall gap between
    -- this inset and the photo-grounded OLD-OAK lower bookcase. Reuse the
    -- exact six existing wood/display Parts at the same front face as the
    -- original bookcase, seat its bottom rail onto the library cornice,
    -- and leave the opening for the rear classroom doorway unchanged.
    local inset=part(root,"Library built-in display backing",
        Vector3.new(18.05,5.58,.12),CFrame.new(-22,9.40,22.05),
        Color3.fromRGB(46,49,48),Enum.Material.SmoothPlastic,false)
    inset.Reflectance=.005
    for _,x in ipairs({-31.12,-12.88}) do
        part(root,"Library built-in dark inset frame stile",
            Vector3.new(.28,5.86,.20),CFrame.new(x,9.50,21.81),
            caseFace,Enum.Material.Wood,false)
    end
    for _,y in ipairs({6.62,12.28}) do
        part(root,"Library built-in dark inset frame rail",
            Vector3.new(18.48,.23,.23),CFrame.new(-22,y,21.81),
            caseFace,Enum.Material.Wood,false)
    end
    -- Three intentionally anonymous paper specimens. The supplied event
    -- photos contain real children's work; that text/art is NOT reproduced.
    for i,x in ipairs({-27.4,-22.0,-16.6}) do
        local papers={
            Color3.fromRGB(235,232,216),Color3.fromRGB(220,231,225),
            Color3.fromRGB(232,225,219),
        }
        part(root,"Library built-in anonymous paper",
            Vector3.new(2.85,2.05,.045),CFrame.new(x,10.05,21.73),
            papers[i],Enum.Material.SmoothPlastic,false)
        part(root,"Library built-in paper heading",
            Vector3.new(2.05,.12,.03),CFrame.new(x,10.64,21.68),
            Color3.fromRGB(117,146,157),Enum.Material.SmoothPlastic,false)
    end

    -- Spines use staggered sizes and restrained classroom-library colors,
    -- not forty equal-height blocks with identical white labels. Keep the
    -- existing shelf, capacity and book count; no extra replicated pieces.
    local colors={
        P.blue,Color3.fromRGB(151,84,79),P.green,
        Color3.fromRGB(177,146,79),Color3.fromRGB(81,107,130),
        Color3.fromRGB(118,98,132),Color3.fromRGB(144,122,95),
    }
    for row=0,1 do
        for i=1,20 do
            local x=-30.5+(i-1)*.85
            local width=.47+((i*3+row)%4)*.075
            local height=1.45+(i%5)*.14
            local z=23.3+(((i+row)%3)-1)*.075
            local lowerShelf=.83+row*2.55
            local lean=math.rad(((i*7+row*3)%11)-5)
            local spineFrame=CFrame.new(x,lowerShelf+height/2,z)*
                CFrame.Angles(0,0,lean)
            part(root,"Reading book spine",Vector3.new(width,height,1.5),
                spineFrame,colors[(i*5+row*3)%#colors+1],
                Enum.Material.SmoothPlastic,false)
            -- Six selected physical front-facing book covers break up the uniform
            -- rows of anonymous spines without changing shelving or book count.
            -- Paper/cover relief faces the room (-Z) and remains non-collidable.
            local faceOut=(i+row*2)%7==3
            if faceOut then
                part(root,"Reading book cover",Vector3.new(width*.92,height*.92,.055),
                    spineFrame*CFrame.new(0,0,-.79),
                    colors[((i+row)*3)%#colors+1],Enum.Material.SmoothPlastic,false)
                part(root,"Reading book cover illustration",Vector3.new(width*.57,height*.38,.024),
                    spineFrame*CFrame.new(0,.10,-.825),
                    P.cream,Enum.Material.SmoothPlastic,false)
                part(root,"Reading book cover title",Vector3.new(width*.67,.11,.025),
                    spineFrame*CFrame.new(0,-height*.30,-.828),
                    P.gold,Enum.Material.SmoothPlastic,false)
            end
            -- Keep the existing 40 individual physical spine labels. Move a
            -- few onto the new cover surface so they remain visible to players.
            part(root,"Book spine label",Vector3.new(width*.52,.14,.03),
                spineFrame*CFrame.new(0,faceOut and -height*.30 or -height*.09,
                    faceOut and -.857 or -.765),
                P.cream,Enum.Material.SmoothPlastic,false)
        end
    end
    -- Thin steel bookends sit on existing shelves rather than adding a new rack.
    for row=0,1 do
        for _,x in ipairs({-30.96,-13.94}) do
            part(root,"Reading shelf metal bookend",Vector3.new(.12,1.55,1.55),
                CFrame.new(x,1.64+row*2.55,23.3),P.metal,Enum.Material.Metal,false)
        end
    end
    -- Six synthetic artwork panels were duplicated on the front chalkboard.
    -- A dedicated single student gallery remains on the back wall.

end

local function buildCubbies(root: Instance)
    -- IMG_2903/2904: the storage room has substantial dark varnished
    -- school cabinetry. Preserve these established frame dimensions,
    -- aisle footprints and all 12 bin slots; avoid a toy-store finish.
    local cabinetWood=Color3.fromRGB(109,76,52)
    part(root,"Cubbies wood surround",Vector3.new(27,8,.24),
        CFrame.new(21,4.2,26.5),cabinetWood,Enum.Material.Wood)
    for _,y in ipairs({.28,4.2,8.2}) do
        part(root,"Cubbie open shelf",Vector3.new(27,.22,3),
            CFrame.new(21,y,25.2),cabinetWood,Enum.Material.Wood,false)
    end
    for i=0,6 do
        part(root,"Cubbie divider",Vector3.new(.18,8,3),
            CFrame.new(7.5+i*4.5,4.2,25.2),
            cabinetWood,Enum.Material.Wood,false)
    end
    -- Architectural carpentry treatment. The actual school storage uses
    -- substantial dark, framed panels rather than floating plastic bins.
    -- Keep all twelve existing slots and their exact volumes. These are
    -- noncolliding thin facings, aligned to dividers/shelf fronts only.
    local walnutFace=Color3.fromRGB(99,68,46)
    local walnutHighlight=Color3.fromRGB(145,103,70)
    for i=0,6 do
        local x=7.5+i*4.5
        part(root,"Built-in walnut cubby face stile",
            Vector3.new(.29,8.02,.22),CFrame.new(x,4.22,23.53),
            walnutFace,Enum.Material.Wood,false)
        part(root,"Built-in walnut stile routed edge",
            Vector3.new(.052,7.86,.029),CFrame.new(x+.092,4.22,23.387),
            walnutHighlight,Enum.Material.Wood,false)
    end
    for _,y in ipairs({.76,4.20,8.25}) do
        part(root,"Built-in horizontal walnut face rail",
            Vector3.new(27.24,.24,.23),CFrame.new(21,y,23.52),
            walnutFace,Enum.Material.Wood,false)
        part(root,"Built-in horizontal fine molding",
            Vector3.new(26.86,.055,.032),CFrame.new(21,y+.12,23.376),
            walnutHighlight,Enum.Material.Wood,false)
    end
    part(root,"Built-in recessed dark toe kick",
        Vector3.new(26.94,.37,.17),CFrame.new(21,.46,23.56),
        Color3.fromRGB(76,53,38),Enum.Material.Wood,false)
    part(root,"Built-in deep hardwood cornice",
        Vector3.new(27.50,.42,.47),CFrame.new(21,8.66,23.88),
        walnutFace,Enum.Material.Wood,false)
    part(root,"Built-in stepped cornice edge",
        Vector3.new(27.74,.10,.35),CFrame.new(21,8.91,23.68),
        walnutHighlight,Enum.Material.Wood,false)
    -- Photo-informed muted classroom supply tubs: translucent-looking pale
    -- gray-blue, kraft and sage containers rather than 12 neon toy blocks.
    -- Unique blue and colored backpacks are left unchanged for continuity.
    local binColors={
        Color3.fromRGB(112,142,159),Color3.fromRGB(175,187,179),
        Color3.fromRGB(179,164,132),Color3.fromRGB(113,149,143),
        Color3.fromRGB(160,169,187),Color3.fromRGB(153,169,173),
    }
    local backpackColors={
        Color3.fromRGB(67,129,183),Color3.fromRGB(229,112,103),
        Color3.fromRGB(97,150,90),Color3.fromRGB(233,182,67),
        Color3.fromRGB(157,105,176),Color3.fromRGB(74,155,148),
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
            -- Real supply tubs have open tops and lower front lips. Keep
            -- their back walls tall, but reveal interior folders above the
            -- shorter front panel, without expanding storage footprints.
            for _,dz in ipairs({-1.15,1.15}) do
                local front=dz<0
                part(root,"Bin front and back",
                    Vector3.new(3.4,front and 1.08 or 1.45,.15),
                    cf*CFrame.new(0,front and -.20 or 0,dz),
                    color,Enum.Material.SmoothPlastic,false)
            end
            roundedPanel(root,"Bin label",Vector3.new(1.2,.43,.025),
                cf*CFrame.new(0,.18,-1.235),P.cream,.08,false,false)
            if (row+col)%2==0 then
                -- Six minimally protruding folders provide evidence of use.
                -- All papers are original low-detail anonymous props, not
                -- reproduced student assignments or school documents.
                part(root,"Stored classroom file folder",
                    Vector3.new(1.68,.82,.07),
                    cf*CFrame.new(0,.36,-.48),
                    (row==0) and Color3.fromRGB(223,215,190)
                        or Color3.fromRGB(196,211,207),
                    Enum.Material.SmoothPlastic,false)
            end
        end
    end
    part(root,"Wood coat rail",Vector3.new(26,.65,.38),CFrame.new(21,11.1,26.1),P.woodDark,Enum.Material.Wood,false)
    part(root,"Storage ledge",Vector3.new(27,.27,3.2),CFrame.new(21,8.35,25.1),P.woodDark,Enum.Material.Wood,false)
    for i=0,7 do
        local x=10.3+i*3.05
        part(root,"Metal coat hook",Vector3.new(.10,.55,.48),CFrame.new(x,10.83,25.76),P.metal,Enum.Material.Metal,false)
        -- Backpacks are upholstered schoolbags with a rounded rectangular
        -- profile, NOT eight identical ellipsoid balloons. All are decorative
        -- and remain supported by the physical coat hooks above the cubbies.
        local color=backpackColors[i%#backpackColors+1]:Lerp(P.woodDark,.10)
        local bagCF=CFrame.new(x,9.62,25.40)
        roundedPanel(root,"Hanging school bag",Vector3.new(1.72,2.10,.58),
            bagCF,color,.28,false,false,Enum.Material.Fabric)
        for _,side in ipairs({-1,1}) do
            part(root,"Backpack shoulder strap",Vector3.new(.19,1.37,.12),
                bagCF*CFrame.new(side*.57,-.11,.36),
                color:Lerp(P.ink,.20),Enum.Material.Fabric,false)
        end
        -- The handle meets the actual hook at y=10.83. This closes the
        -- visible gap that previously made the rounded blobs appear suspended.
        part(root,"Backpack hanging loop",Vector3.new(.44,.22,.14),
            CFrame.new(x,10.76,25.64),color:Lerp(P.ink,.21),
            Enum.Material.Fabric,false)
        part(root,"Backpack upper flap",Vector3.new(1.42,.38,.12),
            bagCF*CFrame.new(0,.51,-.355),color:Lerp(P.cream,.11),
            Enum.Material.Fabric,false)
        part(root,"Backpack front pocket",Vector3.new(1.18,.72,.13),
            bagCF*CFrame.new(0,-.43,-.38),color:Lerp(P.ink,.14),
            Enum.Material.Fabric,false)
        part(root,"Backpack pocket zipper",Vector3.new(.98,.055,.07),
            bagCF*CFrame.new(0,-.13,-.47),P.metal,Enum.Material.Metal,false)
        part(root,"Backpack zipper pull",Vector3.new(.09,.15,.085),
            bagCF*CFrame.new(.41,-.22,-.51),P.metal,Enum.Material.Metal,false)
    end
    -- Wall-mounted above the backpack hooks, not floating in front of and
    -- obscuring the shaped bags. Artwork below ends at approximately y=12.
    sign(root,"Cubbies label","READ • CREATE • GROW",Vector3.new(19,.90,.2),
        CFrame.new(21,13.0,26.28),P.blue,P.cream)
end

local function buildWindows(root: Instance)
    -- Photo-grounded landscape: muted hazy daylight and a green treeline.
    -- The old saturated blue sky and apartment-like facades were conspicuous
    -- through the glazed windows. Keep these original backdrop dimensions and
    -- the window frames, shutters, radiators and daylight entirely unchanged.
    part(root,"Outdoor sky backdrop",Vector3.new(.35,14,45),CFrame.new(-39,9,-6),
        Color3.fromRGB(192,211,216),Enum.Material.SmoothPlastic,false)
    part(root,"Outdoor hill backdrop",Vector3.new(.5,5,45),CFrame.new(-38.7,3.2,-6),
        Color3.fromRGB(91,139,92),Enum.Material.Grass,false)
    for _,z in ipairs({-19,6}) do
        for _,dy in ipairs({-4.75,4.75}) do
            part(root,"Window wood horizontal frame",Vector3.new(.5,.45,15.5),CFrame.new(-36.5,9+dy,z),Color3.fromRGB(217,223,213),Enum.Material.Wood,false)
        end
        for _,dz in ipairs({-7.6,7.6}) do
            part(root,"Window wood vertical frame",Vector3.new(.5,9.5,.45),CFrame.new(-36.5,9,z+dz),Color3.fromRGB(217,223,213),Enum.Material.Wood,false)
        end
        part(root,"Deep window sill",Vector3.new(1.8,.35,15.5),CFrame.new(-35.8,4.4,z),Color3.fromRGB(210,216,207),Enum.Material.Wood,false)
        -- Shallow internal returns make the glazing sit inside a believable
        -- thick school wall instead of appearing pasted onto one flat plane.
        for _,side in ipairs({-1,1}) do
            part(root,"Window painted plaster reveal",
                Vector3.new(.76,8.85,.18),
                CFrame.new(-36.05,9,z+side*7.77),
                Color3.fromRGB(226,218,199),Enum.Material.SmoothPlastic,false)
            part(root,"Window timber inner stop",
                Vector3.new(.19,8.85,.17),
                CFrame.new(-35.61,9,z+side*7.64),
                Color3.fromRGB(223,225,213),Enum.Material.Wood,false)
        end
        part(root,"Window interior head return",
            Vector3.new(.76,.20,15.38),CFrame.new(-36.03,13.62,z),
            Color3.fromRGB(224,215,195),Enum.Material.SmoothPlastic,false)
        part(root,"Window sill rounded shadow line",
            Vector3.new(1.36,.055,15.22),CFrame.new(-35.71,4.64,z),
            Color3.fromRGB(104,91,77),Enum.Material.Wood,false)
        local glass=part(root,"Window glass",Vector3.new(.22,8.4,14.2),CFrame.new(-36.18,9,z),Color3.fromRGB(233,242,238),Enum.Material.Glass,false);glass.Transparency=.68;glass.Reflectance=.005
        for _,dz in ipairs({-4.6,0,4.6}) do part(root,"Window vertical mullion",Vector3.new(.28,8.5,.24),CFrame.new(-36.03,9,z+dz),Color3.fromRGB(217,223,213),Enum.Material.Wood,false) end
        part(root,"Window horizontal mullion",Vector3.new(.3,.30,14.2),CFrame.new(-36.02,9,z),Color3.fromRGB(217,223,213),Enum.Material.Wood,false)
        -- IMG_2906/2910: navy curtains gathered open on either side of both
        -- school windows. The old six pencil-thin blue strips were almost
        -- invisible from the child-eye camera. Keep the central 11+ stud
        -- daylight aperture unobstructed and the underlying blinds in place.
        -- These original Fabric details are strictly decorative/noncolliding.
        part(root,"Blue curtain valance",Vector3.new(.25,.38,15),
            CFrame.new(-35.50,13.16,z),Color3.fromRGB(54,70,110),
            Enum.Material.Fabric,false)
        for i=0,15 do
            local shade=part(root,"Window blind slat",Vector3.new(.14,.10,14.1),
                CFrame.new(-35.90,12.9-i*.15,z),
                Color3.fromRGB(221,217,199),Enum.Material.Fabric,false)
            shade.Transparency=.12
        end
        for _,side in ipairs({-1,1}) do
            local curtainZ=z+side*6.65
            part(root,"Navy curtain fabric panel",
                Vector3.new(.15,8.00,1.47),
                CFrame.new(-35.43,9.05,curtainZ),
                Color3.fromRGB(51,67,105),Enum.Material.Fabric,false)
            -- Shallow alternating folds, rather than six dangling poles.
            -- Two seams per panel provide fabric depth at iPhone distance.
            for pleat=1,2 do
                local dz=(pleat==1 and -.37 or .37)
                part(root,"Navy curtain stitched pleat",
                    Vector3.new(.08,7.72,.20),
                    CFrame.new(-35.29,9.04,curtainZ+dz),
                    pleat==1 and Color3.fromRGB(43,57,91)
                        or Color3.fromRGB(72,88,124),
                    Enum.Material.Fabric,false)
            end
            part(root,"Navy curtain cloth tieback",
                Vector3.new(.10,.23,1.30),
                CFrame.new(-35.26,7.70,curtainZ),
                Color3.fromRGB(135,147,166),Enum.Material.Fabric,false)
        end
        part(root,"Radiator body",Vector3.new(1.35,2.6,11.7),CFrame.new(-35.2,1.75,z),Color3.fromRGB(222,221,207),Enum.Material.Metal,false)
        -- Ten widely spaced stamped-metal fins per radiator preserve the body
        -- silhouette while leaving room for higher-impact bookcover details.
        -- Fewer tiny individual Parts improves mobile replication/draw work.
        for rz=-4.95,4.95,1.1 do part(root,"Radiator fin",Vector3.new(1.48,2.7,.18),CFrame.new(-34.48,1.75,z+rz),Color3.fromRGB(201,204,196),Enum.Material.Metal,false) end
        if z==-19 then
            -- Real photo: compact beige window AC at the LOWER LEFT window,
            -- just inside the opening above its original wood sill. Model a
            -- steel enclosure and restrained stamped grille, not an oversized
            -- block or a glowing UI. All pieces are static and noncolliding.
            local acColor=Color3.fromRGB(213,210,193)
            local housing=part(root,"Photo window air conditioner housing",
                Vector3.new(1.05,1.24,4.80),
                CFrame.new(-35.55,5.23,z),acColor,Enum.Material.Metal,false)
            housing.Reflectance=.015
            part(root,"Photo AC inset front grille",
                Vector3.new(.08,.85,3.85),
                CFrame.new(-34.975,5.29,z-.42),
                Color3.fromRGB(155,158,152),Enum.Material.Metal,false)
            for row=0,4 do
                part(root,"Photo AC horizontal vent louver",
                    Vector3.new(.05,.065,3.70),
                    CFrame.new(-34.913,5.00+row*.145,z-.42),
                    Color3.fromRGB(92,100,102),Enum.Material.Metal,false)
            end
            part(root,"Photo AC control fascia",
                Vector3.new(.085,.85,.68),
                CFrame.new(-34.970,5.29,z+2.0),
                Color3.fromRGB(230,224,206),
                Enum.Material.SmoothPlastic,false)
            for _,y in ipairs({5.08,5.49}) do
                cylinder(root,"Photo AC control dial",
                    Vector3.new(.08,.18,.18),
                    CFrame.new(-34.895,y,z+2.0)*CFrame.Angles(0,math.pi/2,0),
                    Color3.fromRGB(82,88,91),
                    Enum.Material.SmoothPlastic,false)
            end
        end
    end
    -- Warm sunlight washes the front-left classroom corner.
    local sunAnchor=part(root,"Window sun anchor",Vector3.new(.3,.3,.3),CFrame.new(-34,10,-10),Color3.new(1,1,1),Enum.Material.Neon,false);sunAnchor.Transparency=1
    local sun=Instance.new("PointLight");sun.Color=Color3.fromRGB(255,246,225);sun.Brightness=.50;sun.Range=48;sun.Shadows=true;sun.Parent=sunAnchor
end

-- Photo-specific grouping from the newly supplied cheer classroom image:
-- a gray tall cabinet and narrow black files left of the AC window, with a
-- worktable in front of the seated adult. No people, game UI, or new gameplay.
-- Photo perspective is incomplete; coordinates remain owner-review candidates.
local function buildPhotoWindowWorkstation(root: Instance)
    local gray=Color3.fromRGB(126,135,140)
    local dark=Color3.fromRGB(46,49,52)
    part(root,"Photo gray corner storage cabinet",
        Vector3.new(2.55,10.8,4.1),CFrame.new(-34.05,5.55,-30.50),
        gray,Enum.Material.Metal,true)
    part(root,"Photo gray cabinet front",
        Vector3.new(.10,9.75,3.80),CFrame.new(-32.72,5.55,-30.50),
        Color3.fromRGB(137,147,152),Enum.Material.Metal,false)
    for _,y in ipairs({2.9,8.3}) do
        part(root,"Photo gray cabinet pull",
            Vector3.new(.15,.86,.15),CFrame.new(-32.60,y,-29.17),
            Color3.fromRGB(64,72,78),Enum.Material.Metal,false)
    end
    part(root,"Photo black filing cabinet",
        Vector3.new(2.45,5.40,2.10),CFrame.new(-34.10,3.12,-26.25),
        dark,Enum.Material.Metal,true)
    for _,y in ipairs({1.65,3.30,4.95}) do
        part(root,"Photo filing drawer face",
            Vector3.new(.075,1.35,1.90),CFrame.new(-32.83,y,-26.25),
            Color3.fromRGB(57,60,63),Enum.Material.Metal,false)
        part(root,"Photo filing drawer pull",
            Vector3.new(.12,.14,.68),CFrame.new(-32.73,y,-26.25),
            Color3.fromRGB(166,174,179),Enum.Material.Metal,false)
    end
    -- Surface stands between the purple chair and the student workstations,
    -- without covering the school rug or the existing front-row desks.
    part(root,"Photo window worktable",
        Vector3.new(6.20,.28,4.00),CFrame.new(-27.50,3.16,-19.60),
        Color3.fromRGB(150,170,178),Enum.Material.SmoothPlastic,true)
    for _,x in ipairs({-30.04,-24.96}) do
        for _,z in ipairs({-21.12,-18.08}) do
            part(root,"Photo worktable metal leg",
                Vector3.new(.18,2.92,.18),CFrame.new(x,1.49,z),
                Color3.fromRGB(88,93,95),Enum.Material.Metal,true)
        end
    end
    -- Only a few anonymous school papers: avoid turning a real corner into a
    -- decorative exhibition or implying a specific pupil's work.
    part(root,"Photo worktable paper stack",
        Vector3.new(1.75,.10,1.08),CFrame.new(-26.65,3.38,-20.45),
        Color3.fromRGB(243,241,235),Enum.Material.SmoothPlastic,false)
    part(root,"Photo worktable book",
        Vector3.new(1.10,.22,1.48),CFrame.new(-29.15,3.42,-18.85),
        Color3.fromRGB(52,73,108),Enum.Material.SmoothPlastic,false)
end

local function buildFrontWall(root: Instance)
    -- IMG_2909/2910 show the freestanding display in front of a much wider
    -- blackboard. Preserve the structural wall, the photograph's layering,
    -- and all original student furniture positions; location is provisional.
    part(root,"Main chalkboard",Vector3.new(29.0,7.55,.30),CFrame.new(5.2,8.1,-34.14),Color3.fromRGB(43,54,50),Enum.Material.SmoothPlastic,false)
    for _,y in ipairs({4.20,12.0}) do
        part(root,"Chalkboard hardwood horizontal",Vector3.new(29.8,.48,.60),CFrame.new(5.2,y,-34.0),
            Color3.fromRGB(119,83,53),Enum.Material.Wood,false)
    end
    for _,x in ipairs({-9.7,20.1}) do
        part(root,"Chalkboard hardwood stile",Vector3.new(.42,7.85,.58),CFrame.new(x,8.1,-34.0),
            Color3.fromRGB(119,83,53),Enum.Material.Wood,false)
    end
    part(root,"Chalk tray",Vector3.new(29.0,.18,.80),CFrame.new(5.2,4.02,-33.63),Color3.fromRGB(129,92,57),Enum.Material.Wood,false)
    for i=0,3 do
        part(root,"Chalk stick",Vector3.new(.58,.095,.095),CFrame.new(-8.6+i*.64,4.16,-33.37),
            P.cream,Enum.Material.SmoothPlastic,false)
    end
    part(root,"Chalkboard eraser",Vector3.new(1.20,.28,.51),CFrame.new(-6.6,4.2,-33.38),P.ink,Enum.Material.Fabric,false)
    -- IMG_2909/2910: the modern white-framed touch display stands on a
    -- wheeled steel support in front of the permanent teaching wall.
    -- Keep its established x/y and screen proportions but move it two studs
    -- into the room so its depth, support posts and casters are visible.
    -- Every newly authored cart element is noncolliding and contains no script.
    -- Real IMG_2909/2910 display has a substantial off-white molded frame;
    -- the previous navy 0.25-stud edge read as a generic dark rectangle.
    -- Reuse the existing noncolliding backing Part, no new geometry.
    part(root,"Smartboard white composite bezel",Vector3.new(19.85,7.27,.24),
        CFrame.new(5.2,8.2,-31.95),
        Color3.fromRGB(242,244,240),Enum.Material.SmoothPlastic,false)
    part(root,"Smartboard pen tray",Vector3.new(10.5,.22,.65),
        CFrame.new(5.2,4.61,-31.18),Color3.fromRGB(208,211,209),
        Enum.Material.Metal,false)
    local smart=part(root,"Interactive smartboard",Vector3.new(18.85,6.35,.35),
        CFrame.new(5.2,8.2,-31.67),Color3.fromRGB(238,243,241),
        Enum.Material.Glass,false);smart.Transparency=.02
    for _,dx in ipairs({-5.1,5.1}) do
        local supportX=5.2+dx
        part(root,"Mobile smartboard support post",Vector3.new(.25,4.35,.26),
            CFrame.new(supportX,2.85,-32.25),
            Color3.fromRGB(118,125,128),Enum.Material.Metal,false)
        part(root,"Mobile smartboard mounting collar",Vector3.new(.72,.36,.35),
            CFrame.new(supportX,5.0,-32.22),
            Color3.fromRGB(172,180,181),Enum.Material.Metal,false)
        part(root,"Mobile smartboard rolling foot",Vector3.new(.30,.18,2.70),
            CFrame.new(supportX,.79,-32.21),
            Color3.fromRGB(106,113,117),Enum.Material.Metal,false)
        for _,casterZ in ipairs({-33.25,-31.15}) do
            ball(root,"Mobile smartboard caster",Vector3.new(.44,.44,.44),
                CFrame.new(supportX,.73,casterZ),
                Color3.fromRGB(57,61,65),Enum.Material.SmoothPlastic,false)
        end
    end
    part(root,"Mobile smartboard cross brace",Vector3.new(10.5,.20,.22),
        CFrame.new(5.2,2.8,-32.32),
        Color3.fromRGB(118,125,128),Enum.Material.Metal,false)
    -- Static architectural smartboard. GalleryPass supplies a non-interactive display.


    -- Cross, motto, alphabet strip and classroom values from the target concept.
    part(root,"Classroom cross vertical",Vector3.new(1,4.8,.45),CFrame.new(32,10,-33.9),Color3.fromRGB(104,72,46),Enum.Material.Wood,false)
    part(root,"Classroom cross horizontal",Vector3.new(3.5,1,.45),CFrame.new(32,10.7,-33.72),Color3.fromRGB(104,72,46),Enum.Material.Wood,false)
    -- Photographed chalkboard: a dark-blue handwritten alphabet frieze
    -- and 26 small phonics cards, not a generic giant slogan.
    -- Reuse EXACTLY 27 existing physical Parts. These original example words
    -- are purely scenery, NOT a teacher's curriculum or children's work.
    local banner=part(root,"Handwriting alphabet strip",
        Vector3.new(29,1.45,.2),CFrame.new(-6,15.0,-33.85),
        Color3.fromRGB(43,75,111),Enum.Material.SmoothPlastic,false)
    local writing=surfaceText(banner,
        "a b c d e f g h i j k l m n o p q r s t u v w x y z",
        Enum.NormalId.Back,P.cream,banner.Color,Enum.Font.Garamond)
    writing.Name="HandwritingSequence"
    writing.TextWrapped=false
    local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local examples={
        "apple","ball","cat","dog","egg","fish","goat","hat","igloo",
        "jam","kite","leaf","moon","nest","owl","pig","queen","rain",
        "sun","tree","umbrella","violin","whale","x-ray","yarn","zebra",
    }
    local palettes={
        Color3.fromRGB(224,238,227),Color3.fromRGB(240,228,209),
        Color3.fromRGB(220,232,240),Color3.fromRGB(239,220,218),
    }
    for i=1,26 do
        local x=-31.2+(i-1)*2.38
        local tint=palettes[(i-1)%#palettes+1]
        local tile=part(root,"Alphabet tile",
            Vector3.new(2.15,1.4,.18),CFrame.new(x,13.4,-33.78),
            tint,Enum.Material.SmoothPlastic,false)
        local letter=string.sub(alphabet,i,i)
        local big=surfaceText(tile,letter..string.lower(letter),
            Enum.NormalId.Back,P.blue,tint,Enum.Font.GothamBold)
        big.Name="PhonicsLetter"
        big.Size=UDim2.fromScale(1,.64)
        big.BackgroundTransparency=1
        big.TextWrapped=false
        local surface=big.Parent
        if surface and surface:IsA("SurfaceGui") then
            surface.CanvasSize=Vector2.new(260,170)
            surface.LightInfluence=.08
        end
        local word=Instance.new("TextLabel")
        word.Name="PhonicsExample"
        word.Text=examples[i]
        word.Font=Enum.Font.GothamMedium
        word.TextColor3=Color3.fromRGB(52,69,81)
        word.BackgroundTransparency=1
        word.Position=UDim2.fromScale(.04,.67)
        word.Size=UDim2.fromScale(.92,.28)
        word.TextScaled=true
        word.TextWrapped=false
        word.Parent=surface
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
    -- Seat the laptop and all desk supplies on the real laminate plane (top y=3.29).
    -- Previously the laptop base and several objects hovered 0.1-0.3 studs.
    local screenCF=CFrame.new(26,4.94,-26.1)*CFrame.Angles(math.rad(-8),0,0)
    roundedPanel(root,"Laptop display frame",Vector3.new(4.6,2.8,.20),screenCF,Color3.fromRGB(38,42,48),.12,false,false)
    local laptop=part(root,"Teacher laptop screen",Vector3.new(4.23,2.40,.025),screenCF*CFrame.new(0,.03,.12),Color3.fromRGB(225,238,236),Enum.Material.SmoothPlastic,false)
    local display=surfaceText(laptop,"TODAY'S LESSON\nReading • Math • Spelling",Enum.NormalId.Back,P.blue,Color3.fromRGB(225,238,236),Enum.Font.GothamMedium)
    display.BackgroundTransparency=0
    ball(root,"Laptop webcam",Vector3.new(.065,.065,.025),screenCF*CFrame.new(0,1.29,.12),P.ink,Enum.Material.Glass,false)
    roundedPanel(root,"Teacher laptop base",Vector3.new(4.8,.20,3.1),CFrame.new(26,3.39,-24.85),Color3.fromRGB(162,167,173),.14,true,false)
    -- The previous 40 individually replicated 3D keycaps were tiny and
    -- indistinguishable in the native iPhone classroom walkthrough. Retain
    -- all forty manufactured key shapes as static in-world SurfaceGui Frames
    -- on ONE supported noncolliding keyboard deck, saving 39 physical Parts.
    -- This is decorative laptop artwork, not any educational/gameplay UI.
    local keyboardCF=CFrame.new(26,3.51,-25.20)
    local keyboard=part(root,"Laptop native keyboard panel",
        Vector3.new(4.20,.025,1.45),keyboardCF,
        Color3.fromRGB(51,56,60),Enum.Material.SmoothPlastic,false)
    keyboard.CastShadow=false
    local keyGui=Instance.new("SurfaceGui")
    keyGui.Name="LaptopKeyboardDetail"
    keyGui.Face=Enum.NormalId.Top
    keyGui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
    keyGui.CanvasSize=Vector2.new(840,290)
    keyGui.LightInfluence=.10
    keyGui.Parent=keyboard
    local backing=Instance.new("Frame")
    backing.Name="LaptopKeyboardBackground"
    backing.Size=UDim2.fromScale(1,1)
    backing.BackgroundColor3=Color3.fromRGB(49,52,57)
    backing.BorderSizePixel=0
    backing.Parent=keyGui
    for row=0,3 do
        for col=0,9 do
            local key=Instance.new("Frame")
            key.Name="LaptopKeycap"
            key.Position=UDim2.fromScale(.067+col*.089,.085+row*.224)
            key.Size=UDim2.fromScale(.074,.155)
            local shade=74+((row+col)%3)*5
            key.BackgroundColor3=Color3.fromRGB(shade,shade+3,shade+6)
            key.BorderSizePixel=0
            key.Parent=backing
        end
    end
    part(root,"Laptop space bar",Vector3.new(1.7,.04,.23),CFrame.new(26,3.52,-24.32),P.ink,Enum.Material.SmoothPlastic,false)
    roundedPanel(root,"Laptop trackpad",Vector3.new(1.48,.016,.68),CFrame.new(26,3.52,-23.87),Color3.fromRGB(119,126,136),.06,true,false)
    cylinder(root,"Laptop hinge",Vector3.new(4.30,.16,.16),CFrame.new(26,3.53,-26.12),P.metal,Enum.Material.Metal,false)
    pencilCup(root,21.5,4.08,-24.2)
    book(root,29.5,3.38,-24.2,Color3.fromRGB(61,110,78),math.rad(8))
    book(root,29.5,3.64,-24.2,Color3.fromRGB(44,75,110),math.rad(8))
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

-- Teacher's annotated weekly board, placed between the Smartboard and cross.
-- All small paper layers are noncolliding and sit on the room-facing cork side.
-- The lesson print is atmospheric, not connected to any study authority.
local function buildTeacherPlanningWall(root: Instance)
    local x,y,z=22.65,8.90,-33.95
    part(root,"Teacher planning board shallow oak back",
        Vector3.new(9.4,6.4,.16),CFrame.new(x,y,z-.17),
        Color3.fromRGB(120,84,57),Enum.Material.Wood,false)
    part(root,"Teacher planning board woven cork",
        Vector3.new(8.90,5.94,.08),CFrame.new(x,y,z+.02),
        Color3.fromRGB(171,133,96),Enum.Material.Fabric,false)
    for _,dy in ipairs({-3.08,3.08}) do
        part(root,"Teacher planning board hardwood trim",
            Vector3.new(9.45,.25,.26),CFrame.new(x,y+dy,z+.14),
            Color3.fromRGB(102,70,48),Enum.Material.Wood,false)
    end
    for _,dx in ipairs({-4.57,4.57}) do
        part(root,"Teacher planning board hardwood stile",
            Vector3.new(.24,6.22,.26),CFrame.new(x+dx,y,z+.14),
            Color3.fromRGB(102,70,48),Enum.Material.Wood,false)
    end
    local heading=part(root,"Teacher planning board header",
        Vector3.new(7.75,.55,.055),CFrame.new(x,y+2.35,z+.12),
        P.blue,Enum.Material.SmoothPlastic,false)
    surfaceText(heading,"THIS WEEK",Enum.NormalId.Back,P.cream,heading.Color)
    local paperTints={
        Color3.fromRGB(248,243,224),
        Color3.fromRGB(226,234,231),
        Color3.fromRGB(242,225,218),
    }
    for i,dx in ipairs({-2.75,0,2.75}) do
        local yOffset=(i==2) and -.12 or .08
        local sheet=part(root,"Teacher annotated planning sheet",
            Vector3.new(2.23,3.10,.045),CFrame.new(x+dx,y-.36+yOffset,z+.17),
            paperTints[i],Enum.Material.SmoothPlastic,false)
        part(root,"Teacher planning sheet colored tab",
            Vector3.new(1.72,.22,.035),
            sheet.CFrame*CFrame.new(0,1.01,.04),
            ({P.blue,P.green,Color3.fromRGB(178,106,85)})[i],
            Enum.Material.SmoothPlastic,false)
        for j=1,4 do
            part(root,"Teacher handwritten planner line",
                Vector3.new(1.60-(j%2)*.22,.032,.03),
                sheet.CFrame*CFrame.new(-.07,.68-j*.45,.052),
                Color3.fromRGB(142,153,151),Enum.Material.SmoothPlastic,false)
        end
        ball(root,"Teacher planner brass pin",
            Vector3.new(.17,.17,.09),
            sheet.CFrame*CFrame.new(0,1.48,.10),
            Color3.fromRGB(190,158,88),Enum.Material.Metal,false)
    end
    -- Fine rail below the papers creates a physical shadow; not a walk collider.
    part(root,"Teacher planner chalk ledge",
        Vector3.new(8.15,.12,.45),CFrame.new(x,y-3.18,z+.22),
        Color3.fromRGB(139,99,69),Enum.Material.Wood,false)
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
    -- Source-derived October 10 hallway screenshots proved that a single
    -- opaque ten-stud Wood slab sat BEHIND each translucent "Door glass".
    -- Transparency could never reveal the classroom. Form a REAL aperture:
    -- the one original door Part becomes the lower solid panel; reuse the
    -- existing two oak rails and two side stiles as the upper timber frame.
    -- Only two slim middle crossbars and two brass pulls add physical Parts.
    -- Keep the same open-leaf rotation, threshold and NO-COLLISION policy.
    for _,x in ipairs({-2.75,2.75}) do
        local leafCF=CFrame.new(x,5.28,25.96)*
            CFrame.Angles(0,math.rad(x<0 and -48 or 48),0)
        -- Relative bottom -5 and top -.74 of the original ten-stud door.
        local door=part(root,"Open classroom door",Vector3.new(4.65,4.26,.36),
            leafCF*CFrame.new(0,-2.87,0),
            Color3.fromRGB(128,91,60),Enum.Material.Wood,false)
        door:SetAttribute("OpenLeaf","Lower solid panel; glass aperture above")
        local glass=part(root,"Door glass",Vector3.new(2.54,4.38,.10),
            leafCF*CFrame.new(0,1.42,-.06),
            Color3.fromRGB(198,217,217),Enum.Material.Glass,false)
        glass.Transparency=.29
        glass.Reflectance=.025
        glass.CastShadow=false
        glass:SetAttribute("GlazedOpening","No opaque slab behind this pane")
        -- Reuse the original two rail Parts: a lower glass sill and tall
        -- upper timber lintel, both matching the original leaf outline.
        for _,rail in ipairs({
            {name="Sill",y=-.88,height=.32},
            {name="Top",y=4.35,height=1.30},
        }) do
            local p=part(root,"Glazed door solid oak rail",
                Vector3.new(4.65,rail.height,.36),
                leafCF*CFrame.new(0,rail.y,0),
                Color3.fromRGB(112,76,50),Enum.Material.Wood,false)
            p:SetAttribute("DoorRailType",rail.name)
        end
        -- Widen ONLY the existing pair of very thin side stiles. This fills
        -- the margins outside the true glass cut-out without obscuring it.
        for _,dx in ipairs({-1.80,1.80}) do
            part(root,"Glazed door oak side stile",
                Vector3.new(1.05,4.38,.36),
                leafCF*CFrame.new(dx,1.42,0),
                Color3.fromRGB(112,76,50),Enum.Material.Wood,false)
        end
        part(root,"Door lower raised panel",Vector3.new(3.7,2.85,.10),
            leafCF*CFrame.new(0,-2.72,-.24),
            Color3.fromRGB(142,105,73),Enum.Material.Wood,false)
        -- Photo: wood crossbar visually separates the two glazed lights.
        -- The clear glazing remains a full pane with thin frame in front.
        part(root,"Glazed door glass divider",Vector3.new(2.54,.18,.14),
            leafCF*CFrame.new(0,1.42,-.17),
            Color3.fromRGB(121,84,54),Enum.Material.Wood,false)
        -- Near-leaf narrow vintage pull, photo-guided but not door physics.
        part(root,"Glazed door brass pull",Vector3.new(.14,.70,.16),
            leafCF*CFrame.new(x<0 and 2.06 or -2.06,-.60,-.27),
            Color3.fromRGB(181,153,103),Enum.Material.Metal,false)
    end
    sign(root,"Welcome over door","EMMA'S CLASSROOM",Vector3.new(10.7,1.20,.16),
        CFrame.new(0,15.6,26.40),Color3.fromRGB(247,237,207),P.blue)
    -- OWNER-SUPPLIED SIX PHOTOS: corridor architecture, not event-day people.
    -- Long corridor scales and X direction are explicitly PROVISIONAL.
    -- Artistic tile/assignment geometry is authored with SurfaceGui Frames
    -- to leave the existing 3,100-physical-Part iPhone budget unchanged.
    local hall=Instance.new("Folder")
    hall.Name="PhotographedHallway"
    hall:SetAttribute("Reference","2026-10-10 anonymous hallway architecture")
    hall:SetAttribute("ScaleConfidence","provisional")
    hall.Parent=root
    local blueGray=Color3.fromRGB(107,117,125)
    local darkOak=Color3.fromRGB(112,77,50)
    local paperColor=Color3.fromRGB(243,241,232)
    local mortar=Color3.fromRGB(106,74,49)
    local function hp(name:string,size:Vector3,cf:CFrame,color:Color3,
        material:Enum.Material?,solid:boolean?):Part
        local p=part(hall,name,size,cf,color,material,solid)
        if solid==false then p.CanQuery=false;p.CastShadow=false end
        return p
    end
    local function imageSurface(target:BasePart,name:string,face:Enum.NormalId,
        wide:number,tall:number):SurfaceGui
        local gui=Instance.new("SurfaceGui")
        gui.Name=name;gui.Face=face;gui.LightInfluence=.34
        gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
        gui.CanvasSize=Vector2.new(wide,tall);gui.Parent=target
        return gui
    end
    local function paintedRectangle(parent:Instance,name:string,
        size:UDim2,pos:UDim2,color:Color3):Frame
        local f=Instance.new("Frame")
        f.Name=name;f.Size=size;f.Position=pos
        f.BorderSizePixel=0;f.BackgroundColor3=color;f.Parent=parent
        return f
    end

    -- One safe physical floor: the native Top SurfaceGui draws narrow
    -- square-tile grout at ~4.5-stud centers without 28 extra Parts.
    local floor=hp("Photo hall polished square stone floor",
        Vector3.new(108,.50,22.5),CFrame.new(0,.25,38),
        Color3.fromRGB(75,73,70),Enum.Material.SmoothPlastic,true)
    floor.Reflectance=.085
    local floorGui=imageSurface(floor,"Photo square-stone tile grout",
        Enum.NormalId.Top,2160,450)
    for x=0,24 do
        local line=paintedRectangle(floorGui,"Stone long tile joint",
            UDim2.fromOffset(1,450),UDim2.fromOffset(x*90,0),
            Color3.fromRGB(38,37,36))
        line.BackgroundTransparency=.44
    end
    for z=0,5 do
        local line=paintedRectangle(floorGui,"Stone cross tile joint",
            UDim2.fromOffset(2160,1),UDim2.fromOffset(0,z*90),
            Color3.fromRGB(38,37,36))
        line.BackgroundTransparency=.44
    end
    -- Existing real wood-and-glass entrance and open double leaf retain
    -- their exact shapes, free walking clearance and level brass threshold.
    hp("Classroom doorway brass threshold",Vector3.new(10.02,.045,.24),
        CFrame.new(0,.556,26.65),Color3.fromRGB(169,145,88),
        Enum.Material.Metal,false)

    local rear=hp("Photo hall rear blue-gray wall",Vector3.new(108,13,.90),
        CFrame.new(0,6.5,49.25),blueGray,Enum.Material.SmoothPlastic,true)
    for _,x in ipairs({-45.5,45.5}) do
        hp("Photo hall front outer wall",Vector3.new(17,13,.90),
            CFrame.new(x,6.5,26.95),blueGray,Enum.Material.SmoothPlastic,true)
    end
    local leftCap=hp("Photo hall end cap",Vector3.new(.9,13,22.5),
        CFrame.new(-54,6.5,38),blueGray,Enum.Material.SmoothPlastic,true)
    local rightCap=hp("Photo hall end cap",Vector3.new(.9,13,22.5),
        CFrame.new(54,6.5,38),blueGray,Enum.Material.SmoothPlastic,true)
    -- Paint only the CORRIDOR-facing side of original pale-yellow classroom
    -- back wall; don't change Emma's existing interior or cut new doorways.
    for _,x in ipairs({-23,23}) do
        hp("Photo hall classroom exterior blue-gray paint",
            Vector3.new(28,8.6,.09),CFrame.new(x,8.7,27.565),
            blueGray,Enum.Material.SmoothPlastic,false)
    end

    -- A true 6-course staggered bond and subtle ochre tone differences.
    -- The graphic lives on seven noncolliding flat dado carriers, and is
    -- fully independent of marketplace image uploads / texture IDs.
    local bricks={
        Color3.fromRGB(188,123,54),Color3.fromRGB(196,134,61),
        Color3.fromRGB(211,148,68),Color3.fromRGB(174,111,48),
        Color3.fromRGB(201,141,72),Color3.fromRGB(181,121,60),
    }
    local function dado(name:string,size:Vector3,cf:CFrame,face:Enum.NormalId)
        -- Warm ochre glazed-brick BASE is visible even where third-party
        -- renderers or low-detail clients omit the staggered SurfaceGui.
        -- Dark mortar and color variation are still drawn by the GUI on top.
        local p=hp(name,size,cf,Color3.fromRGB(192,132,63),
            Enum.Material.SmoothPlastic,false)
        p.Reflectance=.055
        local w=(face==Enum.NormalId.Left or face==Enum.NormalId.Right)
            and size.Z or size.X
        local pixels=math.max(50,math.floor(w*22))
        local gui=imageSurface(p,"Photo glazed offset brick bond",face,pixels,100)
        local field=paintedRectangle(gui,"Warm mortar field",
            UDim2.fromScale(1,1),UDim2.fromScale(0,0),mortar)
        field.ClipsDescendants=true
        local brickW=78
        for row=0,5 do
            local offset=(row%2==0) and 0 or -brickW/2
            for col=0,math.ceil(pixels/brickW)+1 do
                local px=math.floor(offset+col*brickW+2)
                if px<pixels and px+brickW>0 then
                    paintedRectangle(field,"Photo glazed brick",
                        UDim2.fromOffset(brickW-3,14),
                        UDim2.fromOffset(px,math.floor(row*100/6+1)),
                        bricks[((row*7+col*3)%#bricks)+1])
                end
            end
        end
    end
    dado("Photo hall rear glazed brick",Vector3.new(107,4.25,.075),
        CFrame.new(0,2.125,48.735),Enum.NormalId.Front)
    for _,x in ipairs({-23,23}) do
        dado("Photo hall classroom exterior glazed brick",
            Vector3.new(27.85,4.25,.075),CFrame.new(x,2.125,27.66),
            Enum.NormalId.Back)
    end
    for _,x in ipairs({-45.5,45.5}) do
        dado("Photo hall front outer glazed brick",
            Vector3.new(16.75,4.25,.075),CFrame.new(x,2.125,27.66),
            Enum.NormalId.Back)
    end
    dado("Photo hall left end glazed brick",
        Vector3.new(.075,4.25,22),CFrame.new(-53.49,2.125,38),
        Enum.NormalId.Right)
    dado("Photo hall right end glazed brick",
        Vector3.new(.075,4.25,22),CFrame.new(53.49,2.125,38),
        Enum.NormalId.Left)
    hp("Photo hall rear dado cap",Vector3.new(107.2,.16,.16),
        CFrame.new(0,4.34,48.66),Color3.fromRGB(162,124,79),
        Enum.Material.Wood,false)
    for _,x in ipairs({-31.5,31.5}) do
        hp("Photo hall front dado cap",Vector3.new(44.5,.16,.14),
            CFrame.new(x,4.34,27.73),Color3.fromRGB(162,124,79),
            Enum.Material.Wood,false)
    end

    -- Both faces of the ACTUAL existing glass leaves receive tiny, anonymous
    -- green shamrock artwork. Four circular UI lobes and one stem each.
    for _,obj in ipairs(root:GetChildren()) do
        if obj.Name=="Door glass" and obj:IsA("BasePart") then
            for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back}) do
                local gui=imageSurface(obj,"Photo green shamrock on glass",
                    face,300,440)
                for _,xy in ipairs({{105,90},{151,90},{128,54},{128,132}}) do
                    local petal=paintedRectangle(gui,"Shamrock leaf",
                        UDim2.fromOffset(53,53),
                        UDim2.fromOffset(xy[1],xy[2]),
                        Color3.fromRGB(46,119,67))
                    local corner=Instance.new("UICorner")
                    corner.CornerRadius=UDim.new(1,0);corner.Parent=petal
                end
                local stem=paintedRectangle(gui,"Shamrock stem",
                    UDim2.fromOffset(9,60),UDim2.fromOffset(142,165),
                    Color3.fromRGB(46,119,67))
                stem.Rotation=-17
            end
        end
    end

    -- Adjacent closed school doors are facades, never fake enterable
    -- classrooms. One flat oak carrier per door, not 6+ separate blockers.
    for _,x in ipairs({-45.5,45.5}) do
        local door=hp("Photo hall adjacent oak door",
            Vector3.new(6.45,10,.14),CFrame.new(x,5.5,27.79),
            darkOak,Enum.Material.Wood,false)
        local gui=imageSurface(door,"Frosted glass and oak door trim",
            Enum.NormalId.Back,450,700)
        paintedRectangle(gui,"School door frosted glazing",
            UDim2.fromScale(.73,.51),UDim2.fromScale(.135,.09),
            Color3.fromRGB(187,202,202))
        paintedRectangle(gui,"School door oak center rail",
            UDim2.fromScale(.87,.035),UDim2.fromScale(.065,.58),
            Color3.fromRGB(149,102,60))
        paintedRectangle(gui,"School door brass push plate",
            UDim2.fromScale(.05,.15),UDim2.fromScale(.80,.69),
            Color3.fromRGB(181,161,118))
        paintedRectangle(gui,"School door lower raised panel",
            UDim2.fromScale(.73,.20),UDim2.fromScale(.135,.73),
            Color3.fromRGB(140,96,62))
    end
    local welcome=hp("Photo hall vertical welcome plaque",
        Vector3.new(1.15,7.5,.09),CFrame.new(-10.5,8,27.8),
        Color3.fromRGB(39,40,40),Enum.Material.SmoothPlastic,false)
    local welcomeArt=imageSurface(welcome,"Stacked WELCOME lettering",
        Enum.NormalId.Back,115,750)
    for i,letter in ipairs({"W","E","L","C","O","M","E"}) do
        local tile=Instance.new("TextLabel")
        tile.Name="Vertical school welcome letter"
        tile.Size=UDim2.fromScale(.94,1/7)
        tile.Position=UDim2.fromScale(.03,(i-1)/7)
        tile.BackgroundTransparency=1
        tile.Font=Enum.Font.GothamBold
        tile.TextColor3=paperColor;tile.TextScaled=true
        tile.Text=letter;tile.Parent=welcomeArt
    end

    -- A wood suspension rail and 23 ROTATED paper frames. Original printed
    -- student assignments, names, faces and event data are NOT reproduced.
    hp("Photo hall student work hanging rail",Vector3.new(83,.16,.17),
        CFrame.new(0,10.54,48.69),Color3.fromRGB(167,130,88),
        Enum.Material.Wood,false)
    local paperGui=imageSurface(rear,"Anonymous rotated schoolwork",
        Enum.NormalId.Front,2160,260)
    for i=-11,11 do
        local sheet=paintedRectangle(paperGui,"Photo hall anonymous diamond paper",
            UDim2.fromOffset(36,42),
            UDim2.fromOffset(math.floor(1080+i*3.55*20),86),
            paperColor)
        sheet.AnchorPoint=Vector2.new(.5,.5)
        sheet.Rotation=45
        for line=1,3 do
            local stroke=paintedRectangle(sheet,"Anonymous pencil guideline",
                UDim2.fromScale(.55,.017),
                UDim2.fromScale(.20,.22+line*.17),
                Color3.fromRGB(185,190,189))
            stroke.BackgroundTransparency=.1
        end
    end

    -- No open sky: a flat ivory acoustical ceiling and five pale, slim
    -- fluorescent diffusers with real downward SurfaceLight children.
    hp("Photo hall ivory ceiling",Vector3.new(108,.36,22.5),
        CFrame.new(0,13.2,38),Color3.fromRGB(237,236,226),
        Enum.Material.SmoothPlastic,false)
    for _,x in ipairs({-43,-22,0,22,43}) do
        local lens=hp("Photo hall fluorescent diffuser",
            Vector3.new(6.14,.08,2.04),CFrame.new(x,12.85,38),
            Color3.fromRGB(244,242,232),Enum.Material.Glass,false)
        lens.Transparency=.06
        local rim=imageSurface(lens,"Inset silver fluorescent rim",
            Enum.NormalId.Bottom,614,204)
        paintedRectangle(rim,"Frosted diffuser center",
            UDim2.fromScale(.92,.85),UDim2.fromScale(.04,.075),
            Color3.fromRGB(242,240,228))
        local light=Instance.new("SurfaceLight")
        light.Face=Enum.NormalId.Bottom
        light.Color=Color3.fromRGB(252,246,235)
        light.Brightness=.42;light.Range=19;light.Shadows=false
        light.Parent=lens
    end

    -- Far mustard-framed transom with hand-authored sunburst. Attach thin
    -- Graphics to solid end cap so the corridor cannot expose outdoor sky.
    local endGui=imageSurface(leftCap,"Photo hallway yellow end-window motif",
        Enum.NormalId.Right,450,260)
    local sash=paintedRectangle(endGui,"Mustard window frame",
        UDim2.fromOffset(300,175),UDim2.fromOffset(75,25),
        Color3.fromRGB(214,166,63))
    paintedRectangle(sash,"Dark frosted upper glazing",
        UDim2.fromScale(.93,.90),UDim2.fromScale(.035,.05),
        Color3.fromRGB(57,70,69))
    for _,x in ipairs({.33,.67}) do
        paintedRectangle(sash,"Yellow vertical glazing bar",
            UDim2.fromScale(.022,.91),UDim2.fromScale(x,.045),
            Color3.fromRGB(227,187,86))
    end
    paintedRectangle(sash,"Yellow horizontal glazing bar",
        UDim2.fromScale(.94,.03),UDim2.fromScale(.03,.52),
        Color3.fromRGB(227,187,86))
    local sun=paintedRectangle(sash,"Photo hall abstract sunrise",
        UDim2.fromOffset(44,44),UDim2.fromOffset(132,19),
        Color3.fromRGB(243,208,51))
    local sunCorner=Instance.new("UICorner")
    sunCorner.CornerRadius=UDim.new(1,0);sunCorner.Parent=sun
    for i=0,7 do
        local a=i*math.pi/4
        local ray=paintedRectangle(sash,"Photo hall drawn sun ray",
            UDim2.fromOffset(5,15),
            UDim2.fromOffset(math.floor(153+math.sin(a)*39),
                math.floor(40-math.cos(a)*39)),
            Color3.fromRGB(242,204,65))
        ray.Rotation=i*45
    end
    local noticeGui=imageSurface(rightCap,"Original school noticeboard",
        Enum.NormalId.Left,450,260)
    local board=paintedRectangle(noticeGui,"Oak school announcement frame",
        UDim2.fromOffset(120,85),UDim2.fromOffset(165,38),darkOak)
    paintedRectangle(board,"Cork facing",
        UDim2.fromScale(.93,.90),UDim2.fromScale(.035,.05),
        Color3.fromRGB(155,124,94))
    for _,x in ipairs({.12,.56}) do
        paintedRectangle(board,"Anonymous pale school flyer",
            UDim2.fromScale(.32,.57),UDim2.fromScale(x,.21),
            Color3.fromRGB(241,237,221))
    end
    -- Photographed children, event-day money, and food-drive bags remain
    -- outside this public place and repository.
end

local function buildTeacherEntry(root: Instance)
    -- Side staff door and a tiny continuation of the real blue-gray/tan-brick hallway.
    part(root,"Staff door jamb front",Vector3.new(1.3,11.5,1.0),CFrame.new(36.9,5.75,8.3),Color3.fromRGB(113,78,50),Enum.Material.Wood,false)
    part(root,"Staff door jamb back",Vector3.new(1.3,11.5,1.0),CFrame.new(36.9,5.75,22.7),Color3.fromRGB(113,78,50),Enum.Material.Wood,false)
    part(root,"Staff door header",Vector3.new(1.3,1.0,15.4),CFrame.new(36.9,11.25,15.5),Color3.fromRGB(113,78,50),Enum.Material.Wood,false)
    local door=part(root,"Open staff classroom door",Vector3.new(.55,10,6.6),CFrame.new(35.9,5.3,20.2)*CFrame.Angles(0,math.rad(58),0),Color3.fromRGB(124,87,57),Enum.Material.Wood,false)
    local glass=part(root,"Staff door glass",Vector3.new(.18,4.7,3.1),door.CFrame*CFrame.new(-.35,1.6,0),Color3.fromRGB(206,219,216),Enum.Material.Glass,false);glass.Transparency=.28
    part(root,"Side hall floor",Vector3.new(18,.5,20),CFrame.new(45.5,.25,15.5),Color3.fromRGB(67,68,66),Enum.Material.Slate)
    part(root,"Staff doorway brass threshold",
        Vector3.new(.24,.045,13.35),CFrame.new(37.10,.556,15.5),
        Color3.fromRGB(169,145,88),Enum.Material.Metal,false)
    part(root,"Side hall far wall",Vector3.new(1,13,20),CFrame.new(54.5,6.5,15.5),P.blueSoft)
    part(root,"Side hall far brick",Vector3.new(1.1,4.3,20),CFrame.new(54.0,2.15,15.5),Color3.fromRGB(177,122,63),Enum.Material.Brick,false)
    part(root,"Side hall ceiling",Vector3.new(18,.4,20),CFrame.new(45.5,13,15.5),Color3.fromRGB(224,226,223),Enum.Material.SmoothPlastic,false)
    -- Both z ends were entirely open: real iPhone video at 5-7 seconds
    -- revealed blue sky beside the classroom door and a dangling chair rail.
    -- Cap only the OUTER corridor ends, not the entrance through x=37.
    for _,endZ in ipairs({5.65,25.35}) do
        local interior = endZ < 15.5 and .53 or -.53
        part(root,"Side corridor end wall",Vector3.new(18,13,.80),
            CFrame.new(45.5,6.5,endZ),P.blueSoft,Enum.Material.SmoothPlastic,true)
        part(root,"Side corridor brick dado",Vector3.new(17.7,4.25,.13),
            CFrame.new(45.5,2.125,endZ+interior),
            Color3.fromRGB(177,122,63),Enum.Material.Brick,false)
        part(root,"Side corridor navy cap rail",Vector3.new(17.7,.16,.12),
            CFrame.new(45.5,4.30,endZ+interior*1.12),
            P.blue,Enum.Material.Wood,false)
    end
    -- Facing-wall school notices break up the blank corridor without
    -- claiming a photographed or navigable room beyond the capped hall.
    part(root,"Staff hall framed announcement board",Vector3.new(.16,3.35,5.90),
        CFrame.new(53.80,7.74,15.50),Color3.fromRGB(109,79,55),
        Enum.Material.Wood,false)
    part(root,"Staff hall inset cork noticeboard",Vector3.new(.07,2.99,5.52),
        CFrame.new(53.68,7.74,15.50),Color3.fromRGB(165,134,103),
        Enum.Material.Fabric,false)
    for _,pz in ipairs({13.85,17.15}) do
        part(root,"Staff hall anonymous paper notice",Vector3.new(.025,1.73,1.75),
            CFrame.new(53.61,7.70,pz),
            Color3.fromRGB(243,239,218),Enum.Material.SmoothPlastic,false)
    end
    part(root,"Side hall fluorescent metal surround",Vector3.new(6.45,.16,2.55),
        CFrame.new(47,12.80,15.5),Color3.fromRGB(193,200,200),
        Enum.Material.Metal,false)
    local hallLight=part(root,"Side hall fluorescent",Vector3.new(5.97,.07,2.10),
        CFrame.new(47,12.68,15.5),Color3.fromRGB(242,242,234),
        Enum.Material.Glass,false)
    hallLight.Transparency=.065
    local light=Instance.new("SurfaceLight")
    light.Face=Enum.NormalId.Bottom;light.Color=Color3.fromRGB(251,243,227)
    light.Brightness=.42;light.Range=15;light.Shadows=false;light.Parent=hallLight
    sign(root,"Staff entry sign","WELCOME  •  ABVM STAFF",Vector3.new(10,2.0,.20),CFrame.new(36.3,13.3,15.5)*CFrame.Angles(0,-math.pi/2,0),Color3.fromRGB(247,237,207),P.blue)
end

local function applyLighting(root: Instance)
    -- Centralized daytime profile. IMG_2903–2910 show a well-lit yellow
    -- elementary classroom, not a cool, underexposed exhibition space.
    -- GalleryPass must not override these values after the room is built.
    Lighting.ClockTime=10.25;Lighting.Brightness=1.62;Lighting.GlobalShadows=true;Lighting.ShadowSoftness=.67
    -- Soft is the current Roblox lighting-style API. Keep compatibility with
    -- engine versions where the enum is unavailable; no external assets.
    pcall(function() Lighting.LightingStyle=Enum.LightingStyle.Soft end)
    Lighting.Ambient=Color3.fromRGB(162,159,151)
    Lighting.OutdoorAmbient=Color3.fromRGB(183,185,177)
    Lighting.EnvironmentDiffuseScale=.72
    Lighting.EnvironmentSpecularScale=.25
    Lighting.ExposureCompensation=.04
    local atmosphere=Lighting:FindFirstChild("EmmaClassroomAtmosphere") or Instance.new("Atmosphere")
    atmosphere.Name="EmmaClassroomAtmosphere";atmosphere.Density=.008;atmosphere.Offset=.08;atmosphere.Color=Color3.fromRGB(221,230,235);atmosphere.Decay=Color3.fromRGB(188,192,185);atmosphere.Haze=.15;atmosphere.Glare=.05;atmosphere.Parent=Lighting
    local bloom=Lighting:FindFirstChild("EmmaClassroomBloom") or Instance.new("BloomEffect")
    bloom.Name="EmmaClassroomBloom";bloom.Intensity=.03;bloom.Size=20;bloom.Threshold=1.25;bloom.Parent=Lighting
    local grade=Lighting:FindFirstChild("EmmaClassroomGrade") or Instance.new("ColorCorrectionEffect")
    -- Daylight-neutral whites, a slight warm wall bounce, and mild contrast.
    -- No stylized bloom/neon treatment and no second calibration in Gallery.
    grade.Name="EmmaClassroomGrade"
    grade.Brightness=.01;grade.Contrast=.055;grade.Saturation=.015
    grade.TintColor=Color3.fromRGB(255,252,246);grade.Parent=Lighting
    local rays=Lighting:FindFirstChild("EmmaClassroomSunRays") or Instance.new("SunRaysEffect")
    rays.Name="EmmaClassroomSunRays";rays.Intensity=.025;rays.Spread=.8;rays.Parent=Lighting
end

function World.build()
    local old=Workspace:FindFirstChild("ABVMClassroomReplica");if old then old:Destroy() end
    local root=Instance.new("Folder");root.Name="ABVMClassroomReplica";root.Parent=Workspace
    root:SetAttribute("ArtDirection","EmmaRoomOriginalArtV9")
    applyLighting(root)

    -- Architectural shell.
    -- October 10 real-room photos and v78 native iPhone footage show that
    -- Roblox WoodPlanks exaggerates giant seams across the activity area.
    -- The actual classroom has tightly finished, dark varnished hardwood.
    -- Use the native fine-grain Wood material on the SAME one-piece floor:
    -- zero extra Parts, overlays, decals, seams or collision changes.
    local floor=part(root,"Warm oak classroom floor",Vector3.new(74,1,62),
        CFrame.new(0,0,-4),Color3.fromRGB(83,59,45),Enum.Material.Wood)
    -- Mild worn-varnish sheen, not a polished mirror. True native Roblox
    -- material/lighting confirmation must come from an iPhone screenshot.
    floor.Reflectance=.10

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
    -- The real ceiling has thin, PALE white-painted T-bars, not the dark
    -- high-contrast exposed-metal rails seen in iPhone v78. All ten grid
    -- strips retain their positions and are fully noncolliding.
    for _,x in ipairs({-24,-12,0,12,24}) do part(root,"Ceiling grid line",Vector3.new(.07,.07,61),CFrame.new(x,17.7,-4),Color3.fromRGB(226,226,218),Enum.Material.SmoothPlastic,false) end
    for _,z in ipairs({-28,-16,-4,8,20}) do part(root,"Ceiling grid cross",Vector3.new(73,.07,.07),CFrame.new(0,17.7,z),Color3.fromRGB(226,226,218),Enum.Material.SmoothPlastic,false) end
    -- Photo-grounded smooth white acoustic tiles: the prior Fabric shader
    -- rendered as a DARK heavily grooved ceiling in real iPhone footage,
    -- despite bright RGB constants and green headless render checks.
    -- SmoothPlastic on the existing 30 insets removes simulated cloth grooves.
    -- No extra geometry, replacement lights, or fake luminance overlays.
    -- Insets remain just below the host slab and above the T-bar grid.
    local tileShades={
        Color3.fromRGB(236,236,229),
        Color3.fromRGB(243,241,233),
        Color3.fromRGB(239,240,235),
        Color3.fromRGB(234,236,231),
    }
    for ix,x in ipairs({-30,-18,-6,6,18,30}) do
        for iz,z in ipairs({-28,-16,-4,8,20}) do
            local tile=part(root,"Acoustic ceiling inset tile",
                Vector3.new(11.72,.025,11.72),CFrame.new(x,17.735,z),
                tileShades[(ix+iz)%#tileShades+1],
                Enum.Material.SmoothPlastic,false)
            tile.CastShadow=false
        end
    end
    -- Preserve the navy finish without running wood THROUGH an open door.
    -- The original one-piece 61-stud right-hand rail was plainly suspended
    -- across the staff doorway at player eye height in the phone recording.
    part(root,"Blue baseboard",Vector3.new(.35,.72,61),
        CFrame.new(-36.35,.55,-4),P.blue,Enum.Material.Wood,false)
    for _,span in ipairs({{-13.5,42.5},{25,3.5}}) do
        part(root,"Blue baseboard",Vector3.new(.35,.72,span[2]),
            CFrame.new(36.35,.55,span[1]),P.blue,Enum.Material.Wood,false)
        part(root,"Blue chair rail right",Vector3.new(.35,.35,span[2]),
            CFrame.new(36.32,5.3,span[1]),P.blue,Enum.Material.Wood,false)
    end
    for _,z in ipairs({-34.35,26.35}) do part(root,"Blue baseboard",Vector3.new(73,.72,.35),CFrame.new(0,.55,z),P.blue,Enum.Material.Wood,false) end

    buildWindows(root)
    -- Photo references: the two windows do NOT share one 38-stud banner.
    -- Near z=-19, the wall says JESUS LOVES YOU S'MORE above the left window;
    -- near z=6, "I am a child of God. I make a difference!" is above the
    -- other window. Preserve both photograph-backed phrases as distinct
    -- low-relief indoor signs; no child's likeness, name or photo asset.
    local faithBanner=part(root,"Classroom faith window banner",
        Vector3.new(.12,1.08,17.5),CFrame.new(-36.33,15.22,6),
        Color3.fromRGB(247,236,216),Enum.Material.SmoothPlastic,false)
    surfaceText(faithBanner,"I AM A CHILD OF GOD. I MAKE A DIFFERENCE!",
        Enum.NormalId.Right,P.blue,faithBanner.Color,Enum.Font.GothamMedium)
    local smoreTop=part(root,"Smore faith headline",
        Vector3.new(.12,.48,11.1),CFrame.new(-36.30,16.21,-19),
        Color3.fromRGB(247,233,184),Enum.Material.SmoothPlastic,false)
    surfaceText(smoreTop,"JESUS LOVES YOU",Enum.NormalId.Right,
        Color3.fromRGB(120,60,50),smoreTop.Color,Enum.Font.GothamBold)
    local smoreTitle=part(root,"Smore classroom main title",
        Vector3.new(.14,.84,7.9),CFrame.new(-36.28,15.39,-19),
        Color3.fromRGB(227,190,115),Enum.Material.Wood,false)
    surfaceText(smoreTitle,"S'MORE",Enum.NormalId.Right,
        Color3.fromRGB(65,45,34),smoreTitle.Color,Enum.Font.GothamBold)
    -- Two understated camping trees, not generic holiday decorations.
    -- Tiny original wood/foliage shapes echo the photo's S'more sign.
    for _,z in ipairs({-25.75,-12.25}) do
        part(root,"Smore mural pine trunk",Vector3.new(.095,.65,.16),
            CFrame.new(-36.20,15.65,z),Color3.fromRGB(108,75,49),
            Enum.Material.Wood,false)
        for tier=0,1 do
            local canopy=part(root,"Smore mural green canopy",
                Vector3.new(.10,.39,.70-tier*.18),
                CFrame.new(-36.17,15.94+tier*.25,z),
                Color3.fromRGB(55+tier*14,112+tier*6,66),
                Enum.Material.Fabric,false)
            canopy.CastShadow=false
        end
    end
    buildFrontWall(root)
    buildRightWall(root)
    buildTeacherDesk(root)
    buildTeacherPlanningWall(root)
    buildBackDoorAndHall(root)
    buildTeacherEntry(root)
    buildClassroomTexture(root)
    buildReadingCorner(root)
    buildPhotoWindowWorkstation(root)

    -- Emma identified the purple chair where an adult is sitting beside the
    -- visible window AC and cabinets in her cheer photo. The prior candidate
    -- at z=+23 was the opposite reading corner, not this photographed corner.
    -- Move ONLY the unique chair to the AC-side workstation; its silhouette
    -- remains provisional because the occupied chair is hidden in the photo.
    -- Do not alter the 16 matching student desk chairs or the alphabet rug.
    schoolChair(root,"Purple corner chair",-32.45,-19.60,
        Color3.fromRGB(117,73,163))
    -- The conventional student chairs face the teaching wall (-Z). This
    -- unique chair belongs beside a window-side worktable at greater X.
    -- Rotate ONLY its already-constructed physical family around its own
    -- floor pivot so the seat faces the tabletop (+X) while its back rests
    -- toward the A/C wall. Do not rotate any student seat or cabinet.
    -- This orientation is a photo-guided owner-review candidate: the person
    -- in the original photo obscures the precise molded chair silhouette.
    local purplePivot=CFrame.new(-32.45,0,-19.60)
    local purpleTurn=purplePivot*CFrame.Angles(0,-math.pi/2,0)*
        CFrame.new(32.45,0,19.60)
    for _,object in ipairs(root:GetDescendants()) do
        if object:IsA("BasePart") and
            string.sub(object.Name,1,#"Purple corner chair")=="Purple corner chair" then
            object.CFrame=purpleTurn*object.CFrame
        end
    end

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
    -- Actual classroom photo: the analog white clock hangs on the broad
    -- yellow WALL PIER between the two navy-curtained windows, not over
    -- the front chalkboard. Reuse the existing FIVE Parts with no new clock
    -- assets or physical footprint. A Roblox Cylinder faces along local X;
    -- the window-side pier faces positive world X into the classroom.
    local clock=cylinder(root,"Classroom wall clock",
        Vector3.new(.25,3.2,3.2),CFrame.new(-36.38,11.60,-6.50),
        Color3.fromRGB(242,242,237),Enum.Material.SmoothPlastic,false)
    cylinder(root,"Clock rim",Vector3.new(.34,3.55,3.55),
        clock.CFrame,Color3.fromRGB(61,63,63),Enum.Material.Metal,false)
    cylinder(root,"Clock visible dial",Vector3.new(.08,3.17,3.17),
        clock.CFrame*CFrame.new(.22,0,0),
        Color3.fromRGB(242,242,237),Enum.Material.SmoothPlastic,false)
    -- Clock hands project toward +X and rotate in the Y/Z clock-face
    -- plane, rather than burying themselves in the wall or facing a window.
    part(root,"Clock minute hand",Vector3.new(.12,1.25,.12),
        CFrame.new(-36.05,11.92,-6.53)*CFrame.Angles(math.rad(-22),0,0),
        Color3.fromRGB(48,49,49),Enum.Material.Metal,false)
    part(root,"Clock hour hand",Vector3.new(.12,.85,.12),
        CFrame.new(-36.03,11.77,-6.72)*CFrame.Angles(math.rad(48),0,0),
        Color3.fromRGB(48,49,49),Enum.Material.Metal,false)

    -- The classroom photos show a portable silver fan by the teaching wall.
    -- A PHOTO-BASED equipment candidate, not proof of its normal-day resting
    -- location. Exactly fifteen original noncolliding Roblox solids.
    local fanX,fanZ=31.0,-31.40
    local silver=Color3.fromRGB(161,168,172)
    local foot=cylinder(root,"Photo portable fan weighted foot",
        Vector3.new(.16,1.65,1.65),
        CFrame.new(fanX,.62,fanZ)*CFrame.Angles(0,0,math.pi/2),
        Color3.fromRGB(112,117,121),Enum.Material.SmoothPlastic,false)
    foot.CastShadow=false
    part(root,"Photo portable fan upright",
        Vector3.new(.22,2.10,.22),CFrame.new(fanX,1.69,fanZ),
        Color3.fromRGB(122,127,130),Enum.Material.Metal,false)
    cylinder(root,"Photo portable fan neck collar",
        Vector3.new(.36,.42,.42),
        CFrame.new(fanX,2.67,fanZ)*CFrame.Angles(0,0,math.pi/2),
        silver,Enum.Material.Metal,false)
    -- A Cylinder's local-X normal faces -worldZ into the open room.
    local faceCF=CFrame.new(fanX,3.10,fanZ)*
        CFrame.Angles(0,math.pi/2,0)
    local back=cylinder(root,"Photo portable fan back guard",
        Vector3.new(.08,2.70,2.70),faceCF*CFrame.new(-.08,0,0),
        Color3.fromRGB(193,198,198),Enum.Material.SmoothPlastic,false)
    back.Transparency=.78
    back.CastShadow=false
    for i=0,2 do
        local blade=part(root,"Photo portable fan blade",
            Vector3.new(.06,1.13,.45),
            faceCF*CFrame.new(.09,0,0)*
                CFrame.Angles(i*2*math.pi/3,0,0)*CFrame.new(0,.52,0),
            Color3.fromRGB(177+i*6,188+i*3,190),
            Enum.Material.SmoothPlastic,false)
        blade.CastShadow=false
    end
    cylinder(root,"Photo portable fan center hub",
        Vector3.new(.15,.48,.48),faceCF*CFrame.new(.20,0,0),
        Color3.fromRGB(115,123,125),Enum.Material.Metal,false)
    for i=0,5 do
        local spoke=part(root,"Photo portable fan safety grille spoke",
            Vector3.new(.046,2.58,.052),
            faceCF*CFrame.new(.30,0,0)*
                CFrame.Angles(math.rad(i*30),0,0),
            silver,Enum.Material.Metal,false)
        spoke.CastShadow=false
    end
    local front=cylinder(root,"Photo portable fan translucent face",
        Vector3.new(.025,2.80,2.80),faceCF*CFrame.new(.29,0,0),
        Color3.fromRGB(213,215,213),Enum.Material.SmoothPlastic,false)
    front.Transparency=.96
    front.CastShadow=false

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
