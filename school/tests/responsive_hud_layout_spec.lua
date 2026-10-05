local ResponsiveHudLayout = assert(loadfile("school/src/shared/ResponsiveHudLayout.lua"))()

local function approxBetween(value, minimum, maximum, label)
    if value < minimum or value > maximum then
        error(string.format("%s: %.4f outside [%.4f, %.4f]", label, value, minimum, maximum), 2)
    end
end

local function zone(x, y, width, height)
    return {
        x = x,
        y = y,
        width = width,
        height = height,
        right = x + width,
        bottom = y + height,
    }
end

local fixtures = {
    {
        name = "reference-desktop-909x483",
        viewport = { width = 909, height = 483 },
        insets = { left = 0, top = 0, right = 0, bottom = 0 },
    },
    {
        name = "iphone-landscape-852x393",
        viewport = { width = 852, height = 393 },
        insets = { left = 47, top = 12, right = 47, bottom = 21 },
    },
    {
        name = "ipad-landscape-1024x768",
        viewport = { width = 1024, height = 768 },
        insets = { left = 24, top = 24, right = 24, bottom = 20 },
    },
}

for _, fixture in ipairs(fixtures) do
    fixture.zones = fixture.name == "reference-desktop-909x483"
        and {}
        or ResponsiveHudLayout.touchExclusionZones(fixture.viewport, fixture.insets)
end

local layouts = {}
for _, fixture in ipairs(fixtures) do
    local layout = ResponsiveHudLayout.compute(
        fixture.viewport,
        fixture.insets,
        fixture.zones
    )
    local valid, reason = ResponsiveHudLayout.validate(layout)
    assert(valid, fixture.name .. ": " .. tostring(reason))

    for _, group in ipairs({ layout.status, layout.rail, layout.quick }) do
        assert(ResponsiveHudLayout.contains(layout.safe, group), fixture.name .. ": HUD group outside safe area")
    end
    assert(not ResponsiveHudLayout.overlaps(layout.status, layout.rail), fixture.name .. ": status/rail overlap")
    assert(not ResponsiveHudLayout.overlaps(layout.status, layout.quick), fixture.name .. ": status/quick overlap")
    assert(not ResponsiveHudLayout.overlaps(layout.rail, layout.quick), fixture.name .. ": rail/quick overlap")

    local auxiliary = ResponsiveHudLayout.computeAuxiliaryPanels(layout)
    local auxiliaryValid, auxiliaryReason = ResponsiveHudLayout.validateAuxiliaryPanels(layout, auxiliary)
    assert(auxiliaryValid, fixture.name .. ": " .. tostring(auxiliaryReason))
    layout.auxiliary = auxiliary

    for _, panel in ipairs({ auxiliary.house, auxiliary.editor }) do
        assert(ResponsiveHudLayout.contains(layout.safe, panel), fixture.name .. ": auxiliary panel outside safe area")
        assert(not ResponsiveHudLayout.overlaps(panel, layout.status), fixture.name .. ": auxiliary/status overlap")
        assert(not ResponsiveHudLayout.overlaps(panel, layout.rail), fixture.name .. ": auxiliary/rail overlap")
        assert(not ResponsiveHudLayout.overlaps(panel, layout.quick), fixture.name .. ": auxiliary/quick overlap")
    end
    assert(not ResponsiveHudLayout.overlaps(auxiliary.house, auxiliary.editor), fixture.name .. ": auxiliary panels overlap")

    for index, exclusion in ipairs(fixture.zones) do
        assert(not ResponsiveHudLayout.overlaps(auxiliary.house, exclusion), fixture.name .. ": house/movement-camera overlap " .. index)
        assert(not ResponsiveHudLayout.overlaps(auxiliary.editor, exclusion), fixture.name .. ": editor/movement-camera overlap " .. index)
        assert(ResponsiveHudLayout.contains(layout.safe, exclusion), fixture.name .. ": touch zone outside safe area")
        assert(not ResponsiveHudLayout.overlaps(layout.status, exclusion), fixture.name .. ": status/movement-camera overlap " .. index)
        assert(not ResponsiveHudLayout.overlaps(layout.rail, exclusion), fixture.name .. ": rail/movement-camera overlap " .. index)
        assert(not ResponsiveHudLayout.overlaps(layout.quick, exclusion), fixture.name .. ": quick/movement-camera overlap " .. index)
        assert(exclusion.width == math.min(190, math.floor(fixture.viewport.width * 0.22)), fixture.name .. ": normalized touch-zone width")
        assert(exclusion.height == math.min(120, math.floor(fixture.viewport.height * 0.25)), fixture.name .. ": normalized touch-zone height")
        assert(exclusion.bottom == fixture.viewport.height - fixture.insets.bottom, fixture.name .. ": touch zone respects bottom safe inset")
    end

    assert(layout.railButtonSize * 4 + layout.railGap * 3 <= layout.rail.height, fixture.name .. ": rail buttons exceed rail")
    assert(layout.quickSlotSize * 4 + layout.quickGap * 3 <= layout.quick.width, fixture.name .. ": quick slots exceed bar")
    assert(layout.quickSlotSize <= layout.quick.height, fixture.name .. ": quick slots exceed bar height")

    if #fixture.zones > 0 then
        assert(fixture.zones[1].x == fixture.insets.left, fixture.name .. ": left movement zone respects safe inset")
        assert(fixture.zones[2].right == fixture.viewport.width - fixture.insets.right, fixture.name .. ": right camera zone respects safe inset")
        assert(layout.status.y >= fixture.insets.top, fixture.name .. ": status ignores top safe inset")
        assert(layout.rail.y >= fixture.insets.top, fixture.name .. ": rail ignores top safe inset")
    end

    layouts[fixture.name] = layout
