local SchoolConfig = {}

SchoolConfig.BELL_SECONDS = 150
SchoolConfig.TRAVEL_GRACE_SECONDS = 20

SchoolConfig.Periods = {
    { id = "homeroom", label = "Homeroom", subject = "Life Skills", room = "Homeroom", canQuestion = true },
    { id = "math", label = "Math", subject = "Math", room = "Math", canQuestion = true },
    { id = "ela", label = "English / Reading", subject = "ELA", room = "ELA", canQuestion = true },
    { id = "science", label = "Science", subject = "Science", room = "Science", canQuestion = true },
    { id = "lunch", label = "Lunch", subject = "Lunch", room = "Cafeteria", canQuestion = false },
    { id = "social", label = "Social Studies", subject = "Social Studies", room = "SocialStudies", canQuestion = true },
    { id = "pe", label = "Physical Education", subject = "Health", room = "Gym", canQuestion = true },
    { id = "free", label = "Free Time", subject = "Free Time", room = "Courtyard", canQuestion = false },
}

SchoolConfig.Rooms = {
    Homeroom = { position = Vector3.new(-58, 4, -55), displayName = "Homeroom" },
    Math = { position = Vector3.new(-58, 4, -5), displayName = "Math" },
    ELA = { position = Vector3.new(-58, 4, 48), displayName = "English / Reading" },
    Science = { position = Vector3.new(58, 4, -55), displayName = "Science" },
    SocialStudies = { position = Vector3.new(58, 4, -5), displayName = "Social Studies" },
    Library = { position = Vector3.new(58, 4, 48), displayName = "Library" },
    Cafeteria = { position = Vector3.new(-48, 4, 102), displayName = "Cafeteria" },
    Gym = { position = Vector3.new(48, 4, -108), displayName = "Gym" },
    Courtyard = { position = Vector3.new(48, 3, 102), displayName = "Courtyard" },
}

SchoolConfig.Rewards = {
    attendance = 5,
    correct = 10,
    completedAfterRetries = 3,
}

return SchoolConfig
