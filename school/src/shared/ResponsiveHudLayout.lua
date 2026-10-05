-- Pure responsive HUD geometry contract. This module intentionally owns no
-- gameplay, economy, progression, travel, housing, or persistence state.

local ResponsiveHudLayout = {}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function rect(x, y, width, height)
    return {
        x = x,
        y = y,
        width = width,
        height = height,
        right = x + width,
        bottom = y + height,
    }
end

local function normalizeInsets(insets)
    insets = insets or {}
    return {
        left = math.max(0, tonumber(insets.left) or 0),
        top = math.max(0, tonumber(insets.top) or 0),
        right = math.max(0, tonumber(insets.right) or 0),
        bottom = math.max(0, tonumber(insets.bottom) or 0),
    }
end

function ResponsiveHudLayout.overlaps(left, right)
    return math.min(left.right, right.right) > math.max(left.x, right.x)
        and math.min(left.bottom, right.bottom) > math.max(left.y, right.y)
end

function ResponsiveHudLayout.contains(container, item)
    return item.x >= container.x
        and item.y >= container.y
        and item.right <= container.right
        and item.bottom <= container.bottom
end

-- Thumbstick and right-side camera/action touch regions used by Roblox on mobile.
-- These remain pure geometry so the same zones are exercised by static contracts.
function ResponsiveHudLayout.touchExclusionZones(viewport, insets)
    local width = assert(tonumber(viewport and viewport.width), "viewport width required")
    local height = assert(tonumber(viewport and viewport.height), "viewport height required")
    local safeInsets = normalizeInsets(insets)
    local zoneWidth = math.min(190, math.floor(width * 0.22))
    local zoneHeight = math.min(120, math.floor(height * 0.25))
    local zoneY = height - safeInsets.bottom - zoneHeight
    local leftX = safeInsets.left
    local rightX = width - safeInsets.right - zoneWidth

    return {
        rect(leftX, zoneY, zoneWidth, zoneHeight),
        rect(rightX, zoneY, zoneWidth, zoneHeight),
    }
end

function ResponsiveHudLayout.compute(viewport, insets, exclusionZones)
    assert(type(viewport) == "table", "viewport table required")
    local width = assert(tonumber(viewport.width), "viewport width required")
    local height = assert(tonumber(viewport.height), "viewport height required")
    assert(width >= 480 and height >= 300, "viewport below supported landscape bounds")

    local safeInsets = normalizeInsets(insets)
    local safe = rect(
        safeInsets.left,
        safeInsets.top,
        width - safeInsets.left - safeInsets.right,
        height - safeInsets.top - safeInsets.bottom
    )
    assert(safe.width > 0 and safe.height > 0, "safe area must be positive")

    local outerGap = clamp(math.floor(math.min(width, height) * 0.012 + 0.5), 6, 12)
    local groupGap = clamp(math.floor(width * 0.009 + 0.5), 7, 12)

    -- Reference occupancy targets at the nominal 909x483 gameplay viewport:
    -- status ~= 0.1298 x 0.147, primary rail ~= 0.0539 x 0.4389,
    -- and quick slots ~= 0.275 x 0.1159. Clamps preserve usability elsewhere.
    local statusWidth = clamp(math.floor(width * 0.1298 + 0.5), 118, 154)
    local statusHeight = clamp(math.floor(height * 0.147 + 0.5), 70, 86)
    local railWidth = clamp(math.floor(width * 0.0539 + 0.5), 46, 58)
    local railHeight = clamp(math.floor(height * 0.4389 + 0.5), 176, 230)
    local quickWidth = clamp(math.floor(width * 0.275 + 0.5), 216, 252)
    local quickHeight = clamp(math.floor(height * 0.1159 + 0.5), 48, 58)

    local railX = safe.right - outerGap - railWidth
    local statusX = railX - groupGap - statusWidth
    local statusY = safe.y + outerGap
    local railY = math.max(
        safe.y + math.floor(height * 0.1884 + 0.5),
        statusY + statusHeight + groupGap
    )
    local quickX = safe.x + ((safe.width - quickWidth) / 2)
    local quickY = safe.bottom - outerGap - quickHeight

    local layout = {
        viewport = rect(0, 0, width, height),
        safe = safe,
        status = rect(statusX, statusY, statusWidth, statusHeight),
        rail = rect(railX, railY, railWidth, railHeight),
        quick = rect(quickX, quickY, quickWidth, quickHeight),
        exclusionZones = exclusionZones or {},
        railGap = clamp(math.floor(railHeight * 0.022 + 0.5), 4, 6),
        quickGap = clamp(math.floor(quickWidth * 0.026 + 0.5), 5, 7),
    }

    layout.railButtonSize = math.min(
        railWidth - 4,
        math.floor((railHeight - (layout.railGap * 3)) / 4)
    )
    layout.quickSlotSize = math.min(
        quickHeight,
        math.floor((quickWidth - (layout.quickGap * 3)) / 4)
    )

    return layout
