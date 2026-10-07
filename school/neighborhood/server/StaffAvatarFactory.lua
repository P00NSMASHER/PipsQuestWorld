--!strict
-- Canonical faculty NPC constructor.
-- The factory deliberately favors simple Roblox-native likeness cues over photo reconstruction.
-- Only staff records with avatar.prototype=true receive the enhanced prototype treatment.
local Factory={}

local DEFAULT_SKIN=Color3.fromRGB(226,196,164)
local DEFAULT_HAIR=Color3.fromRGB(95,75,60)
local DEFAULT_TOP=Color3.fromRGB(80,112,145)
local INK=Color3.fromRGB(35,40,46)
local NAVY=Color3.fromRGB(22,45,79)
local GOLD=Color3.fromRGB(223,177,60)
local CREAM=Color3.fromRGB(239,234,221)

local function rgb(value,fallback)
    if type(value)=="table" and #value>=3 then
        return Color3.fromRGB(value[1],value[2],value[3])
    end
    return fallback
end

local function part(parent,name,size,cf,tint,material)
    local p=Instance.new("Part")
    p.Name=name
    p.Size=size
    p.CFrame=cf
    p.Color=tint
    p.Anchored=true
    p.CanCollide=false
    p.CanTouch=false
    p.CanQuery=false
    p.Material=material or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end

local function ball(parent,name,size,cf,tint)
    local p=part(parent,name,size,cf,tint,Enum.Material.SmoothPlastic)
    p.Shape=Enum.PartType.Ball
    return p
end

local function simpleFace(model,position,skin,prototype)
    local eyeY=prototype and 8.06 or 8.04
    local eyeZ=prototype and -1.11 or -1.10
    local eyeSize=prototype and Vector3.new(.20,.25,.08) or Vector3.new(.22,.27,.09)
    for _,entry in ipairs({
        {"Simple left eye",-.43},
        {"Simple right eye",.43},
    }) do
        ball(model,entry[1],eyeSize,CFrame.new(position+Vector3.new(entry[2],eyeY,eyeZ)),INK)
    end

    local smileWidth=prototype and .64 or .70
    part(
        model,
        "Simple smile",
        Vector3.new(smileWidth,.11,.07),
        CFrame.new(position+Vector3.new(0,7.40,-1.11))*CFrame.Angles(0,0,math.rad(-2)),
        Color3.fromRGB(139,84,84)
    )

    if prototype then
        -- One tiny bridge/nose cue gives the face depth without drifting back toward uncanny reconstruction.
        ball(model,"Simple nose",Vector3.new(.16,.22,.12),CFrame.new(position+Vector3.new(0,7.72,-1.07)),skin:Lerp(Color3.fromRGB(190,145,122),.08))
    end
end

