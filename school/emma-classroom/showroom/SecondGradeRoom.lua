--!strict
-- Photo-guided ABVM second-grade classroom across the hall from the existing
-- first-grade room. The supplied photographs remain private local references;
-- this module reconstructs only their architecture, furniture and decor.

local SecondGradeRoom={}

local WALL=Color3.fromRGB(238,224,132)
local WALL_SHADOW=Color3.fromRGB(221,205,116)
local OAK=Color3.fromRGB(105,70,45)
local DARK_OAK=Color3.fromRGB(72,46,31)
local FLOOR=Color3.fromRGB(62,43,34)
local BOARD=Color3.fromRGB(35,40,37)
local STEEL=Color3.fromRGB(92,95,91)
local BURGUNDY=Color3.fromRGB(91,42,50)
local LAMINATE=Color3.fromRGB(177,133,87)
local CREAM=Color3.fromRGB(239,235,214)
local BRICK=Color3.fromRGB(192,132,63)

local function makePart(parent:Instance,name:string,size:Vector3,cf:CFrame,
    color:Color3,material:Enum.Material?,collide:boolean?):Part
    local p=Instance.new("Part")
    p.Name="Second grade "..name
    p.Size=size
    p.CFrame=cf
    p.Color=color
    p.Material=material or Enum.Material.SmoothPlastic
    p.Anchored=true
    p.CanCollide=collide~=false
    p.CanTouch=p.CanCollide
    p.CanQuery=true
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p:SetAttribute("Classroom","Second Grade")
    p.Parent=parent
    return p
end

local function addText(target:BasePart,text:string,face:Enum.NormalId,
    fg:Color3,bg:Color3,font:Enum.Font?):TextLabel
    local gui=Instance.new("SurfaceGui")
    gui.Name="SecondGradePhotoText"
    gui.Face=face
    gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
    gui.CanvasSize=Vector2.new(900,240)
    gui.LightInfluence=.15
    gui.Parent=target
    local label=Instance.new("TextLabel")
    label.Name="Reference lettering"
    label.Size=UDim2.fromScale(1,1)
    label.BackgroundColor3=bg
    label.BackgroundTransparency=0
    label.BorderSizePixel=0
    label.Text=text
    label.TextColor3=fg
    label.Font=font or Enum.Font.GothamBold
    label.TextScaled=true
    label.TextWrapped=true
    label.Parent=gui
    local pad=Instance.new("UIPadding")
    pad.PaddingLeft=UDim.new(.025,0)
    pad.PaddingRight=UDim.new(.025,0)
    pad.PaddingTop=UDim.new(.08,0)
    pad.PaddingBottom=UDim.new(.08,0)
    pad.Parent=label
    return label
end

