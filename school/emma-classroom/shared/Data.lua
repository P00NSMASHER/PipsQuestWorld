--!strict
-- Static personalized classroom staff metadata. Curriculum is generated separately
-- in the server-only QuestionBank module with its exact source receipt.
local Data = {}
Data.PlayerName = "Emma"

Data.Teachers = {
    -- Names/roles transcribed from the supplied labeled directory screenshots.
    {name="Mrs. Benulis", fullName="Mrs. Aimee Benulis", role="Second Grade", shirt={27,40,62}, weight=5, skin={229,194,163}, hair={118,71,44}, hairStyle="shoulder", glasses=false, clothing="cardigan", beard=nil, accent={235,230,213}},
    {name="Mrs. Russek", fullName="Mrs. Karla Russek", role="First Grade", shirt={37,40,46}, weight=2, skin={229,194,163}, hair={182,154,110}, hairStyle="long", glasses=false, clothing="cardigan", beard=nil, accent={235,230,213}},
    {name="Mrs. Kochol", fullName="Mrs. Lucilla Kochol", role="Art / After School", shirt={33,29,35}, weight=2, skin={229,194,163}, hair={170,130,90}, hairStyle="short", glasses=true, clothing="floral", beard=nil, accent={235,230,213}},
    {name="Mr. Bolich", fullName="Mr. David Bolich", role="Technology / PE", shirt={66,91,125}, pants={180,157,122}, weight=2, skin={229,194,163}, hair={181,181,177}, hairStyle="balding", glasses=true, clothing="polo", beard={176,177,177}, accent={235,230,213}},
    {name="Mrs. Boyer", fullName="Mrs. Carol Boyer", role="President of Catholicity and Mission", shirt={32,34,41}, weight=2, skin={229,194,163}, hair={202,180,138}, hairStyle="bob", glasses=false, clothing="blazer", beard=nil, accent={215,204,232}},
    {name="Mrs. Thompson", fullName="Mrs. Melissa Thompson", role="Administrative Assistant / Marketing", shirt={29,38,58}, weight=1, skin={229,194,163}, hair={210,187,132}, hairStyle="long", glasses=false, clothing="cardigan", beard=nil, accent={235,230,213}},
    {name="Dr. McBreen", fullName="Dr. Carl McBreen", role="Principal", shirt={34,42,62}, weight=1, skin={229,194,163}, hair={151,153,150}, hairStyle="short", glasses=false, clothing="suit", beard=nil, accent={166,192,225}},
    {name="Mrs. Campion", fullName="Mrs. Cindy Campion", role="Kindergarten", shirt={42,64,52}, weight=1, skin={229,194,163}, hair={98,62,42}, hairStyle="shoulder", glasses=false, clothing="blouse", beard=nil, accent={235,230,213}},
    {name="Mrs. Lascala", fullName="Mrs. MaryAnn Lascala", role="Kindergarten Aide", shirt={32,31,34}, weight=1, skin={229,194,163}, hair={196,178,138}, hairStyle="bob", glasses=false, clothing="turtleneck", beard=nil, accent={235,230,213}},
    {name="Mrs. Callaghan", fullName="Mrs. Marla Callaghan", role="Third Grade", shirt={144,48,102}, weight=1, skin={229,194,163}, hair={177,137,90}, hairStyle="bob", glasses=true, clothing="floral", beard=nil, accent={235,230,213}},
    {name="Ms. Smith", fullName="Ms. MaryLouise Smith", role="Fourth Grade", shirt={217,203,189}, weight=1, skin={229,194,163}, hair={181,137,86}, hairStyle="short", glasses=false, clothing="pattern", beard=nil, accent={235,230,213}},
    {name="Mrs. Leagans", fullName="Mrs Nicole Leagans", role="Fifth Grade Teacher", shirt={115,39,58}, weight=1, skin={229,194,163}, hair={131,82,47}, hairStyle="long", glasses=false, clothing="pattern", beard=nil, accent={235,230,213}},
    {name="Mr. Yordy", fullName="Mr. Mike Yordy", role="Seventh Grade", shirt={31,32,36}, weight=1, skin={229,194,163}, hair={82,57,43}, hairStyle="short", glasses=false, clothing="polo", beard={82,57,43}, accent={235,230,213}},
    {name="Mrs. Urban", fullName="Mrs. Jacqui Urban", role="Eighth Grade", shirt={236,184,200}, weight=1, skin={229,194,163}, hair={164,167,176}, hairStyle="bob", glasses=true, clothing="striped", beard=nil, accent={235,230,213}},
    {name="Mrs. Paskel", fullName="Mrs. Lyric Paskel", role="6th Grade Teacher", shirt={155,151,150}, weight=1, skin={229,194,163}, hair={38,30,28}, hairStyle="waves", glasses=false, clothing="cardigan", beard=nil, accent={235,230,213}},
    {name="Mrs. Rossi", fullName="Mrs. Sharon Rossi", role="Pre-Kindergarten", shirt={88,126,194}, weight=1, skin={229,194,163}, hair={158,125,83}, hairStyle="shoulder", glasses=false, clothing="blouse", beard=nil, accent={235,230,213}},
    {name="Mrs. Long", fullName="Mrs. Cindy Long", role="Food Service Manager", shirt={37,38,43}, weight=1, skin={229,194,163}, hair={150,116,83}, hairStyle="short", glasses=false, clothing="pattern", beard=nil, accent={235,230,213}},
    {name="Mrs. Heckman", fullName="Mrs. Erin Heckman", role="Pre-Kindergarten", shirt={153,56,53}, weight=1, skin={229,194,163}, hair={204,173,116}, hairStyle="shoulder", glasses=false, clothing="vest", beard=nil, accent={235,230,213}},
}

return Data
