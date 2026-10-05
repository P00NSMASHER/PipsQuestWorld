--!strict
-- Deterministic school-day rotation used by both runtime services and tests.
-- Five of seven class types run each day, with lunch fixed in period four.

local DailySchedule = {}

local CLASS_POOL = {
    { id = "math", label = "Math", room = "Math", subject = "Math" },
    { id = "art", label = "Art", room = "ELA", subject = "Art" },
    {
        id = "science_engineering",
        label = "Science & Engineering",
        room = "Science",
        subject = "ScienceEngineering",
    },
    { id = "pe", label = "Physical Education", room = "Gym", subject = "PE" },
    {
        id = "performance_arts",
        label = "Performance Arts",
        room = "SocialStudies",
        subject = "PerformanceArts",
    },
    { id = "cooking", label = "Cooking", room = "Library", subject = "Cooking" },
    { id = "dance", label = "Dance", room = "Courtyard", subject = "Dance" },
}

local function copyPeriod(period)
    return {
        id = period.id,
        label = period.label,
        room = period.room,
        subject = period.subject,
    }
end

function DailySchedule.classPool()
    local result = {}
    for index, period in ipairs(CLASS_POOL) do
        result[index] = copyPeriod(period)
    end
    return result
end

function DailySchedule.forDay(schoolDay)
    local day = tonumber(schoolDay) or 1
    day = math.max(1, math.floor(day))

    -- Advancing by five makes every adjacent day meaningfully different while
    -- cycling through every class before the seven-day pattern repeats.
    local firstClassIndex = (((day - 1) * 5) % #CLASS_POOL) + 1
    local selected = {}
    for offset = 0, 4 do
        local index = ((firstClassIndex + offset - 1) % #CLASS_POOL) + 1
        selected[#selected + 1] = copyPeriod(CLASS_POOL[index])
    end

    return {
        { id = "homeroom", label = "Homeroom", room = "Homeroom" },
        selected[1],
        selected[2],
        { id = "lunch", label = "Lunch", room = "Cafeteria" },
        selected[3],
        selected[4],
        selected[5],
        { id = "free", label = "Free Time", room = "Courtyard" },
    }
end

return DailySchedule
