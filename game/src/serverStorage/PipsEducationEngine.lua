local EducationEngine = {}

EducationEngine.QUEST_LENGTH = 5
EducationEngine.MIN_OPTIONS = 2
EducationEngine.MAX_OPTIONS = 4
EducationEngine.MAX_DIFFICULTY_JUMP = 1
EducationEngine.FIRST_TRY_POINTS = 25
EducationEngine.CORRECTED_POINTS = 20

local function isNonEmptyString(value)
	return type(value) == 'string' and value:match('%S') ~= nil
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

local function isInteger(value)
	return type(value) == 'number' and value % 1 == 0
end

function EducationEngine.validate(question)
	if type(question) ~= 'table' then
		return false, 'question must be a table'
	end
	if not isNonEmptyString(question.id) then
		return false, 'question.id is required'
	end
	if not isNonEmptyString(question.prompt) then
		return false, 'question.prompt is required'
	end
	if type(question.options) ~= 'table'
		or #question.options < EducationEngine.MIN_OPTIONS
		or #question.options > EducationEngine.MAX_OPTIONS then
		return false, 'question.options must contain 2-4 choices'
	end
	for index, option in ipairs(question.options) do
		if not isNonEmptyString(option) then
			return false, ('option %d must be non-empty'):format(index)
		end
	end
	if not hasUniqueChoices(question.options) then
		return false, 'question.options must be unique'
	end
	if not isInteger(question.correctIndex) then
		return false, 'question.correctIndex must be an integer'
	end
	if question.correctIndex < 1 or question.correctIndex > #question.options then
		return false, 'question.correctIndex is outside options'
	end
	if not isNonEmptyString(question.hint) then
		return false, 'question.hint is required'
	end
	if not isNonEmptyString(question.explanation) then
		return false, 'question.explanation is required'
	end
	if question.tier ~= 'material' and question.tier ~= 'star-fallback' then
		return false, 'question.tier must be material or star-fallback'
	end
	if question.questionType ~= nil
		and question.questionType ~= 'direct'
		and question.questionType ~= 'transfer'
		and question.questionType ~= 'reasoning' then
		return false, 'question.questionType is invalid'
	end
	if question.difficulty ~= nil and tonumber(question.difficulty) == nil then
		return false, 'question.difficulty must be numeric when present'
	end
	return true
end

function EducationEngine.validateBank(bank)
	if type(bank) ~= 'table' or #bank == 0 then
		return false, 'question bank is empty'
	end
	local seen = {}
	for index, question in ipairs(bank) do
		local ok, err = EducationEngine.validate(question)
		if not ok then
			return false, ('question %d invalid: %s'):format(index, err)
		end
		if seen[question.id] then
			return false, ('duplicate question id: %s'):format(question.id)
		end
		seen[question.id] = true
	end
	return true
end

function EducationEngine.newHistory()
	return {
		seenIds = {},
		questSeenIds = {},
		materialExhausted = false,
		lastQuestionId = nil,
		lastSkill = nil,
		lastDifficulty = nil,
		questSkillCounts = {},
		questQuestionTypeCounts = {},
		resolvedCount = 0,
		pendingComebackSkill = nil,
		pendingComebackDueAfter = nil,
	}
end

function EducationEngine.beginQuest(history)
	history.questSkillCounts = {}
	history.questQuestionTypeCounts = {}
	history.questSeenIds = {}
	history.resolvedCount = 0
	history.lastSkill = nil
	history.lastDifficulty = nil
	if history.pendingComebackSkill then
		history.pendingComebackDueAfter = 0
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

local function unseenForTier(bank, history, tier)
	return filtered(bank, function(question)
		return question.tier == tier and not history.seenIds[question.id]
	end)
end
local function allForTier(bank, tier)
	return filtered(bank, function(question)
		return question.tier == tier
	end)
end

local function resetFallbackSeen(bank, history)
	for _, question in ipairs(bank) do
		if question.tier == 'star-fallback' then
			history.seenIds[question.id] = nil
		end
	end
end

local function tierPool(bank, history)
	if not history.materialExhausted then
		local material = unseenForTier(bank, history, 'material')
		if #material > 0 then
			return material
		end
		history.materialExhausted = true
	end

	local fallback = unseenForTier(bank, history, 'star-fallback')
	if #fallback == 0 then
		resetFallbackSeen(bank, history)
		fallback = unseenForTier(bank, history, 'star-fallback')
	end
	if #fallback > 0 then
		return fallback
	end
	return allForTier(bank, 'material')
