--!strict
-- iPhone-first UI: native movement stays intact; only visible controls are active.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local shared=ReplicatedStorage:WaitForChild("NeighborhoodShared")
local Catalog=require(shared:WaitForChild("Catalog"))
local Layout=require(shared:WaitForChild("Layout"))
local UI=require(script.Parent:WaitForChild("UI"))
local remotes=ReplicatedStorage:WaitForChild("NeighborhoodRemotes")
local request=remotes:WaitForChild("Request")
local changed=remotes:WaitForChild("Changed")
local drive=remotes:WaitForChild("Drive")
local gui=UI.new("ScreenGui",player:WaitForChild("PlayerGui"),{Name="PipNeighborhoodUI",ResetOnSpawn=false,DisplayOrder=20,IgnoreGuiInset=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local canvas=UI.new("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
local state={ready=false,coins=0,earned=0,lost=0,correct=0,answers=0,accuracyBasisPoints=0,correctStreak=0,wrongStreak=0,lessonCount=0,owned={},equipped={},goal="home_cottage"}
local view=nil
local activeQuestion=nil
local busy=false
local category="Homes"
local header=UI.frame(canvas,{Name="Header",Position=UDim2.fromOffset(8,4),Size=UDim2.new(1,-16,0,52),BackgroundColor3=UI.P.paper})
UI.stroke(header)
UI.text(header,"PIP HIGH",17,{Position=UDim2.fromOffset(12,5),Size=UDim2.fromOffset(94,38),Font=Enum.Font.GothamBold})
local wallet=UI.frame(header,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,0,6),Size=UDim2.fromOffset(110,38),BackgroundColor3=UI.P.ink})
local walletText=UI.text(wallet,"0 coins",17,{TextColor3=UI.P.paper,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,Size=UDim2.fromScale(1,1)})
local nav=UI.new("Frame",header,{BackgroundTransparency=1,Size=UDim2.fromOffset(320,44)})
local goalCard=UI.frame(canvas,{Name="NextGoal",Position=UDim2.fromOffset(12,68),Size=UDim2.fromOffset(274,96),BackgroundColor3=UI.P.paper})
UI.stroke(goalCard)
local resumeButton
local goalTitle=UI.text(goalCard,"Your first home is ready",14,{Position=UDim2.fromOffset(12,5),Size=UDim2.new(1,-24,0,28),Font=Enum.Font.GothamBold})
local goalInfo=UI.text(goalCard,"Loading your progress…",13,{Position=UDim2.fromOffset(12,32),Size=UDim2.new(1,-24,0,25),TextColor3=UI.P.muted})
local goalTrack=UI.frame(goalCard,{Position=UDim2.fromOffset(12,64),Size=UDim2.new(1,-24,0,7),BackgroundColor3=UI.P.line});UI.corner(goalTrack,4)
local goalFill=UI.frame(goalTrack,{Size=UDim2.fromScale(0,1),BackgroundColor3=UI.P.teal});UI.corner(goalFill,4)
local streakInfo=UI.text(goalCard,"Accuracy —  •  Correct streak 0",11,{Position=UDim2.fromOffset(12,76),Size=UDim2.new(1,-24,0,16),TextColor3=UI.P.muted})
local panel=UI.frame(canvas,{Name="FocusPanel",Visible=false,BackgroundColor3=UI.P.paper,ClipsDescendants=true})
UI.stroke(panel)
local panelTitle=UI.text(panel,"",21,{Position=UDim2.fromOffset(18,9),Size=UDim2.new(1,-105,0,42),Font=Enum.Font.GothamBold})
local body=UI.new("ScrollingFrame",panel,{Name="Content",Position=UDim2.fromOffset(14,64),Size=UDim2.new(1,-28,1,-78),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,ScrollBarImageColor3=UI.P.muted,ScrollingDirection=Enum.ScrollingDirection.Y})
UI.stack(body,10)
UI.new("UIPadding",body,{PaddingRight=UDim.new(0,5),PaddingBottom=UDim.new(0,12)})
local toast=UI.frame(canvas,{Name="Notice",Visible=false,AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-10),Size=UDim2.new(0,430,0,58),BackgroundColor3=UI.P.ink,ZIndex=30})
local toastText=UI.text(toast,"",15,{Size=UDim2.new(1,-28,1,-12),Position=UDim2.fromOffset(14,6),TextColor3=UI.P.white,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=31})
local toastSerial=0
local function notify(message)
    toastSerial+=1;local serial=toastSerial
    toastText.Text=message;toast.Visible=true
    task.delay(4,function() if toastSerial==serial then toast.Visible=false end end)
