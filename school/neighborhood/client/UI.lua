--!strict
local TweenService=game:GetService("TweenService")
local UI={}
UI.P={ink=Color3.fromRGB(22,45,79),muted=Color3.fromRGB(95,108,119),paper=Color3.fromRGB(247,244,236),white=Color3.fromRGB(255,255,255),line=Color3.fromRGB(217,219,211),teal=Color3.fromRGB(31,91,67),gold=Color3.fromRGB(221,175,60),soft=Color3.fromRGB(232,239,230),rose=Color3.fromRGB(182,92,85),success=Color3.fromRGB(47,142,103),negative=Color3.fromRGB(182,92,85),navySoft=Color3.fromRGB(232,237,243),goldSoft=Color3.fromRGB(250,242,218)}
UI.T={display=23,section=18,body=15,caption=12}
UI.R={surface=18,control=13,chip=999}
function UI.new(class,parent,props)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent;return o
end
function UI.corner(o,r) UI.new("UICorner",o,{CornerRadius=UDim.new(0,r or 14)}) end
function UI.stroke(o,c) UI.new("UIStroke",o,{Color=c or UI.P.line,Thickness=1}) end
function UI.pad(o,p)
    UI.new("UIPadding",o,{PaddingTop=UDim.new(0,p),PaddingBottom=UDim.new(0,p),PaddingLeft=UDim.new(0,p),PaddingRight=UDim.new(0,p)})
end
function UI.frame(parent,props)
    props=props or {};props.BorderSizePixel=0
    if props.BackgroundColor3==nil then props.BackgroundColor3=UI.P.white end
    local o=UI.new("Frame",parent,props);UI.corner(o);return o
end
function UI.shadow(parent,position,size,radius)
    local s=UI.new("Frame",parent,{Position=position or UDim2.fromOffset(2,3),Size=size or UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(18,31,47),BackgroundTransparency=.86,BorderSizePixel=0,ZIndex=0})
    UI.corner(s,radius or UI.R.surface)
    return s
end
function UI.surface(parent,props)
    props=props or {}
    local shadowProps=props.Shadow~=false
    props.Shadow=nil
    local position=props.Position
    local size=props.Size
    local radius=props.CornerRadius or UI.R.surface
    props.CornerRadius=nil
    if shadowProps then UI.shadow(parent,position and position+UDim2.fromOffset(2,3) or UDim2.fromOffset(2,3),size,radius) end
    local o=UI.frame(parent,props);UI.corner(o,radius);UI.stroke(o,UI.P.line);return o
end
function UI.chip(parent,text,props)
    props=props or {}
    local bg=props.BackgroundColor3 or UI.P.white
    local fg=props.TextColor3 or UI.P.ink
    local size=props.Size or UDim2.fromOffset(math.max(74,#text*7+24),30)
    local frame=UI.frame(parent,{Position=props.Position or UDim2.new(),Size=size,BackgroundColor3=bg,BackgroundTransparency=props.BackgroundTransparency or 0,ZIndex=props.ZIndex or 2})
    UI.corner(frame,UI.R.chip);UI.stroke(frame,props.StrokeColor or UI.P.line)
    UI.text(frame,text,props.TextSize or UI.T.caption,{Size=UDim2.fromScale(1,1),TextColor3=fg,TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,ZIndex=(props.ZIndex or 2)+1})
    return frame
end
function UI.flyout(parent,text,color)
    local label=UI.text(parent,text,15,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,0,-2),Size=UDim2.fromOffset(88,28),TextColor3=color or UI.P.success,TextXAlignment=Enum.TextXAlignment.Right,Font=Enum.Font.GothamBold,ZIndex=50})
    label.TextTransparency=0
    TweenService:Create(label,TweenInfo.new(.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(1,-8,0,-28),TextTransparency=1}):Play()
    task.delay(.6,function() if label.Parent then label:Destroy() end end)
end
function UI.text(parent,text,size,props)
    local base={BackgroundTransparency=1,Text=text,Font=Enum.Font.Gotham,TextSize=size or 17,TextColor3=UI.P.ink,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,Size=UDim2.new(1,0,0,32)}
    for k,v in pairs(props or {}) do base[k]=v end
    return UI.new("TextLabel",parent,base)
