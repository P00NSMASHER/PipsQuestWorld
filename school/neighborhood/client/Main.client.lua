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
local gui=UI.new("ScreenGui",player:WaitForChild("PlayerGui"),{Name="PipNeighborhoodUI",ResetOnSpawn=false,DisplayOrder=20,IgnoreGuiInset=true,ScreenInsets=Enum.ScreenInsets.None,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
gui:SetAttribute("RobloxPlaceVersion",game.PlaceVersion)
local canvas=UI.new("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
local state={ready=false,coins=0,earned=0,lost=0,correct=0,answers=0,accuracyBasisPoints=0,correctStreak=0,wrongStreak=0,lessonCount=0,owned={},equipped={},goal="home_cottage"}
local view=nil
local activeQuestion=nil
local busy=false
local category="Homes"
local locationCommand=nil
local clothesFilter="All"
local homeFilter="All"
local vehicleFilter="All"

-- User-approved exploration HUD: one CoreGui-height capsule plus a right-side nav rail.
local header=UI.surface(canvas,{Name="Header",AnchorPoint=Vector2.new(0,0),Position=UDim2.fromOffset(0,15),Size=UDim2.fromOffset(650,56),BackgroundColor3=UI.P.ink,BackgroundTransparency=.02,CornerRadius=999})
local avatar=UI.new("ImageLabel",header,{Position=UDim2.fromOffset(8,8),Size=UDim2.fromOffset(40,40),BackgroundColor3=UI.P.navySoft,BorderSizePixel=0,Image="rbxthumb://type=AvatarHeadShot&id="..tostring(player.UserId).."&w=150&h=150",ScaleType=Enum.ScaleType.Crop})
UI.corner(avatar,999);UI.stroke(avatar,UI.P.gold)
local nameText=UI.text(header,player.DisplayName,16,{Position=UDim2.fromOffset(56,5),Size=UDim2.fromOffset(144,23),Font=Enum.Font.GothamBold,TextColor3=UI.P.white,TextTruncate=Enum.TextTruncate.AtEnd})
local gradeText=UI.text(header,"GRADE 2  •  ABVM  •  v"..tostring(game.PlaceVersion),9,{Position=UDim2.fromOffset(56,27),Size=UDim2.fromOffset(146,16),Font=Enum.Font.GothamBold,TextColor3=UI.P.gold,TextTruncate=Enum.TextTruncate.AtEnd})
local profileDivider=UI.frame(header,{Position=UDim2.fromOffset(204,13),Size=UDim2.fromOffset(1,30),BackgroundColor3=Color3.fromRGB(102,120,143),BackgroundTransparency=.25})
UI.corner(profileDivider,1)

local wallet=UI.frame(header,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,0,8),Size=UDim2.fromOffset(108,40),BackgroundColor3=UI.P.gold})
UI.corner(wallet,UI.R.chip)
local coinIcon=UI.frame(wallet,{Position=UDim2.fromOffset(5,5),Size=UDim2.fromOffset(30,30),BackgroundColor3=UI.P.ink})
UI.corner(coinIcon,999)
UI.text(coinIcon,"C",12,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,TextColor3=UI.P.gold})
local walletText=UI.text(wallet,"0",15,{Position=UDim2.fromOffset(40,2),Size=UDim2.new(1,-46,0,20),TextColor3=UI.P.ink,Font=Enum.Font.GothamBold})
UI.text(wallet,"CREDITS",8,{Position=UDim2.fromOffset(40,20),Size=UDim2.new(1,-46,0,13),TextColor3=Color3.fromRGB(75,64,35),Font=Enum.Font.GothamBold})

-- Streak state is preserved for feedback logic but is intentionally not a permanent explore-mode block.
local streakPill=UI.frame(header,{Visible=false,Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(1,1),BackgroundColor3=UI.P.teal})
local streakIcon=UI.frame(streakPill,{Size=UDim2.fromOffset(1,1),BackgroundColor3=Color3.fromRGB(24,78,58)})
local streakIconText=UI.text(streakIcon,"✦",1,{Size=UDim2.fromScale(1,1),TextColor3=UI.P.white})
local streakText=UI.text(streakPill,"0",1,{Size=UDim2.fromScale(1,1),TextColor3=UI.P.white})
local streakCaption=UI.text(streakPill,"STREAK",1,{Size=UDim2.fromScale(1,1),TextColor3=Color3.fromRGB(220,239,231)})

local nav=UI.frame(canvas,{Name="PrimaryNav",BackgroundColor3=UI.P.ink,BackgroundTransparency=.04,Size=UDim2.fromOffset(104,212)})
UI.corner(nav,18);UI.stroke(nav,Color3.fromRGB(46,67,93))

-- Next reward is integrated into the navy player capsule instead of floating as a second card.
local goalCard=UI.new("Frame",header,{Name="NextGoal",Position=UDim2.fromOffset(208,5),Size=UDim2.fromOffset(312,46),BackgroundTransparency=1,BorderSizePixel=0})
local goalIcon=UI.frame(goalCard,{Position=UDim2.fromOffset(0,7),Size=UDim2.fromOffset(32,32),BackgroundColor3=UI.P.success})
UI.corner(goalIcon,999)
local function renderGoalIcon(kind)
    local old=goalIcon:FindFirstChild("Icon")
    if old then old:Destroy() end
    UI.vectorIcon(goalIcon,kind,UI.P.white,4)
end
renderGoalIcon("home")
local resumeButton
local goalTitle=UI.text(goalCard,"Cozy Cottage",11,{Position=UDim2.fromOffset(40,1),Size=UDim2.new(1,-104,0,18),Font=Enum.Font.GothamBold,TextColor3=UI.P.white,TextTruncate=Enum.TextTruncate.AtEnd})
local bonusChip=UI.frame(goalCard,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-4,0,2),Size=UDim2.fromOffset(52,22),BackgroundColor3=UI.P.ink})
UI.corner(bonusChip,999);UI.stroke(bonusChip,UI.P.gold)
local bonusText=UI.text(bonusChip,"★ 0/5",9,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,TextColor3=UI.P.gold})
local goalInfo=UI.text(goalCard,"0 / 400",10,{Position=UDim2.fromOffset(40,18),Size=UDim2.new(1,-96,0,15),TextColor3=Color3.fromRGB(207,218,231),TextTruncate=Enum.TextTruncate.AtEnd})
local goalTrack=UI.frame(goalCard,{Position=UDim2.fromOffset(40,37),Size=UDim2.new(1,-96,0,4),BackgroundColor3=Color3.fromRGB(73,103,133)});UI.corner(goalTrack,4)
local goalFill=UI.frame(goalTrack,{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(94,151,183)});UI.corner(goalFill,4)

