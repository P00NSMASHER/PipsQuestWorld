--!strict
-- Process-wide economy repository registry. Every gameplay system shares the
-- same per-player repository so a committed wage is immediately visible to
-- housing and shopping without aggressive DataStore polling.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local EconomyRepository = require(schoolFoundation:WaitForChild("EconomyRepository"))
local VersionedDataStore = require(schoolFoundation:WaitForChild("ProgressionDataStore"))

local EconomyRuntime = {}
local repositories = {}
-- Opening a repository reads from persistence and can yield.  Keep one
-- in-flight open per player so two systems joining at once (for example the
-- HUD and a nearby shop prompt) cannot create independent snapshots.
local openings = {}

local function createStore()
    if RunService:IsStudio() and game.GameId == 0 then
        local StudioStore = require(schoolFoundation:WaitForChild("ProgressionStudioStore"))
        Workspace:SetAttribute("EconomyPersistenceMode", "StudioMemoryUnpublished")
        return StudioStore.shared("economy")
    end

    Workspace:SetAttribute("EconomyPersistenceMode", "DataStore")
    return VersionedDataStore.new(DataStoreService:GetDataStore("PipHighEconomyV1"))
end

local store = createStore()

function EconomyRuntime.open(playerId, reload)
    local repository = repositories[playerId]
    if repository == nil then
        local inFlight = openings[playerId]
        if inFlight ~= nil then
            inFlight.event.Event:Wait()
            repository = repositories[playerId]
            if repository == nil then
                return nil, inFlight.error or "repository_unavailable"
            end
        else
            inFlight = {
                event = Instance.new("BindableEvent"),
                error = nil,
                released = false,
            }
            openings[playerId] = inFlight

            local callSucceeded, opened, openError = pcall(
                EconomyRepository.open,
                store,
                playerId
            )
            if callSucceeded ~= true then
                openError = "repository_open_failed:" .. tostring(opened)
                opened = nil
            end

            if opened ~= nil and inFlight.released ~= true then
                repositories[playerId] = opened
                repository = opened
            elseif inFlight.released == true then
                openError = "repository_released"
            end

            inFlight.error = openError
            if openings[playerId] == inFlight then
                openings[playerId] = nil
            end
            inFlight.event:Fire()

            if repository == nil then
                return nil, openError or "repository_unavailable"
            end
        end
    elseif reload == true then
        local ok, reloadError = repository:reload()
        if not ok then
            return nil, reloadError
        end
    end
    return repository, nil
end

function EconomyRuntime.release(playerId)
    repositories[playerId] = nil
    local inFlight = openings[playerId]
    if inFlight ~= nil then
        inFlight.released = true
    end
end

return EconomyRuntime
