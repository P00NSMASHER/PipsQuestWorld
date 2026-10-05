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
panel.Size = UDim2.fromOffset(560, 360)
panel.Position = UDim2.new(0.5, -280, 0.5, -180)
panel.BackgroundColor3 = Color3.fromRGB(229, 241, 249)
panel.ClipsDescendants = true
panel.Visible = false
panel:SetAttribute("ReferenceExactHierarchy", true)
panel:SetAttribute("ReferenceExactLayout", false)
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "OutfitName"
title.Text = "Custom Outfits"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(31, 72, 102)
title.TextSize = 18
title:SetAttribute("ReferenceExactLabel", true)
title.Parent = panel

local slots = Instance.new("Frame")
slots.Name = "OutfitSlots"
slots.BackgroundTransparency = 1
slots.Position = UDim2.new(0, 14, 0, 42)
slots.Size = UDim2.new(0.52, -20, 0, 112)
slots:SetAttribute("ReferenceExactHierarchy", true)
slots:SetAttribute("SavedOutfitSlotCount", 12)
slots.Parent = panel

for index = 1, 12 do
    local slot = Instance.new("TextButton")
    slot.Name = "Slot" .. tostring(index)
    slot.Text = "Empty"
    slot.Size = UDim2.new(0.25, -5, 0, 28)
    slot.Position = UDim2.new(((index - 1) % 4) * 0.25, 0, 0, math.floor((index - 1) / 4) * 34)
    slot.BackgroundColor3 = Color3.fromRGB(238, 244, 249)
    slot.Font = Enum.Font.GothamBold
    slot.TextColor3 = Color3.fromRGB(31, 72, 102)
    slot.TextSize = 11
    slot:SetAttribute("ReferenceExactEmptyLabel", true)
    slot:SetAttribute("ReferenceExactLayout", false)
    slot.Parent = slots
end

local pages = Instance.new("Frame")
pages.Name = "OutfitPages"
pages.BackgroundTransparency = 1
pages.Position = UDim2.new(0, 14, 0, 160)
pages.Size = UDim2.new(0.52, -20, 0, 1)
pages:SetAttribute("ReferenceExactHierarchy", true)
pages:SetAttribute("PageStart1", 1)
pages:SetAttribute("PageStart2", 4)
pages:SetAttribute("PageStart3", 7)
pages:SetAttribute("PageStart4", 10)
pages.Parent = panel

local morphs = Instance.new("Frame")
morphs.Name = "MorphsFrame"
morphs.BackgroundTransparency = 1
morphs.Position = UDim2.new(0, 14, 0, 174)
morphs.Size = UDim2.new(0.52, -20, 0, 48)
morphs:SetAttribute("ReferenceExactHierarchy", true)
morphs.Parent = panel

local r6Warning = Instance.new("TextLabel")
r6Warning.Name = "R6WarningInternal"
r6Warning.Text = "[Morphs only work with R6]"
r6Warning.BackgroundTransparency = 1
r6Warning.Size = UDim2.new(1, 0, 0, 24)
r6Warning:SetAttribute("ReferenceExactLabel", true)
r6Warning.Parent = morphs

local details = Instance.new("ScrollingFrame")
details.Name = "OutfitDetails"
details.BackgroundColor3 = Color3.fromRGB(243, 248, 252)
details.BackgroundTransparency = 0.08
details.BorderSizePixel = 0
details.Position = UDim2.new(0.52, 2, 0, 42)
details.Size = UDim2.new(0.48, -16, 1, -56)
details.CanvasSize = UDim2.fromOffset(0, 372)
details.ScrollBarThickness = 5
details.ScrollBarImageColor3 = Color3.fromRGB(57, 126, 168)
details.Parent = panel

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
local inputControls = {}
local detailRow = 0

