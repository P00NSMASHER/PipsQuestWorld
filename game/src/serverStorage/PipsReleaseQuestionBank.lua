-- Curated Grade-2 release pool for brief Maze World checkpoints.
-- The certified archive remains unchanged; weak release candidates are replaced
-- here with original skill-equivalent items derived from the same sanitized evidence.

local archive
if script and script.Parent then
	archive = require(script.Parent.PipsQuestionBank)
else
	archive = require('./PipsQuestionBank')
end

local byId = {}
for _, question in ipairs(archive) do
	byId[question.id] = question
end

local function archiveQuestion(id)
	local question = byId[id]
	assert(question, "Missing approved release question: " .. id)
	assert(
		question.photoDerived == true and question.tier == "material",
		"Release question lost ABVM material provenance: " .. id
	)
	return question
end

local pluralTransfer = {
	id = "pips-grade2-plural-boxes-transfer-v2",
	stationId = "spelling-forge-fog-v1",
	subject = "Reading / ELA",
	skill = "plural-nouns",
	prompt = "Which sentence uses the correct plural of “box”?",
	explanation = "Words ending in x usually add -es, so box becomes boxes.",
	provenance = "curated-equivalent-from-sanitized-schoolwork-skill",
	sourceFact = "Sanitized schoolwork-photo skill evidence: plural-nouns; batch schoolwork-2026-09-26-001",
	tier = "material",
	domain = "Word knowledge and skills",
	difficulty = 2,
	standards = { "CCSS.L.2.1.b" },
	dok = 2,
	cognitiveDemand = "skill-and-concept-application",
	hint = "Look at the end of the noun. Words ending in x usually need two letters added.",
	scaffold = "Start with the noun, then add -es to show more than one.",
	choiceDiagnostics = {
		{
			choice = "Two boxs are by the door.",
			misconception = "plural-ending-confusion",
			feedback = "A noun ending in x usually adds -es, not only -s.",
		},
		{
			choice = "Two box's are by the door.",
			misconception = "apostrophe-for-plural",
			feedback = "An apostrophe does not make this regular noun plural.",
		},
	},
	responseType = "multiple-choice",
	signalId = "plural-s-es",
	questionType = "transfer",
	coverageWeight = 4,
	photoDerived = true,
	options = {
		"Two boxes are by the door.",
		"Two boxs are by the door.",
		"Two box's are by the door.",
	},
	correctIndex = 1,
}

local trinityTransfer = {
	id = "pips-grade2-trinity-meaning-transfer-v2",
	stationId = "culture-lab-culture-v1",
	subject = "Religion",
	skill = "religion-application",
	prompt = "Nora says, “The Father is God, the Son is God, and the Holy Spirit is God, but there is only one God.” What is she describing?",
	explanation = "She is describing one God in three Persons: Father, Son, and Holy Spirit.",
	provenance = "curated-equivalent-from-sanitized-schoolwork-skill",
	sourceFact = "Sanitized schoolwork-photo skill evidence: religion-application; batch schoolwork-2026-09-26-001",
	tier = "material",
	domain = "Religion: current lesson application",
	difficulty = 2,
	standards = { "ABVM.RELIGION.CURRENT" },
	dok = 2,
	cognitiveDemand = "skill-and-concept-application",
	hint = "Look for the belief about one God and three divine Persons.",
	scaffold = "Notice that the sentence says one God while naming the Father, Son, and Holy Spirit.",
	choiceDiagnostics = {
		{
			choice = "three separate gods",
			misconception = "trinity-many-gods",
			feedback = "The sentence says there is only one God.",
		},
		{
			choice = "one person using three different names",
			misconception = "trinity-one-person-roles",
			feedback = "The lesson distinguishes three Persons, not one person switching names.",
		},
	},
	responseType = "multiple-choice",
	signalId = "religion-trinity",
	questionType = "transfer",
	coverageWeight = 4,
	photoDerived = true,
	options = {
		"the Trinity",
		"three separate gods",
		"one person using three different names",
	},
	correctIndex = 1,
}

local cvcTransfer = {
	id = "pips-grade2-cvc-pattern-transfer-v2",
	stationId = "spelling-forge-fog-v1",
	subject = "Reading / ELA",
	skill = "cvc-structure",
	prompt = "Which word has the same consonant-vowel-consonant pattern as “sun”?",
	explanation = "“Sun” and “map” each have one consonant, one vowel, then one consonant.",
	provenance = "curated-equivalent-from-sanitized-schoolwork-skill",
	sourceFact = "Sanitized schoolwork-photo skill evidence: cvc-structure; batch schoolwork-2026-09-26-001",
	tier = "material",
	domain = "Word knowledge and skills",
	difficulty = 2,
	standards = { "CCSS.RF.2.3" },
	dok = 2,
	cognitiveDemand = "skill-and-concept-application",
	hint = "Break “sun” into three letters and compare the pattern in each choice.",
	scaffold = "Look for one consonant, then one vowel, then one consonant.",
	choiceDiagnostics = {
		{
			choice = "moon",
			misconception = "double-vowel-pattern-confusion",
			feedback = "“Moon” has two vowel letters together in the middle.",
		},
		{
			choice = "star",
			misconception = "consonant-cluster-pattern-confusion",
			feedback = "“Star” begins with two consonants, so it does not match the C-V-C pattern.",
		},
	},
	responseType = "multiple-choice",
	signalId = "cvc-pattern",
	questionType = "transfer",
	coverageWeight = 5,
	photoDerived = true,
	options = {
		"map",
		"moon",
		"star",
	},
	correctIndex = 1,
}

return {
	archiveQuestion("abvm-b9d55008a7c4-629ea7-photo-vocabulary-definition-direct-ev1"),
	archiveQuestion("abvm-b9d55008a7c4-629ea7-photo-short-vowel-identification-transfer-ev1"),
	pluralTransfer,
	archiveQuestion("abvm-b9d55008a7c4-629ea7-photo-reading-genre-direct-ev1"),
	trinityTransfer,
	cvcTransfer,
	archiveQuestion("abvm-b9d55008a7c4-629ea7-photo-spelling-short-vowel-transfer-ev2"),
}
