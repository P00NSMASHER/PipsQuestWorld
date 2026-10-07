--!strict
-- Deterministic client-only coordinator for the four verified feature panels.
-- It owns visibility only. Class, vehicle, job, travel, shopping, avatar, and
-- housing authority remain in their existing boundaries.

local Controller = {}
Controller.__index = Controller

local VALID_INPUTS = {
    mouse = true,
    touch = true,
    keyboard = true,
    gamepad = true,
    system = true,
}

function Controller.new()
    return setmetatable({
        _panels = {},
        _activeId = nil,
        _generation = 0,
    }, Controller)
end

function Controller:register(panelId, adapter)
    assert(type(panelId) == "string" and panelId ~= "", "panelId is required")
    assert(type(adapter) == "table", "panel adapter is required")
    assert(type(adapter.show) == "function", "panel show callback is required")
    assert(type(adapter.hide) == "function", "panel hide callback is required")
    assert(self._panels[panelId] == nil, "panel already registered: " .. panelId)
    self._panels[panelId] = adapter
end

function Controller:activeId()
    return self._activeId
end

function Controller:_hide(panelId, reason)
    local adapter = self._panels[panelId]
    if adapter then
        adapter.hide(reason or "closed")
    end
end

function Controller:close(reason)
    local activeId = self._activeId
    if activeId == nil then
        return false, "already_closed"
    end
    self._activeId = nil
    self._generation = self._generation + 1
    self:_hide(activeId, reason)
    return true, "closed"
end

function Controller:activate(panelId, inputKind)
    local adapter = self._panels[panelId]
    if adapter == nil then
        return false, "unknown_panel"
    end
    if not VALID_INPUTS[inputKind or "system"] then
        return false, "unsupported_input"
    end
    if self._activeId == panelId then
        self:close("repeat_activation")
        return true, "closed"
    end
    if self._activeId ~= nil then
        self:close("panel_switch")
    end

    self._generation = self._generation + 1
    local shown = adapter.show(inputKind or "system")
    if shown == false then
        self:_hide(panelId, "show_denied")
        return false, "show_denied"
    end
    self._activeId = panelId
    return true, "opened"
end

function Controller:restore(panelId, reason)
    local adapter = self._panels[panelId]
    if adapter == nil then
        return false, "unknown_panel"
    end
    if self._activeId ~= nil and self._activeId ~= panelId then
        self:close("restore_switch")
    end
    self._generation = self._generation + 1
    local shown = adapter.show(reason or "restore")
    if shown == false then
        self:_hide(panelId, "restore_denied")
        self._activeId = nil
        return false, "restore_denied"
    end
    self._activeId = panelId
    return true, "restored"
end

function Controller:reset(reason)
    self._activeId = nil
    self._generation = self._generation + 1
    for panelId in pairs(self._panels) do
        self:_hide(panelId, reason or "reset")
    end
end

function Controller:generation()
    return self._generation
end

return Controller
