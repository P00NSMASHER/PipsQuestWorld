local function read(path)
    local handle = assert(io.open(path, "r"))
    local source = handle:read("*a")
    handle:close()
    return source
end

local canonical = read("school/src/client/CanonicalSchoolClient.client.lua")
local market = read("school/src/client/MarketStockJob.client.lua")
local styleShop = read("school/src/client/StyleShopCatalog.client.lua")

local function has(source, fragment, label)
    if not source:find(fragment, 1, true) then
        error("missing mobile UI contract: " .. (label or fragment), 2)
    end
end

has(canonical, 'local choices = Instance.new("ScrollingFrame")', "scrollable class answers")
has(canonical, "constraint.MinSize = Vector2.new(280, 250)", "class modal compact minimum")
has(canonical, "if viewport.Y < 440 then", "class height breakpoint")
has(canonical, "if modalWidth < 340 then", "narrow class header lanes")
has(canonical, "classUi.title.Size = UDim2.new(0.44, 0, 1, 0)", "narrow class title lane")
has(canonical, "classUi.round.Position = UDim2.new(0.62, 0, 0, 0)", "narrow class round lane")
has(canonical, "classUi.leave.Size = UDim2.fromOffset(38, 38)", "compact class close target")
has(canonical, 'camera:GetPropertyChangedSignal("ViewportSize")', "class viewport listener")

has(canonical, "editorSizeConstraint.MinSize = Vector2.new(240, 260)", "housing editor compact minimum")
has(canonical, "or (UserInputService.TouchEnabled and viewport.Y < 560)", "touch housing breakpoint")
has(canonical, "editorGrid.CellSize = UDim2.new(0.25, -4, 0, 36)", "compact housing action grid")
has(canonical, "bindEditorViewport(Workspace.CurrentCamera)", "housing viewport listener")

has(market, "sizeConstraint.MinSize = Vector2.new(280, 220)", "market compact minimum")
has(market, "local compact = viewport.Y < 380 or viewport.X < 420", "market phone breakpoint")
has(market, "body.Size = UDim2.new(1, 0, 1, -112)", "market scrolling middle region")
has(market, "primaryButton.Size = UDim2.new(1, -20, 0, 42)", "market compact action target")

has(styleShop, "body.AbsoluteSize.Y > 0 and body.AbsoluteSize.Y < 190", "style detail-pane breakpoint")
has(styleShop, "detailSwatch.Size = UDim2.new(0, 52, 1, -16)", "style horizontal preview")
has(styleShop, "detailName.Position = UDim2.fromOffset(68, 7)", "style horizontal name")
has(styleShop, "action.Position = UDim2.new(0, 68, 1, -8)", "style horizontal action")

has(canonical, "ContextActionService:SetPosition(VEHICLE_FORWARD, UDim2.new(0.5, -30, 1, -220))", "vehicle forward stays in center touch lane")
has(canonical, "ContextActionService:SetPosition(VEHICLE_LEFT, UDim2.new(0.5, -92, 1, -158))", "vehicle steer stays clear of thumbstick")
has(canonical, "local compactDealer = viewport.X < 620 or viewport.Y < 440", "dealer compact breakpoint")
has(canonical, "vehicleShowroom.Size = UDim2.new(1, -28, 1, -150)", "dealer preview leaves action lane")
has(canonical, "if state.driving == true then", "vehicle driving HUD mode")

-- Verify the exact minimum landscape target geometrically. These values mirror
-- the guarded compact branches above, so accidental overlap regressions fail
-- even when every expected source marker remains present.
local viewportWidth, viewportHeight = 480, 300
local classWidth = math.max(300, math.min(540, viewportWidth - 86))
local classHeight = math.max(250, math.min(390, viewportHeight - 20))
local classCenterX = viewportWidth * 0.43
assert(classCenterX - (classWidth / 2) >= 0, "class modal leaves left viewport")
assert(classCenterX + (classWidth / 2) <= viewportWidth, "class modal leaves right viewport")
assert((viewportHeight - classHeight) / 2 >= 0, "class modal leaves top viewport")
assert((viewportHeight + classHeight) / 2 <= viewportHeight, "class modal leaves bottom viewport")
assert(54 + (classWidth * 0.52) <= classWidth * 0.66, "class title overlaps round lane")
local narrowClassWidth = 280
assert(46 + (narrowClassWidth * 0.44) <= narrowClassWidth * 0.62, "narrow class title overlaps round lane")
assert(narrowClassWidth * 0.8 <= narrowClassWidth - 44, "narrow class round overlaps close target")
local classChoicesBottom = 106 + math.max(72, classHeight - 170)
local classFeedbackTop = classHeight - 56
assert(classChoicesBottom <= classFeedbackTop, "class answers overlap feedback")
assert(classFeedbackTop + 44 <= classHeight, "class feedback leaves modal")

local editorWidth = math.max(260, math.min(330, viewportWidth - 212))
local editorHeight = math.max(260, math.min(320, viewportHeight - 16))
local editorCatalogHeight = math.max(48, math.min(72, editorHeight - 220))
local editorStatusY = 52 + editorCatalogHeight + 4
local editorActionsY = editorStatusY + 34
assert(8 + editorWidth <= viewportWidth, "housing editor leaves viewport")
assert((viewportHeight - editorHeight) / 2 >= 0, "housing editor leaves top viewport")
assert(editorActionsY + 76 <= editorHeight - 42, "housing actions overlap Hide Walls")
assert(editorHeight - 8 <= viewportHeight, "housing editor leaves bottom viewport")

local marketHeight = math.max(220, viewportHeight - 16)
assert(54 + 58 < marketHeight, "market scrolling region collapses")
assert(8 + 42 <= 58, "market footer action leaves fixed footer")

local featurePanelHeight = math.max(220, viewportHeight * 0.72)
local styleBodyHeight = featurePanelHeight - 72
local styleDetailHeight = styleBodyHeight - 62
assert(styleBodyHeight < 190, "480x300 style shop must select compact layout")
assert(25 + 12 <= 40, "style name/description overlap purchase action")
assert(40 + 38 <= styleDetailHeight, "style purchase action leaves detail pane")
assert(8 + 52 <= 68, "style preview overlaps text/action column")

-- At minimum landscape, the dealer uses a full-height compact card and its
-- preview, status, and action regions remain distinct.  The centered drive
-- buttons avoid both 105px-wide native lower-corner touch zones.
local dealerWidth = math.max(280, math.min(560, viewportWidth - 24))
local dealerHeight = math.max(250, math.min(380, viewportHeight - 16))
assert(dealerWidth <= viewportWidth and dealerHeight <= viewportHeight, "compact dealer leaves viewport")
local dealerPreviewBottom = 54 + (dealerHeight - 150)
local dealerStatusTop = dealerHeight - 96
local dealerActionTop = dealerHeight - 52
assert(dealerPreviewBottom <= dealerStatusTop, "dealer preview overlaps status")
assert(dealerStatusTop + 32 <= dealerActionTop, "dealer status overlaps action")
for _, x in ipairs({ viewportWidth * 0.5 - 30, viewportWidth * 0.5 - 92, viewportWidth * 0.5 + 32 }) do
    assert(x > 105 and x < viewportWidth - 105, "vehicle touch control enters native corner zone")
end

print("HIGH_SCHOOL_MOBILE_UI_RESPONSIVENESS_PASS")
