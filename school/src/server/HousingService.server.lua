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
local HousingLayoutRepository = require(schoolFoundation:WaitForChild("HousingLayoutRepository"))
local HousingEditorController = require(schoolFoundation:WaitForChild("HousingEditorController"))
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

local function createHousingLayoutStore()
    if RunService:IsStudio() and game.GameId == 0 then
        local StudioStore = require(schoolFoundation:WaitForChild("ProgressionStudioStore"))
        Workspace:SetAttribute("HousingLayoutPersistenceMode", "StudioMemoryUnpublished")
        return StudioStore.new()
    end

    Workspace:SetAttribute("HousingLayoutPersistenceMode", "DataStore")
    return VersionedDataStore.new(
        DataStoreService:GetDataStore("PipHighHousingLayoutV1")
    )
end

local economyStore = createEconomyStore()
local housingLayoutStore = createHousingLayoutStore()
local repositoryByPlayerId = {}
local layoutRepositoryByPlayerId = {}

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
local getEditorStateRemote = getOrCreateRemoteFunction(housingRoot, "GetEditorState")
local purchaseFurnitureRemote = getOrCreateRemoteFunction(housingRoot, "PurchaseFurniture")
local placeFurnitureRemote = getOrCreateRemoteFunction(housingRoot, "PlaceFurniture")
local moveFurnitureRemote = getOrCreateRemoteFunction(housingRoot, "MoveFurniture")
local rotateFurnitureRemote = getOrCreateRemoteFunction(housingRoot, "RotateFurniture")
local removeFurnitureRemote = getOrCreateRemoteFunction(housingRoot, "RemoveFurniture")
local sellFurnitureRemote = getOrCreateRemoteFunction(housingRoot, "SellFurniture")
local paintFurnitureRemote = getOrCreateRemoteFunction(housingRoot, "PaintFurniture")
local hideWallsRemote = getOrCreateRemoteFunction(housingRoot, "SetHideWalls")

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

local function openLayoutRepository(playerId, reload)
    local repository = layoutRepositoryByPlayerId[playerId]
    if repository == nil then
        local opened, openError = HousingLayoutRepository.open(housingLayoutStore, playerId)
        if opened == nil then
            return nil, tostring(openError or "layout_repository_unavailable")
        end
        repository = opened
        layoutRepositoryByPlayerId[playerId] = repository
    elseif reload == true then
        local ok, reloadError = repository:reload()
        if not ok then
            return nil, tostring(reloadError or "layout_repository_reload_failed")
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

local PAINT_COLORS = {
    ["default"] = Color3.fromRGB(151, 116, 84),
    ["legacy-blue"] = Color3.fromRGB(92, 132, 204),
    ["legacy-red"] = Color3.fromRGB(183, 127, 119),
    ["legacy-green"] = Color3.fromRGB(145, 171, 132),
    ["legacy-tan"] = Color3.fromRGB(191, 177, 155),
}

local function getFurnitureFolder(plotId)
    local plotFolder = housingPlotsFolder:FindFirstChild(plotId)
    if not plotFolder then return nil end
    local existing = plotFolder:FindFirstChild("EditorFurniture")
    if existing then return existing end
    local folder = Instance.new("Folder")
    folder.Name = "EditorFurniture"
    folder.Parent = plotFolder
    return folder
end

local function setEditorWalls(plotId, hidden)
    local folder = housingPlotsFolder:FindFirstChild(plotId)
    if not folder then return end
    folder:SetAttribute("HideWalls", hidden == true)
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BasePart") then
            if child.Name == "HouseBody" then
                child.Transparency = hidden and 1 or 0
            elseif child.Name == "HouseRoof" then
                child.Transparency = hidden and 0.82 or 0
            end
        end
    end
end

local function catalogEntry(catalog, itemId)
    for _, entry in ipairs(catalog or {}) do
        if entry.itemId == itemId then return entry end
    end
    return nil
end

local function syncEditorVisuals(player, editorState)
    if type(editorState) ~= "table"
        or editorState.accepted ~= true
        or not editorState.plotId then
        return
    end

    local plot = plotConfigById[editorState.plotId]
    local folder = getFurnitureFolder(editorState.plotId)
    if not plot or not folder then return end

    folder:ClearAllChildren()
    for _, placement in ipairs(editorState.placements or {}) do
        local entry = catalogEntry(editorState.catalog, placement.itemId)
        if entry then
            local part = Instance.new("Part")
            part.Name = "Furniture_" .. tostring(placement.placementId)
            part.Anchored = true
            part.TopSurface = Enum.SurfaceType.Smooth
            part.BottomSurface = Enum.SurfaceType.Smooth
            part.Material = Enum.Material.Wood
            if entry.geometry == "lamp" then
                part.Size = Vector3.new(2, 5, 2)
            else
                part.Size = Vector3.new(4, 3, 4)
            end
            local localY = placement.y + (part.Size.Y / 2)
            part.CFrame = CFrame.new(
                plot.houseOrigin.X + placement.x,
                plot.houseOrigin.Y + localY,
                plot.houseOrigin.Z + placement.z
            ) * CFrame.Angles(0, math.rad(placement.rotation), 0)
            part.Color = PAINT_COLORS[placement.paintId] or PAINT_COLORS.default
            part:SetAttribute("PlacementId", placement.placementId)
            part:SetAttribute("ItemId", placement.itemId)
            part:SetAttribute("OwnerUserId", player.UserId)
            part.Parent = folder
        end
    end

    local hideWalls = editorState.editing == true and editorState.hideWalls == true
    setEditorWalls(editorState.plotId, hideWalls)
    folder:SetAttribute("Editing", editorState.editing == true)
    folder:SetAttribute("OwnerUserId", player.UserId)
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