end

local nominal = layouts["reference-desktop-909x483"]
approxBetween(nominal.status.width / 909, 0.129, 0.131, "nominal normalized status width")
approxBetween(nominal.status.height / 483, 0.146, 0.148, "nominal normalized status height")
approxBetween(nominal.rail.width / 909, 0.045, 0.065, "nominal rail width")
approxBetween(nominal.rail.height / 483, 0.40, 0.48, "nominal rail height")
approxBetween(nominal.quick.width / 909, 0.24, 0.30, "nominal quick width")
approxBetween(nominal.quick.height / 483, 0.09, 0.13, "nominal quick height")

local iphone = layouts["iphone-landscape-852x393"]
local ipad = layouts["ipad-landscape-1024x768"]
assert(nominal.auxiliary.house.scale == 1 and nominal.auxiliary.editor.scale == 1, "desktop auxiliary panels keep native scale")
assert(ipad.auxiliary.house.scale == 1 and ipad.auxiliary.editor.scale == 1, "iPad auxiliary panels keep native scale")
assert(iphone.auxiliary.house.scale < 1, "iPhone house panel must reflow")
assert(iphone.auxiliary.editor.scale < 1, "iPhone housing editor must reflow")
assert(iphone.auxiliary.house.y >= iphone.safe.y, "iPhone house panel safe-top clearance")
assert(iphone.auxiliary.editor.y >= iphone.safe.y, "iPhone editor safe-top clearance")
assert(iphone.status.width ~= ipad.status.width, "status width must reflow by viewport")
assert(iphone.status.height ~= ipad.status.height, "status height must reflow by viewport")
assert(iphone.rail.height ~= ipad.rail.height, "rail height must reflow by viewport")
assert(iphone.quick.y ~= ipad.quick.y, "quick bar must follow safe bottom")

local badStatus = ResponsiveHudLayout.compute(
    { width = 909, height = 483 },
    {},
    {}
)
badStatus.status = {
    x = badStatus.rail.x,
    y = badStatus.rail.y,
    width = badStatus.rail.width,
    height = badStatus.rail.width,
    right = badStatus.rail.right,
    bottom = badStatus.rail.y + badStatus.rail.width,
}
local validStatus, statusReason = ResponsiveHudLayout.validate(badStatus)
assert(not validStatus and statusReason == "status overlaps rail", "status/rail mutation must fail")

local quickProbe = ResponsiveHudLayout.compute(
    { width = 852, height = 393 },
    { left = 47, top = 0, right = 47, bottom = 21 },
    {}
)
quickProbe.exclusionZones = {
    zone(quickProbe.quick.x, quickProbe.quick.y, quickProbe.quick.width, quickProbe.quick.height),
}
local validQuick, quickReason = ResponsiveHudLayout.validate(quickProbe)
assert(not validQuick and quickReason == "quick overlaps exclusion zone 1", "quick/control mutation must fail")

local legacyHouse = zone(256, 393 - (112 + 66) - 292, 248, 292)
local legacyEditor = zone(512, 393 - (112 + 66) - 346, 330, 346)
assert(not ResponsiveHudLayout.contains(iphone.safe, legacyHouse), "legacy fixed house geometry must fail iPhone safe bounds")
assert(not ResponsiveHudLayout.contains(iphone.safe, legacyEditor), "legacy fixed editor geometry must fail iPhone safe bounds")

local badHouse = zone(
    iphone.safe.x - 1,
    iphone.auxiliary.house.y,
    iphone.auxiliary.house.width,
    iphone.auxiliary.house.height
)
badHouse.scale = iphone.auxiliary.house.scale
local houseMutationValid, houseMutationReason = ResponsiveHudLayout.validateAuxiliaryPanels(iphone, {
    house = badHouse,
    editor = iphone.auxiliary.editor,
})
assert(not houseMutationValid and houseMutationReason == "house panel leaves safe bounds", "house geometry mutation must fail")

local badEditor = zone(
    iphone.safe.right - iphone.auxiliary.editor.width + 1,
    iphone.auxiliary.editor.y,
    iphone.auxiliary.editor.width,
    iphone.auxiliary.editor.height
)
badEditor.scale = iphone.auxiliary.editor.scale
local editorMutationValid, editorMutationReason = ResponsiveHudLayout.validateAuxiliaryPanels(iphone, {
    house = iphone.auxiliary.house,
    editor = badEditor,
})
assert(not editorMutationValid and editorMutationReason == "housing editor leaves safe bounds", "editor geometry mutation must fail")

local clientFile = assert(io.open("school/src/client/CanonicalSchoolClient.client.lua", "r"))
local clientSource = clientFile:read("*a")
clientFile:close()
for _, fragment in ipairs({
    'ResponsiveHudLayout.computeAuxiliaryPanels(layout)',
    'ResponsiveHudLayout.validateAuxiliaryPanels(layout, auxiliaryPanels)',
    'housePanelScale = Instance.new("UIScale")',
    'editorPanelScale = Instance.new("UIScale")',
    'housePanelScale.Scale = auxiliaryPanels.house.scale',
    'editorPanelScale.Scale = auxiliaryPanels.editor.scale',
}) do
    assert(clientSource:find(fragment, 1, true), "client missing responsive auxiliary binding: " .. fragment)
end
assert(not clientSource:find('housePanel.Position = UDim2.new(0, 256', 1, true), "fixed house panel position regression")
assert(not clientSource:find('editorPanel.Position = UDim2.new(0, 512', 1, true), "fixed housing editor position regression")

print("RESPONSIVE_HUD_LAYOUT_CONTRACT_PASS")
