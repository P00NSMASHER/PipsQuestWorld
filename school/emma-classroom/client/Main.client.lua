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
    green2=Color3.fromRGB(43,106,74),
    gold=Color3.fromRGB(244,207,102),
    cream=Color3.fromRGB(253,250,239),
    paper=Color3.fromRGB(248,248,244),
    ink=Color3.fromRGB(38,42,44),
    muted=Color3.fromRGB(94,101,104),
    blue=Color3.fromRGB(72,143,220),
    teal=Color3.fromRGB(79,177,136),
    amber=Color3.fromRGB(235,181,67),
    purple=Color3.fromRGB(146,111,205),
    wrong=Color3.fromRGB(246,219,211),
    right=Color3.fromRGB(224,244,226),
}

local function corner(parent: Instance,r: number)
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=parent;return c
end
local function stroke(parent: Instance,color: Color3,transparency: number?,thickness: number?)
    local s=Instance.new("UIStroke");s.Color=color;s.Transparency=transparency or 0;s.Thickness=thickness or 1;s.Parent=parent;return s
end
local function label(parent: Instance,textValue: string,size: number,props)
    local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Text=textValue;t.TextColor3=(props and props.color) or P.ink
    t.Font=(props and props.font) or Enum.Font.Gotham;t.TextSize=size;t.TextWrapped=(props and props.wrap)~=false
    t.TextXAlignment=(props and props.x) or Enum.TextXAlignment.Left;t.TextYAlignment=(props and props.y) or Enum.TextYAlignment.Center
    t.Parent=parent;return t
end
local function shadow(parent: Instance)
    local s=Instance.new("Frame");s.Name="Shadow";s.BackgroundColor3=Color3.fromRGB(22,27,31);s.BackgroundTransparency=.73;s.BorderSizePixel=0;s.ZIndex=parent.ZIndex-1;s.Parent=parent.Parent
    corner(s,24);return s
end

local gui=Instance.new("ScreenGui")
gui.Name="EmmaStudyUI";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=false;gui.DisplayOrder=30;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(function() gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets end)
gui.Parent=player:WaitForChild("PlayerGui")

local root=Instance.new("Frame");root.Size=UDim2.fromScale(1,1);root.BackgroundTransparency=1;root.Parent=gui

-- Gold-standard title capsule.
local top=Instance.new("Frame");top.Name="Top";top.BackgroundColor3=P.green;top.BackgroundTransparency=.02;top.BorderSizePixel=0;top.ZIndex=10;top.Parent=root
corner(top,18);stroke(top,P.gold,.15,1.4)
local topShadow=shadow(top);topShadow.ZIndex=8
local crossTile=Instance.new("Frame");crossTile.Position=UDim2.fromOffset(9,9);crossTile.Size=UDim2.fromOffset(44,44);crossTile.BackgroundColor3=Color3.fromRGB(20,59,45);crossTile.BorderSizePixel=0;crossTile.ZIndex=11;crossTile.Parent=top
corner(crossTile,12)
local crossV=Instance.new("Frame");crossV.AnchorPoint=Vector2.new(.5,.5);crossV.Position=UDim2.fromScale(.5,.5);crossV.Size=UDim2.fromOffset(7,28);crossV.BackgroundColor3=P.gold;crossV.BorderSizePixel=0;crossV.ZIndex=12;crossV.Parent=crossTile
local crossH=Instance.new("Frame");crossH.AnchorPoint=Vector2.new(.5,.5);crossH.Position=UDim2.fromScale(.5,.42);crossH.Size=UDim2.fromOffset(23,7);crossH.BackgroundColor3=P.gold;crossH.BorderSizePixel=0;crossH.ZIndex=12;crossH.Parent=crossTile
local title=label(top,"Emma's Study Classroom",20,{color=P.gold,font=Enum.Font.GothamBold});title.Position=UDim2.fromOffset(62,6);title.Size=UDim2.new(1,-72,0,25);title.ZIndex=11
local subtitle=label(top,"ASSUMPTION BVM SCHOOL  •  GRADE 2",10,{color=Color3.fromRGB(236,241,231),font=Enum.Font.GothamBold});subtitle.Position=UDim2.fromOffset(63,31);subtitle.Size=UDim2.new(1,-72,0,15);subtitle.ZIndex=11
local progressText=label(top,"Getting ready…",11,{color=Color3.fromRGB(236,241,231),font=Enum.Font.GothamMedium});progressText.Position=UDim2.fromOffset(63,46);progressText.Size=UDim2.new(1,-72,0,15);progressText.ZIndex=11

