-- Pure day/night profile for the school runtime.
-- This module deliberately has no Roblox service or instance dependencies so
-- its schedule math and readability bounds remain deterministic in CI.

local SchoolLightingProfile = {}

local DEFAULT_PERIOD_COUNT = 8
local MAX_PERIOD_COUNT = 32
local SCHEDULE_START_HOUR = 6.5
local SCHEDULE_END_HOUR = 22.5

local KEYFRAMES = {
    {
        hour = 0,
        ambient = { r = 0.18, g = 0.22, b = 0.33 },
        outdoorAmbient = { r = 0.22, g = 0.27, b = 0.39 },
        brightness = 1.45,
        fogEnd = 1250,
    },
    {
        hour = 5,
        ambient = { r = 0.27, g = 0.29, b = 0.38 },
        outdoorAmbient = { r = 0.38, g = 0.36, b = 0.43 },
        brightness = 1.7,
        fogEnd = 1500,
    },
    {
        hour = 7,
        ambient = { r = 0.51, g = 0.52, b = 0.57 },
        outdoorAmbient = { r = 0.58, g = 0.57, b = 0.59 },
        brightness = 2.15,
        fogEnd = 2400,
    },
    {
        hour = 12,
        ambient = { r = 0.59, g = 0.61, b = 0.65 },
        outdoorAmbient = { r = 0.67, g = 0.68, b = 0.71 },
        brightness = 2.55,
        fogEnd = 3200,
    },
    {
        hour = 16.5,
        ambient = { r = 0.55, g = 0.53, b = 0.55 },
        outdoorAmbient = { r = 0.64, g = 0.58, b = 0.54 },
        brightness = 2.2,
        fogEnd = 2600,
    },
    {
        hour = 18.5,
        ambient = { r = 0.39, g = 0.35, b = 0.42 },
        outdoorAmbient = { r = 0.48, g = 0.39, b = 0.41 },
        brightness = 1.85,
        fogEnd = 1850,
    },
    {
        hour = 20,
        ambient = { r = 0.23, g = 0.27, b = 0.38 },
        outdoorAmbient = { r = 0.28, g = 0.33, b = 0.46 },
        brightness = 1.55,
        fogEnd = 1400,
    },
    {
        hour = 24,
        ambient = { r = 0.18, g = 0.22, b = 0.33 },
        outdoorAmbient = { r = 0.22, g = 0.27, b = 0.39 },
        brightness = 1.45,
        fogEnd = 1250,
    },
}

local function isFinite(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function lerp(left, right, alpha)
    return left + ((right - left) * alpha)
end

local function lerpColor(left, right, alpha)
    return {
        r = lerp(left.r, right.r, alpha),
        g = lerp(left.g, right.g, alpha),
        b = lerp(left.b, right.b, alpha),
    }
end

local function smoothstep(value)
    local alpha = clamp(value, 0, 1)
    return alpha * alpha * (3 - (2 * alpha))
end

local function normalizeClock(clockTime)
    local value = isFinite(clockTime) and clockTime or 12
    value = value % 24
    if value < 0 then
        value = value + 24
    end
    return value
end

function SchoolLightingProfile.normalizeSchedule(periodIndex, periodCount)
    local count = isFinite(periodCount) and math.floor(periodCount) or DEFAULT_PERIOD_COUNT
    count = clamp(count, 1, MAX_PERIOD_COUNT)

    local index = isFinite(periodIndex) and math.floor(periodIndex) or 1
    index = clamp(index, 1, count)
    return index, count
end

function SchoolLightingProfile.clockForSchedule(periodIndex, periodCount, periodProgress)
    local index, count = SchoolLightingProfile.normalizeSchedule(periodIndex, periodCount)
    local progress = isFinite(periodProgress) and periodProgress or 0
    progress = clamp(progress, 0, 1)

    local scheduleProgress = ((index - 1) + progress) / count
    return lerp(SCHEDULE_START_HOUR, SCHEDULE_END_HOUR, scheduleProgress)
end

function SchoolLightingProfile.lampLevelForClock(clockTime)
    local hour = normalizeClock(clockTime)
    if hour >= 19.25 or hour < 5.5 then
        return 1
    end
    if hour >= 17.25 then
        return smoothstep((hour - 17.25) / 2)
    end
    if hour < 7 then
        return 1 - smoothstep((hour - 5.5) / 1.5)
    end
    return 0
end

function SchoolLightingProfile.sample(clockTime)
    local hour = normalizeClock(clockTime)
    local left = KEYFRAMES[1]
    local right = KEYFRAMES[#KEYFRAMES]

    for index = 1, #KEYFRAMES - 1 do
        local candidateLeft = KEYFRAMES[index]
        local candidateRight = KEYFRAMES[index + 1]
        if hour >= candidateLeft.hour and hour <= candidateRight.hour then
            left = candidateLeft
            right = candidateRight
            break
        end
    end

    local span = math.max(0.001, right.hour - left.hour)
    local alpha = clamp((hour - left.hour) / span, 0, 1)
    local lampLevel = SchoolLightingProfile.lampLevelForClock(hour)

    return {
        clockTime = hour,
        ambient = lerpColor(left.ambient, right.ambient, alpha),
        outdoorAmbient = lerpColor(left.outdoorAmbient, right.outdoorAmbient, alpha),
        brightness = lerp(left.brightness, right.brightness, alpha),
        fogEnd = lerp(left.fogEnd, right.fogEnd, alpha),
        lampLevel = lampLevel,
        lampsEnabled = lampLevel > 0.02,
        lampBrightness = 2.4 * lampLevel,
        lampRange = 28,
    }
end

function SchoolLightingProfile.forSchedule(periodIndex, periodCount, periodProgress)
    return SchoolLightingProfile.sample(
        SchoolLightingProfile.clockForSchedule(periodIndex, periodCount, periodProgress)
    )
end

SchoolLightingProfile.DEFAULT_PERIOD_COUNT = DEFAULT_PERIOD_COUNT
SchoolLightingProfile.SCHEDULE_START_HOUR = SCHEDULE_START_HOUR
SchoolLightingProfile.SCHEDULE_END_HOUR = SCHEDULE_END_HOUR

return SchoolLightingProfile
