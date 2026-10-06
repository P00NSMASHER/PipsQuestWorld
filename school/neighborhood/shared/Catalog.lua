--!strict
-- One shared, fixed-price catalog. Server alone changes balances and ownership.
-- IDs already shipped in the neighborhood playtest are preserved so existing saves migrate forward.
local Catalog = {}

Catalog.Subjects = {
    {id="math", name="Math", short="Math", teacher="Mrs. Campion", color={62,154,214}},
    {id="reading", name="Reading / ELA", short="Reading", teacher="Mrs. Russek", color={125,103,202}},
    {id="grammar", name="Grammar", short="Grammar", teacher="Mrs. Benulis", color={137,105,170}},
    {id="religion", name="Religion", short="Religion", teacher="Mr. Bolich", color={196,147,58}},
    {id="vocabulary", name="Vocabulary", short="Vocabulary", teacher="Mr. Yordy", color={58,135,118}},
    {id="spelling", name="Spelling / Handwriting", short="Spelling", teacher="Mrs. Kochol", color={51,158,129}},
}

Catalog.Tiers = {
    {name="Starting out", earned=0},
    {name="Getting comfortable", earned=400},
    {name="Moving up", earned=1500},
    {name="Living well", earned=4500},
    {name="Dream life", earned=12000},
}

Catalog.Items = {
    -- Homes: every player begins with a functional home; later tiers must be visibly different.
    {id="home_starter", category="Homes", name="Starter Cottage", price=0, tier=1, style=1, color={225,220,206}, description="A small furnished home with your own front door and driveway."},
    {id="home_cottage", category="Homes", name="Cozy Cottage", price=400, tier=2, style=2, color={180,213,202}, description="Better finishes, a porch, shutters and a larger living area."},
    {id="home_suburban", category="Homes", name="Suburban Home", price=1500, tier=3, style=3, color={213,204,184}, description="More space, a garden and a stronger two-level silhouette."},
    {id="home_villa", category="Homes", name="Modern Home", price=4500, tier=4, style=4, color={231,236,239}, description="Large windows, a terrace and cleaner premium architecture."},
    {id="home_estate", category="Homes", name="Dream Estate", price=12000, tier=5, style=5, color={238,231,216}, description="The largest home, with premium details, grounds and a distinctive entrance."},

    -- Clothes: experience-local looks. No listing claims platform-wide Roblox ownership.
    {id="outfit_coral", category="Clothes", name="Everyday Tee • Coral", price=50, tier=1, style=1, color={227,128,126}, description="A simple everyday school look."},
    {id="outfit_ocean", category="Clothes", name="Everyday Tee • Ocean", price=50, tier=1, style=1, color={70,158,183}, description="The same starter look in ocean blue."},
    {id="outfit_hoodie", category="Clothes", name="Campus Hoodie", price=150, tier=2, style=2, color={42,91,126}, description="A navy hoodie-inspired layer for school and the neighborhood."},
    {id="outfit_varsity", category="Clothes", name="Varsity Jacket", price=450, tier=3, style=3, color={57,84,124}, description="Navy with light sleeves and ABVM-inspired gold trim."},
    {id="outfit_rose", category="Clothes", name="Rose Varsity", price=450, tier=3, style=3, color={173,105,149}, description="The varsity silhouette in rose."},
    {id="outfit_signature", category="Clothes", name="Signature Outfit", price=1250, tier=4, style=4, color={46,58,78}, description="Dark tailoring with refined gold accents."},
    {id="outfit_premier", category="Clothes", name="Premier Collection", price=3500, tier=5, style=5, color={31,42,59}, description="The most polished experience-local outfit treatment."},

    -- Furnishings/wearables. Every enabled listing has an existing renderer/equip path.
    {id="item_lamp", category="Items", name="Reading Lamp", price=50, tier=1, style=2, color={224,192,115}, description="A warm reading light for your home."},
    {id="item_rug", category="Items", name="Cozy Rug", price=90, tier=1, style=1, color={220,178,112}, description="A soft rug that makes the starter home feel more finished."},
    {id="item_backpack", category="Items", name="Campus Backpack", price=180, tier=2, style=4, color={68,156,155}, description="A wearable school backpack."},
    {id="item_sofa", category="Items", name="Modern Sofa", price=400, tier=3, style=5, color={111,145,135}, description="Upgrade the main seating in your living room."},
    {id="item_books", category="Items", name="Home Library", price=850, tier=4, style=3, color={150,112,79}, description="A substantial bookshelf/library feature for your home."},
    {id="item_fountain", category="Items", name="Garden Fountain", price=1500, tier=5, style=6, color={211,219,220}, description="A premium fountain for the front garden."},

    -- Vehicles: free starter ride plus increasingly expensive upgrades.
    {id="vehicle_cart", category="Vehicles", name="Starter Cart", price=0, tier=1, style=1, speed=24, color={189,204,199}, description="Your free starter ride for the neighborhood."},
    {id="vehicle_hatch", category="Vehicles", name="Compact Car", price=900, tier=2, style=2, speed=34, color={70,151,184}, description="A compact everyday car with a painted roof and alloy wheels."},
    {id="vehicle_sport", category="Vehicles", name="Sport Coupe", price=2400, tier=4, style=3, speed=40, color={198,101,101}, description="A lower, faster-looking coupe with premium trim."},
    {id="vehicle_luxe", category="Vehicles", name="Signature Sedan", price=6500, tier=5, style=4, speed=40, color={50,61,78}, description="A long polished sedan with gold accents."},
}

Catalog.ById = {}
for _,item in ipairs(Catalog.Items) do
    assert(Catalog.ById[item.id] == nil, "duplicate catalog id")
    Catalog.ById[item.id]=item
end

function Catalog.tier(earned)
    local index=1
    for i,tier in ipairs(Catalog.Tiers) do
        if earned>=tier.earned then index=i end
    end
    return index,Catalog.Tiers[index],Catalog.Tiers[index+1]
end

return Catalog