local function editorAuthorization(playerId)
    local player = Players:GetPlayerByUserId(playerId)
    if not player then return { owned = false, editing = false } end

    local repository = openRepository(playerId, true)
    if repository == nil then return { owned = false, editing = false } end

    local owned = hasHouse(repository:getState())
    local state = ensureClaim(player, owned)
    return {
        owned = owned,
        editing = state and state.editing == true or false,
        plotId = state and state.plotId or nil,
    }
end

local editorController = HousingEditorController.new({
    layoutRepositoryFactory = function(playerId)
        return openLayoutRepository(playerId, true)
    end,
    economyRepositoryFactory = function(playerId)
        return openRepository(playerId, true)
    end,
    authorize = editorAuthorization,
})

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
    local layoutState = nil
    if owned then
        local layout = openLayoutRepository(player.UserId, reload)
        if layout then
            layoutState = layout:getState()
            if houseState then
                setHouseVisual(
                    houseState.plotId,
                    true,
                    layoutState.houseStyleId or "classic-blue",
                    player.UserId
                )
            end
        end
    end

    local response = {
        available = true,
        owned = owned,
        price = HOUSE_PRICE,
        balance = economyState.balance,
        plotId = houseState and houseState.plotId or nil,
        editing = houseState and houseState.editing == true or false,
        styleId = layoutState and layoutState.houseStyleId or "classic-blue",
        hideWalls = layoutState and layoutState.hideWalls == true or false,
        inventory = layoutState and layoutState.inventory or {},
        placements = layoutState and layoutState.placements or {},
        plotAvailable = owned == false or houseState ~= nil,
        customizationPersistence = "durable_v2",
    }
    if owned and houseState and layoutState then
        response.accepted = true
        response.catalog = editorController:getCatalog()
        syncEditorVisuals(player, response)
        response.accepted = nil
    end
    return response
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
    local editorState = editorController:getState(player.UserId)
    if editorState.accepted then syncEditorVisuals(player, editorState) end
    return updated
end

styleRemote.OnServerInvoke = function(player, styleId, requestId)
    if STYLE_COLORS[styleId] == nil then
        return { accepted = false, code = "invalid_style" }
    end
    if type(requestId) ~= "string" or requestId == "" then
        return { accepted = false, code = "invalid_request_id" }
    end

    local result = editorController:setHouseStyle(player.UserId, styleId, requestId)
    if result.accepted ~= true then return result end
    setHouseVisual(result.plotId, true, result.houseStyleId, player.UserId)
    syncEditorVisuals(player, result)
    return result
end

local function editorResponse(player, response)
    if type(response) == "table" and response.accepted == true then
        syncEditorVisuals(player, response)
        local economy = openRepository(player.UserId, false)
        if economy then
            response.balance = economy:getState().balance
        end
    end
    return response
end

getEditorStateRemote.OnServerInvoke = function(player)
    return editorResponse(player, editorController:getState(player.UserId))
end

purchaseFurnitureRemote.OnServerInvoke = function(player, itemId, requestId)
    return editorResponse(player, editorController:purchase(player.UserId, itemId, requestId))
end

placeFurnitureRemote.OnServerInvoke = function(player, itemId, transform, requestId)
    return editorResponse(player, editorController:place(player.UserId, itemId, transform, requestId))
end

moveFurnitureRemote.OnServerInvoke = function(player, placementId, transform, requestId)
    return editorResponse(player, editorController:move(player.UserId, placementId, transform, requestId))
end

rotateFurnitureRemote.OnServerInvoke = function(player, placementId, deltaDegrees, requestId)
    return editorResponse(player, editorController:rotate(player.UserId, placementId, deltaDegrees, requestId))
end

removeFurnitureRemote.OnServerInvoke = function(player, placementId, itemId, requestId)
    return editorResponse(player, editorController:remove(player.UserId, placementId, itemId, requestId))
end

sellFurnitureRemote.OnServerInvoke = function(player, itemId, requestId)
    return editorResponse(player, editorController:sellInventory(player.UserId, itemId, requestId))
end

paintFurnitureRemote.OnServerInvoke = function(player, placementId, paintId, requestId)
    return editorResponse(player, editorController:paint(player.UserId, placementId, paintId, requestId))
end

hideWallsRemote.OnServerInvoke = function(player, enabled, requestId)
    return editorResponse(player, editorController:setHideWalls(player.UserId, enabled, requestId))
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
    layoutRepositoryByPlayerId[player.UserId] = nil
end)
