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
-- Roblox refuses GetDataStore for an unpublished local Studio file. Treat
-- that environment as a disposable visual/gameplay sandbox rather than
-- crashing the entire server before the first classroom question.
-- Published Roblox servers MUST still use the real persistent DataStore.
local storeOK,storeOrError=pcall(function()
    return DataStoreService:GetDataStore("EmmaStudyClassroomV1")
end)
local store
if storeOK then
    store=storeOrError
else
    local inStudio=game:GetService("RunService"):IsStudio()
    if not inStudio then error(storeOrError) end
    warn("Emma classroom: unpublished Studio playtest uses SESSION-ONLY progress, never live saved progress")
    local localOnly={}
    store={
        GetAsync=function(_,key) return localOnly[key] end,
        UpdateAsync=function(_,key,change)
            localOnly[key]=change(localOnly[key])
            return localOnly[key]
        end,
    }
end
local sessions={}
local SESSION_GOAL=10
local DATASTORE_ATTEMPTS=4
local DATASTORE_RETRY_SECONDS=.35

local function retryDataStore(operationName,operation)
    local lastError
    for attempt=1,DATASTORE_ATTEMPTS do
        local ok,result=pcall(operation)
        if ok then return true,result end
        lastError=result
        if attempt<DATASTORE_ATTEMPTS then
            task.wait(DATASTORE_RETRY_SECONDS*2^(attempt-1))
        end
    end
    warn(string.format("Emma classroom %s failed after %d attempts: %s",operationName,DATASTORE_ATTEMPTS,tostring(lastError)))
    return false,nil
end

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
    local ok,result=retryDataStore("progress load",function()
        return store:GetAsync("u:"..player.UserId)
    end)
    if ok and type(result)=="table" then
        data.totalCorrect=tonumber(result.totalCorrect) or 0
        data.sessionsCompleted=tonumber(result.sessionsCompleted) or 0
        data.skills=type(result.skills)=="table" and result.skills or {}
    end
    return data
end

local function saveProgress(player,s,awaitCompletion:boolean?)
    -- Every correct answer can schedule a save. DataStore requests may finish in
    -- a different order, so snapshots and writes must both be monotonic: an
    -- older completion is never allowed to erase newer lifetime progress.
    local snapshot={
        totalCorrect=math.max(0,tonumber(s.totalCorrect) or 0),
        sessionsCompleted=math.max(0,tonumber(s.sessionsCompleted) or 0),
        skills=table.clone(s.skills),
    }
    local function writeSnapshot()
        return retryDataStore("progress save",function()
            store:UpdateAsync("u:"..player.UserId,function(old)
                old=type(old)=="table" and old or {}
                old.totalCorrect=math.max(tonumber(old.totalCorrect) or 0,snapshot.totalCorrect)
                old.sessionsCompleted=math.max(tonumber(old.sessionsCompleted) or 0,snapshot.sessionsCompleted)
                local mergedSkills=type(old.skills)=="table" and table.clone(old.skills) or {}
                for skillName,snapshotSkill in pairs(snapshot.skills) do
                    local oldSkill=type(mergedSkills[skillName])=="table" and mergedSkills[skillName] or {}
                    local nextSkill=table.clone(oldSkill)
                    nextSkill.correct=math.max(
                        tonumber(oldSkill.correct) or 0,
                        tonumber(snapshotSkill.correct) or 0
                    )
                    mergedSkills[skillName]=nextSkill
                end
                old.skills=mergedSkills
                old.updatedAt=os.time()
                return old
            end)
        end)
    end
    if awaitCompletion then writeSnapshot() else task.spawn(writeSnapshot) end
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

