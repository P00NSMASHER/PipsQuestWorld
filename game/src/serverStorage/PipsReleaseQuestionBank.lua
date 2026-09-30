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

local mainCharacterTransfer = {
	id = "pips-grade2-main-character-focus-transfer-v2",
	stationId = "word-portal-put-v1",
	subject = "Reading / ELA",
	skill = "story-elements",
	prompt = "Maya plants seeds and checks them every morning. Leo carries the watering can. Which description identifies the main character?",
	explanation = "The main character is the person whose actions and experiences receive the most attention.",
	provenance = "curated-equivalent-from-sanitized-schoolwork-skill",
	sourceFact = "Sanitized schoolwork-photo skill evidence: story-elements; batch schoolwork-2026-09-26-001",
	tier = "material",
	domain = "Analyzing literary text",
	difficulty = 2,
	standards = { "CCSS.RL.2.3" },
	dok = 2,
	cognitiveDemand = "skill-and-concept-application",
	hint = "Ask whose actions the passage follows most closely.",
	scaffold = "Compare how many important actions belong to each character.",
	choiceDiagnostics = {
		{
			choice = "the child who carries the watering can",
			misconception = "mentioned-character-vs-main-character",
			feedback = "Being mentioned does not automatically make a character the main character.",
		},
		{
			choice = "both children are followed equally",
			misconception = "equal-focus-confusion",
			feedback = "One character gets more important actions and repeated attention.",
		},
	},
	responseType = "multiple-choice",
	signalId = "reading-main-character",
	questionType = "transfer",
	coverageWeight = 4,
	photoDerived = true,
	options = {
		"the child who plants and checks the seeds",
		"the child who carries the watering can",
		"both children are followed equally",
	},
	correctIndex = 1,
}

local settingReasoning = {
	id = "pips-grade2-setting-evidence-reasoning-v2",
	stationId = "word-portal-put-v1",
	subject = "Reading / ELA",
	skill = "story-elements",
	prompt = "Snow taps the windows as Ava hangs her coat beside the classroom door before announcements. Which setting fits best?",
	explanation = "The details point to a classroom and to a snowy morning before the school day gets underway.",
	provenance = "curated-equivalent-from-sanitized-schoolwork-skill",
	sourceFact = "Sanitized schoolwork-photo skill evidence: story-elements; batch schoolwork-2026-09-26-001",
	tier = "material",
	domain = "Analyzing literary text",
	difficulty = 3,
	standards = { "CCSS.RL.2.3" },
	dok = 2,
	cognitiveDemand = "strategic-reasoning",
	hint = "Use both place clues and time clues.",
	scaffold = "The classroom door tells the place; the announcements and coat help with the time and weather.",
	choiceDiagnostics = {
		{
			choice = "outside on a snowy morning",
			misconception = "weather-for-place-confusion",
			feedback = "Snow gives weather, but the passage also gives a clear indoor place clue.",
		},
		{
			choice = "a classroom on a summer afternoon",
			misconception = "place-only-setting",
			feedback = "The place fits, but the weather and before-announcements clue do not.",
		},
	},
	responseType = "multiple-choice",
	signalId = "reading-setting",
	questionType = "reasoning",
	coverageWeight = 4,
	photoDerived = true,
	options = {
		"a classroom on a snowy morning",
		"outside on a snowy morning",
		"a classroom on a summer afternoon",
	},
	correctIndex = 1,
}

local motivationReasoning = {
	id = "pips-grade2-character-motivation-reasoning-v2",
	stationId = "word-portal-put-v1",
	subject = "Reading / ELA",
	skill = "inference",
	prompt = "Before the presentation, Jamal sees his group’s poster has fallen and tapes it back up without being asked. Why most likely?",
	explanation = "His action supports the inference that he wants the group prepared for the presentation.",
	provenance = "curated-equivalent-from-sanitized-schoolwork-skill",
	sourceFact = "Sanitized schoolwork-photo skill evidence: inference; batch schoolwork-2026-09-26-001",
	tier = "material",
	domain = "Comprehension strategies and constructing meaning",
	difficulty = 3,
	standards = { "CCSS.RL.2.1" },
	dok = 3,
	cognitiveDemand = "strategic-reasoning",
	hint = "Connect what Jamal notices, when he acts, and what his group is about to do.",
	scaffold = "Ask which reason is best supported by fixing the poster right before the presentation.",
	choiceDiagnostics = {
		{
			choice = "He wants to change the poster into his own project.",
			misconception = "unsupported-ownership-inference",
			feedback = "Nothing says Jamal is trying to take ownership of the poster.",
		},
		{
			choice = "He thinks the presentation is already finished.",
			misconception = "timeline-inference-error",
			feedback = "The passage says he fixes it before the presentation.",
		},
	},
	responseType = "multiple-choice",
	signalId = "reading-character-motivation",
	questionType = "reasoning",
	coverageWeight = 5,
	photoDerived = true,
	options = {
		"He wants to help the group be ready.",
		"He wants to change the poster into his own project.",
		"He thinks the presentation is already finished.",
	},
	correctIndex = 1,
}

