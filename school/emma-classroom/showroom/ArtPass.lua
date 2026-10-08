--!strict
-- Original room art built from authored geometry; no Toolbox scripts, no private data.
-- Showroom copy intentionally isolated from the archived study-game source.
local ArtPass = {}
local C = {
    navy=Color3.fromRGB(49,73,103),blue=Color3.fromRGB(97,147,179),
    mint=Color3.fromRGB(117,178,157),leaf=Color3.fromRGB(80,127,104),
    cream=Color3.fromRGB(252,247,229),wood=Color3.fromRGB(169,126,83),
    woodEdge=Color3.fromRGB(103,75,55),brass=Color3.fromRGB(202,174,109),
    coral=Color3.fromRGB(220,126,118),lilac=Color3.fromRGB(157,139,191),
    golden=Color3.fromRGB(234,190,99),ink=Color3.fromRGB(59,68,75),
}
local function piece(parent:Instance,name:string,size:Vector3,cf:CFrame,color:Color3,material:Enum.Material?,collides:boolean?):Part
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
    p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
    p.CanCollide=collides==true;p.CanTouch=false;p.CanQuery=collides==true
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.CastShadow=collides==true or size.Magnitude>2.5
    p.Parent=parent
    return p
end
local function orb(parent:Instance,name:string,size:Vector3,cf:CFrame,color:Color3,material:Enum.Material?):Part
    local p=piece(parent,name,size,cf,color,material,false);p.Shape=Enum.PartType.Ball;return p
end
local function disk(parent:Instance,name:string,diameter:number,length:number,cf:CFrame,color:Color3,material:Enum.Material?):Part
    local p=piece(parent,name,Vector3.new(length,diameter,diameter),cf,color,material,false)
    p.Shape=Enum.PartType.Cylinder;return p
end
local function printed(target:BasePart,words:string,face:Enum.NormalId,ink:Color3,bg:Color3)
    local gui=Instance.new("SurfaceGui");gui.Name="Printed detail";gui.Face=face;gui.LightInfluence=.15
    local width=target.Size.X
    if face==Enum.NormalId.Left or face==Enum.NormalId.Right then width=target.Size.Z end
    local height=face==Enum.NormalId.Top and target.Size.Z or target.Size.Y
    gui.CanvasSize=Vector2.new(600,math.max(85,math.floor(600*height/width)));gui.Parent=target
    local t=Instance.new("TextLabel");t.Name="Printed text";t.Size=UDim2.fromScale(1,1)
    t.Text=words;t.Font=Enum.Font.GothamBold;t.TextColor3=ink
    t.TextScaled=true;t.TextWrapped=true;t.BackgroundColor3=bg;t.BackgroundTransparency=.08;t.Parent=gui
    local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,22);pad.PaddingRight=UDim.new(0,22)
    pad.PaddingTop=UDim.new(0,13);pad.PaddingBottom=UDim.new(0,13);pad.Parent=t
end
local function makeGroup(parent:Instance,name:string):Folder
    local group=Instance.new("Folder");group.Name=name;group.Parent=parent;return group
end

