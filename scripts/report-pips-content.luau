local bank = require('../game/src/common/PipsQuestionBank')

local issues = {}
local ids = {}
local prompts = {}
local counts = {
	total = 0,
	material = 0,
	fallback = 0,
	photoDerived = 0,
	transfer = 0,
	reasoning = 0,
	direct = 0,
}
local bySubject = {}
local bySkill = {}

local function issue(question, code, detail)
	table.insert(issues, {
		id = question and question.id or 'BANK',
		code = code,
		detail = detail,
	})
end

local function normalize(text)
	return string.lower((text or ''):gsub('%s+', ' '):match('^%s*(.-)%s*$'))
end
for index, question in ipairs(bank) do
	counts.total += 1
	if question.tier == 'material' then counts.material += 1 end
	if question.tier == 'star-fallback' then counts.fallback += 1 end
	if question.photoDerived then counts.photoDerived += 1 end
	if question.questionType == 'transfer' then counts.transfer += 1 end
	if question.questionType == 'reasoning' then counts.reasoning += 1 end
	if question.questionType == 'direct' then counts.direct += 1 end

	bySubject[question.subject or 'UNKNOWN'] = (bySubject[question.subject or 'UNKNOWN'] or 0) + 1
	local skill = question.skill or 'UNKNOWN'
	local skillRow = bySkill[skill] or { total = 0, direct = 0, transfer = 0, reasoning = 0 }
	skillRow.total += 1
	if question.questionType then
		skillRow[question.questionType] = (skillRow[question.questionType] or 0) + 1
	end
	bySkill[skill] = skillRow

	if type(question.id) ~= 'string' or question.id == '' then
		issue(question, 'missing-id', 'question ' .. index)
	elseif ids[question.id] then
		issue(question, 'duplicate-id', question.id)
	else
		ids[question.id] = true
	end
	local prompt = question.prompt or ''
	local promptKey = normalize(prompt)
	if promptKey == '' then
		issue(question, 'empty-prompt', '')
	elseif prompts[promptKey] then
		issue(question, 'duplicate-prompt', prompts[promptKey])
	else
		prompts[promptKey] = question.id
	end

	if #prompt > 240 then
		issue(question, 'long-prompt', tostring(#prompt) .. ' chars')
	end

	local options = question.options
	if type(options) ~= 'table' or #options < 2 or #options > 4 then
		issue(question, 'bad-option-count', tostring(type(options) == 'table' and #options or -1))
	else
		local seen = {}
		for _, option in ipairs(options) do
			if type(option) ~= 'string' or option:match('%S') == nil then
				issue(question, 'empty-option', '')
			elseif #option > 120 then
				issue(question, 'long-option', tostring(#option) .. ' chars')
			end
			if seen[option] then issue(question, 'duplicate-option', option) end
			seen[option] = true
		end
	end
	if type(question.correctIndex) ~= 'number'
		or question.correctIndex % 1 ~= 0
		or not options
		or question.correctIndex < 1
		or question.correctIndex > #options then
		issue(question, 'bad-correct-index', tostring(question.correctIndex))
	end

	if question.questionType ~= 'direct'
		and question.questionType ~= 'transfer'
		and question.questionType ~= 'reasoning' then
		issue(question, 'bad-question-type', tostring(question.questionType))
	end

	local lowerPrompt = string.lower(prompt)
	for _, forbidden in ipairs({
		'teacher page',
		'study list',
		'being practiced this week',
		'which spelling correctly shows the word',
	}) do
		if string.find(lowerPrompt, forbidden, 1, true) then
			issue(question, 'forbidden-meta-or-trivial-stem', forbidden)
		end
	end

	local correct = options and options[question.correctIndex]
	if question.signalId == 'spelling-short-vowel'
		and question.questionType == 'direct'
		and type(correct) == 'string'
		and #correct >= 3
		and string.find(lowerPrompt, string.lower(correct), 1, true) then
		issue(question, 'answer-in-prompt', correct)
	end
end
for skill, row in pairs(bySkill) do
	if row.total >= 3 and (row.transfer or 0) + (row.reasoning or 0) == 0 then
		issue({ id = 'SKILL:' .. skill }, 'rote-only-skill', tostring(row.total) .. ' items')
	end
end

table.sort(issues, function(a, b)
	if a.code == b.code then return a.id < b.id end
	return a.code < b.code
end)

print('CONTENT_TOTAL', counts.total)
print('CONTENT_MATERIAL', counts.material)
print('CONTENT_FALLBACK', counts.fallback)
print('CONTENT_PHOTO_DERIVED', counts.photoDerived)
print('CONTENT_DIRECT', counts.direct)
print('CONTENT_TRANSFER', counts.transfer)
print('CONTENT_REASONING', counts.reasoning)
print('SUBJECTS')
for subject, count in pairs(bySubject) do
	print(subject, count)
end
print('ISSUES', #issues)
for _, row in ipairs(issues) do
	print('ISSUE', row.code, row.id, row.detail)
end
