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

    local classModal = ResponsiveHudLayout.computeCenteredModal(layout, { width = 540, height = 390 })
    local classModalValid, classModalReason = ResponsiveHudLayout.validateCenteredModal(layout, classModal)
    assert(classModalValid, fixture.name .. ": " .. tostring(classModalReason))
    assert(ResponsiveHudLayout.contains(layout.safe, classModal), fixture.name .. ": class modal outside safe area")
    layout.classModal = classModal

    local outfitModal = ResponsiveHudLayout.computeCenteredModal(layout, { width = 286, height = 400 })
    local outfitModalValid, outfitModalReason = ResponsiveHudLayout.validateCenteredModal(layout, outfitModal)
    assert(outfitModalValid, fixture.name .. ": " .. tostring(outfitModalReason))
    assert(ResponsiveHudLayout.contains(layout.safe, outfitModal), fixture.name .. ": outfit modal outside safe area")
    layout.outfitModal = outfitModal

    local featureModal = ResponsiveHudLayout.computeInteractionModal(layout, { width = 530, height = 354 })
    local featureValid, featureReason = ResponsiveHudLayout.validateInteractionModal(layout, featureModal)
    assert(featureValid, fixture.name .. ": " .. tostring(featureReason))
    assert(ResponsiveHudLayout.contains(layout.safe, featureModal), fixture.name .. ": feature modal outside safe area")
    assert(not ResponsiveHudLayout.overlaps(featureModal, layout.status), fixture.name .. ": feature/status overlap")
    assert(not ResponsiveHudLayout.overlaps(featureModal, layout.rail), fixture.name .. ": feature/rail overlap")
    assert(not ResponsiveHudLayout.overlaps(featureModal, layout.quick), fixture.name .. ": feature/quick overlap")
    layout.featureModal = featureModal

    local cafeCard = ResponsiveHudLayout.computeSafeFloatingCard(layout, { width = 260, height = 150 })
    local cafeValid, cafeReason = ResponsiveHudLayout.validateSafeFloatingCard(layout, cafeCard)
    assert(cafeValid, fixture.name .. ": " .. tostring(cafeReason))
    assert(ResponsiveHudLayout.contains(layout.safe, cafeCard), fixture.name .. ": cafe card outside safe area")
    assert(not ResponsiveHudLayout.overlaps(cafeCard, layout.status), fixture.name .. ": cafe/status overlap")
    assert(not ResponsiveHudLayout.overlaps(cafeCard, layout.rail), fixture.name .. ": cafe/rail overlap")
    assert(not ResponsiveHudLayout.overlaps(cafeCard, layout.quick), fixture.name .. ": cafe/quick overlap")
    layout.cafeCard = cafeCard

    local vehicleCard = ResponsiveHudLayout.computeBottomCenteredCard(layout, { width = 260, height = 132 })
    local vehicleValid, vehicleReason = ResponsiveHudLayout.validateSafeFloatingCard(layout, vehicleCard)
    assert(vehicleValid, fixture.name .. ": " .. tostring(vehicleReason))
    assert(ResponsiveHudLayout.contains(layout.safe, vehicleCard), fixture.name .. ": vehicle card outside safe area")
    assert(not ResponsiveHudLayout.overlaps(vehicleCard, layout.status), fixture.name .. ": vehicle/status overlap")
    assert(not ResponsiveHudLayout.overlaps(vehicleCard, layout.rail), fixture.name .. ": vehicle/rail overlap")
    assert(not ResponsiveHudLayout.overlaps(vehicleCard, layout.quick), fixture.name .. ": vehicle/quick overlap")
    layout.vehicleCard = vehicleCard

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
        assert(not ResponsiveHudLayout.overlaps(cafeCard, exclusion), fixture.name .. ": cafe/movement-camera overlap " .. index)
        assert(not ResponsiveHudLayout.overlaps(vehicleCard, exclusion), fixture.name .. ": vehicle/movement-camera overlap " .. index)
        assert(not ResponsiveHudLayout.overlaps(featureModal, exclusion), fixture.name .. ": feature/movement-camera overlap " .. index)
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
assert(nominal.classModal.scale == 1, "desktop class modal keeps native scale")
assert(ipad.classModal.scale == 1, "iPad class modal keeps native scale")
assert(iphone.classModal.scale < 1, "iPhone class modal must reflow")
assert(iphone.classModal.y >= iphone.safe.y, "iPhone class modal clears safe top")
assert(iphone.classModal.bottom <= iphone.safe.bottom, "iPhone class modal clears safe bottom")
assert(nominal.outfitModal.scale == 1, "desktop outfit modal keeps native scale")
assert(ipad.outfitModal.scale == 1, "iPad outfit modal keeps native scale")
assert(iphone.outfitModal.scale < 1, "iPhone outfit modal must reflow")
assert(iphone.outfitModal.y >= iphone.safe.y, "iPhone outfit modal clears safe top")
assert(iphone.outfitModal.bottom <= iphone.safe.bottom, "iPhone outfit modal clears safe bottom")
assert(nominal.featureModal.scale == 1, "desktop feature modal keeps native scale")
assert(math.abs(nominal.featureModal.x - 189) <= 3, "desktop feature modal must match locked RHS2 horizontal reference")
assert(math.abs(nominal.featureModal.y - 64) <= 8, "desktop feature modal must match locked RHS2 vertical reference")
assert(nominal.featureModal.width == 530, "desktop feature modal matches locked RHS2 width")
assert(nominal.featureModal.height == 354, "desktop feature modal matches locked RHS2 height")
assert(ipad.featureModal.scale == 1, "iPad feature modal keeps native scale")
assert(iphone.featureModal.scale < 1, "iPhone feature modal must reflow into central touch corridor")
assert(iphone.featureModal.right <= iphone.exclusionZones[2].x, "iPhone feature modal clears right touch zone")
assert(iphone.featureModal.x >= iphone.exclusionZones[1].right, "iPhone feature modal clears left touch zone")
assert(nominal.cafeCard.scale == 1, "desktop cafe card keeps native scale")
assert(ipad.cafeCard.scale == 1, "iPad cafe card keeps native scale")
assert(iphone.cafeCard.scale == 1, "iPhone cafe card fits without shrinking")
assert(nominal.vehicleCard.scale == 1, "desktop vehicle card keeps native scale")
assert(ipad.vehicleCard.scale == 1, "iPad vehicle card keeps native scale")
assert(iphone.vehicleCard.scale == 1, "iPhone vehicle card fits without shrinking")
assert(nominal.vehicleCard.bottom < nominal.quick.y, "desktop vehicle card clears quick bar")
assert(iphone.vehicleCard.bottom < iphone.quick.y, "iPhone vehicle card clears quick bar")
assert(ipad.vehicleCard.bottom < ipad.quick.y, "iPad vehicle card clears quick bar")
assert(iphone.cafeCard.right <= iphone.safe.right, "iPhone cafe card clears safe right")
assert(ipad.cafeCard.right <= ipad.safe.right, "iPad cafe card clears safe right")
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

