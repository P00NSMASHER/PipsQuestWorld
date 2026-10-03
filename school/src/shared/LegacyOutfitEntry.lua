-- Exact-reference avatar/customization entry surface.
-- Verified Legacy names/labels come from Content-QA PR #150.
-- Layout/styling remain explicitly non-exact until verified reference geometry is available.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local function mount(player, UserInputService)
local playerGui = player:WaitForChild("PlayerGui")
local outfitRoot = ReplicatedStorage:WaitForChild("SchoolFoundation")
    :WaitForChild("FreeRoam")
    :WaitForChild("Outfits")
local loadOutfit = outfitRoot:WaitForChild("LoadOutfit")
local loadOutfitPage = outfitRoot:WaitForChild("LoadOutfitPage")
local getFilteredNamesForOutfit = outfitRoot:WaitForChild("GetFilteredNamesForOutfit")
local wearOutfit = outfitRoot:WaitForChild("WearOutfit")
local saveOutfit = outfitRoot:WaitForChild("SaveOutfit")

local function exactGuiName()
    if UserInputService.TouchEnabled then
        return "OutfitsMobile"
    end
    if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
        return "OutfitsConsole"
    end
    return "Outfits"
end

local gui = Instance.new("ScreenGui")
gui.Name = exactGuiName()
gui.ResetOnSpawn = false
gui:SetAttribute("ReferenceExactIdentity", true)
gui:SetAttribute("ReferenceExactLayout", false)
gui.Parent = playerGui

local entry = Instance.new("TextButton")
entry.Name = "OutfitEntryInternal"
entry.Text = "Custom Outfits"
entry.Size = UDim2.fromOffset(132, 34)
entry.Position = UDim2.new(1, -144, 0, 12)
entry:SetAttribute("ReferenceExactLabel", true)
entry:SetAttribute("ReferenceExactLayout", false)
entry.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "OutfitInputs"
panel.Size = UDim2.fromOffset(286, 262)
panel.Position = UDim2.new(0.5, -143, 0.5, -131)
panel.Visible = false
panel:SetAttribute("ReferenceExactHierarchy", true)
panel:SetAttribute("ReferenceExactLayout", false)
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "OutfitName"
title.Text = "Custom Outfits"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title:SetAttribute("ReferenceExactLabel", true)
title.Parent = panel

local slots = Instance.new("Frame")
slots.Name = "OutfitSlots"
slots.BackgroundTransparency = 1
slots.Position = UDim2.new(0, 8, 0, 38)
slots.Size = UDim2.new(1, -16, 0, 102)
slots:SetAttribute("ReferenceExactHierarchy", true)
slots:SetAttribute("SavedOutfitSlotCount", 12)
slots.Parent = panel

for index = 1, 12 do
    local slot = Instance.new("TextButton")
    slot.Name = "Slot" .. tostring(index)
    slot.Text = "Empty"
    slot.Size = UDim2.fromOffset(60, 24)
    slot.Position = UDim2.fromOffset(((index - 1) % 4) * 66, math.floor((index - 1) / 4) * 30)
    slot:SetAttribute("ReferenceExactEmptyLabel", true)
    slot:SetAttribute("ReferenceExactLayout", false)
    slot.Parent = slots
end

local pages = Instance.new("Frame")
pages.Name = "OutfitPages"
pages.BackgroundTransparency = 1
pages.Position = UDim2.new(0, 8, 0, 146)
pages.Size = UDim2.new(1, -16, 0, 1)
pages:SetAttribute("ReferenceExactHierarchy", true)
pages:SetAttribute("PageStart1", 1)
pages:SetAttribute("PageStart2", 4)
pages:SetAttribute("PageStart3", 7)
pages:SetAttribute("PageStart4", 10)
pages.Parent = panel

local morphs = Instance.new("Frame")
morphs.Name = "MorphsFrame"
morphs.BackgroundTransparency = 1
morphs.Position = UDim2.new(0, 8, 0, 160)
morphs.Size = UDim2.new(1, -16, 0, 48)
morphs:SetAttribute("ReferenceExactHierarchy", true)
morphs.Parent = panel

local r6Warning = Instance.new("TextLabel")
r6Warning.Name = "R6WarningInternal"
r6Warning.Text = "[Morphs only work with R6]"
r6Warning.BackgroundTransparency = 1
r6Warning.Size = UDim2.new(1, 0, 0, 24)
r6Warning:SetAttribute("ReferenceExactLabel", true)
r6Warning.Parent = morphs

local verifiedInputLabels = {
    { name = "WearOutfitLabel", text = "Wear Outfit" },
    { name = "SaveOutfitLabel", text = "Save Outfit:" },
    { name = "Hat1Label", text = "Hat 1:" },
    { name = "Hat2Label", text = "Hat 2:" },
    { name = "Hat3Label", text = "Hat 3:" },
    { name = "ShirtLabel", text = "Shirt:" },
    { name = "PantsLabel", text = "Pants:" },
    { name = "RemoveShirtLabel", text = "Remove Shirt:" },
    { name = "OutfitNameLabel", text = "Outfit Name:" },
}

local actionControls = {}

