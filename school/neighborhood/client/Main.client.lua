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
local clothesFilter="All"

-- Compact floating rail from the authoritative gold-standard board.
local header=UI.surface(canvas,{Name="Header",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,4),Size=UDim2.fromOffset(760,50),BackgroundColor3=UI.P.paper,BackgroundTransparency=.03})
UI.crest(header,{Position=UDim2.fromOffset(8,7),Size=UDim2.fromOffset(34,34)})
UI.text(header,"ABVM",17,{Position=UDim2.fromOffset(48,2),Size=UDim2.fromOffset(78,23),Font=Enum.Font.GothamBold})
UI.text(header,"CATHOLIC SCHOOL",9,{Position=UDim2.fromOffset(48,24),Size=UDim2.fromOffset(104,15),Font=Enum.Font.GothamBold,TextColor3=UI.P.gold})

local wallet=UI.frame(header,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,0,8),Size=UDim2.fromOffset(104,34),BackgroundColor3=UI.P.ink})
UI.corner(wallet,UI.R.chip)
local walletText=UI.text(wallet,"0 Credits",15,{TextColor3=UI.P.paper,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,Size=UDim2.fromScale(1,1)})
local streakPill=UI.frame(header,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-120,0,8),Size=UDim2.fromOffset(106,34),BackgroundColor3=UI.P.goldSoft})
UI.corner(streakPill,UI.R.chip)
local streakText=UI.text(streakPill,"✓ 0  •  ✕ 0",12,{TextColor3=UI.P.ink,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,Size=UDim2.fromScale(1,1)})
local nav=UI.new("Frame",header,{BackgroundTransparency=1,Size=UDim2.fromOffset(300,40)})

-- Compact progression chip; expand only while a lesson can be resumed.
local goalCard=UI.surface(canvas,{Name="NextGoal",Position=UDim2.fromOffset(12,62),Size=UDim2.fromOffset(286,44),BackgroundColor3=UI.P.paper,BackgroundTransparency=.04})
local resumeButton
local goalTitle=UI.text(goalCard,"Your first home is ready",13,{Position=UDim2.fromOffset(11,3),Size=UDim2.new(1,-22,0,19),Font=Enum.Font.GothamBold,TextTruncate=Enum.TextTruncate.AtEnd})
local goalInfo=UI.text(goalCard,"Loading progress…",11,{Position=UDim2.fromOffset(11,20),Size=UDim2.new(1,-22,0,15),TextColor3=UI.P.muted,TextTruncate=Enum.TextTruncate.AtEnd})
local goalTrack=UI.frame(goalCard,{Position=UDim2.fromOffset(11,37),Size=UDim2.new(1,-22,0,4),BackgroundColor3=UI.P.line});UI.corner(goalTrack,4)
local goalFill=UI.frame(goalTrack,{Size=UDim2.fromScale(0,1),BackgroundColor3=UI.P.teal});UI.corner(goalFill,4)

local panel=UI.surface(canvas,{Name="FocusPanel",Visible=false,BackgroundColor3=UI.P.paper,BackgroundTransparency=.015,ClipsDescendants=true})
local panelTitle=UI.text(panel,"",UI.T.display,{Position=UDim2.fromOffset(18,7),Size=UDim2.new(1,-76,0,42),Font=Enum.Font.GothamBold})
local body=UI.new("ScrollingFrame",panel,{Name="Content",Position=UDim2.fromOffset(14,58),Size=UDim2.new(1,-28,1,-72),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=UI.P.muted,ScrollingDirection=Enum.ScrollingDirection.Y})
UI.stack(body,10)
UI.new("UIPadding",body,{PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,12)})

-- Sticky shop controls live outside the scrolling content.
local shopTabs=UI.new("Frame",panel,{Name="ShopTabs",Visible=false,Position=UDim2.fromOffset(14,54),Size=UDim2.new(1,-28,0,42),BackgroundTransparency=1})
local shopSubtabs=UI.new("Frame",panel,{Name="ShopSubtabs",Visible=false,Position=UDim2.fromOffset(14,99),Size=UDim2.new(1,-28,0,34),BackgroundTransparency=1})

