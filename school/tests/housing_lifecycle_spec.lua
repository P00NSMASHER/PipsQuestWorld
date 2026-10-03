local HousingLifecycle = assert(loadfile("school/src/server/HousingLifecycle.lua"))()

local function eq(actual, expected, label)
    if actual ~= expected then
        error((label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local lifecycle = HousingLifecycle.new({ "plot-01", "plot-02" })

local first = lifecycle:claim("101")
eq(first.accepted, true, "first claim rejected")
eq(first.code, "plot_claimed", "first claim code")
eq(first.state.plotId, "plot-01", "first plot")
eq(lifecycle:isOwner("101", "plot-01"), true, "first owner")

local repeated = lifecycle:claim("101")
eq(repeated.code, "plot_already_claimed", "repeat claim")
eq(repeated.state.plotId, "plot-01", "repeat plot changed")

local second = lifecycle:claim("202")
eq(second.state.plotId, "plot-02", "second plot")
local full = lifecycle:claim("303")
eq(full.accepted, false, "full claim accepted")
eq(full.code, "no_plot_available", "full claim code")

local nonOwnerEdit = lifecycle:setEditing("303", true)
eq(nonOwnerEdit.accepted, false, "non-owner edit accepted")
eq(nonOwnerEdit.code, "no_active_plot", "non-owner edit code")

local edit = lifecycle:setEditing("101", true)
eq(edit.accepted, true, "owner edit rejected")
eq(edit.state.editing, true, "edit state")

local style = lifecycle:setStyle("101", "classic-red")
eq(style.accepted, true, "style change rejected")
eq(style.state.styleId, "classic-red", "style id")

local released = lifecycle:release("101")
eq(released.accepted, true, "release rejected")
eq(lifecycle:isOwner("101", "plot-01"), false, "plot still owned")

local reclaimed = lifecycle:claim("303")
eq(reclaimed.accepted, true, "reclaim rejected")
eq(reclaimed.state.plotId, "plot-01", "released plot not reused")

local repeatedRelease = lifecycle:release("101")
eq(repeatedRelease.code, "plot_already_released", "repeat release code")

print("HIGH_SCHOOL_HOUSING_LIFECYCLE_PASS")
