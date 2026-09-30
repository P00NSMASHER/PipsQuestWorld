local bank = require('../game/src/serverStorage/PipsReleaseQuestionBank')

local expected = {
	"abvm-b9d55008a7c4-629ea7-photo-vocabulary-definition-direct-ev1",
	"pips-grade2-main-character-focus-transfer-v2",
	"abvm-b9d55008a7c4-629ea7-photo-short-vowel-identification-transfer-ev1",
	"pips-grade2-trinity-meaning-transfer-v2",
	"pips-grade2-plural-boxes-transfer-v2",
	"pips-grade2-character-motivation-reasoning-v2",
	"abvm-b9d55008a7c4-629ea7-photo-reading-genre-direct-ev1",
	"pips-grade2-setting-evidence-reasoning-v2",
	"pips-grade2-cvc-pattern-transfer-v2",
	"pips-grade2-gifts-service-transfer-v2",
	"abvm-b9d55008a7c4-629ea7-photo-spelling-short-vowel-transfer-ev2",
	"pips-grade2-welcoming-love-transfer-v2",
}

local function clean(v)
	return string.lower((v or ''):gsub('%s+', ' '))
end

assert(#bank == 12, 'reviewed release count drift')

local ids = {}
local prompts = {}
local correctIndexCounts = { 0, 0, 0, 0 }
for i, q in ipairs(bank) do
	assert(q.id == expected[i], 'release id/order drift')
	assert(q.photoDerived == true and q.tier == 'material')
	assert(type(q.subject) == 'string' and type(q.skill) == 'string' and type(q.domain) == 'string')
	assert(type(q.prompt) == 'string' and #q.prompt <= 140)
	assert(type(q.hint) == 'string' and type(q.scaffold) == 'string')
	assert(type(q.explanation) == 'string')
	assert(type(q.difficulty) == 'number' and q.difficulty >= 1 and q.difficulty <= 3)
	assert(type(q.dok) == 'number' and q.dok >= 1 and q.dok <= 3)
	assert(q.questionType == 'direct' or q.questionType == 'transfer' or q.questionType == 'reasoning')
	assert(not ids[q.id]); ids[q.id] = true
	local stem = clean(q.prompt)
	assert(not prompts[stem]); prompts[stem] = true

	assert(type(q.options) == 'table' and #q.options >= 2 and #q.options <= 4)
	assert(type(q.correctIndex) == 'number' and q.correctIndex >= 1 and q.correctIndex <= #q.options)
	correctIndexCounts[q.correctIndex] += 1
	local seen = {}
	for _, option in ipairs(q.options) do
		assert(type(option) == 'string' and #option > 0 and #option <= 90)
		local key = clean(option)
		assert(not seen[key]); seen[key] = true
	end

	local answer = clean(q.options[q.correctIndex])
	if #answer >= 3 then
		assert(not string.find(clean(q.prompt), answer, 1, true), 'prompt reveals accepted choice')
		assert(not string.find(clean(q.hint), answer, 1, true), 'hint reveals accepted choice')
		assert(not string.find(clean(q.scaffold), answer, 1, true), 'scaffold reveals accepted choice')
	end

	local covered = {}
	for _, d in ipairs(q.choiceDiagnostics or {}) do covered[d.choice] = type(d.feedback) == 'string' end
	for oi, option in ipairs(q.options) do
		if oi ~= q.correctIndex then assert(covered[option], 'missing distractor feedback') end
	end
end

assert(correctIndexCounts[1] == 4, 'answer-position balance drift at choice 1')
assert(correctIndexCounts[2] == 4, 'answer-position balance drift at choice 2')
assert(correctIndexCounts[3] == 4, 'answer-position balance drift at choice 3')
assert(correctIndexCounts[4] == 0, 'unexpected fourth-choice answer in current three-choice release pool')

for first = 1, #bank - 4 do
	local skills, applied = {}, 0
	for i = first, first + 4 do
		skills[bank[i].skill] = true
		if bank[i].questionType ~= 'direct' then applied += 1 end
	end
	local n = 0; for _ in pairs(skills) do n += 1 end
	assert(n >= 4 and applied >= 2, 'five-question quality mix failed')
end

print('PIPS_RELEASE_CONTENT_PASS', #bank)
