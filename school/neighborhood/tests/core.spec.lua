local Learning=require("../server/Learning")
local Bank=require("../server/QuestionBank")
local Catalog=require("../shared/Catalog")
local Layout=require("../shared/Layout")
local count=0
local function test(name,fn)
    fn();count+=1;print("PASS "..name)
end
local function equal(a,b) assert(a==b,tostring(a).." != "..tostring(b)) end
local function first(subject)
    for _,q in ipairs(Bank.Questions) do if q.subject==subject then return q end end
end
test("every player begins with a free house and vehicle",function()
    local a,b=Learning.newProfile(),Learning.newProfile()
    assert(Learning.valid(a));equal(a.coins,0);assert(a.owned.home_starter);assert(a.owned.vehicle_cart)
    equal(a.correctStreak,0);equal(a.wrongStreak,0);equal(a.answers,0)
    a.owned.outfit_coral=true;assert(not b.owned.outfit_coral)
end)
test("old profiles normalize safely into streak fields",function()
    local p=Learning.newProfile()
    p.lost=nil;p.correctStreak=nil;p.wrongStreak=nil;p.bestCorrectStreak=nil;p.worstWrongStreak=nil
    Learning.normalize(p)
    equal(p.lost,0);equal(p.correctStreak,0);equal(p.wrongStreak,0)
    assert(Learning.valid(p))
end)
test("ABVM source is pinned and every question has one unique valid answer",function()
    equal(Bank.Source.commit,"aa2fe3fbcb9b25205948073ee284b96910733d79")
    local ids,subjects={},{}
    for _,q in ipairs(Bank.Questions) do
        assert(not ids[q.id]);ids[q.id]=true
        assert(type(q.prompt)=="string" and #q.prompt>5);assert(#q.choices>=3 and #q.choices<=4)
        assert(type(q.answer)=="number" and q.answer>=1 and q.answer<=#q.choices)
        local choices={};for _,c in ipairs(q.choices) do assert(not choices[c]);choices[c]=true end
        assert(type(q.explanation)=="string" and #q.explanation>5)
        subjects[q.subject]=(subjects[q.subject] or 0)+1
    end
    equal(#Bank.Questions,338)
    for _,subject in ipairs(Catalog.Subjects) do assert(subjects[subject.id]>=10);assert(type(subject.teacher)=="string" and #subject.teacher>3) end
end)
test("first try and correction bases use the tuned 10/6 split",function()
    local a,b=Learning.newProfile(),Learning.newProfile();local q=first("math")
    local firstTry=Learning.reward(a,"one",q,true,1000)
    local correction=Learning.reward(b,"two",q,false,1000)
    equal(firstTry.coins,10);equal(firstTry.streakBonus,0);equal(firstTry.total,10)
    equal(correction.coins,6);equal(correction.streakBonus,0);equal(correction.total,6)
end)
test("correct streak bonuses progress by two and cap at ten",function()
    local p=Learning.newProfile()
    local expected={0,2,4,6,8,10,10,10}
    for i,want in ipairs(expected) do
        local result=Learning.reward(p,"right"..i,Bank.Questions[i],true,1000+i)
        equal(result.streakBonus,want);equal(result.correctStreak,i)
    end
    equal(p.correctStreak,#expected);equal(p.bestCorrectStreak,#expected)
end)
test("wrong penalties progress by two and cap at ten",function()
    local p=Learning.newProfile();p.coins=200;p.earned=200
    local q=first("math")
    local expected={2,4,6,8,10,10,10}
    local spent=0
    for i,want in ipairs(expected) do
        local result=Learning.miss(p,"miss"..i,q,1000+i)
        equal(result.penalty,want);equal(result.deducted,want);equal(result.wrongStreak,i)
        spent+=want
    end
    equal(p.coins,200-spent);equal(p.lost,spent);equal(p.worstWrongStreak,#expected)
end)
test("wrong penalties never push the wallet below zero",function()
    local p=Learning.newProfile();p.coins=7;p.earned=7
    local q=first("math")
    equal(Learning.miss(p,"m1",q,1000).deducted,2)
    equal(Learning.miss(p,"m2",q,1001).deducted,4)
    equal(Learning.miss(p,"m3",q,1002).deducted,1)
    equal(p.coins,0);equal(p.lost,7);assert(Learning.valid(p))
end)
test("wrong answer breaks positive streak and correct answer breaks negative streak",function()
    local p=Learning.newProfile()
    Learning.reward(p,"r1",Bank.Questions[1],true,1000)
    Learning.reward(p,"r2",Bank.Questions[2],true,1001)
    equal(p.correctStreak,2)
    Learning.miss(p,"m1",Bank.Questions[3],1002)
    equal(p.correctStreak,0);equal(p.wrongStreak,1)
    local result=Learning.reward(p,"r3",Bank.Questions[3],false,1003)
    equal(result.streakBonus,0);equal(p.correctStreak,1);equal(p.wrongStreak,0)
end)
test("accuracy uses all saved attempts",function()
    local p=Learning.newProfile();local q=first("reading")
    Learning.reward(p,"r1",q,true,1000)
    Learning.miss(p,"m1",q,1001)
    Learning.reward(p,"r2",q,false,1002)
    equal(p.correct,2);equal(p.answers,3)
    equal(Learning.accuracyBasisPoints(p),6667)
end)
test("duplicate correct completion never doubles coins or lesson progress",function()
    local p=Learning.newProfile();local q=first("math")
    local firstResult=Learning.reward(p,"stable-operation",q,true,1000)
    local again=Learning.reward(p,"stable-operation",q,true,1001)
    equal(again.total,firstResult.total);equal(p.coins,10);equal(p.correct,1);equal(p.answers,1)
    equal(p.lessonCount,1);equal(p.correctStreak,1)
end)
test("duplicate miss receipt never doubles a penalty",function()
    local p=Learning.newProfile();p.coins=50;p.earned=50;local q=first("math")
    local firstMiss=Learning.miss(p,"stable-miss",q,1000)
    local again=Learning.miss(p,"stable-miss",q,1001)
    equal(firstMiss.deducted,2);equal(again.deducted,2)
    equal(p.coins,48);equal(p.answers,1);equal(p.wrongStreak,1)
end)
test("new operation id does not farm an immediate repeated question",function()
    local p=Learning.newProfile();local q=first("math")
    Learning.reward(p,"one",q,true,1000)
    local repeatResult=Learning.reward(p,"two",q,true,1002)
    equal(repeatResult.total,0);assert(repeatResult.reviewOnly);equal(p.coins,10);equal(p.lessonCount,1)
    equal(p.correctStreak,1)
end)
test("a later spaced review earns base plus current streak bonus",function()
    local p=Learning.newProfile();local q=first("math")
    Learning.reward(p,"one",q,true,1000)
    local review=Learning.reward(p,"two",q,true,1600)
    equal(review.coins,10);equal(review.streakBonus,2);equal(review.total,12)
end)
test("five different paid questions award streaks plus one lesson bonus",function()
    local p=Learning.newProfile();local bonus=0;local streak=0
    for i=1,5 do
        local result=Learning.reward(p,"q"..i,Bank.Questions[i],true,1000+i)
        bonus+=result.bonus;streak+=result.streakBonus
    end
    equal(streak,20);equal(bonus,15);equal(p.coins,85);equal(p.lessonCount,0)
end)
test("twenty first-try answers buy a cottage with change",function()
    local p=Learning.newProfile()
    for i=1,20 do Learning.reward(p,"q"..i,Bank.Questions[i],true,1000+i) end
    equal(p.coins,430)
    assert(Learning.purchase(p,"buy-cottage",Catalog.ById.home_cottage).ok)
    equal(p.coins,30);assert(p.owned.home_cottage);equal(p.earned,430)
end)
test("home ladder has deliberate perfect-play pacing",function()
    local function earnedAfter(n)
        local p=Learning.newProfile()
        for i=1,n do Learning.reward(p,"pace"..i,Bank.Questions[(i-1)%#Bank.Questions+1],true,1000+i*601) end
        return p.coins
    end
    assert(earnedAfter(19)<400);assert(earnedAfter(20)>=400)
    assert(earnedAfter(66)<1500);assert(earnedAfter(67)>=1500)
    assert(earnedAfter(197)<4500);assert(earnedAfter(198)>=4500)
    assert(earnedAfter(523)<12000);assert(earnedAfter(524)>=12000)
end)
test("prices come from catalog and no purchase can go negative",function()
    local p=Learning.newProfile()
    assert(not Learning.purchase(p,"x",Catalog.ById.home_estate).ok);equal(p.coins,0)
    assert(not Learning.purchase(p,"y",nil).ok)
    assert(not Learning.purchase(p,"z",{id="bad",price=-1}).ok)
end)
test("retrying a purchase with even a different id cannot charge twice",function()
    local p=Learning.newProfile();p.coins=100;p.earned=100
    Learning.purchase(p,"buy",Catalog.ById.outfit_coral)
    equal(p.coins,50)
    Learning.purchase(p,"buy-again",Catalog.ById.outfit_coral)
    equal(p.coins,50)
end)
test("unowned item cannot be equipped",function()
    local p=Learning.newProfile();assert(not Learning.equip(p,"equip",Catalog.ById.home_estate).ok)
    equal(p.equipped.home,"home_starter")
end)
test("owning an estate never increases first-question income",function()
    local p=Learning.newProfile();p.owned.home_estate=true;p.equipped.home="home_estate"
    equal(Learning.reward(p,"one",first("reading"),true,1000).total,10)
end)
test("question selection is subject-scoped and avoids immediate repeat",function()
    local p=Learning.newProfile();local q=Learning.choose(p,Bank.Questions,"reading",1000,nil)
    equal(q.subject,"reading");local next=Learning.choose(p,Bank.Questions,"reading",1001,q.id);assert(next.id~=q.id)
    equal(Learning.choose(p,Bank.Questions,"unknown",1000,nil),nil)
end)
test("mistakes are prioritized and reviewed earlier",function()
    local a,b=Learning.newProfile(),Learning.newProfile();local qa=first("religion");local qb=first("math")
    Learning.reward(a,"one",qa,true,1000)
    Learning.miss(b,"two",qb,1000)
    assert(a.practice[qa.id].due>b.practice[qb.id].due)
end)
test("public snapshot exposes stats but not answer keys or receipts",function()
    local p=Learning.newProfile();Learning.reward(p,"q",first("math"),true,1000)
    local snapshot=Learning.public(p)
    equal(snapshot.practice,nil);equal(snapshot.receipts,nil);equal(snapshot.answer,nil)
    equal(snapshot.correct,1);equal(snapshot.answers,1);equal(snapshot.accuracyBasisPoints,10000)
    equal(snapshot.correctStreak,1);equal(snapshot.wrongStreak,0)
    snapshot.owned.home_estate=true;assert(not p.owned.home_estate)
end)
test("receipt memory is bounded and profiles remain valid",function()
    local p=Learning.newProfile()
    for i=1,200 do
        if i%4==0 then
            Learning.miss(p,"m"..i,Bank.Questions[(i-1)%#Bank.Questions+1],1000+i*601)
        else
            Learning.reward(p,"q"..i,Bank.Questions[(i-1)%#Bank.Questions+1],i%2==0,1000+i*601)
        end
    end
    equal(#p.receiptOrder,96);assert(Learning.valid(p))
end)
test("corrupt balances fail validation while legacy statistics normalize",function()
    local p=Learning.newProfile();p.coins=-1;assert(not Learning.valid(p))
    p=Learning.newProfile();p.coins=math.huge;assert(not Learning.valid(p))
    p=Learning.newProfile();p.coins=0/0;assert(not Learning.valid(p))
    p=Learning.newProfile();p.lost=1;p.earned=0;assert(not Learning.valid(p))
    p=Learning.newProfile();p.correct=2;p.answers=1;assert(Learning.valid(p));equal(p.answers,2)
end)
test("catalog ids and prices are valid; every category has a progression",function()
    local seen={};local categories={}
    for _,item in ipairs(Catalog.Items) do
        assert(not seen[item.id]);seen[item.id]=true
        assert(item.price>=0 and item.price%1==0);assert(item.tier>=1 and item.tier<=#Catalog.Tiers)
        categories[item.category]=(categories[item.category] or 0)+1
    end
    for _,category in ipairs({"Homes","Clothes","Items","Vehicles"}) do assert(categories[category]>=4) end

    local homes={"home_starter","home_cottage","home_suburban","home_villa","home_estate"}
    local homePrices={0,400,1500,4500,12000}
    for i,id in ipairs(homes) do
        local item=Catalog.ById[id]
        assert(item and item.category=="Homes")
        equal(item.price,homePrices[i]);equal(item.style,i)
        if i>1 then assert(item.price>Catalog.ById[homes[i-1]].price) end
    end
    equal(Catalog.ById.vehicle_cart.price,0)
    equal(Catalog.ById.vehicle_hatch.price,900)
    equal(Catalog.ById.vehicle_sport.price,2400)
    equal(Catalog.ById.vehicle_luxe.price,6500)
    equal(Catalog.ById.outfit_abvm_polo.price,25)
    equal(Catalog.ById.outfit_abvm_polo.style,6)
    equal(Catalog.ById.outfit_abvm_plaid.price,75)
    equal(Catalog.ById.outfit_abvm_plaid.style,7)

    local retail={
        abvm_store_polo_green=15,abvm_store_polo_navy=15,
        abvm_store_ls_polo_green=17,abvm_store_ls_polo_navy=17,
        abvm_store_quarter_zip_navy=26,abvm_store_heather_tee=10,
        abvm_store_crewneck_heather=15,abvm_store_sweatpants_heather=15,
        abvm_store_shorts_heather=12,
    }
    for id,usd in pairs(retail) do
        local item=Catalog.ById[id]
        assert(item and item.category=="Clothes")
        equal(item.retailUSD,usd);equal(item.price,usd*4)
        assert(item.slot=="uniformTop" or item.slot=="uniformBottom")
        assert(not string.find(item.name,"Youth") and not string.find(item.name,"Adult"))
    end
    equal(Catalog.ById.abvm_store_polo_green.style,51)
    equal(Catalog.ById.abvm_store_ls_polo_navy.style,52)
    equal(Catalog.ById.abvm_store_quarter_zip_navy.style,53)
    equal(Catalog.ById.abvm_store_heather_tee.style,54)
    equal(Catalog.ById.abvm_store_crewneck_heather.style,55)
    equal(Catalog.ById.abvm_store_sweatpants_heather.style,61)
    equal(Catalog.ById.abvm_store_shorts_heather.style,62)
    local hoodie=Catalog.ById.abvm_store_hoodie_heather
    assert(hoodie and hoodie.slot=="uniformTop" and hoodie.retailUSD==nil)
end)
test("mix-and-match ABVM uniform pieces equip independently",function()
    local p=Learning.newProfile();p.coins=500;p.earned=500
    local ids={"uniform_top_green_polo","uniform_bottom_plaid_skirt","uniform_socks_navy","uniform_shoes_brown"}
    local slots={"uniformTop","uniformBottom","uniformLegwear","uniformShoes"}
    for i,id in ipairs(ids) do
        local item=Catalog.ById[id];assert(item and item.slot==slots[i])
        assert(Learning.purchase(p,"buy-"..id,item).ok)
        assert(Learning.equip(p,"equip-"..id,item).ok)
        equal(p.equipped[slots[i]],id)
    end
    assert(p.equipped.home=="home_starter" and p.equipped.vehicle=="vehicle_cart")
end)
test("layout remains inside gold-standard iPhone, iPad and desktop safe canvases",function()
    for _,v in ipairs({{1112,512},{852,393},{758,360},{720,320},{350,760},{320,568},{976,724},{1366,700}}) do
        local l=Layout.compute(v[1],v[2]);local r=l.modal
        assert(r.x>=0 and r.y>=l.headerHeight and r.x+r.width<=v[1] and r.y+r.height<=v[2])
        assert(l.rail.x>=0 and l.rail.y>=0 and l.rail.x+l.rail.width<=v[1])
        assert(l.goal.x>=0 and l.goal.x+l.goal.width<=v[1])
        assert(l.answerHeight>=48)
        assert(l.drive.width>=88 and l.drive.height>=160)
        if v[1]>=720 and v[1]>=v[2] then
            assert(l.headerHeight/v[2]<=.20)
            assert(l.columns==2)
        end
    end
end)
print("NEIGHBORHOOD_CORE_TESTS_PASS "..count)