local panel=UI.surface(canvas,{Name="FocusPanel",Visible=false,BackgroundColor3=UI.P.white,BackgroundTransparency=.01,ClipsDescendants=true})
local panelScale=UI.new("UIScale",panel,{Scale=1})
local panelHeader=UI.frame(panel,{Name="PanelHeader",Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,50),BackgroundColor3=UI.P.ink,ZIndex=3})
UI.corner(panelHeader,18)
local panelHeaderMask=UI.frame(panelHeader,{Position=UDim2.new(0,0,1,-18),Size=UDim2.new(1,0,0,18),BackgroundColor3=UI.P.ink,ZIndex=3})
local panelTitle=UI.text(panelHeader,"",UI.T.section,{Position=UDim2.fromOffset(54,4),Size=UDim2.new(1,-108,0,42),Font=Enum.Font.GothamBold,TextColor3=UI.P.white,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=4})
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
    local wasReady=state.ready
    local oldCoins=state.coins
    state=snapshot
    walletText.Text=tostring(state.coins)
    bonusText.Text="★ "..tostring(state.lessonCount or 0).."/5"
    if (state.wrongStreak or 0)>0 then
        streakText.Text=tostring(state.wrongStreak)
        streakCaption.Text="WRONG STREAK"
        streakPill.BackgroundColor3=UI.P.negative
        streakIcon.BackgroundColor3=Color3.fromRGB(133,61,57)
        streakIconText.Text="✕"
        streakText.TextColor3=UI.P.white
        streakCaption.TextColor3=Color3.fromRGB(250,226,224)
    else
        streakText.Text=tostring(state.correctStreak or 0)
        streakCaption.Text="STREAK"
        streakPill.BackgroundColor3=UI.P.teal
        streakIcon.BackgroundColor3=Color3.fromRGB(24,78,58)
        streakIconText.Text="✦"
        streakText.TextColor3=UI.P.white
        streakCaption.TextColor3=Color3.fromRGB(220,239,231)
    end
    local delta=state.coins-oldCoins
    if wasReady and delta~=0 then
        UI.flyout(wallet,(delta>0 and "+" or "")..tostring(delta),delta>0 and UI.P.success or UI.P.negative)
    end
    if resumeButton then
        resumeButton.Visible=state.subject~=nil
        bonusChip.Visible=state.subject==nil
    end
    local goal=Catalog.ById[state.goal] or Catalog.ById.home_cottage
    local goalKinds={Homes="home",Vehicles="vehicle",Clothes="apparel",Items="items"}
    local goalColors={Homes=UI.P.success,Vehicles=Color3.fromRGB(58,124,219),Clothes=UI.P.gold,Items=UI.P.ink}
    renderGoalIcon(goalKinds[goal.category] or "home")
    goalIcon.BackgroundColor3=goalColors[goal.category] or UI.P.success
    if state.owned[goal.id] then
        goalTitle.Text=goal.name
        goalInfo.Text="OWNED"
        goalFill.Size=UDim2.fromScale(1,1)
    else
        goalTitle.Text=goal.name
        goalInfo.Text=string.format("%d / %d",math.min(state.coins,goal.price),goal.price)
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
local showShop,showQuestion,setNavActive,showAvatar,showClasses
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
    if setNavActive then setNavActive(locationCommand) end
    if wasQuiz and notifyServer~=false then task.spawn(call,"dismiss",{}) end
end
UI.button(panelHeader,"‹",function() close() end,{Position=UDim2.fromOffset(8,7),Size=UDim2.fromOffset(36,36),TextSize=28,BackgroundColor3=UI.P.paper,TextColor3=UI.P.ink,CornerRadius=999,ZIndex=5})
local function open(kind,title)
    view=kind;panelTitle.Text=title;UI.clear(body);body.CanvasPosition=Vector2.zero;panel.Visible=true;goalCard.Visible=false
    panelScale.Scale=.975
    TweenService:Create(panelScale,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1}):Play()
    local isShop=kind=="shop"
    local layout=Layout.compute(canvas.AbsoluteSize.X,canvas.AbsoluteSize.Y)
    shopTabs.Visible=isShop
    local hasSubtabs=isShop and (category=="Clothes" or category=="Homes" or category=="Vehicles")
    shopSubtabs.Visible=hasSubtabs
    panelTitle.Visible=true
    panelHeader.Visible=true
    if isShop then
        if layout.compact and layout.landscape then
            shopTabs.Position=UDim2.fromOffset(14,54)
            shopTabs.Size=UDim2.new(1,-28,0,34)
            shopSubtabs.Position=UDim2.fromOffset(14,91)
            shopSubtabs.Size=UDim2.new(1,-28,0,28)
            local top=hasSubtabs and 123 or 92
            body.Position=UDim2.fromOffset(14,top)
            body.Size=UDim2.new(1,-28,1,-(top+12))
        else
            shopTabs.Position=UDim2.fromOffset(14,56)
            shopTabs.Size=UDim2.new(1,-28,0,40)
            shopSubtabs.Position=UDim2.fromOffset(14,99)
            shopSubtabs.Size=UDim2.new(1,-28,0,32)
            body.Position=UDim2.fromOffset(14,hasSubtabs and 136 or 99)
            body.Size=UDim2.new(1,-28,1,-(hasSubtabs and 148 or 112))
        end
    else
        body.Position=UDim2.fromOffset(14,58)
        body.Size=UDim2.new(1,-28,1,-72)
    end
end
local function subject(id)
    for _,s in ipairs(Catalog.Subjects) do if s.id==id then return s end end
    return Catalog.Subjects[1]
end

