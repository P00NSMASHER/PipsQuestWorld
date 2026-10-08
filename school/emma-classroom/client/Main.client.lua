--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local TweenService=game:GetService("TweenService")
local Workspace=game:GetService("Workspace")
local TextService=game:GetService("TextService")
local Layout=require(ReplicatedStorage:WaitForChild("EmmaStudyShared"):WaitForChild("Layout"))

local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("EmmaClassroomRemotes")
local request=remotes:WaitForChild("Request")
local event=remotes:WaitForChild("Event")

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,false)
end)

local P={
    green=Color3.fromRGB(25,70,51),
    gold=Color3.fromRGB(244,207,102),
    cream=Color3.fromRGB(253,250,239),
    ink=Color3.fromRGB(38,42,44),
    muted=Color3.fromRGB(94,101,104),
    blue=Color3.fromRGB(72,143,220),
    teal=Color3.fromRGB(79,177,136),
    amber=Color3.fromRGB(235,181,67),
    purple=Color3.fromRGB(146,111,205),
    wrong=Color3.fromRGB(246,219,211),
    right=Color3.fromRGB(224,244,226),
}

local function corner(parent: Instance,r:number)
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=parent
end

local function stroke(parent: Instance,color:Color3,transparency:number?,thickness:number?)
    local s=Instance.new("UIStroke");s.Color=color;s.Transparency=transparency or 0;s.Thickness=thickness or 1;s.Parent=parent
end

local function text(parent: Instance,value:string,size:number,color:Color3,font:Enum.Font?):TextLabel
    local t=Instance.new("TextLabel")
    t.BackgroundTransparency=1;t.Text=value;t.TextColor3=color;t.Font=font or Enum.Font.Gotham
    t.TextSize=size;t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Center;t.TextYAlignment=Enum.TextYAlignment.Center;t.Parent=parent
    return t
end

local gui=Instance.new("ScreenGui")
gui.Name="EmmaStudyUI";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.DisplayOrder=30;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(function() gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets end)
gui.Parent=player:WaitForChild("PlayerGui")

local root=Instance.new("Frame");root.Size=UDim2.fromScale(1,1);root.BackgroundTransparency=1;root.Parent=gui

-- One phone-safe question panel. All choices remain visible beside the teacher.
local progressChip=Instance.new("TextButton")
progressChip.Text="";progressChip.AutoButtonColor=true;progressChip.Name="ProgressChip";progressChip.BackgroundColor3=P.green;progressChip.BackgroundTransparency=.04;progressChip.BorderSizePixel=0;progressChip.ZIndex=10;progressChip.Parent=root
corner(progressChip,14);stroke(progressChip,P.gold,.18,1.2)
local progressText=text(progressChip,"★ 0  •  1 / 10",13,P.gold,Enum.Font.GothamBold);progressText.Size=UDim2.fromScale(1,1);progressText.ZIndex=11

local teacherChip=Instance.new("Frame")
teacherChip.Name="TeacherChip";teacherChip.BackgroundColor3=Color3.fromRGB(248,246,236);teacherChip.BackgroundTransparency=.04;teacherChip.BorderSizePixel=0;teacherChip.Visible=false;teacherChip.ZIndex=10;teacherChip.Parent=root
corner(teacherChip,14);stroke(teacherChip,P.green,.48,1)
local teacherText=text(teacherChip,"Teacher",12,P.green,Enum.Font.GothamBold);teacherText.Size=UDim2.fromScale(1,1);teacherText.ZIndex=11

local viewToggle=Instance.new("TextButton")
viewToggle.Name="ViewToggle";viewToggle.BackgroundColor3=Color3.fromRGB(248,246,236);viewToggle.BorderSizePixel=0
viewToggle.Text="Study view";viewToggle.TextColor3=P.green;viewToggle.Font=Enum.Font.GothamBold;viewToggle.TextSize=12
viewToggle.AutoButtonColor=true;viewToggle.ZIndex=12;viewToggle.Parent=root
corner(viewToggle,12);stroke(viewToggle,P.green,.42,1)

