local Config = {}

Config.GameName = "School Life World"
Config.ProfileStoreName = "SchoolLifeProfile_v1"

Config.DefaultProfile = {
	Credits = 150,
	XP = 0,
	ClassCompletions = 0,
	JobDeliveries = 0,
	StylePreset = 1,
}

-- Real seconds are intentionally short enough that a complete school day can
-- be tested in one normal play session. Clock values are minutes after midnight.
Config.DayPhases = {
	{ id = "before", name = "Before School", kind = "free", duration = 45, clockStart = 450, clockEnd = 480 },
	{ id = "math", name = "Math", kind = "class", classId = "Math", duration = 75, clockStart = 480, clockEnd = 540, rewardCredits = 30, rewardXP = 10 },
	{ id = "pass1", name = "Passing Time", kind = "free", duration = 15, clockStart = 540, clockEnd = 550 },
	{ id = "science", name = "Science", kind = "class", classId = "Science", duration = 75, clockStart = 550, clockEnd = 610, rewardCredits = 30, rewardXP = 10 },
	{ id = "lunch", name = "Lunch", kind = "free", duration = 50, clockStart = 610, clockEnd = 650 },
	{ id = "pass2", name = "Passing Time", kind = "free", duration = 15, clockStart = 650, clockEnd = 660 },
	{ id = "pe", name = "P.E.", kind = "class", classId = "PE", duration = 75, clockStart = 660, clockEnd = 720, rewardCredits = 30, rewardXP = 10 },
	{ id = "pass3", name = "Passing Time", kind = "free", duration = 15, clockStart = 720, clockEnd = 730 },
	{ id = "art", name = "Art", kind = "class", classId = "Art", duration = 75, clockStart = 730, clockEnd = 790, rewardCredits = 30, rewardXP = 10 },
	{ id = "after", name = "After School", kind = "free", duration = 120, clockStart = 790, clockEnd = 960 },
}

Config.ClassRooms = {
	Math = { displayName = "Math", position = Vector3.new(-56, 3, -30), accent = Color3.fromRGB(88, 142, 255) },
	Science = { displayName = "Science", position = Vector3.new(56, 3, -30), accent = Color3.fromRGB(78, 190, 120) },
	PE = { displayName = "P.E.", position = Vector3.new(56, 3, 34), accent = Color3.fromRGB(245, 145, 66) },
	Art = { displayName = "Art", position = Vector3.new(-56, 3, 34), accent = Color3.fromRGB(207, 110, 228) },
}

Config.StylePresets = {
	{
		name = "Sky",
		head = "Light orange",
		torso = "Pastel Blue",
		arms = "Light orange",
		legs = "Institutional white",
	},
	{
		name = "Crimson",
		head = "Nougat",
		torso = "Crimson",
		arms = "Nougat",
		legs = "Really black",
	},
	{
		name = "Mint",
		head = "Light orange",
		torso = "Mint",
		arms = "Light orange",
		legs = "Dark stone grey",
	},
	{
		name = "Violet",
		head = "Nougat",
		torso = "Royal purple",
		arms = "Nougat",
		legs = "Institutional white",
	},
}

Config.Vehicle = {
	Speed = 58,
	TurnRate = 1.9,
}

Config.Job = {
	DeliveryReward = 25,
	DeliveriesPerShift = 3,
}

return Config