local function addHair(model,position,hair,style,detail)
    local function hairPart(name,size,offset,shape)
        local p=part(model,name,size,CFrame.new(position+offset),hair,Enum.Material.SmoothPlastic)
        if shape then p.Shape=shape end
        return p
    end

    if detail=="sidePart" then
        hairPart("Prototype hair crown",Vector3.new(2.28,.72,2.02),Vector3.new(0,8.72,.18),Enum.PartType.Ball)
        hairPart("Prototype side sweep",Vector3.new(1.30,.46,1.55),Vector3.new(-.48,8.78,-.34),Enum.PartType.Ball)
        hairPart("Prototype left temple",Vector3.new(.42,1.18,1.20),Vector3.new(-1.02,8.18,.18),Enum.PartType.Ball)
        hairPart("Prototype right temple",Vector3.new(.38,1.05,1.10),Vector3.new(1.03,8.22,.20),Enum.PartType.Ball)
        return
    elseif detail=="softBob" then
        hairPart("Prototype bob crown",Vector3.new(2.48,1.05,2.26),Vector3.new(0,8.66,.10),Enum.PartType.Ball)
        hairPart("Prototype bob left",Vector3.new(.76,2.92,1.34),Vector3.new(-1.08,7.42,.16),Enum.PartType.Ball)
        hairPart("Prototype bob right",Vector3.new(.76,2.92,1.34),Vector3.new(1.08,7.42,.16),Enum.PartType.Ball)
        hairPart("Prototype bob back",Vector3.new(2.08,2.32,.82),Vector3.new(0,7.50,.87),Enum.PartType.Ball)
        return
    elseif detail=="balding" then
        hairPart("Prototype hair back",Vector3.new(2.02,1.05,.52),Vector3.new(0,8.16,.96),Enum.PartType.Ball)
        hairPart("Prototype temple left",Vector3.new(.43,1.14,.78),Vector3.new(-1.00,8.20,.35),Enum.PartType.Ball)
        hairPart("Prototype temple right",Vector3.new(.43,1.14,.78),Vector3.new(1.00,8.20,.35),Enum.PartType.Ball)
        hairPart("Prototype crown wisp",Vector3.new(1.15,.28,1.18),Vector3.new(-.18,8.76,.22),Enum.PartType.Ball)
        return
    end

    if style=="balding" then
        hairPart("Hair crown",Vector3.new(1.75,.62,1.9),Vector3.new(0,8.72,.28),Enum.PartType.Ball)
        hairPart("Hair back",Vector3.new(2.05,1.2,.55),Vector3.new(0,8.14,1.02),Enum.PartType.Ball)
        hairPart("Hair temple left",Vector3.new(.42,.95,.75),Vector3.new(-1.02,8.22,.45),Enum.PartType.Ball)
        hairPart("Hair temple right",Vector3.new(.42,.95,.75),Vector3.new(1.02,8.22,.45),Enum.PartType.Ball)
        return
    end

    hairPart("Hair crown",Vector3.new(2.48,1.12,2.36),Vector3.new(0,8.68,.10),Enum.PartType.Ball)
    if style=="short" then
        hairPart("Hair side left",Vector3.new(.42,1.35,1.55),Vector3.new(-1.08,8.05,.15),Enum.PartType.Ball)
        hairPart("Hair side right",Vector3.new(.42,1.35,1.55),Vector3.new(1.08,8.05,.15),Enum.PartType.Ball)
    elseif style=="pulledBack" then
        hairPart("Hair side left",Vector3.new(.5,2.1,1.35),Vector3.new(-1.03,7.75,.2),Enum.PartType.Ball)
        hairPart("Hair side right",Vector3.new(.5,2.1,1.35),Vector3.new(1.03,7.75,.2),Enum.PartType.Ball)
        hairPart("Ponytail",Vector3.new(1.15,2.3,1.2),Vector3.new(0,7.65,1.55),Enum.PartType.Ball)
    else
        local long=(style=="long" or style=="longWavy" or style=="longStraight")
        local sideHeight=long and 4.4 or 3.0
        hairPart("Hair side left",Vector3.new(.7,sideHeight,1.45),Vector3.new(-1.12,7.25,.25),Enum.PartType.Ball)
        hairPart("Hair side right",Vector3.new(.7,sideHeight,1.45),Vector3.new(1.12,7.25,.25),Enum.PartType.Ball)
        if style=="bob" then
            hairPart("Bob back",Vector3.new(2.18,2.15,.82),Vector3.new(0,7.58,.88),Enum.PartType.Ball)
        elseif style=="shoulder" then
            hairPart("Shoulder hair back",Vector3.new(2.08,2.78,.86),Vector3.new(0,7.08,.92),Enum.PartType.Ball)
        elseif style=="shoulderBangs" then
            hairPart("Bangs",Vector3.new(2.1,.75,.45),Vector3.new(0,8.52,-1.0),Enum.PartType.Ball)
            hairPart("Shoulder hair back",Vector3.new(2.08,2.78,.86),Vector3.new(0,7.08,.92),Enum.PartType.Ball)
        elseif style=="longStraight" or style=="long" then
            hairPart("Long hair back",Vector3.new(2.12,4.05,.88),Vector3.new(0,6.45,.92),Enum.PartType.Ball)
        elseif style=="longWavy" then
            hairPart("Long hair back",Vector3.new(2.05,3.55,.86),Vector3.new(0,6.68,.94),Enum.PartType.Ball)
            hairPart("Wavy hair left",Vector3.new(.9,2.3,1.1),Vector3.new(-1.3,6.3,.35),Enum.PartType.Ball)
            hairPart("Wavy hair right",Vector3.new(.9,2.3,1.1),Vector3.new(1.3,6.3,.35),Enum.PartType.Ball)
        end
    end
end

