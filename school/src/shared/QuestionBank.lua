-- Original starter questions for the clean-room School Life project.
-- Correct-answer metadata stays server-side because only the server requires this module.

return {
	Math = {
		{ id = "m1", prompt = "What is 8 + 7?", choices = { "13", "14", "15", "16" }, correct = 3, explanation = "8 + 7 = 15." },
		{ id = "m2", prompt = "Which number is even?", choices = { "11", "13", "16", "19" }, correct = 3, explanation = "16 is divisible by 2." },
		{ id = "m3", prompt = "What is 20 - 6?", choices = { "12", "13", "14", "15" }, correct = 3, explanation = "20 - 6 = 14." },
		{ id = "m4", prompt = "Which is the largest number?", choices = { "27", "72", "47", "67" }, correct = 2, explanation = "72 is greater than the other choices." },
	},
	Science = {
		{ id = "s1", prompt = "Which state of matter keeps its own shape?", choices = { "Solid", "Liquid", "Gas", "Steam" }, correct = 1, explanation = "A solid keeps its own shape." },
		{ id = "s2", prompt = "Plants use sunlight to help make...", choices = { "Food", "Plastic", "Metal", "Sand" }, correct = 1, explanation = "Plants use sunlight during photosynthesis to make food." },
		{ id = "s3", prompt = "Which object is attracted to a magnet?", choices = { "Wood spoon", "Iron nail", "Rubber ball", "Paper cup" }, correct = 2, explanation = "Iron is magnetic." },
		{ id = "s4", prompt = "Water freezes at which temperature on the Celsius scale?", choices = { "0°C", "10°C", "50°C", "100°C" }, correct = 1, explanation = "Fresh water freezes at about 0°C." },
	},
	PE = {
		{ id = "p1", prompt = "Before exercise, a good first step is to...", choices = { "Warm up", "Skip water", "Sit all day", "Hold your breath" }, correct = 1, explanation = "A warm-up prepares your body to move." },
		{ id = "p2", prompt = "Which activity mainly builds endurance?", choices = { "Jogging", "Sleeping", "Reading", "Drawing" }, correct = 1, explanation = "Jogging challenges your heart and lungs over time." },
		{ id = "p3", prompt = "When you feel pain during an activity, you should...", choices = { "Ignore it", "Stop and tell an adult", "Run faster", "Hide it" }, correct = 2, explanation = "Stopping and getting help is the safe choice." },
	},
	Art = {
		{ id = "a1", prompt = "Red and blue mixed together make...", choices = { "Green", "Purple", "Orange", "Brown" }, correct = 2, explanation = "Red plus blue makes purple." },
		{ id = "a2", prompt = "A repeated visual design is called a...", choices = { "Pattern", "Shadow", "Sound", "Sentence" }, correct = 1, explanation = "A pattern repeats visual elements." },
		{ id = "a3", prompt = "Which pair contains warm colors?", choices = { "Red and orange", "Blue and green", "Blue and violet", "Green and blue" }, correct = 1, explanation = "Red and orange are commonly grouped as warm colors." },
	},
}