end
function UI.button(parent,text,fn,props)
    local base={Text=text,Font=Enum.Font.GothamBold,TextSize=16,TextColor3=UI.P.ink,TextWrapped=true,BorderSizePixel=0,BackgroundColor3=UI.P.soft,AutoButtonColor=true,Size=UDim2.new(1,0,0,48)}
    local radius=(props and props.CornerRadius) or UI.R.control
    for k,v in pairs(props or {}) do if k~="CornerRadius" then base[k]=v end end
    local b=UI.new("TextButton",parent,base);UI.corner(b,radius)
    local scale=UI.new("UIScale",b,{Scale=1})
    b.InputBegan:Connect(function(input)
        if b.Active and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1) then
            TweenService:Create(scale,TweenInfo.new(.08),{Scale=.965}):Play()
        end
    end)
    b.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            TweenService:Create(scale,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1}):Play()
        end
    end)
    b.Activated:Connect(function() if b.Active then fn(b) end end)
    return b
end
function UI.iconButton(parent,icon,label,fn,props)
    props=props or {}
    local b=UI.button(parent,"",fn,{Position=props.Position,Size=props.Size or UDim2.fromOffset(72,44),BackgroundColor3=props.BackgroundColor3 or UI.P.white,CornerRadius=props.CornerRadius or UI.R.control})
    UI.text(b,icon,props.IconSize or 18,{Name="Icon",Position=UDim2.fromOffset(7,0),Size=UDim2.fromOffset(24,b.AbsoluteSize.Y>0 and b.AbsoluteSize.Y or 44),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold,TextColor3=props.IconColor or UI.P.teal})
    UI.text(b,label,props.TextSize or 12,{Name="Label",Position=UDim2.fromOffset(31,0),Size=UDim2.new(1,-35,1,0),Font=Enum.Font.GothamBold,TextColor3=props.TextColor3 or UI.P.ink})
    return b
end
function UI.answerCard(parent,text,fn,props)
    props=props or {}
    local b=UI.button(parent,text,fn,{LayoutOrder=props.LayoutOrder,Size=props.Size or UDim2.new(1,0,0,58),AutomaticSize=props.AutomaticSize,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=props.BackgroundColor3 or UI.P.white,TextSize=props.TextSize or 16,TextColor3=props.TextColor3 or UI.P.ink})
    UI.pad(b,14);UI.stroke(b,props.StrokeColor or UI.P.line);return b
end
function UI.feedbackCard(parent,text,tone,props)
    props=props or {}
    local bg=tone=="negative" and Color3.fromRGB(249,235,232) or tone=="success" and Color3.fromRGB(232,245,238) or UI.P.goldSoft
    local fg=tone=="negative" and UI.P.negative or tone=="success" and UI.P.success or UI.P.ink
    local f=UI.frame(parent,{LayoutOrder=props.LayoutOrder or 10,Visible=props.Visible~=false,Size=props.Size or UDim2.new(1,0,0,58),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=bg})
    UI.stroke(f,fg);UI.pad(f,12)
    local t=UI.text(f,text,props.TextSize or 14,{Size=UDim2.new(1,0,0,34),AutomaticSize=Enum.AutomaticSize.Y,TextColor3=fg,Font=Enum.Font.GothamMedium})
    return f,t
end
function UI.stack(parent,gap)
    return UI.new("UIListLayout",parent,{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,gap or 10)})
end
function UI.clear(parent)
    for _,child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
end
function UI.flash(o)
    local original=o.BackgroundColor3;o.BackgroundColor3=Color3.fromRGB(244,220,157)
    TweenService:Create(o,TweenInfo.new(.45),{BackgroundColor3=original}):Play()
