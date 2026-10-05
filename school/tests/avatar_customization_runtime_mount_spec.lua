local projectFile = assert(io.open("school/default.project.json", "r"))
local project = projectFile:read("*a")
projectFile:close()

local clientFile = assert(io.open("school/src/client/CanonicalSchoolClient.client.lua", "r"))
local client = clientFile:read("*a")
clientFile:close()

local function has(text, fragment, label)
    if not text:find(fragment, 1, true) then
        error("missing avatar/customization runtime mount: " .. (label or fragment), 2)
    end
end

local function lacks(text, fragment, label)
    if text:find(fragment, 1, true) then
        error("unexpected avatar/customization runtime mount: " .. (label or fragment), 2)
    end
end

has(project, '"LegacyOutfitEntry"', "Legacy outfit shared project node")
has(project, '"$path": "src/shared/LegacyOutfitEntry.lua"', "Legacy outfit shared source path")
lacks(project, '"$path": "src/client/AvatarCustomization.client.lua"', "duplicate client source mapping")

has(client, 'require(shared:WaitForChild("LegacyOutfitEntry"))', "canonical client requires Legacy outfit module")
has(client, 'local legacyOutfitSurface = LegacyOutfitEntry(player, UserInputService)', "canonical client captures Legacy outfit surface")
has(client, 'legacyOutfitSurface.entry.Visible = false', "canonical Avatar rail suppresses redundant internal entry")
has(client, 'local outfitPanel = legacyOutfitSurface.panel', "canonical client owns outfit panel position")
has(client, 'local outfitPanelScale = legacyOutfitSurface.panelScale', "canonical client owns outfit panel scale")
has(client, 'local outfitModalLayout = ResponsiveHudLayout.computeCenteredModal(layout, {', "outfit panel uses shared safe modal geometry")
has(client, 'width = 286,', "outfit modal base width")
has(client, 'height = 400,', "outfit modal base height")
has(client, 'outfitPanel.Position = UDim2.fromOffset(outfitModalLayout.x, outfitModalLayout.y)', "outfit panel follows safe layout")
has(client, 'outfitPanelScale.Scale = outfitModalLayout.scale', "outfit panel follows safe scale")

print("HIGH_SCHOOL_AVATAR_CUSTOMIZATION_RUNTIME_MOUNT_PASS")
