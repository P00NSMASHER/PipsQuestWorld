--!strict
-- Eventually-consistent school leaderboards. ProfileStore remains authoritative:
-- a leaderboard outage never rolls back a saved answer, penalty, reward or purchase.
local DataStoreService=game:GetService("DataStoreService")
local Players=game:GetService("Players")
local Learning=require(script.Parent.Learning)

local Leaderboards={}
Leaderboards.__index=Leaderboards

local ACCURACY_MIN_ANSWERS=20
local REFRESH_SECONDS=30

local palette={
    navy=Color3.fromRGB(20,31,49),paper=Color3.fromRGB(245,242,234),
    muted=Color3.fromRGB(143,157,175),green=Color3.fromRGB(54,176,122),
    blue=Color3.fromRGB(70,132,232),gold=Color3.fromRGB(226,178,77)
}

local function storeName(suffix:string):string
    return "PipNeighborhoodV1_"..suffix
end

local function key(userId:number):string
    return "player:"..tostring(userId)
end

local function userIdFromKey(value:any):number?
    if type(value)~="string" then return nil end
    return tonumber(string.match(value,"^player:(%d+)$"))
end

local function displayName(userId:number):string
    local ok,name=pcall(function()return Players:GetNameFromUserIdAsync(userId)end)
    if ok and type(name)=="string" and #name>0 then return string.sub(name,1,40) end
    return "Player "..tostring(userId)
end

local function orderedRows(store:OrderedDataStore,limit:number):{any}
    local pages=store:GetSortedAsync(false,limit)
    local rows={}
    for rank,entry in ipairs(pages:GetCurrentPage()) do
        local id=userIdFromKey(entry.key)
        if id and type(entry.value)=="number" then
            table.insert(rows,{rank=rank,userId=id,name=displayName(id),value=math.floor(entry.value+0.5)})
        end
    end
    return rows
end

function Leaderboards.new()
    return setmetatable({
        accuracy=DataStoreService:GetOrderedDataStore(storeName("Accuracy")),
        questions=DataStoreService:GetOrderedDataStore(storeName("Questions")),
        credits=DataStoreService:GetOrderedDataStore(storeName("Credits")),
    },Leaderboards)
end

function Leaderboards:record(userId:number,profile:any):boolean
    if not Learning.valid(profile) then return false end
    local id=key(userId)
    local ok=true
    local function write(store:OrderedDataStore,value:number)
        local success=pcall(function()store:SetAsync(id,value)end)
        if not success then ok=false end
    end
    write(self.questions,profile.answers)
    write(self.credits,profile.coins)
    if profile.answers>=ACCURACY_MIN_ANSWERS then
        write(self.accuracy,Learning.accuracyBasisPoints(profile))
    end
    return ok
end

function Leaderboards:snapshot(limit:number?):any
    local count=math.clamp(math.floor(limit or 10),1,10)
    local ok,result=pcall(function()
        return {
            accuracyMinAnswers=ACCURACY_MIN_ANSWERS,
            accuracy=orderedRows(self.accuracy,count),
            questions=orderedRows(self.questions,count),
            credits=orderedRows(self.credits,count),
        }
    end)
    if not ok then return nil end
    return result
end

local function make(class:string,parent:Instance,props:any):Instance
    local object=Instance.new(class)
    for property,value in pairs(props or {}) do (object::any)[property]=value end
    object.Parent=parent
    return object
end

local function formatValue(kind:string,value:number):string
    if kind=="accuracy" then return string.format("%.1f%%",value/100) end
    if kind=="credits" then return tostring(value).." Credits" end
    return tostring(value)
end

local meta={
    accuracy={title="HIGHEST ACCURACY",subtitle="Correct answers ÷ all saved attempts • 20 minimum",accent=palette.green},
    questions={title="MOST QUESTIONS",subtitle="All saved answer attempts",accent=palette.blue},
    credits={title="MOST CREDITS",subtitle="Current spendable balance",accent=palette.gold},
}

local function renderBoard(part:BasePart,kind:string,rows:{any})
    local previous=part:FindFirstChild("PipLeaderboard")
    if previous then previous:Destroy() end
    local m=meta[kind]
    local gui=make("SurfaceGui",part,{Name="PipLeaderboard",Face=Enum.NormalId.Front,SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud,PixelsPerStud=36,LightInfluence=0})::SurfaceGui
    local root=make("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundColor3=palette.navy,BorderSizePixel=0})::Frame
    make("UICorner",root,{CornerRadius=UDim.new(0,10)})
    make("Frame",root,{Size=UDim2.new(1,0,0,8),BackgroundColor3=m.accent,BorderSizePixel=0})
    make("TextLabel",root,{Position=UDim2.fromOffset(18,13),Size=UDim2.new(1,-36,0,18),BackgroundTransparency=1,Text="ASSUMPTION BVM CATHOLIC SCHOOL",TextColor3=palette.gold,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left})
    make("TextLabel",root,{Position=UDim2.fromOffset(18,30),Size=UDim2.new(1,-36,0,34),BackgroundTransparency=1,Text=m.title,TextColor3=palette.paper,Font=Enum.Font.GothamBold,TextSize=23,TextXAlignment=Enum.TextXAlignment.Left})
    make("TextLabel",root,{Position=UDim2.fromOffset(18,61),Size=UDim2.new(1,-36,0,31),BackgroundTransparency=1,Text=m.subtitle,TextWrapped=true,TextColor3=palette.muted,Font=Enum.Font.GothamMedium,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left})
    local holder=make("Frame",root,{Position=UDim2.fromOffset(14,98),Size=UDim2.new(1,-28,1,-112),BackgroundTransparency=1})::Frame
    make("UIListLayout",holder,{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
    if #rows==0 then
        make("TextLabel",holder,{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,Text="No ranked players yet",TextColor3=palette.muted,Font=Enum.Font.GothamMedium,TextSize=16})
        return
    end
    for rank,row in ipairs(rows) do
        local line=make("Frame",holder,{LayoutOrder=rank,Size=UDim2.new(1,0,0,35),BackgroundColor3=Color3.fromRGB(29,43,64),BorderSizePixel=0})::Frame
        make("UICorner",line,{CornerRadius=UDim.new(0,7)})
        make("TextLabel",line,{Position=UDim2.fromOffset(8,0),Size=UDim2.fromOffset(34,35),BackgroundTransparency=1,Text="#"..rank,TextColor3=rank<=3 and m.accent or palette.muted,Font=Enum.Font.GothamBold,TextSize=14})
        make("TextLabel",line,{Position=UDim2.fromOffset(44,0),Size=UDim2.new(1,-145,1,0),BackgroundTransparency=1,Text=row.name,TextColor3=palette.paper,Font=Enum.Font.GothamMedium,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
        make("TextLabel",line,{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,0,0),Size=UDim2.fromOffset(92,35),BackgroundTransparency=1,Text=formatValue(kind,row.value),TextColor3=m.accent,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Right})
    end
end

function Leaderboards:render(parts:any,snapshot:any)
    if not snapshot or not parts then return end
    for _,kind in ipairs({"accuracy","questions","credits"}) do
        local part=parts[kind]
        if part and part:IsA("BasePart") then renderBoard(part,kind,snapshot[kind] or {}) end
    end
end

Leaderboards.ACCURACY_MIN_ANSWERS=ACCURACY_MIN_ANSWERS
Leaderboards.REFRESH_SECONDS=REFRESH_SECONDS

return Leaderboards