local entering=Instance.new("Frame")
entering.AnchorPoint=Vector2.new(.5,.5);entering.BackgroundColor3=P.green;entering.BackgroundTransparency=.05;entering.BorderSizePixel=0;entering.Visible=false;entering.ZIndex=20;entering.Parent=root
corner(entering,999);stroke(entering,P.gold,.20,1.2)
local enteringText=text(entering,"A teacher is coming in…",14,P.cream,Enum.Font.GothamBold);enteringText.Size=UDim2.fromScale(1,1);enteringText.ZIndex=21

local answerBar=Instance.new("Frame")
answerBar.Name="AnswerBar";answerBar.AnchorPoint=Vector2.new(1,1);answerBar.BackgroundColor3=Color3.fromRGB(250,248,239);answerBar.BackgroundTransparency=.035;answerBar.BorderSizePixel=0;answerBar.Visible=false;answerBar.ZIndex=30;answerBar.Parent=root
corner(answerBar,18);stroke(answerBar,P.green,.32,1.4)

local subjectLine=text(answerBar,"Schoolwork",12,P.green,Enum.Font.GothamBold);subjectLine.TextXAlignment=Enum.TextXAlignment.Left;subjectLine.ZIndex=31
local feedback=text(answerBar,"Take your time.",13,P.muted,Enum.Font.GothamMedium);feedback.TextXAlignment=Enum.TextXAlignment.Left;feedback.ZIndex=31
local content=Instance.new("ScrollingFrame")
content.Name="QuestionAndHint";content.BackgroundTransparency=1;content.BorderSizePixel=0;content.ScrollBarThickness=4
content.ScrollBarImageColor3=P.green;content.AutomaticCanvasSize=Enum.AutomaticSize.Y;content.CanvasSize=UDim2.new();content.ZIndex=31;content.Parent=answerBar
local promptText=text(content,"",17,P.ink,Enum.Font.GothamBold)
promptText.Name="QuestionPrompt";promptText.LayoutOrder=0;promptText.TextXAlignment=Enum.TextXAlignment.Left;promptText.TextYAlignment=Enum.TextYAlignment.Top;promptText.ZIndex=32
local answers=Instance.new("Frame");answers.BackgroundTransparency=1;answers.LayoutOrder=1;answers.ZIndex=31;answers.Parent=answerBar
-- Answers use explicit rows; four-choice questions use two columns on short screens.
local skip=Instance.new("TextButton")
skip.Name="SkipQuestion";skip.BackgroundColor3=Color3.fromRGB(230,231,225);skip.Text="Skip";skip.TextColor3=P.muted;skip.Font=Enum.Font.GothamBold;skip.TextSize=13;skip.AutoButtonColor=true;skip.ZIndex=32;skip.Parent=answerBar
corner(skip,10)
local layout
local feedbackHint=""

local modeId="mix"
local modeMenu=Instance.new("ScrollingFrame")
modeMenu.Name="PracticeMenu";modeMenu.BackgroundColor3=P.cream;modeMenu.BorderSizePixel=0;modeMenu.ScrollBarThickness=4
modeMenu.Visible=false;modeMenu.ZIndex=60;modeMenu.Parent=root
corner(modeMenu,12);stroke(modeMenu,P.green,.2,1)
local modeChoices={}

local currentToken:string?=nil
local busy=false
local colors={P.blue,P.teal,P.amber,P.purple}
local camera=Workspace.CurrentCamera
local studyView=false
local hasStudyCard=false

local function setPlayerCamera()
    camera=Workspace.CurrentCamera
    if not camera then return end
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    camera.CameraType=Enum.CameraType.Custom
    if humanoid then camera.CameraSubject=humanoid end
    camera.FieldOfView=70
    studyView=false;answerBar.Visible=false
    viewToggle.Text="Study view"
end

local function setStudyCamera()
    camera=Workspace.CurrentCamera
    if not camera then return end
    camera.CameraType=Enum.CameraType.Scriptable
    local framing=Layout.studyCamera(root.AbsoluteSize.X,root.AbsoluteSize.Y)
    camera.FieldOfView=framing.fov
    -- Teaching-corner composition: staff face and outfit are visible beside the answer panel; desks stay behind the camera.
    camera.CFrame=CFrame.lookAt(Vector3.new(table.unpack(framing.eye)),Vector3.new(table.unpack(framing.target)))
    studyView=true;answerBar.Visible=hasStudyCard
    viewToggle.Text="Look around"
end