local subjectVisuals={
    math={color=Color3.fromRGB(224,82,97),icon="×÷"},
    reading={color=Color3.fromRGB(116,105,218),icon="▤"},
    religion={color=Color3.fromRGB(59,151,95),icon="✝"},
    spelling={color=Color3.fromRGB(224,165,56),icon="ABC"},
    grammar={color=Color3.fromRGB(58,124,219),icon="✎"},
    vocabulary={color=Color3.fromRGB(111,92,207),icon="…"},
}
local function subjectVisual(id)
    return subjectVisuals[id] or {color=UI.P.teal,icon="•"}
end

showClasses=function()
    if setNavActive then setNavActive("school") end
    open("classes","▤  Classes")
    UI.text(body,"ASSUMPTION BVM CATHOLIC SCHOOL",UI.T.caption,{
        LayoutOrder=1,Size=UDim2.new(1,0,0,20),TextColor3=UI.P.gold,Font=Enum.Font.GothamBold,
    })
    UI.text(body,"Choose a classroom, then walk through its doorway to begin.",13,{
        LayoutOrder=2,Size=UDim2.new(1,0,0,30),TextColor3=UI.P.muted,
    })
    local layout=Layout.compute(canvas.AbsoluteSize.X,canvas.AbsoluteSize.Y)
    local columns=layout.landscape and layout.columns or 1
    local rows=math.ceil(#Catalog.Subjects/columns)
    local grid=UI.new("Frame",body,{LayoutOrder=3,Size=UDim2.new(1,0,0,rows*66+(rows-1)*8),BackgroundTransparency=1})
    UI.new("UIGridLayout",grid,{
        CellPadding=UDim2.fromOffset(8,8),
        CellSize=UDim2.new(1/columns,-(8*(columns-1))/columns,0,66),
        FillDirectionMaxCells=columns,
        SortOrder=Enum.SortOrder.LayoutOrder,
    })
    for i,s in ipairs(Catalog.Subjects) do
        local visual=subjectVisual(s.id)
        local cardTint=visual.color:Lerp(UI.P.white,.88)
        local card=UI.surface(grid,{LayoutOrder=i,BackgroundColor3=cardTint,Shadow=false})
        local cardStroke=card:FindFirstChildOfClass("UIStroke")
        if cardStroke then cardStroke.Color=visual.color;cardStroke.Transparency=.58 end
        local accent=UI.frame(card,{Position=UDim2.fromOffset(5,10),Size=UDim2.fromOffset(4,44),BackgroundColor3=visual.color})
        UI.corner(accent,999)
        local iconTile=UI.frame(card,{Position=UDim2.fromOffset(14,10),Size=UDim2.fromOffset(44,44),BackgroundColor3=visual.color})
        UI.corner(iconTile,11)
        UI.text(iconTile,visual.icon,visual.icon=="ABC" and 10 or 18,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,TextColor3=UI.P.white})
        UI.text(card,s.short,16,{Position=UDim2.fromOffset(68,7),Size=UDim2.new(1,-86,0,25),Font=Enum.Font.GothamBold})
        UI.text(card,s.teacher or "Classroom",12,{Position=UDim2.fromOffset(68,32),Size=UDim2.new(1,-86,0,20),TextColor3=UI.P.muted})
        UI.text(card,"›",21,{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-10,.5,0),Size=UDim2.fromOffset(18,30),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=visual.color})
    end
    UI.chip(body,"Six ABVM classrooms • one clear learning path",{LayoutOrder=4,Size=UDim2.fromOffset(292,30),BackgroundColor3=UI.P.soft,TextColor3=UI.P.teal})
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
    local quizVisual=subjectVisual(s.id)
    local subjectRow=UI.new("Frame",questionColumn,{LayoutOrder=1,Size=UDim2.new(1,0,0,34),BackgroundTransparency=1})
    local subjectBadge=UI.frame(subjectRow,{Position=UDim2.fromOffset(0,2),Size=UDim2.fromOffset(30,30),BackgroundColor3=quizVisual.color})
    UI.corner(subjectBadge,9)
    UI.text(subjectBadge,quizVisual.icon,quizVisual.icon=="ABC" and 8 or 14,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,TextColor3=UI.P.white})
    UI.text(subjectRow,s.short.."  •  "..(s.teacher or "Classroom"),UI.T.section,{Position=UDim2.fromOffset(38,0),Size=UDim2.new(1,-38,1,0),Font=Enum.Font.GothamBold})

    local progressRow=UI.new("Frame",questionColumn,{LayoutOrder=2,Size=UDim2.new(1,0,0,28),BackgroundTransparency=1})
    local progressTrack=UI.frame(progressRow,{Position=UDim2.fromOffset(0,8),Size=UDim2.new(1,-54,0,7),BackgroundColor3=UI.P.line})
    UI.corner(progressTrack,999)
    local lessonFraction=math.clamp((state.lessonCount or 0)/5,0,1)
    local progressFill=UI.frame(progressTrack,{Size=UDim2.fromScale(lessonFraction,1),BackgroundColor3=quizVisual.color})
    UI.corner(progressFill,999)
    UI.text(progressRow,tostring(state.lessonCount or 0).."/5",11,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(46,24),TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamBold,TextColor3=UI.P.muted})

    local rewardRow=UI.new("Frame",questionColumn,{LayoutOrder=3,Size=UDim2.new(1,0,0,30),BackgroundTransparency=1})
    local rewardList=UI.new("UIListLayout",rewardRow,{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Left,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,6)})
    if q.reviewOnly then
        UI.chip(rewardRow,"Practice review",{Size=UDim2.fromOffset(104,28),BackgroundColor3=UI.P.goldSoft,TextColor3=UI.P.ink})
    else
        UI.chip(rewardRow,"+10 first try",{Size=UDim2.fromOffset(96,28),BackgroundColor3=UI.P.soft,TextColor3=UI.P.success})
        UI.chip(rewardRow,"+6 retry",{Size=UDim2.fromOffset(76,28),BackgroundColor3=UI.P.goldSoft,TextColor3=UI.P.ink})
        UI.chip(rewardRow,"streak +10",{Size=UDim2.fromOffset(86,28),BackgroundColor3=UI.P.navySoft,TextColor3=UI.P.ink})
    end

    local questionCard=UI.surface(questionColumn,{LayoutOrder=4,Size=UDim2.new(1,0,0,98),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=UI.P.white,Shadow=false})
    UI.pad(questionCard,16)
    UI.text(questionCard,q.prompt,layout.textSize,{Size=UDim2.new(1,0,0,62),AutomaticSize=Enum.AutomaticSize.Y,TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.GothamMedium})

    local feedbackFrame,feedbackText=UI.feedbackCard(questionColumn,"","hint",{LayoutOrder=10,Visible=false,TextSize=14})
    local buttons={}
    local useAnswerGrid=layout.landscape and layout.columns==2 and #q.choices==4
    local answerParent=answerColumn
    if useAnswerGrid then
        local answerGap=9
        local answerGrid=UI.new("Frame",answerColumn,{
            Name="AnswerGrid",LayoutOrder=1,
            Size=UDim2.new(1,0,0,layout.answerHeight*2+answerGap),
            BackgroundTransparency=1,
        })
        UI.new("UIGridLayout",answerGrid,{
            CellPadding=UDim2.fromOffset(answerGap,answerGap),
            CellSize=UDim2.new(.5,-answerGap/2,0,layout.answerHeight),
            FillDirectionMaxCells=2,
            SortOrder=Enum.SortOrder.LayoutOrder,
        })
        answerParent=answerGrid
    end
    for i,choice in ipairs(q.choices) do
        local button
        button=UI.answerCard(answerParent,string.char(64+i).."   "..choice,function()
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
                    feedbackText.Text=headline.."\n"..tostring(result.explanation or "")

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
                    feedbackText.Text=penaltyText.."\nHint: "..tostring(result.hint or q.hint or "Try eliminating one answer.")
                end

                task.defer(function()
                    if feedbackFrame.Parent then
                        questionColumn.CanvasPosition=Vector2.new(0,math.max(0,questionColumn.AbsoluteCanvasSize.Y-questionColumn.AbsoluteWindowSize.Y))
                    end
                end)
            end)
        end,{
            LayoutOrder=useAnswerGrid and i or (3+i),
            Size=UDim2.new(1,0,0,layout.answerHeight),
            AutomaticSize=useAnswerGrid and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
            BackgroundColor3=UI.P.white,
            TextSize=16,
        })
        table.insert(buttons,button)
    end
