local Repository = assert(loadfile("school/src/server/EconomyRepository.lua"))()

local function clone(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, child in pairs(value) do copy[key] = clone(child) end
    return copy
end

local function newStore()
    return {
        snapshot = nil,
        version = 0,
        read = function(self, _playerId)
            return self.snapshot and clone(self.snapshot) or nil, self.version, nil
        end,
        compareAndSwap = function(self, _playerId, expectedVersion, snapshot)
            if self.version ~= expectedVersion then return false, nil, "conflict" end
            self.snapshot = clone(snapshot)
            self.version = snapshot.revision
            return true, self.version, nil
        end,
    }
end

local function operation(id, delta)
    return {
        operationId = id,
        playerId = 101,
        delta = delta,
        reason = "qa:operation-order",
    }
end

local store = newStore()
local repo = assert(Repository.open(store, 101))
assert(repo:record(operation("z:funding", 100)).durable == true)
assert(repo:record(operation("a:purchase", -40)).durable == true)

local reopened, err = Repository.open(store, 101)
assert(reopened, "durable economy history must reopen regardless of operationId lexical order: " .. tostring(err))
assert(reopened:getState().balance == 60)

print("HIGH_SCHOOL_QA_ECONOMY_ORDER_PERSISTENCE_PASS")