local giftsServiceTransfer = {
	id = "pips-grade2-gifts-service-transfer-v2",
	stationId = "culture-lab-culture-v1",
	subject = "Religion",
	skill = "religion-application",
	prompt = "Lena is good at drawing. Which choice most clearly uses that talent as a gift in service to other people?",
	explanation = "A talent can be received gratefully and used in a way that helps or welcomes other people.",
	provenance = "curated-equivalent-from-sanitized-schoolwork-skill",
	sourceFact = "Sanitized schoolwork-photo skill evidence: religion-application; batch schoolwork-2026-09-26-001",
	tier = "material",
	domain = "Religion: current lesson application",
	difficulty = 3,
	standards = { "ABVM.RELIGION.CURRENT" },
	dok = 2,
	cognitiveDemand = "skill-and-concept-application",
	hint = "Look for the choice where the talent directly helps or welcomes someone else.",
	scaffold = "All three choices use drawing, but only one clearly turns the talent outward in service.",
	choiceDiagnostics = {
		{
			choice = "Practice drawing alone during free time.",
			misconception = "self-improvement-vs-service",
			feedback = "Practice can be good, but this question asks about using the talent in service to others.",
		},
		{
			choice = "Enter a favorite picture in the art show.",
			misconception = "achievement-vs-service",
			feedback = "Sharing work in a show can be positive, but it does not directly answer the service part of the question.",
		},
	},
	responseType = "multiple-choice",
	signalId = "religion-gifts",
	questionType = "transfer",
	coverageWeight = 4,
	photoDerived = true,
	options = {
		"Make welcome cards for new students.",
		"Practice drawing alone during free time.",
		"Enter a favorite picture in the art show.",
	},
	correctIndex = 1,
}

local welcomingLoveTransfer = {
	id = "pips-grade2-welcoming-love-transfer-v2",
	stationId = "culture-lab-culture-v1",
	subject = "Religion",
	skill = "religion-application",
	prompt = "A new student stands alone while a recess game is starting. Which choice gives the student the clearest chance to belong?",
	explanation = "Welcoming someone means taking an action that includes the person, not only noticing them.",
	provenance = "curated-equivalent-from-sanitized-schoolwork-skill",
	sourceFact = "Sanitized schoolwork-photo skill evidence: religion-application; batch schoolwork-2026-09-26-001",
	tier = "material",
	domain = "Religion: current lesson application",
	difficulty = 2,
	standards = { "ABVM.RELIGION.CURRENT" },
	dok = 2,
	cognitiveDemand = "skill-and-concept-application",
	hint = "Choose the action that moves from being friendly to actually including the student.",
	scaffold = "A smile or explanation can help, but look for the choice that offers participation.",
	choiceDiagnostics = {
		{
			choice = "Smile and wave, then keep playing with the same group.",
			misconception = "friendly-vs-inclusive",
			feedback = "That is friendly, but it does not give the student a way to join.",
		},
		{
			choice = "Explain the rules from across the playground.",
			misconception = "information-vs-inclusion",
			feedback = "Explaining may help, but the student still has not been included in the game.",
		},
	},
	responseType = "multiple-choice",
	signalId = "religion-choice-love",
	questionType = "transfer",
	coverageWeight = 4,
	photoDerived = true,
	options = {
		"Invite the student to join the game.",
		"Smile and wave, then keep playing with the same group.",
		"Explain the rules from across the playground.",
	},
	correctIndex = 1,
}

return {
	archiveQuestion("abvm-b9d55008a7c4-629ea7-photo-vocabulary-definition-direct-ev1"),
	mainCharacterTransfer,
	archiveQuestion("abvm-b9d55008a7c4-629ea7-photo-short-vowel-identification-transfer-ev1"),
	trinityTransfer,
	pluralTransfer,
	motivationReasoning,
	archiveQuestion("abvm-b9d55008a7c4-629ea7-photo-reading-genre-direct-ev1"),
	settingReasoning,
	cvcTransfer,
	giftsServiceTransfer,
	archiveQuestion("abvm-b9d55008a7c4-629ea7-photo-spelling-short-vowel-transfer-ev2"),
	welcomingLoveTransfer,
}