local function addGlasses(model,position,prototype)
    if prototype then
        for _,x in ipairs({-.48,.48}) do
            local lens=part(model,"Glasses lens",Vector3.new(.72,.52,.075),CFrame.new(position+Vector3.new(x,8.02,-1.22)),Color3.fromRGB(45,49,54),Enum.Material.Glass)
            lens.Transparency=.70
        end
        part(model,"Glasses bridge",Vector3.new(.32,.07,.07),CFrame.new(position+Vector3.new(0,8.02,-1.24)),Color3.fromRGB(45,49,54),Enum.Material.Metal)
        return
    end

    -- Preserve the shipped baseline exactly for the 15 non-prototype staff.
    for _,x in ipairs({-.48,.48}) do
        local lens=part(model,"Glasses lens",Vector3.new(.78,.58,.08),CFrame.new(position+Vector3.new(x,8.02,-1.33)),Color3.fromRGB(45,49,54),Enum.Material.Glass)
        lens.Transparency=.72
    end
    part(model,"Glasses bridge",Vector3.new(.34,.08,.08),CFrame.new(position+Vector3.new(0,8.02,-1.35)),Color3.fromRGB(45,49,54),Enum.Material.Metal)
    part(model,"Glasses temple left",Vector3.new(.72,.07,.07),CFrame.new(position+Vector3.new(-.96,8.04,-1.03))*CFrame.Angles(0,math.rad(72),0),Color3.fromRGB(45,49,54),Enum.Material.Metal)
    part(model,"Glasses temple right",Vector3.new(.72,.07,.07),CFrame.new(position+Vector3.new(.96,8.04,-1.03))*CFrame.Angles(0,math.rad(-72),0),Color3.fromRGB(45,49,54),Enum.Material.Metal)
end

local function addBeard(model,position,color,prototype)
    if prototype then
        local beard=part(model,"Beard",Vector3.new(1.30,.66,.16),CFrame.new(position+Vector3.new(0,7.12,-1.12)),color,Enum.Material.SmoothPlastic)
        beard.CanQuery=false
        part(model,"Mustache",Vector3.new(.92,.16,.09),CFrame.new(position+Vector3.new(0,7.48,-1.16)),color,Enum.Material.SmoothPlastic)
        return
    end

    local beard=part(model,"Beard",Vector3.new(1.45,.82,.18),CFrame.new(position+Vector3.new(0,7.10,-1.16)),color,Enum.Material.SmoothPlastic)
    beard.CanQuery=false
    part(model,"Mustache",Vector3.new(1.05,.18,.10),CFrame.new(position+Vector3.new(0,7.48,-1.23)),color,Enum.Material.SmoothPlastic)
end

