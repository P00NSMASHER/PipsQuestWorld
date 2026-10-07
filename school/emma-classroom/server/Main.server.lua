--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local DataStoreService=game:GetService("DataStoreService")
local HttpService=game:GetService("HttpService")
local Data=require(ReplicatedStorage:WaitForChild("EmmaStudyShared"):WaitForChild("Data"))
local Questions=require(script.Parent:WaitForChild("QuestionBank"))
local World=require(script.Parent:WaitForChild("World")).build()

local remotes=Instance.new("Folder");remotes.Name="EmmaClassroomRemotes";remotes.Parent=ReplicatedStorage
local request=Instance.new("RemoteFunction");request.Name="Request";request.Parent=remotes
local event=Instance.new("RemoteEvent");event.Name="Event";event.Parent=remotes
local store=DataStoreService:GetDataStore("EmmaStudyClassroomV1")
local sessions={}
local SESSION_GOAL=10

local function shuffle(list)
    local out=table.clone(list)
    for i=#out,2,-1 do local j=math.random(1,i);out[i],out[j]=out[j],out[i] end
    return out
end

local function publicProgress(s)
    return {stars=s.stars,questionNumber=math.min(s.correctThisSession+1,SESSION_GOAL),goal=SESSION_GOAL,totalCorrect=s.totalCorrect or 0}
end

local function loadProgress(player)
    local data={totalCorrect=0,sessionsCompleted=0,skills={}}
    local ok,result=pcall(function() return store:GetAsync("u:"..player.UserId) end)
    if ok and type(result)=="table" then
        data.totalCorrect=tonumber(result.totalCorrect) or 0
        data.sessionsCompleted=tonumber(result.sessionsCompleted) or 0
        data.skills=type(result.skills)=="table" and result.skills or {}
    end
    return data
end

local function saveProgress(player,s)
    local snapshot={totalCorrect=s.totalCorrect,sessionsCompleted=s.sessionsCompleted,skills=s.skills}
    task.spawn(function()
        pcall(function()
            store:UpdateAsync("u:"..player.UserId,function(old)
                old=type(old)=="table" and old or {}
                old.totalCorrect=snapshot.totalCorrect;old.sessionsCompleted=snapshot.sessionsCompleted;old.skills=snapshot.skills
                old.updatedAt=os.time()
                return old
            end)
        end)
    end)
end

