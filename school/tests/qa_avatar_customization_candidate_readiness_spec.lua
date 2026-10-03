local path = "school/src/client/AvatarCustomization.client.lua"
local file = assert(io.open(path, "r"))
local source = file:read("*a")
file:close()

local function has(fragment, label)
    if not source:find(fragment, 1, true) then
        error("avatar/customization QA readiness missing: " .. (label or fragment), 2)
    end
end

local function lacks(fragment, label)
    if source:find(fragment, 1, true) then
        error("avatar/customization QA authority violation: " .. (label or fragment), 2)
    end
end

-- Exact identity/hierarchy claims already supported by the pinned Legacy reference.
has('return "OutfitsMobile"', "mobile GUI identity")
has('return "OutfitsConsole"', "console GUI identity")
has('return "Outfits"', "desktop GUI identity")
has('panel.Name = "OutfitInputs"', "OutfitInputs hierarchy")
has('slots.Name = "OutfitSlots"', "OutfitSlots hierarchy")
has('pages.Name = "OutfitPages"', "OutfitPages hierarchy")
has('morphs.Name = "MorphsFrame"', "MorphsFrame hierarchy")
has('slots:SetAttribute("SavedOutfitSlotCount", 12)', "twelve saved outfit slots")

-- Geometry/presentation is not yet reference-verified and must remain explicitly non-exact.
has('gui:SetAttribute("ReferenceExactLayout", false)', "GUI layout non-exact marker")
has('entry:SetAttribute("ReferenceExactLayout", false)', "entry layout non-exact marker")
has('slot:SetAttribute("ReferenceExactLayout", false)', "slot layout non-exact marker")

-- This client surface may request server actions later, but must never become a
-- second persistence/economy/ownership authority or manufacture remotes.
for _, forbidden in ipairs({
    'game:GetService("DataStoreService")',
    'Instance.new("RemoteEvent")',
    'Instance.new("RemoteFunction")',
    ":SetAsync(",
    ":UpdateAsync(",
    ":IncrementAsync(",
}) do
    lacks(forbidden, forbidden)
end

-- Phase-2 education remains outside the canonical clone slice.
for _, deferred in ipairs({
    "STAR-style",
    "second-grade",
    "Grade 2",
    "Emma",
}) do
    lacks(deferred, "deferred Phase-2 content: " .. deferred)
end

print("HIGH_SCHOOL_QA_AVATAR_CUSTOMIZATION_READINESS_PASS")