local tierRank={current=1,archive=2,["star-fallback"]=3}
local function testCatalog()
    local out={}
    for _,t in ipairs(Questions.Tests or {}) do
        -- Only menu metadata is replicated, never keys or test membership IDs.
        out[#out+1]={id=t.id,label=t.label,date=t.date,supported=t.supported}
    end
    return out
end

local function chooseQuestion(s)
    local pool={}
    local rank=math.huge
    for _,q in ipairs(Questions) do
        if not s.seen[q.id] and (not s.allowed or s.allowed[q.id]) then
            local candidate=tierRank[q.tier] or 1
            if candidate<rank then pool={};rank=candidate end
            if candidate==rank then pool[#pool+1]=q end
        end
    end
    if #pool==0 then
        -- Repeat only after the selected full bank is exhausted, never merely
        -- after ten questions. Private seen-state remains inside this server.
        s.seen={};return chooseQuestion(s)
    end
    return pool[math.random(1,#pool)]
end

local function dismissTeacher(s)
    if s.teacherModel and s.teacherModel.Parent then
        local m=s.teacherModel;s.teacherModel=nil
        World.setTeacherSpeech(m,nil)
        -- CharacterStudio-style clear-before-replace lifecycle: release the
        -- outgoing visual immediately, before constructing the next teacher.
        -- No detached outgoing rig or delayed cleanup may overlap the new one.
        m:Destroy()
    end
end

local startRound
startRound=function(player)
    local s=sessions[player.UserId];if not s or s.busy then return end
    if s.correctThisSession>=SESSION_GOAL then
        -- Credit is normally committed by the tenth correct answer, before
        -- this delayed notification. Retain a guarded fallback for recovery.
        if not s.sessionCompleteReported then
            s.sessionCompleteReported=true
            s.sessionsCompleted+=1;saveProgress(player,s)
        end
        if not s.sessionCompleteSent then
            s.sessionCompleteSent=true
            event:FireClient(player,{kind="session_complete",progress=publicProgress(s),totalCorrect=s.totalCorrect,sessionsCompleted=s.sessionsCompleted})
        end
        return
    end
    s.busy=true
    local q=chooseQuestion(s);s.seen[q.id]=true
    local teacher=chooseTeacher(q.subject,s.previousTeacher)
    s.previousTeacher=teacher.name
    dismissTeacher(s)
    -- The 3D classroom is shared across players; individual questions are
    -- rendered locally on each student's smartboard, never on the server.
    -- Appearance must never prevent Emma from answering. Native visual assets
    -- are bundled; if a constructor fails, the question still starts normally.
    local visualOK,model=pcall(World.teacherModel,teacher)
    if visualOK and model then
        model:SetAttribute("OwnerUserId",player.UserId)
        model:SetAttribute("StaffEntranceAnimation",true)
        model:PivotTo(World.TeacherDoor)
        model.Parent=World.Root
        s.teacherModel=model
    else
        model=nil
        warn("Teacher visual unavailable; question remains usable")
    end
    local choices=shuffle(q.choices)
    local token=HttpService:GenerateGUID(false)
    s.pending={token=token,q=q,choices=choices,teacher=teacher};s.busy=false
    event:FireClient(player,{kind="question",teacher=teacher.fullName or teacher.name,role=teacher.role,subject=q.subject,prompt=q.prompt,tier=q.tier,choices=choices,token=token,progress=publicProgress(s),focus=s.modeLabel or "Current ABVM lessons"})
    if model then task.spawn(function() World.walkTeacher(model,true) end) end

end

local function answer(player,args)
    local s=sessions[player.UserId];if not s or not s.pending then return {ok=false,code="no_question"} end
    local p=s.pending
    if type(args)~="table" or args.token~=p.token or type(args.index)~="number" or args.index%1~=0 or args.index<1 or args.index>#p.choices then return {ok=false,code="invalid"} end
    local choice=p.choices[args.index]
    if not choice then return {ok=false,code="invalid_choice"} end
    if choice~=p.q.answer then
        World.setTeacherSpeech(s.teacherModel,nil)
        return {ok=true,correct=false,hint=p.q.hint,message="Try again. "..(p.q.hint or "")}
    end
    s.pending=nil;s.stars+=1;s.correctThisSession+=1;s.totalCorrect+=1
    local skill=s.skills[p.q.skill] or {correct=0};skill.correct=(skill.correct or 0)+1;s.skills[p.q.skill]=skill
    -- Credit the completed session in the same atomic grading step as the
    -- tenth correct answer. A student may switch test modes, restart or leave
    -- before the delayed celebration callback fires. None may erase credit.
    if s.correctThisSession>=SESSION_GOAL and not s.sessionCompleteReported then
        s.sessionCompleteReported=true
        s.sessionsCompleted+=1
    end
    saveProgress(player,s)
    World.setTeacherSpeech(s.teacherModel,nil)
    event:FireClient(player,{kind="correct",teacher=p.teacher.fullName or p.teacher.name,explanation=p.q.explanation,progress=publicProgress(s)})
    local completedGeneration=s.generation or 0
    task.delay(1.9,function()
        local current=sessions[player.UserId]
        if current==s and (current.generation or 0)==completedGeneration then
            dismissTeacher(s)
            startRound(player)
        end
    end)
    return {ok=true,correct=true}
end

request.OnServerInvoke=function(player,command,args)
    if command=="answer" then return answer(player,args) end
    local s=sessions[player.UserId]
    if command=="select_test" and s then
        if s.busy or type(args)~="table" or type(args.id)~="string" then return {ok=false,code="invalid"} end
        local allowed,label
        if args.id~="mix" then
            local selected
            for _,t in ipairs(Questions.Tests or {}) do if t.id==args.id then selected=t;break end end
            if not selected or not selected.supported or #selected.questionIds==0 then return {ok=false,code="unavailable"} end
            allowed={};for _,id in ipairs(selected.questionIds) do allowed[id]=true end
            label=selected.label
        end
        dismissTeacher(s);s.pending=nil;s.seen={};s.allowed=allowed;s.modeId=args.id;s.modeLabel=label
        s.stars=0;s.correctThisSession=0;s.sessionCompleteReported=false;s.sessionCompleteSent=false;s.generation=(s.generation or 0)+1
        local selectedGeneration=s.generation
        task.defer(function() if sessions[player.UserId]==s and s.generation==selectedGeneration then startRound(player) end end)
        return {ok=true,modeId=args.id,modeLabel=label or "Mix"}
    end
    if command=="restart" and s and not s.busy and s.correctThisSession>=SESSION_GOAL then
        dismissTeacher(s);s.pending=nil;s.stars=0;s.correctThisSession=0;s.sessionCompleteReported=false;s.sessionCompleteSent=false
        s.generation=(s.generation or 0)+1
        local restartGeneration=s.generation
        task.delay(.35,function()
            if sessions[player.UserId]==s and s.generation==restartGeneration then startRound(player) end
        end)
        return {ok=true}
    end
    if command=="skip" and s and s.pending then
        s.pending=nil;dismissTeacher(s)
        s.generation=(s.generation or 0)+1
        local skipGeneration=s.generation
        task.defer(function() if sessions[player.UserId]==s and s.generation==skipGeneration then startRound(player) end end)
        return {ok=true}
    end
    if command=="state" and s then
        if not s.ready then
            s.ready=true
            task.defer(function() if sessions[player.UserId]==s then startRound(player) end end)
        end
        local pending=s.pending
        return {ok=true,progress=publicProgress(s),week=Questions.WeekLabel,focus=s.modeLabel or "Current ABVM lessons",tests=testCatalog(),modeId=s.modeId or "mix",modeLabel=s.modeLabel or "Mix",
            completed=s.correctThisSession>=SESSION_GOAL,sessionsCompleted=s.sessionsCompleted,
            question=pending and {kind="question",teacher=pending.teacher.fullName or pending.teacher.name,role=pending.teacher.role,subject=pending.q.subject,prompt=pending.q.prompt,tier=pending.q.tier,choices=pending.choices,token=pending.token,progress=publicProgress(s)} or nil}
    end
    return {ok=false,code="unknown"}
end

local function join(player)
    local saved=loadProgress(player)
    local s={stars=0,correctThisSession=0,totalCorrect=saved.totalCorrect,sessionsCompleted=saved.sessionsCompleted,skills=saved.skills,seen={},pending=nil,teacherModel=nil,busy=false,sessionCompleteReported=false,sessionCompleteSent=false}
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
    local s=sessions[player.UserId];if s then dismissTeacher(s);saveProgress(player,s,true) end;sessions[player.UserId]=nil
end)

game:BindToClose(function()
    for _,p in ipairs(Players:GetPlayers()) do local s=sessions[p.UserId];if s then saveProgress(p,s,true) end end
end)