end
local function update(snapshot)
    if not snapshot or not snapshot.ready then return end
    local oldCoins=state.coins
    state=snapshot
    walletText.Text=tostring(state.coins).." coins"
    streakInfo.Text=string.format("%.1f%% correct  •  +%d / -%d streak",(state.accuracyBasisPoints or 0)/100,state.correctStreak or 0,state.wrongStreak or 0)
    if state.coins>oldCoins then UI.flash(wallet) end
    if resumeButton then
        resumeButton.Visible=state.subject~=nil
        goalCard.Size=UDim2.fromOffset(274,state.subject and 148 or 96)
    end
    local goal=Catalog.ById[state.goal] or Catalog.ById.home_cottage
    if state.owned[goal.id] then
        goalTitle.Text="Made it: "..goal.name
        goalInfo.Text="Choose your next goal in the shop"
        goalFill.Size=UDim2.fromScale(1,1)
    else
        goalTitle.Text="Next: "..goal.name
        goalInfo.Text=string.format("%d / %d coins  •  Lesson %d/5",state.coins,goal.price,state.lessonCount)
        TweenService:Create(goalFill,TweenInfo.new(.3),{Size=UDim2.fromScale(math.clamp(state.coins/math.max(1,goal.price),0,1),1)}):Play()
    end
end
local messages={
    saving="Your progress is saving. Try again in a moment.", save_unavailable="Save not confirmed. Please retry; purchases are protected against double charges.",
    profile_in_use="Your progress is open in another server. Rejoin after leaving that game.", loading="Your progress is still loading.",
    read_question="Take a moment to read the question, then choose.", question_expired="Walk into a classroom to start a new question.",
    enter_classroom="Walk into one of the four subject classrooms first.", outside_for_vehicle="Walk outside the school to call your vehicle.",
    not_enough_coins="Keep learning, or choose a smaller goal. Your coins are safe.",not_owned="Earn and buy this item before equipping it.",
    temporarily_unavailable="That did not finish. Please try again.",slow_down="One action at a time.",travel_cooldown="You're already on your way. Try again shortly.",
}
local function call(command,args)
    if busy then return {ok=false,code="saving"} end
    busy=true
    local ok,result=pcall(function() return request:InvokeServer(command,args or {}) end)
    busy=false
    if not ok or type(result)~="table" then notify("Connection interrupted. Your saved progress has not been reset.");return {ok=false} end
    if result.state then update(result.state) end
    if not result.ok then notify(messages[result.code] or "That action is unavailable right now.") end
    return result
end
local function close(notifyServer)
    local wasQuiz=view=="quiz"
    panel.Visible=false;goalCard.Visible=true;view=nil;activeQuestion=nil
    if wasQuiz and notifyServer~=false then task.spawn(call,"dismiss",{}) end
end
UI.button(panel,"Close",function() close() end,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,9),Size=UDim2.fromOffset(72,44),TextSize=14,BackgroundColor3=UI.P.white})
local function open(kind,title)
    view=kind;panelTitle.Text=title;UI.clear(body);body.CanvasPosition=Vector2.zero;panel.Visible=true;goalCard.Visible=false
end
local showShop,showQuestion
local function subject(id)
    for _,s in ipairs(Catalog.Subjects) do if s.id==id then return s end end
    return Catalog.Subjects[1]
