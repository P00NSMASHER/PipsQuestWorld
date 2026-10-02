local SchoolConfig = {}

SchoolConfig.PERIOD_SECONDS = 150
SchoolConfig.ATTENDANCE_RADIUS = 45
SchoolConfig.TRAVEL_OFFSET = Vector3.new(0, 3, 0)

SchoolConfig.Interfaces = {
    remoteFolder = "SchoolFoundation",
    stateSnapshot = "StateSnapshot",
    requestTravel = "RequestTravel",
    serverEventFolder = "SchoolFoundationEvents",
    sessionStarted = "SessionStarted",
    sessionEnded = "SessionEnded",
    periodChanged = "PeriodChanged",
    attendanceChanged = "AttendanceChanged",
}

SchoolConfig.Periods = {
    { id = "homeroom", label = "Homeroom", room = "Homeroom" },
    { id = "math", label = "Math", room = "Math" },
    { id = "ela", label = "English / Reading", room = "ELA" },
    { id = "science", label = "Science", room = "Science" },
    { id = "lunch", label = "Lunch", room = "Cafeteria" },
    { id = "social", label = "Social Studies", room = "SocialStudies" },
    { id = "pe", label = "Physical Education", room = "Gym" },
    { id = "free", label = "Free Time", room = "Courtyard" },
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

SchoolConfig.WorldLocations = {
    SchoolEntrance = { position = Vector3.new(0, 3, 142), displayName = "Pip High" },
    TownCenter = { position = Vector3.new(0, 3, 390), displayName = "Town Center" },
    Cafe = { position = Vector3.new(-165, 3, 360), displayName = "Corner Cafe" },
    StyleShop = { position = Vector3.new(-65, 3, 360), displayName = "Style Shop" },
    AutoShop = { position = Vector3.new(70, 3, 360), displayName = "Auto Shop" },
    Market = { position = Vector3.new(170, 3, 360), displayName = "Market" },
    Neighborhood = { position = Vector3.new(0, 3, 505), displayName = "Neighborhood" },
    TownPark = { position = Vector3.new(0, 3, 455), displayName = "Town Park" },
}

return SchoolConfig
