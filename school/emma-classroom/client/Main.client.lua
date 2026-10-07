--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local TweenService=game:GetService("TweenService")
local Workspace=game:GetService("Workspace")

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
pcall(function() gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets end)
gui.Parent=player:WaitForChild("PlayerGui")

local root=Instance.new("Frame");root.Size=UDim2.fromScale(1,1);root.BackgroundTransparency=1;root.Parent=gui

-- The UI is deliberately tiny. The classroom, teacher and Smartboard are the interface now.
local progressChip=Instance.new("Frame")
progressChip.Name="ProgressChip";progressChip.BackgroundColor3=P.green;progressChip.BackgroundTransparency=.04;progressChip.BorderSizePixel=0;progressChip.ZIndex=10;progressChip.Parent=root
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
answerBar.Name="AnswerBar";answerBar.AnchorPoint=Vector2.new(.5,1);answerBar.BackgroundColor3=Color3.fromRGB(250,248,239);answerBar.BackgroundTransparency=.035;answerBar.BorderSizePixel=0;answerBar.Visible=false;answerBar.ZIndex=30;answerBar.Parent=root
corner(answerBar,18);stroke(answerBar,P.green,.32,1.4)

local subjectLine=text(answerBar,"Schoolwork",11,P.green,Enum.Font.GothamBold);subjectLine.TextXAlignment=Enum.TextXAlignment.Left;subjectLine.ZIndex=31
local feedback=text(answerBar,"",11,P.muted,Enum.Font.GothamMedium);feedback.TextXAlignment=Enum.TextXAlignment.Left;feedback.ZIndex=31

local answers=Instance.new("Frame");answers.BackgroundTransparency=1;answers.ZIndex=31;answers.Parent=answerBar
local answerGrid=Instance.new("UIGridLayout");answerGrid.SortOrder=Enum.SortOrder.LayoutOrder;answerGrid.CellPadding=UDim2.fromOffset(8,8);answerGrid.Parent=answers

local skip=Instance.new("TextButton")
skip.BackgroundColor3=Color3.fromRGB(230,231,225);skip.Text="Skip";skip.TextColor3=Color3.fromRGB(74,77,78);skip.Font=Enum.Font.GothamBold;skip.TextSize=11;skip.AutoButtonColor=true;skip.ZIndex=32;skip.Parent=answerBar
corner(skip,10)

local currentToken:string?=nil
local busy=false
local colors={P.blue,P.teal,P.amber,P.purple}
local camera=Workspace.CurrentCamera
local studyView=false

local function setPlayerCamera()
    camera=Workspace.CurrentCamera
    if not camera then return end
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    camera.CameraType=Enum.CameraType.Custom
    if humanoid then camera.CameraSubject=humanoid end
    camera.FieldOfView=70
    studyView=false
    viewToggle.Text="Study view"
end

local function setStudyCamera()
    camera=Workspace.CurrentCamera
    if not camera then return end
    camera.CameraType=Enum.CameraType.Scriptable
    camera.FieldOfView=68
    -- Rear-left classroom view: Emma/desk foreground, teacher + Smartboard center, doorway/right wall visible.
    camera.CFrame=CFrame.lookAt(Vector3.new(-18,8.8,21),Vector3.new(-4,7.2,-18))
    studyView=true
    viewToggle.Text="Look around"
end

local function setProgress(p)
    if not p then return end
    progressText.Text="★ "..tostring(p.stars or 0).."   •   "..tostring(p.questionNumber or 1).." / "..tostring(p.goal or 10)
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
    badge.AnchorPoint=Vector2.new(0,.5);badge.Position=UDim2.new(0,8,.5,0);badge.Size=UDim2.fromOffset(30,30);badge.BackgroundColor3=color;badge.BorderSizePixel=0;badge.ZIndex=33;badge.Parent=b
    corner(badge,999)
    local bt=text(badge,string.char(64+index),14,Color3.new(1,1,1),Enum.Font.GothamBold);bt.Size=UDim2.fromScale(1,1);bt.ZIndex=34

    local a=text(b,value,14,P.ink,Enum.Font.GothamBold);a.Position=UDim2.fromOffset(42,3);a.Size=UDim2.new(1,-48,1,-6);a.ZIndex=33

    b.Activated:Connect(function()
        if busy or not currentToken then return end
        busy=true
        local ok,res=pcall(function() return request:InvokeServer("answer",{token=currentToken,index=index}) end)
        busy=false
        if not ok or not res then feedback.Text="Try that tap again.";return end
        if res.correct==false then
            feedback.Text=res.hint or "Take another look."
            local old=b.BackgroundColor3;b.BackgroundColor3=P.wrong
            TweenService:Create(b,TweenInfo.new(.45),{BackgroundColor3=old}):Play()
        end
    end)
