local ResponsiveHudLayout = assert(loadfile("school/src/shared/ResponsiveHudLayout.lua"))()

local function approxBetween(value, minimum, maximum, label)
    if value < minimum or value > maximum then
        error(string.format("%s: %.4f outside [%.4f, %.4f]", label, value, minimum, maximum), 2)
    end
end

local function zone(x, y, width, height)
    return {
        x = x,
        y = y,
        width = width,
        height = height,
        right = x + width,
        bottom = y + height,
    }
end

local fixtures = {
    {
        name = "reference-desktop-909x483",
        viewport = { width = 909, height = 483 },
        insets = { left = 0, top = 0, right = 0, bottom = 0 },
        zones = {},
    },
    {
        name = "iphone-landscape-852x393",
        viewport = { width = 852, height = 393 },
        insets = { left = 47, top = 0, right = 47, bottom = 21 },
        zones = {
            zone(47, 274, 187, 98),
            zone(618, 274, 187, 98),
        },
    },
    {
        name = "ipad-landscape-1024x768",
        viewport = { width = 1024, height = 768 },
        insets = { left = 24, top = 0, right = 24, bottom = 20 },
        zones = {
            zone(24, 628, 190, 120),
            zone(810, 628, 190, 120),
        },
    },
}

local layouts = {}
for _, fixture in ipairs(fixtures) do
    local layout = ResponsiveHudLayout.compute(
        fixture.viewport,
        fixture.insets,
        fixture.zones
    )
    local valid, reason = ResponsiveHudLayout.validate(layout)
    assert(valid, fixture.name .. ": " .. tostring(reason))

    for _, group in ipairs({ layout.status, layout.rail, layout.quick }) do
        assert(ResponsiveHudLayout.contains(layout.safe, group), fixture.name .. ": HUD group outside safe area")
    end
    assert(not ResponsiveHudLayout.overlaps(layout.status, layout.rail), fixture.name .. ": status/rail overlap")
    assert(not ResponsiveHudLayout.overlaps(layout.status, layout.quick), fixture.name .. ": status/quick overlap")
    assert(not ResponsiveHudLayout.overlaps(layout.rail, layout.quick), fixture.name .. ": rail/quick overlap")

    for _, exclusion in ipairs(fixture.zones) do
        assert(not ResponsiveHudLayout.overlaps(layout.status, exclusion), fixture.name .. ": status/control overlap")
        assert(not ResponsiveHudLayout.overlaps(layout.rail, exclusion), fixture.name .. ": rail/control overlap")
        assert(not ResponsiveHudLayout.overlaps(layout.quick, exclusion), fixture.name .. ": quick/control overlap")
    end

    layouts[fixture.name] = layout
end

local nominal = layouts["reference-desktop-909x483"]
approxBetween(nominal.status.width / 909, 0.12, 0.15, "nominal status width")
approxBetween(nominal.status.height / 483, 0.13, 0.17, "nominal status height")
approxBetween(nominal.rail.width / 909, 0.045, 0.065, "nominal rail width")
approxBetween(nominal.rail.height / 483, 0.40, 0.48, "nominal rail height")
approxBetween(nominal.quick.width / 909, 0.24, 0.30, "nominal quick width")
approxBetween(nominal.quick.height / 483, 0.09, 0.13, "nominal quick height")

local iphone = layouts["iphone-landscape-852x393"]
local ipad = layouts["ipad-landscape-1024x768"]
assert(iphone.status.width ~= ipad.status.width, "status width must reflow by viewport")
assert(iphone.status.height ~= ipad.status.height, "status height must reflow by viewport")
assert(iphone.rail.height ~= ipad.rail.height, "rail height must reflow by viewport")
assert(iphone.quick.y ~= ipad.quick.y, "quick bar must follow safe bottom")

local badStatus = ResponsiveHudLayout.compute(
    { width = 909, height = 483 },
    {},
    {}
)
badStatus.status = {
    x = badStatus.rail.x,
    y = badStatus.rail.y,
    width = badStatus.rail.width,
    height = badStatus.rail.width,
    right = badStatus.rail.right,
    bottom = badStatus.rail.y + badStatus.rail.width,
}
local validStatus, statusReason = ResponsiveHudLayout.validate(badStatus)
assert(not validStatus and statusReason == "status overlaps rail", "status/rail mutation must fail")

local quickProbe = ResponsiveHudLayout.compute(
    { width = 852, height = 393 },
    { left = 47, top = 0, right = 47, bottom = 21 },
    {}
)
quickProbe.exclusionZones = {
    zone(quickProbe.quick.x, quickProbe.quick.y, quickProbe.quick.width, quickProbe.quick.height),
}
local validQuick, quickReason = ResponsiveHudLayout.validate(quickProbe)
assert(not validQuick and quickReason == "quick overlaps exclusion zone 1", "quick/control mutation must fail")

print("RESPONSIVE_HUD_LAYOUT_CONTRACT_PASS")