local toast=UI.frame(canvas,{Name="Notice",Visible=false,AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-10),Size=UDim2.new(0,390,0,48),BackgroundColor3=UI.P.ink,ZIndex=30})
UI.corner(toast,UI.R.chip)
local toastText=UI.text(toast,"",14,{Size=UDim2.new(1,-24,1,-8),Position=UDim2.fromOffset(12,4),TextColor3=UI.P.white,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=31})
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
    walletText.Text=tostring(state.coins).." Credits"
    streakText.Text=string.format("✓ %d  •  ✕ %d",state.correctStreak or 0,state.wrongStreak or 0)
    local delta=state.coins-oldCoins
    if delta~=0 then
        UI.flyout(wallet,(delta>0 and "+" or "")..tostring(delta),delta>0 and UI.P.success or UI.P.negative)
    end
    if resumeButton then
        resumeButton.Visible=state.subject~=nil
        goalCard.Size=UDim2.fromOffset(286,state.subject and 84 or 44)
    end
    local goal=Catalog.ById[state.goal] or Catalog.ById.home_cottage
    if state.owned[goal.id] then
        goalTitle.Text="Made it: "..goal.name
        goalInfo.Text="Choose a new goal in the shop"
        goalFill.Size=UDim2.fromScale(1,1)
    else
        local remaining=math.max(0,goal.price-state.coins)
        goalTitle.Text="Next: "..goal.name
        local baseAnswers=math.ceil(remaining/10)
        goalInfo.Text=remaining==0
            and ("Ready to buy  •  lesson "..tostring(state.lessonCount).."/5")
            or string.format("%d Credits to go  •  ≈ %d correct or fewer",remaining,baseAnswers)
        TweenService:Create(goalFill,TweenInfo.new(.3),{Size=UDim2.fromScale(math.clamp(state.coins/math.max(1,goal.price),0,1),1)}):Play()
    end
end
local messages={
    saving="Your progress is saving. Try again in a moment.", save_unavailable="Save not confirmed. Please retry; purchases are protected against double charges.",
    profile_in_use="Your progress is open in another server. Rejoin after leaving that game.", loading="Your progress is still loading.",
    read_question="Take a moment to read the question, then choose.", question_expired="Walk into a classroom to start a new question.",
    enter_classroom="Walk into one of the six subject classrooms first.", outside_for_vehicle="Walk outside the school to call your vehicle.",
    not_enough_coins="Keep learning, or choose a smaller goal. Your Credits are safe.",not_owned="Earn and buy this item before equipping it.",
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
    panel.Visible=false;shopTabs.Visible=false;shopSubtabs.Visible=false
    goalCard.Visible=player:GetAttribute("NeighborhoodDriving")~=true
    view=nil;activeQuestion=nil
    if wasQuiz and notifyServer~=false then task.spawn(call,"dismiss",{}) end
end
UI.button(panel,"×",function() close() end,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-10,0,8),Size=UDim2.fromOffset(40,40),TextSize=24,BackgroundColor3=UI.P.white,CornerRadius=20})
local function open(kind,title)
    view=kind;panelTitle.Text=title;UI.clear(body);body.CanvasPosition=Vector2.zero;panel.Visible=true;goalCard.Visible=false
    local isShop=kind=="shop"
    shopTabs.Visible=isShop
    shopSubtabs.Visible=isShop and category=="Clothes"
    if isShop then
        body.Position=UDim2.fromOffset(14,category=="Clothes" and 138 or 100)
        body.Size=UDim2.new(1,-28,1,-(category=="Clothes" and 152 or 114))
    else
        body.Position=UDim2.fromOffset(14,58)
        body.Size=UDim2.new(1,-28,1,-72)
    end
end
local showShop,showQuestion
local function subject(id)
    for _,s in ipairs(Catalog.Subjects) do if s.id==id then return s end end
    return Catalog.Subjects[1]
