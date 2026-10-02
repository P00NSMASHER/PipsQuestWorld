local Controller = assert(loadfile("school/src/server/CafeJobController.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function newEconomy()
    local stateByPlayer = {}
    local calls = 0
    local failNext = false
    local throwFactoryNext = false
    local throwRecordNext = false

    local function repositoryFor(playerId)
        stateByPlayer[playerId] = stateByPlayer[playerId] or {
            balance = 0,
            operations = {},
            saves = 0,
        }
        local state = stateByPlayer[playerId]

        return {
            record = function(_, operation)
                calls = calls + 1
                if throwRecordNext then
                    throwRecordNext = false
                    error("injected record exception")
                end
                if failNext then
                    failNext = false
                    return {
                        status = "rejected",
                        applied = false,
                        durable = false,
                        error = "injected",
                    }
                end

                local prior = state.operations[operation.operationId]
                if prior then
                    if prior.delta == operation.delta and prior.reason == operation.reason then
                        return {
                            status = "duplicate",
                            applied = false,
                            durable = true,
                            state = {
                                balance = state.balance,
                                operationCount = state.saves,
                            },
                        }
                    end
                    return {
                        status = "conflict",
                        applied = false,
                        durable = false,
                        error = "OPERATION_ID_CONFLICT",
                    }
                end

                state.operations[operation.operationId] = {
                    delta = operation.delta,
                    reason = operation.reason,
                }
                state.balance = state.balance + operation.delta
                state.saves = state.saves + 1
                return {
                    status = "applied",
                    applied = true,
                    durable = true,
                    state = {
                        balance = state.balance,
                        operationCount = state.saves,
                    },
                }
            end,
        }
    end

    return {
        repositoryFactory = function(playerId)
            if throwFactoryNext then
                throwFactoryNext = false
                error("injected factory exception")
            end
            return repositoryFor(playerId), nil
        end,
        setFailNext = function()
            failNext = true
        end,
        setThrowFactoryNext = function()
            throwFactoryNext = true
        end,
        setThrowRecordNext = function()
            throwRecordNext = true
        end,
        balance = function(playerId)
            local state = stateByPlayer[playerId]
            return state and state.balance or 0
        end,
        saves = function(playerId)
            local state = stateByPlayer[playerId]
            return state and state.saves or 0
        end,
        calls = function()
            return calls
        end,
    }
end

local ids = { "shift-a", "shift-b", "shift-c", "shift-d", "shift-e" }
local nextId = 0
local economy = newEconomy()
local controller = Controller.new({
    wage = 25,
    repositoryFactory = economy.repositoryFactory,
    shiftIdFactory = function()
        nextId = nextId + 1
        return ids[nextId]
    end,
})

local away = controller:startShift(101, false)
eq(away.accepted, false, "away start accepted")
eq(away.code, "not_at_cafe", "away start code")

local started = controller:startShift(101, true)
eq(started.accepted, true, "start accepted")
eq(started.code, "shift_started", "start code")
eq(started.active, true, "start active")
eq(started.shiftId, "shift-a", "start shift id")
eq(started.taskId, "serve_order", "task id")
eq(started.wage, 25, "wage")

local duplicateStart = controller:startShift(101, true)
eq(duplicateStart.code, "shift_already_active", "duplicate start code")
eq(duplicateStart.shiftId, "shift-a", "duplicate start changed shift")

local wrongShift = controller:completeTask(101, "shift-z", "serve_order", true)
eq(wrongShift.accepted, false, "wrong shift accepted")
eq(wrongShift.code, "stale_shift", "wrong shift code")

local wrongTask = controller:completeTask(101, "shift-a", "wrong_task", true)
eq(wrongTask.code, "invalid_task", "wrong task code")

local leftCafe = controller:completeTask(101, "shift-a", "serve_order", false)
eq(leftCafe.code, "not_at_cafe", "left cafe code")
eq(controller:getState(101).active, true, "left cafe ended shift")

local completed = controller:completeTask(101, "shift-a", "serve_order", true)
eq(completed.accepted, true, "completion accepted")
eq(completed.code, "shift_completed", "completion code")
eq(completed.returnToFreeRoam, true, "completion free roam")
eq(completed.economyStatus, "applied", "completion economy status")
eq(completed.economyState.balance, 25, "completion balance")
eq(economy.balance(101), 25, "economy balance")
eq(economy.saves(101), 1, "economy saves")
eq(controller:getState(101).active, false, "completion still active")

local replay = controller:completeTask(101, "shift-a", "serve_order", true)
eq(replay.accepted, true, "replay accepted")
eq(replay.code, "shift_already_completed", "replay code")
eq(replay.replayed, true, "replay flag")
eq(replay.economyStatus, "duplicate", "replay economy status")
eq(economy.balance(101), 25, "replay double paid")
eq(economy.saves(101), 1, "replay wrote again")
eq(economy.calls(), 2, "replay did not exercise idempotence")

local second = controller:startShift(101, true)
eq(second.shiftId, "shift-b", "second shift id")
economy.setFailNext()
local failed = controller:completeTask(101, "shift-b", "serve_order", true)
eq(failed.accepted, false, "failed wage accepted")
eq(failed.code, "wage_commit_failed", "failed wage code")
eq(controller:getState(101).active, true, "failed wage lost active shift")
eq(economy.balance(101), 25, "failed wage changed balance")

local retried = controller:completeTask(101, "shift-b", "serve_order", true)
eq(retried.accepted, true, "retry accepted")
eq(retried.code, "shift_completed", "retry code")
eq(retried.economyState.balance, 50, "retry balance")
eq(economy.saves(101), 2, "retry saves")

local third = controller:startShift(101, true)
eq(third.shiftId, "shift-c", "third shift id")
economy.setThrowFactoryNext()
local factoryFailed = controller:completeTask(101, "shift-c", "serve_order", true)
eq(factoryFailed.accepted, false, "factory exception accepted")
eq(factoryFailed.code, "economy_unavailable", "factory exception code")
eq(factoryFailed.error, "repository_factory_failed", "factory exception classification")
eq(controller:getState(101).active, true, "factory exception lost active shift")
eq(economy.balance(101), 50, "factory exception changed balance")

local factoryRetried = controller:completeTask(101, "shift-c", "serve_order", true)
eq(factoryRetried.accepted, true, "factory retry accepted")
eq(factoryRetried.code, "shift_completed", "factory retry code")
eq(factoryRetried.economyState.balance, 75, "factory retry balance")

local fourth = controller:startShift(101, true)
eq(fourth.shiftId, "shift-d", "fourth shift id")
economy.setThrowRecordNext()
local recordFailed = controller:completeTask(101, "shift-d", "serve_order", true)
eq(recordFailed.accepted, false, "record exception accepted")
eq(recordFailed.code, "economy_unavailable", "record exception code")
eq(recordFailed.error, "repository_record_failed", "record exception classification")
eq(controller:getState(101).active, true, "record exception lost active shift")
eq(economy.balance(101), 75, "record exception changed balance")

local recordRetried = controller:completeTask(101, "shift-d", "serve_order", true)
eq(recordRetried.accepted, true, "record retry accepted")
eq(recordRetried.code, "shift_completed", "record retry code")
eq(recordRetried.economyState.balance, 100, "record retry balance")

local fifth = controller:startShift(101, true)
eq(fifth.shiftId, "shift-e", "fifth shift id")
local left = controller:leaveShift(101)
eq(left.accepted, true, "leave accepted")
eq(left.code, "shift_left", "leave code")
eq(left.returnToFreeRoam, true, "leave free roam")
eq(controller:getState(101).active, false, "leave still active")

print("HIGH_SCHOOL_CAFE_JOB_CONTROLLER_PASS")
