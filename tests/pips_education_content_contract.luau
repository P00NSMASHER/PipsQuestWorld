local Engine = require('../game/src/serverStorage/PipsEducationEngine')
local Bank = require('../game/src/serverStorage/PipsReleaseQuestionBank')

local Deterministic = {}
Deterministic.__index = Deterministic
function Deterministic.new()
	return setmetatable({ n = 0 }, Deterministic)
end
function Deterministic:NextInteger(minimum, maximum)
	self.n += 1
	return minimum + ((self.n - 1) % (maximum - minimum + 1))
end

local ok, err = Engine.validateBank(Bank)
assert(ok, err)
assert(#Bank == 7, 'curated release pool drift')

local history = Engine.newHistory()
Engine.beginQuest(history)
local rng = Deterministic.new()
local seen = {}
local transferCount = 0
local independentCorrect = 0
local points = 0

for number = 1, Engine.QUEST_LENGTH do
	local question = Engine.pickNextQuestion(Bank, history, rng)
	assert(question.tier == 'material', 'release pool must remain current material')
	assert(not seen[question.id], 'release quest repeated an item')
	seen[question.id] = true

	local view = Engine.clientView(question, number)
	assert(view.correctIndex == nil, 'client view leaked the answer')
	assert(#view.options >= 2 and #view.options <= 4)
	assert(view.questionNumber == number)
	assert(view.questionTotal == Engine.QUEST_LENGTH)

	if question.questionType == 'transfer' then
		transferCount += 1
	end

	assert(Engine.isCorrect(question, question.correctIndex))
	independentCorrect += 1
	points += Engine.scoreResolution(0, false)
	Engine.markShown(history, question)
	Engine.markResolved(history)
end

assert(history.resolvedCount == Engine.QUEST_LENGTH)
assert(transferCount >= 1, 'five-question run needs transfer evidence')
assert(points == 125)
assert(Engine.scorePercent(points, 5) == 100)
assert(Engine.gradeBand(100) == 'A')
assert(Engine.masteryTier(independentCorrect, 5) == 'Brightside Pro')

local corrected = Engine.scoreResolution(1, false)
local modeled = Engine.scoreResolution(3, true)
assert(corrected == 20)
assert(modeled == 0)
assert(Engine.masteryTier(4, 5) == 'Quest Champ')

print('PIPS_EDUCATION_CONTENT_CONTRACT_PASS', #Bank, transferCount, points)
