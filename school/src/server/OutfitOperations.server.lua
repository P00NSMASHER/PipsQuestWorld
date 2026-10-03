--!strict
-- Runtime adapter for verified pinned-baseline outfit operations.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local SchoolConfig = require(shared:WaitForChild("SchoolConfig"))
local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local ProgressionRepository = require(schoolFoundation:WaitForChild("ProgressionRepository"))
local ProgressionPersistence = require(schoolFoundation:WaitForChild("ProgressionPersistence"))
local OutfitOperationsController = require(schoolFoundation:WaitForChild("OutfitOperationsController"))

local progressionStore = ProgressionPersistence.get()

local function getRepository(playerId)
    return ProgressionRepository.open(progressionStore, playerId)
end

local function filterIdentityForPlayer(player, value)
    if value == "" then return "" end
    local result = TextService:FilterStringAsync(value, player.UserId)
    return result:GetNonChatStringForUserAsync(player.UserId)
end

local function applyOutfit(player, outfit)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false, "HUMANOID_UNAVAILABLE" end

    local description = humanoid:GetAppliedDescription()
    description.Shirt = outfit.RemoveShirt and 0 or outfit.Shirt
    description.Pants = outfit.Pants
    description.Face = outfit.Face

    local hats = {}
    for _, field in ipairs({ "Hat1", "Hat2", "Hat3" }) do
        local assetId = outfit[field]
        if type(assetId) == "number" and assetId > 0 then
            hats[#hats + 1] = tostring(assetId)
        end
    end
    description.HatAccessory = table.concat(hats, ",")

    -- Package is persisted exactly because it is verified baseline state, but
    -- its avatar-application mapping remains unverified and is not guessed here.
    humanoid:ApplyDescription(description)
    return true, nil
end

local controller = OutfitOperationsController.new(
    getRepository,
    function(value, _field, player)
        return filterIdentityForPlayer(player, value)
    end,
    applyOutfit
)

-- Bind the player into the controller's server filter without making filtering client-owned.
local function filterFor(player, value, field)
    return filterIdentityForPlayer(player, value)
end

local function getOrCreateFolder(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing then
        assert(existing:IsA("Folder"), name .. " must be a Folder")
        return existing
    end
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function getOrCreateRemoteFunction(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing then
        assert(existing:IsA("RemoteFunction"), name .. " must be a RemoteFunction")
        return existing
    end
    local remote = Instance.new("RemoteFunction")
    remote.Name = name
    remote.Parent = parent
    return remote
end

local remoteRoot = ReplicatedStorage:WaitForChild(SchoolConfig.Interfaces.remoteFolder)
local freeRoam = getOrCreateFolder(remoteRoot, "FreeRoam")
local outfitRoot = getOrCreateFolder(freeRoam, "Outfits")
local loadOutfit = getOrCreateRemoteFunction(outfitRoot, "LoadOutfit")
local loadOutfitPage = getOrCreateRemoteFunction(outfitRoot, "LoadOutfitPage")
local wearOutfit = getOrCreateRemoteFunction(outfitRoot, "WearOutfit")
local saveOutfit = getOrCreateRemoteFunction(outfitRoot, "SaveOutfit")

loadOutfit.OnServerInvoke = function(player, slot)
    return controller:loadOutfit(player.UserId, slot)
end

loadOutfitPage.OnServerInvoke = function(player, startSlot)
    return controller:loadOutfitPage(player.UserId, startSlot)
end

wearOutfit.OnServerInvoke = function(player, slot)
    return controller:wearOutfit(player.UserId, slot, player)
end

saveOutfit.OnServerInvoke = function(player, slot, input)
    local filteredController = OutfitOperationsController.new(
        getRepository,
        function(value, field)
            return filterFor(player, value, field)
        end,
        applyOutfit
    )
    return filteredController:saveOutfit(player.UserId, slot, input)
end
