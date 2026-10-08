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

function StaffModel.create(teacher)
    local male=isMale(teacher)
    local model=assets:WaitForChild(male and "Man" or "Woman"):Clone()
    model.Name=teacher.name;model:SetAttribute("StaffGeometryVersion",6)
    local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(2,2,1)
    root.Transparency=1;root.CFrame=CFrame.new();root.Parent=model;model.PrimaryPart=root
    local rootAttachment=Instance.new("Attachment");rootAttachment.Name="RootRigAttachment";rootAttachment.CFrame=CFrame.new(0,-1,0);rootAttachment.Parent=root
    local head=Instance.new("Part");head.Name="Head";head.Size=Vector3.new(2,1,1);head.CFrame=CFrame.new(0,1.5,0);head.Color=rgb(teacher.skin);head.Parent=model
    local shape=Instance.new("SpecialMesh");shape.Name="Standard Roblox head";shape.MeshType=Enum.MeshType.Head;shape.Scale=Vector3.new(1.25,1.25,1.25);shape.Parent=head
    for name,cf in pairs({NeckRigAttachment=CFrame.new(0,-.5,0),HairAttachment=CFrame.new(0,.6,0),HatAttachment=CFrame.new(0,.6,0)}) do
        local a=Instance.new("Attachment");a.Name=name;a.CFrame=cf;a.Parent=head
    end
    local face
    if male then
        face=Instance.new("Decal");face.Name="face";face.Face=Enum.NormalId.Front;face.Texture="rbxasset://textures/face.png"
    else face=assets:WaitForChild("WomanFace"):Clone();face.Name="face" end
    face.Parent=head

    local hum=Instance.new("Humanoid");hum.Name="Humanoid";hum.RigType=Enum.HumanoidRigType.R15
    hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.BreakJointsOnDeath=false;hum.AutomaticScalingEnabled=false;hum.AutoRotate=false;hum.RequiresNeck=false;hum.EvaluateStateMachine=false;hum.Parent=model
    local shirt=assets:WaitForChild((teacher.name=="Mrs. Thompson" and "DenimJacket") or ((teacher.clothing=="pattern" or teacher.clothing=="floral" or teacher.clothing=="striped") and "PatternShirt" or "Jacket")):Clone();shirt.Parent=model
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
    bodyColors.TorsoColor3=skin;bodyColors.LeftLegColor3=skin;bodyColors.RightLegColor3=skin;bodyColors.Parent=model
    -- Bundled limbs already have an aligned rest pose. Do not create Motor6D
    -- or AnimationConstraint joints on an anchored display avatar: those engine
    -- transforms would compete with PivotTo/rest transforms and detach the head.
    for _,d in ipairs(model:GetDescendants()) do
        if d:IsA("JointInstance") or d:IsA("Constraint") then d:Destroy() end
    end
    if teacher.hairStyle~="balding" then
        local hairName=male and (teacher.name=="Mr. Yordy" and "BrownHair" or "ShortHair") or (teacher.hairStyle=="short" and "BunHair" or "LongHair")
        local accessory=assets:WaitForChild(hairName):Clone();accessory.Parent=model
        local handle=accessory:FindFirstChild("Handle")
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
            end
        end
    end
    -- Accessories use familiar small proportions rather than giant facial parts.
    if teacher.glasses then
        local function bar(name,size,cf)
            local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=head.CFrame*cf;p.Color=Color3.fromRGB(29,27,30);p.Parent=model
        end
        for _,x in ipairs({-.30,.30}) do
            bar("Glasses top",Vector3.new(.48,.035,.035),CFrame.new(x,.13,-.64))
            bar("Glasses bottom",Vector3.new(.48,.035,.035),CFrame.new(x,-.11,-.64))
            for _,side in ipairs({-1,1}) do bar("Glasses side",Vector3.new(.035,.24,.035),CFrame.new(x+side*.24,.01,-.64)) end
        end
        bar("Glasses bridge",Vector3.new(.13,.035,.035),CFrame.new(0,.06,-.64))
    end
    -- Staff badge remains a small world-space name, never a screen-sized banner.
    local label=Instance.new("BillboardGui");label.Name="TeacherName";label.Size=UDim2.fromScale(4.2,.5);label.StudsOffset=Vector3.new(0,3.25,0)
    label.AlwaysOnTop=false;label.MaxDistance=28;label.Parent=root
    local name=Instance.new("TextLabel");name.Name="Staff badge";name.Size=UDim2.fromScale(1,1);name.BackgroundColor3=GREEN;name.BackgroundTransparency=.08
    name.Text=teacher.name;name.TextColor3=GOLD;name.TextScaled=true;name.Font=Enum.Font.GothamBold;name.Parent=label
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,8);corner.Parent=name
    local speech=Instance.new("BillboardGui");speech.Name="Speech";speech.Enabled=false;speech.Parent=root
    local speechText=Instance.new("TextLabel");speechText.Name="Text";speechText.Parent=speech

    model:ScaleTo(SCALE)
    local lowest=math.huge
    for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") and string.find(p.Name,"Foot") then lowest=math.min(lowest,p.Position.Y-p.Size.Y/2) end end
    local shift=FLOOR_RELATIVE-lowest
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true
            if p~=root then p.CFrame=CFrame.new(0,shift,0)*p.CFrame end
            p:SetAttribute("RestCF",root.CFrame:Inverse()*p.CFrame)
            local side=string.find(p.Name,"Left") and "left" or (string.find(p.Name,"Right") and "right" or nil)
            if side and (string.find(p.Name,"Arm") or string.find(p.Name,"Hand")) then p:SetAttribute("PoseGroup",side.."Arm") end
            if side and (string.find(p.Name,"Leg") or string.find(p.Name,"Foot")) then p:SetAttribute("PoseGroup",side.."Leg") end
        end
    end
    model:SetAttribute("PoseShift",shift)
    return model
end

-- Articulated display gait without new engine rig joints. Bundled R15 mesh
-- limbs stay connected as groups, including their hands and feet. The rest
-- pose remains the single immutable authority; poses never accumulate drift.
-- This is built from the existing licensed/native avatar meshes rather than
-- primitive replacement limbs or uncontrolled humanoid animations.
function StaffModel.pose(model,phase,walking)
    local pivot=model:GetPivot()
    local swing=walking and math.sin(phase*.46)*.23 or 0
    local armRoll=walking and math.sin(phase*.23)*.045 or 0
    local function joint(group)
        local shoulder=(group=="leftArm" or group=="rightArm")
        local side=(group=="leftArm" or group=="leftLeg") and -1 or 1
        local anchor=shoulder and Vector3.new(side*.85,.78,0) or Vector3.new(side*.48,-1.0,0)
        local angle=shoulder and -side*swing or side*swing
        local tilt=shoulder and side*armRoll or 0
        return CFrame.new(anchor)*CFrame.Angles(angle,0,tilt)*CFrame.new(anchor*-1)
    end
    local joints={
        leftArm=joint("leftArm"),rightArm=joint("rightArm"),
        leftLeg=joint("leftLeg"),rightLeg=joint("rightLeg")
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
