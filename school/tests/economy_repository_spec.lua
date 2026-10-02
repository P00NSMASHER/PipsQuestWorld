local Repository = assert(loadfile("school/src/server/EconomyRepository.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function clone(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, child in pairs(value) do copy[key] = clone(child) end
    return copy
end

local function newStore(initial)
    return {
        snapshot = initial and clone(initial) or nil,
        version = initial and initial.revision or 0,
        saves = 0,
        failSave = false,
        injectConflict = nil,
        read = function(self, _playerId)
            return self.snapshot and clone(self.snapshot) or nil, self.version, nil
        end,
        compareAndSwap = function(self, _playerId, expectedVersion, snapshot)
            if self.failSave then return false, nil, "injected" end
            if self.injectConflict then
                local hook = self.injectConflict
                self.injectConflict = nil
                hook(self)
            end
            if self.version ~= expectedVersion then return false, nil, "conflict" end
            self.snapshot = clone(snapshot)
            self.version = snapshot.revision
            self.saves = self.saves + 1
            return true, self.version, nil
        end,
    }
end

local function operation(id, delta, reason, unlock)
    return {
        operationId = id,
        playerId = 101,
        delta = delta,
        reason = reason,
        unlock = unlock,
    }
end

local store = newStore(nil)
local repo = assert(Repository.open(store, 101))
eq(repo:getState().balance, 0, "new balance")
eq(repo:getState().operationCount, 0, "new operation count")

local wage = operation("job:cafe:shift-1", 25, "job:cafe")
local first = repo:record(wage)
eq(first.status, "applied", "wage status")
eq(first.durable, true, "wage durable")
eq(first.state.balance, 25, "wage balance")

local duplicate = repo:record(wage)
eq(duplicate.status, "duplicate", "duplicate wage status")
eq(duplicate.state.balance, 25, "duplicate changed balance")
eq(store.saves, 1, "duplicate wrote again")

local conflict = repo:record(operation("job:cafe:shift-1", 30, "job:cafe"))
eq(conflict.status, "conflict", "operation id conflict status")
eq(conflict.error, "OPERATION_ID_CONFLICT", "operation id conflict error")
eq(store.saves, 1, "conflict wrote")

local purchase = operation(
    "purchase:vehicle:bike-1",
    -20,
    "purchase:vehicle",
    { category = "vehicle", itemId = "bike-1" }
)
local bought = repo:record(purchase)
eq(bought.status, "applied", "purchase status")
eq(bought.state.balance, 5, "purchase balance")
eq(#bought.state.ownership, 1, "purchase ownership count")
eq(bought.state.ownership[1].category, "vehicle", "purchase ownership category")
eq(bought.state.ownership[1].itemId, "bike-1", "purchase ownership item")

local duplicatePurchase = repo:record(purchase)
eq(duplicatePurchase.status, "duplicate", "duplicate purchase status")
eq(duplicatePurchase.state.balance, 5, "duplicate purchase charged again")

local repurchase = repo:record(operation(
    "purchase:vehicle:bike-1:again",
    -1,
    "purchase:vehicle",
    { category = "vehicle", itemId = "bike-1" }
))
eq(repurchase.status, "rejected", "repurchase status")
eq(repurchase.error, "ALREADY_OWNED", "repurchase error")
eq(repo:getState().balance, 5, "repurchase changed balance")

local tooExpensive = repo:record(operation("purchase:house:starter", -10, "purchase:house"))
eq(tooExpensive.status, "rejected", "insufficient funds status")
eq(tooExpensive.error, "INSUFFICIENT_FUNDS", "insufficient funds error")
eq(repo:getState().balance, 5, "insufficient funds changed balance")

local reopened = assert(Repository.open(store, 101))
eq(reopened:getState().balance, 5, "rejoin balance")
eq(reopened:getState().operationCount, 2, "rejoin operation count")
eq(#reopened:getState().ownership, 1, "rejoin ownership count")

store.injectConflict = function(s)
    s.snapshot = {
        schemaVersion = 1,
        revision = 3,
        balance = 10,
        operations = {
            operation("job:cafe:shift-1", 25, "job:cafe"),
            operation(
                "purchase:vehicle:bike-1",
                -20,
                "purchase:vehicle",
                { category = "vehicle", itemId = "bike-1" }
            ),
            operation("job:market:shift-1", 5, "job:market"),
        },
        ownership = {
            { category = "vehicle", itemId = "bike-1" },
        },
    }
    s.version = 3
end

local raced = reopened:record(operation("job:cafe:shift-2", 10, "job:cafe"))
eq(raced.status, "applied", "raced status")
eq(raced.durable, true, "raced durable")
eq(raced.revision, 4, "raced revision")
eq(raced.state.balance, 20, "raced lost concurrent money")
eq(raced.state.operationCount, 4, "raced lost concurrent operation")

local afterRace = assert(Repository.open(store, 101))
eq(afterRace:getState().balance, 20, "rejoin after race balance")
eq(afterRace:getState().operationCount, 4, "rejoin after race count")

store.failSave = true
local failed = afterRace:record(operation("job:cafe:shift-3", 10, "job:cafe"))
eq(failed.status, "rejected", "save failure status")
eq(failed.durable, false, "save failure durable")
eq(failed.error, "SAVE_FAILED:injected", "save failure error")
eq(afterRace:getState().balance, 20, "failed save mutated local balance")

print("HIGH_SCHOOL_ECONOMY_REPOSITORY_PASS")