local legacyClassWidth = 540
local legacyClassHeight = 390
local legacyClass = zone(
    (852 - legacyClassWidth) / 2,
    (393 * 0.55) - (legacyClassHeight / 2),
    legacyClassWidth,
    legacyClassHeight
)
assert(not ResponsiveHudLayout.contains(iphone.safe, legacyClass), "legacy fixed class modal geometry must fail iPhone safe bounds")

local badClassModal = zone(
    iphone.classModal.x,
    iphone.safe.bottom - iphone.classModal.height + 1,
    iphone.classModal.width,
    iphone.classModal.height
)
badClassModal.scale = iphone.classModal.scale
local classMutationValid, classMutationReason = ResponsiveHudLayout.validateCenteredModal(iphone, badClassModal)
assert(not classMutationValid and classMutationReason == "centered modal leaves safe bounds", "class modal geometry mutation must fail")

local legacyFeatureDesktop = zone(
    (909 - 560) / 2,
    (483 - (483 * 0.76)) / 2,
    560,
    483 * 0.76
)
assert(ResponsiveHudLayout.overlaps(legacyFeatureDesktop, nominal.status), "legacy desktop feature modal must overlap status")
assert(ResponsiveHudLayout.overlaps(legacyFeatureDesktop, nominal.quick), "legacy desktop feature modal must overlap quick bar")

local legacyFeatureIphone = zone(
    (852 - 560) / 2,
    (393 - (393 * 0.76)) / 2,
    560,
    393 * 0.76
)
assert(ResponsiveHudLayout.overlaps(legacyFeatureIphone, iphone.status), "legacy iPhone feature modal must overlap status")
assert(ResponsiveHudLayout.overlaps(legacyFeatureIphone, iphone.quick), "legacy iPhone feature modal must overlap quick bar")
assert(ResponsiveHudLayout.overlaps(legacyFeatureIphone, iphone.exclusionZones[1]), "legacy iPhone feature modal must overlap left touch zone")
assert(ResponsiveHudLayout.overlaps(legacyFeatureIphone, iphone.exclusionZones[2]), "legacy iPhone feature modal must overlap right touch zone")

