local function read(path)
    local handle = assert(io.open(path, "r"))
    local source = handle:read("*a")
    handle:close()
    return source
end

local controller = read("school/src/server/PEDodgeballController.lua")
local server = read("school/src/server/PEDodgeballDrill.server.lua")
local client = read("school/src/client/PEDodgeballDrill.client.lua")

local function contains(source, fragment, label)
    if not source:find(fragment, 1, true) then
        error("missing P.E. dodgeball contract: " .. (label or fragment), 2)
    end
end

local function excludes(source, fragment, label)
    if source:find(fragment, 1, true) then
        error("forbidden P.E. dodgeball contract: " .. (label or fragment), 2)
    end
end

contains(controller, "DEFAULT_DURATION = 15", "practical round duration")
contains(controller, "computeBallisticVelocity", "deterministic trajectory math")
contains(controller, "segmentHitsSphere", "deterministic swept hit check")
contains(controller, "start_rate_limited", "prompt rate authority")
contains(controller, "spawnedBallIds", "server spawn registry")
contains(controller, "hitBallIds", "idempotent server hits")
contains(controller, 'return "C", "Drill complete!', "encouraging minimum grade")

contains(server, "SchoolConfig.Rooms.Gym", "Foundation Gym seam")
contains(server, "isAtGym(player)", "gym proximity checks")
contains(server, 'Instance.new("ProximityPrompt")', "discoverable drill prompt")
contains(server, 'ball.Shape = Enum.PartType.Ball', "visible primitive foam balls")
contains(server, "ball.Anchored = false", "physical unanchored balls")
contains(server, "ball:SetNetworkOwner(nil)", "server network ownership")
contains(server, 'Instance.new("VectorForce")', "physical gravity assist")
contains(server, "ball.AssemblyLinearVelocity", "physical launch velocity")
contains(server, "RunService.Heartbeat", "server simulation loop")
contains(server, "PEDodgeballController.segmentHitsSphere", "server swept hit evaluation")
contains(server, "controller:recordHit", "server-only score authority")
contains(server, "Players.PlayerRemoving", "leave cleanup")
contains(server, "controller:clearPlayer", "session cleanup")
contains(server, "CanCollide = false", "movement-safe foam balls")
contains(server, 'getOrCreateRemoteFunction(drillRoot, "Leave")', "safe leave action")
excludes(server, "sign.AlwaysOnTop = true", "gym sign must respect world depth")
excludes(server, "OnServerEvent", "client-authored hit or score event")
excludes(server, "TakeDamage", "punitive damage")
excludes(server, "WalkSpeed", "movement lock")
excludes(server, "JumpPower", "movement lock")
excludes(server, "MarketplaceService", "monetization")

contains(client, 'Instance.new("UISizeConstraint")', "responsive HUD bounds")
contains(client, 'activePanel.Name = "ActiveDrillHud"', "movement HUD")
contains(client, 'resultCard.Name = "DodgeballResultCard"', "clear result card")
contains(client, "remainingSeconds", "public timer rendering")
contains(client, "state.hits", "public hit rendering")
contains(client, "result.grade", "grade result")
contains(client, "leaveRemote:InvokeServer", "safe server leave")
excludes(client, "recordHit", "client-authored hit")
excludes(client, "BallId", "private ball identity")
excludes(client, "sessionId", "private session identity")
excludes(client, "AssemblyLinearVelocity", "client-authored trajectory")
excludes(client, "MarketplaceService", "monetization")

print("HIGH_SCHOOL_PE_DODGEBALL_RUNTIME_CONTRACT_PASS")
