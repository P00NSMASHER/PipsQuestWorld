--!strict
-- Server-owned learning economy. Correct answers build a positive streak;
-- wrong answers build an escalating penalty streak. All mutations are persisted
-- through ProfileStore before the client is told they succeeded.
local Learning = {}

local CORRECT_STREAK_STEP = 2
local CORRECT_STREAK_MAX = 10
local WRONG_PENALTY_BASE = 2
local WRONG_PENALTY_STEP = 2
local WRONG_PENALTY_MAX = 10

local function integer(x)
    return type(x)=="number" and x==x and x>=0 and x<1e12 and x==math.floor(x)
end

function Learning.copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Learning.copy(child) end
    return result
end

function Learning.newProfile()
    return {
        goal="home_cottage",schema=1,revision=0,coins=0,earned=0,lost=0,
        correct=0,answers=0,correctStreak=0,wrongStreak=0,bestCorrectStreak=0,worstWrongStreak=0,
        owned={home_starter=true,vehicle_cart=true},equipped={home="home_starter",vehicle="vehicle_cart"},
        practice={},lesson={},lessonCount=0,receipts={},receiptOrder={}
    }
end

function Learning.normalize(p)
    if type(p)~="table" then return p end
    -- Backward-compatible defaults for profiles created before streaks existed.
    p.lost=p.lost or 0
    p.correct=p.correct or 0
    p.answers=math.max(p.answers or 0,p.correct)
    p.correctStreak=p.correctStreak or 0
    p.wrongStreak=p.wrongStreak or 0
    p.bestCorrectStreak=math.max(p.bestCorrectStreak or 0,p.correctStreak)
    p.worstWrongStreak=math.max(p.worstWrongStreak or 0,p.wrongStreak)
    for _,progress in pairs(p.practice or {}) do
        if type(progress)=="table" then progress.misses=progress.misses or 0 end
    end
    return p
end

function Learning.valid(p)
    if type(p)~="table" or p.schema~=1 then return false end
    Learning.normalize(p)
    for _, key in ipairs({
        "revision","coins","earned","lost","correct","answers","correctStreak","wrongStreak",
        "bestCorrectStreak","worstWrongStreak","lessonCount"
    }) do
        if not integer(p[key]) then return false end
    end
    if p.coins > p.earned or p.lost > p.earned or p.correct > p.answers then return false end
    if p.bestCorrectStreak < p.correctStreak or p.worstWrongStreak < p.wrongStreak then return false end
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

local function streakBonus(streak)
    return math.min(math.max(0,streak-1)*CORRECT_STREAK_STEP,CORRECT_STREAK_MAX)
end

local function wrongPenalty(streak)
    return math.min(WRONG_PENALTY_BASE+math.max(0,streak-1)*WRONG_PENALTY_STEP,WRONG_PENALTY_MAX)
end

function Learning.miss(p,op,question,now)
    Learning.normalize(p)
    if p.receipts[op] then return Learning.copy(p.receipts[op]) end
    assert(integer(now),"server timestamp required")
    local prior=p.practice[question.id]

    p.answers += 1
    p.correctStreak = 0
    p.wrongStreak += 1
    p.worstWrongStreak=math.max(p.worstWrongStreak,p.wrongStreak)

    local penalty=wrongPenalty(p.wrongStreak)
    local deducted=math.min(p.coins,penalty)
    p.coins -= deducted
    p.lost += deducted

    p.practice[question.id]={
        seen=(prior and prior.seen or 0)+1,
        success=(prior and prior.success or 0),
        misses=(prior and prior.misses or 0)+1,
        lastSeen=now,
        lastReward=prior and prior.lastReward or 0,
        due=now+120,
    }

    return Learning.record(p,op,{
        ok=true,kind="miss",penalty=penalty,deducted=deducted,
        wrongStreak=p.wrongStreak,correctStreak=0,total=-deducted
    })
end

