--!strict
local TweenService=game:GetService("TweenService")
local UI={}
UI.P={ink=Color3.fromRGB(36,52,71),muted=Color3.fromRGB(103,118,131),paper=Color3.fromRGB(245,242,234),white=Color3.fromRGB(255,255,255),line=Color3.fromRGB(221,227,226),teal=Color3.fromRGB(39,132,123),gold=Color3.fromRGB(222,178,77),soft=Color3.fromRGB(230,240,235),rose=Color3.fromRGB(182,111,93)}
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
function UI.text(parent,text,size,props)
    local base={BackgroundTransparency=1,Text=text,Font=Enum.Font.Gotham,TextSize=size or 17,TextColor3=UI.P.ink,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,Size=UDim2.new(1,0,0,32)}
    for k,v in pairs(props or {}) do base[k]=v end
    return UI.new("TextLabel",parent,base)
end
function UI.button(parent,text,fn,props)
    local base={Text=text,Font=Enum.Font.GothamBold,TextSize=16,TextColor3=UI.P.ink,TextWrapped=true,BorderSizePixel=0,BackgroundColor3=UI.P.soft,AutoButtonColor=true,Size=UDim2.new(1,0,0,48)}
    for k,v in pairs(props or {}) do base[k]=v end
    local b=UI.new("TextButton",parent,base);UI.corner(b,12)
    b.Activated:Connect(function() if b.Active then fn(b) end end)
    return b
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
function UI.preview(parent,item)
    local v=UI.new("ViewportFrame",parent,{Size=UDim2.fromOffset(94,94),Position=UDim2.fromOffset(10,10),BackgroundColor3=UI.P.soft,BorderSizePixel=0,LightDirection=Vector3.new(-1,-1,-1),Ambient=Color3.fromRGB(205,205,205)})
    UI.corner(v,12)
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
        if item.style>=3 then p(Vector3.new(3,2,2.5),Vector3.new(0,4.8,.3),tint);p(Vector3.new(3.4,.25,2.9),Vector3.new(0,5.9,.3),UI.P.gold) end
    elseif item.category=="Vehicles" then
        p(Vector3.new(3.8,1.1,6),Vector3.new(0,1,0),tint)
        p(Vector3.new(3.3,1.1,2.8),Vector3.new(0,2,.2),Color3.fromRGB(165,198,204))
        p(Vector3.new(3.5,.25,3),Vector3.new(0,2.7,.2),tint)
        for _,x in ipairs({-1.85,1.85}) do for _,z in ipairs({-1.9,1.9}) do p(Vector3.new(.5,1.4,1.4),Vector3.new(x,.7,z),UI.P.ink,Enum.PartType.Cylinder) end end
    elseif item.category=="Clothes" then
        p(Vector3.new(2,2.2,1),Vector3.new(0,2.4,0),tint)
        p(Vector3.new(1.1,1.1,1.1),Vector3.new(0,4.1,0),Color3.fromRGB(226,207,181),Enum.PartType.Ball)
        for _,x in ipairs({-1.45,1.45}) do p(Vector3.new(.8,2,.8),Vector3.new(x,2.4,0),item.style==2 and UI.P.paper or tint) end
        for _,x in ipairs({-.5,.5}) do p(Vector3.new(.85,1.4,.8),Vector3.new(x,.7,0),UI.P.ink) end
        if item.style>=2 then p(Vector3.new(.12,2.1,.05),Vector3.new(0,2.4,-.55),UI.P.gold) end
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
