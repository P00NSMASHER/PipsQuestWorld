local Ledger = assert(loadfile("highschool/src/progression/ProgressionLedger.lua"))()

local Repository = {}
Repository.__index = Repository

local function validPlayerId(playerId)
    return type(playerId) == "number" and playerId > 0 and playerId % 1 == 0
end

function Repository.open(store, playerId)
    if type(store) ~= "table"
        or type(store.load) ~= "function"
        or type(store.save) ~= "function" then
        return nil, "INVALID_STORE"
    end
    if not validPlayerId(playerId) then
        return nil, "INVALID_PLAYER_ID"
    end

    local snapshot, loadError = store:load(playerId)
    if loadError ~= nil then
        return nil, "LOAD_FAILED:" .. tostring(loadError)
    end

    local ledger, sourceOrError = Ledger.restoreOrDefault(snapshot)
    if not ledger then
        return nil, sourceOrError
    end

    return setmetatable({
        _store = store,
        _playerId = playerId,
        _ledger = ledger,
        _source = sourceOrError,
    }, Repository)
end

function Repository:getState()
    return self._ledger:getPlayerState(self._playerId)
end

function Repository:getLoadSource()
    return self._source
end

function Repository:record(completion)
    if type(completion) ~= "table" then
        return { status = "rejected", applied = false, error = "INVALID_RECORD" }
    end
    if completion.playerId ~= self._playerId then
        return {
            status = "rejected",
            applied = false,
            error = "PLAYER_SCOPE_MISMATCH",
        }
    end

    local shadow, restoreError = Ledger.restore(self._ledger:save())
    if not shadow then
        return {
            status = "rejected",
            applied = false,
            error = restoreError or "SHADOW_RESTORE_FAILED",
        }
    end

    local receipt = shadow:apply(completion)
    if receipt.status ~= "applied" then
        return receipt
    end

    local persisted, saveError = self._store:save(self._playerId, shadow:save())
    if persisted ~= true then
        return {
            status = "rejected",
            applied = false,
            error = "SAVE_FAILED:" .. tostring(saveError or "unknown"),
        }
    end

    self._ledger = shadow
    self._source = "live"
    return receipt
end

return Repository