for index, definition in ipairs(verifiedInputLabels) do
    local isAction = definition.name == "WearOutfitLabel" or definition.name == "SaveOutfitLabel"
    local label = Instance.new(isAction and "TextButton" or "TextLabel")
    label.Name = definition.name
    label.Text = definition.text
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromOffset(128, 20)
    label.Position = UDim2.fromOffset(8, 210 + ((index - 1) * 20))
    label:SetAttribute("ReferenceExactLabel", true)
    label:SetAttribute("ReferenceExactLayout", false)
    label.Parent = panel
    if isAction then actionControls[definition.name] = label end
end

local fieldValues = {}
for _, fieldName in ipairs({ "Hat1", "Hat2", "Hat3", "Shirt", "Pants", "Face", "Package" }) do
    local marker = Instance.new("IntValue")
    marker.Name = fieldName
    marker.Value = 0
    marker:SetAttribute("ReferenceExactHierarchy", true)
    marker.Parent = panel
    fieldValues[fieldName] = marker
end
for _, fieldName in ipairs({ "RPName", "RPDesc" }) do
    local marker = Instance.new("StringValue")
    marker.Name = fieldName
    marker.Value = ""
    marker:SetAttribute("ReferenceExactHierarchy", true)
    marker.Parent = panel
    fieldValues[fieldName] = marker
end
local removeShirt = Instance.new("BoolValue")
removeShirt.Name = "RemoveShirt"
removeShirt.Value = false
removeShirt:SetAttribute("ReferenceExactHierarchy", true)
removeShirt.Parent = panel
fieldValues.RemoveShirt = removeShirt

local baseSlot = Instance.new("IntValue")
baseSlot.Name = "BaseSlot"
baseSlot.Value = 1
baseSlot:SetAttribute("ReferenceExactHierarchy", true)
baseSlot.Parent = panel

local selectedSlot = 1
local selectedOutfit = nil
local pendingSaveRequestId = nil

local function applyLoadedOutfit(slot, outfit)
    if type(outfit) ~= "table" then return end
    selectedSlot = slot
    selectedOutfit = outfit
    for fieldName, marker in pairs(fieldValues) do
        local value = outfit[fieldName]
        if value ~= nil then marker.Value = value end
    end
end

local function refreshPage(startSlot)
    local ok, response = pcall(function()
        return loadOutfitPage:InvokeServer(startSlot)
    end)
    if not ok or type(response) ~= "table" or response.accepted ~= true then return end
    baseSlot.Value = startSlot
    for _, entryData in ipairs(response.outfits or {}) do
        local slotButton = slots:FindFirstChild("Slot" .. tostring(entryData.slot))
        local outfit = entryData.outfit
        if slotButton and type(outfit) == "table" then
            slotButton.Text = outfit.OutfitName ~= "" and outfit.OutfitName or "Empty"
        end
    end
end

for index = 1, 12 do
    local slot = slots:FindFirstChild("Slot" .. tostring(index))
    if slot and slot:IsA("TextButton") then
        slot.Activated:Connect(function()
            local ok, response = pcall(function()
                return loadOutfit:InvokeServer(index)
            end)
            if ok and type(response) == "table" and response.accepted == true then
                if response.status ~= "noload" then
                    applyLoadedOutfit(index, response.outfit)
                else
                    selectedSlot = index
                    selectedOutfit = nil
                end
            end
        end)
    end
end

actionControls.WearOutfitLabel.Activated:Connect(function()
    local ok, response = pcall(function()
        return wearOutfit:InvokeServer(selectedSlot)
    end)
    if ok and type(response) == "table" and response.accepted == true then
        applyLoadedOutfit(selectedSlot, response.outfit)
    end
end)

actionControls.SaveOutfitLabel.Activated:Connect(function()
    local outfit = {
        OutfitName = selectedOutfit and selectedOutfit.OutfitName or "",
        Hat1 = 0,
        Hat2 = 0,
        Hat3 = 0,
        Shirt = 0,
        Pants = 0,
        Face = 0,
        Package = 0,
        RPName = selectedOutfit and selectedOutfit.RPName or "",
        RPDesc = selectedOutfit and selectedOutfit.RPDesc or "",
        RemoveShirt = false,
    }
    for fieldName, marker in pairs(fieldValues) do
        outfit[fieldName] = marker.Value
    end

    local filterOk, filtered = pcall(function()
        return getFilteredNamesForOutfit:InvokeServer(outfit)
    end)
    if not filterOk or type(filtered) ~= "table" or filtered.accepted ~= true then
        if type(filtered) == "table" and filtered.code == "INVALID_NAME" then
            pendingSaveRequestId = nil
        end
        return
    end
    outfit.OutfitName = filtered.OutfitName
    outfit.RPName = filtered.RPName
    outfit.RPDesc = filtered.RPDesc

    if pendingSaveRequestId == nil then
        pendingSaveRequestId = HttpService:GenerateGUID(false)
    end
    local requestId = pendingSaveRequestId
    local ok, response = pcall(function()
        return saveOutfit:InvokeServer(selectedSlot, outfit, requestId)
    end)
    if ok and type(response) == "table" then
        if response.accepted == true then
            pendingSaveRequestId = nil
            applyLoadedOutfit(selectedSlot, response.outfit)
            refreshPage(baseSlot.Value)
        elseif response.retryable ~= true then
            pendingSaveRequestId = nil
        end
    end
end)

entry.Activated:Connect(function()
    panel.Visible = not panel.Visible
    if panel.Visible then refreshPage(baseSlot.Value) end
end)


return mount