local badFeature = zone(
    iphone.status.x - iphone.featureModal.width + 1,
    iphone.featureModal.y,
    iphone.featureModal.width,
    iphone.featureModal.height
)
badFeature.scale = iphone.featureModal.scale
local badFeatureValid, badFeatureReason = ResponsiveHudLayout.validateInteractionModal(iphone, badFeature)
assert(not badFeatureValid and badFeatureReason == "interaction modal overlaps status", "feature modal HUD-overlap mutation must fail")

local legacyVehicleDesktop = zone(
    (909 - 260) / 2,
    483 - 12 - 132,
    260,
    132
)
assert(ResponsiveHudLayout.overlaps(legacyVehicleDesktop, nominal.quick), "legacy fixed vehicle card must overlap desktop quick bar")

local badVehicle = zone(
    nominal.vehicleCard.x,
    nominal.quick.y - nominal.vehicleCard.height + 1,
    nominal.vehicleCard.width,
    nominal.vehicleCard.height
)
badVehicle.scale = nominal.vehicleCard.scale
local badVehicleValid, badVehicleReason = ResponsiveHudLayout.validateSafeFloatingCard(nominal, badVehicle)
assert(not badVehicleValid and badVehicleReason == "floating card overlaps quick", "vehicle quick-bar mutation must fail")

local legacyOutfitPanelHeight = 262
local verifiedOutfitContentBottom = 210 + (8 * 20) + 20
assert(verifiedOutfitContentBottom == 390, "verified outfit content bottom fixture")
assert(verifiedOutfitContentBottom > legacyOutfitPanelHeight, "legacy outfit panel must be proven too short")

local legacyOutfitDesktopTop = (483 * 0.5) - 131
local legacyOutfitIphoneTop = (393 * 0.5) - 131
assert(legacyOutfitDesktopTop + verifiedOutfitContentBottom > nominal.safe.bottom, "legacy outfit content must overflow desktop viewport")
assert(legacyOutfitIphoneTop + verifiedOutfitContentBottom > iphone.safe.bottom, "legacy outfit content must overflow iPhone safe bottom")

local badOutfit = zone(
    iphone.outfitModal.x,
    iphone.safe.bottom - iphone.outfitModal.height + 1,
    iphone.outfitModal.width,
    iphone.outfitModal.height
)
badOutfit.scale = iphone.outfitModal.scale
local badOutfitValid, badOutfitReason = ResponsiveHudLayout.validateCenteredModal(iphone, badOutfit)
assert(not badOutfitValid and badOutfitReason == "centered modal leaves safe bounds", "outfit modal safe-bottom mutation must fail")

local legacyOutfitEntry = zone(852 - 144, 12, 132, 34)
assert(not ResponsiveHudLayout.contains(iphone.safe, legacyOutfitEntry), "legacy outfit internal entry must fail iPhone safe-right bounds")

local legacyCafe = zone(852 - 12 - 260, 393 - 112 - 150, 260, 150)
assert(not ResponsiveHudLayout.contains(iphone.safe, legacyCafe), "legacy fixed cafe geometry must fail iPhone safe bounds")
assert(ResponsiveHudLayout.overlaps(legacyCafe, iphone.exclusionZones[2]), "legacy fixed cafe geometry must overlap right touch zone")

local badCafe = zone(
    iphone.safe.right - iphone.cafeCard.width + 1,
    iphone.cafeCard.y,
    iphone.cafeCard.width,
    iphone.cafeCard.height
)
badCafe.scale = iphone.cafeCard.scale
local badCafeValid, badCafeReason = ResponsiveHudLayout.validateSafeFloatingCard(iphone, badCafe)
assert(not badCafeValid and badCafeReason == "floating card leaves safe bounds", "cafe safe-right mutation must fail")

