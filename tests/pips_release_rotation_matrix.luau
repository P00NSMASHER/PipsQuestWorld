local Engine = require('../game/src/serverStorage/PipsEducationEngine')
local Bank = require('../game/src/serverStorage/PipsReleaseQuestionBank')

local CyclingRng = {}
CyclingRng.__index = CyclingRng

function CyclingRng.new(offset, step)
	return setmetatable({
		n = offset or 0,
		step = step or 1,
	}, CyclingRng)
end

function CyclingRng:NextInteger(minimum, maximum)
	local width = maximum - minimum + 1
	local value = minimum + (self.n % width)
	self.n += self.step
	return value
end

local ok, err = Engine.validateBank(Bank)
assert(ok, err)
assert(#Bank == 12, 'release bank size drift')

local scenarios = 0
for offset = 0, 11 do
	for step = 1, 4 do
		scenarios += 1
		local history = Engine.newHistory()
		Engine.beginQuest(history)
		local rng = CyclingRng.new(offset, step)
		local ids = {}
		local skills = {}
		local previousSkill = nil
		local transferOrReasoning = 0
		local lastDifficulty = nil

		for slot = 1, Engine.QUEST_LENGTH do
			local question = Engine.pickNextQuestion(Bank, history, rng)
			assert(not ids[question.id], 'rotation matrix repeated a question')
			ids[question.id] = true
			skills[question.skill] = true

			if previousSkill ~= nil then
				assert(
					question.skill ~= previousSkill,
					'rotation matrix repeated the same skill back-to-back'
				)
			end

			local difficulty = tonumber(question.difficulty) or 2
			if lastDifficulty ~= nil then
				assert(
					difficulty <= lastDifficulty + Engine.MAX_DIFFICULTY_JUMP,
					'rotation matrix exceeded the difficulty jump cap'
				)
			end

			if question.questionType == 'transfer' or question.questionType == 'reasoning' then
				transferOrReasoning += 1
			end

			Engine.markShown(history, question)
			Engine.markResolved(history)
			previousSkill = question.skill
			lastDifficulty = difficulty
		end

		local skillCount = 0
		for _ in pairs(skills) do
			skillCount += 1
		end

		assert(skillCount >= 4, 'five-question quest produced fewer than four skills')
		assert(transferOrReasoning >= 2, 'five-question quest needs at least two application/reasoning items')
	end
end

print('PIPS_RELEASE_ROTATION_MATRIX_PASS', scenarios)