for index, definition in ipairs(verifiedInputLabels) do
    local isAction = definition.name == "WearOutfitLabel" or definition.name == "SaveOutfitLabel"
    local label = Instance.new(isAction and "TextButton" or "TextLabel")
    label.Name = definition.name
    label.Text = definition.text
    label:SetAttribute("ReferenceExactLabel", true)
    label:SetAttribute("ReferenceExactLayout", false)
    label.Parent = details
    if isAction then
        label.BackgroundColor3 = definition.name == "WearOutfitLabel"
            and Color3.fromRGB(54, 174, 221)
            or Color3.fromRGB(83, 188, 77)
        label.Size = UDim2.new(1, -16, 0, 32)
        label.Position = UDim2.fromOffset(8, definition.name == "WearOutfitLabel" and 8 or 46)
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 12
        actionControls[definition.name] = label
    else
        local fieldName = definition.name:gsub("Label$", "")
        local rowY = 88 + (detailRow * 40)
        detailRow = detailRow + 1
        label.BackgroundTransparency = 1
        label.Position = UDim2.fromOffset(8, rowY)
        label.Size = UDim2.fromOffset(92, 32)
        label.Font = Enum.Font.Gotham
        label.TextColor3 = Color3.fromRGB(31, 72, 102)
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left

        local input = Instance.new(fieldName == "RemoveShirt" and "TextButton" or "TextBox")
        input.Name = fieldName .. "Input"
        input.Position = UDim2.fromOffset(102, rowY + 2)
        input.Size = UDim2.new(1, -110, 0, 28)
        input.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        input.Font = Enum.Font.Gotham
        input.TextColor3 = Color3.fromRGB(31, 72, 102)
        input.TextSize = 11
        input.Text = fieldName == "OutfitName" and "New Outfit" or (fieldName == "RemoveShirt" and "OFF" or "0")
        if input:IsA("TextBox") then
            input.ClearTextOnFocus = false
            input.PlaceholderText = fieldName == "OutfitName" and "Outfit name" or "Asset ID"
        end
        input.Parent = details
        inputControls[fieldName] = input
    end
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

local function syncInputControls()
    for fieldName, control in pairs(inputControls) do
        if fieldName == "OutfitName" then
            control.Text = selectedOutfit and tostring(selectedOutfit.OutfitName or "") or "New Outfit"
        elseif fieldName == "RemoveShirt" then
            control.Text = fieldValues.RemoveShirt.Value and "ON" or "OFF"
            control.BackgroundColor3 = fieldValues.RemoveShirt.Value
                and Color3.fromRGB(220, 66, 66)
                or Color3.fromRGB(255, 255, 255)
            control.TextColor3 = fieldValues.RemoveShirt.Value
                and Color3.fromRGB(255, 255, 255)
                or Color3.fromRGB(31, 72, 102)
        elseif fieldValues[fieldName] then
            control.Text = tostring(fieldValues[fieldName].Value)
        end
    end
end

for fieldName, control in pairs(inputControls) do
    if fieldName == "RemoveShirt" then
        control.Activated:Connect(function()
            fieldValues.RemoveShirt.Value = not fieldValues.RemoveShirt.Value
            syncInputControls()
        end)
    elseif control:IsA("TextBox") then
        control.FocusLost:Connect(function()
            if fieldName == "OutfitName" then
                selectedOutfit = selectedOutfit or {}
                selectedOutfit.OutfitName = control.Text
                return
            end
            local marker = fieldValues[fieldName]
            if marker and marker:IsA("IntValue") then
                marker.Value = math.max(0, math.floor(tonumber(control.Text) or marker.Value))
                control.Text = tostring(marker.Value)
            end
        end)
    end
end

local function applyLoadedOutfit(slot, outfit)
    if type(outfit) ~= "table" then return end
    selectedSlot = slot
    selectedOutfit = outfit
    for fieldName, marker in pairs(fieldValues) do
        local value = outfit[fieldName]
        if value ~= nil then marker.Value = value end
    end
    syncInputControls()
end

local function refreshPage(startSlot)
    local ok, response = pcall(function()
        return loadOutfitPage:InvokeServer(startSlot)
    end)
    if not ok or type(response) ~= "table" or response.accepted ~= true then return end
    baseSlot.Value = startSlot
    for index = 1, 12 do
        local slotButton = slots:FindFirstChild("Slot" .. tostring(index))
        if slotButton then slotButton.Text = "Empty" end
    end
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
        OutfitName = inputControls.OutfitName and inputControls.OutfitName.Text
            or (selectedOutfit and selectedOutfit.OutfitName or ""),
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
    -- GetFilteredNamesForOutfit is the verified preview/validation seam.
    -- SaveOutfit receives the original values and performs the authoritative
    -- server filter exactly once before durability.
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

return {
    panel = panel,
    entry = entry,
    refresh = function()
        refreshPage(baseSlot.Value)
    end,
}

end

return mount
