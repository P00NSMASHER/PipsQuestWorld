local catalog = dofile("highschool/content/Grade2MathCatalog.lua")

local ids = {}
local prompts = {}
local skills = {}
local difficulty = {}

local function normalized(text)
    return string.lower((text:gsub("%s+", " ")))
end

assert(#catalog >= 8)

for _, item in ipairs(catalog) do
    assert(type(item.id) == "string" and item.id ~= "")
    assert(not ids[item.id], "duplicate id " .. item.id)
    ids[item.id] = true

    assert(item.subject == "Math")
    assert(type(item.skill) == "string" and item.skill ~= "")
    skills[item.skill] = true

    assert(type(item.difficulty) == "number")
    assert(item.difficulty >= 1 and item.difficulty <= 5)
    difficulty[item.difficulty] = true

    assert(type(item.prompt) == "string" and #item.prompt > 0 and #item.prompt <= 150)
    local prompt = normalized(item.prompt)
    assert(not prompts[prompt], "duplicate prompt " .. item.id)
    prompts[prompt] = true

    assert(type(item.choices) == "table" and #item.choices >= 3 and #item.choices <= 4)
    local choiceSet = {}
    for _, choice in ipairs(item.choices) do
        local key = normalized(choice)
        assert(choice ~= "" and not choiceSet[key], "bad choice in " .. item.id)
        choiceSet[key] = true
    end

    assert(type(item.correctIndex) == "number")
    assert(item.correctIndex >= 1 and item.correctIndex <= #item.choices)
    assert(type(item.hint) == "string" and item.hint ~= "")
    assert(type(item.explanation) == "string" and item.explanation ~= "")
    assert(type(item.misconceptions) == "table")

    for i = 1, #item.choices do
        if i == item.correctIndex then
            assert(item.misconceptions[i] == nil)
        else
            assert(type(item.misconceptions[i]) == "string" and item.misconceptions[i] ~= "")
        end
    end

    assert(item.provenance == "original-grade2-core-v1")
end

local skillCount = 0
for _ in pairs(skills) do
    skillCount = skillCount + 1
end
assert(skillCount >= 8)
assert(difficulty[1] and difficulty[2] and difficulty[3])

print("PASS Grade-2 math content")