end
showQuestion=function(q)
    if not q then return end
    local s=subject(q.subject)
    open("quiz",s.short.." classroom")
    activeQuestion=q
    local questionColumn, answerColumn=body,body
    if canvas.AbsoluteSize.X>=680 and canvas.AbsoluteSize.Y<520 then
        local row=UI.new("Frame",body,{Size=UDim2.new(1,0,0,math.max(120,body.AbsoluteSize.Y-4)),BackgroundTransparency=1})
        questionColumn=UI.new("ScrollingFrame",row,{Size=UDim2.new(.47,-6,1,0),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=3})
        answerColumn=UI.new("ScrollingFrame",row,{Position=UDim2.new(.47,6,0,0),Size=UDim2.new(.53,-6,1,0),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=3})
        UI.stack(questionColumn,8);UI.stack(answerColumn,8)
    end
    local info=UI.text(questionColumn,q.reviewOnly and "PRACTICE REVIEW  •  No coins for an immediate repeat" or "25 first try  •  15 after retry  •  correct streak bonus up to +25",13,{LayoutOrder=1,Size=UDim2.new(1,0,0,26),TextColor3=UI.P.teal,Font=Enum.Font.GothamBold})
    local questionCard=UI.frame(questionColumn,{LayoutOrder=2,Size=UDim2.new(1,0,0,84),AutomaticSize=Enum.AutomaticSize.Y})
    UI.pad(questionCard,16)
    UI.text(questionCard,q.prompt,canvas.AbsoluteSize.Y<520 and 17 or 20,{Size=UDim2.new(1,0,0,52),AutomaticSize=Enum.AutomaticSize.Y,TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.GothamMedium})
    local feedback=UI.text(questionColumn,"",16,{LayoutOrder=10,Visible=false,Size=UDim2.new(1,-4,0,48),AutomaticSize=Enum.AutomaticSize.Y,TextColor3=UI.P.teal})
    local buttons={}
    for i,choice in ipairs(q.choices) do
        local button
        button=UI.button(answerColumn,string.char(64+i).."   "..choice,function()
            task.spawn(function()
                for _,b in ipairs(buttons) do b.Active=false end
                local result=call("answer",{token=q.token,choice=i})
                if activeQuestion~=q or view~="quiz" then return end
                for _,b in ipairs(buttons) do b.Active=true end
                if not result.ok then return end
                feedback.Visible=true
                if result.correct then
                    for _,b in ipairs(buttons) do b.Active=false;b.Visible=false end
                    button.BackgroundColor3=UI.P.teal;button.TextColor3=UI.P.white
                    local headline=result.reviewOnly and "Review complete." or "+"..tostring(result.total).." coins saved!"
                    if result.streakBonus and result.streakBonus>0 then headline..="  Streak +"..tostring(result.streakBonus).."." end
                    if result.bonus and result.bonus>0 then headline..="  Includes your +50 lesson bonus." end
                    feedback.Text=headline.."\n"..result.explanation
                    info.Text=string.format("Lesson %d / 5  •  Every 5 different questions earns +50",state.lessonCount)
                    UI.button(answerColumn,"Next question  →",function() showQuestion(result.next) end,{LayoutOrder=11,BackgroundColor3=UI.P.ink,TextColor3=UI.P.white})
                    UI.button(answerColumn,"Back to exploring",function() close() end,{LayoutOrder=12,BackgroundColor3=UI.P.white,TextSize=14})
                else
                    button.BackgroundColor3=Color3.fromRGB(247,232,220)
                    local penaltyText=result.message or ("Wrong streak "..tostring(result.wrongStreak or 0))
                    feedback.Text=penaltyText.."\n"..result.explanation.."\nChoose another answer to break the negative streak."
                    feedback.TextColor3=UI.P.ink
                end
                -- Keep feedback reachable without forcing the user to hunt beneath long passages.
                task.defer(function() if feedback.Parent then questionColumn.CanvasPosition=Vector2.new(0,math.max(0,questionColumn.AbsoluteCanvasSize.Y-questionColumn.AbsoluteWindowSize.Y)) end end)
            end)
        end,{LayoutOrder=2+i,Size=UDim2.new(1,0,0,54),AutomaticSize=Enum.AutomaticSize.Y,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=UI.P.white,TextSize=17})
        UI.pad(button,14);UI.stroke(button);table.insert(buttons,button)
    end
