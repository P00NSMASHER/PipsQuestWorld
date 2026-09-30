-- Curated Grade-2 release pool for brief Maze World checkpoints.
-- Source questions remain in PipsQuestionBank as certified/archive evidence.
-- Only explicitly approved ABVM-derived material is eligible here; STAR stays fallback.

local archive = require(script.Parent.PipsQuestionBank)

local approvedIds = {
	"abvm-b9d55008a7c4-629ea7-photo-vocabulary-definition-direct-ev1",
	"abvm-b9d55008a7c4-629ea7-photo-short-vowel-identification-transfer-ev1",
	"abvm-b9d55008a7c4-629ea7-photo-plural-s-es-reasoning-ev1",
	"abvm-b9d55008a7c4-629ea7-photo-reading-genre-direct-ev1",
	"abvm-b9d55008a7c4-629ea7-photo-religion-trinity-direct-ev1",
	"abvm-b9d55008a7c4-629ea7-photo-cvc-missing-vowel-direct-ev1",
	"abvm-b9d55008a7c4-629ea7-photo-spelling-short-vowel-transfer-ev2",
}

local byId = {}
for _, question in ipairs(archive) do
	byId[question.id] = question
end

local release = {}
for _, id in ipairs(approvedIds) do
	local question = byId[id]
	assert(question, "Missing approved release question: " .. id)
	assert(
		question.photoDerived == true and question.tier == "material",
		"Release question lost ABVM material provenance: " .. id
	)
	table.insert(release, question)
end

return release
