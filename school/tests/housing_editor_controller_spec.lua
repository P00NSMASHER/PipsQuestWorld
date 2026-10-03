local Editor = assert(loadfile("school/src/server/HousingEditorController.lua"))()
local LayoutRepository = assert(loadfile("school/src/server/HousingLayoutRepository.lua"))()

local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[clone(key)] = clone(child) end
    return result
end

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function memoryAdapter()
    local row = nil
    return {
        read = function()
            if row == nil then return nil, 0, nil end
            return clone(row.snapshot), row.version, nil
        end,
        compareAndSwap = function(_, _playerId, expectedVersion, snapshot)
            local currentVersion = row and row.version or 0
            if currentVersion ~= expectedVersion then return false, nil, "conflict" end
            row = { version = snapshot.revision, snapshot = clone(snapshot) }
            return true, row.version, nil
        end,
    }
end

local layoutAdapters = {}
local layoutRepos = {}
local function layoutFactory(playerId)
    if not layoutAdapters[playerId] then layoutAdapters[playerId] = memoryAdapter() end
    if not layoutRepos[playerId] then
        layoutRepos[playerId] = assert(LayoutRepository.open(layoutAdapters[playerId], playerId))
    else
        assert(layoutRepos[playerId]:reload())
    end
    return layoutRepos[playerId]
end

local economyState = {}
local function economyFactory(playerId)
    economyState[playerId] = economyState[playerId] or { balance = 100, operations = {} }
    local state = economyState[playerId]
    return {
        getState = function()
            return { balance = state.balance }
        end,
        record = function(_, operation)
            local prior = state.operations[operation.operationId]
            if prior then
                if prior.delta ~= operation.delta or prior.reason ~= operation.reason then
                    return { status = "conflict", durable = false, error = "OPERATION_ID_CONFLICT" }
                end
                return { status = "duplicate", durable = true, state = { balance = state.balance } }
            end
            if state.balance + operation.delta < 0 then
                return { status = "rejected", durable = false, error = "INSUFFICIENT_FUNDS" }
            end
            state.operations[operation.operationId] = {
                delta = operation.delta,
                reason = operation.reason,
            }
            state.balance = state.balance + operation.delta
            return { status = "applied", durable = true, state = { balance = state.balance } }
        end,
    }
end

local auth = {
    [101] = { owned = true, editing = true, plotId = "plot-01" },
    [202] = { owned = false, editing = false },
}
local function authorize(playerId)
    return clone(auth[playerId] or { owned = false, editing = false })
end

local editor = Editor.new({
    layoutRepositoryFactory = layoutFactory,
    economyRepositoryFactory = economyFactory,
    authorize = authorize,
})

local state = editor:getState(101)
eq(state.accepted, true, "state accepted")
eq(#state.catalog, 2, "catalog size")
eq(state.catalog[1].category, "Utilities", "verified category one")
eq(state.catalog[2].category, "Other", "verified category two")

local visitor = editor:purchase(202, "other-chair-v1", "visitor-buy")
eq(visitor.accepted, false, "visitor purchase accepted")
eq(visitor.code, "house_not_owned", "visitor purchase code")

auth[101].editing = false
local notEditing = editor:purchase(101, "other-chair-v1", "not-editing")
eq(notEditing.accepted, false, "non-edit purchase accepted")
eq(notEditing.code, "edit_mode_required", "non-edit purchase code")
auth[101].editing = true

local bought = editor:purchase(101, "other-chair-v1", "buy-1")
eq(bought.accepted, true, "buy rejected")
eq(bought.code, "furniture_purchased", "buy code")
eq(bought.inventory[1].quantity, 1, "buy inventory")
eq(economyState[101].balance, 92, "buy balance")

local buyReplay = editor:purchase(101, "other-chair-v1", "buy-1")
eq(buyReplay.accepted, true, "buy replay rejected")
eq(buyReplay.replayed, true, "buy replay flag")
eq(buyReplay.inventory[1].quantity, 1, "buy replay duplicated inventory")
eq(economyState[101].balance, 92, "buy replay double charged")

local placed = editor:place(101, "other-chair-v1", { x = 0, y = 0, z = 0, rotation = 0 }, "place-1")
eq(placed.accepted, true, "place rejected")
eq(placed.code, "furniture_placed", "place code")
eq(#placed.inventory, 0, "place did not consume inventory")
eq(#placed.placements, 1, "placement count")
local placementId = placed.placementId

local placeReplay = editor:place(101, "other-chair-v1", { x = 0, y = 0, z = 0, rotation = 0 }, "place-1")
eq(placeReplay.accepted, true, "place replay rejected")
eq(#placeReplay.placements, 1, "place replay duplicated placement")

local moved = editor:move(101, placementId, { x = 4, y = 0, z = 2, rotation = 0 }, "move-1")
eq(moved.accepted, true, "move rejected")
eq(moved.placements[1].x, 4, "move x")
eq(moved.placements[1].z, 2, "move z")

local rotated = editor:rotate(101, placementId, 90, "rotate-1")
eq(rotated.accepted, true, "rotate rejected")
eq(rotated.placements[1].rotation, 90, "rotation")

local painted = editor:paint(101, placementId, "legacy-red", "paint-1")
eq(painted.accepted, true, "paint rejected")
eq(painted.placements[1].paintId, "legacy-red", "paint id")

local hidden = editor:setHideWalls(101, true, "walls-1")
eq(hidden.accepted, true, "hide walls rejected")
eq(hidden.hideWalls, true, "hide walls state")

local removed = editor:remove(101, placementId, "other-chair-v1", "remove-1")
eq(removed.accepted, true, "remove rejected")
eq(#removed.placements, 0, "remove placement")
eq(removed.inventory[1].quantity, 1, "remove did not return inventory")

local sold = editor:sellInventory(101, "other-chair-v1", "sell-1")
eq(sold.accepted, true, "sell rejected")
eq(sold.code, "furniture_sold", "sell code")
eq(#sold.inventory, 0, "sell inventory")
eq(economyState[101].balance, 96, "sell balance")

local sellReplay = editor:sellInventory(101, "other-chair-v1", "sell-1")
eq(sellReplay.accepted, true, "sell replay rejected")
eq(sellReplay.replayed, true, "sell replay flag")
eq(economyState[101].balance, 96, "sell replay double credited")

local boughtLamp = editor:purchase(101, "utility-floor-lamp-v1", "buy-lamp")
eq(boughtLamp.accepted, true, "lamp buy")
local placedLamp = editor:place(101, "utility-floor-lamp-v1", { x = -3, y = 0, z = 3, rotation = 180 }, "place-lamp")
eq(placedLamp.accepted, true, "lamp place")

layoutRepos[101] = nil
local reopenedEditor = Editor.new({
    layoutRepositoryFactory = layoutFactory,
    economyRepositoryFactory = economyFactory,
    authorize = authorize,
})
local reopened = reopenedEditor:getState(101)
eq(reopened.hideWalls, true, "rejoin hide walls")
eq(#reopened.placements, 1, "rejoin placement count")
eq(reopened.placements[1].itemId, "utility-floor-lamp-v1", "rejoin placement item")
eq(reopened.placements[1].rotation, 180, "rejoin rotation")
eq(economyState[101].balance, 86, "rejoin economy balance")

local outside = editor:move(101, reopened.placements[1].placementId, { x = 99, y = 0, z = 0, rotation = 0 }, "outside")
eq(outside.accepted, false, "out-of-bounds move accepted")
eq(outside.code, "invalid_transform", "out-of-bounds code")

print("HIGH_SCHOOL_HOUSING_EDITOR_CONTROLLER_PASS")
