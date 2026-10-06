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
        layer(folder,torso,"Jacket",Vector3.new(ts.X*1.03,ts.Y*.88,ts.Z*1.06),CFrame.new(0,0,0),tint)
        if outfit.style>=2 then
            layer(folder,torso,"Jacket trim",Vector3.new(.13,ts.Y*.86,.05),CFrame.new(0,0,-ts.Z*.55),outfit.style==3 and Color3.fromRGB(217,184,105) or Color3.fromRGB(242,233,211))
        end
        for _,side in ipairs({"Left","Right"}) do
            local arm=character:FindFirstChild(side.."UpperArm") or character:FindFirstChild(side.." Arm")
            if arm and arm:IsA("BasePart") then
                layer(folder,arm,"Sleeve",Vector3.new(arm.Size.X*1.045,arm.Size.Y*.66,arm.Size.Z*1.045),CFrame.new(0,arm.Size.Y*.12,0),outfit.style==2 and Color3.fromRGB(237,231,218) or tint)
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
