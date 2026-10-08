--!strict
-- Original, photo-guided environmental art for the ABVM classroom replica.
-- These are physical room details, not a game HUD or interactive lesson UI.
local Lighting=game:GetService("Lighting")
local GalleryPass={}
local C={
    navy=Color3.fromRGB(48,68,100),
    blue=Color3.fromRGB(102,137,161),
    oak=Color3.fromRGB(120,82,56),
    gold=Color3.fromRGB(202,159,91),
    cream=Color3.fromRGB(248,245,231),
    paper=Color3.fromRGB(253,250,240),
    slate=Color3.fromRGB(52,64,69),
    pencil=Color3.fromRGB(217,175,84),
    metal=Color3.fromRGB(153,154,149),
    green=Color3.fromRGB(53,110,83),
}

local function piece(parent:Instance,name:string,size:Vector3,cf:CFrame,color:Color3,material:Enum.Material?,collide:boolean?):Part
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color
    p.Material=material or Enum.Material.SmoothPlastic
    p.Anchored=true;p.CanCollide=collide==true;p.CanTouch=false;p.CanQuery=false
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end

local function sphere(parent:Instance,name:string,size:Vector3,cf:CFrame,color:Color3,material:Enum.Material?)
    local p=piece(parent,name,size,cf,color,material,false)
    p.Shape=Enum.PartType.Ball
    return p
end

local function printFace(target:BasePart,face:Enum.NormalId,title:string,small:string,bg:Color3,ink:Color3)
    local gui=Instance.new("SurfaceGui")
    gui.Name="InWorldSignage";gui.Face=face;gui.LightInfluence=.22
    gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
    local wide=(face==Enum.NormalId.Left or face==Enum.NormalId.Right) and target.Size.Z or target.Size.X
    gui.CanvasSize=Vector2.new(900,math.max(100,math.floor(900*target.Size.Y/wide)))
    gui.Parent=target
    local backdrop=Instance.new("Frame")
    backdrop.BackgroundColor3=bg;backdrop.BorderSizePixel=0;backdrop.Size=UDim2.fromScale(1,1);backdrop.Parent=gui
    local heading=Instance.new("TextLabel")
    heading.Name="DecorativeHeading";heading.Size=UDim2.fromScale(.90,.41)
    heading.Position=UDim2.fromScale(.05,.11)
    heading.BackgroundTransparency=1;heading.Font=Enum.Font.GothamBold
    heading.TextColor3=ink;heading.TextScaled=true;heading.TextWrapped=true;heading.Text=title
    heading.Parent=backdrop
    local sub=Instance.new("TextLabel")
    sub.Name="DecorativeCaption";sub.Size=UDim2.fromScale(.84,.22)
    sub.Position=UDim2.fromScale(.08,.66);sub.BackgroundTransparency=1
    sub.Font=Enum.Font.GothamMedium;sub.TextColor3=ink
    sub.TextScaled=true;sub.TextWrapped=true;sub.Text=small;sub.Parent=backdrop
    return gui
end

local function framedPoster(group:Instance,name:string,x:number,y:number,z:number,w:number,h:number,title:string,caption:string,face:Enum.NormalId)
    local side=face==Enum.NormalId.Left
    local frameSize=side and Vector3.new(.32,h+.35,w+.35) or Vector3.new(w+.35,h+.35,.26)
    local frontSize=side and Vector3.new(.34,h,w) or Vector3.new(w,h,.28)
    local frame=piece(group,name.." oak surround",frameSize,CFrame.new(x,y,z),C.oak,Enum.Material.Wood,false)
    local front=piece(group,name.." paper art",frontSize,
        CFrame.new(x+(side and -.20 or 0),y,z+(side and 0 or -.18)),
        C.paper,Enum.Material.SmoothPlastic,false)
    printFace(front,face,title,caption,C.paper,C.navy)
    return frame
end

