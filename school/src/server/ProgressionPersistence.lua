--!strict
-- Single canonical durable progression adapter provider.
-- Both class progression and Free-Roam outfit operations consume this same adapter.

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local schoolFoundation = ServerScriptService:WaitForChild("SchoolFoundation")
local ProgressionDataStore = require(schoolFoundation:WaitForChild("ProgressionDataStore"))

local Provider = {}
local singleton = nil

function Provider.get()
    if singleton ~= nil then return singleton end

    if RunService:IsStudio() and game.GameId == 0 then
        local ProgressionStudioStore = require(
            schoolFoundation:WaitForChild("ProgressionStudioStore")
        )
        Workspace:SetAttribute("ProgressionPersistenceMode", "StudioMemoryUnpublished")
        singleton = ProgressionStudioStore.new()
        return singleton
    end

    local DataStoreService = game:GetService("DataStoreService")
    Workspace:SetAttribute("ProgressionPersistenceMode", "DataStore")
    singleton = ProgressionDataStore.new(
        DataStoreService:GetDataStore("PipHighProgressionV1")
    )
    return singleton
end

return Provider
