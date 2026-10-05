local Repository = assert(loadfile("school/src/server/EconomyRepository.lua"))()
local Catalog = assert(loadfile("school/src/server/StyleShopCatalog.lua"))()
local Controller = assert(loadfile("school/src/server/StyleShopController.lua"))()

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

local store = {
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

local seed = assert(Repository.open(store, 101))
local funded = seed:record({
    operationId = "qa:style-shop:funding",
    playerId = 101,
    delta = 100,
    reason = "qa:funding",
})
eq(funded.status, "applied", "funding status")

local function provider(playerId)
    return Repository.open(store, playerId)
end

local controller = Controller.new(Catalog, provider)
local initial = controller:getState(101)
eq(initial.accepted, true, "initial state rejected")
eq(initial.balance, 100, "initial balance")
eq(#initial.items, 9, "catalog count")
eq(next(initial.owned), nil, "new wardrobe not empty")

for index, item in ipairs(initial.items) do
    eq(item.originalContent, true, "item " .. index .. " original-content marker")
    eq(type(item.price), "number", "item " .. index .. " server price")
    eq(item.assetId, nil, "item " .. index .. " leaked asset id")
end

local bought = controller:purchase(101, "sunset-varsity", "request-001")
eq(bought.accepted, true, "valid purchase rejected")
eq(bought.code, "purchased", "purchase code")
eq(bought.balance, 80, "server price not charged")
eq(bought.owned["sunset-varsity"], true, "ownership missing")

local replay = controller:purchase(101, "sunset-varsity", "request-001")
eq(replay.accepted, true, "idempotent replay rejected")
eq(replay.code, "purchase_already_processed", "idempotent replay code")
eq(replay.balance, 80, "idempotent replay charged twice")

local conflict = controller:purchase(101, "ocean-hoodie", "request-001")
eq(conflict.accepted, false, "request conflict accepted")
eq(conflict.code, "request_id_conflict", "request conflict code")
eq(conflict.balance, 80, "request conflict changed balance")

local forged = controller:purchase(101, "studio-tee", "request-002", {
    price = 0,
    owned = true,
})
eq(forged.accepted, true, "purchase with ignored extra client claim rejected")
eq(forged.balance, 66, "client price claim changed authoritative price")

local alreadyOwned = controller:purchase(101, "studio-tee", "request-003")
eq(alreadyOwned.accepted, true, "owned item did not converge")
eq(alreadyOwned.code, "already_owned", "owned item code")
eq(alreadyOwned.balance, 66, "owned item charged twice")

local tooLong = controller:purchase(101, "ocean-hoodie", string.rep("a", 65))
eq(tooLong.accepted, false, "oversized request id accepted")
eq(tooLong.code, "invalid_request_id", "oversized request code")
eq(controller:getState(101).balance, 66, "invalid request changed balance")

local unsafe = controller:purchase(101, "ocean-hoodie", "request with spaces")
eq(unsafe.code, "invalid_request_id", "unsafe request id accepted")

local unknown = controller:purchase(101, "not-in-catalog", "request-004")
eq(unknown.code, "unknown_item", "unknown item accepted")

local equipOwned = controller:authorizeEquip(101, "sunset-varsity")
eq(equipOwned.accepted, true, "owned item equip rejected")
eq(equipOwned.item.slot, "top", "equip slot")
local equipLocked = controller:authorizeEquip(101, "ocean-hoodie")
eq(equipLocked.accepted, false, "unowned item equip accepted")
eq(equipLocked.code, "not_owned", "unowned equip code")

local reopened = Controller.new(Catalog, provider)
local persisted = reopened:getState(101)
eq(persisted.balance, 66, "rejoin balance")
eq(persisted.owned["sunset-varsity"], true, "rejoin first ownership")
eq(persisted.owned["studio-tee"], true, "rejoin second ownership")
eq(#persisted.items, 9, "rejoin catalog")

eq(Controller.MAX_REQUEST_ID_LENGTH, 64, "request id bound")
eq(Controller.OWNERSHIP_CATEGORY, "style", "ownership namespace")

print("HIGH_SCHOOL_STYLE_SHOP_CONTROLLER_PASS")
