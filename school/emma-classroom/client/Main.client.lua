--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local StarterGui=game:GetService("StarterGui")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("EmmaClassroomRemotes")
local request=remotes:WaitForChild("Request")
local event=remotes:WaitForChild("Event")

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)
end)

local gui=Instance.new("ScreenGui");gui.Name="EmmaStudyUI";gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.DisplayOrder=30;gui.Parent=player:WaitForChild("PlayerGui")
local root=Instance.new("Frame");root.Size=UDim2.fromScale(1,1);root.BackgroundTransparency=1;root.Parent=gui

local top=Instance.new("Frame");top.AnchorPoint=Vector2.new(.5,0);top.Position=UDim2.new(.5,0,0,18);top.Size=UDim2.fromOffset(430,62);top.BackgroundColor3=Color3.fromRGB(25,67,50);top.BackgroundTransparency=.03;top.Parent=root
local tc=Instance.new("UICorner");tc.CornerRadius=UDim.new(0,18);tc.Parent=top
local title=Instance.new("TextLabel");title.Position=UDim2.fromOffset(18,5);title.Size=UDim2.new(1,-36,0,27);title.BackgroundTransparency=1;title.Text="EMMA'S STUDY CLASSROOM";title.TextColor3=Color3.fromRGB(250,223,132);title.Font=Enum.Font.GothamBold;title.TextSize=19;title.Parent=top
local progress=Instance.new("TextLabel");progress.Position=UDim2.fromOffset(18,33);progress.Size=UDim2.new(1,-36,0,22);progress.BackgroundTransparency=1;progress.Text="Getting your first question…";progress.TextColor3=Color3.fromRGB(245,245,238);progress.Font=Enum.Font.GothamMedium;progress.TextSize=13;progress.Parent=top

local card=Instance.new("Frame");card.AnchorPoint=Vector2.new(.5,1);card.Position=UDim2.new(.5,0,1,-26);card.Size=UDim2.new(.92,0,0,340);card.BackgroundColor3=Color3.fromRGB(251,249,240);card.BackgroundTransparency=.02;card.Parent=root
local cc=Instance.new("UICorner");cc.CornerRadius=UDim.new(0,22);cc.Parent=card
local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(44,90,68);stroke.Thickness=2;stroke.Transparency=.18;stroke.Parent=card
local teacher=Instance.new("TextLabel");teacher.Position=UDim2.fromOffset(18,14);teacher.Size=UDim2.new(1,-36,0,28);teacher.BackgroundTransparency=1;teacher.Text="";teacher.TextColor3=Color3.fromRGB(32,76,57);teacher.Font=Enum.Font.GothamBold;teacher.TextSize=19;teacher.TextXAlignment=Enum.TextXAlignment.Left;teacher.Parent=card
local subject=Instance.new("TextLabel");subject.Position=UDim2.fromOffset(18,42);subject.Size=UDim2.new(1,-36,0,22);subject.BackgroundTransparency=1;subject.Text="";subject.TextColor3=Color3.fromRGB(83,91,101);subject.Font=Enum.Font.GothamMedium;subject.TextSize=13;subject.TextXAlignment=Enum.TextXAlignment.Left;subject.Parent=card
local qtext=Instance.new("TextLabel");qtext.Position=UDim2.fromOffset(18,70);qtext.Size=UDim2.new(1,-36,0,82);qtext.BackgroundTransparency=1;qtext.Text="";qtext.TextColor3=Color3.fromRGB(36,40,43);qtext.Font=Enum.Font.GothamBold;qtext.TextSize=22;qtext.TextWrapped=true;qtext.TextYAlignment=Enum.TextYAlignment.Center;qtext.Parent=card
local answers=Instance.new("Frame");answers.Position=UDim2.fromOffset(18,160);answers.Size=UDim2.new(1,-36,0,126);answers.BackgroundTransparency=1;answers.Parent=card
local grid=Instance.new("UIGridLayout");grid.CellPadding=UDim2.fromOffset(10,10);grid.CellSize=UDim2.new(.5,-5,0,58);grid.FillDirectionMaxCells=2;grid.SortOrder=Enum.SortOrder.LayoutOrder;grid.Parent=answers
local feedback=Instance.new("TextLabel");feedback.Position=UDim2.fromOffset(18,292);feedback.Size=UDim2.new(1,-110,0,34);feedback.BackgroundTransparency=1;feedback.Text="";feedback.TextColor3=Color3.fromRGB(78,84,89);feedback.Font=Enum.Font.GothamMedium;feedback.TextSize=14;feedback.TextWrapped=true;feedback.TextXAlignment=Enum.TextXAlignment.Left;feedback.Parent=card
local skip=Instance.new("TextButton");skip.AnchorPoint=Vector2.new(1,0);skip.Position=UDim2.new(1,-18,0,294);skip.Size=UDim2.fromOffset(78,30);skip.BackgroundColor3=Color3.fromRGB(225,226,219);skip.Text="Skip";skip.TextColor3=Color3.fromRGB(69,73,76);skip.Font=Enum.Font.GothamBold;skip.TextSize=13;skip.Parent=card
local skc=Instance.new("UICorner");skc.CornerRadius=UDim.new(0,10);skc.Parent=skip

