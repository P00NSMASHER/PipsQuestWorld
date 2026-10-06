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
    if profile.owned.item_backpack then
        local s=torso.Size
        layer(folder,torso,"Campus backpack",Vector3.new(s.X*.73,s.Y*.85,.6),CFrame.new(0,0,s.Z/2+.38),Color3.fromRGB(65,150,150))
        layer(folder,torso,"Backpack pocket",Vector3.new(s.X*.55,s.Y*.34,.14),CFrame.new(0,-s.Y*.2,s.Z/2+.72),Color3.fromRGB(219,198,153))
    end
end
return Wardrobe