end
resumeButton=UI.button(goalCard,"CONTINUE",function()
    task.spawn(function()
        local result=call("study",{})
        if result.ok then showQuestion(result.question) end
    end)
end,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-4,0,5),Size=UDim2.fromOffset(66,30),Visible=false,TextSize=9,BackgroundColor3=UI.P.teal,TextColor3=UI.P.white,CornerRadius=999})
local function equippedSlot(item)
    if item.slot then return item.slot end
    if item.category=="Homes" then return "home" end
    if item.category=="Vehicles" then return "vehicle" end
    if item.category=="Clothes" then return "outfit" end
    return nil
end

local function clothingMatches(item,filter)
    if filter=="All" then return true end
    if filter=="Tops" then return item.slot=="uniformTop" end
    if filter=="Bottoms" then return item.slot=="uniformBottom" end
    if filter=="Socks" then return item.slot=="uniformLegwear" end
    if filter=="Shoes" then return item.slot=="uniformShoes" end
    if filter=="Sweaters" or filter=="Layers" then return item.style==14 or item.style==15 or item.style==53 or item.style==55 or item.style==56 end
    if filter=="Full" then return item.slot==nil end
    return true
end

local function homeMatches(item,filter)
    if filter=="All" then return true end
    if filter=="Starter" then return item.tier<=2 end
    if filter=="Family" then return item.tier==3 end
    if filter=="Luxury" then return item.tier>=4 end
    return true
end

local function vehicleMatches(item,filter)
    if filter=="All" then return true end
    if filter=="Starter" then return item.tier<=2 end
    if filter=="Sport" then return item.style==3 end
    if filter=="Premium" then return item.tier>=5 end
    return true
end