local currentToken=nil
local busy=false
local function clearAnswers() for _,c in ipairs(answers:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end end
local function setProgress(p)
    if not p then return end
    progress.Text="★ "..tostring(p.stars or 0).."   •   Question "..tostring(p.questionNumber or 1).."/"..tostring(p.goal or 10).."   •   Total correct: "..tostring(p.totalCorrect or 0)
end
local function makeAnswer(textValue,index)
    local b=Instance.new("TextButton");b.LayoutOrder=index;b.BackgroundColor3=Color3.fromRGB(238,243,239);b.TextColor3=Color3.fromRGB(31,66,51);b.Text=textValue;b.TextWrapped=true;b.Font=Enum.Font.GothamBold;b.TextSize=16;b.AutoButtonColor=true;b.Parent=answers
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,14);c.Parent=b
    local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(87,131,104);s.Transparency=.45;s.Parent=b
    b.Activated:Connect(function()
        if busy or not currentToken then return end
        busy=true
        local ok,res=pcall(function() return request:InvokeServer("answer",{token=currentToken,index=index}) end)
        busy=false
        if not ok or not res then feedback.Text="Try that again.";return end
        if res.correct==false then
            feedback.Text=res.hint or "Try again."
            b.BackgroundColor3=Color3.fromRGB(251,229,220)
            task.delay(.7,function() if b.Parent then b.BackgroundColor3=Color3.fromRGB(238,243,239) end end)
        end
    end)
end

event.OnClientEvent:Connect(function(payload)
    if type(payload)~="table" then return end
    if payload.kind=="question" then
        currentToken=payload.token;busy=false;feedback.Text=""
        teacher.Text=(payload.teacher or "Teacher").."  •  "..(payload.role or "")
        subject.Text=(payload.subject or "Schoolwork").."   |   "..(payload.focus or "")
        qtext.Text=payload.prompt or ""
        clearAnswers()
        for i,v in ipairs(payload.choices or {}) do makeAnswer(v,i) end
        setProgress(payload.progress)
        card.Visible=true
    elseif payload.kind=="correct" then
        currentToken=nil;clearAnswers();feedback.Text=""
        qtext.Text="Correct!  "..(payload.explanation or "Nice job.")
        teacher.Text=(payload.teacher or "Teacher").." says: Nice job, Emma!"
        setProgress(payload.progress)
        local old=card.BackgroundColor3;card.BackgroundColor3=Color3.fromRGB(226,244,228)
        TweenService:Create(card,TweenInfo.new(.8),{BackgroundColor3=old}):Play()
    elseif payload.kind=="session_complete" then
        currentToken=nil;clearAnswers()
        teacher.Text="Study session complete"
        subject.Text="10 real schoolwork questions"
        qtext.Text="Nice work, Emma. You finished your study session!"
        feedback.Text="You can stop here or do another 10."
        setProgress(payload.progress)
        local again=Instance.new("TextButton");again.BackgroundColor3=Color3.fromRGB(31,91,67);again.TextColor3=Color3.fromRGB(250,225,137);again.Text="Do another 10";again.Font=Enum.Font.GothamBold;again.TextSize=18;again.Parent=answers
        local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,14);c.Parent=again
        again.Activated:Connect(function() request:InvokeServer("restart") end)
    end
end)

skip.Activated:Connect(function()
    if currentToken and not busy then busy=true;pcall(function() request:InvokeServer("skip") end);currentToken=nil;clearAnswers();feedback.Text="Skipped. Next teacher is coming in…";busy=false end
end)

task.spawn(function()
    local ok,res=pcall(function() return request:InvokeServer("state") end)
    if ok and res and res.progress then setProgress(res.progress) end
end)
