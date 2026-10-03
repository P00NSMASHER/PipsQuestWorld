--!strict
-- Exact-reference avatar/customization entry surface.
-- Verified Legacy names/labels come from Content-QA PR #150.
-- Layout/styling remain explicitly non-exact until verified reference geometry is available.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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

for index, definition in ipairs(verifiedInputLabels) do
    local label = Instance.new("TextLabel")
    label.Name = definition.name
    label.Text = definition.text
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromOffset(128, 20)
    label.Position = UDim2.fromOffset(8, 210 + ((index - 1) * 20))
    label:SetAttribute("ReferenceExactLabel", true)
    label:SetAttribute("ReferenceExactLayout", false)
    label.Parent = panel
end

for _, fieldName in ipairs({ "Hat1", "Hat2", "Hat3", "Shirt", "Pants", "Face", "RemoveShirt", "RPName", "RPDesc", "BaseSlot" }) do
    local marker = Instance.new("StringValue")
    marker.Name = fieldName
    marker.Value = ""
    marker:SetAttribute("ReferenceExactHierarchy", true)
    marker.Parent = panel
end

entry.Activated:Connect(function()
    panel.Visible = not panel.Visible
end)
