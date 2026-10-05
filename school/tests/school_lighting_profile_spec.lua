local Profile = assert(loadfile("school/src/shared/SchoolLightingProfile.lua"))()

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function near(actual, expected, tolerance, label)
    if math.abs(actual - expected) > tolerance then
        error((label or "value") .. ": expected near " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local defaultIndex, defaultCount = Profile.normalizeSchedule(nil, nil)
equal(defaultIndex, 1, "default period index")
equal(defaultCount, 8, "default period count")

local clampedIndex, clampedCount = Profile.normalizeSchedule(99, 4)
equal(clampedIndex, 4, "clamped period index")
equal(clampedCount, 4, "normalized period count")

near(Profile.clockForSchedule(1, 8, 0), 6.5, 0.001, "schedule dawn")
near(Profile.clockForSchedule(4, 8, 0), 12.5, 0.001, "schedule midday")
near(Profile.clockForSchedule(8, 8, 1), 22.5, 0.001, "schedule evening")
near(Profile.clockForSchedule(1, 8, -10), 6.5, 0.001, "period progress low clamp")
near(Profile.clockForSchedule(8, 8, 10), 22.5, 0.001, "period progress high clamp")

local midday = Profile.sample(12)
equal(midday.lampsEnabled, false, "midday lamps")
near(midday.lampLevel, 0, 0.001, "midday lamp level")
if midday.brightness < 2 or midday.fogEnd < 2000 then
    error("midday profile is unexpectedly dim or foggy")
end

local evening = Profile.sample(21)
equal(evening.lampsEnabled, true, "evening lamps")
if evening.lampLevel < 0.95 then
    error("evening lamps did not reach full output")
end
if evening.brightness < 1.35 or evening.fogEnd < 1200 then
    error("evening profile violates readable-night bounds")
end
for _, color in ipairs({ evening.ambient, evening.outdoorAmbient }) do
    if color.r < 0.15 or color.g < 0.15 or color.b < 0.15 then
        error("evening ambient color is too dark for readable gameplay")
    end
end

local wrapped = Profile.sample(25)
local oneAm = Profile.sample(1)
near(wrapped.brightness, oneAm.brightness, 0.001, "clock wrapping")

evening.ambient.r = 0
if Profile.sample(21).ambient.r == 0 then
    error("profile samples share mutable color state")
end

print("SCHOOL_LIGHTING_PROFILE_PASS")
