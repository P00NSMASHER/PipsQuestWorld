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
    model.Name=teacher.name;model:SetAttribute("StaffGeometryVersion",5)
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
    hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.BreakJointsOnDeath=false;hum.AutomaticScalingEnabled=false;hum.Parent=model
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
    -- Use the engine's standard rig attachment alignment before taking the rest
    -- pose. No procedural skulls, separate eyeballs, ears, teeth, or hair caps.
    hum:BuildRigFromAttachments()
    if teacher.hairStyle~="balding" then
        local hairName=male and (teacher.name=="Mr. Yordy" and "BrownHair" or "ShortHair") or (teacher.hairStyle=="short" and "BunHair" or "LongHair")
        local accessory=assets:WaitForChild(hairName):Clone();accessory.Parent=model
        local handle=accessory:FindFirstChild("Handle")
        local attachment=handle and handle:FindFirstChild("HairAttachment")
        if handle and attachment then
            handle.CFrame=head.CFrame*head.HairAttachment.CFrame*attachment.CFrame:Inverse()
            local mesh=handle:FindFirstChildOfClass("SpecialMesh")
            -- The blonde texture is light enough to tint darker hair naturally.
            if mesh and hairName=="LongHair" then mesh.VertexColor=rgb(teacher.hair) end
            if mesh and teacher.name=="Dr. McBreen" then mesh.TextureId="";mesh.VertexColor=rgb(teacher.hair) end
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

function StaffModel.pose(model,phase,walking)
    local pivot=model:GetPivot();local scale=model:GetScale();local shift=model:GetAttribute("PoseShift") or 0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part~=model.PrimaryPart then
            local rest=part:GetAttribute("RestCF");local group=part:GetAttribute("PoseGroup")
            local transform=CFrame.new()
            if group then
                local arm=string.find(group,"Arm")~=nil;local left=string.find(group,"left")~=nil
                local origin=Vector3.new((left and -1 or 1)*(arm and 1 or .5)*scale,(arm and .763 or -1)*scale+shift,0)
                local swing=walking and math.sin(phase)*.28 or 0
                if not left then swing=-swing end
                if not arm then swing=-swing end
                transform=CFrame.new(origin)*CFrame.Angles(swing,0,0)*CFrame.new(origin*-1)
            end
            if rest then part.CFrame=pivot*transform*rest end
        end
    end
end
return StaffModel
