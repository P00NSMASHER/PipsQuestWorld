--!strict
-- Original, asset-ID-free clothing layers. Never strips a player's existing clothes.
local Wardrobe={}
local function layer(parent,body,name,size,offset,tint)
    local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=tint;p.Material=Enum.Material.Fabric
    p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true;p.CFrame=body.CFrame*offset;p.Parent=parent
    local weld=Instance.new("WeldConstraint");weld.Part0=body;weld.Part1=p;weld.Parent=p
    return p
end
function Wardrobe.apply(character,profile,catalog)
    if not character or not character.Parent then return end
    local old=character:FindFirstChild("NeighborhoodWearables");if old then old:Destroy() end
    local folder=Instance.new("Folder");folder.Name="NeighborhoodWearables";folder.Parent=character
    local torso=character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso or not torso:IsA("BasePart") then return end
    local outfit=catalog.ById[profile.equipped.outfit]
    if outfit and profile.owned[outfit.id] then
        local tint=Color3.fromRGB(table.unpack(outfit.color))
        local ts=torso.Size
        if outfit.style==6 or outfit.style==7 then
            local forest=Color3.fromRGB(31,91,67)
            local khaki=Color3.fromRGB(205,190,154)
            local navy=Color3.fromRGB(28,48,72)
            local cream=Color3.fromRGB(235,231,216)
            layer(folder,torso,"ABVM polo",Vector3.new(ts.X*1.035,ts.Y*.88,ts.Z*1.06),CFrame.new(0,0,0),forest)
            layer(folder,torso,"ABVM collar",Vector3.new(ts.X*.72,.3,ts.Z*1.08),CFrame.new(0,ts.Y*.39,0),forest)
            layer(folder,torso,"ABVM chest mark",Vector3.new(.42,.22,.06),CFrame.new(ts.X*.25,ts.Y*.14,-ts.Z*.56),cream)
            for _,side in ipairs({"Left","Right"}) do
                local arm=character:FindFirstChild(side.."UpperArm") or character:FindFirstChild(side.." Arm")
                if arm and arm:IsA("BasePart") then
                    layer(folder,arm,"ABVM polo sleeve",Vector3.new(arm.Size.X*1.045,arm.Size.Y*.55,arm.Size.Z*1.045),CFrame.new(0,arm.Size.Y*.2,0),forest)
                end
            end
            for _,side in ipairs({"Left","Right"}) do
                local leg=character:FindFirstChild(side.."UpperLeg") or character:FindFirstChild(side.." Leg")
                if leg and leg:IsA("BasePart") then
                    local lowerColor=outfit.style==7 and navy or khaki
                    layer(folder,leg,outfit.style==7 and "Navy sock/underlayer" or "Khaki uniform bottom",
                        Vector3.new(leg.Size.X*1.06,leg.Size.Y*.92,leg.Size.Z*1.06),CFrame.new(0,0,0),lowerColor)
                end
            end
            if outfit.style==7 then
                local skirt=layer(folder,torso,"ABVM plaid jumper",Vector3.new(ts.X*1.18,ts.Y*.95,ts.Z*1.14),CFrame.new(0,-ts.Y*.08,0),forest)
                -- Native layered strips approximate the green/navy/white plaid without an external texture asset.
                for _,x in ipairs({-.38,0,.38}) do
                    layer(folder,torso,"Plaid vertical",Vector3.new(.12,ts.Y*.92,.07),CFrame.new(ts.X*x,-ts.Y*.08,-ts.Z*.6),navy)
                end
                for _,y in ipairs({-.28,.05,.32}) do
                    layer(folder,torso,"Plaid horizontal",Vector3.new(ts.X*1.12,.09,.07),CFrame.new(0,ts.Y*y,-ts.Z*.6),cream)
                end
                skirt.Name="ABVM plaid jumper"
            end
        else
            layer(folder,torso,"Jacket",Vector3.new(ts.X*1.03,ts.Y*.88,ts.Z*1.06),CFrame.new(0,0,0),tint)
        end
        if outfit.style>=2 and outfit.style<=5 then
            layer(folder,torso,"Jacket trim",Vector3.new(.13,ts.Y*.86,.05),CFrame.new(0,0,-ts.Z*.55),outfit.style>=3 and Color3.fromRGB(217,184,105) or Color3.fromRGB(242,233,211))
        end
        for _,side in ipairs({"Left","Right"}) do
            local arm=character:FindFirstChild(side.."UpperArm") or character:FindFirstChild(side.." Arm")
            if arm and arm:IsA("BasePart") then
                layer(folder,arm,"Sleeve",Vector3.new(arm.Size.X*1.045,arm.Size.Y*.66,arm.Size.Z*1.045),CFrame.new(0,arm.Size.Y*.12,0),outfit.style==2 and Color3.fromRGB(237,231,218) or tint)
            end
        end
        if outfit.style>=4 and outfit.style<=5 then
            layer(folder,torso,"Signature collar",Vector3.new(ts.X*.72,.35,ts.Z*1.08),CFrame.new(0,ts.Y*.38,0),Color3.fromRGB(217,184,105))
        end
        if outfit.style==5 then
            layer(folder,torso,"Premier band",Vector3.new(ts.X*1.05,.18,ts.Z*1.08),CFrame.new(0,-ts.Y*.25,0),Color3.fromRGB(225,199,121))
        end
    end
    -- Additive mix-and-match uniform pieces layer over the legacy outfit slot.
    local function equipped(slot)
        local id=profile.equipped[slot]
        local item=id and catalog.ById[id] or nil
        if item and profile.owned[id] then return item end
        return nil
    end
    local top=equipped("uniformTop")
    if top then
        local topColor=Color3.fromRGB(table.unpack(top.color))
        local ts=torso.Size
        layer(folder,torso,"Uniform top",Vector3.new(ts.X*1.04,ts.Y*.9,ts.Z*1.07),CFrame.new(0,0,0),topColor)
        local markColor=top.style==13 and Color3.fromRGB(31,91,67) or Color3.fromRGB(238,238,231)
        layer(folder,torso,"Uniform ABVM chest mark",Vector3.new(.42,.22,.06),CFrame.new(ts.X*.25,ts.Y*.14,-ts.Z*.56),markColor)
        if top.style==14 then
            layer(folder,torso,"Sweater collar",Vector3.new(ts.X*.7,.28,ts.Z*1.08),CFrame.new(0,ts.Y*.38,0),Color3.fromRGB(238,238,231))
        elseif top.style==15 then
            layer(folder,torso,"Cardigan shirt inset",Vector3.new(ts.X*.42,ts.Y*.78,.06),CFrame.new(0,0,-ts.Z*.57),Color3.fromRGB(238,238,231))
        end
        for _,side in ipairs({"Left","Right"}) do
            local arm=character:FindFirstChild(side.."UpperArm") or character:FindFirstChild(side.." Arm")
            if arm and arm:IsA("BasePart") then
                local sleeveScale=(top.style==14 or top.style==15) and .95 or .55
                layer(folder,arm,"Uniform sleeve",Vector3.new(arm.Size.X*1.05,arm.Size.Y*sleeveScale,arm.Size.Z*1.05),CFrame.new(0,0,0),topColor)
            end
        end
    end

    local bottom=equipped("uniformBottom")
    if bottom then
        local bottomColor=Color3.fromRGB(table.unpack(bottom.color))
        local plaid=bottom.style==24 or bottom.style==25
        local navy=Color3.fromRGB(28,48,72)
        local cream=Color3.fromRGB(235,231,216)
        if plaid or bottom.style==23 then
            local height=bottom.style==25 and torso.Size.Y*1.02 or torso.Size.Y*.68
            layer(folder,torso,bottom.style==25 and "Plaid jumper" or "Uniform skirt",
                Vector3.new(torso.Size.X*1.2,height,torso.Size.Z*1.15),CFrame.new(0,-torso.Size.Y*.24,0),bottomColor)
            if plaid then
                for _,x in ipairs({-.38,0,.38}) do
                    layer(folder,torso,"Plaid vertical",Vector3.new(.12,height*.96,.07),CFrame.new(torso.Size.X*x,-torso.Size.Y*.24,-torso.Size.Z*.6),navy)
                end
                for _,y in ipairs({-.33,-.05,.23}) do
                    layer(folder,torso,"Plaid horizontal",Vector3.new(torso.Size.X*1.14,.09,.07),CFrame.new(0,torso.Size.Y*y,-torso.Size.Z*.6),cream)
                end
            end
        else
            for _,side in ipairs({"Left","Right"}) do
                local leg=character:FindFirstChild(side.."UpperLeg") or character:FindFirstChild(side.." Leg")
                if leg and leg:IsA("BasePart") then
                    local scale=bottom.style==22 and .58 or .98
                    layer(folder,leg,bottom.style==22 and "Khaki shorts" or "Khaki pants",
                        Vector3.new(leg.Size.X*1.07,leg.Size.Y*scale,leg.Size.Z*1.07),CFrame.new(0,leg.Size.Y*(1-scale)*.42,0),bottomColor)
                end
            end
        end
    end

    local legwear=equipped("uniformLegwear")
    if legwear then
        local sockColor=Color3.fromRGB(table.unpack(legwear.color))
        for _,side in ipairs({"Left","Right"}) do
            local lower=character:FindFirstChild(side.."LowerLeg") or character:FindFirstChild(side.." Leg")
            if lower and lower:IsA("BasePart") then
                layer(folder,lower,legwear.style==33 and "School tights" or "School socks",
                    Vector3.new(lower.Size.X*1.055,lower.Size.Y*.98,lower.Size.Z*1.055),CFrame.new(0,0,0),sockColor)
            end
        end
    end

    local shoes=equipped("uniformShoes")
    if shoes then
        local shoeColor=Color3.fromRGB(table.unpack(shoes.color))
        for _,side in ipairs({"Left","Right"}) do
            local foot=character:FindFirstChild(side.."Foot") or character:FindFirstChild(side.." Leg")
            if foot and foot:IsA("BasePart") then
                layer(folder,foot,"School shoe",Vector3.new(foot.Size.X*1.12,foot.Size.Y*.72,foot.Size.Z*1.18),CFrame.new(0,-foot.Size.Y*.1,-foot.Size.Z*.04),shoeColor)
            end
        end
    end

    if profile.owned.item_backpack then
        local s=torso.Size
        layer(folder,torso,"Campus backpack",Vector3.new(s.X*.73,s.Y*.85,.6),CFrame.new(0,0,s.Z/2+.38),Color3.fromRGB(65,150,150))
        layer(folder,torso,"Backpack pocket",Vector3.new(s.X*.55,s.Y*.34,.14),CFrame.new(0,-s.Y*.2,s.Z/2+.72),Color3.fromRGB(219,198,153))
    end
end
return Wardrobe
