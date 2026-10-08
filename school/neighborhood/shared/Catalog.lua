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
    -- ABVM uniform references supplied by the user: forest-green polo + khaki, or green/navy/white plaid.
    {id="outfit_abvm_polo", category="Clothes", name="ABVM Uniform • Polo", price=25, tier=1, style=6, color={31,91,67}, description="Forest-green ABVM polo with khaki school bottoms."},
    {id="outfit_abvm_plaid", category="Clothes", name="ABVM Uniform • Plaid", price=75, tier=1, style=7, color={31,91,67}, description="ABVM green/navy/white plaid uniform with navy knee socks."},

    -- Mix-and-match ABVM uniform pieces. The slot field is additive and preserves legacy outfit saves.
    {id="uniform_top_green_polo", category="Clothes", slot="uniformTop", name="Uniform Top • Green Polo", price=15, tier=1, style=11, color={31,91,67}, description="Forest-green ABVM polo."},
    {id="uniform_top_navy_polo", category="Clothes", slot="uniformTop", name="Uniform Top • Navy Polo", price=15, tier=1, style=12, color={28,48,72}, description="Navy school polo with ABVM chest mark."},
    {id="uniform_top_white_polo", category="Clothes", slot="uniformTop", name="Uniform Top • White Polo", price=15, tier=1, style=13, color={238,238,231}, description="White school polo with green ABVM chest mark."},
    {id="uniform_top_green_sweater", category="Clothes", slot="uniformTop", name="School Sweater • Green", price=30, tier=1, style=14, color={31,91,67}, description="Forest-green school sweater for cooler days."},
    {id="uniform_top_navy_cardigan", category="Clothes", slot="uniformTop", name="School Cardigan • Navy", price=30, tier=1, style=15, color={28,48,72}, description="Navy school cardigan with light shirt inset."},
    {id="uniform_bottom_khaki_pants", category="Clothes", slot="uniformBottom", name="Uniform Bottom • Khaki Pants", price=15, tier=1, style=21, color={205,190,154}, description="Classic khaki uniform pants."},
    {id="uniform_bottom_khaki_shorts", category="Clothes", slot="uniformBottom", name="Uniform Bottom • Khaki Shorts", price=15, tier=1, style=22, color={205,190,154}, description="Classic khaki uniform shorts."},
    {id="uniform_bottom_khaki_skirt", category="Clothes", slot="uniformBottom", name="Uniform Bottom • Khaki Skirt", price=20, tier=1, style=23, color={205,190,154}, description="Khaki school skirt."},
    {id="uniform_bottom_plaid_skirt", category="Clothes", slot="uniformBottom", name="Uniform Bottom • Plaid Skirt", price=25, tier=1, style=24, color={31,91,67}, description="Green/navy/white plaid school skirt."},
    {id="uniform_bottom_plaid_jumper", category="Clothes", slot="uniformBottom", name="Uniform • Plaid Jumper", price=35, tier=1, style=25, color={31,91,67}, description="Green/navy/white plaid school jumper."},
    {id="uniform_socks_navy", category="Clothes", slot="uniformLegwear", name="School Socks • Navy", price=10, tier=1, style=31, color={28,48,72}, description="Navy knee socks."},
    {id="uniform_socks_white", category="Clothes", slot="uniformLegwear", name="School Socks • White", price=10, tier=1, style=32, color={238,238,231}, description="White school socks."},
    {id="uniform_tights_navy", category="Clothes", slot="uniformLegwear", name="School Tights • Navy", price=15, tier=1, style=33, color={28,48,72}, description="Navy school tights."},
    {id="uniform_shoes_brown", category="Clothes", slot="uniformShoes", name="School Shoes • Brown", price=20, tier=1, style=41, color={112,74,50}, description="Brown school shoes."},
    {id="uniform_shoes_black", category="Clothes", slot="uniformShoes", name="School Shoes • Black", price=20, tier=1, style=42, color={45,47,49}, description="Black school shoes."},
    {id="uniform_shoes_tan", category="Clothes", slot="uniformShoes", name="School Shoes • Tan", price=20, tier=1, style=43, color={166,127,86}, description="Tan school shoes."},

    -- Official 2026 ABVM school-store apparel supplied by the user.
    -- Youth/adult storefront duplicates collapse into one avatar-scaled Roblox garment.
    -- When the retail price is visible in the supplied reference, the in-game Credit price is 4x that value.
    {id="abvm_store_polo_green", category="Clothes", slot="uniformTop", name="ABVM Store Polo • Green", price=60, retailUSD=15, tier=1, style=51, color={31,91,67}, description="Official ABVM school-store short-sleeve polo in forest green."},
    {id="abvm_store_polo_navy", category="Clothes", slot="uniformTop", name="ABVM Store Polo • Navy", price=60, retailUSD=15, tier=1, style=51, color={28,48,72}, description="Official ABVM school-store short-sleeve polo in navy."},
    {id="abvm_store_ls_polo_green", category="Clothes", slot="uniformTop", name="ABVM Store Long-Sleeve Polo • Green", price=68, retailUSD=17, tier=1, style=52, color={31,91,67}, description="Official ABVM school-store long-sleeve polo in forest green."},
    {id="abvm_store_ls_polo_navy", category="Clothes", slot="uniformTop", name="ABVM Store Long-Sleeve Polo • Navy", price=68, retailUSD=17, tier=1, style=52, color={28,48,72}, description="Official ABVM school-store long-sleeve polo in navy."},
    {id="abvm_store_quarter_zip_navy", category="Clothes", slot="uniformTop", name="ABVM Store 1/4-Zip • Navy", price=104, retailUSD=26, tier=1, style=53, color={28,48,72}, description="Official ABVM school-store quarter-zip pullover in navy."},
    {id="abvm_store_heather_tee", category="Clothes", slot="uniformTop", name="ABVM Store Heather Tee", price=40, retailUSD=10, tier=1, style=54, color={166,168,170}, description="Official ABVM school-store heather-gray short-sleeve tee."},
    {id="abvm_store_crewneck_heather", category="Clothes", slot="uniformTop", name="ABVM Store Crewneck", price=60, retailUSD=15, tier=1, style=55, color={166,168,170}, description="Official ABVM school-store heather-gray crewneck sweatshirt."},
    {id="abvm_store_hoodie_heather", category="Clothes", slot="uniformTop", name="ABVM Store Pullover Hoodie", price=120, tier=2, style=56, color={166,168,170}, description="ABVM school-store heather-gray pullover hoodie from the supplied reference; retail price was not visible, so only the in-game Credit price is defined."},
    {id="abvm_store_sweatpants_heather", category="Clothes", slot="uniformBottom", name="ABVM Store Sweatpants", price=60, retailUSD=15, tier=1, style=61, color={166,168,170}, description="Official ABVM school-store heather-gray sweatpants."},
    {id="abvm_store_shorts_heather", category="Clothes", slot="uniformBottom", name="ABVM Store Athletic Shorts", price=48, retailUSD=12, tier=1, style=62, color={194,196,198}, description="Official ABVM school-store light-gray athletic shorts."},

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