local function addClothing(model,position,appearance,avatar,topColor,outerColor,innerColor)
    local style=avatar.outfit
    if appearance.suit or style=="suit" then
        part(model,"Suit shirt",Vector3.new(1.38,2.25,.18),CFrame.new(position+Vector3.new(0,5,-1)),innerColor,Enum.Material.Fabric)
        part(model,"Suit lapel left",Vector3.new(.64,2.05,.16),CFrame.new(position+Vector3.new(-.56,5.05,-1.08))*CFrame.Angles(0,0,math.rad(-12)),outerColor,Enum.Material.Fabric)
        part(model,"Suit lapel right",Vector3.new(.64,2.05,.16),CFrame.new(position+Vector3.new(.56,5.05,-1.08))*CFrame.Angles(0,0,math.rad(12)),outerColor,Enum.Material.Fabric)
        local tie=rgb(appearance.tie,NAVY)
        part(model,"Suit tie",Vector3.new(.26,1.82,.19),CFrame.new(position+Vector3.new(0,4.9,-1.16)),tie,Enum.Material.Fabric)
        if avatar.prototype then
            part(model,"Prototype shirt collar left",Vector3.new(.48,.62,.12),CFrame.new(position+Vector3.new(-.32,5.82,-1.16))*CFrame.Angles(0,0,math.rad(-28)),innerColor,Enum.Material.Fabric)
            part(model,"Prototype shirt collar right",Vector3.new(.48,.62,.12),CFrame.new(position+Vector3.new(.32,5.82,-1.16))*CFrame.Angles(0,0,math.rad(28)),innerColor,Enum.Material.Fabric)
        end
    elseif style=="cardigan" then
        part(model,"Prototype cardigan inset",Vector3.new(1.62,3.35,.15),CFrame.new(position+Vector3.new(0,4.58,-.99)),innerColor,Enum.Material.Fabric)
        part(model,"Prototype cardigan left",Vector3.new(.65,3.35,.16),CFrame.new(position+Vector3.new(-.79,4.58,-1.02)),outerColor,Enum.Material.Fabric)
        part(model,"Prototype cardigan right",Vector3.new(.65,3.35,.16),CFrame.new(position+Vector3.new(.79,4.58,-1.02)),outerColor,Enum.Material.Fabric)
        for y=3.72,5.45,.43 do
            ball(model,"Prototype cardigan button",Vector3.new(.11,.11,.07),CFrame.new(position+Vector3.new(0,y,-1.13)),Color3.fromRGB(205,205,198))
        end
    elseif style=="staffCasual" then
        part(model,"Prototype collar",Vector3.new(1.48,.64,.15),CFrame.new(position+Vector3.new(0,5.85,-1.02)),Color3.fromRGB(228,228,220),Enum.Material.Fabric)
        part(model,"Prototype shirt placket",Vector3.new(.16,2.45,.11),CFrame.new(position+Vector3.new(0,4.72,-1.02)),topColor:Lerp(Color3.new(1,1,1),.14),Enum.Material.Fabric)
    elseif appearance.outer then
        part(model,appearance.vest and "Sweater vest" or "Jacket shirt inset",Vector3.new(1.65,3.5,.16),CFrame.new(position+Vector3.new(0,4.55,-.99)),topColor,Enum.Material.Fabric)
    end

    if appearance.pin then
        ball(model,"Lapel pin",Vector3.new(.28,.28,.1),CFrame.new(position+Vector3.new(.75,5.35,-1.03)),GOLD)
    end
    if appearance.cross then
        part(model,"Cross necklace vertical",Vector3.new(.12,.62,.08),CFrame.new(position+Vector3.new(0,5.45,-1.12)),Color3.fromRGB(202,175,116),Enum.Material.Metal)
        part(model,"Cross necklace horizontal",Vector3.new(.38,.12,.08),CFrame.new(position+Vector3.new(0,5.58,-1.13)),Color3.fromRGB(202,175,116),Enum.Material.Metal)
    end
end