local function addPolkaArtwork(rug:BasePart)
    local gui=Instance.new("SurfaceGui")
    gui.Name="SecondGradePolkaDotRugArt"
    gui.Face=Enum.NormalId.Top
    gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
    gui.CanvasSize=Vector2.new(640,480)
    gui.LightInfluence=.25
    gui.Parent=rug
    local colors={
        Color3.fromRGB(223,75,72),Color3.fromRGB(244,192,65),
        Color3.fromRGB(58,154,190),Color3.fromRGB(91,177,123),
        Color3.fromRGB(178,100,172),Color3.fromRGB(226,128,75),
    }
    local points={
        {.10,.14},{.30,.13},{.52,.14},{.74,.13},{.90,.15},
        {.18,.36},{.40,.35},{.63,.37},{.84,.35},
        {.09,.59},{.29,.61},{.51,.58},{.72,.61},{.91,.58},
        {.18,.82},{.40,.81},{.63,.83},{.84,.80},
    }
    for i,point in ipairs(points) do
        local dot=Instance.new("Frame")
        dot.Name="Polka dot"
        dot.AnchorPoint=Vector2.new(.5,.5)
        dot.Position=UDim2.fromScale(point[1],point[2])
        dot.Size=UDim2.fromScale(.085,.115)
        dot.BackgroundColor3=colors[(i-1)%#colors+1]
        dot.BorderSizePixel=0
        dot.Parent=gui
        local corner=Instance.new("UICorner")
        corner.CornerRadius=UDim.new(1,0)
        corner.Parent=dot
    end
end

local function addAlphabetStrip(carrier:BasePart)
    local gui=Instance.new("SurfaceGui")
    gui.Name="SecondGradeAlphabetStrip"
    gui.Face=Enum.NormalId.Left
    gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
    gui.CanvasSize=Vector2.new(1560,140)
    gui.LightInfluence=.1
    gui.Parent=carrier
    local row=Instance.new("Frame")
    row.Size=UDim2.fromScale(1,1)
    row.BackgroundColor3=Color3.fromRGB(223,225,211)
    row.BorderSizePixel=0
    row.Parent=gui
    local layout=Instance.new("UIListLayout")
    layout.FillDirection=Enum.FillDirection.Horizontal
    layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    layout.VerticalAlignment=Enum.VerticalAlignment.Center
    layout.Padding=UDim.new(.002,0)
    layout.Parent=row
    for code=65,90 do
        local card=Instance.new("TextLabel")
        card.Name="Alphabet card"
        card.Size=UDim2.fromScale(1/27.2,.88)
        card.BackgroundColor3=(code%2==0) and Color3.fromRGB(239,225,210)
            or Color3.fromRGB(218,232,222)
        card.BorderColor3=Color3.fromRGB(121,91,67)
        card.BorderSizePixel=2
        local upper=string.char(code)
        card.Text=upper..string.lower(upper)
        card.TextColor3=Color3.fromRGB(55,69,78)
        card.Font=Enum.Font.GothamBold
        card.TextScaled=true
        card.Parent=row
    end
end

local function buildDeskSet(parent:Instance,index:number,x:number,z:number)
    local set=Instance.new("Folder")
    set.Name=string.format("Second grade student desk %02d",index)
    set:SetAttribute("Classroom","Second Grade")
    set:SetAttribute("StudentSeatIndex",index)
    set.Parent=parent
    local prefix=string.format("desk %02d ",index)
    local top=makePart(set,prefix.."laminate top",Vector3.new(3.75,.22,5.55),
        CFrame.new(x,3.05,z),LAMINATE,Enum.Material.Wood,true)
    top.Reflectance=.035
    makePart(set,prefix.."dark edge",Vector3.new(3.85,.13,5.65),
        CFrame.new(x,2.91,z),Color3.fromRGB(61,61,57),Enum.Material.Metal,false)
    makePart(set,prefix.."wire book tray",Vector3.new(2.55,.15,4.35),
        CFrame.new(x-.15,2.15,z),STEEL,Enum.Material.Metal,false)
    for _,dx in ipairs({-1.42,1.42}) do
        for _,dz in ipairs({-2.20,2.20}) do
            makePart(set,prefix.."tubular leg",Vector3.new(.16,2.55,.16),
                CFrame.new(x+dx,1.62,z+dz),STEEL,Enum.Material.Metal,false)
        end
    end
    local chairX=x-3.05
    makePart(set,prefix.."burgundy chair seat",Vector3.new(2.45,.34,3.35),
        CFrame.new(chairX,1.82,z),BURGUNDY,Enum.Material.SmoothPlastic,true)
    makePart(set,prefix.."burgundy chair back",Vector3.new(.30,3.05,3.45),
        CFrame.new(chairX-1.06,3.15,z)*CFrame.Angles(0,0,math.rad(-7)),
        BURGUNDY,Enum.Material.SmoothPlastic,false)
    for _,dz in ipairs({-1.34,1.34}) do
        makePart(set,prefix.."chair runner",Vector3.new(2.55,.16,.16),
            CFrame.new(chairX-.08,.58,z+dz),STEEL,Enum.Material.Metal,false)
        makePart(set,prefix.."chair rear leg",Vector3.new(.16,2.55,.16),
            CFrame.new(chairX-1.02,1.36,z+dz),STEEL,Enum.Material.Metal,false)
    end
    local plate=makePart(set,prefix.."blue-white nameplate",Vector3.new(.14,.48,3.35),
        CFrame.new(x+1.45,3.36,z),Color3.fromRGB(234,239,230),
        Enum.Material.SmoothPlastic,false)
    addText(plate,"STUDENT  "..tostring(index),Enum.NormalId.Left,
        Color3.fromRGB(35,91,137),plate.Color,Enum.Font.GothamBold)
    local workbook=makePart(set,prefix.."open workbook",Vector3.new(1.65,.07,2.75),
        CFrame.new(x-.30,3.205,z+.45),Color3.fromRGB(244,241,222),
        Enum.Material.SmoothPlastic,false)
    workbook.CanQuery=false
    local tray=makePart(set,prefix.."blue pencil tray",Vector3.new(2.35,.13,.72),
        CFrame.new(x-.25,3.19,z-1.80),Color3.fromRGB(49,116,169),
        Enum.Material.SmoothPlastic,false)
    tray.CanQuery=false
    local pencil=makePart(set,prefix.."yellow pencil",Vector3.new(.08,.08,2.10),
        CFrame.new(x-.15,3.30,z-1.80)*CFrame.Angles(0,math.rad(4),0),
        Color3.fromRGB(239,188,57),Enum.Material.SmoothPlastic,false)
    pencil.CanQuery=false
end

local function buildWindows(room:Folder)
    for _,centerX in ipairs({79,109}) do
        local glass=makePart(room,"window glass",Vector3.new(23.5,10,.13),
            CFrame.new(centerX,9.25,-18.05),Color3.fromRGB(167,210,223),
            Enum.Material.Glass,false)
        glass.Transparency=.28
        glass.Reflectance=.035
        glass.CastShadow=false
        for _,dx in ipairs({-11.75,-3.92,3.92,11.75}) do
            makePart(room,"window vertical mullion",Vector3.new(.28,10.35,.28),
                CFrame.new(centerX+dx,9.25,-17.92),OAK,Enum.Material.Wood,false)
        end
        for _,y in ipairs({4.10,9.25,14.40}) do
            makePart(room,"window horizontal sash",Vector3.new(23.8,.28,.28),
                CFrame.new(centerX,y,-17.92),OAK,Enum.Material.Wood,false)
        end
        for blind=0,5 do
            local bx=centerX-9.75+blind*3.9
            local slat=makePart(room,"cream vertical blind",Vector3.new(3.25,10.05,.045),
                CFrame.new(bx,9.25,-17.68)*CFrame.Angles(0,math.rad((blind%2==0) and 4 or -4),0),
                Color3.fromRGB(222,216,193),Enum.Material.Fabric,false)
            slat.Transparency=.12
            slat.CastShadow=false
        end
        makePart(room,"window radiator body",Vector3.new(18.5,2.15,.65),
            CFrame.new(centerX,1.65,-16.85),Color3.fromRGB(93,103,105),
            Enum.Material.Metal,false)
        for fin=-7,7,2 do
            makePart(room,"window radiator fin",Vector3.new(.24,2.40,.82),
                CFrame.new(centerX+fin,1.72,-16.65),Color3.fromRGB(109,117,118),
                Enum.Material.Metal,false)
        end
    end
end

local function buildTeachingWall(room:Folder)
    local board=makePart(room,"full chalkboard wall",Vector3.new(.28,8.45,55),
        CFrame.new(127.82,9.25,15.5),BOARD,Enum.Material.Slate,false)
    board.Reflectance=.02
    makePart(room,"chalkboard oak top rail",Vector3.new(.42,.36,55.4),
        CFrame.new(127.62,13.50,15.5),OAK,Enum.Material.Wood,false)
    makePart(room,"chalkboard chalk tray",Vector3.new(.65,.32,55.4),
        CFrame.new(127.48,5.05,15.5),OAK,Enum.Material.Wood,false)
    local smart=makePart(room,"interactive Smartboard",Vector3.new(.48,7.65,15.2),
        CFrame.new(127.25,9.15,15.5),Color3.fromRGB(22,26,28),
        Enum.Material.SmoothPlastic,false)
    smart.Reflectance=.09
    addText(smart,"SECOND GRADE\nREADY TO LEARN",Enum.NormalId.Left,
        Color3.fromRGB(228,233,225),smart.Color,Enum.Font.GothamBold)
    for _,z in ipairs({9.25,21.75}) do
        makePart(room,"Smartboard rolling stand",Vector3.new(.62,5.6,.34),
            CFrame.new(126.55,3.02,z),Color3.fromRGB(43,46,47),Enum.Material.Metal,false)
        makePart(room,"Smartboard rolling foot",Vector3.new(2.15,.24,.48),
            CFrame.new(125.95,.72,z),Color3.fromRGB(43,46,47),Enum.Material.Metal,false)
    end
    local alphabet=makePart(room,"alphabet strip carrier",Vector3.new(.16,1.48,55.5),
        CFrame.new(127.42,14.55,15.5),CREAM,Enum.Material.SmoothPlastic,false)
    addAlphabetStrip(alphabet)
    local scriptStrip=makePart(room,"cursive alphabet banner",Vector3.new(.15,1.05,44),
        CFrame.new(127.40,16.08,15.5),Color3.fromRGB(43,74,87),
        Enum.Material.SmoothPlastic,false)
    addText(scriptStrip,"Aa  Bb  Cc  Dd  Ee  Ff  Gg  Hh  Ii  Jj  Kk  Ll  Mm  Nn  Oo  Pp  Qq  Rr  Ss  Tt  Uu  Vv  Ww  Xx  Yy  Zz",
        Enum.NormalId.Left,Color3.fromRGB(242,238,210),scriptStrip.Color,Enum.Font.Arial)
    local amazing=makePart(room,"amazing things lettering carrier",Vector3.new(.14,1.35,18),
        CFrame.new(127.40,16.72,-3.5),WALL,Enum.Material.SmoothPlastic,false)
    addText(amazing,"AMAZING THINGS HAPPEN HERE",Enum.NormalId.Left,
        Color3.fromRGB(231,231,218),WALL,Enum.Font.GothamBold)
    makePart(room,"front crucifix vertical",Vector3.new(.35,3.05,.35),
        CFrame.new(127.25,16.30,15.5),DARK_OAK,Enum.Material.Wood,false)
    makePart(room,"front crucifix horizontal",Vector3.new(.35,.35,2.05),
        CFrame.new(127.20,16.72,15.5),DARK_OAK,Enum.Material.Wood,false)
end

local function buildCoatWall(room:Folder)
    makePart(room,"built-in coat wall",Vector3.new(66.8,7.35,.55),
        CFrame.new(94.1,4.05,48.70),Color3.fromRGB(103,67,45),Enum.Material.Wood,false)
    makePart(room,"coat wall upper rail",Vector3.new(66.8,.42,.78),
        CFrame.new(94.1,7.60,48.45),DARK_OAK,Enum.Material.Wood,false)
    for x=64,124,6 do
        makePart(room,"coat cubby stile",Vector3.new(.20,6.5,.76),
            CFrame.new(x,4.05,48.38),DARK_OAK,Enum.Material.Wood,false)
        makePart(room,"coat hook",Vector3.new(.20,.20,.72),
            CFrame.new(x,5.75,47.85),Color3.fromRGB(180,153,91),Enum.Material.Metal,false)
    end
    for _,y in ipairs({2.0,4.2,6.4}) do
        makePart(room,"coat wall shelf rail",Vector3.new(66,.20,.70),
            CFrame.new(94.1,y,48.36),DARK_OAK,Enum.Material.Wood,false)
    end
    local work=makePart(room,"coat wall student work carrier",Vector3.new(38,3.0,.12),
        CFrame.new(96,10.15,48.30),Color3.fromRGB(228,222,198),
        Enum.Material.SmoothPlastic,false)
    local label=addText(work,"OUR SECOND GRADE WORK  •  READ  •  WRITE  •  GROW",
        Enum.NormalId.Back,Color3.fromRGB(85,52,39),work.Color,Enum.Font.GothamBold)
    label.TextWrapped=true
    local numberLine=makePart(room,"number line",Vector3.new(60,1.0,.12),
        CFrame.new(96,13.25,48.26),CREAM,Enum.Material.SmoothPlastic,false)
    addText(numberLine,"1  2  3  4  5  6  7  8  9  10  20  30  40  50  60  70  80  90  100",
        Enum.NormalId.Back,Color3.fromRGB(63,104,104),CREAM,Enum.Font.GothamBold)
end

local function buildTeacherArea(room:Folder)
    -- L-shaped, paper-filled teacher station beside the windows.
    makePart(room,"teacher desk main top",Vector3.new(9.8,.35,5.2),
        CFrame.new(70.2,3.25,-9.6),Color3.fromRGB(126,82,53),Enum.Material.Wood,true)
    makePart(room,"teacher desk return top",Vector3.new(5.0,.35,6.4),
        CFrame.new(65.9,3.25,-5.2),Color3.fromRGB(126,82,53),Enum.Material.Wood,true)
    for _,x in ipairs({66.1,74.3}) do
        makePart(room,"teacher desk pedestal",Vector3.new(1.8,3.0,4.6),
            CFrame.new(x,1.70,-9.6),Color3.fromRGB(86,83,77),Enum.Material.Metal,true)
    end
    local monitor=makePart(room,"teacher computer monitor",Vector3.new(.35,3.2,5.4),
        CFrame.new(71.3,5.20,-9.2)*CFrame.Angles(0,math.rad(8),0),
        Color3.fromRGB(35,40,43),Enum.Material.SmoothPlastic,false)
    addText(monitor,"CLASSROOM DESKTOP",Enum.NormalId.Right,
        Color3.fromRGB(173,205,215),monitor.Color,Enum.Font.GothamMedium)
    makePart(room,"teacher monitor stand",Vector3.new(1.4,.25,1.4),
        CFrame.new(70.7,3.55,-9.2),Color3.fromRGB(48,50,51),Enum.Material.Metal,false)
    for i=0,5 do
        local paper=makePart(room,"teacher paper stack",Vector3.new(1.55,.10,2.15),
            CFrame.new(67.2+i*.72,3.50+i*.025,-11.0+i*.22)*
                CFrame.Angles(0,math.rad((i%3-1)*5),0),
            (i%2==0) and Color3.fromRGB(241,236,217) or Color3.fromRGB(225,102,112),
            Enum.Material.SmoothPlastic,false)
        paper.CanQuery=false
    end
    local cup=makePart(room,"teacher pencil cup",Vector3.new(.85,1.2,.85),
        CFrame.new(73.5,4.0,-7.8),Color3.fromRGB(160,68,77),
        Enum.Material.SmoothPlastic,false)
    for i=0,5 do
        makePart(room,"teacher colored pencil",Vector3.new(.08,1.65,.08),
            cup.CFrame*CFrame.new(0,.78,0)*CFrame.Angles(math.rad((i-2)*4),0,math.rad((i%3-1)*6)),
            ({Color3.fromRGB(231,86,71),Color3.fromRGB(75,137,191),Color3.fromRGB(242,180,62)})[i%3+1],
            Enum.Material.SmoothPlastic,false)
    end
    makePart(room,"teacher tissue box",Vector3.new(1.65,.78,1.35),
        CFrame.new(68.3,3.82,-7.7),Color3.fromRGB(112,172,183),
        Enum.Material.SmoothPlastic,false)
    local tissue=makePart(room,"teacher raised tissue",Vector3.new(.06,.82,.72),
        CFrame.new(68.3,4.55,-7.7)*CFrame.Angles(math.rad(8),0,math.rad(-12)),
        Color3.fromRGB(245,242,225),Enum.Material.Fabric,false)
    tissue.CanQuery=false
    for i=0,4 do
        local book=makePart(room,"teacher planning book",Vector3.new(1.55,.18,2.65),
            CFrame.new(66.4,3.52+i*.19,-10.7),
            ({Color3.fromRGB(55,123,95),Color3.fromRGB(205,83,83),
                Color3.fromRGB(65,108,164)})[i%3+1],Enum.Material.SmoothPlastic,false)
        book.CanQuery=false
    end
    local vase=makePart(room,"teacher flower vase",Vector3.new(.72,1.15,.72),
        CFrame.new(73.3,4.00,-11.1),Color3.fromRGB(230,224,196),
        Enum.Material.SmoothPlastic,false)
    for i=0,4 do
        makePart(room,"teacher flower stem",Vector3.new(.07,1.55,.07),
            vase.CFrame*CFrame.new(0,1.15,0)*
                CFrame.Angles(math.rad((i-2)*6),0,math.rad((i%3-1)*8)),
            Color3.fromRGB(71,119,67),Enum.Material.SmoothPlastic,false)
        local bloom=makePart(room,"teacher sunflower",Vector3.new(.45,.45,.20),
            CFrame.new(73.3+(i-2)*.18,5.35+(i%2)*.20,-11.1),
            Color3.fromRGB(232,176,44),Enum.Material.SmoothPlastic,false)
        bloom.Shape=Enum.PartType.Ball
    end
    -- Purple wood chair visible beside the teacher station.
    makePart(room,"teacher purple chair seat",Vector3.new(3.7,.42,3.9),
        CFrame.new(66.5,2.05,-13.6),Color3.fromRGB(105,64,141),Enum.Material.Wood,true)
    makePart(room,"teacher purple chair back",Vector3.new(.38,4.7,3.9),
        CFrame.new(65.0,4.0,-13.6),Color3.fromRGB(105,64,141),Enum.Material.Wood,false)
    for _,dz in ipairs({-1.55,1.55}) do
        makePart(room,"teacher purple chair leg",Vector3.new(.32,3.3,.32),
            CFrame.new(65.3,1.65,-13.6+dz),Color3.fromRGB(82,45,111),Enum.Material.Wood,false)
    end
end

local function buildActivityCorner(room:Folder)
    local banner=makePart(room,"reading wave banner",Vector3.new(.16,7.3,22),
        CFrame.new(60.18,10.15,37.0),Color3.fromRGB(227,235,221),
        Enum.Material.SmoothPlastic,false)
    addText(banner,"CATCH THE\nREADING WAVE",Enum.NormalId.Right,
        Color3.fromRGB(45,117,142),banner.Color,Enum.Font.GothamBold)
    local halloween=makePart(room,"seasonal classroom banner",Vector3.new(.16,1.4,18),
        CFrame.new(60.16,15.7,34.5),WALL,Enum.Material.SmoothPlastic,false)
    addText(halloween,"HAPPY HALLOWEEN",Enum.NormalId.Right,
        Color3.fromRGB(92,61,47),WALL,Enum.Font.GothamBold)
    local top=makePart(room,"round activity table",Vector3.new(.42,8.0,8.0),
        CFrame.new(68.5,3.05,38.8)*CFrame.Angles(0,0,math.pi/2),
        Color3.fromRGB(232,227,204),Enum.Material.SmoothPlastic,true)
    top.Shape=Enum.PartType.Cylinder
    makePart(room,"round activity table pedestal",Vector3.new(.75,2.65,.75),
        CFrame.new(68.5,1.55,38.8),STEEL,Enum.Material.Metal,true)
    for i,color in ipairs({
        Color3.fromRGB(230,78,82),Color3.fromRGB(244,191,65),
        Color3.fromRGB(67,153,183),Color3.fromRGB(88,171,113),
    }) do
        local angle=(i-1)*math.pi/2
        local cx=68.5+math.cos(angle)*5.6
        local cz=38.8+math.sin(angle)*5.6
        makePart(room,"activity chair seat",Vector3.new(2.5,.32,2.7),
            CFrame.new(cx,1.75,cz),BURGUNDY,Enum.Material.SmoothPlastic,true)
        makePart(room,"activity table color mat",Vector3.new(.06,3.0,3.0),
            CFrame.new(68.5,3.29,38.8)*CFrame.Angles(0,0,math.pi/2)*
                CFrame.Angles(angle,0,0)*CFrame.new(0,2.0,0),
            color,Enum.Material.SmoothPlastic,false)
    end
    -- Rolling whiteboard between the two window banks.
    local whiteboard=makePart(room,"rolling whiteboard",Vector3.new(7.8,6.4,.30),
        CFrame.new(94,7.1,-15.7),Color3.fromRGB(239,240,231),
        Enum.Material.SmoothPlastic,false)
    addText(whiteboard,"TODAY\nRead • Think • Share",Enum.NormalId.Back,
        Color3.fromRGB(73,89,92),whiteboard.Color,Enum.Font.GothamMedium)
    for _,dx in ipairs({-3.2,3.2}) do
        makePart(room,"whiteboard rolling leg",Vector3.new(.20,3.7,.20),
            CFrame.new(94+dx,2.25,-15.7),STEEL,Enum.Material.Metal,false)
        makePart(room,"whiteboard wheel foot",Vector3.new(1.1,.20,.35),
            CFrame.new(94+dx,.62,-15.7),STEEL,Enum.Material.Metal,false)
    end
end

local function buildHallDoor(root:Instance,room:Folder)
    local oldWall=root:FindFirstChild("Staff entry outer east wall")
    local oldBrick=root:FindFirstChild("Staff entry east wall glazed brick")
    assert(oldWall and oldWall:IsA("BasePart"),"Second-grade entry requires the photographed vestibule wall")
    assert(oldBrick and oldBrick:IsA("BasePart"),"Second-grade entry requires the vestibule brick skin")
    oldWall:Destroy()
    oldBrick:Destroy()
    -- The doorway is centered directly opposite the existing first-grade
    -- staff door. Structural and brick pieces are split around a true opening.
    for _,segment in ipairs({
        {z=7.775,length=7.05},
        {z=23.50,length=7.60},
    }) do
        makePart(room,"hall-facing entry wall",Vector3.new(1,13,segment.length),
            CFrame.new(59.60,6.5,segment.z),BRICK,Enum.Material.Brick,true)
        local skin=makePart(room,"hall-facing glazed brick",Vector3.new(.12,12.7,segment.length-.15),
            CFrame.new(59.02,6.35,segment.z),BRICK,Enum.Material.Brick,false)
        skin.Reflectance=.035
    end
    makePart(room,"hall-facing door header wall",Vector3.new(1,2.0,8.30),
        CFrame.new(59.60,12.0,15.5),BRICK,Enum.Material.Brick,true)
    local headerSkin=makePart(room,"hall-facing door header glazed brick",Vector3.new(.12,1.9,8.15),
        CFrame.new(59.02,12.0,15.5),BRICK,Enum.Material.Brick,false)
    headerSkin.Reflectance=.035
    for _,z in ipairs({11.25,19.75}) do
        makePart(room,"entry oak jamb",Vector3.new(1.25,11.1,.65),
            CFrame.new(59.58,5.55,z),OAK,Enum.Material.Wood,false)
    end
    makePart(room,"entry oak lintel",Vector3.new(1.25,.70,9.15),
        CFrame.new(59.58,10.82,15.5),OAK,Enum.Material.Wood,false)
    makePart(room,"entry brass threshold",Vector3.new(1.35,.06,8.35),
        CFrame.new(59.70,.56,15.5),Color3.fromRGB(174,146,84),Enum.Material.Metal,false)
    -- Open inward against the north-side wall: lower oak panel and genuine
    -- upper glass aperture remain clear of the walking route.
    local leafCF=CFrame.new(63.00,5.25,19.35)
    makePart(room,"open classroom door lower panel",Vector3.new(6.75,4.2,.42),
        leafCF*CFrame.new(0,-2.75,0),Color3.fromRGB(120,81,52),Enum.Material.Wood,false)
    local glass=makePart(room,"open classroom door glass",Vector3.new(4.75,4.35,.12),
        leafCF*CFrame.new(0,1.55,-.18),Color3.fromRGB(194,214,216),Enum.Material.Glass,false)
    glass.Transparency=.30
    glass.CastShadow=false
    for _,x in ipairs({-2.88,2.88}) do
        makePart(room,"open classroom door stile",Vector3.new(.95,4.4,.45),
            leafCF*CFrame.new(x,1.55,0),OAK,Enum.Material.Wood,false)
    end
    makePart(room,"open classroom door middle rail",Vector3.new(6.75,.35,.46),
        leafCF*CFrame.new(0,-.65,0),OAK,Enum.Material.Wood,false)
    makePart(room,"open classroom door pull",Vector3.new(.22,.85,.22),
        leafCF*CFrame.new(-2.65,-1.2,-.35),Color3.fromRGB(183,151,84),Enum.Material.Metal,false)
end

function SecondGradeRoom.build(root:Instance):Folder
    local room=Instance.new("Folder")
    room.Name="SecondGradeClassroom"
    room:SetAttribute("Grade",2)
    room:SetAttribute("Reference","Owner-supplied burgundy-chair polka-rug classroom photographs")
    room:SetAttribute("Placement","Directly across hall from existing first-grade doorway")
    room:SetAttribute("ReferenceImagesEmbedded",false)
    room.Parent=root

    buildHallDoor(root,room)

    local floor=makePart(room,"dark varnished hardwood floor",Vector3.new(69,1,68),
        CFrame.new(94.1,0,15.5),FLOOR,Enum.Material.Wood,true)
    floor.Reflectance=.14
    -- East/front teaching wall and north built-in storage wall.
    makePart(room,"front wall",Vector3.new(1,18,68),CFrame.new(128.6,9,15.5),WALL,Enum.Material.SmoothPlastic,true)
    makePart(room,"coat wall structure",Vector3.new(69,18,1),CFrame.new(94.1,9,49.5),WALL,Enum.Material.SmoothPlastic,true)
    -- West wall continues beyond the photographed vestibule; the middle is
    -- provided by buildHallDoor's split brick opening.
    makePart(room,"west wall south",Vector3.new(1,18,22.75),CFrame.new(59.6,9,-7.125),WALL_SHADOW,Enum.Material.SmoothPlastic,true)
    makePart(room,"west wall north",Vector3.new(1,18,22.20),CFrame.new(59.6,9,38.40),WALL_SHADOW,Enum.Material.SmoothPlastic,true)
    -- South/window wall split into low/high bands and three structural piers.
    makePart(room,"window wall lower",Vector3.new(69,4,1),CFrame.new(94.1,2,-18.5),WALL,Enum.Material.SmoothPlastic,true)
    makePart(room,"window wall upper",Vector3.new(69,4,1),CFrame.new(94.1,16,-18.5),WALL,Enum.Material.SmoothPlastic,true)
    for _,pier in ipairs({{63.35,7.5},{94,6.0},{124.85,7.5}}) do
        makePart(room,"window wall pier",Vector3.new(pier[2],10,1),
            CFrame.new(pier[1],9,-18.5),WALL,Enum.Material.SmoothPlastic,true)
    end
    makePart(room,"acoustic ceiling",Vector3.new(69,.45,68),
        CFrame.new(94.1,18,15.5),Color3.fromRGB(237,237,231),
        Enum.Material.SmoothPlastic,false)
    for x=64,124,12 do
        makePart(room,"ceiling grid line",Vector3.new(.07,.07,67.2),
            CFrame.new(x,17.72,15.5),Color3.fromRGB(213,214,209),
            Enum.Material.SmoothPlastic,false)
    end
    for z=-14,46,12 do
        makePart(room,"ceiling grid cross",Vector3.new(68.2,.07,.07),
            CFrame.new(94.1,17.71,z),Color3.fromRGB(213,214,209),
            Enum.Material.SmoothPlastic,false)
    end
    for _,x in ipairs({76,94,112}) do
        for _,z in ipairs({-8,16,40}) do
            local lightPart=makePart(room,"fluorescent diffuser",Vector3.new(5.8,.10,2.0),
                CFrame.new(x,17.52,z),Color3.fromRGB(246,245,232),Enum.Material.Glass,false)
            lightPart.Transparency=.08
            lightPart.CastShadow=false
            local light=Instance.new("SurfaceLight")
            light.Face=Enum.NormalId.Bottom
            light.Color=Color3.fromRGB(250,244,222)
            light.Brightness=.34
            light.Range=14
            light.Shadows=false
            light.Parent=lightPart
        end
    end
    -- Dark wood trim matches the photographed varnished floor and built-ins.
    makePart(room,"front baseboard",Vector3.new(.35,.75,67),CFrame.new(128.0,.58,15.5),DARK_OAK,Enum.Material.Wood,false)
    makePart(room,"coat wall baseboard",Vector3.new(68,.75,.35),CFrame.new(94.1,.58,48.95),DARK_OAK,Enum.Material.Wood,false)
    makePart(room,"window wall baseboard",Vector3.new(68,.75,.35),CFrame.new(94.1,.58,-17.95),DARK_OAK,Enum.Material.Wood,false)

    buildWindows(room)
    buildTeachingWall(room)
    buildCoatWall(room)
    buildTeacherArea(room)
    buildActivityCorner(room)

    local rug=makePart(room,"black multicolor polka-dot rug",Vector3.new(15.5,.10,13.0),
        CFrame.new(112.0,.56,-11.1),Color3.fromRGB(28,29,31),Enum.Material.Fabric,false)
    addPolkaArtwork(rug)

    local index=0
    for _,x in ipairs({82,93,104,115}) do
        for _,z in ipairs({-1.5,8.5,18.5,28.5,38.5}) do
            index+=1
            buildDeskSet(room,index,x,z)
        end
    end
    assert(index==20,"Second grade requires twenty complete student stations")

    -- Tall cabinet and low bookcases visible along the back/teacher corners.
    makePart(room,"tall classroom cabinet",Vector3.new(5.4,11.5,5.2),
        CFrame.new(63.1,6.25,44.8),Color3.fromRGB(67,58,55),Enum.Material.Wood,true)
    for _,y in ipairs({2.3,5.1,7.9}) do
        makePart(room,"tall cabinet drawer line",Vector3.new(.12,.15,4.45),
            CFrame.new(65.84,y,44.8),Color3.fromRGB(178,126,78),Enum.Material.Metal,false)
    end
    for _,x in ipairs({78,86,102,110}) do
        makePart(room,"window bookcase",Vector3.new(7.0,4.0,2.6),
            CFrame.new(x,2.5,-15.9),Color3.fromRGB(93,68,50),Enum.Material.Wood,true)
        for shelf=0,2 do
            makePart(room,"window bookcase shelf",Vector3.new(6.5,.16,2.45),
                CFrame.new(x,1.0+shelf*1.25,-15.7),Color3.fromRGB(72,49,37),Enum.Material.Wood,false)
        end
        for bin=0,1 do
            makePart(room,"window bookcase bright bin",Vector3.new(2.55,1.05,2.10),
                CFrame.new(x+(bin==0 and -1.65 or 1.65),3.55,-15.55),
                (bin==0) and Color3.fromRGB(79,145,169)
                    or Color3.fromRGB(166,88,134),
                Enum.Material.SmoothPlastic,false)
        end
    end

    room:SetAttribute("StudentDeskCount",20)
    room:SetAttribute("HasPolkaDotRug",true)
    room:SetAttribute("HasDualWindowBanks",true)
    room:SetAttribute("HasBlackboardSmartboardWall",true)
    room:SetAttribute("HasAcrossHallWalkableEntry",true)
    return room
end

return SecondGradeRoom
