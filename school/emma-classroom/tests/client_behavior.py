"""Execute actual client event/answer/camera flow with GUI/service doubles; no render claim."""
from pathlib import Path
import argparse,subprocess
ap=argparse.ArgumentParser();ap.add_argument('--luau',required=True);args=ap.parse_args()
p=Path(__file__).resolve().parents[1]
prefix=r'''
local Layout=require("../shared/Layout")
local function signal() return {Connect=function(self,f) self.callback=f end} end
local methods={}
local meta={__index=function(t,k)
    if methods[k] then return methods[k] end
    if t.props[k]~=nil then return t.props[k] end
    return methods.FindFirstChild(t,k)
end,__newindex=function(t,k,v)
    if k=="Parent" then
        local old=t.props.Parent
        if old then local n=table.find(old.children,t);if n then table.remove(old.children,n) end end
        if v then table.insert(v.children,t) end
    end
    t.props[k]=v
end}
local Instance={new=function(class) return setmetatable({props={Name=class,ClassName=class,AbsoluteSize={X=844,Y=390}},children={},attrs={},signals={}},meta) end}
function methods:IsA(k) return self.ClassName==k or (k=="BasePart" and self.ClassName=="Part") end
function methods:GetChildren() return table.clone(self.children) end
function methods:GetDescendants()
 local out={}
 local function walk(node) for _,child in ipairs(node.children) do out[#out+1]=child;walk(child) end end
 walk(self);return out
end
function methods:FindFirstChild(k) for _,c in ipairs(self.children) do if c.Name==k then return c end end end
function methods:FindFirstChildOfClass(k) for _,c in ipairs(self.children) do if c.ClassName==k then return c end end end
function methods:WaitForChild(k) return self:FindFirstChild(k) end
function methods:SetAttribute(k,v) self.attrs[k]=v end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:GetPropertyChangedSignal(k) self.signals[k]=self.signals[k] or signal();return self.signals[k] end
function methods:Destroy() self.Parent=nil end
local oldNew=Instance.new
Instance.new=function(class) local x=oldNew(class);if class=="TextButton" then x.Activated=signal() end;return x end
local player={UserId=1,CharacterAdded=signal()};local playerGui=Instance.new("Folder")
player.WaitForChild=function() return playerGui end
local request,event={}, {OnClientEvent=signal()}
local remoteFolder={WaitForChild=function(_,n)return n=="Request" and request or event end}
local replicated={WaitForChild=function(_,n) if n=="EmmaClassroomRemotes" then return remoteFolder end;return {WaitForChild=function()return Layout end} end}
local workspace=Instance.new("Folder")
workspace.CurrentCamera={GetPropertyChangedSignal=function()return signal()end}
local world=Instance.new("Folder");world.Name="EmmaStudyWorld";world.ChildAdded=signal();world.Parent=workspace
local smart=Instance.new("Part");smart.Name="Interactive smartboard";smart.Parent=world
local boardGui=Instance.new("SurfaceGui");boardGui.Name="QuestionBoard";boardGui.Parent=smart
local boardFrame=Instance.new("Frame");boardFrame.Parent=boardGui
for _,name in ipairs({"Subject","Question","Footer"}) do local label=Instance.new("TextLabel");label.Name=name;label.Parent=boardFrame end
local foreign=Instance.new("Model");foreign.Name="AnotherStudentTeacher";foreign.DescendantAdded=signal();foreign:SetAttribute("OwnerUserId",2);foreign.Parent=world
local foreignPart=Instance.new("Part");foreignPart.Parent=foreign
local foreignSpeech=Instance.new("BillboardGui");foreignSpeech.Enabled=true;foreignSpeech.Parent=foreign
local own=Instance.new("Model");own.Name="MyTeacher";own.DescendantAdded=signal();own:SetAttribute("OwnerUserId",1);own.Parent=world
local ownPart=Instance.new("Part");ownPart.Parent=own
local game={GetService=function(_,n)
 if n=="Players" then return {LocalPlayer=player} end
 if n=="ReplicatedStorage" then return replicated end
 if n=="StarterGui" then return {SetCoreGuiEnabled=function()end} end
 if n=="Workspace" then return workspace end
 if n=="TextService" then return {GetTextSize=function(_,value,size,font,bounds)return {Y=math.max(1,math.ceil(#value*size*.6/bounds.X))*size*1.2}end} end
 if n=="TweenService" then return {Create=function()return {Play=function()end}end} end
end}
local Enum=setmetatable({},{__index=function(t,k)local v=setmetatable({},{__index=function(_,n)return k.."."..n end});rawset(t,k,v);return v end})
local color={Lerp=function(self)return self end}
local Color3={fromRGB=function()return color end,new=function()return color end}
local UDim={new=function(s,o)return {Scale=s,Offset=o}end}
local UDim2={new=function(sx,ox,sy,oy)return {X={Scale=sx,Offset=ox},Y={Scale=sy,Offset=oy}}end}
UDim2.fromScale=function(x,y)return UDim2.new(x,0,y,0)end
UDim2.fromOffset=function(x,y)return UDim2.new(0,x,0,y)end
local Vector2={new=function(x,y)return {X=x or 0,Y=y or 0}end}
local Vector3={new=function(x,y,z)return {x,y,z}end}
local CFrame={lookAt=function(a,b)return {eye=a,target=b}end}
local TweenInfo={new=function()return {}end}
local queue={}
local task={spawn=function(f)table.insert(queue,f)end,delay=function(_,f)table.insert(queue,f)end,wait=function()end}
local nativeRequire=require
local require=function(x) if x==Layout then return Layout end;return nativeRequire(x)end
local question={kind="question",token="q1",prompt="Which word begins with a blend?",subject="Spelling",teacher="Mrs. Benulis",choices={"frog","apple","open"},progress={stars=0,questionNumber=1,goal=10}}
request.InvokeServer=function(_,cmd)
 if cmd=="state" then return {ok=true,question=question,progress=question.progress,tests={{id="grammar",label="Grammar",date="2026-10-09",supported=true},{id="missing",label="Religion Ch. 3",supported=false}}} end
 error(cmd)
end
local function boot()
'''
suffix=r'''
end
boot()
assert(#queue==2,"Board replica and initial handshake should both be scheduled")
table.remove(queue,1)();table.remove(queue,1)()
assert(foreignPart.LocalTransparencyModifier==1 and foreignSpeech.Enabled==false,"Other players' teacher parts and speech must be hidden locally")
assert(ownPart.LocalTransparencyModifier~=1,"Do not hide the student's own teacher")
assert(string.find(boardFrame.Question.Text,"Which word begins",1,true),"Personal question should paint the local smartboard")
assert(string.find(boardFrame.Subject.Text,"Mrs. Benulis",1,true))
local gui=playerGui.EmmaStudyUI;local root=gui:GetChildren()[1]
local card=root.AnswerBar;local toggle=root.ViewToggle
assert(card.Visible and workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable)
local function answerButton(n) for _,c in ipairs(card:GetChildren())do for _,b in ipairs(c:GetChildren())do if b.Name=="Answer"..n then return b end end end end
assert(answerButton(1) and answerButton(2) and answerButton(3))
assert(answerButton(1).Parent.Parent==card,"Answers must not be inside the question ScrollingFrame")
toggle.Activated.callback();assert(not card.Visible and workspace.CurrentCamera.CameraType==Enum.CameraType.Custom)
event.OnClientEvent.callback(question);assert(not card.Visible,"New question cannot cover free-roam controls")
toggle.Activated.callback();assert(card.Visible)
-- Four-choice reviewed worksheet/STAR items retain every touch target.
root.AbsoluteSize={X=568,Y=280}
local four=table.clone(question);four.choices={"A","B","C","D"}
event.OnClientEvent.callback(four)
assert(answerButton(4) and answerButton(4).Size.Y.Offset>=44)
assert(string.find(boardFrame.Question.Text,"D.  D",1,true),"Four-choice mirror must include last answer")
assert(answerButton(1).Position.Y.Offset==answerButton(2).Position.Y.Offset,"Short landscape uses two columns")
root.AbsoluteSize={X=844,Y=390}
event.OnClientEvent.callback(question)
root.ProgressChip.Activated.callback();assert(root.PracticeMenu.Visible)
root.PracticeMenu.PracticeMode3.Activated.callback();assert(root.PracticeMenu.Visible,"Unavailable test must not interrupt the question")
local selected
request.InvokeServer=function(_,cmd,arg)
 if cmd=="select_test" then selected=arg.id;return {ok=true,modeId=arg.id} end
 if cmd=="state" then return {ok=true,question=question,progress=question.progress} end
 error(cmd)
end
root.PracticeMenu.PracticeMode2.Activated.callback();assert(selected=="grammar" and not root.PracticeMenu.Visible)
local lastToken,lastIndex
request.InvokeServer=function(_,cmd,arg)
 if cmd=="answer" then lastToken=arg.token;lastIndex=arg.index;return {ok=true,correct=false,hint="Say the first two sounds."} end
 if cmd=="skip" then
    local nextQuestion=table.clone(question);nextQuestion.token="q2"
    event.OnClientEvent.callback(nextQuestion) -- Event races the RPC return.
    return {ok=true}
 end
 error(cmd)
end
answerButton(2).Activated.callback();assert(lastToken=="q1" and lastIndex==2)
assert(string.find(card.QuestionAndHint.QuestionPrompt.Text,"Say the first two sounds.",1,true))
assert(boardFrame.Footer.Text=="Hint: Say the first two sounds.","Hint must remain local to this player")
card.SkipQuestion.Activated.callback()
answerButton(1).Activated.callback();assert(lastToken=="q2" and lastIndex==1,"Skip return must not erase the new question token/answers")
event.OnClientEvent.callback({kind="correct",explanation="Frog begins with fr.",progress={stars=1}})
assert(not answerButton(1) and card.Visible and not card.SkipQuestion.Visible)
assert(string.find(boardFrame.Subject.Text,"CORRECT",1,true))
event.OnClientEvent.callback({kind="session_complete",progress={stars=10}})
local restart
for _,c in ipairs(card:GetChildren())do for _,b in ipairs(c:GetChildren())do if b:IsA("TextButton") then restart=b end end end
assert(restart and restart.Text=="Do another 10")
assert(string.find(boardFrame.Subject.Text,"session complete",1,true),"Completion mirrored client-only")
-- A fresh HUD/late handshake can miss the final RemoteEvent. The server's
-- completed state must restore the restart control without another question.
while #queue>0 do table.remove(queue,1)() end
local beforeGui=#playerGui:GetChildren()
request.InvokeServer=function(_,cmd)
    if cmd=="state" then return {ok=true,completed=true,progress={stars=10,questionNumber=10,goal=10,totalCorrect=10},sessionsCompleted=1,tests={}} end
    error(cmd)
end
boot()
assert(#queue==2,"Fresh GUI schedules world binding and initial state recovery")
table.remove(queue,1)();table.remove(queue,1)()
local restoredGui=playerGui:GetChildren()[beforeGui+1]
local restoredRoot=restoredGui:GetChildren()[1]
local restoredCard=restoredRoot.AnswerBar
assert(restoredCard.Visible,"Completed session must be visible after GUI re-creation")
local foundRestart=false
for _,frame in ipairs(restoredCard:GetChildren()) do
    for _,item in ipairs(frame:GetChildren()) do
        if item:IsA("TextButton") and item.Text=="Do another 10" then foundRestart=true end
    end
end
assert(foundRestart,"Missing final event must not strand the learner without restart")
assert(string.find(boardFrame.Subject.Text,"session complete",1,true),"Recovered state must repaint the personal smartboard")
print("PASS: client-local smartboard, owned NPC visibility, complete answers, hint/retry/camera, and missed-completion-event HUD recovery")
'''
fixture=p/'tests/.client-runtime.generated.lua'
try:
 fixture.write_text(prefix+(p/'client/Main.client.lua').read_text()+suffix)
 subprocess.run([args.luau,str(fixture)],check=True)
finally:fixture.unlink(missing_ok=True)