showAvatar=function()
    if setNavActive then setNavActive("shop") end
    open("avatar","◆  Avatar Preview")

    local layout=Layout.compute(canvas.AbsoluteSize.X,canvas.AbsoluteSize.Y)
    local previewHeight=layout.compact and 210 or 290
    local previewCard=UI.surface(body,{LayoutOrder=1,Size=UDim2.new(1,0,0,previewHeight),BackgroundColor3=UI.P.white,Shadow=false})
    local viewport=UI.new("ViewportFrame",previewCard,{
        Position=UDim2.fromOffset(8,8),Size=UDim2.new(1,-16,1,-16),
        BackgroundColor3=UI.P.paper,BorderSizePixel=0,
        Ambient=Color3.fromRGB(220,217,205),LightDirection=Vector3.new(-1,-1,-1),
    })
    UI.corner(viewport,16)
    UI.new("UIGradient",viewport,{
        Rotation=90,
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,UI.P.navySoft),
            ColorSequenceKeypoint.new(.55,UI.P.paper),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(233,225,204)),
        }),
    })
    local stageLabel=UI.text(viewport,"ABVM UNIFORM PREVIEW",10,{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,18),Font=Enum.Font.GothamBold,TextColor3=UI.P.ink,ZIndex=5})
    UI.text(viewport,"‹ rotate ›",10,{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-8),Size=UDim2.fromOffset(88,18),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=UI.P.muted,ZIndex=5})

    local clone=nil
    local baseCf=CFrame.new()
    local angle=0
    local character=player.Character
    if character then
        local oldArchivable=character.Archivable
        character.Archivable=true
        local ok,value=pcall(function() return character:Clone() end)
        character.Archivable=oldArchivable
        if ok and value then
            clone=value
            for _,desc in ipairs(clone:GetDescendants()) do
                if desc:IsA("BasePart") then
                    desc.Anchored=true;desc.CanCollide=false;desc.CanTouch=false;desc.CanQuery=false
                elseif desc:IsA("Script") or desc:IsA("LocalScript") then
                    desc:Destroy()
                end
            end
            clone.Parent=viewport
            local _,bounds=clone:GetBoundingBox()
            baseCf=CFrame.new(0,bounds.Y*.5,0)*CFrame.Angles(0,math.pi,0)
            clone:PivotTo(baseCf)
            local camera=Instance.new("Camera")
            camera.FieldOfView=28
            camera.CFrame=CFrame.lookAt(Vector3.new(0,bounds.Y*.56,bounds.Y*2.15),Vector3.new(0,bounds.Y*.5,0))
            camera.Parent=viewport;viewport.CurrentCamera=camera
        end
    end
    if not clone then
        UI.text(viewport,"Your avatar will appear here after your character loads.",14,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(1,-40,0,60),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=UI.P.muted})
    end

    UI.button(previewCard,"‹",function()
        if clone then angle-=math.rad(30);clone:PivotTo(baseCf*CFrame.Angles(0,angle,0)) end
    end,{Position=UDim2.new(0,14,.5,-22),Size=UDim2.fromOffset(44,44),TextSize=28,BackgroundColor3=UI.P.paper,CornerRadius=999})
    UI.button(previewCard,"›",function()
        if clone then angle+=math.rad(30);clone:PivotTo(baseCf*CFrame.Angles(0,angle,0)) end
    end,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,.5,-22),Size=UDim2.fromOffset(44,44),TextSize=28,BackgroundColor3=UI.P.paper,CornerRadius=999})

    local pieces=UI.new("Frame",body,{LayoutOrder=2,Size=UDim2.new(1,0,0,48),BackgroundTransparency=1})
    local defs={{"▰","Tops","Tops"},{"▥","Bottoms","Bottoms"},{"▯","Socks","Socks"},{"◆","Shoes","Shoes"}}
    for i,def in ipairs(defs) do
        UI.iconButton(pieces,def[1],def[2],function() showShop("Clothes",def[3]) end,{
            Position=UDim2.new((i-1)/4,3,0,0),Size=UDim2.new(.25,-6,1,0),
            TextSize=11,IconSize=14,BackgroundColor3=UI.P.white,
            IconBackgroundColor3=i==1 and UI.P.teal or i==2 and Color3.fromRGB(58,124,219) or i==3 and UI.P.gold or Color3.fromRGB(111,92,207),
            IconColor=UI.P.white,
        })
    end

    local equippedRow=UI.new("Frame",body,{LayoutOrder=3,Size=UDim2.new(1,0,0,64),BackgroundTransparency=1})
    local equippedDefs={
        {"uniformTop","Top"},
        {"uniformBottom","Bottom"},
        {"uniformLegwear","Socks"},
        {"uniformShoes","Shoes"},
    }
    for i,entry in ipairs(equippedDefs) do
        local id=state.equipped[entry[1]]
        local item=id and Catalog.ById[id] or nil
        local short=item and item.name:gsub("^.- • ","") or "None"
        UI.chip(equippedRow,entry[2].." • "..short,{
            Position=UDim2.new(((i-1)%2)*.5,((i-1)%2)*4,math.floor((i-1)/2)*.5,math.floor((i-1)/2)*4),
            Size=UDim2.new(.5,-6,0,28),
            BackgroundColor3=item and UI.P.soft or UI.P.white,
            TextColor3=item and UI.P.teal or UI.P.muted,
            TextSize=10,
        })
    end
    UI.button(body,"✓  Save Outfit",function()
        notify("Your equipped uniform pieces are saved automatically.")
    end,{LayoutOrder=4,Size=UDim2.new(1,0,0,48),BackgroundColor3=UI.P.teal,TextColor3=UI.P.white,TextSize=15})
end