end

local AUXILIARY_BASE = {
    house = { width = 248, height = 292 },
    editor = { width = 330, height = 346 },
}

-- House and housing-editor surfaces share the same safe-area contract as the
-- compact HUD. On short touch viewports they shrink uniformly through UIScale
-- and stay above the movement/camera regions; larger fixtures retain 1:1 size.
function ResponsiveHudLayout.computeAuxiliaryPanels(layout)
    assert(type(layout) == "table", "layout table required")
    assert(layout.safe and layout.viewport and layout.status and layout.rail and layout.quick, "complete HUD layout required")

    local viewport = layout.viewport
    local safe = layout.safe
    local gap = clamp(math.floor(math.min(viewport.width, viewport.height) * 0.02 + 0.5), 8, 12)
    local topLimit = safe.y + gap
    local bottomLimit = math.min(safe.bottom - gap, layout.quick.y - gap)

    for _, zone in ipairs(layout.exclusionZones or {}) do
        bottomLimit = math.min(bottomLimit, zone.y - gap)
    end

    local availableHeight = bottomLimit - topLimit
    assert(availableHeight > 0, "no vertical room for auxiliary panels")

    local houseScale = math.min(1, availableHeight / AUXILIARY_BASE.house.height)
    local editorScale = math.min(1, availableHeight / AUXILIARY_BASE.editor.height)

    local startX = safe.x + gap
    local rightLimit = math.min(layout.status.x, layout.rail.x) - gap
    local availableWidth = rightLimit - startX
    assert(availableWidth > gap, "no horizontal room for auxiliary panels")

    local houseWidth = AUXILIARY_BASE.house.width * houseScale
    local editorWidth = AUXILIARY_BASE.editor.width * editorScale
    if houseWidth + gap + editorWidth > availableWidth then
        local widthScale = math.max(0, (availableWidth - gap) / (houseWidth + editorWidth))
        houseScale = houseScale * widthScale
        editorScale = editorScale * widthScale
        houseWidth = AUXILIARY_BASE.house.width * houseScale
        editorWidth = AUXILIARY_BASE.editor.width * editorScale
    end

    local houseHeight = AUXILIARY_BASE.house.height * houseScale
    local editorHeight = AUXILIARY_BASE.editor.height * editorScale
    local house = rect(startX, bottomLimit - houseHeight, houseWidth, houseHeight)
    local editor = rect(house.right + gap, bottomLimit - editorHeight, editorWidth, editorHeight)
    house.scale = houseScale
    editor.scale = editorScale

    return {
        house = house,
        editor = editor,
        gap = gap,
    }
end