end
function EducationEngine.pickNextQuestion(bank, history, rng)
	local ok, err = EducationEngine.validateBank(bank)
	assert(ok, err)
	history = history or EducationEngine.newHistory()
	rng = rng or Random.new()

	local pool = tierPool(bank, history)
	assert(#pool > 0, 'question pool is empty')

	history.questSeenIds = history.questSeenIds or {}
	local freshThisQuest = filtered(pool, function(question)
		return not history.questSeenIds[question.id]
	end)
	if #freshThisQuest > 0 then
		pool = freshThisQuest
	end

	local dueComeback = history.pendingComebackSkill
		and history.pendingComebackDueAfter
		and history.resolvedCount >= history.pendingComebackDueAfter
	if dueComeback then
		local comeback = filtered(pool, function(question)
			return question.skill == history.pendingComebackSkill
		end)
		if #comeback > 0 then
			pool = comeback
			history.pendingComebackSkill = nil
			history.pendingComebackDueAfter = nil
		end
	end

	local transferCount = history.questQuestionTypeCounts.transfer or 0
	local lastSlot = history.resolvedCount >= EducationEngine.QUEST_LENGTH - 1
	if transferCount == 0 and lastSlot then
		pool = prefer(pool, function(question)
			return question.questionType == 'transfer'
		end)
	end
	if history.resolvedCount < 2 then
		pool = prefer(pool, function(question)
			return (tonumber(question.difficulty) or 2) <= 2
		end)
	end

	if history.lastDifficulty then
		local maximum = history.lastDifficulty + EducationEngine.MAX_DIFFICULTY_JUMP
		pool = prefer(pool, function(question)
			return (tonumber(question.difficulty) or history.lastDifficulty) <= maximum
		end)
	end

	-- Use an unvisited skill before repeating one whenever the current
	-- difficulty/tier pool contains a viable alternative. This keeps a short
	-- five-question quest broad enough to sample actual skill variety instead
	-- of bouncing between two or three familiar skills.
	pool = prefer(pool, function(question)
		local count = history.questSkillCounts[question.skill] or 0
		return count == 0
	end)

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
	history.questSeenIds = history.questSeenIds or {}
	history.questSeenIds[question.id] = true
	history.lastQuestionId = question.id
	history.lastSkill = question.skill
	history.lastDifficulty = tonumber(question.difficulty) or history.lastDifficulty
	history.questSkillCounts[question.skill] = (history.questSkillCounts[question.skill] or 0) + 1
	local questionType = question.questionType or 'direct'
	history.questQuestionTypeCounts[questionType] =
		(history.questQuestionTypeCounts[questionType] or 0) + 1
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
	return isInteger(index) and index == question.correctIndex
end
function EducationEngine.isIndependent(misses)
	return (tonumber(misses) or 0) == 0
end

function EducationEngine.scoreResolution(misses, modeled)
	local missCount = math.max(0, tonumber(misses) or 0)
	if modeled or missCount >= 3 then
		return 0
	end
	if missCount == 0 then
		return EducationEngine.FIRST_TRY_POINTS
	end
	return EducationEngine.CORRECTED_POINTS
end

function EducationEngine.scorePercent(points, questionCount)
	local count = math.max(1, tonumber(questionCount) or EducationEngine.QUEST_LENGTH)
	local maximum = EducationEngine.FIRST_TRY_POINTS * count
	local earned = math.clamp(tonumber(points) or 0, 0, maximum)
	return math.floor((earned / maximum) * 100 + 0.5)
end

function EducationEngine.gradeBand(percent)
	local value = math.clamp(tonumber(percent) or 0, 0, 100)
	if value >= 90 then
		return 'A'
	elseif value >= 80 then
		return 'B'
	elseif value >= 70 then
		return 'C'
	end
	return 'Practice'
end

function EducationEngine.masteryTier(independentCorrect, questionCount)
	local total = math.max(1, tonumber(questionCount) or EducationEngine.QUEST_LENGTH)
	local independent = math.clamp(tonumber(independentCorrect) or 0, 0, total)
	if independent == total then
		return 'Brightside Pro'
	elseif independent >= total - 1 then
		return 'Quest Champ'
	elseif independent >= math.ceil(total * 0.4) then
		return 'Rising Star'
	end
	return 'Rookie'
end

function EducationEngine.getHint(question)
	return isNonEmptyString(question.hint)
		and question.hint
		or 'Look closely at every choice and try again.'
end

function EducationEngine.getExplanation(question)
	return isNonEmptyString(question.explanation)
		and question.explanation
		or 'Nice work!'
end

function EducationEngine.getWrongFeedback(question, selection, attemptNumber)
	local selected = question.options[tonumber(selection) or 0]
	if attemptNumber <= 1 and selected and type(question.choiceDiagnostics) == 'table' then
		for _, diagnostic in ipairs(question.choiceDiagnostics) do
			if diagnostic.choice == selected and isNonEmptyString(diagnostic.feedback) then
				return diagnostic.feedback, 'clue'
			end
		end
	end

	if attemptNumber <= 1 then
		return EducationEngine.getHint(question), 'clue'
	end
	if attemptNumber == 2 then
		if isNonEmptyString(question.scaffold) then
			return question.scaffold, 'support'
		end
		return EducationEngine.getHint(question), 'support'
	end

	local answer = question.options[question.correctIndex]
	local explanation = EducationEngine.getExplanation(question)
	return ('The answer is %s. %s'):format(answer, explanation), 'model'
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
		questionType = question.questionType,
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
