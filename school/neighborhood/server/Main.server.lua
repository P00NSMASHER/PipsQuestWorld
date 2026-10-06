--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local Catalog=require(ReplicatedStorage.NeighborhoodShared.Catalog)
local Bank=require(script.Parent.QuestionBank)
local Learning=require(script.Parent.Learning)
local ProfileStore=require(script.Parent.ProfileStore)
local World=require(script.Parent.World).build()
local Garage=require(script.Parent.Garage)
local Wardrobe=require(script.Parent.Wardrobe)
local Leaderboards=require(script.Parent.Leaderboards)
local store=ProfileStore.new()
local leaderboards=Leaderboards.new()
local leaderboardQueued={}
local sessions={}
local remote=Instance.new("Folder");remote.Name="NeighborhoodRemotes";remote.Parent=ReplicatedStorage
local function create(class,name) local v=Instance.new(class);v.Name=name;v.Parent=remote;return v end
local request=create("RemoteFunction","Request")
local changed=create("RemoteEvent","Changed")
local drive=create("RemoteEvent","Drive")
local function root(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end
local function state(player)
    local s=sessions[player.UserId];local p=store.profiles[player.UserId]
    if not s or not p then return {ready=false,message="Your progress is loading."} end
    local result=Learning.public(p);result.ready=true;result.subject=s.subject;result.plot=s.plot;return result
end
local function emit(player,kind,data)
    if player.Parent==Players then changed:FireClient(player,{kind=kind,data=data,state=state(player)}) end
end
local function syncLeaderboard(userId,immediate)
    local profile=store.profiles[userId]
    if not profile then return end
    local snapshot=Learning.copy(profile)
    if immediate then
        leaderboardQueued[userId]=nil
        task.spawn(function() leaderboards:record(userId,snapshot) end)
        return
    end
    if leaderboardQueued[userId] then
        leaderboardQueued[userId]=snapshot
        return
    end
    leaderboardQueued[userId]=snapshot
    task.delay(5,function()
        local latest=leaderboardQueued[userId]
        leaderboardQueued[userId]=nil
        if latest then leaderboards:record(userId,latest) end
    end)
end
local function refreshLeaderboardBoards()
    local snapshot=leaderboards:snapshot(10)
    if snapshot then leaderboards:render(World.leaderboardParts,snapshot) end
end
local function nextQuestion(player)
    local s=sessions[player.UserId];local profile=store.profiles[player.UserId]
    if not s or not profile or not s.subject then return nil end
    local q=Learning.choose(profile,Bank.Questions,s.subject,os.time(),s.lastQuestion)
    if not q then return nil end
    local order={};for i=1,#q.choices do order[i]=i end
    for i=#order,2,-1 do local j=math.random(i);order[i],order[j]=order[j],order[i] end
    local choices={};local correctIndex=0
    for i,index in ipairs(order) do choices[i]=q.choices[index];if index==q.answer then correctIndex=i end end
    s.pending={token=HttpService:GenerateGUID(false),q=q,correctIndex=correctIndex,started=os.clock(),missed=false,wrongChoices={}}
    s.lastQuestion=q.id
    local progress=profile.practice[q.id]
    return {token=s.pending.token,subject=q.subject,prompt=q.prompt,choices=choices,skill=q.skill,
        reviewOnly=progress~=nil and os.time()-progress.lastReward<600}
end
local function move(player,cf)
    Garage.remove(player)
    local r=root(player)
    if r then player.Character:PivotTo(cf);r.AssemblyLinearVelocity=Vector3.zero end
end
local function appearance(player)
    local s=sessions[player.UserId];local p=store.profiles[player.UserId]
    if not s or not p then return end
    World.house(player,s.plot,p)
    Wardrobe.apply(player.Character,p,Catalog)
end
local function join(player)
    local loaded
    for attempt=1,3 do
        loaded=store:load(player.UserId)
        if loaded.ok or player.Parent~=Players then break end
        task.wait(attempt*2)
    end
    if player.Parent~=Players then store:release(player.UserId);return end
    if not loaded or not loaded.ok then
        player:Kick("Your saved progress could not be opened safely. Please rejoin in a moment; nothing has been reset.")
        return
    end
    local plot=World.allocate(player)
    if not plot then store:release(player.UserId);player:Kick("This neighborhood is full. Join another server to get your own house.");return end
    sessions[player.UserId]={plot=plot,lastRequest=0,subject=nil,pending=nil,blockedSubject=nil,busy=false,lastTravel=0}
    local function spawned(character)
        character:WaitForChild("HumanoidRootPart",10)
        if not sessions[player.UserId] then return end
        local hum=character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=18;hum.Died:Connect(function() Garage.remove(player) end) end
        move(player,World.plots[plot].door)
        appearance(player)
    end
    player.CharacterAppearanceLoaded:Connect(function(character)
        local profile=store.profiles[player.UserId]
        if profile then Wardrobe.apply(character,profile,Catalog) end
    end)
    player.CharacterAdded:Connect(spawned)
    if player.Character then task.spawn(spawned,player.Character) end
    appearance(player)
    emit(player,"ready",{message="This home is yours. Head to school and choose a classroom."})
    syncLeaderboard(player.UserId)
end
local function handle(player,command,args)
    local s=sessions[player.UserId];local p=store.profiles[player.UserId]
    if command=="state" then return {ok=true,state=state(player)} end
    if not s or not p then return {ok=false,code="loading"} end
    if type(command)~="string" or #command>24 or type(args)~="table" then return {ok=false,code="invalid"} end
    if os.clock()-s.lastRequest<.12 then return {ok=false,code="slow_down"} end
    s.lastRequest=os.clock()
    local r=root(player)
    if not r then return {ok=false,code="character_loading"} end
    if command=="answer" then
        local pending=s.pending
        if not pending or args.token~=pending.token or World.subjectAt(r.Position)~=pending.q.subject then return {ok=false,code="question_expired"} end
        if os.clock()-pending.started<1 then return {ok=false,code="read_question"} end
        if type(args.choice)~="number" or args.choice%1~=0 or args.choice<1 or args.choice>#pending.q.choices then return {ok=false,code="invalid_choice"} end
        if args.choice~=pending.correctIndex then
            if pending.wrongChoices[args.choice] then
                return {ok=true,correct=false,duplicate=true,penalty=0,deducted=0,
                    wrongStreak=p.wrongStreak,explanation=pending.q.explanation,
                    message="You already tried that answer. No extra Credits were deducted.",state=state(player)}
            end
            local missId=pending.token..":miss:"..tostring(args.choice)
            local result=store:transact(player.UserId,function(profile)
                return Learning.miss(profile,missId,pending.q,os.time())
            end)
            if not result.ok then return result end
            pending.missed=true
            pending.wrongChoices[args.choice]=true
            result.correct=false;result.hint=pending.q.hint;result.state=state(player)
            result.message=result.deducted>0
                and ("Wrong streak "..tostring(result.wrongStreak).." • -"..tostring(result.deducted).." Credits")
                or ("Wrong streak "..tostring(result.wrongStreak).." • balance protected at 0")
            syncLeaderboard(player.UserId)
            return result
        end
        local result=store:transact(player.UserId,function(profile)
            return Learning.reward(profile,pending.token,pending.q,not pending.missed,os.time())
        end)
        if not result.ok then return result end
        s.pending=nil
        result.correct=true;result.explanation=pending.q.explanation;result.state=state(player)
        result.next=nextQuestion(player)
        syncLeaderboard(player.UserId)
        return result
    elseif command=="dismiss" then
        s.pending=nil;s.blockedSubject=s.subject
        return {ok=true}
    elseif command=="study" then
        s.subject=World.subjectAt(r.Position);s.blockedSubject=nil
        if not s.subject then return {ok=false,code="enter_classroom"} end
        return {ok=true,question=nextQuestion(player)}
    elseif command=="goal" then
        local item=type(args.itemId)=="string" and Catalog.ById[args.itemId] or nil
        if not item then return {ok=false,code="unknown_item"} end
        local result=store:transact(player.UserId,function(profile) profile.goal=item.id;return {ok=true} end)
        if result.ok then result.state=state(player) end
        return result
    elseif command=="buy" or command=="equip" then
        local item=type(args.itemId)=="string" and Catalog.ById[args.itemId] or nil
        if not item then return {ok=false,code="unknown_item"} end
        local operation=HttpService:GenerateGUID(false)
        local result=store:transact(player.UserId,function(profile)
            if command=="buy" then return Learning.purchase(profile,operation,item) end
            return Learning.equip(profile,operation,item)
        end)
        if result.ok then
            -- Purchasing never silently spends again. Equipping is a separate free action.
            appearance(player);result.state=state(player);syncLeaderboard(player.UserId)
        end
        return result
    elseif command=="home" or command=="school" then
        if os.clock()-s.lastTravel<3 then return {ok=false,code="travel_cooldown"} end
        s.lastTravel=os.clock();s.pending=nil;s.subject=nil;s.blockedSubject=nil
        move(player,command=="home" and World.plots[s.plot].door or World.schoolDoor)
        return {ok=true,state=state(player)}
    elseif command=="vehicle" then
        if World.subjectAt(r.Position) or r.Position.Z < -12 then return {ok=false,code="outside_for_vehicle"} end
        local item=Catalog.ById[p.equipped.vehicle]
        if not item or not p.owned[item.id] then return {ok=false,code="not_owned"} end
        local cf=r.Position.Z<60 and CFrame.new((s.plot%2==0 and 1 or -1)*(38+(math.floor((s.plot-1)/2)%6)*12),1.65,39+math.floor((s.plot-1)/12)*25) or World.plots[s.plot].drive
        local ok=Garage.spawn(player,item,cf)
        return {ok=ok,code=ok and "vehicle_ready" or "character_loading"}
    elseif command=="park" then Garage.remove(player);return {ok=true} end
    return {ok=false,code="unknown_command"}
end
request.OnServerInvoke=function(player,command,args)
    local s=sessions[player.UserId]
    if s and s.busy then return {ok=false,code="saving"} end
    if s then s.busy=true end
    local ok,result=pcall(handle,player,command,args or {})
    if s then s.busy=false end
    if not ok then warn("Neighborhood request failed for "..tostring(player.UserId));return {ok=false,code="temporarily_unavailable"} end
    return result
end
drive.OnServerEvent:Connect(function(player,throttle,steer) Garage.controls(player,throttle,steer) end)
World.shopPrompt.Triggered:Connect(function(player) emit(player,"shop",{}) end)
Players.PlayerAdded:Connect(function(player) task.spawn(join,player) end)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(join,player) end
Players.PlayerRemoving:Connect(function(player)
    syncLeaderboard(player.UserId,true)
    Garage.remove(player);World.release(player);sessions[player.UserId]=nil;store:release(player.UserId)
end)
task.spawn(function()
    while task.wait(.35) do
        for _,player in ipairs(Players:GetPlayers()) do
            local s=sessions[player.UserId];local r=root(player)
            if not s or not r or s.busy then continue end
            local subject=World.subjectAt(r.Position)
            if subject~=s.subject then
                s.subject=subject;s.pending=nil;s.blockedSubject=nil
                if subject then emit(player,"question",nextQuestion(player)) else emit(player,"left_classroom",{}) end
            end
        end
    end
end)
task.spawn(function()
    while task.wait(60) do
        for _,player in ipairs(Players:GetPlayers()) do
            task.spawn(function()
                local result=store:renew(player.UserId)
                if not result.ok and result.code~="saving" then emit(player,"notice",{message="Saving is temporarily unavailable. Purchases and rewards must be saved before they appear."}) end
            end)
        end
    end
end)
task.spawn(function()
    while true do
        refreshLeaderboardBoards()
        task.wait(Leaderboards.REFRESH_SECONDS)
    end
end)
game:BindToClose(function()
    local count=0
    for _,player in ipairs(Players:GetPlayers()) do
        count+=1;task.spawn(function() store:release(player.UserId);count-=1 end)
    end
    local start=os.clock();repeat task.wait(.1) until count==0 or os.clock()-start>25
end)
