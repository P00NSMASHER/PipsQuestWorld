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
local teacherModels={}
local World={Root={},resetBoard=function() end,setBoardQuestion=function() end,setBoardHint=function() end,setBoardCorrect=function() end,
    setTeacherSpeech=function() end,walkTeacher=function() end,
    teacherModel=function()
        for _,old in ipairs(teacherModels) do assert(old.Parent==nil,"Outgoing teacher must be removed before the next teacher is created") end
        if visualFailure then error("forced visual constructor failure") end
        local model={SetAttribute=function() end,PivotTo=function() end,Destroy=function(self) self.Parent=nil end}
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
print("PASS: retrying load/save, handshake/recovery, wrong hint, invalid tokens, no replay reward, ten-question finish, restart, skip with failed visual constructor, monotonic and awaited-shutdown persistence; no overlapping teacher models")
'''
fixture=p/'tests/.server-runtime.generated.lua'
try:
    fixture.write_text(prefix+(p/'server/Main.server.lua').read_text()+suffix)
    subprocess.run([args.luau,str(fixture)],check=True)
finally:
    fixture.unlink(missing_ok=True)
