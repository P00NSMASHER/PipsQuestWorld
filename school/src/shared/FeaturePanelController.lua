-- Pure single-active-panel state machine. This module owns presentation state
-- only; gameplay, economy, progression, travel, and persistence stay with their
-- existing server-authoritative systems.

local FeaturePanelController = {}
FeaturePanelController.__index = FeaturePanelController

local function result(controller, accepted, code, previous)
    return {
        accepted = accepted,
        code = code,
        active = controller._active,
        previous = previous,
        revision = controller._revision,
        reason = controller._reason,
    }
end

function FeaturePanelController.new(panelNames)
    assert(type(panelNames) == "table", "panel names are required")

    local allowed = {}
    for _, name in ipairs(panelNames) do
        assert(type(name) == "string" and name ~= "", "panel name must be non-empty")
        assert(allowed[name] ~= true, "duplicate panel name: " .. name)
        allowed[name] = true
    end

    return setmetatable({
        _allowed = allowed,
        _active = nil,
        _revision = 0,
        _reason = "initial",
    }, FeaturePanelController)
end

function FeaturePanelController:open(name, reason)
    if self._allowed[name] ~= true then
        return result(self, false, "unknown_panel")
    end
    if self._active == name then
        return result(self, true, "already_open", name)
    end

    local previous = self._active
    self._active = name
    self._revision = self._revision + 1
    self._reason = reason or "open"
    return result(self, true, "opened", previous)
end

function FeaturePanelController:toggle(name, reason)
    if self._active == name then
        return self:close(name, reason or "toggle_close")
    end
    return self:open(name, reason or "toggle_open")
end

function FeaturePanelController:close(name, reason)
    if name ~= nil and self._allowed[name] ~= true then
        return result(self, false, "unknown_panel")
    end
    if name ~= nil and self._active ~= name then
        return result(self, false, "not_active")
    end
    if self._active == nil then
        return result(self, true, "already_closed")
    end

    local previous = self._active
    self._active = nil
    self._revision = self._revision + 1
    self._reason = reason or "close"
    return result(self, true, "closed", previous)
end

function FeaturePanelController:reset(reason)
    return self:close(nil, reason or "reset")
end

function FeaturePanelController:snapshot()
    return result(self, true, "snapshot")
end

return FeaturePanelController
