--!strict
-- Verified Legacy avatar/outfit server contract. No runtime or persistence authority.

return {
    remotes = {
        WearOutfit = "WearOutfit",
        SaveOutfit = "SaveOutfit",
        ChangeBodyMorph = "ChangeBodyMorph",
    },
    persistedFields = {
        "OutfitName",
        "Hat1",
        "Hat2",
        "Hat3",
        "Shirt",
        "Pants",
        "Face",
        "Package",
        "RPName",
        "RPDesc",
        "RemoveShirt",
    },
    defaults = {
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
    },
    filteredIdentityFields = {
        OutfitName = true,
        RPName = true,
        RPDesc = true,
    },
    savedOutfitSlotCount = 12,
    morphsRequireR6 = true,
    boundaries = {
        createsPersistenceWriter = false,
        createsEconomyAuthority = false,
        createsWorldAuthority = false,
        createsClassAuthority = false,
    },
}