end
function UI.crest(parent,props)
    props=props or {}
    local size=props.Size or UDim2.fromOffset(38,42)
    local z=props.ZIndex or 3
    local root=UI.new("Frame",parent,{Name=props.Name or "ABVMCrest",Position=props.Position or UDim2.fromOffset(8,4),Size=size,BackgroundTransparency=1,ZIndex=z})

    -- Native shield approximation of the gold-standard ABVM crest: navy field, gold border,
    -- gold crown/cross language and white central cross. No external asset dependency.
    local shield=UI.new("Frame",root,{AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,0),Size=UDim2.fromScale(.78,.88),BackgroundColor3=UI.P.ink,BorderSizePixel=0,ZIndex=z+1})
    UI.corner(shield,8)
    UI.new("UIStroke",shield,{Color=UI.P.gold,Thickness=2.2})

    local crown=UI.new("TextLabel",root,{BackgroundTransparency=1,Position=UDim2.fromScale(.12,-.11),Size=UDim2.fromScale(.76,.34),Text="♛",Font=Enum.Font.GothamBold,TextScaled=true,TextColor3=UI.P.gold,ZIndex=z+4})
    local crossV=UI.new("Frame",shield,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.56),Size=UDim2.fromScale(.18,.52),BackgroundColor3=UI.P.paper,BorderSizePixel=0,ZIndex=z+3})
    UI.corner(crossV,3)
    local crossH=UI.new("Frame",shield,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.48),Size=UDim2.fromScale(.52,.16),BackgroundColor3=UI.P.paper,BorderSizePixel=0,ZIndex=z+3})
    UI.corner(crossH,3)

    local foot=UI.new("Frame",root,{AnchorPoint=Vector2.new(.5,1),Position=UDim2.fromScale(.5,.98),Size=UDim2.fromScale(.48,.16),BackgroundColor3=UI.P.ink,BorderSizePixel=0,Rotation=45,ZIndex=z+1})
    UI.corner(foot,5)
    UI.new("UIStroke",foot,{Color=UI.P.gold,Thickness=2})
    return root