function Factory.build(parent,staff,position)
    local appearance=staff.appearance or {}
    local avatar=staff.avatar or {}
    local prototype=avatar.prototype==true

    local model=Instance.new("Model")
    model.Name="Faculty_"..staff.id
    model:SetAttribute("StaffId",staff.id)
    model:SetAttribute("StaffName",staff.name)
    model:SetAttribute("StaffRole",staff.role)
    model:SetAttribute("StaffLocation",staff.location or "")
    model:SetAttribute("StaffFloor",staff.floor or 0)
    model:SetAttribute("LikenessMode","simple-stylized")
    model:SetAttribute("PortraitMode","disabled")
    model:SetAttribute("AvatarFactoryMode",prototype and "prototype-v1" or "baseline-v1")
    model.Parent=parent

    local skin=rgb(appearance.skin,DEFAULT_SKIN)
    local hair=rgb(appearance.hair,DEFAULT_HAIR)
    local topColor=rgb(appearance.top,DEFAULT_TOP)
    local outerColor=rgb(appearance.outer,topColor)
    local innerColor=rgb(appearance.inner,Color3.fromRGB(235,235,230))
    local lowerColor=rgb(avatar.lower,Color3.fromRGB(48,54,65))

    local bodyWidth=prototype and (avatar.body=="administrator" and 3.38 or 3.10) or 3.2
    local torsoHeight=prototype and 4.08 or 4.2
    local torsoColor=appearance.outer and outerColor or topColor
    part(model,"Torso",Vector3.new(bodyWidth,torsoHeight,1.8),CFrame.new(position+Vector3.new(0,4.5,0)),torsoColor,Enum.Material.Fabric)
    part(model,"Left leg",Vector3.new(1.2,3.5,1.2),CFrame.new(position+Vector3.new(-.8,1.4,0)),lowerColor,Enum.Material.Fabric)
    part(model,"Right leg",Vector3.new(1.2,3.5,1.2),CFrame.new(position+Vector3.new(.8,1.4,0)),lowerColor,Enum.Material.Fabric)

    local armColor=(appearance.jacket or appearance.outer) and outerColor or topColor
    part(model,"Left arm",Vector3.new(.9,3.7,.9),CFrame.new(position+Vector3.new(-2.02,4.4,0))*CFrame.Angles(0,0,math.rad(-4)),armColor,Enum.Material.Fabric)
    part(model,"Right arm",Vector3.new(.9,3.7,.9),CFrame.new(position+Vector3.new(2.02,4.4,0))*CFrame.Angles(0,0,math.rad(4)),armColor,Enum.Material.Fabric)

    for _,x in ipairs({-2.13,2.13}) do
        ball(model,x<0 and "Left hand" or "Right hand",Vector3.new(.82,.82,.82),CFrame.new(position+Vector3.new(x,2.52,-.02)),skin)
    end
    local neck=part(model,"Neck",Vector3.new(.68,.72,.68),CFrame.new(position+Vector3.new(0,6.62,0))*CFrame.Angles(0,0,math.rad(90)),skin)
    neck.Shape=Enum.PartType.Cylinder

    local shoeColor=rgb(avatar.shoes,Color3.fromRGB(38,42,48))
    part(model,"Left shoe",Vector3.new(1.28,.58,1.78),CFrame.new(position+Vector3.new(-.8,-.02,-.26)),shoeColor)
    part(model,"Right shoe",Vector3.new(1.28,.58,1.78),CFrame.new(position+Vector3.new(.8,-.02,-.26)),shoeColor)

    local headSize=prototype and Vector3.new(2.30,2.32,2.04) or Vector3.new(2.35,2.35,2.10)
    part(model,"Head",headSize,CFrame.new(position+Vector3.new(0,7.8,0)),skin)
    simpleFace(model,position,skin,prototype)

    for _,x in ipairs({-1.18,1.18}) do
        ball(model,"Ear",Vector3.new(.28,.52,.24),CFrame.new(position+Vector3.new(x,7.86,0)),skin)
    end

    addHair(model,position,hair,appearance.hairStyle or "short",avatar.hairDetail)
    if appearance.glasses then addGlasses(model,position,prototype) end
    if appearance.beard then addBeard(model,position,rgb(appearance.beardColor,hair),prototype) end
    addClothing(model,position,appearance,avatar,topColor,outerColor,innerColor)

    if appearance.pattern and not prototype then
        local patternColors={
            floral={Color3.fromRGB(245,238,232),Color3.fromRGB(89,39,81)},
            lineFloral={Color3.fromRGB(48,49,54),Color3.fromRGB(235,229,218)},
            school={Color3.fromRGB(232,170,63),Color3.fromRGB(88,145,149)},
            brightFloral={Color3.fromRGB(235,72,153),Color3.fromRGB(74,166,124)},
            geometric={Color3.fromRGB(32,33,36),Color3.fromRGB(239,238,231)},
        }
        local colors=patternColors[appearance.pattern] or {GOLD,Color3.fromRGB(24,103,59)}
        for i,offset in ipairs({{-1,.75},{0,.92},{1,.62},{-.6,-.15},{.55,-.35},{0,-1.05}}) do
            ball(model,"Clothing pattern",Vector3.new(.38,.38,.08),CFrame.new(position+Vector3.new(offset[1],4.7+offset[2],-1.02)),colors[(i-1)%#colors+1])
        end
    end

    local head=model:FindFirstChild("Head") :: BasePart
    local gui=Instance.new("BillboardGui")
    gui.Name="FacultyName"
    gui.AlwaysOnTop=false
    gui.Size=UDim2.fromOffset(148,28)
    gui.StudsOffset=Vector3.new(0,1.55,0)
    gui.MaxDistance=18
    gui.Parent=head
    local label=Instance.new("TextLabel")
    label.Size=UDim2.fromScale(1,1)
    label.BackgroundColor3=NAVY
    label.BackgroundTransparency=.18
    label.TextColor3=CREAM
    label.Font=Enum.Font.GothamBold
    label.TextSize=10
    label.TextWrapped=false
    label.TextTruncate=Enum.TextTruncate.AtEnd
    label.Text=staff.name
    label.Parent=gui
    local stroke=Instance.new("UIStroke")
    stroke.Color=GOLD
    stroke.Transparency=.35
    stroke.Thickness=1
    stroke.Parent=label
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,8)
    corner.Parent=label

    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="MeetFaculty"
    prompt.ActionText="Meet"
    prompt.ObjectText=staff.name
    prompt.MaxActivationDistance=8
    prompt.RequiresLineOfSight=true
    prompt.HoldDuration=0
    prompt.Parent=head

    return model
end

return Factory