function Learning.reward(p, op, question, firstTry, now)
    Learning.normalize(p)
    if p.receipts[op] then return Learning.copy(p.receipts[op]) end
    assert(integer(now), "server timestamp required")
    local prior = p.practice[question.id]
    local reward = 0
    -- Revisiting helps learning; replaying the same item immediately is not a mint.
    if not prior or now - (prior.lastReward or 0) >= 600 then
        reward = firstTry and 10 or 6
    end

    p.answers += 1
    p.correct += 1
    p.wrongStreak = 0
    if reward>0 then
        p.correctStreak += 1
        p.bestCorrectStreak=math.max(p.bestCorrectStreak,p.correctStreak)
    end

    p.practice[question.id] = {
        seen=(prior and prior.seen or 0)+1,
        success=(prior and prior.success or 0)+(firstTry and 1 or 0),
        misses=(prior and prior.misses or 0),
        lastSeen=now,
        lastReward=reward>0 and now or (prior and prior.lastReward or 0),
        due=now+(firstTry and math.min(86400,600*2^math.min(7,prior and prior.success or 0)) or 120),
    }

    local bonus = 0
    if reward > 0 and not p.lesson[question.id] then
        p.lesson[question.id] = true
        p.lessonCount += 1
        if p.lessonCount == 5 then
            bonus=15
            p.lesson={}
            p.lessonCount=0
        end
    end

    local streak=reward>0 and streakBonus(p.correctStreak) or 0
    p.coins += reward+bonus+streak
    p.earned += reward+bonus+streak

    return Learning.record(p,op,{
        ok=true,kind="reward",coins=reward,bonus=bonus,streakBonus=streak,total=reward+bonus+streak,
        reviewOnly=reward==0,firstTry=firstTry,correctStreak=p.correctStreak,wrongStreak=0
    })
end

function Learning.purchase(p, op, item)
    Learning.normalize(p)
    if p.receipts[op] then return Learning.copy(p.receipts[op]) end
    if not item or not integer(item.price) then return {ok=false,code="unknown_item"} end
    if p.owned[item.id] then return {ok=true,code="already_owned",itemId=item.id} end
    if p.coins < item.price then return {ok=false,code="not_enough_coins",missing=item.price-p.coins} end
    p.coins -= item.price
    p.owned[item.id] = true
    return Learning.record(p,op,{ok=true,kind="purchase",itemId=item.id,spent=item.price})
end

function Learning.equip(p, op, item)
    Learning.normalize(p)
    if not item or not p.owned[item.id] then return {ok=false,code="not_owned"} end
    local slots={Homes="home",Vehicles="vehicle",Clothes="outfit"}
    local slot=slots[item.category]
    if slot then p.equipped[slot]=item.id end
    -- Furnishings are automatically placed; ownership is the persisted state.
    return Learning.record(p,op,{ok=true,kind="equip",itemId=item.id})
end

function Learning.choose(p, questions, subject, now, lastId)
    Learning.normalize(p)
    local selected, best = nil, -math.huge
    for _, q in ipairs(questions) do
        if q.subject == subject then
            local progress=p.practice[q.id]
            local priority=not progress and 100000 or (progress.due <= now and 50000 or 0)
            priority += (progress and progress.misses or 0)*350
            priority -= (progress and progress.lastSeen or 0) / 1e8
            priority -= q.id==lastId and 200000 or 0
            if priority > best then selected=q; best=priority end
        end
    end
    return selected
end

function Learning.accuracyBasisPoints(p)
    Learning.normalize(p)
    if p.answers<=0 then return 0 end
    return math.floor((p.correct*10000/p.answers)+0.5)
end

function Learning.public(p)
    Learning.normalize(p)
    return {
        goal=p.goal or "home_cottage",coins=p.coins,earned=p.earned,lost=p.lost,
        correct=p.correct,answers=p.answers,accuracyBasisPoints=Learning.accuracyBasisPoints(p),
        correctStreak=p.correctStreak,wrongStreak=p.wrongStreak,
        bestCorrectStreak=p.bestCorrectStreak,worstWrongStreak=p.worstWrongStreak,
        lessonCount=p.lessonCount,owned=Learning.copy(p.owned),equipped=Learning.copy(p.equipped),revision=p.revision
    }
end

Learning.CORRECT_STREAK_STEP=CORRECT_STREAK_STEP
Learning.CORRECT_STREAK_MAX=CORRECT_STREAK_MAX
Learning.WRONG_PENALTY_BASE=WRONG_PENALTY_BASE
Learning.WRONG_PENALTY_STEP=WRONG_PENALTY_STEP
Learning.WRONG_PENALTY_MAX=WRONG_PENALTY_MAX

return Learning
