local Controller = assert(loadfile("school/src/shared/FeaturePanelController.lua"))()

local controller = Controller.new({ "shop", "avatar", "travel", "house" })

local initial = controller:snapshot()
assert(initial.active == nil and initial.revision == 0, "controller must start neutral")

local opened = controller:open("shop", "rail")
assert(opened.accepted and opened.code == "opened", "shop must open")
assert(opened.active == "shop" and opened.previous == nil, "shop becomes sole active panel")

local repeated = controller:open("shop", "repeat")
assert(repeated.code == "already_open", "repeat-open must be idempotent")
assert(repeated.revision == opened.revision, "repeat-open must not mutate revision")

local switched = controller:open("avatar", "rail")
assert(switched.active == "avatar" and switched.previous == "shop", "open must replace prior panel")

local staleClose = controller:close("shop", "stale_close")
assert(not staleClose.accepted and staleClose.code == "not_active", "stale close must not hide active panel")
assert(staleClose.active == "avatar", "stale close must preserve active panel")

local toggledClosed = controller:toggle("avatar", "back")
assert(toggledClosed.accepted and toggledClosed.active == nil, "active rail button must toggle closed")

local denied = controller:open("unknown", "invalid")
assert(not denied.accepted and denied.code == "unknown_panel", "unknown panel must be denied")
assert(denied.active == nil, "denial must preserve neutral state")

controller:open("house", "rail")
local respawn = controller:reset("respawn")
assert(respawn.active == nil and respawn.previous == "house", "respawn must restore neutral state")
assert(respawn.reason == "respawn", "reset reason must be retained for diagnostics")

local alreadyNeutral = controller:reset("repeat_respawn")
assert(alreadyNeutral.code == "already_closed", "neutral reset must be idempotent")

print("HIGH_SCHOOL_FEATURE_PANEL_CONTROLLER_PASS")
