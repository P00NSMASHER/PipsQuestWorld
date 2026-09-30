local EducationEngine = {}

EducationEngine.QUEST_LENGTH = 5

local function isNonEmptyString(value)
    return type(value) == "string" and value:match("%S") ~= nil
end

local function hasUniqueChoices(options)
    local seen = {}
    for _, option in ipairs(options) do
        if seen[option] then
            return false
        end
        seen[option] = true
    end
    return true
end

function EducationEngine.validate(question)
    if type(question) ~= "table" then
        return false, "question must be a table"
    end
    if not isNonEmptyString(question.id) then
        return false, "question.id is required"
    end
    if not isNonEmptyString(question.prompt) then
        return false, "question.prompt is required"
    end
    if type(question.options) ~= "table" or #question.options ~= 3 then
        return false, "question.options must contain exactly 3 choices"
    end
    for index, option in ipairs(question.options) do
        if not isNonEmptyString(option) then
            return false, ("option %d must be non-empty"):format(index)
        end
    end
    if not hasUniqueChoices(question.options) then
        return false, "question.options must be unique"
    end
    if type(question.correctIndex) ~= "number" then
        return false, "question.correctIndex is required"
    end
    if question.correctIndex < 1 or question.correctIndex > #question.options then
        return false, "question.correctIndex is outside options"
    end
    if not isNonEmptyString(question.hint) then
        return false, "question.hint is required"
    end
    if not isNonEmptyString(question.explanation) then
        return false, "question.explanation is required"
    end
    return true
end

function EducationEngine.validateBank(bank)
    if type(bank) ~= "table" or #bank == 0 then        return false, "question bank is empty"
    end
    local seen = {}
    for index, question in ipairs(bank) do
        local ok, err = EducationEngine.validate(question)
        if not ok then
            return false, ("question %d invalid: %s"):format(index, err)
        end
        if seen[question.id] then
            return false, ("duplicate question id: %s"):format(question.id)
        end
        seen[question.id] = true
    end
    return true
end

function EducationEngine.newHistory()
    return {
        seenIds = {},
        materialExhausted = false,
        lastQuestionId = nil,
        lastSkill = nil,
        questSkillCounts = {},
        resolvedCount = 0,
        pendingComebackSkill = nil,
        pendingComebackDueAfter = nil,
    }
end

function EducationEngine.beginQuest(history)
    history.questSkillCounts = {}
    history.resolvedCount = 0
    if history.pendingComebackSkill then
        history.pendingComebackDueAfter = 0
    end
end

local function unseenForTier(bank, history, tier)
    local pool = {}
    for _, question in ipairs(bank) do
        if question.tier == tier and not history.seenIds[question.id] then
            table.insert(pool, question)
        end
    end
    return pool
end

local function allForTier(bank, tier)
    local pool = {}
    for _, question in ipairs(bank) do
        if question.tier == tier then
            table.insert(pool, question)
        end
    end
    return pool
end

local function resetFallbackSeen(bank, history)
    for _, question in ipairs(bank) do
        if question.tier == "star-fallback" then
            history.seenIds[question.id] = nil
        end
    end
end

local function filtered(pool, predicate)
    local result = {}
    for _, question in ipairs(pool) do
        if predicate(question) then
            table.insert(result, question)
        end
    end
    return result
end

local function prefer(pool, predicate)
    local preferred = filtered(pool, predicate)
    return #preferred > 0 and preferred or pool
end

