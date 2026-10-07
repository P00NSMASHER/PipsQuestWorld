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
    model:SetAttribute("StaffGeometryVersion",2)
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
    local function line(name,a,b,width,color,group)
        return box(name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)*.5,b),color,group)
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

    box("Torso",Vector3.new(3.15,2.85,1.65),CFrame.new(0,1.46,0),shirt,nil,Enum.Material.Fabric)
    oval("Neck",Vector3.new(.9,.55,.9),CFrame.new(0,3.08,0),skin)
    local head=box("Head",Vector3.new(2.25,2.2,2),CFrame.new(0,4.12,0),skin)
    local headMesh=Instance.new("SpecialMesh");headMesh.Name="Classic rounded head";headMesh.MeshType=Enum.MeshType.Head;headMesh.Parent=head
    for _,side in ipairs({-1,1}) do
        local x=side*.48
        oval("Expressive oval eye",Vector3.new(.24,.45,.07),CFrame.new(x,4.23,-1.025),INK)
        oval("Eye catchlight",Vector3.new(.075,.095,.028),CFrame.new(x-.035,4.34,-1.064),WHITE)
        path("Shaped eyebrow",{Vector3.new(x-.23,4.72,-.98),Vector3.new(x,4.78,-1.015),Vector3.new(x+.23,4.72,-.98)},.085,hair)
        oval("Ear",Vector3.new(.32,.55,.55),CFrame.new(side*1.08,4.09,.0),skin)
        oval("Ear inset",Vector3.new(.05,.25,.22),CFrame.new(side*1.245,4.1,-.045),skin:Lerp(Color3.fromRGB(192,112,91),.24))
        if isBoyer then oval("Pearl earring",Vector3.new(.19,.19,.19),CFrame.new(side*1.18,3.87,-.34),WHITE) end
        if not string.find(teacher.name,"Mr.",1,true) and teacher.name~="Dr. McBreen" then
            line("Eyelash",Vector3.new(x+side*.07,4.44,-1.06),Vector3.new(x+side*.20,4.53,-1.05),.045,INK)
        end
    end
    -- Filled mouth with a white inset and curved lip; avoids the former straight red bar.
    oval("Smile mouth",Vector3.new(.96,.37,.055),CFrame.new(0,3.76,-1.025),INK)
    oval("Smile teeth",Vector3.new(.77,.18,.038),CFrame.new(0,3.83,-1.059),WHITE)
    box("Smile upper mask",Vector3.new(1.0,.17,.04),CFrame.new(0,3.985,-1.07),skin)
    curve("Smile lower outline",0,3.86,-1.065,.46,.26,math.pi,math.pi*2,8,.035,INK)
    if teacher.glasses then
        for _,x in ipairs({-.48,.48}) do
            -- Rounded rectangle contours, no opaque lens plates covering the eyes.
            local points={Vector3.new(x-.32,4.55,-1.13),Vector3.new(x+.30,4.55,-1.13),Vector3.new(x+.36,4.49,-1.13),Vector3.new(x+.36,4.02,-1.13),Vector3.new(x+.30,3.96,-1.13),Vector3.new(x-.30,3.96,-1.13),Vector3.new(x-.36,4.02,-1.13),Vector3.new(x-.36,4.49,-1.13),Vector3.new(x-.32,4.55,-1.13)}
            path("Rounded glasses frame",points,.075,INK)
        end
        line("Glasses bridge",Vector3.new(-.12,4.35,-1.13),Vector3.new(.12,4.35,-1.13),.075,INK)
        for _,side in ipairs({-1,1}) do line("Glasses temple",Vector3.new(side*.83,4.46,-1.13),Vector3.new(side*1.15,4.38,.25),.06,INK) end
    end

    -- Sculpted locks overlap along the sweep; strand ridges use restrained contrast.
    local highlight=hair:Lerp(WHITE,.16)
    local style=teacher.hairStyle or "shoulder"
    if style=="balding" then
        for _,side in ipairs({-1,1}) do
            oval("Balding side hair",Vector3.new(.28,1.05,1.45),CFrame.new(side*1.11,4.57,.27),hair)
            for i=1,4 do oval("Side hair strand",Vector3.new(.065,.8,.20),CFrame.new(side*1.235,4.6,-.25+i*.22)*CFrame.Angles(.12,0,side*.08),highlight) end
        end
    else
        oval("Hair back cap",Vector3.new(2.38,1.27,1.78),CFrame.new(0,4.98,.27),hair)
        local short=style=="short"
        for i=0,5 do
            local x=-.87+i*.34
            local y=short and 5.08 or 4.98+.16*math.sin(i*.5)
            local tilt=short and math.rad(-18) or math.rad(-30-i*3)
            local cf=CFrame.new(x,y,-.72)*CFrame.Angles(0,0,tilt)
            oval("Swept hair lock",Vector3.new(short and .78 or .88,short and .30 or .78,.63),cf,hair)
            oval("Hair strand ridge",Vector3.new(.045,short and .22 or .57,.045),cf*CFrame.new(-.1,0,-.255),highlight)
        end
        if not short then
            local length=style=="bob" and 1.8 or (style=="shoulder" and 2.25 or 3.1)
            for _,side in ipairs({-1,1}) do
                local cf=CFrame.new(side*1.08,4.66-length*.39,.22)*CFrame.Angles(0,0,side*-.065)
                oval("Shaped side hair",Vector3.new(.68,length,1.45),cf,hair)
                for i=0,2 do
                    oval("Side hair contour",Vector3.new(.065,length*.77,.065),cf*CFrame.new(side*.20,0,-.55+i*.25),highlight)
                end
                if style=="waves" then
                    for i=0,3 do oval("Layered hair wave",Vector3.new(.58,.72,.65),cf*CFrame.new(side*.09,-length*.36+i*.66,-.4)*CFrame.Angles(0,0,side*.3),hair) end
                end
            end
            oval("Hair back fall",Vector3.new(2.0,length,.62),CFrame.new(0,4.66-length*.39,.96),hair)
        end
    end
    if teacher.beard then
        local beard=rgb(teacher.beard)
        local long=isBolich
        for i=0,6 do
            local x=-.78+i*.26
            local drop=long and (.45+.25*(1-math.abs(x))) or .12
            oval("Layered beard lock",Vector3.new(.40,long and .92 or .45,.39),CFrame.new(x,3.42-drop*.35,-.88),beard)
            if long then
                for j=0,1 do oval("Beard strand",Vector3.new(.045,.56,.065),CFrame.new(x-.08+j*.13,3.25-drop*.3,-1.07)*CFrame.Angles(0,0,x*.15),beard:Lerp(WHITE,.25)) end
            end
        end
        for _,side in ipairs({-1,1}) do oval("Swept moustache",Vector3.new(.48,.18,.18),CFrame.new(side*.22,3.985,-1.09)*CFrame.Angles(0,0,side*.2),beard) end
    end

    local jacket=formal or clothes=="cardigan" or clothes=="vest"
    if jacket then
        box("Shirt inset",Vector3.new(1.1,2.45,.09),CFrame.new(0,1.72,-.862),accent,nil,Enum.Material.Fabric)
        for _,side in ipairs({-1,1}) do
            box("Tailored jacket panel",Vector3.new(1.0,2.62,.15),CFrame.new(side*1.03,1.46,-.9),shirt,nil,Enum.Material.Fabric)
            box("Notched jacket lapel",Vector3.new(.46,1.18,.12),CFrame.new(side*.65,2.35,-1.005)*CFrame.Angles(0,0,side*-.30),shirt:Lerp(WHITE,.06),nil,Enum.Material.Fabric)
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
            for i=-4,4 do box("Polo woven vertical check",Vector3.new(.015,2.55,.02),CFrame.new(i*.31,1.45,-.852),shirt:Lerp(WHITE,.11)) end
            for i=0,7 do box("Polo woven horizontal check",Vector3.new(2.92,.015,.02),CFrame.new(0,.30+i*.33,-.854),shirt:Lerp(WHITE,.11)) end
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
        box(side<0 and "Left Arm" or "Right Arm",Vector3.new(1.03,2.65,1.40),CFrame.new(x,1.58,0),short and skin or shirt,armGroup,short and Enum.Material.SmoothPlastic or Enum.Material.Fabric)
        box("Sleeve shoulder",Vector3.new(1.09,short and 1.13 or 2.05,1.46),CFrame.new(x,short and 2.31 or 1.85,0),shirt,armGroup,Enum.Material.Fabric)
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
        box(side<0 and "Left Leg" or "Right Leg",Vector3.new(1.36,2.77,1.48),CFrame.new(lx,-1.47,0),pants,legGroup,Enum.Material.Fabric)
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
    local nameGui=Instance.new("BillboardGui");nameGui.Name="TeacherName";nameGui.Size=UDim2.fromOffset(190,42)
    nameGui.StudsOffset=Vector3.new(0,6.25,0);nameGui.AlwaysOnTop=false;nameGui.MaxDistance=45;nameGui.Parent=root
    local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=GREEN;label.BackgroundTransparency=.08
    label.TextColor3=GOLD;label.TextScaled=true;label.Text=teacher.fullName or teacher.name;label.Font=Enum.Font.GothamBold;label.Parent=nameGui
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