local function showcaseBoards(root:Instance,group:Instance)
    -- Eliminate the gigantic floating values graphics seen in the phone capture.
    -- Replace them with wall-mounted, human-scale classroom displays.
    for _,object in ipairs(root:GetChildren()) do
        if object.Name=="Class values" or object.Name=="All loved sign" then
            object:Destroy()
        end
    end
    framedPoster(group,"ABVM classroom values",36.27,10.1,-18.0,7.5,5.0,
        "BE KIND","Be respectful  •  Be your best",Enum.NormalId.Left)
    framedPoster(group,"Classroom encouragement",36.27,13.2,1.0,9.4,3.0,
        "LET YOUR LIGHT SHINE","Assumption BVM Catholic School",Enum.NormalId.Left)
    -- More believable classroom boards with muted cork and pinned paper, not menus.
    local board=piece(group,"Class notice board",Vector3.new(.30,5.0,11.2),
        CFrame.new(36.22,8.0,1.0),Color3.fromRGB(174,134,92),Enum.Material.Fabric,false)
    for _,z in ipairs({-3.8,5.8}) do
        piece(group,"Noticeboard vertical oak frame",Vector3.new(.40,5.4,.25),CFrame.new(36.03,8,z),C.oak,Enum.Material.Wood,false)
    end
    for _,y in ipairs({5.45,10.55}) do
        piece(group,"Noticeboard horizontal oak frame",Vector3.new(.40,.25,11.6),CFrame.new(36.03,y,1),C.oak,Enum.Material.Wood,false)
    end
    for i=1,3 do
        local z=-2.8+(i-1)*3.8
        local sheet=piece(group,"Pinned classroom newsletter",Vector3.new(.12,3.2,2.7),
            CFrame.new(35.95,8,z),C.paper,Enum.Material.SmoothPlastic,false)
        local ink=({C.green,C.navy,C.blue})[i]
        printFace(sheet,Enum.NormalId.Left,({"OUR CLASS","READING","ART ROOM"})[i],
            ({"We belong here","Stories we love","Create and explore"})[i],C.paper,ink)
        sphere(group,"Brass push pin",Vector3.new(.23,.23,.23),CFrame.new(35.8,9.36,z),C.gold,Enum.Material.Metal)
    end

    local smart=root:FindFirstChild("Interactive smartboard")
    if smart and smart:IsA("BasePart") then
        for _,child in ipairs(smart:GetChildren()) do
            if child:IsA("SurfaceGui") then child:Destroy() end
        end
        smart.Material=Enum.Material.Glass
        smart.Color=Color3.fromRGB(49,65,70)
        smart.Transparency=0
        printFace(smart,Enum.NormalId.Back,"WELCOME TO GRADE 2",
            "ASSUMPTION BVM  •  LEARN  •  CREATE  •  GROW",C.slate,C.paper)
        -- Hardware, not a giant question-card UI.
        piece(group,"Interactive board camera",Vector3.new(.28,.28,.23),
            CFrame.new(7,11.77,-33.35),C.slate,Enum.Material.Metal,false)
        for _,x in ipairs({1.5,2.2,2.9}) do
            piece(group,"Interactive board stylus",Vector3.new(.12,.12,1.05),
                CFrame.new(x,4.79,-33.10)*CFrame.Angles(0,math.rad(90),0),
                x<2 and C.slate or C.metal,Enum.Material.SmoothPlastic,false)
        end
    end
    -- Actual chalkboard remains physically visible beside the smartboard.
    local chalk=piece(group,"Chalk handwriting panel",Vector3.new(12.6,4.20,.065),
        CFrame.new(-13.7,8.3,-33.93),Color3.fromRGB(40,51,49),
        Enum.Material.SmoothPlastic,false)
    printFace(chalk,Enum.NormalId.Back,"GOOD MORNING!","We learn together.",chalk.Color,C.cream)
    for i=1,8 do
        piece(group,"Chalk dust in tray",Vector3.new(.26,.02,.14),
            CFrame.new(-18+i*.43,4.20,-33.31),C.cream,Enum.Material.SmoothPlastic,false)
    end
end

local function pupilWork(group:Instance)
    -- The back-wall student gallery is modeled as anonymous crayon art:
    -- no children's names, portraits, uploads, or real work are redistributed.
    local positions={-29,-22,-15,14,21,28}
    local colors={
        Color3.fromRGB(189,205,220),Color3.fromRGB(233,196,158),
        Color3.fromRGB(184,212,185),Color3.fromRGB(226,196,202),
        Color3.fromRGB(210,203,232),Color3.fromRGB(219,211,171),
    }
    for i,x in ipairs(positions) do
        local z=26.31
        piece(group,"Student art walnut frame",Vector3.new(5.6,4.8,.28),
            CFrame.new(x,9.6,z),C.oak,Enum.Material.Wood,false)
        piece(group,"Student art ivory mount",Vector3.new(5.06,4.24,.10),
            CFrame.new(x,9.6,z-.18),C.paper,Enum.Material.SmoothPlastic,false)
        piece(group,"Student art illustration backing",Vector3.new(4.55,3.63,.08),
            CFrame.new(x,9.6,z-.26),colors[i],Enum.Material.SmoothPlastic,false)
        local petalColor=(i%2==0) and C.cream or C.pencil
        for p=1,5 do
            local angle=(p-1)*math.pi*2/5
            local px=x+math.cos(angle)*.92
            local py=9.55+math.sin(angle)*.78
            sphere(group,"Crayon flower petal",Vector3.new(.80,.65,.045),
                CFrame.new(px,py,z-.35),petalColor,Enum.Material.SmoothPlastic)
        end
        sphere(group,"Crayon flower center",Vector3.new(.65,.65,.06),CFrame.new(x,9.55,z-.39),
            C.gold,Enum.Material.SmoothPlastic)
        piece(group,"Crayon stem",Vector3.new(.065,1.1,.05),CFrame.new(x,8.45,z-.35),
            C.green,Enum.Material.SmoothPlastic,false)
        piece(group,"Gallery paper clip",Vector3.new(.46,.17,.12),
            CFrame.new(x,12,z-.43),C.metal,Enum.Material.Metal,false)
    end
