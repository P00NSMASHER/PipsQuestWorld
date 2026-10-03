--!strict
-- Pure active-session housing plot authority.
-- Durable ownership/money remains in EconomyRepository.

local HousingLifecycle = {}
HousingLifecycle.__index = HousingLifecycle

local function validKey(value)
    return type(value) == "string" and value ~= ""
end

local function copy(state)
    if state == nil then return nil end
    return {
        playerKey = state.playerKey,
        plotId = state.plotId,
        editing = state.editing == true,
        styleId = state.styleId,
    }
end

function HousingLifecycle.new(plotIds)
    assert(type(plotIds) == "table" and #plotIds > 0, "plotIds are required")
    local seen = {}
    local ordered = {}
    for index, plotId in ipairs(plotIds) do
        assert(validKey(plotId), "plot id must be a non-empty string")
        assert(not seen[plotId], "duplicate plot id")
        seen[plotId] = true
        ordered[index] = plotId
    end

    return setmetatable({
        _plots = ordered,
        _ownerByPlot = {},
        _stateByPlayer = {},
    }, HousingLifecycle)
end

function HousingLifecycle:get(playerKey)
    assert(validKey(playerKey), "playerKey must be a non-empty string")
    return copy(self._stateByPlayer[playerKey])
end

function HousingLifecycle:claim(playerKey)
    assert(validKey(playerKey), "playerKey must be a non-empty string")
    local existing = self._stateByPlayer[playerKey]
    if existing then
        return {
            accepted = true,
            code = "plot_already_claimed",
            state = copy(existing),
        }
    end

    for _, plotId in ipairs(self._plots) do
        if self._ownerByPlot[plotId] == nil then
            local state = {
                playerKey = playerKey,
                plotId = plotId,
                editing = false,
                styleId = "classic-blue",
            }
            self._ownerByPlot[plotId] = playerKey
            self._stateByPlayer[playerKey] = state
            return {
                accepted = true,
                code = "plot_claimed",
                state = copy(state),
            }
        end
    end

    return {
        accepted = false,
        code = "no_plot_available",
        state = nil,
    }
end

function HousingLifecycle:release(playerKey)
    assert(validKey(playerKey), "playerKey must be a non-empty string")
    local current = self._stateByPlayer[playerKey]
    if current == nil then
        return { accepted = true, code = "plot_already_released" }
    end

    self._ownerByPlot[current.plotId] = nil
    self._stateByPlayer[playerKey] = nil
    return {
        accepted = true,
        code = "plot_released",
        released = copy(current),
    }
end

function HousingLifecycle:isOwner(playerKey, plotId)
    assert(validKey(playerKey), "playerKey must be a non-empty string")
    assert(validKey(plotId), "plotId must be a non-empty string")
    return self._ownerByPlot[plotId] == playerKey
end

function HousingLifecycle:setEditing(playerKey, enabled)
    assert(validKey(playerKey), "playerKey must be a non-empty string")
    local current = self._stateByPlayer[playerKey]
    if current == nil then
        return { accepted = false, code = "no_active_plot" }
    end
    current.editing = enabled == true
    return {
        accepted = true,
        code = current.editing and "edit_started" or "edit_ended",
        state = copy(current),
    }
end

function HousingLifecycle:setStyle(playerKey, styleId)
    assert(validKey(playerKey), "playerKey must be a non-empty string")
    local current = self._stateByPlayer[playerKey]
    if current == nil then
        return { accepted = false, code = "no_active_plot" }
    end
    if current.editing ~= true then
        return { accepted = false, code = "edit_mode_required", state = copy(current) }
    end
    if not validKey(styleId) then
        return { accepted = false, code = "invalid_style", state = copy(current) }
    end
    current.styleId = styleId
    return {
        accepted = true,
        code = "style_changed",
        state = copy(current),
    }
end

return HousingLifecycle
