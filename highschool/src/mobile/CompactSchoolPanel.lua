local CompactSchoolPanel = {}

local MIN_HIT_TARGET = 44
local MIN_TEXT_SIZE = 13
local MAX_PANEL_WIDTH = 330
local MAX_PANEL_HEIGHT = 192
local MAX_SCREEN_COVERAGE = 0.34
local EDGE_MARGIN = 12
local MAX_CLASS_ROWS = 3

local function finiteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function nonNegativeNumber(value)
    return finiteNumber(value) and value >= 0
end

local function integer(value)
    return finiteNumber(value) and value % 1 == 0
end

local function normalizeInsets(safeArea)
    safeArea = safeArea or {}
    local result = {
        top = safeArea.top or 0,
        right = safeArea.right or 0,
        bottom = safeArea.bottom or 0,
        left = safeArea.left or 0,
    }
    for _, key in ipairs({ "top", "right", "bottom", "left" }) do
        if not nonNegativeNumber(result[key]) then
            return nil, "invalid_safe_area"
        end
    end
    return result
end

local function truncate(value, limit)
    if value == nil then return nil end
    if type(value) ~= "string" then return nil end
    if #value <= limit then return value end
    return string.sub(value, 1, limit - 3) .. "..."
end

local function buildLayout(viewport, safeArea)
    if type(viewport) ~= "table"
        or not nonNegativeNumber(viewport.width)
        or not nonNegativeNumber(viewport.height)
        or viewport.width <= 0
        or viewport.height <= 0 then
        return nil, "invalid_viewport"
    end

    local insets, insetError = normalizeInsets(safeArea)
    if not insets then return nil, insetError end

    local availableWidth = viewport.width - insets.left - insets.right
    local availableHeight = viewport.height - insets.top - insets.bottom
    if availableWidth < 244 or availableHeight < 220 then
        return nil, "viewport_too_small"
    end

    local panelWidth = math.min(MAX_PANEL_WIDTH, availableWidth - EDGE_MARGIN * 2)
    local panelHeight = math.min(MAX_PANEL_HEIGHT, availableHeight - EDGE_MARGIN * 2)
    local maxHeightForCoverage = math.floor(
        (MAX_SCREEN_COVERAGE * viewport.width * viewport.height) / panelWidth
    )
    panelHeight = math.min(panelHeight, maxHeightForCoverage)

    if panelWidth < 220 or panelHeight < 132 then
        return nil, "viewport_too_small"
    end

    return {
        viewport = { width = viewport.width, height = viewport.height },
        safeArea = insets,
        panel = {
            x = viewport.width - insets.right - EDGE_MARGIN - panelWidth,
            y = insets.top + EDGE_MARGIN,
            width = panelWidth,
            height = panelHeight,
        },
        minimumHitTarget = MIN_HIT_TARGET,
        maxClassRows = MAX_CLASS_ROWS,
        textSize = { title = 16, body = 14, meta = MIN_TEXT_SIZE },
        maxScreenCoverage = MAX_SCREEN_COVERAGE,
    }
end

local function normalizeProgression(progression)
    progression = progression or { totalScore = 0, completionCount = 0, classes = {} }
    if type(progression) ~= "table"
        or not nonNegativeNumber(progression.totalScore)
        or not integer(progression.completionCount)
        or progression.completionCount < 0
        or type(progression.classes) ~= "table" then
        return nil, "invalid_progression"
    end

    local rows = {}
    for index, classState in ipairs(progression.classes) do
        if index > MAX_CLASS_ROWS then break end
        if type(classState) ~= "table"
            or type(classState.classId) ~= "string"
            or classState.classId == ""
            or not nonNegativeNumber(classState.score)
            or not integer(classState.completionCount)
            or classState.completionCount < 0 then
            return nil, "invalid_progression"
        end
        rows[#rows + 1] = {
            classId = truncate(classState.classId, 24),
            score = classState.score,
            completionCount = classState.completionCount,
        }
    end

    return {
        totalScore = progression.totalScore,
        completionCount = progression.completionCount,
        classes = rows,
        hasMoreClasses = #progression.classes > MAX_CLASS_ROWS,
    }
end

local function normalizeSchedule(schedule)
    if schedule == nil then
        return { periodLabel = nil, roomLabel = nil }
    end
    if type(schedule) ~= "table" then return nil, "invalid_schedule" end
    if schedule.periodLabel ~= nil and type(schedule.periodLabel) ~= "string" then
        return nil, "invalid_schedule"
    end
    if schedule.roomLabel ~= nil and type(schedule.roomLabel) ~= "string" then
        return nil, "invalid_schedule"
    end
    return {
        periodLabel = truncate(schedule.periodLabel, 36),
        roomLabel = truncate(schedule.roomLabel, 36),
    }
end

function CompactSchoolPanel.build(input)
    if type(input) ~= "table" then return nil, "invalid_input" end

    local layout, layoutError = buildLayout(input.viewport, input.safeArea)
    if not layout then return nil, layoutError end

    local status = input.status or "loading"
    if status ~= "loading" and status ~= "error" and status ~= "ready" then
        return nil, "invalid_status"
    end

    local result = { status = status, layout = layout, interactive = false }
    if status == "loading" then
        result.message = "Loading school info..."
        return result
    end
    if status == "error" then
        result.message = truncate(input.errorMessage or "School info unavailable", 72)
        return result
    end

    local progression, progressionError = normalizeProgression(input.progression)
    if not progression then return nil, progressionError end
    local schedule, scheduleError = normalizeSchedule(input.schedule)
    if not schedule then return nil, scheduleError end

    result.schedule = schedule
    result.progression = progression
    return result
end

function CompactSchoolPanel.validateStatic(view)
    if type(view) ~= "table" or type(view.layout) ~= "table" then
        return false, "invalid_view"
    end

    local layout = view.layout
    local panel = layout.panel
    local viewport = layout.viewport
    local safe = layout.safeArea

    if type(panel) ~= "table" or type(viewport) ~= "table" or type(safe) ~= "table" then
        return false, "invalid_layout"
    end
    if layout.minimumHitTarget < MIN_HIT_TARGET then
        return false, "hit_target_too_small"
    end
    if layout.textSize.title < MIN_TEXT_SIZE
        or layout.textSize.body < MIN_TEXT_SIZE
        or layout.textSize.meta < MIN_TEXT_SIZE then
        return false, "text_too_small"
    end
    if panel.width > MAX_PANEL_WIDTH or panel.height > MAX_PANEL_HEIGHT then
        return false, "panel_too_large"
    end

    local safeRight = viewport.width - safe.right
    local safeBottom = viewport.height - safe.bottom
    if panel.x < safe.left
        or panel.y < safe.top
        or panel.x + panel.width > safeRight
        or panel.y + panel.height > safeBottom then
        return false, "panel_outside_safe_area"
    end

    local coverage = (panel.width * panel.height) / (viewport.width * viewport.height)
    if coverage > MAX_SCREEN_COVERAGE + 0.000001 then
        return false, "panel_obstructs_view"
    end

    return true
end

return CompactSchoolPanel
