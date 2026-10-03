local function read(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a")
    file:close()
    return text
end

local project = read("school/default.project.json")
local service = read("school/src/server/OutfitOperations.server.lua")
local persistence = read("school/src/server/ProgressionPersistence.lua")
local classEducation = read("school/src/server/ClassEducation.server.lua")
local client = read("school/src/shared/LegacyOutfitEntry.lua")

local function has(text, fragment, label)
    if not text:find(fragment, 1, true) then
        error("missing outfit runtime contract: " .. (label or fragment), 2)
    end
end

local function lacks(text, fragment, label)
    if text:find(fragment, 1, true) then
        error("forbidden outfit runtime contract: " .. (label or fragment), 2)
    end
end

has(project, '"OutfitOperationsController"', "controller project mapping")
has(project, '"OutfitOperations"', "service project mapping")
has(project, '"ProgressionPersistence"', "single persistence provider mapping")
has(service, 'getOrCreateRemoteFunction(outfitRoot, "LoadOutfit")', "LoadOutfit remote")
has(service, 'getOrCreateRemoteFunction(outfitRoot, "LoadOutfitPage")', "LoadOutfitPage remote")
has(service, 'getOrCreateRemoteFunction(outfitRoot, "GetFilteredNamesForOutfit")', "GetFilteredNamesForOutfit remote")
has(service, 'getOrCreateRemoteFunction(outfitRoot, "WearOutfit")', "WearOutfit remote")
has(service, 'getOrCreateRemoteFunction(outfitRoot, "SaveOutfit")', "SaveOutfit remote")
has(service, 'TextService:FilterStringAsync(value, player.UserId)', "server identity filtering")
has(service, 'return ProgressionRepository.open(progressionStore, playerId)', "canonical repository reuse")
has(service, 'description.HatAccessory = table.concat(hats, ",")', "three-hat server application")
has(service, 'description.Shirt = outfit.RemoveShirt and 0 or outfit.Shirt', "server shirt application")
has(service, 'description.Pants = outfit.Pants', "server pants application")
has(service, 'description.Face = outfit.Face', "server face application")
has(persistence, 'DataStoreService:GetDataStore("PipHighProgressionV1")', "single canonical datastore")
has(classEducation, 'local progressionStore = ProgressionPersistence.get()', "class uses shared persistence provider")
has(service, 'local progressionStore = ProgressionPersistence.get()', "outfits use shared persistence provider")
has(client, 'WaitForChild("LoadOutfit")', "client LoadOutfit binding")
has(client, 'WaitForChild("LoadOutfitPage")', "client LoadOutfitPage binding")
has(client, 'WaitForChild("GetFilteredNamesForOutfit")', "client filtered-name binding")
has(client, 'WaitForChild("WearOutfit")', "client WearOutfit binding")
has(client, 'WaitForChild("SaveOutfit")', "client SaveOutfit binding")
has(client, 'loadOutfit:InvokeServer(index)', "client requests server slot load")
has(client, 'loadOutfitPage:InvokeServer(startSlot)', "client requests server page")
has(client, 'wearOutfit:InvokeServer(selectedSlot)', "client requests server wear")
has(client, 'getFilteredNamesForOutfit:InvokeServer(outfit)', "client requests server filtering")
has(client, 'saveOutfit:InvokeServer(selectedSlot, outfit, requestId)', "client requests idempotent server save")
has(client, 'pendingSaveRequestId = HttpService:GenerateGUID(false)', "client generates stable save request id")
has(client, 'elseif response.retryable ~= true then', "client retains request id across retryable failures")
lacks(client, "DataStoreService", "client datastore authority")
lacks(client, "TextService:FilterStringAsync", "client filtering authority")
lacks(service, "Robux", "shopping behavior excluded")
lacks(service, "PurchasePermanentItem", "shopping purchase excluded")
lacks(client, "Slot13", "storage-only slots are not presented")
lacks(client, "Slot24", "storage-only slots are not presented")

print("HIGH_SCHOOL_OUTFIT_OPERATIONS_RUNTIME_PASS")
