local Repository = assert(loadfile("school/src/server/HousingLayoutRepository.lua"))()

local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do
        result[clone(key)] = clone(child)
    end
    return result
end

local function memoryAdapter()
    local row = nil
    return {
        read = function(_, playerId)
            if row == nil then return nil, 0, nil end
            return clone(row.snapshot), row.version, nil
        end,
        compareAndSwap = function(_, playerId, expectedVersion, snapshot)
            local currentVersion = row and row.version or 0
            if currentVersion ~= expectedVersion then
                return false, nil, "conflict"
            end
            row = { version = snapshot.revision, snapshot = clone(snapshot) }
            return true, row.version, nil
        end,
    }
end

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local adapter = memoryAdapter()
local repo = assert(Repository.open(adapter, 101))
local initial = repo:getState()
eq(initial.revision, 0, "initial revision")
eq(initial.houseStyleId, "classic-blue", "default style")
eq(initial.hideWalls, false, "default hide walls")
eq(#initial.placements, 0, "initial placement count")

local style = repo:commit({
    operationId = "style:1",
    kind = "set_house_style",
    styleId = "classic-tan",
})
eq(style.status, "applied", "style status")
eq(style.durable, true, "style durable")
eq(style.state.houseStyleId, "classic-tan", "style persisted")

local hide = repo:commit({
    operationId = "walls:1",
    kind = "set_hide_walls",
    enabled = true,
})
eq(hide.status, "applied", "hide walls status")
eq(hide.state.hideWalls, true, "hide walls persisted")

local addInventory = repo:commit({
    operationId = "inventory:add:chair:1",
    kind = "add_inventory",
    itemId = "chair-basic",
    quantity = 2,
})
eq(addInventory.status, "applied", "inventory add status")
eq(#addInventory.state.inventory, 1, "inventory item count")
eq(addInventory.state.inventory[1].itemId, "chair-basic", "inventory item id")
eq(addInventory.state.inventory[1].quantity, 2, "inventory quantity")

local duplicateInventory = repo:commit({
    operationId = "inventory:add:chair:1",
    kind = "add_inventory",
    itemId = "chair-basic",
    quantity = 2,
})
eq(duplicateInventory.status, "duplicate", "inventory duplicate")
eq(duplicateInventory.state.inventory[1].quantity, 2, "duplicate inventory quantity")

local removeOne = repo:commit({
    operationId = "inventory:remove:chair:1",
    kind = "remove_inventory",
    itemId = "chair-basic",
    quantity = 1,
})
eq(removeOne.status, "applied", "inventory remove status")
eq(removeOne.state.inventory[1].quantity, 1, "inventory quantity after remove")

local inventoryUnderflow = repo:commit({
    operationId = "inventory:remove:chair:underflow",
    kind = "remove_inventory",
    itemId = "chair-basic",
    quantity = 2,
})
eq(inventoryUnderflow.status, "rejected", "inventory underflow status")
eq(inventoryUnderflow.error, "INSUFFICIENT_INVENTORY", "inventory underflow error")

local place = repo:commit({
    operationId = "place:chair:1",
    kind = "place_furniture",
    placementId = "chair-1",
    itemId = "chair-basic",
    x = 4,
    y = 0,
    z = -3,
    rotation = 90,
})
eq(place.status, "applied", "place status")
eq(#place.state.placements, 1, "place count")
eq(place.state.placements[1].itemId, "chair-basic", "placed item")

local duplicate = repo:commit({
    operationId = "place:chair:1",
    kind = "place_furniture",
    placementId = "chair-1",
    itemId = "chair-basic",
    x = 4,
    y = 0,
    z = -3,
    rotation = 90,
})
eq(duplicate.status, "duplicate", "idempotent duplicate")
eq(duplicate.durable, true, "duplicate durable")
eq(#duplicate.state.placements, 1, "duplicate placement count")

local conflict = repo:commit({
    operationId = "place:chair:1",
    kind = "place_furniture",
    placementId = "chair-2",
    itemId = "chair-basic",
    x = 0,
    y = 0,
    z = 0,
    rotation = 0,
})
eq(conflict.status, "conflict", "operation id conflict")

local moved = repo:commit({
    operationId = "move:chair:1",
    kind = "move_furniture",
    placementId = "chair-1",
    x = 8,
    y = 0,
    z = 2,
    rotation = 180,
})
eq(moved.status, "applied", "move status")
eq(moved.state.placements[1].x, 8, "moved x")
eq(moved.state.placements[1].rotation, 180, "moved rotation")

local painted = repo:commit({
    operationId = "paint:chair:1",
    kind = "paint_furniture",
    placementId = "chair-1",
    paintId = "legacy-red",
})
eq(painted.status, "applied", "paint status")
eq(painted.state.placements[1].paintId, "legacy-red", "paint persisted")

local reopened = assert(Repository.open(adapter, 101))
local restored = reopened:getState()
eq(#restored.inventory, 1, "reopened inventory count")
eq(restored.inventory[1].itemId, "chair-basic", "reopened inventory item")
eq(restored.inventory[1].quantity, 1, "reopened inventory quantity")
eq(restored.houseStyleId, "classic-tan", "reopened style")
eq(restored.hideWalls, true, "reopened hide walls")
eq(#restored.placements, 1, "reopened placement count")
eq(restored.placements[1].x, 8, "reopened position")
eq(restored.placements[1].paintId, "legacy-red", "reopened paint")

local removed = reopened:commit({
    operationId = "remove:chair:1",
    kind = "remove_furniture",
    placementId = "chair-1",
})
eq(removed.status, "applied", "remove status")
eq(#removed.state.placements, 0, "remove placement count")

local missingMove = reopened:commit({
    operationId = "move:missing",
    kind = "move_furniture",
    placementId = "missing",
    x = 0,
    y = 0,
    z = 0,
    rotation = 0,
})
eq(missingMove.status, "rejected", "missing move status")
eq(missingMove.error, "PLACEMENT_NOT_FOUND", "missing move error")

local invalid = reopened:commit({
    operationId = "place:bad",
    kind = "place_furniture",
    placementId = "bad",
    itemId = "chair-basic",
    x = math.huge,
    y = 0,
    z = 0,
    rotation = 0,
})
eq(invalid.status, "rejected", "invalid transform status")
eq(invalid.error, "INVALID_TRANSFORM", "invalid transform error")

print("HIGH_SCHOOL_HOUSING_LAYOUT_REPOSITORY_PASS")
