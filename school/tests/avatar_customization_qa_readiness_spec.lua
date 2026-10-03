-- QA-owned deterministic readiness contract for the avatar/customization/shopping slice.
-- This file validates mounting, device identity, authority boundaries, and coexistence only.
-- It does not implement producer semantics.

local function read(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("*a")
    file:close()
    return text
end

local project = read("school/default.project.json")
local canonical = read("school/src/client/CanonicalSchoolClient.client.lua")
local sharedEntry = read("school/src/shared/LegacyOutfitEntry.lua")
local standaloneClient = read("school/src/client/AvatarCustomization.client.lua")

local function has(text, fragment, label)
    if not text:find(fragment, 1, true) then
        error("avatar/customization QA contract missing: " .. (label or fragment), 2)
    end
end

local function lacks(text, fragment, label)
    if text:find(fragment, 1, true) then
        error("avatar/customization QA authority violation: " .. (label or fragment), 2)
    end
end

local function count(text, fragment)
    local total = 0
    local start = 1
    while true do
        local first, last = text:find(fragment, start, true)
        if not first then
            return total
        end
        total = total + 1
        start = last + 1
    end
end

-- Runtime mounting: one shared implementation, mounted exactly once by the canonical client.
has(project, '"LegacyOutfitEntry"', "shared Legacy outfit project node")
has(project, '"$path": "src/shared/LegacyOutfitEntry.lua"', "shared Legacy outfit source mapping")
lacks(project, '"$path": "src/client/AvatarCustomization.client.lua"', "standalone duplicate client must remain unmounted")

local requireFragment = 'require(shared:WaitForChild("LegacyOutfitEntry"))'
local mountFragment = 'LegacyOutfitEntry(player, UserInputService)'
if count(canonical, requireFragment) ~= 1 then
    error("avatar/customization QA contract missing: canonical client must require LegacyOutfitEntry exactly once", 2)
end
if count(canonical, mountFragment) ~= 1 then
    error("avatar/customization QA contract missing: canonical client must mount LegacyOutfitEntry exactly once", 2)
end

-- Verified device identities and precedence from Content-QA provenance.
has(sharedEntry, 'if UserInputService.TouchEnabled then', "touch identity branch")
has(sharedEntry, 'return "OutfitsMobile"', "mobile GUI identity")
has(sharedEntry, 'if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then', "console identity branch")
has(sharedEntry, 'return "OutfitsConsole"', "console GUI identity")
has(sharedEntry, 'return "Outfits"', "desktop GUI identity")
has(sharedEntry, 'gui:SetAttribute("ReferenceExactIdentity", true)', "exact identity marker")
has(sharedEntry, 'gui:SetAttribute("ReferenceExactLayout", false)', "unverified layout remains explicit")

-- Server/persistence boundaries: presentation code must not become an authority.
for _, source in ipairs({ sharedEntry, standaloneClient }) do
    lacks(source, 'GetService("DataStoreService")', "client DataStoreService")
    lacks(source, "GetDataStore(", "client GetDataStore")
    lacks(source, "SetAsync(", "client SetAsync")
    lacks(source, "UpdateAsync(", "client UpdateAsync")
    lacks(source, "IncrementAsync(", "client IncrementAsync")
    lacks(source, 'Instance.new("RemoteEvent")', "client-created RemoteEvent")
    lacks(source, 'Instance.new("RemoteFunction")', "client-created RemoteFunction")
end

-- Exact pinned-baseline identity/hierarchy signals already verified by Content QA.
for _, fragment in ipairs({
    'entry.Text = "Custom Outfits"',
    'panel.Name = "OutfitInputs"',
    'slots.Name = "OutfitSlots"',
    'slots:SetAttribute("SavedOutfitSlotCount", 12)',
    'pages:SetAttribute("PageStart1", 1)',
    'pages:SetAttribute("PageStart2", 4)',
    'pages:SetAttribute("PageStart3", 7)',
    'pages:SetAttribute("PageStart4", 10)',
    'r6Warning.Text = "[Morphs only work with R6]"',
}) do
    has(sharedEntry, fragment, fragment)
end
lacks(sharedEntry, "Hat4", "later nine-hat revision must not leak")
lacks(sharedEntry, "Hat9", "later nine-hat revision must not leak")

-- The new entry must coexist with the already-certified Legacy HUD and House surfaces.
has(canonical, 'gui.Name = "RobloxHighSchoolLegacyUI"', "Legacy HUD coexistence")
has(canonical, 'houseIcon.Name = "LegacyHouseButton"', "Legacy House button coexistence")
has(canonical, 'housePanel.Name = "LegacyHousePanel"', "Legacy House panel coexistence")
has(canonical, 'editorPanel.Name = "LegacyHousingEditorV2"', "Housing Editor V2 coexistence")

-- Phase-2/retired-product leakage is forbidden in this slice.
for _, forbidden in ipairs({
    "StarBlox",
    "Brookhaven",
    "PipsQuest",
    "Maze World",
    "second-grade",
    "second grade",
    "STAR-style",
}) do
    lacks(sharedEntry, forbidden, "deferred/retired product marker " .. forbidden)
    lacks(standaloneClient, forbidden, "deferred/retired product marker " .. forbidden)
end

print("HIGH_SCHOOL_AVATAR_CUSTOMIZATION_QA_READINESS_PASS")
