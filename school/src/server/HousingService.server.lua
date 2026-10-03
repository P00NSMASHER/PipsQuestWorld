--!strict
-- Legacy housing/property adapter.
-- Free Roam owns active housing interactions; EconomyRepository remains the
-- single durable money/ownership authority and Foundation owns plot geometry.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local SchoolConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SchoolConfig"))
local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local EconomyRepository = require(schoolFoundation:WaitForChild("EconomyRepository"))
local HousingLifecycle = require(schoolFoundation:WaitForChild("HousingLifecycle"))
local VersionedDataStore = require(schoolFoundation:WaitForChild("ProgressionDataStore"))

local HOUSE_PRICE = 50
local HOUSE_UNLOCK = { category = "house", itemId = "starter-house" }
local STYLE_COLORS = {
    ["classic-blue"] = Color3.fromRGB(176, 190, 199),
    ["classic-tan"] = Color3.fromRGB(191, 177, 155),
    ["classic-red"] = Color3.fromRGB(183, 127, 119),
    ["classic-green"] = Color3.fromRGB(145, 171, 132),
}

local function createEconomyStore()
    if RunService:IsStudio() and game.GameId == 0 then
        local StudioStore = require(schoolFoundation:WaitForChild("ProgressionStudioStore"))
        Workspace:SetAttribute("EconomyPersistenceMode", "StudioMemoryUnpublished")
        return StudioStore.new()
    end

    Workspace:SetAttribute("EconomyPersistenceMode", "DataStore")
    return VersionedDataStore.new(
        DataStoreService:GetDataStore("PipHighEconomyV1")
    )
end

local economyStore = createEconomyStore()
local repositoryByPlayerId = {}

local plotIds = {}
local plotConfigById = {}
for index, plot in ipairs(SchoolConfig.HousingPlots) do
    plotIds[index] = plot.id
    plotConfigById[plot.id] = plot
end
local lifecycle = HousingLifecycle.new(plotIds)

local campus = Workspace:WaitForChild("SchoolCampus")
local housingPlotsFolder = campus:WaitForChild("HousingPlots")

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
local freeRoamRoot = getOrCreateFolder(remoteRoot, "FreeRoam")
local housingRoot = getOrCreateFolder(freeRoamRoot, "Housing")
local getStateRemote = getOrCreateRemoteFunction(housingRoot, "GetState")
local buyHouseRemote = getOrCreateRemoteFunction(housingRoot, "BuyHouse")
local teleportRemote = getOrCreateRemoteFunction(housingRoot, "TeleportToHouse")
local editModeRemote = getOrCreateRemoteFunction(housingRoot, "SetEditMode")
local styleRemote = getOrCreateRemoteFunction(housingRoot, "SetStyle")

local function playerKey(player)
    return tostring(player.UserId)
end

local function openRepository(playerId, reload)
    local repository = repositoryByPlayerId[playerId]
    if repository == nil then
        local opened, openError = EconomyRepository.open(economyStore, playerId)
        if opened == nil then
            return nil, tostring(openError or "repository_unavailable")
        end
        repository = opened
        repositoryByPlayerId[playerId] = repository
    elseif reload == true then
        local ok, reloadError = repository:reload()
        if not ok then
            return nil, tostring(reloadError or "repository_reload_failed")
        end
    end
    return repository, nil
end

local function hasHouse(economyState)
    for _, unlock in ipairs(economyState.ownership or {}) do
        if unlock.category == HOUSE_UNLOCK.category
            and unlock.itemId == HOUSE_UNLOCK.itemId then
            return true
        end
    end
    return false
end

local function setHouseVisual(plotId, visible, styleId, ownerUserId)
    local folder = housingPlotsFolder:FindFirstChild(plotId)
    if not folder then
        return false
    end

    folder:SetAttribute("Claimed", visible == true)
    folder:SetAttribute("OwnerUserId", ownerUserId or 0)
    folder:SetAttribute("StyleId", styleId or "classic-blue")

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BasePart") then
            if child.Name == "HouseBody" then
                child.Transparency = visible and 0 or 1
                child.CanCollide = visible
                child.Color = STYLE_COLORS[styleId] or STYLE_COLORS["classic-blue"]
            elseif child.Name == "HouseRoof" then
                child.Transparency = visible and 0 or 1
                child.CanCollide = visible
            elseif child.Name == "HouseDoor" then
                child.Transparency = visible and 0 or 1
                child.CanCollide = false
            elseif child.Name == "HouseWindow" then
                child.Transparency = visible and 0.25 or 1
                child.CanCollide = false
            end
        end
    end
    return true
end

for _, plot in ipairs(SchoolConfig.HousingPlots) do
    setHouseVisual(plot.id, false, "classic-blue", 0)
end

local function ensureClaim(player, ownsHouse)
    local current = lifecycle:get(playerKey(player))
    if ownsHouse ~= true then
        if current then
            setHouseVisual(current.plotId, false, current.styleId, 0)
            lifecycle:release(playerKey(player))
        end
        return nil
    end

    local claim = lifecycle:claim(playerKey(player))
    if claim.accepted and claim.state then
        setHouseVisual(claim.state.plotId, true, claim.state.styleId, player.UserId)
        return claim.state
    end
    return nil