end

local function physicalDetails(root:Instance,group:Instance)
    -- Original trim and hardware at eye height makes the room read as a building,
    -- rather than a pile of bright blocks.
    for _,x in ipairs({-32.9,32.9}) do
        piece(group,"Wall-to-ceiling crown molding",Vector3.new(.52,.30,60.4),
            CFrame.new(x,17.45,-4),C.cream,Enum.Material.Wood,false)
    end
    for _,z in ipairs({-33.9,26}) do
        piece(group,"Wall-to-ceiling crown molding",Vector3.new(71,.30,.45),
            CFrame.new(0,17.45,z),C.cream,Enum.Material.Wood,false)
    end

    for _,z in ipairs({-23,-13,1,14}) do
        local panel=piece(group,"Radiator grilles under classroom windows",
            Vector3.new(.07,1.6,1.2),CFrame.new(-34.35,1.7,z),
            Color3.fromRGB(212,213,206),Enum.Material.Metal,false)
        for i=-2,2 do
            piece(group,"Radiator grille slot",Vector3.new(.09,.12,.78),
                panel.CFrame*CFrame.new(-.03,i*.24,0),C.metal,Enum.Material.Metal,false)
        end
    end

    -- Recessed switch panels/door hardware and realistic wall fixtures.
    for _,z in ipairs({-29,21}) do
        local plate=piece(group,"Wall switch plate",Vector3.new(.14,.86,.61),
            CFrame.new(36.33,4.4,z),C.paper,Enum.Material.SmoothPlastic,false)
        piece(group,"Light switch rocker",Vector3.new(.08,.47,.26),
            plate.CFrame*CFrame.new(-.09,0,0),C.metal,Enum.Material.SmoothPlastic,false)
    end
    for _,door in ipairs(root:GetChildren()) do
        if door.Name=="Open classroom door" or door.Name=="Open staff classroom door" then
            local nearEdge=door.Name=="Open classroom door" and door.Size.X/2-.65 or 0
            local plate=piece(group,"Classroom door handle plate",Vector3.new(.56,1.0,.06),
                door.CFrame*CFrame.new(nearEdge,-.7,-.32),C.metal,Enum.Material.Metal,false)
            sphere(group,"Classroom brass door knob",Vector3.new(.42,.42,.42),
                plate.CFrame*CFrame.new(0,0,-.28),C.gold,Enum.Material.Metal)
        end
    end

    -- Small physical supplies on the teaching desk rather than more HUD labels.
    piece(group,"Teacher desk wooden stationery tray",Vector3.new(2.5,.15,1.6),
        CFrame.new(22,3.46,-22.6),C.oak,Enum.Material.Wood,false)
    for i=1,6 do
        piece(group,"Teacher wooden colored pencil",Vector3.new(.10,.09,1.18),
            CFrame.new(21.2+i*.23,3.57,-22.5),
            ({C.pencil,C.blue,C.green})[(i-1)%3+1],Enum.Material.Wood,false)
    end
    piece(group,"Teacher note paper",Vector3.new(1.75,.04,1.43),
        CFrame.new(30.5,3.42,-24.0),C.paper,Enum.Material.SmoothPlastic,false)
    for i=1,4 do
        piece(group,"Teacher note ruled line",Vector3.new(1.46,.009,.025),
            CFrame.new(30.5,3.45,-24.42+i*.25),C.blue,Enum.Material.SmoothPlastic,false)
    end
end

function GalleryPass.decorate(root:Instance)
    local group=Instance.new("Folder")
    group.Name="Architectural finishing and classroom storytelling"
    group.Parent=root
    showcaseBoards(root,group)
    pupilWork(group)
    physicalDetails(root,group)

    Lighting.ExposureCompensation=-.17
    Lighting.EnvironmentDiffuseScale=.69
    Lighting.EnvironmentSpecularScale=.21
    local cc=Lighting:FindFirstChild("EmmaClassroomGrade")
    if cc and cc:IsA("ColorCorrectionEffect") then
        cc.Contrast=.09
        cc.Saturation=-.02
        cc.TintColor=Color3.fromRGB(255,251,244)
    end
    root:SetAttribute("ExperienceMode","ClassroomOnly_NoQuestionsOrHUD")
    root:SetAttribute("ArtDirection","PhotoGuidedArchitecturalReplica")
    return group
end

return GalleryPass
