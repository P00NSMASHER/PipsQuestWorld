--!strict
-- Runtime Style Shop: durable cash purchases plus original, session-equipped
-- color/geometry wardrobe layers. The client supplies only item/request IDs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local EconomyRuntime = require(schoolFoundation:WaitForChild("EconomyRuntime"))
local StyleShopCatalog = require(schoolFoundation:WaitForChild("StyleShopCatalog"))
local StyleShopController = require(schoolFoundation:WaitForChild("StyleShopController"))

local controller = StyleShopController.new(StyleShopCatalog, function(playerId)
    return EconomyRuntime.open(playerId, false)
end)

local remoteRoot = ReplicatedStorage:WaitForChild("SchoolFoundation")
local freeRoam = remoteRoot:FindFirstChild("FreeRoam")
if freeRoam == nil then
    freeRoam = Instance.new("Folder")
    freeRoam.Name = "FreeRoam"
    freeRoam.Parent = remoteRoot
end

local shopRemotes = freeRoam:FindFirstChild("StyleShop")
if shopRemotes == nil then
    shopRemotes = Instance.new("Folder")
    shopRemotes.Name = "StyleShop"
    shopRemotes.Parent = freeRoam
end

local function remoteFunction(name)
    local existing = shopRemotes:FindFirstChild(name)
    if existing then
        assert(existing:IsA("RemoteFunction"), name .. " must be a RemoteFunction")
        return existing
    end
    local remote = Instance.new("RemoteFunction")
    remote.Name = name
    remote.Parent = shopRemotes
    return remote
end

local getState = remoteFunction("GetState")
local purchaseItem = remoteFunction("PurchaseItem")
local equipItem = remoteFunction("EquipItem")

local equippedByPlayer = {}
local characterConnections = {}

local function color3(rgb)
    return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function makePart(folder, name, target, size, relativeCFrame, color, transparency, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = target.CFrame * relativeCFrame
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.Transparency = transparency or 0
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    if shape then part.Shape = shape end
    part.Parent = folder

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = target
    weld.Part1 = part
    weld.Parent = part
    return part
end

local function applyTop(folder, character, item)
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso or not torso:IsA("BasePart") then return end
    local shell = makePart(
        folder,
        "Top_" .. item.id,
        torso,
        torso.Size + Vector3.new(0.1, 0.08, 0.1),
        CFrame.new(),
        color3(item.primary),
        0.08
    )
    makePart(
        folder,
        "TopAccent_" .. item.id,
        shell,
        Vector3.new(math.max(0.5, shell.Size.X * 0.72), 0.16, 0.04),
        CFrame.new(0, shell.Size.Y * 0.18, -shell.Size.Z * 0.51),
        color3(item.secondary),
        0
    )
end

local function applyBottom(folder, character, item)
    local names = {
        { "LeftUpperLeg", "Left Leg" },
        { "RightUpperLeg", "Right Leg" },
    }
    for index, alternatives in ipairs(names) do
        local leg = character:FindFirstChild(alternatives[1]) or character:FindFirstChild(alternatives[2])
        if leg and leg:IsA("BasePart") then
            local shell = makePart(
                folder,
                "Bottom" .. tostring(index) .. "_" .. item.id,
                leg,
                leg.Size + Vector3.new(0.07, 0.06, 0.07),
                CFrame.new(),
                color3(item.primary),
                0.08
            )
            makePart(
                folder,
                "BottomAccent" .. tostring(index) .. "_" .. item.id,
                shell,
                Vector3.new(0.07, math.max(0.35, shell.Size.Y * 0.55), 0.04),
                CFrame.new((index == 1 and -1 or 1) * shell.Size.X * 0.32, 0, -shell.Size.Z * 0.51),
                color3(item.secondary),
                0
            )
        end
    end
end

local function applyAccessory(folder, character, item)
    local primary = color3(item.primary)
    local secondary = color3(item.secondary)
    if item.shape == "backpack" then
        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        if torso and torso:IsA("BasePart") then
            local pack = makePart(folder, "Daypack", torso, Vector3.new(1.35, 1.5, 0.38), CFrame.new(0, 0, torso.Size.Z * 0.5 + 0.22), primary, 0)
            makePart(folder, "DaypackPocket", pack, Vector3.new(0.9, 0.55, 0.18), CFrame.new(0, -0.28, 0.27), secondary, 0)
        end
    elseif item.shape == "glasses" then
        local head = character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            for index, x in ipairs({ -0.36, 0.36 }) do
                makePart(folder, "Lens" .. tostring(index), head, Vector3.new(0.62, 0.5, 0.08), CFrame.new(x, 0.05, -head.Size.Z * 0.5 - 0.06), primary, 0.18)
            end
            makePart(folder, "GlassesBridge", head, Vector3.new(0.22, 0.08, 0.08), CFrame.new(0, 0.05, -head.Size.Z * 0.5 - 0.07), secondary, 0)
        end
    elseif item.shape == "headband" then
        local head = character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            makePart(folder, "Headband", head, Vector3.new(head.Size.X + 0.08, 0.2, head.Size.Z + 0.08), CFrame.new(0, head.Size.Y * 0.26, 0), primary, 0.04)
            makePart(folder, "StarlightCharm", head, Vector3.new(0.25, 0.25, 0.12), CFrame.new(head.Size.X * 0.35, head.Size.Y * 0.36, -head.Size.Z * 0.5 - 0.08), secondary, 0, Enum.PartType.Ball)
        end
    end
end

local function applyEquipped(player)
    local character = player.Character
    if character == nil then return end

    local prior = character:FindFirstChild("PipHighStyle")
    if prior then prior:Destroy() end

    local folder = Instance.new("Folder")
    folder.Name = "PipHighStyle"
    folder.Parent = character

    local equipped = equippedByPlayer[player.UserId] or {}
    for _, itemId in pairs(equipped) do
        local authorization = controller:authorizeEquip(player.UserId, itemId)
        if authorization.accepted and authorization.item then
            if authorization.item.slot == "top" then
                applyTop(folder, character, authorization.item)
            elseif authorization.item.slot == "bottom" then
                applyBottom(folder, character, authorization.item)
            elseif authorization.item.slot == "accessory" then
                applyAccessory(folder, character, authorization.item)
            end
        end
    end
end

local function applyWhenCharacterReady(player, character)
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid or not humanoid:IsA("Humanoid") then return end
        local torsoName = humanoid.RigType == Enum.HumanoidRigType.R15
            and "UpperTorso"
            or "Torso"
        if not character:WaitForChild(torsoName, 10) then return end
        if not character:WaitForChild("Head", 10) then return end
        if player.Character == character then
            applyEquipped(player)
        end
    end)
