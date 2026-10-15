--!strict
-- Standard Roblox R15 Man/Woman meshes and verified Roblox-made accessories.
-- Visual models are bundled with the place: creating a teacher never waits on
-- the catalog, InsertService, or an avatar service request.
local StaffModel={}
local assets=script.Parent:WaitForChild("StaffAssets")
local SCALE=.94
local FLOOR_RELATIVE=-2.67
local GREEN=Color3.fromRGB(25,70,51)
local GOLD=Color3.fromRGB(244,207,102)
local function rgb(c) return Color3.fromRGB(c[1],c[2],c[3]) end
local function isMale(teacher) return string.sub(teacher.name,1,3)=="Mr." or string.sub(teacher.name,1,3)=="Dr." end

function StaffModel.create(teacher,scaleOverride:number?)
    local male=isMale(teacher)
    local model=assets:WaitForChild(male and "Man" or "Woman"):Clone()
    model.Name=teacher.name;model:SetAttribute("StaffGeometryVersion",10)
    model:SetAttribute("AppearanceProfile",teacher.appearanceId or "standard_staff")
    if teacher.appearanceId=="benulis_2026_portrait" then
        -- The bundled Woman body is a narrow stylized R15 package. At the
        -- classroom's mobile camera distance its tapered arms read as sticks
        -- and its tiny hands can inherit the sleeve tint. Replace only Mrs.
        -- Benulis's body pieces with a conventional, friendly Roblox block
        -- silhouette. The avatar stays a lightweight static Humanoid model.
        local classicParts={
            {"UpperTorso",Vector3.new(1.80,1.50,.85),CFrame.new(0,.25,0)},
            {"LowerTorso",Vector3.new(1.55,.60,.80),CFrame.new(0,-.72,0)},
            {"LeftUpperArm",Vector3.new(.58,1.15,.58),CFrame.new(-1.18,.15,0)},
            {"LeftLowerArm",Vector3.new(.55,1.00,.55),CFrame.new(-1.18,-.90,0)},
            {"LeftHand",Vector3.new(.58,.45,.58),CFrame.new(-1.18,-1.60,0)},
            {"RightUpperArm",Vector3.new(.58,1.15,.58),CFrame.new(1.18,.15,0)},
            {"RightLowerArm",Vector3.new(.55,1.00,.55),CFrame.new(1.18,-.90,0)},
            {"RightHand",Vector3.new(.58,.45,.58),CFrame.new(1.18,-1.60,0)},
            {"LeftUpperLeg",Vector3.new(.72,1.25,.72),CFrame.new(-.42,-1.60,0)},
            {"LeftLowerLeg",Vector3.new(.66,1.20,.66),CFrame.new(-.42,-2.62,0)},
            {"LeftFoot",Vector3.new(.72,.45,1.00),CFrame.new(-.42,-3.35,-.12)},
            {"RightUpperLeg",Vector3.new(.72,1.25,.72),CFrame.new(.42,-1.60,0)},
            {"RightLowerLeg",Vector3.new(.66,1.20,.66),CFrame.new(.42,-2.62,0)},
            {"RightFoot",Vector3.new(.72,.45,1.00),CFrame.new(.42,-3.35,-.12)},
        }
        for _,spec in ipairs(classicParts) do
            local old=model:FindFirstChild(spec[1])
            assert(old and old:IsA("BasePart"),"Missing bundled body part "..spec[1])
            old:Destroy()
            local block=Instance.new("Part")
            block.Name=spec[1];block.Size=spec[2];block.CFrame=spec[3]
            block.Material=Enum.Material.SmoothPlastic
            block.TopSurface=Enum.SurfaceType.Smooth
            block.BottomSurface=Enum.SurfaceType.Smooth
            block.Parent=model
        end
        model:SetAttribute("BodySilhouette","classic_block_avatar")
    end
    local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(2,2,1)
    root.Transparency=1;root.CFrame=CFrame.new();root.Parent=model;model.PrimaryPart=root
    local rootAttachment=Instance.new("Attachment");rootAttachment.Name="RootRigAttachment";rootAttachment.CFrame=CFrame.new(0,-1,0);rootAttachment.Parent=root
    local head=Instance.new("Part");head.Name="Head";head.Size=Vector3.new(2,1,1);head.CFrame=CFrame.new(0,1.5,0);head.Color=rgb(teacher.skin);head.Parent=model
    local shape=Instance.new("SpecialMesh");shape.Name="Standard Roblox head";shape.MeshType=Enum.MeshType.Head
    shape.Scale=(teacher.appearanceId=="benulis_2026_portrait") and Vector3.new(1.06,1.06,1.06) or Vector3.new(1.25,1.25,1.25)
    shape.Parent=head
    for name,cf in pairs({NeckRigAttachment=CFrame.new(0,-.5,0),HairAttachment=CFrame.new(0,.6,0),HatAttachment=CFrame.new(0,.6,0)}) do
        local a=Instance.new("Attachment");a.Name=name;a.CFrame=cf;a.Parent=head
    end
    local face
    if male then
        face=Instance.new("Decal");face.Name="face";face.Face=Enum.NormalId.Front;face.Texture="rbxasset://textures/face.png"
    else
        face=assets:WaitForChild("WomanFace"):Clone();face.Name="face"
        if teacher.appearanceId=="benulis_2026_portrait" then
            -- Use Roblox's familiar friendly default expression. The prior
            -- catalog face stretched badly on this bundled head mesh.
            face.Texture="rbxasset://textures/face.png"
            model:SetAttribute("PortraitAvatarRefinement","v10_classic_block_body_friendly_face_navy_sweater")
        end
    end
    face.Parent=head

    local hum=Instance.new("Humanoid");hum.Name="Humanoid";hum.RigType=Enum.HumanoidRigType.R15
    hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.BreakJointsOnDeath=false;hum.AutomaticScalingEnabled=false;hum.AutoRotate=false;hum.RequiresNeck=false;hum.EvaluateStateMachine=false;hum.Parent=model
    local shirt=assets:WaitForChild((teacher.name=="Mrs. Thompson" and "DenimJacket") or ((teacher.clothing=="pattern" or teacher.clothing=="floral" or teacher.clothing=="striped") and "PatternShirt" or "Jacket")):Clone()
    if teacher.appearanceId=="benulis_2026_portrait" and shirt:IsA("Shirt") then
        -- Let the fitted navy R15 body and authored V-neck trim show instead
        -- of layering the generic black staff jacket over the portrait outfit.
        shirt.ShirtTemplate=""
    end
    shirt.Parent=model
    local pants=assets:WaitForChild("Jeans"):Clone();pants.Parent=model
    local skin=rgb(teacher.skin)
    for _,part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            part.Color=skin
            if part.Name=="UpperTorso" or string.find(part.Name,"Arm") then part.Color=rgb(teacher.shirt) end
            if part.Name=="LowerTorso" or string.find(part.Name,"Leg") then part.Color=teacher.pants and rgb(teacher.pants) or Color3.fromRGB(48,51,60) end
            if string.find(part.Name,"Foot") then part.Color=Color3.fromRGB(38,39,44) end
        end
    end
    local bodyColors=Instance.new("BodyColors");bodyColors.HeadColor3=skin;bodyColors.LeftArmColor3=skin;bodyColors.RightArmColor3=skin
    bodyColors.TorsoColor3=skin;bodyColors.LeftLegColor3=skin;bodyColors.RightLegColor3=skin
    if teacher.appearanceId=="benulis_2026_portrait" then
        -- BodyColors paints an entire arm one color, including its hand. Her
        -- block body uses the explicit sleeve/skin palette below instead.
        bodyColors:Destroy()
    else
        bodyColors.Parent=model
    end
    -- BodyColors applies again when parented and was overwriting Mrs.
    -- Benulis's authored navy sweater with the skin tone. Reassert the final
    -- per-part palette after parenting: long navy sleeves, skin hands/face,
    -- charcoal trousers and dark shoes.
    if teacher.appearanceId=="benulis_2026_portrait" then
        for _,bodyPart in ipairs(model:GetChildren()) do
            if bodyPart:IsA("BasePart") then
                if bodyPart.Name=="UpperTorso"
                    or string.find(bodyPart.Name,"UpperArm")
                    or string.find(bodyPart.Name,"LowerArm") then
                    bodyPart.Color=rgb(teacher.shirt)
                elseif bodyPart.Name=="Head" or string.find(bodyPart.Name,"Hand") then
                    bodyPart.Color=skin
                elseif bodyPart.Name=="LowerTorso" or string.find(bodyPart.Name,"Leg") then
                    bodyPart.Color=rgb(teacher.pants)
                elseif string.find(bodyPart.Name,"Foot") then
                    bodyPart.Color=Color3.fromRGB(38,39,44)
                end
            end
        end
    end
    -- Bundled limbs already have an aligned rest pose. Do not create Motor6D
    -- or AnimationConstraint joints on an anchored display avatar: those engine
    -- transforms would compete with PivotTo/rest transforms and detach the head.
    for _,d in ipairs(model:GetDescendants()) do
        if d:IsA("JointInstance") or d:IsA("Constraint") then d:Destroy() end
    end
    if teacher.hairStyle~="balding" then
        local hairName=male and (teacher.name=="Mr. Yordy" and "BrownHair" or "ShortHair") or ((teacher.hairStyle=="short" or teacher.hairStyle=="bob") and "BunHair" or "LongHair")
        local accessory=assets:WaitForChild(hairName):Clone();accessory.Parent=model
        local handle=accessory:FindFirstChild("Handle")
        -- Hair is a single rigid piece of the head during procedural gait.
        -- It must inherit head yaw rather than stay behind as a floating prop.
        if handle then handle:SetAttribute("PoseGroup","head") end
        local attachment=handle and handle:FindFirstChild("HairAttachment")
        if handle and attachment then
            handle.CFrame=head.CFrame*head.HairAttachment.CFrame*attachment.CFrame:Inverse()
            local mesh=handle:FindFirstChildOfClass("SpecialMesh")
            -- Keep the real catalog texture (highlights, strands, shadows).
            -- Stripping TextureId turned almost every hairstyle into a flat
            -- plastic-looking silhouette. Tint gently so the texture survives.
            if mesh then
                local tint=rgb(teacher.hair):Lerp(Color3.new(1,1,1),.30)
                -- SpecialMesh.VertexColor is Vector3, NOT Color3. Passing
                -- Color3 throws at runtime and silently drops the whole NPC.
                mesh.VertexColor=Vector3.new(tint.R,tint.G,tint.B)
                if teacher.appearanceId=="benulis_2026_portrait" then
                    mesh.Scale=mesh.Scale*.84
                    mesh.Offset=mesh.Offset+Vector3.new(0,.04,.03)
                    -- Preserve strand shading while making the old blond
                    -- catalog texture read as the portrait's warm brown.
                    handle.Color=rgb(teacher.hair)
                    local brown=rgb(teacher.hair):Lerp(Color3.new(1,1,1),.08)
                    mesh.VertexColor=Vector3.new(brown.R,brown.G,brown.B)
                end
            end
        end
    end
    -- Accessories use familiar small proportions rather than giant facial parts.
    if teacher.glasses then
        local function bar(name,size,cf)
            local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=head.CFrame*cf;p.Color=Color3.fromRGB(29,27,30);p.Parent=model
            p:SetAttribute("PoseGroup","head")
        end
        for _,x in ipairs({-.30,.30}) do
            bar("Glasses top",Vector3.new(.48,.035,.035),CFrame.new(x,.13,-.64))
            bar("Glasses bottom",Vector3.new(.48,.035,.035),CFrame.new(x,-.11,-.64))
            for _,side in ipairs({-1,1}) do bar("Glasses side",Vector3.new(.035,.24,.035),CFrame.new(x+side*.24,.01,-.64)) end
        end
        bar("Glasses bridge",Vector3.new(.13,.035,.035),CFrame.new(0,.06,-.64))
    end
    -- Clothing details follow the existing official R15 torso meshes, not a
    -- procedural replacement head or a block-body avatar.
    local upper=model:FindFirstChild("UpperTorso")
    if upper and upper:IsA("BasePart") then
        local function stitch(name,size,offset,color)
            local p=Instance.new("Part")
            p.Name=name;p.Size=size;p.CFrame=upper.CFrame*offset
            p.Color=color;p.Material=Enum.Material.SmoothPlastic
            p.Parent=model
            return p
        end
        local dark=Color3.fromRGB(29,52,69)
        local warm=Color3.fromRGB(235,223,200)
        if teacher.clothing=="vneck_sweater" then
            -- Mrs. Benulis' supplied portrait: fitted navy V-neck knit over
            -- charcoal trousers. The crossed trim leaves a clean skin-toned V
            -- instead of reading as the generic buttoned staff cardigan.
            local navy=rgb(teacher.shirt)
            stitch("V-neck left rib",Vector3.new(.12,.72,.055),CFrame.new(-.22,.34,-.585)*CFrame.Angles(0,0,math.rad(-34)),navy:Lerp(Color3.new(1,1,1),.10))
            stitch("V-neck right rib",Vector3.new(.12,.72,.055),CFrame.new(.22,.34,-.585)*CFrame.Angles(0,0,math.rad(34)),navy:Lerp(Color3.new(1,1,1),.10))
            stitch("Sweater lower rib",Vector3.new(1.62,.16,.055),CFrame.new(0,-.79,-.57),navy:Lerp(Color3.new(0,0,0),.12))

            -- Fine necklace and open teardrop pendant from the portrait.
            local gold=Color3.fromRGB(218,174,91)
            stitch("Necklace left",Vector3.new(.035,.72,.035),CFrame.new(-.18,.29,-.645)*CFrame.Angles(0,0,math.rad(-25)),gold)
            stitch("Necklace right",Vector3.new(.035,.72,.035),CFrame.new(.18,.29,-.645)*CFrame.Angles(0,0,math.rad(25)),gold)
            local pendant=stitch("Teardrop pendant",Vector3.new(.17,.23,.055),CFrame.new(0,-.05,-.68)*CFrame.Angles(0,0,math.rad(45)),gold)
            local inset=Instance.new("Part");inset.Name="Pendant inset";inset.Shape=Enum.PartType.Ball
            inset.Size=Vector3.new(.095,.095,.035);inset.CFrame=pendant.CFrame*CFrame.new(0,0,-.035)
            inset.Color=skin;inset.Material=Enum.Material.SmoothPlastic;inset.Parent=model
        elseif teacher.clothing=="suit" then
            -- Principal: jacket lapels, tie and knot at ordinary avatar scale.
            stitch("Jacket lapel left",Vector3.new(.17,.70,.045),CFrame.new(-.38,.12,-.54)*CFrame.Angles(0,0,math.rad(-17)),warm)
            stitch("Jacket lapel right",Vector3.new(.17,.70,.045),CFrame.new(.38,.12,-.54)*CFrame.Angles(0,0,math.rad(17)),warm)
            stitch("Navy tie",Vector3.new(.19,.66,.06),CFrame.new(0,.05,-.62),dark)
            stitch("Tie knot",Vector3.new(.28,.18,.07),CFrame.new(0,.48,-.64),Color3.fromRGB(79,117,142))
        elseif teacher.clothing=="cardigan" or teacher.clothing=="blazer" then
            stitch("Cardigan seam",Vector3.new(.045,.83,.045),CFrame.new(0,-.17,-.58),warm)
            for _,y in ipairs({-.4,-.15,.10}) do
                stitch("Cardigan button",Vector3.new(.10,.10,.05),CFrame.new(0,y,-.62),Color3.fromRGB(192,169,123))
            end
        elseif teacher.clothing=="polo" then
            stitch("Polo collar left",Vector3.new(.32,.14,.05),CFrame.new(-.23,.57,-.52)*CFrame.Angles(0,0,math.rad(14)),warm)
            stitch("Polo collar right",Vector3.new(.32,.14,.05),CFrame.new(.23,.57,-.52)*CFrame.Angles(0,0,math.rad(-14)),warm)
        end
    end
    if teacher.jewelry=="gold_hoops_pendant" then
        -- Small segmented hoops are readable from the study camera without
        -- becoming oversized costume jewelry. They follow the head idle pose.
        local gold=Color3.fromRGB(221,177,88)
        for _,side in ipairs({-1,1}) do
            for segment=0,7 do
                local angle=(segment/8)*math.pi*2
                local earring=Instance.new("Part")
                earring.Name="Gold hoop earring"
                earring.Shape=Enum.PartType.Ball
                earring.Size=Vector3.new(.055,.055,.055)
                earring.CFrame=head.CFrame*CFrame.new(side*.64,-.18+math.sin(angle)*.15,-.02+math.cos(angle)*.15)
                earring.Color=gold;earring.Material=Enum.Material.Metal
                earring:SetAttribute("PoseGroup","head");earring.Parent=model
            end
        end
    end
    -- Staff badge remains a small world-space name, never a screen-sized banner.
    local label=Instance.new("BillboardGui");label.Name="TeacherName";label.Size=UDim2.fromScale(4.2,.5);label.StudsOffset=Vector3.new(0,3.25,0)
    label.AlwaysOnTop=false;label.MaxDistance=28;label.Parent=root
    local name=Instance.new("TextLabel");name.Name="Staff badge";name.Size=UDim2.fromScale(1,1);name.BackgroundColor3=GREEN;name.BackgroundTransparency=.08
    name.Text=teacher.name;name.TextColor3=GOLD;name.TextScaled=true;name.Font=Enum.Font.GothamBold;name.Parent=label
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,8);corner.Parent=name
    local speech=Instance.new("BillboardGui");speech.Name="Speech";speech.Enabled=false;speech.Parent=root
    local speechText=Instance.new("TextLabel");speechText.Name="Text";speechText.Parent=speech

    -- Apply any showroom-only adult scale before floor alignment and before
    -- immutable pose frames are captured. Scaling a finished posed model at
    -- server startup can leave its cached transforms inconsistent.
    model:ScaleTo(scaleOverride or SCALE)
    local lowest=math.huge
    for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") and string.find(p.Name,"Foot") then lowest=math.min(lowest,p.Position.Y-p.Size.Y/2) end end
    local shift=FLOOR_RELATIVE-lowest
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true
            if p~=root then p.CFrame=CFrame.new(0,shift,0)*p.CFrame end
            p:SetAttribute("RestCF",root.CFrame:Inverse()*p.CFrame)
            if p==head then p:SetAttribute("PoseGroup","head") end
            local side=string.find(p.Name,"Left") and "left" or (string.find(p.Name,"Right") and "right" or nil)
            if side and (string.find(p.Name,"Arm") or string.find(p.Name,"Hand")) then p:SetAttribute("PoseGroup",side.."Arm") end
            if side and (string.find(p.Name,"Leg") or string.find(p.Name,"Foot")) then p:SetAttribute("PoseGroup",side.."Leg") end
        end
    end
    model:SetAttribute("PoseShift",shift)
    return model
