local DailySchedule = assert(loadfile("school/src/shared/DailySchedule.lua"))()

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local seen = {}
for day = 1, 7 do
    local periods = DailySchedule.forDay(day)
    equal(#periods, 8, "period count")
    equal(periods[1].id, "homeroom", "homeroom position")
    equal(periods[4].id, "lunch", "lunch position")
    equal(periods[8].id, "free", "free-time position")

    local classCount = 0
    local today = {}
    for _, period in ipairs(periods) do
        if period.subject then
            classCount = classCount + 1
            if today[period.subject] then
                error("duplicate class in one school day: " .. period.subject)
            end
            today[period.subject] = true
            seen[period.subject] = true
        end
    end
    equal(classCount, 5, "daily class count")
end

equal(#DailySchedule.classPool(), 7, "class pool count")
local seenCount = 0
for _ in pairs(seen) do seenCount = seenCount + 1 end
equal(seenCount, 7, "seven-day class coverage")

local first = DailySchedule.forDay(1)
first[2].label = "mutated"
equal(DailySchedule.forDay(1)[2].label, "Math", "schedule copy isolation")

print("DAILY_SCHEDULE_ROTATION_PASS")