end

local function equippedSnapshot(playerId)
    local result = {}
    for slot, itemId in pairs(equippedByPlayer[playerId] or {}) do
        result[slot] = itemId
    end
    return result
end

local function bindPlayer(player)
    if characterConnections[player.UserId] then
        characterConnections[player.UserId]:Disconnect()
    end
    characterConnections[player.UserId] = player.CharacterAdded:Connect(function(character)
        applyWhenCharacterReady(player, character)
    end)
    if player.Character then
        applyWhenCharacterReady(player, player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(function(player)
    equippedByPlayer[player.UserId] = nil
    local connection = characterConnections[player.UserId]
    if connection then connection:Disconnect() end
    characterConnections[player.UserId] = nil
end)

getState.OnServerInvoke = function(player)
    local response = controller:getState(player.UserId)
    response.equipped = equippedSnapshot(player.UserId)
    return response
end

purchaseItem.OnServerInvoke = function(player, itemId, requestId)
    local response = controller:purchase(player.UserId, itemId, requestId)
    response.equipped = equippedSnapshot(player.UserId)
    return response
end

equipItem.OnServerInvoke = function(player, itemId)
    local response = controller:authorizeEquip(player.UserId, itemId)
    if response.accepted ~= true or response.item == nil then return response end

    local equipped = equippedByPlayer[player.UserId]
    if equipped == nil then
        equipped = {}
        equippedByPlayer[player.UserId] = equipped
    end
    equipped[response.item.slot] = response.item.id
    player:SetAttribute("StyleShopEquipped_" .. response.item.slot, response.item.id)
    applyEquipped(player)
    return {
        accepted = true,
        code = "equipped",
        itemId = response.item.id,
        equipped = equippedSnapshot(player.UserId),
    }
end

Workspace:SetAttribute("StyleShopCatalogCount", #StyleShopCatalog)