end
function UI.preview(parent,item,props)
    props=props or {}
    local v=UI.new("ViewportFrame",parent,{Size=props.Size or UDim2.fromOffset(94,94),Position=props.Position or UDim2.fromOffset(10,10),BackgroundColor3=props.BackgroundColor3 or UI.P.soft,BorderSizePixel=0,LightDirection=Vector3.new(-1,-1,-1),Ambient=Color3.fromRGB(205,205,205)})
    UI.corner(v,props.CornerRadius or 12)
    local model=Instance.new("Model");model.Parent=v
    local tint=Color3.fromRGB(table.unpack(item.color))
    local function p(size,pos,c,shape)
        local o=UI.new("Part",model,{Size=size,CFrame=CFrame.new(pos),Color=c,Anchored=true,Material=Enum.Material.SmoothPlastic})
        if shape then o.Shape=shape end
        return o
    end
    if item.category=="Homes" then
        p(Vector3.new(5,3.5,4),Vector3.new(0,1.75,0),tint)
        p(Vector3.new(5.5,.35,4.5),Vector3.new(0,3.7,0),UI.P.ink)
        p(Vector3.new(.85,2,.12),Vector3.new(0,1,-2.1),UI.P.ink)
        for _,x in ipairs({-1.5,1.5}) do p(Vector3.new(1.1,1,.15),Vector3.new(x,2.1,-2.1),Color3.fromRGB(160,200,214)) end
        if item.style>=2 then
            p(Vector3.new(5.8,.22,1.7),Vector3.new(0,.45,-2.8),UI.P.paper)
            for _,x in ipairs({-2.3,2.3}) do p(Vector3.new(.18,2.5,.18),Vector3.new(x,1.55,-2.8),UI.P.paper) end
        end
        if item.style==3 then
            p(Vector3.new(3.7,2.4,3),Vector3.new(0,4.9,.25),tint)
            p(Vector3.new(4,.3,3.3),Vector3.new(0,6.25,.25),UI.P.ink)
            for _,x in ipairs({-1.1,1.1}) do p(Vector3.new(.9,.8,.12),Vector3.new(x,5.1,-1.3),Color3.fromRGB(160,200,214)) end
        elseif item.style==4 then
            p(Vector3.new(4.2,2.2,3.2),Vector3.new(0,4.7,.15),UI.P.paper)
            p(Vector3.new(3.5,1.45,.12),Vector3.new(0,4.75,-1.5),Color3.fromRGB(139,190,205))
            p(Vector3.new(4.6,.25,3.6),Vector3.new(0,5.95,.15),UI.P.ink)
        elseif item.style>=5 then
            p(Vector3.new(3.6,2.3,3),Vector3.new(0,4.8,.25),UI.P.paper)
            p(Vector3.new(4,.3,3.4),Vector3.new(0,6.1,.25),UI.P.ink)
            p(Vector3.new(1.7,3,3.2),Vector3.new(-3.1,1.8,.1),tint)
            p(Vector3.new(1.7,3,3.2),Vector3.new(3.1,1.8,.1),tint)
            p(Vector3.new(2.4,.28,2.2),Vector3.new(0,4.15,-2.2),UI.P.paper)
            for _,x in ipairs({-2.7,2.7}) do p(Vector3.new(.18,2.6,.18),Vector3.new(x,1.6,-2.9),UI.P.gold) end
        end
    elseif item.category=="Vehicles" then
        local bodyLength=item.style==4 and 7.2 or 6
        p(Vector3.new(3.8,1.1,bodyLength),Vector3.new(0,1,0),tint)
        local cabinHeight=item.style==3 and .85 or 1.1
        p(Vector3.new(3.3,cabinHeight,2.8),Vector3.new(0,1.95,.2),Color3.fromRGB(165,198,204))
        p(Vector3.new(3.5,.25,3),Vector3.new(0,2.6,.2),item.style>=3 and UI.P.ink or tint)
        if item.style>=3 then p(Vector3.new(.24,.08,bodyLength),Vector3.new(0,1.58,0),UI.P.gold) end
        for _,x in ipairs({-1.85,1.85}) do for _,z in ipairs({-1.9,1.9}) do p(Vector3.new(.5,1.4,1.4),Vector3.new(x,.7,z),UI.P.ink,Enum.PartType.Cylinder) end end
    elseif item.category=="Clothes" then
        if item.slot=="uniformTop" then
            local forest=Color3.fromRGB(31,91,67)
            local cream=Color3.fromRGB(238,238,231)
            p(Vector3.new(2.2,2.4,1),Vector3.new(0,2.4,0),tint)
            p(Vector3.new(1.1,1.1,1.1),Vector3.new(0,4.1,0),Color3.fromRGB(226,207,181),Enum.PartType.Ball)
            for _,x in ipairs({-1.5,1.5}) do p(Vector3.new(.8,item.style>=14 and 2.3 or 1.4,.8),Vector3.new(x,2.5,0),tint) end
            p(Vector3.new(.38,.18,.08),Vector3.new(.5,2.75,-.56),item.style==13 and forest or cream)
            if item.style==15 then p(Vector3.new(.7,1.8,.07),Vector3.new(0,2.35,-.57),cream) end
        elseif item.slot=="uniformBottom" then
            local navy=Color3.fromRGB(28,48,72)
            local cream=Color3.fromRGB(235,231,216)
            if item.style==23 or item.style==24 or item.style==25 then
                local h=item.style==25 and 3.2 or 2.2
                p(Vector3.new(3,h,1.2),Vector3.new(0,1.7,0),tint)
                if item.style>=24 then
                    for _,x in ipairs({-.8,0,.8}) do p(Vector3.new(.12,h*.95,.07),Vector3.new(x,1.7,-.64),navy) end
                    for _,y in ipairs({1.05,1.7,2.35}) do p(Vector3.new(2.9,.1,.07),Vector3.new(0,y,-.64),cream) end
                end
            else
                local h=item.style==22 and 1.6 or 3.2
                for _,x in ipairs({-.7,.7}) do p(Vector3.new(1.05,h,1),Vector3.new(x,h/2,0),tint) end
            end
        elseif item.slot=="uniformLegwear" then
            local h=item.style==33 and 4.2 or 3.1
            for _,x in ipairs({-.75,.75}) do p(Vector3.new(.9,h,.9),Vector3.new(x,h/2,0),tint) end
        elseif item.slot=="uniformShoes" then
            for _,x in ipairs({-1.05,1.05}) do
                p(Vector3.new(1.5,.8,2.7),Vector3.new(x,.5,0),tint)
                p(Vector3.new(1.55,.15,2.8),Vector3.new(x,.08,0),Color3.fromRGB(40,42,43))
            end
        else
        local isUniform=item.style==6 or item.style==7
        local forest=Color3.fromRGB(31,91,67)
        local khaki=Color3.fromRGB(205,190,154)
        local navy=Color3.fromRGB(28,48,72)
        local cream=Color3.fromRGB(235,231,216)
        p(Vector3.new(2,2.2,1),Vector3.new(0,2.4,0),isUniform and forest or tint)
        p(Vector3.new(1.1,1.1,1.1),Vector3.new(0,4.1,0),Color3.fromRGB(226,207,181),Enum.PartType.Ball)
        for _,x in ipairs({-1.45,1.45}) do p(Vector3.new(.8,2,.8),Vector3.new(x,2.4,0),isUniform and forest or (item.style==2 and UI.P.paper or tint)) end
        for _,x in ipairs({-.5,.5}) do p(Vector3.new(.85,1.4,.8),Vector3.new(x,.7,0),isUniform and (item.style==7 and navy or khaki) or UI.P.ink) end
        if item.style==6 then
            p(Vector3.new(.38,.18,.08),Vector3.new(.48,2.75,-.56),cream)
            p(Vector3.new(1.7,.18,.08),Vector3.new(0,3.3,-.56),forest)
        elseif item.style==7 then
            p(Vector3.new(2.25,2.4,1.12),Vector3.new(0,2.05,0),forest)
            for _,x in ipairs({-.65,0,.65}) do p(Vector3.new(.11,2.35,.06),Vector3.new(x,2.05,-.59),navy) end
            for _,y in ipairs({1.45,2.05,2.65}) do p(Vector3.new(2.2,.1,.06),Vector3.new(0,y,-.59),cream) end
            p(Vector3.new(.38,.18,.08),Vector3.new(.48,2.75,-.62),cream)
        else
            if item.style>=2 then p(Vector3.new(.12,2.1,.05),Vector3.new(0,2.4,-.55),item.style>=3 and UI.P.gold or UI.P.paper) end
            if item.style>=4 then p(Vector3.new(1.4,.15,.06),Vector3.new(0,3.25,-.56),UI.P.gold) end
            if item.style>=5 then p(Vector3.new(1.7,.12,.06),Vector3.new(0,1.55,-.56),UI.P.gold) end
        end
        end
    elseif item.id=="item_rug" then p(Vector3.new(5,.2,4),Vector3.new(0,.2,0),tint)
    elseif item.id=="item_lamp" then
        p(Vector3.new(2.5,.3,2.5),Vector3.new(0,.2,0),UI.P.ink);p(Vector3.new(.2,3,.2),Vector3.new(0,1.8,0),UI.P.gold);p(Vector3.new(2.7,1.8,2.7),Vector3.new(0,3.5,0),UI.P.paper)
    elseif item.id=="item_backpack" then
        p(Vector3.new(2.8,3.7,1.6),Vector3.new(0,2,0),tint);p(Vector3.new(2.2,1.3,.4),Vector3.new(0,1.3,-.9),UI.P.gold)
    elseif item.id=="item_books" then
        p(Vector3.new(4,4.5,1),Vector3.new(0,2.3,0),tint)
        for i=1,5 do p(Vector3.new(.55,1.5,.7),Vector3.new(-1.8+i*.6,2.7,-.6),i%2==0 and UI.P.teal or UI.P.gold) end
    elseif item.id=="item_sofa" then
        p(Vector3.new(5,1.3,2.6),Vector3.new(0,1,0),tint);p(Vector3.new(5,2,.6),Vector3.new(0,2,1),tint)
    else
        p(Vector3.new(5,1,5),Vector3.new(0,.5,0),tint);p(Vector3.new(4,.1,4),Vector3.new(0,1.1,0),Color3.fromRGB(130,191,209));p(Vector3.new(.5,2,.5),Vector3.new(0,2,0),tint)
    end
    local camera=Instance.new("Camera");camera.FieldOfView=38;camera.CFrame=CFrame.lookAt(Vector3.new(8,6,-10),Vector3.new(0,2,0));camera.Parent=v;v.CurrentCamera=camera
    return v
end
return UI
