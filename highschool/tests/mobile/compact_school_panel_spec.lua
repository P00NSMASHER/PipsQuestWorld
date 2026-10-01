local Panel = assert(loadfile("highschool/src/mobile/CompactSchoolPanel.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function truthy(value, label)
    if not value then
        error(label or "expected truthy value", 2)
    end
end

local iphone = {
    viewport = { width = 393, height = 852 },
    safeArea = { top = 59, right = 0, bottom = 34, left = 0 },
}

local loading = assert(Panel.build({
    viewport = iphone.viewport,
    safeArea = iphone.safeArea,
    status = "loading",
}))
eq(loading.status, "loading", "loading status")
eq(loading.interactive, false, "loading should remain read-only")
truthy(Panel.validateStatic(loading), "loading layout guard")
truthy(loading.layout.panel.y >= iphone.safeArea.top, "top safe-area intrusion")
truthy(loading.layout.minimumHitTarget >= 44, "hit target contract")
truthy(loading.layout.textSize.body >= 13, "body text size")
truthy(loading.layout.panel.height <= 192, "panel height")

local errorView = assert(Panel.build({
    viewport = iphone.viewport,
    safeArea = iphone.safeArea,
    status = "error",
    errorMessage = string.rep("x", 100),
}))
eq(errorView.status, "error", "error status")
eq(#errorView.message, 72, "error text truncation")
truthy(Panel.validateStatic(errorView), "error layout guard")

local progression = {
    totalScore = 90,
    completionCount = 4,
    classes = {
        { classId = "math", score = 40, completionCount = 2 },
        { classId = "ela", score = 20, completionCount = 1 },
        { classId = "science", score = 30, completionCount = 1 },
        { classId = "social", score = 0, completionCount = 0 },
    },
}
local ready = assert(Panel.build({
    viewport = iphone.viewport,
    safeArea = iphone.safeArea,
    status = "ready",
    schedule = {
        periodLabel = "Period 2 - Mathematics",
        roomLabel = "Room 204",
    },
    progression = progression,
}))
eq(ready.status, "ready", "ready status")
eq(ready.interactive, false, "ready view must be read-only")
eq(ready.progression.totalScore, 90, "score copy")
eq(ready.progression.completionCount, 4, "completion count copy")
eq(#ready.progression.classes, 3, "class row cap")
eq(ready.progression.hasMoreClasses, true, "overflow marker")
eq(ready.schedule.roomLabel, "Room 204", "room label")
truthy(Panel.validateStatic(ready), "ready layout guard")

progression.classes[1].score = 999
eq(ready.progression.classes[1].score, 40, "read-only copy changed through caller mutation")

local small = assert(Panel.build({
    viewport = { width = 320, height = 568 },
    safeArea = { top = 20, right = 0, bottom = 0, left = 0 },
    status = "ready",
    progression = { totalScore = 0, completionCount = 0, classes = {} },
}))
truthy(Panel.validateStatic(small), "small-phone layout guard")
local coverage = (small.layout.panel.width * small.layout.panel.height)
    / (small.layout.viewport.width * small.layout.viewport.height)
truthy(coverage <= small.layout.maxScreenCoverage, "small-phone obstruction ratio")

local tooSmall, tooSmallError = Panel.build({
    viewport = { width = 200, height = 180 },
    safeArea = {},
    status = "loading",
})
eq(tooSmall, nil, "tiny viewport should fail closed")
eq(tooSmallError, "viewport_too_small", "tiny viewport error")

local badSafe, badSafeError = Panel.build({
    viewport = iphone.viewport,
    safeArea = { top = -1 },
    status = "loading",
})
eq(badSafe, nil, "negative safe-area should fail closed")
eq(badSafeError, "invalid_safe_area", "negative safe-area error")

local malformed, malformedError = Panel.build({
    viewport = iphone.viewport,
    safeArea = iphone.safeArea,
    status = "ready",
    progression = {
        totalScore = 10,
        completionCount = 1,
        classes = {
            { classId = "math", score = -10, completionCount = 1 },
        },
    },
})
eq(malformed, nil, "malformed progression should fail closed")
eq(malformedError, "invalid_progression", "malformed progression error")

print("HIGH_SCHOOL_MOBILE_COMPACT_PANEL_PASS")
