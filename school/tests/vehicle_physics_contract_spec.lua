local path = "school/src/server/VehicleService.server.lua"
local handle = assert(io.open(path, "r"))
local source = handle:read("*a")
handle:close()

local function contains(fragment, label)
    if not source:find(fragment, 1, true) then
        error("missing vehicle physics contract: " .. (label or fragment), 2)
    end
end

local function excludes(fragment, label)
    if source:find(fragment, 1, true) then
        error("forbidden vehicle movement contract: " .. (label or fragment), 2)
    end
end

contains('Instance.new("VectorForce")', "force actuator")
contains('Instance.new("AlignOrientation")', "orientation actuator")
contains("VehicleDynamics.step", "deterministic handling")
contains("SetNetworkOwner(nil)", "server network ownership")
contains("descendant.Anchored = false", "unanchored assembly")
contains("WeldConstraint", "welded assembly")
excludes("runtime.model:PivotTo", "heartbeat model teleport")
excludes("runtime.position +=", "scripted position integration")

print("HIGH_SCHOOL_VEHICLE_PHYSICS_CONTRACT_PASS")
