"""Execute the actual server source with deterministic service doubles; no Roblox/render claim."""
from pathlib import Path
import argparse,subprocess
ap=argparse.ArgumentParser();ap.add_argument('--luau',required=True);args=ap.parse_args()
p=Path(__file__).resolve().parents[1]
prefix=r'''
local warn=function() end
local Data=require("../shared/Data")
local Questions=require("../server/QuestionBank")
local queue={}
local function flush()
    local guard=0
    while #queue>0 do guard+=1;assert(guard<200);table.remove(queue,1)() end
end
local task={spawn=function(f,...) local a=table.pack(...);table.insert(queue,function() f(table.unpack(a,1,a.n)) end) end,
    defer=function(f) table.insert(queue,f) end,delay=function(_,f) table.insert(queue,f) end,wait=function() end}
local function signal() return {Connect=function(self,f) self.callback=f end} end
local player={UserId=1,CharacterAdded=signal()}
local Players={PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function() return {} end}
local saved,events={ ["u:1"]={totalCorrect=4,sessionsCompleted=0,skills={}} },{}
local getFailures,updateFailures,getAttempts,updateAttempts=2,0,0,0
local store={
    GetAsync=function(_,key)
        getAttempts+=1
        if getFailures>0 then getFailures-=1;error("forced transient GetAsync failure") end
        return saved[key]
    end,
    UpdateAsync=function(_,key,f)
        updateAttempts+=1
        if updateFailures>0 then updateFailures-=1;error("forced transient UpdateAsync failure") end
        saved[key]=f(saved[key]);return saved[key]
    end,
}
local service={}
service.WaitForChild=function(_,name) if name=="EmmaStudyShared" then return service end;return name end
local requests
local Instance={new=function(class)
    if class=="RemoteFunction" then requests={} return requests end
    if class=="RemoteEvent" then return {FireClient=function(_,_,e) table.insert(events,e) end} end
    return {}
end}
local visualFailure=false
local enforceSingleTeacher=true
local teacherModels={}
local function sharedBoardWrite() error("Per-user curriculum must never mutate the shared server smartboard") end
local World={Root={},resetBoard=sharedBoardWrite,setBoardQuestion=sharedBoardWrite,setBoardHint=sharedBoardWrite,setBoardCorrect=sharedBoardWrite,
    setTeacherSpeech=function() end,walkTeacher=function() end,
    teacherModel=function()
        for _,old in ipairs(teacherModels) do if enforceSingleTeacher then assert(old.Parent==nil,"Outgoing teacher must be removed before the next teacher is created") end end
        if visualFailure then error("forced visual constructor failure") end
        local model={attrs={},SetAttribute=function(self,key,value) self.attrs[key]=value end,PivotTo=function() end,Destroy=function(self) self.Parent=nil end}
        table.insert(teacherModels,model);return model
    end}
World.build=function() return World end
local counter=0
local Http={GenerateGUID=function() counter+=1;return "token-"..counter end}
local closeCallback
local game={GetService=function(_,name)
    if name=="Players" then return Players end
    if name=="ReplicatedStorage" then return service end
    if name=="DataStoreService" then return {GetDataStore=function() return store end} end
    if name=="HttpService" then return Http end
end,BindToClose=function(_,callback) closeCallback=callback end}
local script={Parent=service}
local require=function(module)
    if module=="Data" then return Data end
    if module=="QuestionBank" then return Questions end
    if module=="World" then return World end
    error(module)
end
local function boot()
'''
suffix=r'''
end
boot()
Players.PlayerAdded.callback(player)
flush()
assert(getAttempts==3,"Progress load must retry transient DataStore failures")
assert(#events==0,"Wait for the client handshake before emitting a round")
local first=requests.OnServerInvoke(player,"state")
assert(first.ok and first.progress.stars==0 and first.progress.totalCorrect==4)
flush()
local function pending()
    local state=requests.OnServerInvoke(player,"state")
    assert(state.ok and state.question)
    assert(state.question.answer==nil and state.question.correctIndex==nil)
    return state.question
end
local q=pending()
assert(not requests.OnServerInvoke(player,"restart").ok,"Restart cannot race an active round")
assert(not requests.OnServerInvoke(player,"answer",{token=q.token,index=999}).ok)
assert(not requests.OnServerInvoke(player,"answer",{token="old",index=1}).ok)
for step=1,10 do
    q=pending()
    local raw
    for _,candidate in ipairs(Questions) do if candidate.prompt==q.prompt then raw=candidate;break end end
    assert(raw)
    local correct=table.find(q.choices,raw.answer)
    local wrong=correct==1 and 2 or 1
    local miss=requests.OnServerInvoke(player,"answer",{token=q.token,index=wrong})
    assert(miss.ok and miss.correct==false and miss.answer==nil)
    assert(requests.OnServerInvoke(player,"state").progress.stars==step-1,"No wrong-answer penalty or reward")
    if step==1 then updateFailures=2 end
    local hit=requests.OnServerInvoke(player,"answer",{token=q.token,index=correct})
    assert(hit.ok and hit.correct)
    assert(not requests.OnServerInvoke(player,"answer",{token=q.token,index=correct}).ok,"Replay cannot earn another star")
    flush()
    assert(requests.OnServerInvoke(player,"state").progress.stars==step)
end
assert(updateAttempts>=3,"Progress save must retry transient DataStore failures")
assert(events[#events].kind=="session_complete")
assert(saved["u:1"].totalCorrect==14 and saved["u:1"].sessionsCompleted==1)
assert(requests.OnServerInvoke(player,"restart").ok);flush()
assert(requests.OnServerInvoke(player,"state").progress.stars==0)
visualFailure=true
assert(requests.OnServerInvoke(player,"skip").ok);flush();pending()
visualFailure=false
assert(requests.OnServerInvoke(player,"skip").ok);flush();pending()
assert(requests.OnServerInvoke(player,"state").progress.totalCorrect==14)
-- Curriculum selection is server governed and never replicates answer keys.
local state=requests.OnServerInvoke(player,"state")
assert(type(state.tests)=="table")
for _,t in ipairs(state.tests) do assert(t.questionIds==nil and t.answer==nil) end
local beforeToken=state.question.token
assert(not requests.OnServerInvoke(player,"select_test",{id="invented"}).ok)
assert(requests.OnServerInvoke(player,"state").question.token==beforeToken)
local grammar,unavailable
for _,t in ipairs(Questions.Tests) do
    if string.find(t.label,"Grammar",1,true) then grammar=t end
    if not t.supported then unavailable=t end
end
-- The source calendar is allowed to advance or gain complete coverage.
-- If no such menu row exists now, exercise the same protocol with a local
-- server-test fixture made from reviewed bank IDs; never rewrite product data.
if not grammar then
    local refs={};for _,q in ipairs(Questions) do if q.skill=="subject-predicate" then refs[#refs+1]=q.id end end
    grammar={id="fixture-grammar",label="Grammar",questionIds=refs,supported=true};Questions.Tests[#Questions.Tests+1]=grammar
end
if not unavailable then
    unavailable={id="fixture-unavailable",label="Unknown",questionIds={},supported=false};Questions.Tests[#Questions.Tests+1]=unavailable
end
assert(grammar and #grammar.questionIds>0 and unavailable)
assert(not requests.OnServerInvoke(player,"select_test",{id=unavailable.id}).ok)
assert(requests.OnServerInvoke(player,"select_test",{id=grammar.id}).ok);flush()
for _=1,15 do
    local presented=pending();local raw
    for _,candidate in ipairs(Questions) do if candidate.prompt==presented.prompt then raw=candidate;break end end
    assert(raw.skill=="subject-predicate" and raw.tier~="star-fallback")
    assert(table.find(grammar.questionIds,raw.id))
    assert(requests.OnServerInvoke(player,"skip").ok);flush()
end
assert(requests.OnServerInvoke(player,"select_test",{id="mix"}).ok);flush()
local counts={current=0,archive=0,["star-fallback"]=0}
for _,q in ipairs(Questions) do counts[q.tier]+=1 end
local shown={}
for index=1,#Questions do
    local presented=pending();local raw
    for _,candidate in ipairs(Questions) do if candidate.prompt==presented.prompt and candidate.subject==presented.subject then raw=candidate;break end end
    assert(raw and not shown[raw.id],"No repeat before the full curriculum is exhausted")
    shown[raw.id]=true
    local tier=index<=counts.current and "current" or index<=counts.current+counts.archive and "archive" or "star-fallback"
    assert(raw.tier==tier,"Strict current then archive then STAR precedence")
    assert(requests.OnServerInvoke(player,"skip").ok);flush()
end
assert(requests.OnServerInvoke(player,"state").progress.totalCorrect==14,"Selecting or skipping curriculum cannot earn progress")
-- A second user starts with independent progress, and changing test mode
-- after a correct answer cannot let its delayed callback replace the new round.
enforceSingleTeacher=false -- Two player-specific presentations can coexist.
local player2={UserId=2,CharacterAdded=signal()}
Players.PlayerAdded.callback(player2)
assert(requests.OnServerInvoke(player2,"state").progress.totalCorrect==0)
flush()
local two=requests.OnServerInvoke(player2,"state").question
assert(teacherModels[#teacherModels].attrs.OwnerUserId==player2.UserId,"Visual NPC must belong to the student's viewport")
local raw
for _,candidate in ipairs(Questions) do if candidate.prompt==two.prompt and candidate.subject==two.subject then raw=candidate;break end end
assert(requests.OnServerInvoke(player2,"answer",{token=two.token,index=table.find(two.choices,raw.answer)}).correct)
assert(requests.OnServerInvoke(player2,"select_test",{id=grammar.id}).ok)
local eventStart=#events
flush()
local questionEvents=0
for i=eventStart+1,#events do if events[i].kind=="question" then questionEvents+=1 end end
assert(questionEvents==1,"Old correct-delay callback cannot replace a selected test round")
assert(requests.OnServerInvoke(player2,"state").progress.totalCorrect==1)
assert(requests.OnServerInvoke(player,"state").progress.totalCorrect==14,"No cross-player progress exposure")
assert(saved["u:2"].totalCorrect==1 and saved["u:1"].totalCorrect==14)
-- A repeated ten-answer session can be restarted early via a malicious/late
-- RPC. Its old delayed grading callback must never overwrite the new token.
assert(requests.OnServerInvoke(player2,"select_test",{id="mix"}).ok);flush()
for step=1,10 do
    local nextQuestion=requests.OnServerInvoke(player2,"state").question
    local matched
    for _,candidate in ipairs(Questions) do
        if candidate.prompt==nextQuestion.prompt and candidate.subject==nextQuestion.subject then matched=candidate;break end
    end
    assert(matched)
    local answerIndex=table.find(nextQuestion.choices,matched.answer)
    assert(requests.OnServerInvoke(player2,"answer",{token=nextQuestion.token,index=answerIndex}).correct)
    if step<10 then flush() end
end
local newEvents=#events
assert(requests.OnServerInvoke(player2,"restart").ok,"Completed round should allow restart")
flush()
local afterRestart=requests.OnServerInvoke(player2,"state")
assert(afterRestart.question and afterRestart.progress.stars==0,"Restart must create one new session")
local newQuestions,newCompletions=0,0
for i=newEvents+1,#events do
    if events[i].kind=="question" then newQuestions+=1 end
    if events[i].kind=="session_complete" then newCompletions+=1 end
end
assert(newQuestions==1 and newCompletions==0,"Old completion timer must not replace or finish the restarted round")
assert(saved["u:2"].totalCorrect==11 and saved["u:1"].totalCorrect==14)
-- A shutdown save is synchronous: it must be durable before BindToClose returns.
saved["u:1"]={totalCorrect=0,sessionsCompleted=0,skills={}}
Players.GetPlayers=function() return {player} end
closeCallback()
assert(saved["u:1"].totalCorrect==14 and saved["u:1"].sessionsCompleted==1)
-- A stale leaving snapshot must not regress a newer DataStore completion.
saved["u:1"].totalCorrect=20
saved["u:1"].sessionsCompleted=3
saved["u:1"].skills.legacy={correct=9}
Players.PlayerRemoving.callback(player);flush()
assert(saved["u:1"].totalCorrect==20,"Stale save cannot regress lifetime total")
assert(saved["u:1"].sessionsCompleted==3,"Stale save cannot regress completed sessions")
assert(saved["u:1"].skills.legacy.correct==9,"Stale save must preserve newer skill progress")
print("PASS: server grades independently; smartboard stays local; NPCs have owners; old restart/test callbacks cannot overwrite new sessions; monotonic, independent persistence")
'''
fixture=p/'tests/.server-runtime.generated.lua'
try:
    fixture.write_text(prefix+(p/'server/Main.server.lua').read_text()+suffix)
    subprocess.run([args.luau,str(fixture)],check=True)
finally:
    fixture.unlink(missing_ok=True)
