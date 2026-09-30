local Engine = require('../game/src/serverStorage/PipsEducationEngine')
local Bank = require('../game/src/serverStorage/PipsReleaseQuestionBank')

local ok, err = Engine.validateBank(Bank)
assert(ok, err)
assert(#Bank >= Engine.QUEST_LENGTH, 'release bank must support a full quest')

local transfer = 0
local skills = {}
for _, question in ipairs(Bank) do
	assert(question.correctIndex >= 1 and question.correctIndex <= #question.options)
	assert(Engine.clientView(question, 1).correctIndex == nil, 'client view leaked answer authority')
	skills[question.skill] = true
	if question.questionType == 'transfer' or question.questionType == 'reasoning' then
		transfer += 1
	end
end

local skillCount = 0
for _ in pairs(skills) do
	skillCount += 1
end

assert(skillCount >= 4, 'release bank needs at least four distinct skills')
assert(transfer >= 1, 'release bank needs application/transfer coverage')

local history = Engine.newHistory()
Engine.beginQuest(history)
local Deterministic = {}
Deterministic.__index = Deterministic
function Deterministic.new()
	return setmetatable({}, Deterministic)
end
function Deterministic:NextInteger(minimum, _maximum)
	return minimum
end
local rng = Deterministic.new()
local seen = {}
for index = 1, Engine.QUEST_LENGTH do
	local question = Engine.pickNextQuestion(Bank, history, rng)
	assert(not seen[question.id], 'release quest repeated a question')
	seen[question.id] = true
	Engine.markShown(history, question)
	Engine.markResolved(history)
	if index == Engine.QUEST_LENGTH then
		assert((history.questQuestionTypeCounts.transfer or 0) >= 1, 'quest missed transfer/application requirement')
	end
end

print('PIPS_RELEASE_ENGINE_CONTRACT_PASS', #Bank, skillCount, transfer)