end

local function layout()
    local cam=Workspace.CurrentCamera
    local vp=cam and cam.ViewportSize or Vector2.new(844,390)
    local w,h=vp.X,vp.Y
    local landscape=w>h

    progressChip.Position=UDim2.fromOffset(12,12);progressChip.Size=UDim2.fromOffset(138,38)
    viewToggle.Position=UDim2.fromOffset(12,58);viewToggle.Size=UDim2.fromOffset(124,44)
    teacherChip.AnchorPoint=Vector2.new(1,0);teacherChip.Position=UDim2.new(1,-12,0,12);teacherChip.Size=UDim2.fromOffset(math.min(250,w*.30),38)
    entering.Size=UDim2.fromOffset(math.min(300,w-40),44);entering.Position=UDim2.new(.5,0,.52,0)

    local barW=math.min(880,w-20)
    local barH=landscape and 142 or 248
    answerBar.Size=UDim2.fromOffset(barW,barH);answerBar.Position=UDim2.new(.5,0,1,-10)

    subjectLine.Position=UDim2.fromOffset(14,8);subjectLine.Size=UDim2.new(1,-100,0,18)
    feedback.Position=UDim2.fromOffset(14,barH-28);feedback.Size=UDim2.new(1,-100,0,20)
    skip.AnchorPoint=Vector2.new(1,0);skip.Position=UDim2.new(1,-12,0,barH-31);skip.Size=UDim2.fromOffset(70,24)

    answers.Position=UDim2.fromOffset(12,32);answers.Size=UDim2.new(1,-24,0,landscape and 70 or 178)
    if landscape then
        answerGrid.FillDirectionMaxCells=4
        answerGrid.CellSize=UDim2.new(.25,-6,0,64)
    else
        answerGrid.FillDirectionMaxCells=1
        answerGrid.CellSize=UDim2.new(1,0,0,38)
    end
end

local cam=Workspace.CurrentCamera
if cam then
    cam:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
end
layout();setPlayerCamera()

viewToggle.Activated:Connect(function()
    if studyView then setPlayerCamera() else setStudyCamera() end
end)

player.CharacterAdded:Connect(function()
    task.wait(.25);setPlayerCamera()
end)

event.OnClientEvent:Connect(function(payload)
    if type(payload)~="table" then return end
    if payload.kind=="teacher_entering" then
        setProgress(payload.progress)
        currentToken=nil;clearAnswers();answerBar.Visible=false
        teacherChip.Visible=true;teacherText.Text=(payload.teacher or "Teacher").."  •  "..(payload.role or "ABVM Staff")
        enteringText.Text=(payload.teacher or "Teacher").." is coming in…";entering.Visible=true
        task.delay(1.9,function() entering.Visible=false end)
    elseif payload.kind=="question" then
        entering.Visible=false;currentToken=payload.token;busy=false;feedback.Text=""
        teacherChip.Visible=true;teacherText.Text=(payload.teacher or "Teacher").."  •  "..(payload.role or "ABVM Staff")
        subjectLine.Text=(payload.subject or "Schoolwork").."  •  Choose an answer below"
        clearAnswers()
        for i,v in ipairs(payload.choices or {}) do makeAnswer(v,i) end
        setProgress(payload.progress)
        answerBar.Visible=true
    elseif payload.kind=="correct" then
        currentToken=nil;clearAnswers();feedback.Text=""
        answerBar.Visible=false
        teacherChip.Visible=true;teacherText.Text=(payload.teacher or "Teacher").."  •  Correct! ★"
        setProgress(payload.progress);starBurst()
    elseif payload.kind=="session_complete" then
        currentToken=nil;clearAnswers()
        teacherChip.Visible=true;teacherText.Text="Study session complete ★"
        subjectLine.Text="10 real schoolwork questions finished"
        feedback.Text="Nice work, Emma."
        setProgress(payload.progress)
        answerBar.Visible=true
        local again=Instance.new("TextButton");again.BackgroundColor3=P.green;again.TextColor3=P.gold;again.Text="Do another 10";again.Font=Enum.Font.GothamBold;again.TextSize=16;again.ZIndex=32;again.Parent=answers
        corner(again,13);stroke(again,P.gold,.25,1)
        again.Activated:Connect(function() request:InvokeServer("restart") end)
        starBurst()
    end
end)

skip.Activated:Connect(function()
    if currentToken and not busy then
        busy=true
        pcall(function() request:InvokeServer("skip") end)
        currentToken=nil;clearAnswers();answerBar.Visible=false
        busy=false
    end
end)

task.spawn(function()
    local ok,res=pcall(function() return request:InvokeServer("state") end)
    if ok and res and res.progress then setProgress(res.progress) end
end)