showShop=function(selected,subfilter)
    category=selected or category
    if setNavActive then setNavActive("shop") end
    if subfilter then
        if category=="Clothes" then clothesFilter=subfilter
        elseif category=="Homes" then homeFilter=subfilter
        elseif category=="Vehicles" then vehicleFilter=subfilter end
    end
    local titles={Homes="⌂  Houses",Clothes="◆  ABVM Apparel",Items="▣  School Shop",Vehicles="◇  Vehicles"}
    open("shop",titles[category] or "ABVM School Shop")

    UI.clear(shopTabs);UI.clear(shopSubtabs)
    shopTabs.BackgroundTransparency=0;shopTabs.BackgroundColor3=UI.P.navySoft
    UI.corner(shopTabs,14)
    shopSubtabs.BackgroundTransparency=0;shopSubtabs.BackgroundColor3=UI.P.soft
    UI.corner(shopSubtabs,12)
    local categoryDefs={{"Homes","Houses","home"},{"Clothes","Apparel","apparel"},{"Items","Items","items"},{"Vehicles","Vehicles","vehicle"}}
    for i,def in ipairs(categoryDefs) do
        local key,label,iconKind=def[1],def[2],def[3]
        UI.iconButton(shopTabs,"",label,function() showShop(key) end,{
            Position=UDim2.new((i-1)/4,3,0,0),Size=UDim2.new(.25,-6,1,0),TextSize=11,
            BackgroundColor3=key==category and UI.P.ink or UI.P.navySoft,
            TextColor3=key==category and UI.P.white or UI.P.ink,
            IconBackgroundColor3=key==category and UI.P.gold or UI.P.white,
            IconColor=key==category and UI.P.ink or UI.P.teal,
            IconKind=iconKind,
        })
    end

    local subfilters=nil
    local activeFilter="All"
    if category=="Clothes" then
        subfilters={"Avatar","All","Tops","Bottoms","Socks","Shoes","Full","Layers"}
        activeFilter=clothesFilter
    elseif category=="Homes" then
        subfilters={"All","Starter","Family","Luxury"}
        activeFilter=homeFilter
    elseif category=="Vehicles" then
        subfilters={"All","Starter","Sport","Premium"}
        activeFilter=vehicleFilter
    end
    if subfilters then
        shopSubtabs.Visible=true
        local layout=Layout.compute(canvas.AbsoluteSize.X,canvas.AbsoluteSize.Y)
        local wrapFilters=layout.narrow and not layout.landscape and #subfilters>4
        if wrapFilters then
            shopSubtabs.Position=UDim2.fromOffset(14,99)
            shopSubtabs.Size=UDim2.new(1,-28,0,68)
            body.Position=UDim2.fromOffset(14,172)
            body.Size=UDim2.new(1,-28,1,-186)
        elseif not (layout.compact and layout.landscape) then
            body.Position=UDim2.fromOffset(14,138);body.Size=UDim2.new(1,-28,1,-152)
        end
        for i,label in ipairs(subfilters) do
            local position,size
            if wrapFilters then
                local col=(i-1)%4
                local row=math.floor((i-1)/4)
                position=UDim2.new(col/4,2,row/2,2)
                size=UDim2.new(.25,-4,.5,-4)
            else
                position=UDim2.new((i-1)/#subfilters,2,0,0)
                size=UDim2.new(1/#subfilters,-4,1,0)
            end
            UI.button(shopSubtabs,label,function()
                if category=="Clothes" and label=="Avatar" then showAvatar() else showShop(category,label) end
            end,{
                Position=position,Size=size,
                TextSize=10,
                BackgroundColor3=label==activeFilter and UI.P.teal or UI.P.soft,
                TextColor3=label==activeFilter and UI.P.white or UI.P.ink,
                CornerRadius=10,
            })
        end
    else
        shopSubtabs.Visible=false
        local layout=Layout.compute(canvas.AbsoluteSize.X,canvas.AbsoluteSize.Y)
        if not (layout.compact and layout.landscape) then
            body.Position=UDim2.fromOffset(14,100);body.Size=UDim2.new(1,-28,1,-114)
        end
    end

    local _,tier=Catalog.tier(state.earned)
    UI.text(body,tier.name.."  •  "..tostring(state.coins).." Credits available",UI.T.caption,{LayoutOrder=1,Size=UDim2.new(1,0,0,24),TextColor3=UI.P.muted,Font=Enum.Font.GothamBold})

    local visible={}
    for _,item in ipairs(Catalog.Items) do
        local matches=item.category==category
        if matches and category=="Clothes" then matches=clothingMatches(item,clothesFilter) end
        if matches and category=="Homes" then matches=homeMatches(item,homeFilter) end
        if matches and category=="Vehicles" then matches=vehicleMatches(item,vehicleFilter) end
        if matches then table.insert(visible,item) end
    end

    local layout=Layout.compute(canvas.AbsoluteSize.X,canvas.AbsoluteSize.Y)
    local columns=layout.columns
    local gap=layout.shopGap
    local showcaseCategory=category=="Homes" or category=="Vehicles"
    local cardHeight=showcaseCategory and (layout.compact and 178 or 194) or layout.shopCardHeight
    local rows=math.max(1,math.ceil(#visible/columns))
    local grid=UI.new("Frame",body,{Name="ProductGrid",LayoutOrder=2,Size=UDim2.new(1,0,0,rows*cardHeight+(rows-1)*gap),BackgroundTransparency=1})
    UI.new("UIGridLayout",grid,{
        CellPadding=UDim2.fromOffset(gap,gap),
        CellSize=UDim2.new(1/columns,-(gap*(columns-1))/columns,0,cardHeight),
        FillDirectionMaxCells=columns,
        SortOrder=Enum.SortOrder.LayoutOrder,
        HorizontalAlignment=Enum.HorizontalAlignment.Left,
    })

    for number,item in ipairs(visible) do
        local owned=state.owned[item.id]==true
        local slot=equippedSlot(item)
        local equipped=slot~=nil and state.equipped[slot]==item.id
        local cardTint=category=="Homes" and UI.P.goldSoft:Lerp(UI.P.white,.76) or category=="Vehicles" and UI.P.navySoft:Lerp(UI.P.white,.72) or UI.P.white
        local card=UI.surface(grid,{Name=item.id,LayoutOrder=number,Size=UDim2.new(1,0,0,cardHeight),BackgroundColor3=cardTint,Shadow=false})
        local previewSize=showcaseCategory and (layout.compact and 122 or 136) or (layout.compact and 96 or 108)
        local textX=previewSize+20
        local previewBg=category=="Homes" and Color3.fromRGB(244,236,214) or category=="Vehicles" and Color3.fromRGB(229,235,244) or UI.P.soft
        UI.preview(card,item,{Position=UDim2.fromOffset(10,10),Size=UDim2.fromOffset(previewSize,previewSize),CornerRadius=14,BackgroundColor3=previewBg})

        UI.text(card,item.name,15,{Position=UDim2.fromOffset(textX,8),Size=UDim2.new(1,-textX-10,0,30),Font=Enum.Font.GothamBold,TextYAlignment=Enum.TextYAlignment.Top,TextTruncate=Enum.TextTruncate.AtEnd})
        local affordable=state.coins>=item.price
        local tierName=(Catalog.Tiers[item.tier] and Catalog.Tiers[item.tier].name) or "School"
        local slotName=item.slot=="uniformTop" and "TOP" or item.slot=="uniformBottom" and "BOTTOM" or item.slot=="uniformLegwear" and "SOCKS" or item.slot=="uniformShoes" and "SHOES" or nil
        local badgeText=equipped and "✓ EQUIPPED" or owned and "OWNED" or slotName or string.upper(tierName)
        local badgeBg=equipped and Color3.fromRGB(232,245,238) or owned and UI.P.soft or category=="Homes" and UI.P.goldSoft or category=="Vehicles" and UI.P.navySoft or UI.P.soft
        local badgeFg=equipped and UI.P.success or owned and UI.P.teal or UI.P.ink
        UI.chip(card,badgeText,{
            Position=UDim2.fromOffset(textX,38),Size=UDim2.fromOffset(math.min(102,math.max(64,#badgeText*6+18)),22),
            BackgroundColor3=badgeBg,TextColor3=badgeFg,TextSize=9,
            StrokeColor=equipped and UI.P.success or UI.P.line,
        })
        if not owned then
            UI.text(card,"●  "..tostring(item.price).." Credits",12,{
                Position=UDim2.fromOffset(textX,63),Size=UDim2.new(1,-textX-10,0,20),
                TextColor3=affordable and UI.P.success or Color3.fromRGB(180,132,28),
                Font=Enum.Font.GothamBold,TextTruncate=Enum.TextTruncate.AtEnd,
            })
        end
        if not layout.compact then
            UI.text(card,item.description,11,{Position=UDim2.fromOffset(textX,87),Size=UDim2.new(1,-textX-10,0,24),TextColor3=UI.P.muted,TextYAlignment=Enum.TextYAlignment.Top,TextTruncate=Enum.TextTruncate.AtEnd})
        end

        local label
        if owned then
            label=item.category=="Items" and "Owned" or (equipped and "Equipped" or "Equip")
        else
            label="Buy • "..tostring(item.price)
        end
        local action=UI.button(card,label,function()
            task.spawn(function()
                local result=call(owned and "equip" or "buy",{itemId=item.id})
                if result.ok then
                    notify(owned and (item.name.." equipped.") or (item.name.." added to your collection."))
                    if view=="shop" then showShop(category,category=="Clothes" and clothesFilter or category=="Homes" and homeFilter or category=="Vehicles" and vehicleFilter or nil) end
                end
            end)
        end,{Position=UDim2.new(0,10,1,-46),Size=UDim2.new(1,-60,0,36),TextSize=12,BackgroundColor3=UI.P.teal,TextColor3=UI.P.white,CornerRadius=10})
        if owned and (equipped or item.category=="Items") then
            action.Active=false;action.BackgroundColor3=UI.P.soft;action.TextColor3=UI.P.success
        end
        UI.button(card,state.goal==item.id and "★" or "☆",function()
            task.spawn(function()
                local result=call("goal",{itemId=item.id})
                if result.ok and view=="shop" then showShop(category,category=="Clothes" and clothesFilter or category=="Homes" and homeFilter or category=="Vehicles" and vehicleFilter or nil) end
            end)
        end,{
            Position=UDim2.new(1,-46,1,-46),Size=UDim2.fromOffset(36,36),TextSize=18,
            BackgroundColor3=state.goal==item.id and UI.P.goldSoft or UI.P.white,
            TextColor3=state.goal==item.id and Color3.fromRGB(180,132,28) or UI.P.muted,
            CornerRadius=10,
        })
    end
end
local navButtons={}
local navDefs={
    {"school","School","school",Color3.fromRGB(221,175,60)},
    {"home","Home","home",Color3.fromRGB(47,142,103)},
    {"shop","Shop","shop",Color3.fromRGB(58,124,219)},
    {"vehicle","Ride","vehicle",Color3.fromRGB(111,92,207)},
}
for i,definition in ipairs(navDefs) do
    local iconKind,label,command,accent=definition[1],definition[2],definition[3],definition[4]
    local b=UI.iconButton(nav,"",label,function()
        if not state.ready then notify("Your saved progress is still loading.");return end
        if command=="shop" then showShop();return end
        close(false)
        task.spawn(function()
            local result=call(command,{})
            if result.ok and command=="school" then
                locationCommand="school"
                showClasses()
            elseif result.ok and command=="home" then
                locationCommand="home"
                if setNavActive then setNavActive("home") end
            end
            if result.ok and command=="vehicle" then notify("Use your thumbstick to steer. Drive and Reverse control speed.") end
        end)
    end,{
        Position=UDim2.new((i-1)*.25,3,0,0),
        Size=UDim2.new(.25,-6,1,0),
        TextSize=11,
        IconSize=16,
        BackgroundColor3=Color3.fromRGB(19,40,68),
        TextColor3=UI.P.white,
        IconBackgroundColor3=accent,
        IconColor=UI.P.white,
        IconKind=iconKind,
    })
    table.insert(navButtons,b)
end
setNavActive=function(command)
    for i,b in ipairs(navButtons) do
        local active=navDefs[i][3]==command
        local accent=navDefs[i][4]
        b.BackgroundColor3=active and Color3.fromRGB(31,91,67) or Color3.fromRGB(19,40,68)
        local activeStroke=b:FindFirstChild("ActiveStroke")
        if not activeStroke then
            activeStroke=Instance.new("UIStroke");activeStroke.Name="ActiveStroke";activeStroke.Thickness=1.5;activeStroke.Parent=b
        end
        activeStroke.Color=active and UI.P.gold or Color3.fromRGB(46,67,93)
        activeStroke.Transparency=active and 0 or .45

        local iconBox=b:FindFirstChild("IconBox")
        local label=b:FindFirstChild("Label")
        if iconBox and iconBox:IsA("Frame") then
            iconBox.BackgroundColor3=accent
            UI.tintIcon(iconBox,UI.P.white)
        end
        if label and label:IsA("TextLabel") then
            label.TextColor3=UI.P.white
            label.TextTransparency=active and 0 or .06
        end
    end
end

-- Native thumbstick steers. Right-side pedals stay minimal and game-like.
local driving=UI.new("Frame",canvas,{
    Name="DrivingControls",Visible=false,AnchorPoint=Vector2.new(1,.5),
    Position=UDim2.new(1,-12,.58,0),Size=UDim2.fromOffset(92,174),
    BackgroundTransparency=1,BorderSizePixel=0,
})
local driveTag=UI.chip(driving,"RIDE",{
    Position=UDim2.new(.5,-30,0,0),Size=UDim2.fromOffset(60,22),
    BackgroundColor3=UI.P.ink,TextColor3=UI.P.gold,TextSize=9,StrokeColor=Color3.fromRGB(46,67,93),
})
local held={};local heldInputs={};local driveButtons={}
local pedalDefs={
    {"▲\nDRIVE","go",UI.P.teal,UI.P.white},
    {"▼\nREVERSE","back",UI.P.ink,UI.P.white},
}
for i,d in ipairs(pedalDefs) do
    local label,key,bg,fg=d[1],d[2],d[3],d[4]
    local b=UI.button(driving,label,function() end,{
        Position=UDim2.new(.5,-31,0,27+(i-1)*66),
        Size=UDim2.fromOffset(62,62),
        TextSize=11,BackgroundColor3=bg,TextColor3=fg,CornerRadius=999,
    })
    UI.stroke(b,i==1 and UI.P.success or Color3.fromRGB(46,67,93))
    table.insert(driveButtons,b)
    b.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            held[key]=true;heldInputs[input]=key
        end
    end)
end
local parkButton=UI.button(driving,"P  PARK",function() task.spawn(call,"park",{}) end,{
    Position=UDim2.new(.5,-32,1,-24),Size=UDim2.fromOffset(64,24),TextSize=9,
    BackgroundColor3=UI.P.goldSoft,TextColor3=UI.P.ink,CornerRadius=999,
})
UI.stroke(parkButton,UI.P.gold)
UserInputService.InputEnded:Connect(function(input)
    local key=heldInputs[input]
    if key then held[key]=false;heldInputs[input]=nil end
end)
UserInputService.WindowFocusReleased:Connect(function()
    table.clear(held);table.clear(heldInputs);drive:FireServer(0,0)
end)

local lastLayoutSignature=nil
local function reflow()
    local size=canvas.AbsoluteSize
    local layout=Layout.compute(size.X,size.Y)

    header.AnchorPoint=Vector2.new(0,0)
    header.Position=UDim2.fromOffset(layout.rail.x,layout.rail.y)
    header.Size=UDim2.fromOffset(layout.rail.width,layout.rail.height)

    if layout.narrow then
        avatar.Visible=true
        avatar.Position=UDim2.fromOffset(8,8)
        avatar.Size=UDim2.fromOffset(32,32)
        nameText.Position=UDim2.fromOffset(47,4)
        nameText.Size=UDim2.new(1,-170,0,22)
        gradeText.Visible=false
        profileDivider.Visible=false
        wallet.Position=UDim2.new(1,-8,0,7)
        wallet.Size=UDim2.fromOffset(104,36)
    else
        avatar.Visible=true
        avatar.Position=UDim2.fromOffset(8,8)
        avatar.Size=UDim2.fromOffset(40,40)
        nameText.Position=UDim2.fromOffset(56,5)
        nameText.Size=UDim2.fromOffset(layout.topCompact and 112 or 144,23)
        gradeText.Visible=not layout.topCompact
        gradeText.Position=UDim2.fromOffset(56,27)
        gradeText.Size=UDim2.fromOffset(146,16)
        profileDivider.Visible=not layout.topCompact
        profileDivider.Position=UDim2.fromOffset(204,13)
        wallet.Position=UDim2.new(1,-8,0,8)
        wallet.Size=UDim2.fromOffset(108,40)
    end

    goalCard.Position=UDim2.fromOffset(layout.goal.x,layout.goal.y)
    goalCard.Size=UDim2.fromOffset(layout.goal.width,layout.goal.height)
    goalIcon.Position=UDim2.fromOffset(0,7)
    goalIcon.Size=UDim2.fromOffset(32,32)
    local tightGoal=layout.goal.width<190
    goalTitle.Position=UDim2.fromOffset(40,1)
    goalTitle.Size=UDim2.new(1,tightGoal and -48 or -104,0,18)
    goalInfo.Position=UDim2.fromOffset(40,18)
    goalInfo.Size=UDim2.new(1,tightGoal and -44 or -96,0,15)
    goalTrack.Position=UDim2.fromOffset(40,37)
    goalTrack.Size=UDim2.new(1,tightGoal and -44 or -96,0,4)
    bonusChip.Visible=(not tightGoal) and state.subject==nil
    if resumeButton then
        resumeButton.Visible=(not tightGoal) and state.subject~=nil
        resumeButton.Position=UDim2.new(1,-4,0,5)
        resumeButton.Size=UDim2.fromOffset(66,30)
    end
    streakPill.Visible=false

    nav.Parent=canvas
    nav.BackgroundTransparency=.04
    nav.AnchorPoint=Vector2.new(0,0)
    nav.Position=UDim2.fromOffset(layout.nav.x,layout.nav.y)
    nav.Size=UDim2.fromOffset(layout.nav.width,layout.nav.height)
    if layout.goldLandscape then
        for i,b in ipairs(navButtons) do
            b.Size=UDim2.new(1,0,0,46)
            b.Position=UDim2.fromOffset(0,(i-1)*52)
        end
    else
        for i,b in ipairs(navButtons) do
            b.Size=UDim2.new(.25,-6,1,0)
            b.Position=UDim2.new((i-1)*.25,3,0,0)
        end
    end

    local m=layout.modal
    panel.Position=UDim2.fromOffset(m.x,m.y)
    panel.Size=UDim2.fromOffset(m.width,m.height)

    toast.Size=UDim2.fromOffset(math.min(390,size.X-24),48)

    local d=layout.drive
    driving.AnchorPoint=Vector2.new(1,.5)
    driving.Position=UDim2.new(1,-d.right,d.yScale,0)
    driving.Size=UDim2.fromOffset(d.width,d.height)

    local signature=tostring(layout.columns)..":"..tostring(layout.narrow)..":"..tostring(layout.landscape)..":"..tostring(layout.goldLandscape)
    if lastLayoutSignature and signature~=lastLayoutSignature then
        task.defer(function()
            if view=="shop" then
                showShop(category,category=="Clothes" and clothesFilter or category=="Homes" and homeFilter or category=="Vehicles" and vehicleFilter or nil)
            elseif view=="quiz" and activeQuestion then
                showQuestion(activeQuestion)
            elseif view=="avatar" then
                showAvatar()
            elseif view=="classes" then
                showClasses()
            end
        end)
    end
    lastLayoutSignature=signature
end
canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(reflow)
reflow()
changed.OnClientEvent:Connect(function(packet)
    if type(packet)~="table" then return end
    update(packet.state)
    if packet.kind=="question" then
        locationCommand="school"
        if setNavActive then setNavActive("school") end
        showQuestion(packet.data)
    elseif packet.kind=="left_classroom" then
        if view=="quiz" then close(false) end
    elseif packet.kind=="shop" then
        showShop()
    elseif packet.data and packet.data.message then
        notify(packet.data.message)
    end
end)
player:GetAttributeChangedSignal("NeighborhoodDriving"):Connect(function()
    local isDriving=player:GetAttribute("NeighborhoodDriving")==true
    driving.Visible=isDriving
    nav.Visible=not isDriving
    if isDriving then
        if setNavActive then setNavActive("vehicle") end
        goalCard.Visible=false
        panel.Visible=false;shopTabs.Visible=false;shopSubtabs.Visible=false;view=nil
    else
        table.clear(held);table.clear(heldInputs)
        nav.Visible=true
        if setNavActive then setNavActive(locationCommand) end
        if not panel.Visible then goalCard.Visible=true end
    end
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
        if controls then
            local vector=controls:GetMoveVector()
            if throttle==0 then throttle=math.clamp(-vector.Z,-1,1) end
            if steer==0 then steer=math.clamp(vector.X,-1,1) end
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
