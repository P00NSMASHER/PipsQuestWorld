local archive = require('../game/src/common/PipsQuestionBank')
local bank = {}
for _, question in ipairs(archive) do
	if question.photoDerived == true then
		table.insert(bank, question)
	end
end

assert(#bank == 12, 'first release pool must remain the 12 reviewed schoolwork-derived items')

local ids = {}
local prompts = {}
local skills = {}
local subjects = {}
local types = { direct = 0, transfer = 0, reasoning = 0 }

for _, question in ipairs(bank) do
	assert(question.photoDerived == true)
	assert(question.tier == 'material')
	assert(type(question.id) == 'string' and question.id ~= '')
	assert(not ids[question.id], 'duplicate id: ' .. question.id)
	ids[question.id] = true

	local promptKey = string.lower(question.prompt:gsub('%s+', ' '))
	assert(not prompts[promptKey], 'duplicate prompt: ' .. question.prompt)
	prompts[promptKey] = true

	assert(type(question.options) == 'table' and #question.options >= 2 and #question.options <= 4)
	assert(type(question.correctIndex) == 'number')
	assert(question.correctIndex >= 1 and question.correctIndex <= #question.options)
	assert(types[question.questionType] ~= nil, 'missing/invalid questionType: ' .. question.id)
	types[question.questionType] += 1

	local lower = string.lower(question.prompt)
	assert(not string.find(lower, 'which spelling correctly shows the word', 1, true), 'trivial spelling stem')
	skills[question.skill] = true
	subjects[question.subject] = (subjects[question.subject] or 0) + 1
end

local skillCount = 0
for _ in pairs(skills) do skillCount += 1 end
assert(skillCount >= 8, 'release pool must preserve skill variety')
assert(subjects['Reading / ELA'] == 9)
assert(subjects.Religion == 3)
assert(types.direct == 5)
assert(types.transfer == 4)
assert(types.reasoning == 3)
assert(types.transfer + types.reasoning >= 7, 'majority should require application/reasoning')

print('PIPS_RELEASE_CONTENT_PASS', #bank, skillCount, types.direct, types.transfer, types.reasoning)
