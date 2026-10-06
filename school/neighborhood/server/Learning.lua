--!strict
-- Pure, server-owned progression. Inspired by the existing ProgressionBinding's
-- first-try/retry rewards and EconomyRepository's serialized idempotent operations.
local Learning = {}
local function integer(x) return type(x)=="number" and x==x and x>=0 and x<1e12 and x==math.floor(x) end
function Learning.copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Learning.copy(child) end
    return result
end
function Learning.newProfile()
    return {goal="home_cottage",schema=1, revision=0, coins=0, earned=0, correct=0, answers=0,
        owned={home_starter=true,vehicle_cart=true}, equipped={home="home_starter",vehicle="vehicle_cart"},
        practice={}, lesson={}, lessonCount=0, receipts={}, receiptOrder={}}
end
function Learning.valid(p)
    if type(p)~="table" or p.schema~=1 then return false end
    for _, key in ipairs({"revision","coins","earned","correct","answers","lessonCount"}) do
        if not integer(p[key]) then return false end
    end
    if p.coins > p.earned then return false end
    for _, key in ipairs({"owned","equipped","practice","lesson","receipts","receiptOrder"}) do
        if type(p[key])~="table" then return false end
    end
    return p.owned.home_starter==true and p.owned.vehicle_cart==true
end
function Learning.record(p, operation, result)
    p.revision += 1
    p.receipts[operation] = Learning.copy(result)
    table.insert(p.receiptOrder, operation)
    if #p.receiptOrder > 96 then
        p.receipts[table.remove(p.receiptOrder,1)] = nil
    end
    return result
end
function Learning.reward(p, op, question, firstTry, now)
    if p.receipts[op] then return Learning.copy(p.receipts[op]) end
    assert(integer(now), "server timestamp required")
    local prior = p.practice[question.id]
    local reward = 0
    -- Revisiting helps learning; replaying the same item immediately is not a mint.
    if not prior or now - prior.lastReward >= 600 then
        reward = firstTry and 25 or 15
    end
    p.answers += 1
    p.correct += 1
    p.practice[question.id] = {
        seen=(prior and prior.seen or 0)+1,
        success=(prior and prior.success or 0)+(firstTry and 1 or 0),
        lastSeen=now, lastReward=reward>0 and now or (prior and prior.lastReward or 0),
        due=now+(firstTry and math.min(86400,600*2^math.min(7,prior and prior.success or 0)) or 120),
    }
    local bonus = 0
    if reward > 0 and not p.lesson[question.id] then
        p.lesson[question.id] = true
        p.lessonCount += 1
        if p.lessonCount == 5 then
            bonus=50
            p.lesson={}
            p.lessonCount=0
        end
    end
    p.coins += reward+bonus
    p.earned += reward+bonus
    return Learning.record(p,op,{ok=true,kind="reward",coins=reward,bonus=bonus,total=reward+bonus,
        reviewOnly=reward==0,firstTry=firstTry})
end
function Learning.purchase(p, op, item)
    if p.receipts[op] then return Learning.copy(p.receipts[op]) end
    if not item or not integer(item.price) then return {ok=false,code="unknown_item"} end
    if p.owned[item.id] then return {ok=true,code="already_owned",itemId=item.id} end
    if p.coins < item.price then return {ok=false,code="not_enough_coins",missing=item.price-p.coins} end
    p.coins -= item.price
    p.owned[item.id] = true
    return Learning.record(p,op,{ok=true,kind="purchase",itemId=item.id,spent=item.price})
end
function Learning.equip(p, op, item)
    if not item or not p.owned[item.id] then return {ok=false,code="not_owned"} end
    local slots={Homes="home",Vehicles="vehicle",Clothes="outfit"}
    local slot=slots[item.category]
    if slot then p.equipped[slot]=item.id end
    -- Furnishings are automatically placed; ownership is the persisted state.
    return Learning.record(p,op,{ok=true,kind="equip",itemId=item.id})
end
function Learning.choose(p, questions, subject, now, lastId)
    local selected, best = nil, -math.huge
    for _, q in ipairs(questions) do
        if q.subject == subject then
            local progress=p.practice[q.id]
            local priority=not progress and 100000 or (progress.due <= now and 50000 or 0)
            priority -= (progress and progress.lastSeen or 0) / 1e8
            priority -= q.id==lastId and 200000 or 0
            if priority > best then selected=q; best=priority end
        end
    end
    return selected
end
function Learning.public(p)
    return {goal=p.goal or "home_cottage",coins=p.coins,earned=p.earned,correct=p.correct,lessonCount=p.lessonCount,
        owned=Learning.copy(p.owned),equipped=Learning.copy(p.equipped),revision=p.revision}
end
return Learning
