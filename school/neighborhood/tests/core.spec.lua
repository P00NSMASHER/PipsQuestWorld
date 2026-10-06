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
    a.owned.outfit_coral=true;assert(not b.owned.outfit_coral)
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
    equal(#Bank.Questions,51)
    for _,subject in ipairs(Catalog.Subjects) do assert(subjects[subject.id]>=10) end
end)
test("first try and correction rewards retain canonical 25/15 split",function()
    local a,b=Learning.newProfile(),Learning.newProfile();local q=first("math")
    equal(Learning.reward(a,"one",q,true,1000).total,25)
    equal(Learning.reward(b,"two",q,false,1000).total,15)
end)
test("a duplicate completion never doubles coins or lesson progress",function()
    local p=Learning.newProfile();local q=first("math")
    local firstResult=Learning.reward(p,"stable-operation",q,true,1000)
    local again=Learning.reward(p,"stable-operation",q,true,1001)
    equal(again.total,firstResult.total);equal(p.coins,25);equal(p.correct,1);equal(p.lessonCount,1)
end)
test("new operation id does not farm an immediate repeated question",function()
    local p=Learning.newProfile();local q=first("math")
    Learning.reward(p,"one",q,true,1000)
    local repeatResult=Learning.reward(p,"two",q,true,1002)
    equal(repeatResult.total,0);assert(repeatResult.reviewOnly);equal(p.coins,25);equal(p.lessonCount,1)
end)
test("a later spaced review earns coins again",function()
    local p=Learning.newProfile();local q=first("math")
    Learning.reward(p,"one",q,true,1000)
    equal(Learning.reward(p,"two",q,true,1600).total,25)
end)
test("five different paid questions award one 50-coin lesson bonus",function()
    local p=Learning.newProfile();local bonus=0
    for i=1,5 do bonus+=Learning.reward(p,"q"..i,Bank.Questions[i],true,1000+i).bonus end
    equal(bonus,50);equal(p.coins,175);equal(p.lessonCount,0)
end)
test("six first-try answers buy a cottage with change",function()
    local p=Learning.newProfile()
    for i=1,6 do Learning.reward(p,"q"..i,Bank.Questions[i],true,1000+i) end
    equal(p.coins,200)
    assert(Learning.purchase(p,"buy-cottage",Catalog.ById.home_cottage).ok)
    equal(p.coins,20);assert(p.owned.home_cottage);equal(p.earned,200)
end)
test("prices come from catalog and no purchase can go negative",function()
    local p=Learning.newProfile()
    assert(not Learning.purchase(p,"x",Catalog.ById.home_estate).ok);equal(p.coins,0)
    assert(not Learning.purchase(p,"y",nil).ok)
    assert(not Learning.purchase(p,"z",{id="bad",price=-1}).ok)
end)
test("retrying a purchase with even a different id cannot charge twice",function()
    local p=Learning.newProfile()
    for i=1,6 do Learning.reward(p,"q"..i,Bank.Questions[i],true,1000+i) end
    Learning.purchase(p,"buy",Catalog.ById.outfit_coral)
    equal(p.coins,140)
    Learning.purchase(p,"buy-again",Catalog.ById.outfit_coral)
    equal(p.coins,140)
end)
test("unowned item cannot be equipped",function()
    local p=Learning.newProfile();assert(not Learning.equip(p,"equip",Catalog.ById.home_estate).ok)
    equal(p.equipped.home,"home_starter")
end)
test("owning an estate never increases per-question income",function()
    local p=Learning.newProfile();p.owned.home_estate=true;p.equipped.home="home_estate"
    equal(Learning.reward(p,"one",first("reading"),true,1000).total,25)
end)
test("question selection is subject-scoped and avoids immediate repeat",function()
    local p=Learning.newProfile();local q=Learning.choose(p,Bank.Questions,"reading",1000,nil)
    equal(q.subject,"reading");local next=Learning.choose(p,Bank.Questions,"reading",1001,q.id);assert(next.id~=q.id)
    equal(Learning.choose(p,Bank.Questions,"unknown",1000,nil),nil)
end)
test("mistake corrections are reviewed earlier than first-try mastery",function()
    local a,b=Learning.newProfile(),Learning.newProfile();local q=first("religion")
    Learning.reward(a,"one",q,true,1000);Learning.reward(b,"two",q,false,1000)
    assert(a.practice[q.id].due>b.practice[q.id].due)
end)
test("public snapshot does not expose answer keys or receipts",function()
    local p=Learning.newProfile();Learning.reward(p,"q",first("math"),true,1000)
    local snapshot=Learning.public(p)
    equal(snapshot.practice,nil);equal(snapshot.receipts,nil);equal(snapshot.answer,nil)
    snapshot.owned.home_estate=true;assert(not p.owned.home_estate)
end)
test("receipt memory is bounded and profiles remain valid",function()
    local p=Learning.newProfile()
    for i=1,200 do Learning.reward(p,"q"..i,Bank.Questions[(i-1)%#Bank.Questions+1],i%2==0,1000+i*601) end
    equal(#p.receiptOrder,96);assert(Learning.valid(p))
end)
test("corrupt balances fail validation",function()
    local p=Learning.newProfile();p.coins=-1;assert(not Learning.valid(p))
    p.coins=math.huge;assert(not Learning.valid(p))
    p.coins=0/0;assert(not Learning.valid(p))
end)
test("catalog ids and prices are valid; every category has a progression",function()
    local seen={};local categories={}
    for _,item in ipairs(Catalog.Items) do
        assert(not seen[item.id]);seen[item.id]=true
        assert(item.price>=0 and item.price%1==0);assert(item.tier>=1 and item.tier<=#Catalog.Tiers)
        categories[item.category]=(categories[item.category] or 0)+1
    end
    for _,category in ipairs({"Homes","Clothes","Items","Vehicles"}) do assert(categories[category]>=4) end
end)
test("layout remains inside iPhone, iPad and desktop safe canvases",function()
    for _,v in ipairs({{758,360},{720,320},{852,393},{350,760},{320,568},{976,724},{1366,700}}) do
        local l=Layout.compute(v[1],v[2]);local r=l.modal
        assert(r.x>=0 and r.y>=l.headerHeight and r.x+r.width<=v[1] and r.y+r.height<=v[2])
        assert(l.answerHeight>=48)
    end
end)
print("NEIGHBORHOOD_CORE_TESTS_PASS "..count)
