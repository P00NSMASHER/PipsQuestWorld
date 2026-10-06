--!strict
-- One shared, fixed-price catalog. Server alone changes balances and ownership.
local Catalog = {}
Catalog.Subjects = {
    {id = "math", name = "Math", short = "Math", teacher = "Mrs. Campion", color = {62, 154, 214}},
    {id = "reading", name = "Reading / ELA", short = "Reading", teacher = "Mrs. Russek", color = {125, 103, 202}},
    {id = "spelling", name = "Spelling / Handwriting", short = "Spelling", teacher = "Mrs. Kochol", color = {51, 158, 129}},
    {id = "religion", name = "Religion", short = "Religion", teacher = "Mr. Bolich", color = {196, 147, 58}},
}
Catalog.Tiers = {
    {name = "Starting out", earned = 0}, {name = "Finding your style", earned = 300},
    {name = "Moving up", earned = 1200}, {name = "Living well", earned = 3600},
    {name = "Dream life", earned = 9000},
}
Catalog.Items = {
    {id="home_starter", category="Homes", name="First home", price=0, tier=1, style=1, color={225,220,206}, description="Your own furnished home, from the start."},
    {id="home_cottage", category="Homes", name="Garden cottage", price=180, tier=2, style=2, color={180,213,202}, description="A wider home, porch, shutters and a flower garden."},
    {id="home_villa", category="Homes", name="Modern villa", price=1100, tier=3, style=3, color={231,236,239}, description="Wide windows, a larger living room and a terrace."},
    {id="home_estate", category="Homes", name="Dream estate", price=5200, tier=5, style=4, color={238,231,216}, description="A generous home with a balcony, gold details and a garden."},
    {id="outfit_coral", category="Clothes", name="Coral sweatshirt", price=60, tier=1, style=1, color={227,128,126}, description="A cozy wearable sweatshirt over your avatar."},
    {id="outfit_ocean", category="Clothes", name="Ocean sweatshirt", price=60, tier=1, style=1, color={70,158,183}, description="Same price, your favorite color. No wealth bonus."},
    {id="outfit_varsity", category="Clothes", name="Varsity jacket", price=240, tier=2, style=2, color={57,84,124}, description="A navy jacket with cream sleeves and a school stripe."},
    {id="outfit_rose", category="Clothes", name="Rose varsity", price=240, tier=2, style=2, color={173,105,149}, description="The varsity look in rose, with cream sleeves."},
    {id="outfit_signature", category="Clothes", name="Signature jacket", price=1250, tier=4, style=3, color={46,58,78}, description="Dark tailoring with a gold trim. Earned, never pay-to-win."},
    {id="item_rug", category="Items", name="Sunrise rug", price=35, tier=1, style=1, color={220,178,112}, description="A warm rug for your living room."},
    {id="item_lamp", category="Items", name="Reading lamp", price=80, tier=1, style=2, color={224,192,115}, description="A soft light next to your sofa."},
    {id="item_books", category="Items", name="Bookshelf", price=160, tier=2, style=3, color={150,112,79}, description="A real shelf of colorful books inside your home."},
    {id="item_backpack", category="Items", name="Campus backpack", price=120, tier=2, style=4, color={68,156,155}, description="A wearable backpack for your school trips."},
    {id="item_sofa", category="Items", name="Velvet sofa", price=650, tier=3, style=5, color={111,145,135}, description="Upgrade the couch in your living room."},
    {id="item_fountain", category="Items", name="Garden fountain", price=1800, tier=4, style=6, color={211,219,220}, description="A blue-water fountain in your front garden."},
    {id="vehicle_cart", category="Vehicles", name="Neighborhood cart", price=0, tier=1, style=1, speed=24, color={189,204,199}, description="Your free starter ride. Walk or drive to school."},
    {id="vehicle_hatch", category="Vehicles", name="City hatchback", price=420, tier=2, style=2, speed=34, color={70,151,184}, description="A compact car with a painted roof and alloy wheels."},
    {id="vehicle_sport", category="Vehicles", name="Sport coupe", price=1800, tier=4, style=3, speed=40, color={198,101,101}, description="A low roof, sport stripes and a quicker drive."},
    {id="vehicle_luxe", category="Vehicles", name="Signature sedan", price=4500, tier=5, style=4, speed=40, color={50,61,78}, description="A long, polished sedan with gold accents."},
}
Catalog.ById = {}
for _, item in ipairs(Catalog.Items) do
    assert(Catalog.ById[item.id] == nil, "duplicate catalog id")
    Catalog.ById[item.id] = item
end
function Catalog.tier(earned)
    local index = 1
    for i, tier in ipairs(Catalog.Tiers) do if earned >= tier.earned then index = i end end
    return index, Catalog.Tiers[index], Catalog.Tiers[index+1]
end
return Catalog
