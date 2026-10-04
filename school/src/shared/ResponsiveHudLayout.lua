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
        if ResponsiveHudLayout.overlaps(layout.quick, zone) then
            return false, "quick bar overlaps exclusion zone " .. tostring(index)
        end
    end

    return true
end

return ResponsiveHudLayout
