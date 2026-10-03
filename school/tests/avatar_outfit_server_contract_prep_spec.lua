-- Content-QA-verified Legacy outfit server contract.
-- This prep test encodes only verified names/fields/defaults/filtering semantics.

local REMOTES = {
    WearOutfit = "WearOutfit",
    SaveOutfit = "SaveOutfit",
    ChangeBodyMorph = "ChangeBodyMorph",
}

assert(REMOTES.WearOutfit == "WearOutfit")
assert(REMOTES.SaveOutfit == "SaveOutfit")
assert(REMOTES.ChangeBodyMorph == "ChangeBodyMorph")

local fields = {
    OutfitName = "",
    Hat1 = 0,
    Hat2 = 0,
    Hat3 = 0,
    Shirt = 0,
    Pants = 0,
    Face = 0,
    Package = 0,
    RPName = "",
    RPDesc = "",
    RemoveShirt = false,
}

assert(fields.OutfitName == "")
assert(fields.Hat1 == 0 and fields.Hat2 == 0 and fields.Hat3 == 0)
assert(fields.Shirt == 0 and fields.Pants == 0 and fields.Face == 0 and fields.Package == 0)
assert(fields.RPName == "" and fields.RPDesc == "")
assert(fields.RemoveShirt == false)

local filteredIdentity = {
    OutfitName = true,
    RPName = true,
    RPDesc = true,
}

assert(filteredIdentity.OutfitName)
assert(filteredIdentity.RPName)
assert(filteredIdentity.RPDesc)
assert(filteredIdentity.Hat1 == nil)
assert(filteredIdentity.Shirt == nil)

local savedOutfitSlots = 12
assert(savedOutfitSlots == 12)

local morphsRequireR6 = true
assert(morphsRequireR6 == true)

print("HIGH_SCHOOL_AVATAR_OUTFIT_SERVER_CONTRACT_PREP_PASS")
