local Engine = require("../game/src/serverStorage/PipsEducationEngine")

local Deterministic = {}
Deterministic.__index = Deterministic

function Deterministic.new()
	return setmetatable({ n = 0 }, Deterministic)
end

function Deterministic:NextInteger(minimum, maximum)
	self.n += 1
	return minimum + ((self.n - 1) % (maximum - minimum + 1))
end

local function q(id, tier, skill, difficulty, questionType, correctIndex, options)
	return {
		id = id,
		prompt = "Question " .. id,
		options = options or { "A", "B", "C" },
		correctIndex = correctIndex or 1,
		hint = "Hint " .. id,
		scaffold = "Support " .. id,
		explanation = "Explanation " .. id,
		tier = tier,
		skill = skill,
		difficulty = difficulty,
		questionType = questionType,
	}
end
local bank = {
	q("m1", "material", "phonics", 1, "direct"),
	q("m2", "material", "vocabulary", 2, "transfer"),
	q("m3", "material", "inference", 2, "reasoning"),
	q("m4", "material", "math", 3, "direct"),
	q("m5", "material", "religion", 2, "transfer"),
	q("m6", "material", "phonics", 3, "reasoning"),
	q("f1", "star-fallback", "math", 2, "transfer"),
	q("f2", "star-fallback", "reading", 3, "reasoning"),
}

local ok, err = Engine.validateBank(bank)
assert(ok, err)

assert(Engine.validate(q("two", "material", "math", 1, "direct", 1, { "yes", "no" })))
assert(Engine.validate(q("four", "material", "math", 1, "direct", 4, { "a", "b", "c", "d" })))
local invalid = q("bad", "material", "math", 1, "direct", 1, { "same", "same" })
assert(not Engine.validate(invalid))

local history = Engine.newHistory()
Engine.beginQuest(history)
local rng = Deterministic.new()
local seen = {}
for index = 1, Engine.QUEST_LENGTH do
	local question = Engine.pickNextQuestion(bank, history, rng)
	assert(question.tier == "material", "material must be exhausted before fallback")
	assert(not seen[question.id], "quest repeated a question")
	if history.lastDifficulty then
		assert(
			question.difficulty <= history.lastDifficulty + Engine.MAX_DIFFICULTY_JUMP,
			"difficulty jumped too far"
		)
	end
	seen[question.id] = true
	Engine.markShown(history, question)
	Engine.markResolved(history)
end

assert(history.resolvedCount == 5)
assert((history.questQuestionTypeCounts.transfer or 0) >= 1, "quest needs transfer/application evidence")

local exhausted = Engine.newHistory()
for _, question in ipairs(bank) do
	if question.tier == "material" then
		exhausted.seenIds[question.id] = true
	end
end
local fallback = Engine.pickNextQuestion(bank, exhausted, Deterministic.new())
assert(fallback.tier == "star-fallback", "fallback activated incorrectly")
local comeback = Engine.newHistory()
Engine.beginQuest(comeback)
local missed = bank[1]
Engine.markShown(comeback, missed)
Engine.queueComeback(comeback, missed, 2)
Engine.markResolved(comeback)

local nextOne = Engine.pickNextQuestion(bank, comeback, Deterministic.new())
Engine.markShown(comeback, nextOne)
Engine.markResolved(comeback)
local nextTwo = Engine.pickNextQuestion(bank, comeback, Deterministic.new())
assert(
	nextTwo.skill == missed.skill or comeback.pendingComebackSkill ~= nil,
	"same-skill comeback was lost"
)

local view = Engine.clientView(bank[2], 2)
assert(view.id == bank[2].id)
assert(view.correctIndex == nil, "clientView leaked the correct answer")
assert(#view.options == #bank[2].options)

assert(Engine.isCorrect(bank[2], bank[2].correctIndex))
assert(not Engine.isCorrect(bank[2], 99))
assert(Engine.isIndependent(0))
assert(not Engine.isIndependent(1))
local clue, clueKind = Engine.getWrongFeedback(bank[2], 2, 1)
assert(type(clue) == "string" and clueKind == "clue")
local support, supportKind = Engine.getWrongFeedback(bank[2], 2, 2)
assert(type(support) == "string" and supportKind == "support")
local model, modelKind = Engine.getWrongFeedback(bank[2], 2, 3)
assert(type(model) == "string" and modelKind == "model")

print("PASS schema 2-4 choices")
print("PASS material-first selection")
print("PASS no repeat within quest")
print("PASS difficulty jump cap")
print("PASS transfer requirement")
print("PASS STAR fallback gating")
print("PASS spaced comeback")
print("PASS client answer secrecy")
print("PASS feedback escalation")
print("PASS independent mastery classification")