function EducationEngine.pickNextQuestion(bank, history, rng)
    local ok, err = EducationEngine.validateBank(bank)
    assert(ok, err)
    history = history or EducationEngine.newHistory()
    rng = rng or Random.new()

    local pool
    if not history.materialExhausted then
        pool = unseenForTier(bank, history, "material")
        if #pool == 0 then
            history.materialExhausted = true
        end
    end

    if history.materialExhausted then
        pool = unseenForTier(bank, history, "star-fallback")
        if #pool == 0 then
            resetFallbackSeen(bank, history)
            pool = unseenForTier(bank, history, "star-fallback")
        end
    end

    if not pool or #pool == 0 then
        pool = allForTier(bank, "material")
    end

    local dueComeback = history.pendingComebackSkill
        and history.pendingComebackDueAfter
        and history.resolvedCount >= history.pendingComebackDueAfter

    if dueComeback then
        local comebackPool = filtered(pool, function(question)
            return question.skill == history.pendingComebackSkill
        end)
        if #comebackPool > 0 then
            pool = comebackPool
            history.pendingComebackSkill = nil
            history.pendingComebackDueAfter = nil
        end
    end

    if history.resolvedCount < 3 then
        pool = prefer(pool, function(question)
            return (tonumber(question.difficulty) or 2) <= 2
        end)    end

    pool = prefer(pool, function(question)
        local count = history.questSkillCounts[question.skill] or 0
        return count < 2
    end)

    if history.lastSkill then
        pool = prefer(pool, function(question)
            return question.skill ~= history.lastSkill
        end)
    end

    if history.lastQuestionId and #pool > 1 then
        pool = prefer(pool, function(question)
            return question.id ~= history.lastQuestionId
        end)
    end

    return pool[rng:NextInteger(1, #pool)]
end

function EducationEngine.markShown(history, question)
    history.seenIds[question.id] = true
    history.lastQuestionId = question.id
    history.lastSkill = question.skill
    history.questSkillCounts[question.skill] = (history.questSkillCounts[question.skill] or 0) + 1
end

function EducationEngine.markResolved(history)
    history.resolvedCount += 1
end

function EducationEngine.queueComeback(history, question, delayQuestions)
    if question and isNonEmptyString(question.skill) then
        history.pendingComebackSkill = question.skill
        history.pendingComebackDueAfter = history.resolvedCount + (delayQuestions or 2)
    end
end

function EducationEngine.isCorrect(question, selection)
    local ok = EducationEngine.validate(question)
    if not ok then
        return false
    end
    local index = tonumber(selection)
    return index ~= nil and index == question.correctIndex
end

function EducationEngine.getHint(question)
    return isNonEmptyString(question.hint)
        and question.hint
        or "Look closely at every choice and try again."
end

function EducationEngine.getExplanation(question)
    return isNonEmptyString(question.explanation)
        and question.explanation
        or "Nice work!"
end

function EducationEngine.getWrongFeedback(question, selection, attemptNumber)
    local selected = question.options[tonumber(selection) or 0]
    if attemptNumber <= 1 and selected and type(question.choiceDiagnostics) == "table" then
        for _, diagnostic in ipairs(question.choiceDiagnostics) do
            if diagnostic.choice == selected and isNonEmptyString(diagnostic.feedback) then
                return diagnostic.feedback, "clue"
            end
        end
    end

    if attemptNumber <= 1 then
        return EducationEngine.getHint(question), "clue"
    end

    if attemptNumber == 2 then
        if isNonEmptyString(question.scaffold) then
            return question.scaffold, "support"
        end
        return EducationEngine.getHint(question), "support"
    end

    local answer = question.options[question.correctIndex]
    local explanation = EducationEngine.getExplanation(question)
    return ("The answer is %s. %s"):format(answer, explanation), "model"
end

function EducationEngine.clientView(question, questNumber)
    return {
        id = question.id,
        subject = question.subject,
        skill = question.skill,
        tier = question.tier,
        difficulty = question.difficulty,
        domain = question.domain,
        dok = question.dok,
        prompt = question.prompt,
        options = table.clone(question.options),
        richContent = question.richContent,
        questionNumber = questNumber,
        questionTotal = EducationEngine.QUEST_LENGTH,
    }
end

function EducationEngine.pickQuestion(bank, previousId, rng)
    local history = EducationEngine.newHistory()
    history.lastQuestionId = previousId
    return EducationEngine.pickNextQuestion(bank, history, rng)
end

return EducationEngine