end
showQuestion=function(q)
    if not q then return end
    local s=subject(q.subject)
    open("quiz",s.short.."  •  "..(s.teacher or "Classroom"))
    activeQuestion=q

    local layout=Layout.compute(canvas.AbsoluteSize.X,canvas.AbsoluteSize.Y)
    local questionColumn,answerColumn=body,body
    if layout.columns==2 and layout.landscape then
        local row=UI.new("Frame",body,{Size=UDim2.new(1,0,0,math.max(220,layout.modal.height-92)),BackgroundTransparency=1})
        questionColumn=UI.new("ScrollingFrame",row,{Size=UDim2.new(.43,-7,1,0),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=2,ScrollBarImageColor3=UI.P.muted})
        answerColumn=UI.new("ScrollingFrame",row,{Position=UDim2.new(.43,7,0,0),Size=UDim2.new(.57,-7,1,0),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=2,ScrollBarImageColor3=UI.P.muted})
        UI.stack(questionColumn,9);UI.stack(answerColumn,9)
        UI.new("UIPadding",questionColumn,{PaddingRight=UDim.new(0,3),PaddingBottom=UDim.new(0,8)})
        UI.new("UIPadding",answerColumn,{PaddingLeft=UDim.new(0,3),PaddingBottom=UDim.new(0,8)})
    end

    UI.text(questionColumn,"ASSUMPTION BVM CATHOLIC SCHOOL",UI.T.caption,{LayoutOrder=0,Size=UDim2.new(1,0,0,18),TextColor3=UI.P.gold,Font=Enum.Font.GothamBold})
    UI.text(questionColumn,s.short.."  •  "..(s.teacher or "Classroom"),UI.T.section,{LayoutOrder=1,Size=UDim2.new(1,0,0,28),Font=Enum.Font.GothamBold})

    local rewardRow=UI.new("Frame",questionColumn,{LayoutOrder=2,Size=UDim2.new(1,0,0,30),BackgroundTransparency=1})
    local rewardList=UI.new("UIListLayout",rewardRow,{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Left,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,6)})
    if q.reviewOnly then
        UI.chip(rewardRow,"Practice review",{Size=UDim2.fromOffset(104,28),BackgroundColor3=UI.P.goldSoft,TextColor3=UI.P.ink})
    else
        UI.chip(rewardRow,"+10 first try",{Size=UDim2.fromOffset(96,28),BackgroundColor3=UI.P.soft,TextColor3=UI.P.success})
        UI.chip(rewardRow,"+6 retry",{Size=UDim2.fromOffset(76,28),BackgroundColor3=UI.P.goldSoft,TextColor3=UI.P.ink})
        UI.chip(rewardRow,"streak +10",{Size=UDim2.fromOffset(86,28),BackgroundColor3=UI.P.navySoft,TextColor3=UI.P.ink})
    end

    local questionCard=UI.surface(questionColumn,{LayoutOrder=3,Size=UDim2.new(1,0,0,98),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=UI.P.white,Shadow=false})
    UI.pad(questionCard,16)
    UI.text(questionCard,q.prompt,layout.textSize,{Size=UDim2.new(1,0,0,62),AutomaticSize=Enum.AutomaticSize.Y,TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.GothamMedium})

    local feedbackFrame,feedbackText=UI.feedbackCard(questionColumn,"","hint",{LayoutOrder=10,Visible=false,TextSize=14})
    local buttons={}
    for i,choice in ipairs(q.choices) do
        local button
        button=UI.answerCard(answerColumn,string.char(64+i).."   "..choice,function()
            task.spawn(function()
                for _,b in ipairs(buttons) do b.Active=false end
                local result=call("answer",{token=q.token,choice=i})
                if activeQuestion~=q or view~="quiz" then return end
                for _,b in ipairs(buttons) do if not string.find(b.Text,"^✕") then b.Active=true end end
                if not result.ok then return end

                feedbackFrame.Visible=true
                if result.correct then
                    for _,b in ipairs(buttons) do b.Active=false end
                    button.BackgroundColor3=UI.P.success
                    button.TextColor3=UI.P.white
                    local stroke=button:FindFirstChildOfClass("UIStroke");if stroke then stroke.Color=UI.P.success end

                    local headline=result.reviewOnly and "Review complete" or ("+"..tostring(result.total).." Credits")
                    if result.streakBonus and result.streakBonus>0 then headline..="  •  streak +"..tostring(result.streakBonus) end
                    if result.bonus and result.bonus>0 then headline..="  •  +15 bonus" end
                    feedbackFrame.BackgroundColor3=Color3.fromRGB(232,245,238)
                    local feedbackStroke=feedbackFrame:FindFirstChildOfClass("UIStroke");if feedbackStroke then feedbackStroke.Color=UI.P.success end
                    feedbackText.TextColor3=UI.P.success
                    feedbackText.Text=headline.."
"..tostring(result.explanation or "")

                    UI.button(answerColumn,"Next question  →",function() showQuestion(result.next) end,{LayoutOrder=20,Size=UDim2.new(1,0,0,52),BackgroundColor3=UI.P.teal,TextColor3=UI.P.white,TextSize=16})
                    UI.button(answerColumn,"Back to exploring",function() close() end,{LayoutOrder=21,Size=UDim2.new(1,0,0,44),BackgroundColor3=UI.P.white,TextSize=13})
                else
                    button.Active=false
                    button.AutoButtonColor=false
                    button.BackgroundColor3=Color3.fromRGB(249,235,232)
                    button.TextColor3=UI.P.negative
                    button.Text="✕   "..choice
                    local stroke=button:FindFirstChildOfClass("UIStroke");if stroke then stroke.Color=UI.P.negative end

                    feedbackFrame.BackgroundColor3=Color3.fromRGB(249,235,232)
                    local feedbackStroke=feedbackFrame:FindFirstChildOfClass("UIStroke");if feedbackStroke then feedbackStroke.Color=UI.P.negative end
                    feedbackText.TextColor3=UI.P.negative
                    local penaltyText=result.message or ("Wrong streak "..tostring(result.wrongStreak or 0))
                    feedbackText.Text=penaltyText.."
Hint: "..tostring(result.hint or q.hint or "Try eliminating one answer.")
                end

                task.defer(function()
                    if feedbackFrame.Parent then
                        questionColumn.CanvasPosition=Vector2.new(0,math.max(0,questionColumn.AbsoluteCanvasSize.Y-questionColumn.AbsoluteWindowSize.Y))
                    end
                end)
            end)
        end,{LayoutOrder=3+i,Size=UDim2.new(1,0,0,layout.answerHeight),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=UI.P.white,TextSize=16})
        table.insert(buttons,button)
    end
