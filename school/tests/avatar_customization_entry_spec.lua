local path = "school/src/client/AvatarCustomization.client.lua"
local file = assert(io.open(path, "r"))
local text = file:read("*a")
file:close()

local function has(fragment, label)
    if not text:find(fragment, 1, true) then
        error("missing avatar/customization entry contract: " .. (label or fragment), 2)
    end
end

local function lacks(fragment, label)
    if text:find(fragment, 1, true) then
        error("unverified avatar/customization surface leaked: " .. (label or fragment), 2)
    end
end

has('return "OutfitsMobile"', "mobile exact GUI identity")
has('return "OutfitsConsole"', "console exact GUI identity")
has('return "Outfits"', "desktop exact GUI identity")
has('entry.Text = "Custom Outfits"', "exact Custom Outfits label")
has('panel.Name = "OutfitInputs"', "exact OutfitInputs hierarchy")
has('slots.Name = "OutfitSlots"', "exact OutfitSlots hierarchy")
has('pages.Name = "OutfitPages"', "exact OutfitPages hierarchy")
has('morphs.Name = "MorphsFrame"', "exact MorphsFrame hierarchy")
has('r6Warning.Text = "[Morphs only work with R6]"', "exact R6 warning")
has('slots:SetAttribute("SavedOutfitSlotCount", 12)', "exact saved outfit count")
has('pages:SetAttribute("PageStart1", 1)', "page start 1")
has('pages:SetAttribute("PageStart2", 4)', "page start 4")
has('pages:SetAttribute("PageStart3", 7)', "page start 7")
has('pages:SetAttribute("PageStart4", 10)', "page start 10")
has('gui:SetAttribute("ReferenceExactLayout", false)', "unknown layout remains explicit")
has('panel.Visible = not panel.Visible', "entry open-close behavior")
lacks("Hat4", "later nine-hat revision must not leak")
lacks("Hat9", "later nine-hat revision must not leak")
lacks("PurchasePermanentItem", "shopping mechanics not guessed before catalog/remote semantics are implemented")

print("HIGH_SCHOOL_AVATAR_CUSTOMIZATION_ENTRY_PASS")