end
resumeButton=UI.button(goalCard,"Continue this lesson",function()
    task.spawn(function()
        local result=call("study",{})
        if result.ok then showQuestion(result.question) end
    end)
end,{Position=UDim2.fromOffset(12,98),Size=UDim2.new(1,-24,0,44),Visible=false,TextSize=14,BackgroundColor3=UI.P.teal,TextColor3=UI.P.white})
showShop=function(selected)
    category=selected or category
    open("shop","Campus shop")
    local index,tier=Catalog.tier(state.earned)
    UI.text(body,tier.name.."  •  Everything is bought with learning coins",13,{LayoutOrder=1,Size=UDim2.new(1,0,0,34),TextColor3=UI.P.muted})
    local tabs=UI.new("Frame",body,{LayoutOrder=2,Size=UDim2.new(1,0,0,44),BackgroundTransparency=1})
    for i,name in ipairs({"Homes","Clothes","Items","Vehicles"}) do
        UI.button(tabs,name,function() showShop(name) end,{Position=UDim2.new((i-1)/4,3,0,0),Size=UDim2.new(.25,-6,1,0),TextSize=13,BackgroundColor3=name==category and UI.P.ink or UI.P.white,TextColor3=name==category and UI.P.white or UI.P.ink})
    end
    local number=0
    for _,item in ipairs(Catalog.Items) do
        if item.category~=category then continue end
        number+=1
        local owned=state.owned[item.id]==true
        local equipped=state.equipped.home==item.id or state.equipped.outfit==item.id or state.equipped.vehicle==item.id
        local card=UI.frame(body,{Name=item.id,LayoutOrder=number+2,Size=UDim2.new(1,0,0,210)})
        UI.stroke(card)
        UI.preview(card,item)
        UI.text(card,item.name,18,{Position=UDim2.fromOffset(116,10),Size=UDim2.new(1,-128,0,40),Font=Enum.Font.GothamBold})
        UI.text(card,owned and "Owned" or (tostring(item.price).." coins"),17,{Position=UDim2.fromOffset(116,51),Size=UDim2.new(1,-128,0,26),TextColor3=UI.P.teal,Font=Enum.Font.GothamBold})
        UI.text(card,Catalog.Tiers[item.tier].name,12,{Position=UDim2.fromOffset(116,79),Size=UDim2.new(1,-128,0,24),TextColor3=UI.P.muted})
        UI.text(card,item.description,14,{Position=UDim2.fromOffset(12,107),Size=UDim2.new(1,-24,0,42),TextColor3=UI.P.muted})
        local label=owned and (item.category=="Items" and "Placed / worn" or (equipped and "Equipped" or "Equip")) or "Buy • "..item.price
        local action=UI.button(card,label,function()
            task.spawn(function()
                local result=call(owned and "equip" or "buy",{itemId=item.id})
                if result.ok then
                    notify(owned and (item.name.." equipped.") or (item.name.." is yours. Saved to your profile."))
                    if view=="shop" then showShop(category) end
                end
            end)
        end,{Position=UDim2.fromOffset(12,156),Size=UDim2.new(.62,-18,0,44),TextSize=14,BackgroundColor3=UI.P.ink,TextColor3=UI.P.white})
        if owned and (equipped or item.category=="Items") then action.Active=false;action.BackgroundColor3=UI.P.soft;action.TextColor3=UI.P.teal end
        UI.button(card,state.goal==item.id and "Your goal" or "Set goal",function()
            task.spawn(function()
                local result=call("goal",{itemId=item.id})
                if result.ok and view=="shop" then showShop(category) end
            end)
        end,{Position=UDim2.new(.62,0,0,156),Size=UDim2.new(.38,-12,0,44),TextSize=13,BackgroundColor3=UI.P.soft})
    end
end
local navButtons={}
for i,definition in ipairs({{"School","school"},{"Home","home"},{"Shop","shop"},{"Ride","vehicle"}}) do
    local label,command=definition[1],definition[2]
    local b=UI.button(nav,label,function()
        if not state.ready then notify("Your saved progress is still loading.");return end
        if command=="shop" then showShop();return end
        close(false)
        task.spawn(function()
            local result=call(command,{})
            if result.ok and command=="school" then notify("Choose a colored classroom. Walk through its doorway to begin.") end
            if result.ok and command=="vehicle" then notify("Use the driving controls or your thumbstick. Park returns normal walking.") end
        end)
    end,{Position=UDim2.fromOffset((i-1)*80,0),Size=UDim2.fromOffset(74,44),TextSize=14,BackgroundColor3=UI.P.white})
    table.insert(navButtons,b)