local function chooseTeacher(subject,previous)
    local matching={}
    for _,t in ipairs(Data.Teachers) do
        local weight=t.weight or 1
        if t.name=="Mrs. Benulis" then weight+=3 end
        if subject=="Religion" and t.name=="Mrs. Boyer" then weight+=4 end
        if subject=="Spelling / Handwriting" and t.name=="Mrs. Kochol" then weight+=3 end
        if subject=="Reading / ELA" and t.name=="Mrs. Russek" then weight+=2 end
        if subject=="Math" and t.name=="Mrs. Benulis" then weight+=4 end
        if t.name~=previous then
            for _=1,weight do matching[#matching+1]=t end
        end
    end
    return matching[math.random(1,#matching)]
end

local function chooseQuestion(s)
    local pool={}
    local total=0
    for _,q in ipairs(Questions) do
        if not s.seen[q.id] then
            local weight=math.max(1,q.priority or 1)
            total+=weight
            pool[#pool+1]={q=q,edge=total}
        end
    end
    if #pool==0 then s.seen={};return chooseQuestion(s) end
    local roll=math.random()*total
    for _,entry in ipairs(pool) do if roll<=entry.edge then return entry.q end end
    return pool[#pool].q
end

local function dismissTeacher(s)
    if s.teacherModel and s.teacherModel.Parent then
        local m=s.teacherModel;s.teacherModel=nil
        World.setTeacherSpeech(m,nil)
        task.spawn(function()
            World.walkTeacher(m,false)
            if m and m.Parent then m:Destroy() end
        end)
    end
end

local startRound
startRound=function(player)
    local s=sessions[player.UserId];if not s or s.busy then return end
    if s.correctThisSession>=SESSION_GOAL then
        s.sessionsCompleted+=1;saveProgress(player,s)
        event:FireClient(player,{kind="session_complete",progress=publicProgress(s),totalCorrect=s.totalCorrect,sessionsCompleted=s.sessionsCompleted})
        return
    end
    s.busy=true
    local q=chooseQuestion(s);s.seen[q.id]=true
    local teacher=chooseTeacher(q.subject,s.previousTeacher)
    s.previousTeacher=teacher.name
    dismissTeacher(s)
    World.resetBoard()
    local model=World.teacherModel(teacher);model.Parent=World.Root;model:PivotTo(World.TeacherDoor);s.teacherModel=model
    event:FireClient(player,{kind="teacher_entering",teacher=teacher.fullName or teacher.name,role=teacher.role,subject=q.subject,progress=publicProgress(s)})
    task.spawn(function()
        World.walkTeacher(model,true)
        if sessions[player.UserId]~=s or not model.Parent then return end
        World.setTeacherSpeech(model,nil)
        task.wait(.45)
        local choices=shuffle(q.choices)
        local token=HttpService:GenerateGUID(false)
        s.pending={token=token,q=q,choices=choices,teacher=teacher}
        s.busy=false
        World.setBoardQuestion(q.subject,teacher.name,q.prompt,choices)
        event:FireClient(player,{kind="question",teacher=teacher.fullName or teacher.name,role=teacher.role,subject=q.subject,prompt=q.prompt,choices=choices,token=token,progress=publicProgress(s),focus=Data.Focus})
    end)
end

local function answer(player,args)
    local s=sessions[player.UserId];if not s or not s.pending then return {ok=false,code="no_question"} end
    local p=s.pending
    if type(args)~="table" or args.token~=p.token or type(args.index)~="number" then return {ok=false,code="invalid"} end
    local choice=p.choices[args.index]
    if not choice then return {ok=false,code="invalid_choice"} end
    if choice~=p.q.answer then
        World.setBoardHint(p.q.hint or "Take another look.")
        World.setTeacherSpeech(s.teacherModel,nil)
        return {ok=true,correct=false,hint=p.q.hint,message="Try again. "..(p.q.hint or "")}
    end
    s.pending=nil;s.stars+=1;s.correctThisSession+=1;s.totalCorrect+=1
    local skill=s.skills[p.q.skill] or {correct=0};skill.correct=(skill.correct or 0)+1;s.skills[p.q.skill]=skill
    saveProgress(player,s)
    World.setBoardCorrect(p.q.explanation or "Nice job!")
    World.setTeacherSpeech(s.teacherModel,nil)
    event:FireClient(player,{kind="correct",teacher=p.teacher.fullName or p.teacher.name,explanation=p.q.explanation,progress=publicProgress(s)})
    task.delay(1.9,function()
        local current=sessions[player.UserId]
        if current==s then
            dismissTeacher(s)
            task.delay(1.05,function()
                if sessions[player.UserId]==s then World.resetBoard();startRound(player) end
            end)
        end
    end)
    return {ok=true,correct=true}
end

request.OnServerInvoke=function(player,command,args)
    if command=="answer" then return answer(player,args) end
    local s=sessions[player.UserId]
    if command=="restart" and s and not s.busy and s.correctThisSession>=SESSION_GOAL then
        dismissTeacher(s);s.pending=nil;s.seen={};s.stars=0;s.correctThisSession=0;World.resetBoard()
        task.delay(.35,function() startRound(player) end)
        return {ok=true}
    end
    if command=="skip" and s and s.pending then
        s.pending=nil;dismissTeacher(s);World.resetBoard();task.delay(1.05,function() startRound(player) end)
        return {ok=true}
    end
    if command=="state" and s then
        if not s.ready then
            s.ready=true
            task.defer(function() if sessions[player.UserId]==s then startRound(player) end end)
        end
        local pending=s.pending
        return {ok=true,progress=publicProgress(s),week=Data.WeekLabel,focus=Data.Focus,
            question=pending and {kind="question",teacher=pending.teacher.fullName or pending.teacher.name,role=pending.teacher.role,subject=pending.q.subject,prompt=pending.q.prompt,choices=pending.choices,token=pending.token,progress=publicProgress(s)} or nil}
    end
    return {ok=false,code="unknown"}
end

local function join(player)
    local saved=loadProgress(player)
    local s={stars=0,correctThisSession=0,totalCorrect=saved.totalCorrect,sessionsCompleted=saved.sessionsCompleted,skills=saved.skills,seen={},pending=nil,teacherModel=nil,busy=false}
    sessions[player.UserId]=s
    local function place(character)
        local root=character:WaitForChild("HumanoidRootPart",10)
        if root then character:PivotTo(World.Spawn) end
        local hum=character:FindFirstChildOfClass("Humanoid")
        if hum then
            -- The classroom is small, but it is still a Roblox space: Emma can
            -- walk around and use the normal touch camera between questions.
            hum.WalkSpeed=16;hum.JumpPower=50;hum.AutoRotate=true
        end
    end
    player.CharacterAdded:Connect(place);if player.Character then task.spawn(place,player.Character) end

end

Players.PlayerAdded:Connect(join)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(join,p) end
Players.PlayerRemoving:Connect(function(player)
    local s=sessions[player.UserId];if s then dismissTeacher(s);saveProgress(player,s) end;sessions[player.UserId]=nil
end)

game:BindToClose(function()
    for _,p in ipairs(Players:GetPlayers()) do local s=sessions[p.UserId];if s then saveProgress(p,s) end end
    task.wait(2)
end)
