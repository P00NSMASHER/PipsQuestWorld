local EducationEngine = assert(loadfile("school/src/server/EducationEngine.lua"))()
local catalog = assert(loadfile("school/src/server/ClassActivityCatalog.lua"))()

local function fail(message)
    error(message, 2)
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        fail((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function assertTruthy(value, message)
    if not value then
        fail(message or "expected a truthy value")
    end
end

local function normalize(value)
    local compact = string.gsub(value, "%s+", " ")
    compact = string.gsub(compact, "^%s+", "")
    compact = string.gsub(compact, "%s+$", "")
    return string.lower(compact)
end

local expectedSubjects = {
    "Math",
    "Art",
    "PE",
    "ScienceEngineering",
    "PerformanceArts",
    "Cooking",
    "Dance",
}

local allowedFields = {
    id = true,
    subject = true,
    difficulty = true,
    prompt = true,
    choices = true,
    correctIndex = true,
    hint = true,
    explanation = true,
}

local mechanicTerms = {
    Math = { "solve", "answer" },
    Art = { "color", "tile", "canvas", "grid" },
    PE = { "ball", "throw", "shield", "team" },
    ScienceEngineering = { "scrap", "part", "magnet", "conductor" },
    PerformanceArts = { "cue", "sequence", "routine", "stage" },
    Cooking = { "recipe", "ingredient", "soup", "stew" },
    Dance = { "lane", "beat", "combo", "multiplier" },
}

local seenIds = {}
local seenPrompts = {}
local answerById = {}
local orderedIdsBySubject = {}
local subjectText = {}

assertEqual(#catalog, #expectedSubjects * 5, "catalog size")

for subjectIndex, subject in ipairs(expectedSubjects) do
    orderedIdsBySubject[subject] = {}
    subjectText[subject] = ""

    for difficulty = 1, 5 do
        local index = (subjectIndex - 1) * 5 + difficulty
        local activity = catalog[index]
        assertTruthy(type(activity) == "table", "catalog entry must be a table")
        assertEqual(activity.subject, subject, "deterministic subject order at entry " .. tostring(index))
        assertEqual(activity.difficulty, difficulty, "deterministic difficulty order for " .. subject)

        for field in pairs(activity) do
            assertTruthy(allowedFields[field], "unexpected activity field: " .. tostring(field))
        end
        for field in pairs(allowedFields) do
            assertTruthy(activity[field] ~= nil, "missing activity field " .. field .. " for " .. tostring(activity.id))
        end

        assertTruthy(type(activity.id) == "string" and string.find(activity.id, "%S") ~= nil, "blank activity id")
        assertTruthy(not seenIds[activity.id], "duplicate activity id: " .. activity.id)
        seenIds[activity.id] = true

        assertTruthy(type(activity.prompt) == "string" and string.find(activity.prompt, "%S") ~= nil, "blank prompt")
        local promptKey = normalize(activity.prompt)
        assertTruthy(not seenPrompts[promptKey], "duplicate normalized prompt: " .. activity.id)
        seenPrompts[promptKey] = true

        assertTruthy(type(activity.choices) == "table" and #activity.choices >= 2, "choices missing for " .. activity.id)
        local choiceKeys = {}
        for choiceIndex, choice in ipairs(activity.choices) do
            assertTruthy(type(choice) == "string" and string.find(choice, "%S") ~= nil, "blank choice in " .. activity.id)
            local choiceKey = normalize(choice)
            assertTruthy(not choiceKeys[choiceKey], "duplicate normalized choice in " .. activity.id)
            choiceKeys[choiceKey] = true
            assertEqual(choiceIndex, math.floor(choiceIndex), "choice index must be integral")
        end

        assertTruthy(
            type(activity.correctIndex) == "number"
                and activity.correctIndex == math.floor(activity.correctIndex)
                and activity.correctIndex >= 1
                and activity.correctIndex <= #activity.choices,
            "invalid correctIndex for " .. activity.id
        )
        assertTruthy(type(activity.hint) == "string" and string.find(activity.hint, "%S") ~= nil, "blank hint")
        assertTruthy(type(activity.explanation) == "string" and string.find(activity.explanation, "%S") ~= nil, "blank explanation")

        answerById[activity.id] = activity.correctIndex
        table.insert(orderedIdsBySubject[subject], activity.id)
        subjectText[subject] = subjectText[subject] .. " " .. normalize(activity.prompt)
    end
end

for subject, terms in pairs(mechanicTerms) do
    local found = false
    for _, term in ipairs(terms) do
        if string.find(subjectText[subject], term, 1, true) then
            found = true
            break
        end
    end
    assertTruthy(found, subject .. " activities do not express their class mechanic")
end

-- The production validator must accept the complete bank.
local engine = EducationEngine.new(catalog, {
    maxAttempts = 2,
    maxDifficultyJump = 1,
})

-- Every subject follows the same deterministic 1-to-5 adaptive path. Public
-- activity payloads expose neither the answer key nor teaching feedback.
for _, subject in ipairs(expectedSubjects) do
    local sessionId = "catalog-" .. subject
    engine:beginSession(sessionId, subject, 1)

    for difficulty, expectedId in ipairs(orderedIdsBySubject[subject]) do
        local publicActivity, state = engine:nextActivity(sessionId)
        assertEqual(state, "new", subject .. " activity state")
        assertEqual(publicActivity.id, expectedId, subject .. " deterministic activity order")
        assertEqual(publicActivity.difficulty, difficulty, subject .. " adaptive difficulty")
        assertEqual(publicActivity.correctIndex, nil, subject .. " correctIndex leaked")
        assertEqual(publicActivity.hint, nil, subject .. " hint leaked before submission")
        assertEqual(publicActivity.explanation, nil, subject .. " explanation leaked before submission")

        local response, submitState = engine:submit(
            sessionId,
            publicActivity.id,
            sessionId .. "-submission-" .. tostring(difficulty),
            answerById[publicActivity.id]
        )
        assertEqual(submitState, "accepted", subject .. " submission state")
        assertEqual(response.correct, true, subject .. " server-side answer rejected")
        assertEqual(response.completed, true, subject .. " correct answer did not complete")
    end

    local exhausted, exhaustedState = engine:nextActivity(sessionId)
    assertEqual(exhausted, nil, subject .. " bank should be exhausted")
    assertEqual(exhaustedState, "exhausted", subject .. " exhaustion state")
end

print("CLASS_ACTIVITY_CATALOG_TESTS_OK")