local function windowNeighborhood(root:Instance)
    local world=makeGroup(root,"Layered outside neighborhood")
    -- The exterior sits behind the existing windows and glass, never inside.
    for i,z in ipairs({-24.5,-15.5,1,11.5}) do
        local tall=(i%2==0) and 4.8 or 6.2
        local house=piece(world,"Distant brick house",Vector3.new(.36,tall,7),CFrame.new(-38.30,4.6+tall/2,z),
            (i%2==0) and Color3.fromRGB(181,130,103) or Color3.fromRGB(207,174,133),Enum.Material.Brick,false)
        piece(world,"Slate roof silhouette",Vector3.new(.55,.44,7.8),house.CFrame*CFrame.new(0,tall/2+.2,0),C.woodEdge,Enum.Material.Slate,false)
        for floor=0,1 do
            for col=-1,1 do
                piece(world,"Neighbor window",Vector3.new(.10,1.10,.85),CFrame.new(-38.02,6.1+floor*2,z+col*1.80),
                    Color3.fromRGB(212,234,237),Enum.Material.Glass,false)
                piece(world,"Window sill",Vector3.new(.15,.10,1.13),CFrame.new(-37.96,5.52+floor*2,z+col*1.80),
                    C.cream,Enum.Material.SmoothPlastic,false)
            end
        end
    end
    for i,z in ipairs({-28.5,-9.5,16.5}) do
        local trunk=piece(world,"Tree trunk outside",Vector3.new(.32,3.4,.48),
            CFrame.new(-38.45,6.5,z),Color3.fromRGB(92,76,55),Enum.Material.Wood,false)
        -- Six staggered leaf masses make a believable irregular canopy.
        -- One enormous perfect sphere looked like a green beach ball through
        -- the school window in the real source-derived eye-level renders.
        local clusters={
            {-.18,1.85,-1.35,1.16,2.30,2.14},
            {-.24,2.30,.95,1.43,2.15,2.44},
            {.08,3.12,-.56,1.28,1.70,2.14},
            {-.13,1.45,1.82,1.05,1.78,1.62},
            {-.42,2.76,-1.82,.98,1.65,1.58},
            {.25,3.75,.42,.94,1.47,1.49},
        }
        local shades={
            Color3.fromRGB(78,123,79),Color3.fromRGB(92,142,89),
            Color3.fromRGB(116,152,92),Color3.fromRGB(104,138,82),
            Color3.fromRGB(82,129,88),Color3.fromRGB(132,159,103),
        }
        for k,v in ipairs(clusters) do
            orb(world,"Irregular exterior leaf cluster",
                Vector3.new(v[4],v[5],v[6]),
                trunk.CFrame*CFrame.new(v[1],v[2],v[3]),
                shades[(k+i-2)%#shades+1],Enum.Material.Grass)
        end
    end
    for _,z in ipairs({-20.7,6.8}) do
        for _,offset in ipairs({-1.3,0,1.3}) do
            orb(world,"Soft distant cloud",Vector3.new(.42,1.05,2.25),CFrame.new(-38.10,11.8+math.abs(offset)*.18,z+offset),
                Color3.fromRGB(247,246,230),Enum.Material.SmoothPlastic)
        end
    end
end

local function readingCorner(root:Instance)
    local group=makeGroup(root,"Cozy story corner")
    local seats={{x=-29.2,z=13,c=C.coral},{x=-22.7,z=15.1,c=C.blue}}
    for _,v in ipairs(seats) do
        orb(group,"Corduroy floor pouf",Vector3.new(4.1,1.20,3.6),CFrame.new(v.x,1.14,v.z),v.c,Enum.Material.Fabric)
        orb(group,"Soft seat cushion",Vector3.new(3.35,.68,2.90),CFrame.new(v.x,1.83,v.z-.12),
            v.c:Lerp(C.cream,.21),Enum.Material.Fabric)
        disk(group,"Soft fabric button",.31,.055,CFrame.new(v.x,2.19,v.z)*CFrame.Angles(0,0,math.pi/2),
            C.cream,Enum.Material.Fabric)
        for _,side in ipairs({-1,1}) do
            piece(group,"Fabric seat piping",Vector3.new(.075,.085,2.2),CFrame.new(v.x+side*1.60,1.26,v.z),
                C.cream,Enum.Material.Fabric,false)
        end
    end
    piece(group,"Child-height book display shelf",Vector3.new(5.9,.24,2.2),CFrame.new(-19.4,2,15),C.wood,Enum.Material.Wood,false)
    for _,x in ipairs({-21.9,-17}) do
        piece(group,"Story rack leg",Vector3.new(.34,1.8,.34),CFrame.new(x,1.14,15),C.woodEdge,Enum.Material.Wood,false)
    end
    local titles={"SPACE","PETS","OCEAN","STARS","GARDEN"}
    local colors={C.navy,C.coral,C.blue,C.lilac,C.leaf}
    for i=1,5 do
        local cf=CFrame.new(-21.75+(i-1)*1.17,3,14.75)*CFrame.Angles(math.rad(-15),0,0)
        piece(group,"Storybook page edges",Vector3.new(1,1.5,.19),cf,C.cream,Enum.Material.SmoothPlastic,false)
        local cover=piece(group,"Illustrated storybook cover",Vector3.new(1.1,1.64,.05),
            cf*CFrame.new(0,0,.15),colors[i],Enum.Material.SmoothPlastic,false)
        printed(cover,titles[i],Enum.NormalId.Back,C.cream,colors[i])
        piece(group,"Book spine",Vector3.new(.09,1.64,.28),cf*CFrame.new(-.55,0,.05),
            C.woodEdge,Enum.Material.SmoothPlastic,false)
    end
    local lamp=piece(group,"Reading floor lamp stem",Vector3.new(.14,7,.14),CFrame.new(-33.8,4.1,18.7),
        C.brass,Enum.Material.Metal,false)
    disk(group,"Reading lamp base",1.25,.16,CFrame.new(-33.8,.7,18.7)*CFrame.Angles(0,0,math.pi/2),C.ink,Enum.Material.Metal)
    orb(group,"Warm lamp shade",Vector3.new(1.75,1.35,1.75),lamp.CFrame*CFrame.new(0,3.2,0),C.cream,Enum.Material.Glass)
    local light=Instance.new("PointLight");light.Color=Color3.fromRGB(255,223,165)
    light.Brightness=.35;light.Range=13;light.Shadows=false;light.Parent=lamp
end

local function studentDeskDetails(root:Instance)
    local group=makeGroup(root,"Real desk hardware and stationery")
    for row,z in ipairs({-12,4,19}) do
        for col,x in ipairs({-24,-16,-8,0,12,20}) do
            if row<3 or col>2 then
                local accent=({C.blue,C.mint,C.coral,C.golden})[(row+col)%4+1]
                -- Refine the existing desk rather than replace it or shift Emma's spawn.
                piece(group,"Inlaid laminate grain",Vector3.new(4.8,.012,.042),CFrame.new(x,3.179,z+1.33),
                    C.woodEdge:Lerp(C.wood,.6),Enum.Material.Wood,false)
                for _,side in ipairs({-1,1}) do
                    piece(group,"Desk apron bracket",Vector3.new(.16,.40,.95),CFrame.new(x+side*2.22,2.58,z+.84),
                        C.ink,Enum.Material.Metal,false)
                    disk(group,"Desk fixing bolt",.13,.035,CFrame.new(x+side*2.22,2.72,z+.71),
                        C.brass,Enum.Material.Metal)
                end
                -- A third of desks have a colored supply tray. This is a lived-in
                -- classroom, not a cloned showroom arrangement.
                if (row+col)%3==0 then
                piece(group,"Stationery tray",Vector3.new(1.1,.075,.75),CFrame.new(x+1.72,3.24,z+.86),
                    accent,Enum.Material.SmoothPlastic,false)
                for _,side in ipairs({-1,1}) do
                    piece(group,"Tray wall",Vector3.new(.08,.25,.75),CFrame.new(x+1.72+side*.52,3.36,z+.86),
                        accent,Enum.Material.SmoothPlastic,false)
                end
                piece(group,"Pencil marker",Vector3.new(.09,.10,.63),CFrame.new(x+1.62,3.35,z+.86),
                    C.navy,Enum.Material.SmoothPlastic,false)
                piece(group,"Pencil cap",Vector3.new(.11,.12,.16),CFrame.new(x+1.62,3.35,z+.61),
                    C.cream,Enum.Material.SmoothPlastic,false)
                piece(group,"Short ruler",Vector3.new(.09,.035,.67),CFrame.new(x+1.90,3.34,z+.86),
                    C.golden,Enum.Material.SmoothPlastic,false)
                end
                piece(group,"Chair back accent",Vector3.new(1.62,.26,.045),
                    CFrame.new(x,2.93,z+4.39)*CFrame.Angles(math.rad(-7),0,0),
                    accent,Enum.Material.SmoothPlastic,false)
            end
        end
    end
end

local function learningWall(root:Instance)
    local group=makeGroup(root,"Morning routines and learning wall")
    local welcome=piece(group,"Room-wide grade 2 welcome",Vector3.new(18,2.5,.18),
        CFrame.new(-22.4,14.7,26.31),C.navy,Enum.Material.Wood,false)
    printed(welcome,"GRADE 2  •  READ  •  WONDER  •  GROW",Enum.NormalId.Front,C.cream,C.navy)
    piece(group,"Daily jobs cork backing",Vector3.new(.18,6.6,9.8),
        CFrame.new(36.28,9.6,-31),C.wood,Enum.Material.Wood,false)
    piece(group,"Jobs board frame",Vector3.new(.23,7.05,10.25),
        CFrame.new(36.25,9.6,-31),C.woodEdge,Enum.Material.Wood,false)
    for i,job in ipairs({"HELPER","READER","ARTIST","LEADER"}) do
        local color=({C.mint,C.golden,C.coral,C.blue})[i]
        local card=piece(group,"Daily helper job card",Vector3.new(.05,1.24,7.7),
            CFrame.new(36.10,12.1-(i-1)*1.56,-31),color,Enum.Material.SmoothPlastic,false)
        printed(card,job,Enum.NormalId.Left,C.ink,color)
        orb(group,"Jobs board pushpin",Vector3.new(.13,.13,.13),
            CFrame.new(36.04,12.1-(i-1)*1.56,-34.2),C.brass,Enum.Material.Metal)
    end
    -- Avoid putting number cards directly over the framed student artwork.
    for i=1,9 do
        piece(group,"Hanging pastel bunting",Vector3.new(2.2,1.3,.08),
            CFrame.new(-32+(i-1)*3.2,16.5,26.32)*CFrame.Angles(0,0,math.rad(i%2==0 and 12 or -12)),
            ({C.mint,C.coral,C.lilac,C.golden})[i%4+1],Enum.Material.Fabric,false)
    end
    for _,z in ipairs({-20,6}) do
        for i=0,2 do
            local wash=piece(group,"Soft oak floor sunlight",Vector3.new(8,.008,1.05),
                CFrame.new(-29+i*6,.527,z+2+i*1.3),Color3.fromRGB(255,243,211),Enum.Material.SmoothPlastic,false)
            wash.Transparency=.975;wash.CastShadow=false
        end
    end
end

-- Frame the actual teaching board instead of adding a giant UI overlay.
-- This lives in the world and leaves the question SurfaceGui untouched.
local function focalTeachingArea(root:Instance)
    local group=makeGroup(root,"Smartboard and teacher's art corner")
    local metal=Color3.fromRGB(188,198,204)
    local trim=Color3.fromRGB(217,186,121)
    for _,y in ipairs({4.79,11.58}) do
        piece(group,"Smartboard satin aluminum trim",Vector3.new(19.45,.11,.12),
            CFrame.new(5.2,y,-33.26),metal,Enum.Material.Metal,false)
    end
    for _,x in ipairs({-4.525,14.925}) do
        piece(group,"Smartboard protective edge",Vector3.new(.10,6.84,.13),
            CFrame.new(x,8.2,-33.26),metal,Enum.Material.Metal,false)
    end
    piece(group,"Writable marker shelf",Vector3.new(7.3,.15,.75),
        CFrame.new(5.2,4.44,-32.97),C.cream,Enum.Material.SmoothPlastic,false)
    local markerColors={C.coral,C.blue,C.mint,C.golden}
    for i,c in ipairs(markerColors) do
        local x=2.95+(i-1)*1.20
        piece(group,"Smartboard marker body",Vector3.new(.72,.13,.13),
            CFrame.new(x,4.58,-32.72),c,Enum.Material.SmoothPlastic,false)
        piece(group,"Smartboard marker cap",Vector3.new(.14,.15,.15),
            CFrame.new(x+.39,4.58,-32.72),C.navy,Enum.Material.SmoothPlastic,false)
    end
    -- Locate the freestanding art display in the LEFT teaching corner.
    -- The previous x=-20.4 arrangement overlapped the actual chalkboard
    -- silhouette from Emma's eye-height view; this leaves a clear horizontal
    -- gap without moving either wall-mounted teaching board or the desks.
    local easelX=-29
    local wood=piece(group,"Art easel wooden board",Vector3.new(5.3,4.8,.22),
        CFrame.new(easelX,6.55,-29.7),C.wood,Enum.Material.Wood,false)
    local poster=piece(group,"Easel framed print",Vector3.new(4.68,4.18,.055),
        wood.CFrame*CFrame.new(0,0,.15),C.mint,Enum.Material.SmoothPlastic,false)
    printed(poster,"OUR CLASSROOM\nA PLACE TO GROW",Enum.NormalId.Back,C.navy,C.mint)
    for _,dx in ipairs({-1.80,1.80}) do
        piece(group,"Easel timber support",Vector3.new(.32,6.2,.35),
            CFrame.new(easelX+dx,3.2,-29.82),C.woodEdge,Enum.Material.Wood,false)
    end
    piece(group,"Easel display ledge",Vector3.new(5.7,.22,.66),
        CFrame.new(easelX,4.32,-29.36),C.woodEdge,Enum.Material.Wood,false)
    for _,dx in ipairs({-2.2,0,2.2}) do
        orb(group,"Golden achievement star",Vector3.new(.46,.46,.12),
            CFrame.new(easelX+dx,9.35,-29.46),trim,Enum.Material.Metal)
    end
end

function ArtPass.decorate(root:Instance)
    local details=makeGroup(root,"Emma Original Art Direction Pass")
    windowNeighborhood(details)
    readingCorner(details)
    studentDeskDetails(details)
    learningWall(details)
    focalTeachingArea(details)
end
return ArtPass