end

local function discovery(player, reload)
    local repository, repositoryError = openRepository(player.UserId, reload)
    if repository == nil then
        return {
            available = false,
            code = "economy_unavailable",
            error = repositoryError,
            price = HOUSE_PRICE,
        }
    end

    local economyState = repository:getState()
    local owned = hasHouse(economyState)
    local houseState = ensureClaim(player, owned)
    return {
        available = true,
        owned = owned,
        price = HOUSE_PRICE,
        balance = economyState.balance,
        plotId = houseState and houseState.plotId or nil,
        editing = houseState and houseState.editing == true or false,
        styleId = houseState and houseState.styleId or "classic-blue",
        plotAvailable = owned == false or houseState ~= nil,
        customizationPersistence = "session_v1",
    }
end

getStateRemote.OnServerInvoke = function(player)
    return discovery(player, true)
end

buyHouseRemote.OnServerInvoke = function(player)
    local repository, repositoryError = openRepository(player.UserId, true)
    if repository == nil then
        return { accepted = false, code = "economy_unavailable", error = repositoryError }
    end

    local economyState = repository:getState()
    if hasHouse(economyState) then
        local state = discovery(player, false)
        state.accepted = true
        state.code = "house_already_owned"
        return state
    end

    local reservation = lifecycle:claim(playerKey(player))
    if not reservation.accepted then
        return { accepted = false, code = reservation.code, price = HOUSE_PRICE }
    end

    local receipt = repository:record({
        operationId = "housing:starter-house:v1",
        playerId = player.UserId,
        delta = -HOUSE_PRICE,
        reason = "housing:purchase",
        unlock = HOUSE_UNLOCK,
    })

    local committed = receipt
        and receipt.durable == true
        and (receipt.status == "applied" or receipt.status == "duplicate")
    if not committed then
        lifecycle:release(playerKey(player))
        local errorCode = receipt and receipt.error or "purchase_failed"
        return {
            accepted = false,
            code = errorCode == "INSUFFICIENT_FUNDS" and "insufficient_funds" or "purchase_failed",
            error = errorCode,
            price = HOUSE_PRICE,
            balance = economyState.balance,
        }
    end

    local houseState = lifecycle:get(playerKey(player))
    setHouseVisual(houseState.plotId, true, houseState.styleId, player.UserId)

    local state = discovery(player, false)
    state.accepted = true
    state.code = receipt.status == "duplicate" and "house_already_owned" or "house_purchased"
    return state
end

teleportRemote.OnServerInvoke = function(player)
    local state = discovery(player, true)
    if state.available ~= true then
        state.accepted = false
        return state
    end
    if state.owned ~= true then
        return { accepted = false, code = "house_not_owned", price = HOUSE_PRICE, balance = state.balance }
    end
    if not state.plotId then
        return { accepted = false, code = "no_plot_available" }
    end

    local plot = plotConfigById[state.plotId]
    local character = player.Character
    if not plot or not character then
        return { accepted = false, code = "teleport_unavailable" }
    end

    character:PivotTo(
        CFrame.new(plot.teleportPosition)
            * CFrame.Angles(0, math.rad(plot.headingDegrees), 0)
    )

    state.accepted = true
    state.code = "teleported_to_house"
    return state
end

editModeRemote.OnServerInvoke = function(player, enabled)
    local state = discovery(player, true)
    if state.owned ~= true or not state.plotId then
        return { accepted = false, code = "house_not_owned" }
    end

    local result = lifecycle:setEditing(playerKey(player), enabled == true)
    if not result.accepted then
        return result
    end

    local updated = discovery(player, false)
    updated.accepted = true
    updated.code = result.code
    return updated
end

styleRemote.OnServerInvoke = function(player, styleId)
    if STYLE_COLORS[styleId] == nil then
        return { accepted = false, code = "invalid_style" }
    end

    local state = discovery(player, true)
    if state.owned ~= true or not state.plotId then
        return { accepted = false, code = "house_not_owned" }
    end

    local result = lifecycle:setStyle(playerKey(player), styleId)
    if not result.accepted then
        return result
    end

    setHouseVisual(result.state.plotId, true, result.state.styleId, player.UserId)
    local updated = discovery(player, false)
    updated.accepted = true
    updated.code = "style_changed"
    return updated
end

local function restoreOwnedHouse(player)
    local state = discovery(player, true)
    if state.available == true and state.owned == true and state.plotId then
        local lifecycleState = lifecycle:get(playerKey(player))
        setHouseVisual(state.plotId, true, lifecycleState and lifecycleState.styleId or "classic-blue", player.UserId)
    end
end

Players.PlayerAdded:Connect(function(player)
    task.spawn(restoreOwnedHouse, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(restoreOwnedHouse, player)
end

Players.PlayerRemoving:Connect(function(player)
    local current = lifecycle:get(playerKey(player))
    if current then
        setHouseVisual(current.plotId, false, current.styleId, 0)
    end
    lifecycle:release(playerKey(player))
    repositoryByPlayerId[player.UserId] = nil
end)