local rightZone = iphone.exclusionZones[2]
local badCafeTouch = zone(
    iphone.cafeCard.x,
    rightZone.y - iphone.cafeCard.height + 1,
    iphone.cafeCard.width,
    iphone.cafeCard.height
)
badCafeTouch.scale = iphone.cafeCard.scale
local badCafeTouchValid, badCafeTouchReason = ResponsiveHudLayout.validateSafeFloatingCard(iphone, badCafeTouch)
assert(not badCafeTouchValid and badCafeTouchReason == "floating card overlaps exclusion zone 2", "cafe touch-zone mutation must fail")

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
    'ResponsiveHudLayout.computeCenteredModal(layout, {',
    'ResponsiveHudLayout.validateCenteredModal(layout, classModalLayout)',
    'local featureModalLayout = ResponsiveHudLayout.computeInteractionModal(layout, {',
    'width = 530,',
    'height = 354,',
    'ResponsiveHudLayout.validateInteractionModal(layout, featureModalLayout)',
    'panel.Size = UDim2.fromOffset(530, 354)',
    'shopPanel.Position = UDim2.fromOffset(featureModalLayout.x, featureModalLayout.y)',
    'shopPanelScale.Scale = featureModalLayout.scale',
    'travelPanel.Position = UDim2.fromOffset(featureModalLayout.x, featureModalLayout.y)',
    'travelPanelScale.Scale = featureModalLayout.scale',
    'local outfitModalLayout = ResponsiveHudLayout.computeCenteredModal(layout, {',
    'outfitPanel.Position = UDim2.fromOffset(outfitModalLayout.x, outfitModalLayout.y)',
    'outfitPanelScale.Scale = outfitModalLayout.scale',
    'legacyOutfitSurface.entry.Visible = false',
    'ResponsiveHudLayout.computeBottomCenteredCard(layout, {',
    'ResponsiveHudLayout.validateSafeFloatingCard(layout, vehicleCardLayout)',
    'vehicleCard.Position = UDim2.fromOffset(vehicleCardLayout.x, vehicleCardLayout.y)',
    'vehicleCardScale.Scale = vehicleCardLayout.scale',
    'ResponsiveHudLayout.computeSafeFloatingCard(layout, {',
    'ResponsiveHudLayout.validateSafeFloatingCard(layout, cafeCardLayout)',
    'modalScale = Instance.new("UIScale")',
    'modalScale.Scale = classModalLayout.scale',
    'cafeCardScale = Instance.new("UIScale")',
    'cafeCard.Position = UDim2.fromOffset(cafeCardLayout.x, cafeCardLayout.y)',
    'cafeCardScale.Scale = cafeCardLayout.scale',
    'housePanelScale = Instance.new("UIScale")',
    'editorPanelScale = Instance.new("UIScale")',
    'housePanelScale.Scale = auxiliaryPanels.house.scale',
    'editorPanelScale.Scale = auxiliaryPanels.editor.scale',
}) do
    assert(clientSource:find(fragment, 1, true), "client missing responsive auxiliary binding: " .. fragment)
end
assert(not clientSource:find('panel.AnchorPoint = Vector2.new(0.5, 0.5)', 1, true), "fixed feature modal center-anchor regression")
assert(not clientSource:find('panel.Size = UDim2.new(0.82, 0, 0.76, 0)', 1, true), "relative feature modal size regression")
assert(not clientSource:find('panelConstraint.MaxSize = Vector2.new(560, 390)', 1, true), "feature panel size-constraint regression")
assert(not clientSource:find('modal.Position = UDim2.fromScale(0.5, 0.55)', 1, true), "fixed class modal position regression")
assert(not clientSource:find('modal.Size = UDim2.new(0.9, 0, 0, 390)', 1, true), "fixed class modal size regression")
assert(not clientSource:find('vehicleCard.AnchorPoint = Vector2.new(0.5, 1)', 1, true), "fixed vehicle anchor regression")
assert(not clientSource:find('vehicleCard.Position = UDim2.new(0.5, 0, 1, -auxiliaryPanelBottomMargin)', 1, true), "fixed vehicle bottom placement regression")
assert(not clientSource:find('cafeCard.AnchorPoint = Vector2.new(1, 1)', 1, true), "fixed cafe anchor regression")
assert(not clientSource:find('cafeCard.Position = UDim2.new(1, -12, 1, -auxiliaryPanelBottomMargin)', 1, true), "fixed cafe position regression")
assert(not clientSource:find('cafeSizeConstraint.MinSize = Vector2.new(270, 160)', 1, true), "cafe minimum-size regression")
assert(not clientSource:find('housePanel.Position = UDim2.new(0, 256', 1, true), "fixed house panel position regression")
assert(not clientSource:find('editorPanel.Position = UDim2.new(0, 512', 1, true), "fixed housing editor position regression")

print("RESPONSIVE_HUD_LAYOUT_CONTRACT_PASS")
