local Controller = assert(loadfile("school/src/shared/FeaturePanelController.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local visibility = { shop = false, avatar = false, house = false, travel = false }
local showCount = { shop = 0, avatar = 0, house = 0, travel = 0 }
local controller = Controller.new()

for _, panelId in ipairs({ "shop", "avatar", "house", "travel" }) do
    controller:register(panelId, {
        show = function()
            visibility[panelId] = true
            showCount[panelId] = showCount[panelId] + 1
            return true
        end,
        hide = function()
            visibility[panelId] = false
        end,
    })
end

local opened, openCode = controller:activate("shop", "mouse")
eq(opened, true, "desktop activation")
eq(openCode, "opened", "desktop activation code")
eq(controller:activeId(), "shop", "desktop active panel")
eq(visibility.shop, true, "shop shown")

local switched, switchCode = controller:activate("travel", "touch")
eq(switched, true, "touch activation")
eq(switchCode, "opened", "touch activation code")
eq(visibility.shop, false, "prior panel hidden")
eq(visibility.travel, true, "touch panel shown")
eq(controller:activeId(), "travel", "single active panel")

local toggled, toggleCode = controller:activate("travel", "touch")
eq(toggled, true, "repeat activation handled")
eq(toggleCode, "closed", "repeat activation is deterministic close")
eq(controller:activeId(), nil, "repeat activation clears active panel")
eq(visibility.travel, false, "repeat activation hides panel")

controller:restore("travel", "request_denied")
eq(controller:activeId(), "travel", "denial restores active panel")
eq(visibility.travel, true, "denial restores visibility")
eq(showCount.travel, 2, "restoration does not duplicate registration")

controller:activate("house", "gamepad")
controller:reset("respawn")
eq(controller:activeId(), nil, "respawn clears active panel")
for panelId, visible in pairs(visibility) do
    eq(visible, false, "respawn hides " .. panelId)
end

local unavailable = Controller.new()
unavailable:register("avatar", {
    show = function() return false end,
    hide = function() end,
})
local accepted, deniedCode = unavailable:activate("avatar", "keyboard")
eq(accepted, false, "unavailable panel activation denied")
eq(deniedCode, "show_denied", "unavailable panel denial code")
eq(unavailable:activeId(), nil, "denied panel does not become active")

local invalid, invalidCode = controller:activate("shop", "voice")
eq(invalid, false, "unsupported input rejected")
eq(invalidCode, "unsupported_input", "unsupported input code")

print("HIGH_SCHOOL_FEATURE_PANEL_CONTROLLER_PASS")
