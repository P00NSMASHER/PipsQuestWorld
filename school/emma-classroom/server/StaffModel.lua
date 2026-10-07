--!strict
-- Native, asset-independent staff geometry. Portrait targets are art direction,
-- not screenshots of this model. Every clothing detail shares its limb pose.
local StaffModel={}
local WHITE=Color3.fromRGB(250,248,239)
local INK=Color3.fromRGB(27,25,29)
local GOLD=Color3.fromRGB(209,169,83)
local GREEN=Color3.fromRGB(28,82,59)
local SCALE=.76
local HIP_Y=-.12
local SHOULDER_Y=2.76

local function rgb(c) return Color3.fromRGB(c[1],c[2],c[3]) end
local function localPose(cf,scale) return CFrame.new(cf.Position*scale)*cf.Rotation end

function StaffModel.create(teacher)
    local model=Instance.new("Model");model.Name=teacher.name
    local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(1,1,1)
    root.Anchored=true;root.Transparency=1;root.CanCollide=false;root.CanTouch=false;root.CanQuery=false;root.Parent=model
    model.PrimaryPart=root
    model:SetAttribute("StaffGeometryVersion",4)
    local skin,hair,shirt,accent=rgb(teacher.skin),rgb(teacher.hair),rgb(teacher.shirt),rgb(teacher.accent)
    local clothes=teacher.clothing or "blouse"
    local formal=clothes=="suit" or clothes=="blazer"
    local isBolich=teacher.name=="Mr. Bolich"
    local isBoyer=teacher.name=="Mrs. Boyer"
    local pants=teacher.pants and rgb(teacher.pants) or (formal and shirt or Color3.fromRGB(43,45,53))
    local function make(name,size,cf,color,group,shape,material)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color
        p.Anchored=true;p.Massless=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
        -- Default Fabric was visibly noisy in the native Studio close-up.
        p.Material=material==Enum.Material.Fabric and Enum.Material.SmoothPlastic or (material or Enum.Material.SmoothPlastic)
        p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
        if shape then p.Shape=shape end
        if group then p:SetAttribute("PoseGroup",group);p:SetAttribute("RestCF",cf) end
        p.Parent=model;return p
    end
    local function box(name,size,cf,color,group,material) return make(name,size,cf,color,group,nil,material) end
    local function oval(name,size,cf,color,group) return make(name,size,cf,color,group,Enum.PartType.Ball) end
    -- Round the silhouette with real cylindrical corners, rather than a block
    -- hidden behind accessories. All six pieces retain the same limb transform.
    local function rounded(name,size,cf,color,group,radius)
        local r=radius or .12
        local core=box(name,Vector3.new(size.X-2*r,size.Y,size.Z),cf,color,group)
        box(name.." center",Vector3.new(size.X,size.Y-2*r,size.Z),cf,color,group)
        for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do
            make(name.." rounded corner",Vector3.new(size.Z,2*r,2*r),cf*CFrame.new(x*(size.X/2-r),y*(size.Y/2-r),0)*CFrame.Angles(0,math.pi/2,0),color,group,Enum.PartType.Cylinder)
        end end
        return core
    end
    local function wedge(name,size,cf,color)
        local p=box(name,size,cf,color)
        local mesh=Instance.new("SpecialMesh");mesh.Name="Tailored triangular lapel";mesh.MeshType=Enum.MeshType.Wedge;mesh.Parent=p
        return p
    end
    local function line(name,a,b,width,color,group)
        return make(name,Vector3.new((b-a).Magnitude,width,width),CFrame.lookAt((a+b)*.5,b)*CFrame.Angles(0,math.pi/2,0),color,group,Enum.PartType.Cylinder)
    end
    local function path(name,points,width,color,group)
        for i=2,#points do line(name,points[i-1],points[i],width,color,group) end
    end
    local function curve(name,x,y,z,rx,ry,from,to,steps,width,color,group)
        local pts={}
        for i=0,steps do
            local t=from+(to-from)*i/steps
            pts[#pts+1]=Vector3.new(x+math.cos(t)*rx,y+math.sin(t)*ry,z)
        end
        path(name,pts,width,color,group)
    end

    rounded("Torso",Vector3.new(3.15,2.85,1.65),CFrame.new(0,1.46,0),shirt,nil,.20)
    oval("Neck",Vector3.new(.9,.55,.9),CFrame.new(0,3.08,0),skin)
    -- Explicit rounded parts have known bounds. MeshType.Head has nonstandard
    -- scaling; version 55 buried its 3D eyes/mouth and hair inside that mesh.
    local head=rounded("Head",Vector3.new(2.25,2.2,1.75),CFrame.new(0,4.12,0),skin,nil,.32)
    local face=Instance.new("SurfaceGui");face.Name="Friendly face";face.Face=Enum.NormalId.Front
    face.CanvasSize=Vector2.new(440,600);face.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
    face.LightInfluence=0;face.Brightness=1;face.AlwaysOnTop=false;face.ZOffset=.015;face.Parent=head
    local function ink(name,x,y,w,h,color,rotation)
        local f=Instance.new("Frame");f.Name=name;f.AnchorPoint=Vector2.new(.5,.5)
        f.Position=UDim2.fromOffset(x,y);f.Size=UDim2.fromOffset(w,h);f.BackgroundColor3=color
        f.BorderSizePixel=0;f.Rotation=rotation or 0;f.Parent=face
        local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=f
        return f
    end
    -- Two open eyes and a gentle upward smile. Flat ink stays attached and
    -- readable without raised eyeballs, teeth, eyelash spikes or mouth masks.
    for _,x in ipairs({125,315}) do
        ink("Friendly eye",x,295,38,64,INK)
        ink("Eye shine",x-6,281,9,13,WHITE)
        ink("Friendly brow",x,226,65,10,hair,x<220 and -5 or 5)
    end
    for i=0,11 do
        local t1=math.pi*i/12;local t2=math.pi*(i+1)/12
        local x1,y1=220-98*math.cos(t1),396+38*math.sin(t1)
        local x2,y2=220-98*math.cos(t2),396+38*math.sin(t2)
        local dx,dy=x2-x1,y2-y1
        ink("Friendly smile",(x1+x2)/2,(y1+y2)/2,math.sqrt(dx*dx+dy*dy)+2,11,INK,math.deg(math.atan2(dy,dx)))
    end
    for _,side in ipairs({-1,1}) do
        oval("Ear",Vector3.new(.24,.43,.40),CFrame.new(side*1.11,4.12,.10),skin)
        if isBoyer then oval("Pearl earring",Vector3.new(.17,.17,.17),CFrame.new(side*1.19,3.85,-.13),WHITE) end
    end
    if teacher.glasses then
        for _,x in ipairs({125,315}) do
            -- Transparent frames drawn around, never over, the eye centers.
            ink("Glasses top",x,248,134,10,INK)
            ink("Glasses bottom",x,345,134,10,INK)
            ink("Glasses side",x-62,296.5,10,98,INK)
            ink("Glasses side",x+62,296.5,10,98,INK)
        end
        ink("Glasses bridge",220,274,66,9,INK)
        for _,side in ipairs({-1,1}) do line("Glasses temple",Vector3.new(side*.76,4.31,-.90),Vector3.new(side*1.17,4.27,.18),.06,INK) end
    end

    -- One cap, one fringe, and connected side/back pieces. No floating locks
    -- or thin strand geometry that shimmers at phone resolution.
    local style=teacher.hairStyle or "shoulder"
    if style=="balding" then
        for _,side in ipairs({-1,1}) do
            oval("Balding side hair",Vector3.new(.28,1.0,1.40),CFrame.new(side*1.04,4.52,.20),hair)
        end
        oval("Balding back hair",Vector3.new(2.05,.85,.40),CFrame.new(0,4.50,.91),hair)
    else
        local short=style=="short"
        oval("Connected hair cap",Vector3.new(2.42,.80,1.92),CFrame.new(0,5.04,.05),hair)
        oval("Single swept fringe",Vector3.new(1.97,short and .26 or .36,.36),CFrame.new(-.10,4.97,-.81)*CFrame.Angles(0,0,short and -.04 or .10),hair)
        for _,side in ipairs({-1,1}) do
            if short then
                oval("Tapered sideburn",Vector3.new(.25,.73,.62),CFrame.new(side*1.04,4.62,.02),hair)
            else
                local length=style=="bob" and 1.58 or (style=="shoulder" and 2.10 or 2.65)
                oval("Connected side hair",Vector3.new(.49,length,1.50),CFrame.new(side*1.08,5.00-length*.43,.27),hair)
            end
        end
        if not short then
            local length=style=="bob" and 1.58 or (style=="shoulder" and 2.10 or 2.65)
            oval("Connected back hair",Vector3.new(2.12,length,.46),CFrame.new(0,5.00-length*.43,.99),hair)
        end
    end
    if teacher.beard then
        -- Flat, continuous beard silhouette keeps the smile visible. The old
        -- seven bead-like beard locks looked like teeth growing out of the chin.
        local beard=rgb(teacher.beard)
        for i=0,8 do
            local x=-.72+i*.18
            local drop=isBolich and (.24+.20*(1-math.abs(x))) or .05
            oval("Connected beard",Vector3.new(.35,isBolich and .56 or .28,.21),CFrame.new(x,3.28-drop*.4,-.78),beard)
        end
        for _,side in ipairs({-1,1}) do
            oval("Beard side",Vector3.new(.25,.44,.26),CFrame.new(side*.84,3.47,-.72),beard)
        end
    end

    local jacket=formal or clothes=="cardigan" or clothes=="vest"
    if jacket then
        box("Shirt inset",Vector3.new(1.1,2.45,.09),CFrame.new(0,1.72,-.862),accent,nil,Enum.Material.Fabric)
        for _,side in ipairs({-1,1}) do
            box("Tailored jacket panel",Vector3.new(1.0,2.62,.15),CFrame.new(side*1.03,1.46,-.9),shirt,nil,Enum.Material.Fabric)
            wedge("Notched jacket lapel",Vector3.new(.12,1.20,.53),CFrame.new(side*.64,2.32,-1.005)*CFrame.Angles(0,0,side*-.22)*CFrame.Angles(0,side*math.pi/2,0),shirt:Lerp(WHITE,.07))
            box("Jacket welt pocket",Vector3.new(.65,.07,.06),CFrame.new(side*1.03,.92,-1.002),shirt:Lerp(WHITE,.15))
            box("Pocket seam",Vector3.new(.59,.022,.025),CFrame.new(side*1.03,.88,-1.04),shirt:Lerp(WHITE,.25))
        end
        for i=0,1 do oval("Jacket button",Vector3.new(.17,.17,.08),CFrame.new(.13,1.13-i*.48,-1.00),isBoyer and GOLD or INK) end
        if isBoyer then
            oval("Gold mission pin",Vector3.new(.24,.24,.075),CFrame.new(.94,2.39,-1.015),GOLD)
            oval("Pin center",Vector3.new(.12,.12,.085),CFrame.new(.94,2.39,-1.055),WHITE)
        end
    end
    if clothes~="turtleneck" then
        for _,side in ipairs({-1,1}) do box("Shirt collar",Vector3.new(.52,.36,.10),CFrame.new(side*.29,2.79,-.94)*CFrame.Angles(0,0,side*.38),jacket and accent or shirt:Lerp(WHITE,.09),nil,Enum.Material.Fabric) end
    else box("Turtleneck collar",Vector3.new(.99,.42,.9),CFrame.new(0,3.0,0),shirt,nil,Enum.Material.Fabric) end
    if clothes=="suit" then
        oval("Tie knot",Vector3.new(.26,.32,.10),CFrame.new(0,2.64,-1.01),Color3.fromRGB(62,84,122))
        box("Silk tie",Vector3.new(.33,1.55,.095),CFrame.new(0,1.78,-1.005),Color3.fromRGB(62,84,122),nil,Enum.Material.Fabric)
        for i=0,4 do box("Tie diagonal stripe",Vector3.new(.30,.03,.02),CFrame.new(0,1.16+i*.28,-1.067)*CFrame.Angles(0,0,.43),Color3.fromRGB(158,185,214)) end
    elseif clothes=="polo" then
        box("Polo placket",Vector3.new(.24,.68,.065),CFrame.new(0,2.47,-.88),shirt:Lerp(INK,.15),nil,Enum.Material.Fabric)
        for i=0,1 do oval("Polo button",Vector3.new(.075,.075,.055),CFrame.new(0,2.60-i*.29,-.925),WHITE) end
        if isBolich then
            local textile=Instance.new("SurfaceGui");textile.Name="Polo woven print";textile.Face=Enum.NormalId.Front; textile.CanvasSize=Vector2.new(600,math.floor(600*model:FindFirstChild("Torso").Size.Y/model:FindFirstChild("Torso").Size.X));textile.LightInfluence=1;textile.Parent=model:FindFirstChild("Torso")
            for i=1,8 do
                local stripe=Instance.new("Frame");stripe.Name="Polo woven horizontal check";stripe.BorderSizePixel=0;stripe.Size=UDim2.new(1,0,0,1);stripe.Position=UDim2.fromScale(0,i/9);stripe.BackgroundColor3=shirt:Lerp(WHITE,.15);stripe.Parent=textile
            end
            for i=1,7 do
                local stripe=Instance.new("Frame");stripe.BorderSizePixel=0;stripe.Size=UDim2.new(0,1,1,0);stripe.Position=UDim2.fromScale(i/8,0);stripe.BackgroundColor3=shirt:Lerp(WHITE,.12);stripe.Parent=textile
            end
        end
    elseif clothes=="striped" then
        for i=0,7 do box("Blouse stripe",Vector3.new(2.96,.055,.035),CFrame.new(0,.23+i*.34,-.865),accent,nil,Enum.Material.Fabric) end
    elseif clothes=="floral" or clothes=="pattern" then
        for row=0,3 do
            for col=0,3 do
                local cf=CFrame.new(-1.12+col*.73,.46+row*.62,-.861)*CFrame.Angles(0,0,(row-col)*.22)
                local color=teacher.name=="Mrs. Kochol" and Color3.fromRGB(228,82,153) or accent
                oval("Printed flower",Vector3.new(.32,.25,.025),cf,color)
                oval("Print leaf",Vector3.new(.12,.24,.025),cf*CFrame.new(.12,-.14,-.008)*CFrame.Angles(0,0,.5),Color3.fromRGB(87,144,107))
            end
        end
    end
    box("Waist belt",Vector3.new(2.94,.22,1.7),CFrame.new(0,.04,0),INK)
    box("Belt buckle",Vector3.new(.40,.27,.07),CFrame.new(0,.04,-.9),formal and GOLD or Color3.fromRGB(170,172,174),nil,Enum.Material.Metal)
    box("Buckle inset",Vector3.new(.28,.14,.08),CFrame.new(0,.04,-.94),INK)

    for _,side in ipairs({-1,1}) do
        local armGroup=side<0 and "leftArm" or "rightArm"
        local legGroup=side<0 and "leftLeg" or "rightLeg"
        local x=side*2.02
        local short=clothes=="polo"
        rounded(side<0 and "Left Arm" or "Right Arm",Vector3.new(1.03,short and 1.60 or 2.65,1.40),CFrame.new(x,short and 1.12 or 1.58,0),short and skin or shirt,armGroup,.16)
        rounded("Sleeve shoulder",Vector3.new(1.09,short and 1.13 or 2.05,1.46),CFrame.new(x,short and 2.31 or 1.85,0),shirt,armGroup,.17)
        box("Sleeve hem",Vector3.new(1.10,.08,1.47),CFrame.new(x,short and 1.75 or .85,0),shirt:Lerp(WHITE,.09),armGroup,Enum.Material.Fabric)
        if formal then box("Shirt cuff",Vector3.new(1.02,.16,1.41),CFrame.new(x,.65,0),accent,armGroup,Enum.Material.Fabric) end
        -- C-shaped toy hands: a ring with an opening, rounded ends, and a thumb.
        local handX=x
        local from=side<0 and 30 or 210
        local to=side<0 and 320 or 500
        curve("C shaped hand",handX,.22,-.13,.42,.43,math.rad(from),math.rad(to),10,.29,skin,armGroup)
        for _,t in ipairs({math.rad(from),math.rad(to)}) do oval("Rounded hand fingertip",Vector3.new(.30,.30,.31),CFrame.new(handX+math.cos(t)*.42,.22+math.sin(t)*.43,-.13),skin,armGroup) end
        oval("Hand thumb",Vector3.new(.28,.38,.34),CFrame.new(handX-side*.22,.39,-.31),skin,armGroup)
        local lx=side*.82
        rounded(side<0 and "Left Leg" or "Right Leg",Vector3.new(1.36,2.77,1.48),CFrame.new(lx,-1.47,0),pants,legGroup,.12)
        box("Trouser pressed crease",Vector3.new(.022,2.51,.03),CFrame.new(lx,-1.46,-.757),pants:Lerp(WHITE,.13),legGroup)
        box("Trouser cuff seam",Vector3.new(1.30,.045,.035),CFrame.new(lx,-2.78,-.755),pants:Lerp(WHITE,.13),legGroup)
        local shoeColor=isBolich and Color3.fromRGB(39,48,69) or INK
        oval("Rounded shoe upper",Vector3.new(1.51,.64,2.07),CFrame.new(lx,-3.12,-.28),shoeColor,legGroup)
        box("Shoe heel",Vector3.new(1.35,.39,1.02),CFrame.new(lx,-3.15,.20),shoeColor,legGroup)
        box("Shoe sole",Vector3.new(1.46,.18,1.91),CFrame.new(lx,-3.43,-.25),isBolich and WHITE or Color3.fromRGB(49,45,44),legGroup)
        oval("Rounded toe",Vector3.new(1.43,.35,.7),CFrame.new(lx,-3.25,-1.02),shoeColor,legGroup)
        if isBolich then
            for i=0,2 do box("Sneaker lace",Vector3.new(.75,.045,.08),CFrame.new(lx,-2.865,-.37-i*.19),WHITE,legGroup) end
            oval("Sneaker toe cap",Vector3.new(1.43,.29,.45),CFrame.new(lx,-3.26,-1.19),WHITE,legGroup)
        end
    end
    local badge=box("Staff badge",Vector3.new(.39,.48,.055),CFrame.new(-1.08,2.01,-1.0),WHITE)
    box("Badge clip",Vector3.new(.12,.09,.065),badge.CFrame*CFrame.new(0,.28,0),GOLD)
    box("Badge portrait",Vector3.new(.15,.19,.065),badge.CFrame*CFrame.new(0,.08,-.01),shirt)
    for i=0,1 do box("Badge print",Vector3.new(.23,.022,.07),badge.CFrame*CFrame.new(0,-.07-i*.07,-.012),GREEN) end
    local nameGui=Instance.new("BillboardGui");nameGui.Name="TeacherName";nameGui.Size=UDim2.fromScale(4.8,.70)
    nameGui.StudsOffset=Vector3.new(0,6.15,0);nameGui.AlwaysOnTop=false;nameGui.MaxDistance=32;nameGui.Parent=root
    local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=GREEN;label.BackgroundTransparency=.28
    label.TextColor3=GOLD;label.TextScaled=true;label.Text=teacher.name;label.Font=Enum.Font.GothamBold;label.Parent=nameGui
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,10);corner.Parent=label
    local speech=Instance.new("BillboardGui");speech.Name="Speech";speech.Size=UDim2.fromOffset(310,105);speech.StudsOffset=Vector3.new(3.8,7.0,0)
    speech.AlwaysOnTop=true;speech.MaxDistance=55;speech.Enabled=false;speech.Parent=root
    local bubble=Instance.new("TextLabel");bubble.Name="Text";bubble.Size=UDim2.fromScale(1,1);bubble.BackgroundColor3=WHITE
    bubble.TextColor3=INK;bubble.TextWrapped=true;bubble.TextScaled=true;bubble.Font=Enum.Font.GothamBold;bubble.Text="";bubble.Parent=speech
    local bc=Instance.new("UICorner");bc.CornerRadius=UDim.new(0,18);bc.Parent=bubble
    model:ScaleTo(SCALE)
    return model
end

function StaffModel.pose(model,phase,walking)
    local pivot,scale=model:GetPivot(),model:GetScale()
    local swing=walking and math.sin(phase)*math.rad(19) or 0
    local joints={
        leftArm={CFrame.new(-2.02,SHOULDER_Y,0),swing},rightArm={CFrame.new(2.02,SHOULDER_Y,0),-swing},
        leftLeg={CFrame.new(-.82,HIP_Y,0),-swing*.72},rightLeg={CFrame.new(.82,HIP_Y,0),swing*.72},
    }
    for _,p in ipairs(model:GetChildren()) do
        if p:IsA("BasePart") then
            local group=p:GetAttribute("PoseGroup")
            local joint=group and joints[group]
            if joint then
                local rest=p:GetAttribute("RestCF")
                local posed=joint[1]*CFrame.Angles(joint[2],0,0)*joint[1]:Inverse()*rest
                p.CFrame=pivot*localPose(posed,scale)
            end
        end
    end
end
return StaffModel
