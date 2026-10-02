local previousVector3 = _G.Vector3

_G.Vector3 = {
    new = function(x, y, z)
        return { X = x, Y = y, Z = z }
    end,
}

local SchoolConfig = assert(loadfile("school/src/shared/SchoolConfig.lua"))()
_G.Vector3 = previousVector3

local plots = assert(SchoolConfig.HousingPlots, "HousingPlots contract missing")
assert(#plots == 6, "expected exactly six housing plots")

local ids = {}
local coordinates = {}
for index, plot in ipairs(plots) do
    assert(type(plot.id) == "string" and plot.id ~= "", "plot id missing at " .. tostring(index))
    assert(not ids[plot.id], "duplicate plot id " .. plot.id)
    ids[plot.id] = true

    assert(plot.lotCenter and plot.houseOrigin and plot.doorPosition and plot.teleportPosition and plot.drivewayPosition,
        "plot anchors missing for " .. plot.id)
    assert(plot.headingDegrees == 180, "unexpected plot heading for " .. plot.id)
    assert(plot.roadPart == "NeighborhoodRoad", "plot road contract mismatch for " .. plot.id)
    assert(plot.anchorLocation == "Neighborhood", "plot location contract mismatch for " .. plot.id)

    local key = tostring(plot.houseOrigin.X) .. ":" .. tostring(plot.houseOrigin.Z)
    assert(not coordinates[key], "duplicate house origin " .. key)
    coordinates[key] = true

    assert(plot.teleportPosition.Z < plot.doorPosition.Z, "teleport anchor must remain road-side of door")
end

local neighborhood = assert(SchoolConfig.WorldLocations.Neighborhood, "Neighborhood location missing")
for _, plot in ipairs(plots) do
    assert(plot.houseOrigin.Z > neighborhood.position.Z, "house must remain north of NeighborhoodRoad")
end

local file = assert(io.open("school/src/server/CampusBuilder.server.lua", "r"))
local source = file:read("*a")
file:close()

assert(source:find("SchoolConfig.HousingPlots", 1, true), "CampusBuilder must consume HousingPlots")
assert(source:find('housingPlotsFolder.Name = "HousingPlots"', 1, true), "HousingPlots folder missing")
assert(source:find('makeAnchor("HouseOrigin"', 1, true), "HouseOrigin anchor missing")
assert(source:find('makeAnchor("DoorAnchor"', 1, true), "DoorAnchor missing")
assert(source:find('makeAnchor("TeleportAnchor"', 1, true), "TeleportAnchor missing")
assert(not source:find("ipairs({-180, -120, -60, 60, 120, 180})", 1, true),
    "hard-coded legacy decorative house loop still present")

print("HIGH_SCHOOL_HOUSING_PLOT_CONTRACT_PASS")