local focus=Instance.new("Frame");focus.Name="Focus";focus.BackgroundColor3=Color3.fromRGB(30,55,77);focus.BackgroundTransparency=.10;focus.BorderSizePixel=0;focus.ZIndex=9;focus.Parent=root
corner(focus,16);stroke(focus,Color3.fromRGB(112,140,165),.45,1)
local focusTitle=label(focus,"CURRENT FOCUS",10,{color=P.gold,font=Enum.Font.GothamBold});focusTitle.Position=UDim2.fromOffset(14,7);focusTitle.Size=UDim2.new(1,-28,0,16);focusTitle.ZIndex=10
local focusText=label(focus,"Reading • Spelling • Grammar • Math",11,{color=Color3.fromRGB(243,245,242),font=Enum.Font.GothamMedium});focusText.Position=UDim2.fromOffset(14,22);focusText.Size=UDim2.new(1,-28,0,35);focusText.TextWrapped=true;focusText.ZIndex=10

-- Progress dots: intentionally compact, because the game is supposed to be simple.
local dots=Instance.new("Frame");dots.Name="Dots";dots.BackgroundTransparency=1;dots.ZIndex=12;dots.Parent=root
local dotLayout=Instance.new("UIListLayout");dotLayout.FillDirection=Enum.FillDirection.Horizontal;dotLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center;dotLayout.VerticalAlignment=Enum.VerticalAlignment.Center;dotLayout.Padding=UDim.new(0,5);dotLayout.Parent=dots
local dotObjects={}
for i=1,10 do
    local d=Instance.new("Frame");d.Size=UDim2.fromOffset(12,12);d.BackgroundColor3=Color3.fromRGB(218,218,210);d.BorderSizePixel=0;d.ZIndex=12;d.Parent=dots;corner(d,999);dotObjects[i]=d
end

local entering=Instance.new("Frame");entering.AnchorPoint=Vector2.new(.5,.5);entering.BackgroundColor3=P.green;entering.BackgroundTransparency=.04;entering.BorderSizePixel=0;entering.Visible=false;entering.ZIndex=20;entering.Parent=root
corner(entering,999);stroke(entering,P.gold,.20,1.2)
local enteringText=label(entering,"A teacher is coming in…",15,{color=P.cream,font=Enum.Font.GothamBold,x=Enum.TextXAlignment.Center});enteringText.Size=UDim2.fromScale(1,1);enteringText.ZIndex=21

-- Question card.
local card=Instance.new("Frame");card.Name="QuestionCard";card.AnchorPoint=Vector2.new(.5,1);card.BackgroundColor3=P.cream;card.BackgroundTransparency=.015;card.BorderSizePixel=0;card.ZIndex=30;card.Parent=root
corner(card,24);stroke(card,Color3.fromRGB(62,106,79),.22,1.6)
local cardShadow=shadow(card);cardShadow.ZIndex=27

local teacherChip=Instance.new("Frame");teacherChip.BackgroundColor3=P.green;teacherChip.BorderSizePixel=0;teacherChip.ZIndex=31;teacherChip.Parent=card;corner(teacherChip,999)
local teacherText=label(teacherChip,"Teacher",13,{color=P.gold,font=Enum.Font.GothamBold,x=Enum.TextXAlignment.Center});teacherText.Size=UDim2.fromScale(1,1);teacherText.ZIndex=32

local subjectChip=Instance.new("Frame");subjectChip.BackgroundColor3=Color3.fromRGB(232,237,233);subjectChip.BorderSizePixel=0;subjectChip.ZIndex=31;subjectChip.Parent=card;corner(subjectChip,999)
local subjectText=label(subjectChip,"Schoolwork",12,{color=P.green,font=Enum.Font.GothamBold,x=Enum.TextXAlignment.Center});subjectText.Size=UDim2.fromScale(1,1);subjectText.ZIndex=32

local qtext=label(card,"Your first question will appear here.",22,{color=P.ink,font=Enum.Font.GothamBold,x=Enum.TextXAlignment.Center});qtext.ZIndex=31
local answers=Instance.new("Frame");answers.Name="Answers";answers.BackgroundTransparency=1;answers.ZIndex=31;answers.Parent=card
local answerGrid=Instance.new("UIGridLayout");answerGrid.FillDirectionMaxCells=2;answerGrid.SortOrder=Enum.SortOrder.LayoutOrder;answerGrid.CellPadding=UDim2.fromOffset(10,10);answerGrid.Parent=answers

local feedback=label(card,"",13,{color=P.muted,font=Enum.Font.GothamMedium,x=Enum.TextXAlignment.Left});feedback.ZIndex=31
local skip=Instance.new("TextButton");skip.BackgroundColor3=Color3.fromRGB(232,232,225);skip.Text="Skip";skip.TextColor3=Color3.fromRGB(75,78,79);skip.Font=Enum.Font.GothamBold;skip.TextSize=12;skip.AutoButtonColor=true;skip.ZIndex=32;skip.Parent=card;corner(skip,10)

