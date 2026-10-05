local function read(path)
    local file = assert(io.open(path, "rb"))
    local value = assert(file:read("*a"))
    file:close()
    return value
end

local runtime = read("school/src/server/EconomyRuntime.lua")
local housing = read("school/src/server/HousingService.server.lua")

assert(runtime:find("local openings = {}", 1, true), "economy runtime must track in-flight opens")
assert(runtime:find("inFlight.event.Event:Wait()", 1, true), "concurrent opens must join the first read")
assert(runtime:find("openings[playerId] = inFlight", 1, true), "first open must register before yielding")
assert(runtime:find("inFlight.event:Fire()", 1, true), "waiting systems must be released after open")
assert(runtime:find("inFlight.released = true", 1, true), "player removal must cancel an opening cache")
assert(
    housing:find("plot.houseOrigin.Y + placement.y + 0.4", 1, true),
    "furniture must rest on the house floor surface"
)

print("ECONOMY_RUNTIME_CONTRACT_PASS")
