local Engine = require('../game/src/serverStorage/PipsEducationEngine')

local Deterministic = {}
Deterministic.__index = Deterministic
function Deterministic.new()
	return setmetatable({}, Deterministic)
end
function Deterministic:NextInteger(minimum, _maximum)
	return minimum
end

local function q(id, skill, difficulty, questionType, tier, options, correctIndex)
	return {
		id = id,
		subject = 'Test',
		skill = skill,
		tier = tier or 'material',
		difficulty = difficulty or 2,
		questionType = questionType or 'direct',
		prompt = 'Prompt ' .. id,
		options = options or { 'A', 'B', 'C' },
		correctIndex = correctIndex or 1,
		hint = 'Hint ' .. id,
		scaffold = 'Scaffold ' .. id,
		explanation = 'Explanation ' .. id,
	}
end
local validTwo = q('two', 'two', 1, 'direct', 'material', { 'A', 'B' }, 2)
local validFour = q('four', 'four', 1, 'direct', 'material', { 'A', 'B', 'C', 'D' }, 4)
assert(Engine.validate(validTwo))
assert(Engine.validate(validFour))

local invalidOne = q('one', 'one', 1, 'direct', 'material', { 'A' }, 1)
local invalidFive = q('five', 'five', 1, 'direct', 'material', { 'A', 'B', 'C', 'D', 'E' }, 1)
assert(not Engine.validate(invalidOne))
assert(not Engine.validate(invalidFive))

local bank = {
	q('q1', 's1', 1, 'direct'),
	q('q2', 's2', 2, 'direct'),
	q('q3', 's3', 2, 'direct'),
	q('q4', 's4', 2, 'direct'),
	q('q5', 's5', 2, 'transfer'),
	q('q6', 's6', 3, 'reasoning'),
	q('f1', 'fs1', 2, 'transfer', 'star-fallback'),
	q('f2', 'fs2', 2, 'direct', 'star-fallback'),
}
assert(Engine.validateBank(bank))

local history = Engine.newHistory()
Engine.beginQuest(history)
local rng = Deterministic.new()
local picked = {}
for index = 1, Engine.QUEST_LENGTH do
	local question = Engine.pickNextQuestion(bank, history, rng)
	assert(question.tier == 'material', 'material must be used before STAR fallback')
	assert(not picked[question.id], 'question repeated inside quest')
	picked[question.id] = true
	Engine.markShown(history, question)
	Engine.markResolved(history)
	if index == Engine.QUEST_LENGTH then
		assert(question.questionType == 'transfer', 'fifth slot must force transfer when none appeared')
	end
end
assert(history.resolvedCount == 5)
assert((history.questQuestionTypeCounts.transfer or 0) >= 1)

local exhausted = Engine.newHistory()
for _, question in ipairs(bank) do
	if question.tier == 'material' then
		exhausted.seenIds[question.id] = true
	end
end
local fallback = Engine.pickNextQuestion(bank, exhausted, rng)
assert(fallback.tier == 'star-fallback', 'STAR fallback must begin only after material exhaustion')

local jumpBank = {
	q('jump3', 'j3', 3, 'direct'),
	q('jump2', 'j2', 2, 'direct'),
}
local jumpHistory = Engine.newHistory()
jumpHistory.lastDifficulty = 1
jumpHistory.resolvedCount = 3
local capped = Engine.pickNextQuestion(jumpBank, jumpHistory, rng)
assert(capped.difficulty == 2, 'difficulty may not jump upward by more than one level')

local comebackBank = {
	q('c1', 'target', 1, 'direct'),
	q('other', 'other', 1, 'direct'),
	q('c2', 'target', 1, 'transfer'),
}
local comebackHistory = Engine.newHistory()
Engine.beginQuest(comebackHistory)
local first = Engine.pickNextQuestion(comebackBank, comebackHistory, rng)
assert(first.id == 'c1')
Engine.markShown(comebackHistory, first)
Engine.markResolved(comebackHistory)
Engine.queueComeback(comebackHistory, first, 1)

local second = Engine.pickNextQuestion(comebackBank, comebackHistory, rng)
assert(second.id == 'other')
Engine.markShown(comebackHistory, second)
Engine.markResolved(comebackHistory)

local third = Engine.pickNextQuestion(comebackBank, comebackHistory, rng)
assert(third.skill == 'target', 'same-skill comeback must be scheduled after support')

assert(Engine.isIndependent(0))
assert(not Engine.isIndependent(1))
assert(Engine.isCorrect(validFour, 4))
assert(not Engine.isCorrect(validFour, 1))
local diagnosticQuestion = q('diag', 'diag', 2, 'direct')
diagnosticQuestion.choiceDiagnostics = {
	{ choice = 'B', feedback = 'Specific misconception feedback.' },
}
local message1, kind1 = Engine.getWrongFeedback(diagnosticQuestion, 2, 1)
assert(message1 == 'Specific misconception feedback.')
assert(kind1 == 'clue')
local message2, kind2 = Engine.getWrongFeedback(diagnosticQuestion, 2, 2)
assert(message2 == diagnosticQuestion.scaffold)
assert(kind2 == 'support')
local message3, kind3 = Engine.getWrongFeedback(diagnosticQuestion, 2, 3)
assert(string.find(message3, diagnosticQuestion.options[diagnosticQuestion.correctIndex], 1, true))
assert(kind3 == 'model')

local client = Engine.clientView(validFour, 2)
assert(client.correctIndex == nil, 'client view must never leak correctIndex')
assert(#client.options == 4)
assert(client.questionNumber == 2)
assert(client.questionTotal == Engine.QUEST_LENGTH)
assert(client.questionType == 'direct')

print('PIPS_EDUCATION_ENGINE_SMOKE_PASS')
