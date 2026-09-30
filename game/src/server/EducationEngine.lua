-- EducationEngine is deliberately pure/headless. It owns no Maze World objects or UI.
-- Learning Gates call this server-side module for one short encounter at a time.

local EducationEngine = {}

local TRANSFER_TYPES = {
    transfer = true,
    application = true,
    ["skill-and-concept-application"] = true,
}

local function normalizeText(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "[^%w]+", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function arrayToSet(values)
    local result = {}
    if type(values) ~= "table" then
        return result
    end
    for _, value in ipairs(values) do
        result[value] = true
    end
    return result
end

local function copyOptions(options)
    local result = {}
    for index, value in ipairs(options or {}) do
        result[index] = value
    end
    return result
end

local function exactAnswerLeaksIntoPrompt(question)
    if question.allowAnswerInPrompt == true then
        return false
    end
    local answer = question.options and question.options[question.correctIndex]
    local normalizedAnswer = normalizeText(answer)
    local normalizedPrompt = normalizeText(question.prompt)
    if normalizedAnswer == "" or normalizedPrompt == "" then
        return false
    end
    return string.find(" " .. normalizedPrompt .. " ", " " .. normalizedAnswer .. " ", 1, true) ~= nil
end

function EducationEngine.validateQuestion(question)
    if type(question) ~= "table" then
        return false, "question-not-table"
    end
    for _, key in ipairs({ "id", "subject", "skill", "prompt" }) do
        if type(question[key]) ~= "string" or question[key] == "" then
            return false, "missing-" .. key
        end
    end
    if type(question.options) ~= "table" or #question.options < 2 then
        return false, "invalid-options"
    end
    if type(question.correctIndex) ~= "number"
        or question.correctIndex % 1 ~= 0
        or question.correctIndex < 1
        or question.correctIndex > #question.options then
        return false, "invalid-correct-index"
    end
    if exactAnswerLeaksIntoPrompt(question) then
        return false, "answer-leaked-in-prompt"
    end
    return true
end

local function isCurrentMaterial(question, currentSkills)
    return question.tier == "material" and currentSkills[question.skill] == true
end

local function typeRank(question)
    if TRANSFER_TYPES[question.questionType] == true
        or TRANSFER_TYPES[question.cognitiveDemand] == true then
        return 0
    end
    return 1
end

local function stableLess(a, b, context)
    local dueSkills = context.dueComebackSkillsSet
    local counts = context.independentOpportunitiesBySkill or {}

    local aDue = dueSkills[a.skill] and 0 or 1
    local bDue = dueSkills[b.skill] and 0 or 1
    if aDue ~= bDue then
        return aDue < bDue
    end

    local aCount = tonumber(counts[a.skill]) or 0
    local bCount = tonumber(counts[b.skill]) or 0
    if aCount ~= bCount then
        return aCount < bCount
    end

    local aType = typeRank(a)
    local bType = typeRank(b)
    if aType ~= bType then
        return aType < bType
    end

    local aDifficulty = tonumber(a.difficulty) or 0
    local bDifficulty = tonumber(b.difficulty) or 0
    if aDifficulty ~= bDifficulty then
        return aDifficulty < bDifficulty
    end

    return tostring(a.id) < tostring(b.id)
end

function EducationEngine.selectQuestion(questionBank, context)
    context = context or {}
    local currentSkills = arrayToSet(context.currentMaterialSkills)
    local valid = {}

    for _, question in ipairs(questionBank or {}) do
        local ok = EducationEngine.validateQuestion(question)
        if ok and question.id ~= context.lastQuestionId then
            table.insert(valid, question)
        end
    end

    if #valid == 0 then
        return nil, "no-nonrepeat-question"
    end

    local currentMaterial = {}
    local material = {}
    for _, question in ipairs(valid) do
        if isCurrentMaterial(question, currentSkills) then
            table.insert(currentMaterial, question)
        end
        if question.tier == "material" then
            table.insert(material, question)
        end
    end

    local pool = valid
    if #currentMaterial > 0 then
        pool = currentMaterial
    elseif #material > 0 then
        pool = material
    end

    local sortContext = {
        dueComebackSkillsSet = arrayToSet(context.dueComebackSkills),
        independentOpportunitiesBySkill = context.independentOpportunitiesBySkill or {},
    }
    table.sort(pool, function(a, b)
        return stableLess(a, b, sortContext)
    end)

    return pool[1]
end

local function publicQuestion(question)
    return {
        questionId = question.id,
        subject = question.subject,
        skill = question.skill,
        prompt = question.prompt,
        options = copyOptions(question.options),
        difficulty = question.difficulty,
        responseType = question.responseType or "multiple-choice",
    }
end

function EducationEngine.beginEncounter(questionBank, context)
    local question, reason = EducationEngine.selectQuestion(questionBank, context)
    if not question then
        return nil, reason
    end

    return {
        state = {
            question = question,
            misses = 0,
            completed = false,
        },
        presentation = publicQuestion(question),
    }
end

local function diagnosticForChoice(question, choice)
    for _, diagnostic in ipairs(question.choiceDiagnostics or {}) do
        if diagnostic.choice == choice then
            return {
                misconception = diagnostic.misconception,
                message = diagnostic.feedback,
            }
        end
    end
    return nil
end

local function evidence(independent)
    return {
        independent = independent,
        masteryEligible = independent,
    }
end

local function comebackFor(question)
    return {
        skill = question.skill,
        afterEncounters = 2,
    }
end

function EducationEngine.submitAnswer(state, choiceIndex)
    assert(type(state) == "table" and type(state.question) == "table", "invalid encounter state")
    assert(state.completed ~= true, "encounter already completed")

    local question = state.question
    assert(type(choiceIndex) == "number" and choiceIndex >= 1 and choiceIndex <= #question.options, "invalid choice")

    local choice = question.options[choiceIndex]
    local correct = choiceIndex == question.correctIndex

    if correct then
        local independent = state.misses == 0
        state.completed = true
        return {
            correct = true,
            complete = true,
            nextAction = "return-to-maze",
            evidence = evidence(independent),
            comeback = independent and nil or comebackFor(question),
        }
    end

    state.misses = state.misses + 1
    local diagnostic = diagnosticForChoice(question, choice)

    if state.misses == 1 then
        return {
            correct = false,
            complete = false,
            nextAction = "retry-same-question",
            feedback = {
                kind = "clue",
                message = question.hint or "Try a different strategy and look for the key clue.",
                diagnostic = diagnostic,
            },
            evidence = evidence(false),
        }
    end

    if state.misses == 2 then
        return {
            correct = false,
            complete = false,
            nextAction = "retry-same-question",
            feedback = {
                kind = "support",
                message = question.scaffold or question.hint or "Work it one step at a time, then try again.",
                diagnostic = diagnostic,
            },
            evidence = evidence(false),
        }
    end

    state.completed = true
    return {
        correct = false,
        complete = true,
        nextAction = "return-to-maze",
        feedback = {
            kind = "modeled",
            message = question.explanation or "Here is the worked answer so you can use the idea next time.",
            modeledAnswer = question.options[question.correctIndex],
            diagnostic = diagnostic,
        },
        evidence = evidence(false),
        comeback = comebackFor(question),
    }
end

return EducationEngine