local function setProgress(p)
    if not p then return end
    progressText.Text=(modeId=="mix" and "Mix ▾\n" or "Test prep ▾\n").."★ "..tostring(p.stars or 0).."   •   "..tostring(p.questionNumber or 1).." / "..tostring(p.goal or 10)
end

local function clearAnswers()
    for _,c in ipairs(answers:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
end

local function starBurst()
    for i=1,6 do
        local s=text(root,"★",18+math.random(0,8),P.gold,Enum.Font.GothamBold)
        s.AnchorPoint=Vector2.new(.5,.5);s.Position=UDim2.fromScale(.5,.80);s.Size=UDim2.fromOffset(36,36);s.ZIndex=80
        local dx=math.random(-130,130);local dy=math.random(-120,-55)
        TweenService:Create(s,TweenInfo.new(.65,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
            Position=UDim2.new(.5,dx,.80,dy),TextTransparency=1
        }):Play()
        task.delay(.72,function() if s then s:Destroy() end end)
    end
end

local function makeAnswer(value:string,index:number)
    local color=colors[(index-1)%#colors+1]
    local b=Instance.new("TextButton")
    b.Name="Answer"..index;b.LayoutOrder=index;b.BackgroundColor3=color:Lerp(Color3.new(1,1,1),.77)
    b.Text="";b.AutoButtonColor=true;b.ZIndex=32;b.Parent=answers
    corner(b,13);stroke(b,color,.35,1.1)

    local badge=Instance.new("Frame")
    badge.AnchorPoint=Vector2.new(0,.5);badge.Position=UDim2.new(0,8,.5,0);badge.Size=UDim2.fromOffset(24,24);badge.BackgroundColor3=color;badge.BorderSizePixel=0;badge.ZIndex=33;badge.Parent=b
    corner(badge,999)
    local bt=text(badge,string.char(64+index),14,Color3.new(1,1,1),Enum.Font.GothamBold);bt.Size=UDim2.fromScale(1,1);bt.ZIndex=34

    local a=text(b,value,14,P.ink,Enum.Font.GothamBold);a.Name="ChoiceText";a.Position=UDim2.fromOffset(40,4);a.Size=UDim2.new(1,-48,1,-8);a.ZIndex=33
    a.TextScaled=true
    local limit=Instance.new("UITextSizeConstraint");limit.MinTextSize=12;limit.MaxTextSize=16;limit.Parent=a

    b.Activated:Connect(function()
        if busy or not currentToken then return end
        busy=true
        local ok,res=pcall(function() return request:InvokeServer("answer",{token=currentToken,index=index}) end)
        busy=false
        if not ok or not res or res.ok==false then feedback.Text="Tap again to send your answer.";return end
        if res.correct==false then
            feedbackHint=res.hint or "Take another look.";feedback.Text="Try again — your stars are safe.";layout()
            local old=b.BackgroundColor3;b.BackgroundColor3=P.wrong
            TweenService:Create(b,TweenInfo.new(.45),{BackgroundColor3=old}):Play()
        end
    end)
end

layout=function()
    local size=root.AbsoluteSize
    local w,h=math.max(1,size.X),math.max(1,size.Y)
    local dims=Layout.panel(w,h)
    if studyView then setStudyCamera() end
    progressChip.Position=UDim2.fromOffset(12,10);progressChip.Size=UDim2.fromOffset(130,44)
    modeMenu.Position=UDim2.fromOffset(12,58);modeMenu.Size=UDim2.fromOffset(math.min(300,w-24),math.min(240,h-70))
    viewToggle.AnchorPoint=Vector2.new(1,0);viewToggle.Position=UDim2.new(1,-12,0,6);viewToggle.Size=UDim2.fromOffset(116,44)
    teacherChip.AnchorPoint=Vector2.new(.5,0);teacherChip.Position=UDim2.new(.5,0,0,10);teacherChip.Size=UDim2.fromOffset(math.max(100,math.min(300,w-280)),36)
    teacherChip.Visible=teacherText.Text~="Teacher" and w>620
    entering.Size=UDim2.fromOffset(math.min(300,w-40),44);entering.Position=UDim2.new(.35,0,.35,0)
    answerBar.Size=UDim2.fromOffset(dims.width,dims.height);answerBar.Position=UDim2.new(1,-dims.right,1,-dims.bottom)
    subjectLine.Position=UDim2.fromOffset(12,8);subjectLine.Size=UDim2.new(1,-24,0,18)
    local contentW=math.max(100,dims.width-28)
    local stem=promptText:GetAttribute("Prompt") or ""
    promptText.Text=stem..(feedbackHint~="" and "\n\nHint: "..feedbackHint or "")
    local stemH=TextService:GetTextSize(promptText.Text,17,Enum.Font.GothamBold,Vector2.new(contentW,10000)).Y
    local buttons={}
    for _,b in ipairs(answers:GetChildren()) do if b:IsA("TextButton") then table.insert(buttons,b) end end
    local area=Layout.questionArea(dims.height,#buttons,math.max(40,stemH+8))
    content.Position=UDim2.fromOffset(12,34);content.Size=UDim2.new(1,-24,0,area.prompt)
    promptText.Size=UDim2.new(1,-6,0,math.max(32,stemH+8))
    answers.Position=UDim2.fromOffset(12,area.answerTop);answers.Size=UDim2.new(1,-24,0,area.answerTotal)
    table.sort(buttons,function(a,b) return (a.LayoutOrder or 0)<(b.LayoutOrder or 0) end)
    for i,b in ipairs(buttons) do
        local column=(i-1)%area.columns;local row=math.floor((i-1)/area.columns)
        b.Position=UDim2.new(column/area.columns,column*3,0,row*(area.answerHeight+6))
        b.Size=UDim2.new(1/area.columns,area.columns==2 and -3 or 0,0,area.answerHeight)
    end
    feedback.Position=UDim2.new(0,12,1,-38);feedback.Size=UDim2.new(1,-94,0,30)
    skip.AnchorPoint=Vector2.new(1,1);skip.Position=UDim2.new(1,-10,1,-7);skip.Size=UDim2.fromOffset(70,32)

end
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if studyView then setStudyCamera() else setPlayerCamera() end
    layout()
end)

local cam=Workspace.CurrentCamera
if cam then
    cam:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
end
layout();setStudyCamera()

viewToggle.Activated:Connect(function()
    if studyView then setPlayerCamera() else setStudyCamera() end
end)

local function connectCharacter(character)
    local humanoid=character:WaitForChild("Humanoid")
    if studyView then setStudyCamera() else setPlayerCamera() end
    humanoid.Running:Connect(function(speed)
        if studyView and speed>.5 and humanoid.MoveDirection.Magnitude>.05 then setPlayerCamera() end
    end)
end
player.CharacterAdded:Connect(connectCharacter)
if player.Character then task.spawn(connectCharacter,player.Character) end

local function showPayload(payload)
    if type(payload)~="table" then return end
    if payload.kind=="teacher_entering" then
        setProgress(payload.progress)
        currentToken=nil;clearAnswers();hasStudyCard=false;answerBar.Visible=false
        teacherChip.Visible=root.AbsoluteSize.X>620;teacherText.Text=(payload.teacher or "Teacher")
        enteringText.Text=(payload.teacher or "Teacher").." is coming in…";entering.Visible=true
        layout()
    elseif payload.kind=="question" then
        skip.Visible=true;entering.Visible=false;currentToken=payload.token;busy=false;feedbackHint="";feedback.Text="Take your time."
        promptText:SetAttribute("Prompt",payload.prompt or "");content.CanvasPosition=Vector2.new()
        teacherChip.Visible=root.AbsoluteSize.X>620;teacherText.Text=(payload.teacher or "Teacher")
        subjectLine.Text=(payload.subject or "Schoolwork")..(payload.tier=="star-fallback" and " • Original STAR practice" or payload.tier=="archive" and " • Review" or " • Current lessons")
        clearAnswers()
        for i,v in ipairs(payload.choices or {}) do makeAnswer(v,i) end
        setProgress(payload.progress)
        hasStudyCard=true;layout();answerBar.Visible=studyView
    elseif payload.kind=="correct" then
        currentToken=nil;clearAnswers();feedbackHint="";feedback.Text="+1 star"
        promptText:SetAttribute("Prompt",payload.explanation or "Nice work, Emma!")
        subjectLine.Text="Correct!";hasStudyCard=true;layout();answerBar.Visible=studyView;skip.Visible=false
        teacherChip.Visible=root.AbsoluteSize.X>620;teacherText.Text=(payload.teacher or "Teacher").."  •  Correct! ★"
        setProgress(payload.progress);starBurst()
    elseif payload.kind=="session_complete" then
        currentToken=nil;clearAnswers()
        teacherChip.Visible=root.AbsoluteSize.X>620;teacherText.Text="Study session complete ★"
        subjectLine.Text="Session complete"
        feedbackHint="";promptText:SetAttribute("Prompt","You finished 10 questions, Emma! ★")
        skip.Visible=false
        feedback.Text="Nice work, Emma."
        setProgress(payload.progress)
        hasStudyCard=true;layout();answerBar.Visible=studyView
        local again=Instance.new("TextButton");again.BackgroundColor3=P.green;again.TextColor3=P.gold;again.Text="Do another 10";again.Font=Enum.Font.GothamBold;again.TextSize=16;again.ZIndex=32;again.Parent=answers
        corner(again,13);stroke(again,P.gold,.25,1)
        again.Activated:Connect(function()
            if busy then return end;busy=true
            local ok,res=pcall(function() return request:InvokeServer("restart") end);busy=false
            if not ok or not res or not res.ok then feedback.Text="Tap again to start." end
        end)
        layout();starBurst()
    end
end
local function buildPracticeMenu(tests)
    for _,b in ipairs(modeChoices) do b:Destroy() end
    modeChoices={}
    local rows={{id="mix",label="Mix • current lessons first",supported=true}}
    for _,t in ipairs(tests or {}) do rows[#rows+1]=t end
    for i,t in ipairs(rows) do
        local b=Instance.new("TextButton");b.Name="PracticeMode"..i;b.Position=UDim2.fromOffset(6,(i-1)*50+6)
        b.Size=UDim2.new(1,-12,0,44);b.BackgroundColor3=t.supported and P.right or P.wrong
        b.Text=(t.date and t.date.." • " or "")..t.label..(not t.supported and " — material unavailable" or "")
        b.TextWrapped=true;b.TextSize=12;b.TextColor3=P.ink;b.Font=Enum.Font.GothamBold;b.ZIndex=61;b.Parent=modeMenu;corner(b,8)
        modeChoices[#modeChoices+1]=b
        b.Activated:Connect(function()
            if busy or not t.supported then return end
            busy=true
            local ok,res=pcall(function() return request:InvokeServer("select_test",{id=t.id}) end)
            busy=false
            if not ok or not res or not res.ok then feedback.Text="That practice is unavailable. Keep studying this question.";return end
            modeId=res.modeId or "mix";modeMenu.Visible=false
            -- A question event may have raced the RPC. Do not erase its token.
            local stateOK,state=pcall(function() return request:InvokeServer("state") end)
            if stateOK and state and state.ok then setProgress(state.progress);if state.question then showPayload(state.question) end end
        end)
    end
    modeMenu.CanvasSize=UDim2.fromOffset(0,#rows*50+12)
end
progressChip.Activated:Connect(function() modeMenu.Visible=not modeMenu.Visible end)
event.OnClientEvent:Connect(showPayload)

skip.Activated:Connect(function()
    if currentToken and not busy then
        local skippedToken=currentToken
        currentToken=nil;busy=true;feedback.Text="Next question…"
        local ok,res=pcall(function() return request:InvokeServer("skip") end)
        -- A new question event can arrive before InvokeServer returns. Preserve it.
        if not (ok and res and res.ok) and currentToken==nil then
            currentToken=skippedToken;feedback.Text="Tap again to skip."
        end
        busy=false
    end
end)

task.spawn(function()
    local attempt=0
    while gui.Parent do
        attempt+=1
        local ok,res=pcall(function() return request:InvokeServer("state") end)
        if ok and res and res.ok then
            entering.Visible=false
            modeId=res.modeId or "mix";buildPracticeMenu(res.tests);setProgress(res.progress)
            if res.question then showPayload(res.question) end
            return
        end
        enteringText.Text=attempt<5 and "Connecting to your classroom…"
            or "Still connecting — your progress is safe."
        entering.Visible=true
        task.wait(Layout.connectionRetryDelay(attempt))
    end
end)