function ResponsiveHudLayout.computeCenteredModal(layout, baseSize)
    assert(type(layout) == "table" and layout.safe and layout.viewport, "complete HUD layout required")
    assert(type(baseSize) == "table", "baseSize table required")
    local baseWidth = assert(tonumber(baseSize.width), "modal width required")
    local baseHeight = assert(tonumber(baseSize.height), "modal height required")
    assert(baseWidth > 0 and baseHeight > 0, "modal dimensions must be positive")

    local safe = layout.safe
    local viewport = layout.viewport
    local gap = clamp(math.floor(math.min(viewport.width, viewport.height) * 0.02 + 0.5), 8, 12)
    local availableWidth = safe.width - (gap * 2)
    local availableHeight = safe.height - (gap * 2)
    assert(availableWidth > 0 and availableHeight > 0, "no safe room for centered modal")

    local scale = math.min(1, availableWidth / baseWidth, availableHeight / baseHeight)
    assert(scale > 0, "centered modal scale must be positive")

    local width = baseWidth * scale
    local height = baseHeight * scale
    local modal = rect(
        safe.x + ((safe.width - width) / 2),
        safe.y + ((safe.height - height) / 2),
        width,
        height
    )
    modal.scale = scale
    modal.gap = gap
    modal.baseWidth = baseWidth
    modal.baseHeight = baseHeight
    return modal
end

function ResponsiveHudLayout.validateCenteredModal(layout, modal)
    if not modal or not modal.scale or modal.scale <= 0 or modal.scale > 1 then
        return false, "centered modal has invalid scale"
    end
    if not ResponsiveHudLayout.contains(layout.safe, modal) then
        return false, "centered modal leaves safe bounds"
    end
    return true
end

function ResponsiveHudLayout.validateAuxiliaryPanels(layout, auxiliary)
    for _, pair in ipairs({
        { name = "house panel", value = auxiliary.house },
        { name = "housing editor", value = auxiliary.editor },
    }) do
        if not pair.value or not pair.value.scale or pair.value.scale <= 0 or pair.value.scale > 1 then
            return false, pair.name .. " has invalid scale"
        end
        if not ResponsiveHudLayout.contains(layout.safe, pair.value) then
            return false, pair.name .. " leaves safe bounds"
        end
    end

    if ResponsiveHudLayout.overlaps(auxiliary.house, auxiliary.editor) then
        return false, "auxiliary panels overlap"
    end

    for _, panel in ipairs({
        { name = "house panel", value = auxiliary.house },
        { name = "housing editor", value = auxiliary.editor },
    }) do
        for _, hud in ipairs({
            { name = "status", value = layout.status },
            { name = "rail", value = layout.rail },
            { name = "quick", value = layout.quick },
        }) do
            if ResponsiveHudLayout.overlaps(panel.value, hud.value) then
                return false, panel.name .. " overlaps " .. hud.name
            end
        end
        for index, zone in ipairs(layout.exclusionZones or {}) do
            if ResponsiveHudLayout.overlaps(panel.value, zone) then
                return false, panel.name .. " overlaps exclusion zone " .. tostring(index)
            end
        end
    end

    return true
end

function ResponsiveHudLayout.validate(layout)
    for _, pair in ipairs({
        { name = "status", value = layout.status },
        { name = "rail", value = layout.rail },
        { name = "quick", value = layout.quick },
    }) do
        if not ResponsiveHudLayout.contains(layout.safe, pair.value) then
            return false, pair.name .. " leaves safe bounds"
        end
    end

    if ResponsiveHudLayout.overlaps(layout.status, layout.rail) then
        return false, "status overlaps rail"
    end
    if ResponsiveHudLayout.overlaps(layout.status, layout.quick) then
        return false, "status overlaps quick bar"
    end
    if ResponsiveHudLayout.overlaps(layout.rail, layout.quick) then
        return false, "rail overlaps quick bar"
    end

    for index, zone in ipairs(layout.exclusionZones or {}) do
        for _, pair in ipairs({
            { name = "status", value = layout.status },
            { name = "rail", value = layout.rail },
            { name = "quick", value = layout.quick },
        }) do
            if ResponsiveHudLayout.overlaps(pair.value, zone) then
                return false, pair.name .. " overlaps exclusion zone " .. tostring(index)
            end
        end
    end

    return true
end

return ResponsiveHudLayout