end
local driving=UI.frame(canvas,{Name="DrivingControls",Visible=false,AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-8),Size=UDim2.fromOffset(362,66),BackgroundColor3=UI.P.paper})
UI.stroke(driving)
local held={};local heldInputs={};local driveButtons={}
for i,d in ipairs({{"Left","left"},{"Back","back"},{"Go","go"},{"Right","right"}}) do
    local key=d[2]
    local b=UI.button(driving,d[1],function() end,{Position=UDim2.fromOffset(6+(i-1)*70,7),Size=UDim2.fromOffset(64,52),TextSize=13})
    table.insert(driveButtons,b)
    b.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then held[key]=true;heldInputs[input]=key end
    end)
end
local parkButton=UI.button(driving,"Park",function() task.spawn(call,"park",{}) end,{Position=UDim2.fromOffset(286,7),Size=UDim2.fromOffset(68,52),TextSize=13,BackgroundColor3=UI.P.ink,TextColor3=UI.P.white})
UserInputService.InputEnded:Connect(function(input) local key=heldInputs[input];if key then held[key]=false;heldInputs[input]=nil end end)
UserInputService.WindowFocusReleased:Connect(function() table.clear(held);table.clear(heldInputs);drive:FireServer(0,0) end)
local function reflow()
    local size=canvas.AbsoluteSize
    local layout=Layout.compute(size.X,size.Y)
    header.Size=UDim2.new(1,-16,0,layout.headerHeight)
    if size.X<600 then
        nav.Position=UDim2.new(.5,0,0,55);nav.AnchorPoint=Vector2.new(.5,0)
        nav.Size=UDim2.fromOffset(math.min(320,size.X-28),44)
    else
        nav.Position=UDim2.new(.5,-4,0,6);nav.AnchorPoint=Vector2.new(.5,0);nav.Size=UDim2.fromOffset(320,44)
    end
    for i,b in ipairs(navButtons) do b.Size=UDim2.new(.25,-6,1,0);b.Position=UDim2.new((i-1)*.25,3,0,0) end
    local m=layout.modal
    panel.Position=UDim2.fromOffset(m.x,m.y);panel.Size=UDim2.fromOffset(m.width,m.height)
    goalCard.Position=UDim2.fromOffset(12,layout.headerHeight+16)
    toast.Size=UDim2.fromOffset(math.min(430,size.X-24),58)
    driving.Size=UDim2.fromOffset(math.min(362,size.X-12),66)
    for i,b in ipairs(driveButtons) do b.Position=UDim2.new((i-1)/5,4,0,7);b.Size=UDim2.new(.2,-8,0,52) end
    parkButton.Position=UDim2.new(.8,4,0,7);parkButton.Size=UDim2.new(.2,-8,0,52)
end
canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(reflow)
reflow()
changed.OnClientEvent:Connect(function(packet)
    if type(packet)~="table" then return end
    update(packet.state)
    if packet.kind=="question" then showQuestion(packet.data)
    elseif packet.kind=="left_classroom" then if view=="quiz" then close(false) end
    elseif packet.kind=="shop" then showShop()
    elseif packet.data and packet.data.message then notify(packet.data.message) end
end)
player:GetAttributeChangedSignal("NeighborhoodDriving"):Connect(function()
    driving.Visible=player:GetAttribute("NeighborhoodDriving")==true
    if not driving.Visible then table.clear(held);table.clear(heldInputs) end
end)
UserInputService.InputBegan:Connect(function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.Escape then close() end
end)
task.spawn(function()
    local controls=nil
    while task.wait(.1) do
        if not driving.Visible then continue end
        if not controls then
            local module=player.PlayerScripts:FindFirstChild("PlayerModule")
            if module then local ok,value=pcall(require,module);if ok then controls=value:GetControls() end end
        end
        local throttle=(held.go and 1 or 0)-(held.back and 1 or 0)
        local steer=(held.right and 1 or 0)-(held.left and 1 or 0)
        if UserInputService:GetFocusedTextBox()==nil then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then throttle=1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then throttle=-1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then steer=-1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then steer=1 end
        end
        if controls and throttle==0 and steer==0 then
            local vector=controls:GetMoveVector();throttle=math.clamp(-vector.Z,-1,1);steer=math.clamp(vector.X,-1,1)
        end
        drive:FireServer(throttle,steer)
    end
end)
task.spawn(function()
    for _=1,25 do
        if state.ready then break end
        local result=call("state",{})
        if result.state and result.state.ready then
            update(result.state)
            notify("Your home and starter ride are free. Visit a classroom to earn your first upgrade.")
            break
        end
        task.wait(2)
    end
end)