local currentToken:string?=nil
local busy=false
local currentProgress={stars=0,questionNumber=1,goal=10,totalCorrect=0}
local colors={P.blue,P.teal,P.amber,P.purple}

local function setDots(stars:number)
    for i,d in ipairs(dotObjects) do
        if i<=stars then d.BackgroundColor3=P.gold else d.BackgroundColor3=Color3.fromRGB(218,218,210) end
    end
end

local function setProgress(p)
    if not p then return end
    currentProgress=p
    progressText.Text="★ "..tostring(p.stars or 0).."  •  Question "..tostring(p.questionNumber or 1).."/"..tostring(p.goal or 10).."  •  Total correct "..tostring(p.totalCorrect or 0)
    setDots(p.stars or 0)
end

local function clearAnswers()
    for _,c in ipairs(answers:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
end

local function starBurst()
    for i=1,8 do
        local s=label(root,"★",18+math.random(0,10),{color=P.gold,font=Enum.Font.GothamBold,x=Enum.TextXAlignment.Center})
        s.AnchorPoint=Vector2.new(.5,.5);s.Position=UDim2.fromScale(.5,.72);s.Size=UDim2.fromOffset(42,42);s.ZIndex=80
        local dx=math.random(-180,180);local dy=math.random(-160,-60)
        TweenService:Create(s,TweenInfo.new(.75,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(.5,dx,.72,dy),TextTransparency=1}):Play()
        task.delay(.82,function() if s then s:Destroy() end end)
    end
end

local function makeAnswer(textValue:string,index:number)
    local b=Instance.new("TextButton");b.Name="Answer"..index;b.LayoutOrder=index;b.BackgroundColor3=colors[(index-1)%#colors+1]:Lerp(Color3.new(1,1,1),.76);b.Text="";b.AutoButtonColor=true;b.ZIndex=32;b.Parent=answers
    corner(b,15);stroke(b,colors[(index-1)%#colors+1],.35,1.2)
    local badge=Instance.new("Frame");badge.AnchorPoint=Vector2.new(0,.5);badge.Position=UDim2.new(0,10,.5,0);badge.Size=UDim2.fromOffset(34,34);badge.BackgroundColor3=colors[(index-1)%#colors+1];badge.BorderSizePixel=0;badge.ZIndex=33;badge.Parent=b;corner(badge,999)
    local badgeText=label(badge,string.char(64+index),15,{color=Color3.new(1,1,1),font=Enum.Font.GothamBold,x=Enum.TextXAlignment.Center});badgeText.Size=UDim2.fromScale(1,1);badgeText.ZIndex=34
    local a=label(b,textValue,15,{color=P.ink,font=Enum.Font.GothamBold,x=Enum.TextXAlignment.Center});a.Position=UDim2.fromOffset(50,4);a.Size=UDim2.new(1,-58,1,-8);a.ZIndex=33
    b.Activated:Connect(function()
        if busy or not currentToken then return end
        busy=true
        local ok,res=pcall(function() return request:InvokeServer("answer",{token=currentToken,index=index}) end)
        busy=false
        if not ok or not res then feedback.Text="That tap didn't go through. Try again.";return end
        if res.correct==false then
            feedback.Text=res.hint or "Take another look and try again."
            local old=b.BackgroundColor3;b.BackgroundColor3=P.wrong
            TweenService:Create(b,TweenInfo.new(.45),{BackgroundColor3=old}):Play()
        end
    end)
end

local function showEntering(name:string,role:string,subjectName:string)
    currentToken=nil;clearAnswers();feedback.Text=""
    enteringText.Text=name.." is coming in…"
    entering.Visible=true
    teacherText.Text=name.."  •  "..role
    subjectText.Text=subjectName
    qtext.Text="Get ready, Emma. One question at a time."
    TweenService:Create(entering,TweenInfo.new(.2),{BackgroundTransparency=.02}):Play()
    task.delay(2.0,function() entering.Visible=false end)
end

local function layout()
    local camera=Workspace.CurrentCamera
    local vp=camera and camera.ViewportSize or Vector2.new(844,390)
    local w,h=vp.X,vp.Y
    local landscape=w>h

    local topW=math.min(520,w-24)
    top.Position=UDim2.fromOffset(12,12);top.Size=UDim2.fromOffset(topW,68)
    topShadow.Position=UDim2.fromOffset(16,17);topShadow.Size=top.Size

    if landscape and w>=760 then
        focus.Visible=true;focus.AnchorPoint=Vector2.new(1,0);focus.Position=UDim2.new(1,-12,0,12);focus.Size=UDim2.fromOffset(math.min(310,w*.30),68)
    else
        focus.Visible=false
    end

    dots.AnchorPoint=Vector2.new(.5,0);dots.Position=UDim2.new(.5,0,0,87);dots.Size=UDim2.fromOffset(180,18)
    entering.Size=UDim2.fromOffset(math.min(330,w-40),48);entering.Position=UDim2.new(.5,0,.48,0)

    local cardW=math.min(760,w-24)
    local cardH
    if landscape then cardH=math.min(350,h-108) else cardH=math.min(470,h-120) end
    card.Size=UDim2.fromOffset(cardW,cardH);card.Position=UDim2.new(.5,0,1,-12)
    cardShadow.AnchorPoint=card.AnchorPoint;cardShadow.Position=UDim2.new(.5,5,1,-7);cardShadow.Size=card.Size

    teacherChip.Position=UDim2.fromOffset(16,14);teacherChip.Size=UDim2.fromOffset(math.min(285,cardW*.44),34)
    subjectChip.AnchorPoint=Vector2.new(1,0);subjectChip.Position=UDim2.new(1,-16,0,14);subjectChip.Size=UDim2.fromOffset(math.min(210,cardW*.34),34)

    qtext.Position=UDim2.fromOffset(18,56);qtext.Size=UDim2.new(1,-36,0,landscape and 76 or 105)
    answers.Position=UDim2.fromOffset(18,landscape and 138 or 167);answers.Size=UDim2.new(1,-36,0,landscape and 130 or 220)
    if landscape then
        answerGrid.FillDirectionMaxCells=2;answerGrid.CellSize=UDim2.new(.5,-5,0,60)
    else
        answerGrid.FillDirectionMaxCells=1;answerGrid.CellSize=UDim2.new(1,0,0,48)
    end
    feedback.Position=UDim2.fromOffset(18,cardH-46);feedback.Size=UDim2.new(1,-112,0,32)
    skip.AnchorPoint=Vector2.new(1,0);skip.Position=UDim2.new(1,-16,0,cardH-43);skip.Size=UDim2.fromOffset(78,30)

    local scale=math.clamp(w/900,.82,1.12)
    title.TextSize=math.floor(20*scale);qtext.TextSize=math.floor((landscape and 22 or 20)*scale)
end

local camera=Workspace.CurrentCamera
if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout) end
layout()

event.OnClientEvent:Connect(function(payload)
    if type(payload)~="table" then return end
    if payload.kind=="teacher_entering" then
        setProgress(payload.progress)
        showEntering(payload.teacher or "Teacher",payload.role or "ABVM Staff",payload.subject or "Schoolwork")
    elseif payload.kind=="question" then
        entering.Visible=false;currentToken=payload.token;busy=false;feedback.Text=""
        teacherText.Text=(payload.teacher or "Teacher").."  •  "..(payload.role or "ABVM Staff")
        subjectText.Text=payload.subject or "Schoolwork"
        focusText.Text=payload.focus or "Current Grade 2 schoolwork"
        qtext.Text=payload.prompt or ""
        clearAnswers()
        for i,v in ipairs(payload.choices or {}) do makeAnswer(v,i) end
        setProgress(payload.progress)
        card.Visible=true
    elseif payload.kind=="correct" then
        currentToken=nil;clearAnswers();feedback.Text="Another teacher is on the way…"
        qtext.Text="Correct!  "..(payload.explanation or "Nice job.")
        teacherText.Text=(payload.teacher or "Teacher").." says: Nice job, Emma! ★"
        setProgress(payload.progress)
        starBurst()
        local old=card.BackgroundColor3;card.BackgroundColor3=P.right
        TweenService:Create(card,TweenInfo.new(.75),{BackgroundColor3=old}):Play()
    elseif payload.kind=="session_complete" then
        currentToken=nil;clearAnswers()
        teacherText.Text="Study session complete  ★"
        subjectText.Text="10 real schoolwork questions"
        qtext.Text="Nice work, Emma. You finished all 10!"
        feedback.Text="You can stop here or do another 10."
        setProgress(payload.progress)
        local again=Instance.new("TextButton");again.BackgroundColor3=P.green;again.TextColor3=P.gold;again.Text="Do another 10";again.Font=Enum.Font.GothamBold;again.TextSize=17;again.ZIndex=32;again.Parent=answers;corner(again,15);stroke(again,P.gold,.25,1)
        again.Activated:Connect(function() request:InvokeServer("restart") end)
        starBurst()
    end
end)

skip.Activated:Connect(function()
    if currentToken and not busy then
        busy=true
        pcall(function() request:InvokeServer("skip") end)
        currentToken=nil;clearAnswers();feedback.Text="Skipped. The next teacher is coming in…";busy=false
    end
end)

task.spawn(function()
    local ok,res=pcall(function() return request:InvokeServer("state") end)
    if ok and res then
        if res.progress then setProgress(res.progress) end
        if res.focus then focusText.Text=res.focus end
    end
end)