end

-- Native R15 mesh display pose: every moving head-adjacent prop uses the same
-- neck transform. Still requires Roblox runtime verification before a release.
-- Immutable rest poses prevent drift after many arrivals and departures.
-- This is built from the existing licensed/native avatar meshes rather than
-- primitive replacement limbs or uncontrolled humanoid animations.
function StaffModel.pose(model,phase,walking)
    local pivot=model:GetPivot()
    local swing=walking and math.sin(phase*.46)*.23 or math.sin(phase*1.1)*.025
    local armRoll=walking and math.sin(phase*.23)*.045 or math.sin(phase*.7)*.017
    local neck=Vector3.new(0,1.05,0)
    local yaw=walking and math.sin(phase*.20)*.025 or math.sin(phase*.65)*.050
    local headTurn=CFrame.new(neck)*CFrame.Angles(0,yaw,0)*CFrame.new(neck*-1)
    local function joint(group)
        local shoulder=(group=="leftArm" or group=="rightArm")
        local side=(group=="leftArm" or group=="leftLeg") and -1 or 1
        local classic=model:GetAttribute("BodySilhouette")=="classic_block_avatar"
        local anchor
        if classic then
            -- The block avatar is floor-aligned farther above its root than
            -- the bundled narrow Woman mesh. Pivot at its visible shoulders
            -- and hips so arms swing as one normal limb instead of twisting
            -- around the waist.
            anchor=shoulder and Vector3.new(side*1.00,1.20,0)
                or Vector3.new(side*.42,-.20,0)
        else
            anchor=shoulder and Vector3.new(side*.85,.78,0)
                or Vector3.new(side*.48,-1.0,0)
        end
        local angle=shoulder and -side*swing or side*swing
        local tilt=shoulder and side*armRoll or 0
        return CFrame.new(anchor)*CFrame.Angles(angle,0,tilt)*CFrame.new(anchor*-1)
    end
    local joints={
        leftArm=joint("leftArm"),rightArm=joint("rightArm"),
        leftLeg=joint("leftLeg"),rightLeg=joint("rightLeg"),head=headTurn
    }
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part~=model.PrimaryPart then
            local rest=part:GetAttribute("RestCF")
            if rest then
                local group=part:GetAttribute("PoseGroup")
                part.CFrame=pivot*(joints[group] or CFrame.new())*rest
            end
        end
    end
end
return StaffModel
