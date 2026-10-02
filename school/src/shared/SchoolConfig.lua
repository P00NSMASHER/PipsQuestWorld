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


-- Stable Foundation-owned world seam for vehicle producers.
-- X/Z follow the canonical location registry; Y is the TownMainStreet top surface
-- (CampusBuilder center Y 0.45 + half of its 0.4-stud thickness = 0.65).
local autoShopPosition = SchoolConfig.WorldLocations.AutoShop.position
local townCenterPosition = SchoolConfig.WorldLocations.TownCenter.position
local townMainStreetSurfaceY = 0.65

SchoolConfig.WorldSpawnSeams = {
    AutoShopRoad = {
        position = Vector3.new(autoShopPosition.X, townMainStreetSurfaceY, townCenterPosition.Z),
        headingDegrees = 90,
        anchorLocation = "AutoShop",
        roadPart = "TownMainStreet",
    },
}

-- Foundation owns residential plot placement only. Free Roam consumes these
-- stable seams for claim/teleport/edit behavior without inventing coordinates.
local neighborhoodPosition = SchoolConfig.WorldLocations.Neighborhood.position
local housingPlotXs = { -180, -120, -60, 60, 120, 180 }

SchoolConfig.HousingPlots = {}
for index, x in ipairs(housingPlotXs) do
    local plotId = string.format("plot-%02d", index)
    local houseZ = neighborhoodPosition.Z + 34
    SchoolConfig.HousingPlots[index] = {
        id = plotId,
        displayName = "House " .. tostring(index),
        lotCenter = Vector3.new(x, 0.65, houseZ),
        houseOrigin = Vector3.new(x, 0.65, houseZ),
        doorPosition = Vector3.new(x, 3, houseZ - 18),
        teleportPosition = Vector3.new(x, 3, houseZ - 24),
        drivewayPosition = Vector3.new(x, 0.76, neighborhoodPosition.Z + 17),
        headingDegrees = 180,
        roadPart = "NeighborhoodRoad",
        anchorLocation = "Neighborhood",
    }
end

return SchoolConfig