end
resumeButton=UI.button(goalCard,"Continue this lesson",function()
    task.spawn(function()
        local result=call("study",{})
        if result.ok then showQuestion(result.question) end
    end)
end,{Position=UDim2.fromOffset(11,47),Size=UDim2.new(1,-22,0,32),Visible=false,TextSize=12,BackgroundColor3=UI.P.teal,TextColor3=UI.P.white,CornerRadius=10})
showShop=function(selected)
    category=selected or category
    open("shop","ABVM School Shop")
    local index,tier=Catalog.tier(state.earned)
    UI.text(body,tier.name.."  •  Everything is bought with learning Credits",13,{LayoutOrder=1,Size=UDim2.new(1,0,0,34),TextColor3=UI.P.muted})
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
        local remaining=math.max(0,item.price-state.coins)
        local priceStatus
        if owned then
            priceStatus="Owned"
        elseif remaining==0 then
            priceStatus="Ready • "..tostring(item.price).." Credits"
        else
            priceStatus=tostring(item.price).." Credits • "..tostring(remaining).." to go"
        end
        UI.text(card,priceStatus,16,{Position=UDim2.fromOffset(116,51),Size=UDim2.new(1,-128,0,30),TextColor3=UI.P.teal,Font=Enum.Font.GothamBold})
        UI.text(card,Catalog.Tiers[item.tier].name,12,{Position=UDim2.fromOffset(116,81),Size=UDim2.new(1,-128,0,22),TextColor3=UI.P.muted})
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
            if result.ok and command=="school" then notify("Choose an Assumption BVM classroom. Walk through its doorway to begin.") end
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
            notify("Your home and starter ride are free. Head to Assumption BVM to earn your first upgrade.")
            break
        end
        task.wait(2)
    end
end)
