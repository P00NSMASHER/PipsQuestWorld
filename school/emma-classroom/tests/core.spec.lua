local Data=require("../shared/Data")
local Questions=require("../server/QuestionBank")
local Layout=require("../shared/Layout")
assert(#Data.Teachers==18,"All labeled staff must be represented")
assert(Data.Questions==nil,"Shared metadata cannot include the answer bank")
assert(#Questions==134,"Preserve the reviewed question bank")
local names,ids={},{}
for _,teacher in ipairs(Data.Teachers) do
    assert(not names[teacher.fullName]);names[teacher.fullName]=true
    assert(teacher.role~="" and teacher.clothing~="")
end
for _,q in ipairs(Questions) do
    assert(not ids[q.id]);ids[q.id]=true
    assert(q.prompt~="" and #q.choices>=2 and table.find(q.choices,q.answer))
end
local function minus(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
local function unit(a) local n=math.sqrt(dot(a,a));return {a[1]/n,a[2]/n,a[3]/n} end
local function cross(a,b) return {a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]} end
local function project(point,camera,w,h)
    local f=unit(minus(camera.target,camera.eye));local r=unit(cross(f,{0,1,0}));local u=cross(r,f)
    local v=minus(point,camera.eye);local distance=dot(v,f)
    assert(distance>0)
    local focal=h/(2*math.tan(math.rad(camera.fov)/2))
    return w/2+focal*dot(v,r)/distance,h/2-focal*dot(v,u)/distance
end
for _,size in ipairs({{568,280},{724,320},{844,390},{1112,512},{390,760},{375,600},{1024,700}}) do
    local w,h=size[1],size[2]
    local p=Layout.panel(w,h)
    assert(p.width>0 and p.height>104)
    assert(p.width+p.right<=w and p.height+p.bottom<=h)
    if w>h then assert(p.width/w<.55,"Leave the left classroom and thumbstick area clear") end
    -- Check the whole head, not just its center, against the actual answer panel.
    local camera=Layout.studyCamera(w,h)
    local minY,maxY,maxX=math.huge,-math.huge,-math.huge
    for _,x in ipairs({-10.96,-9.04}) do for _,y in ipairs({5.45,7.40}) do
        local sx,sy=project({x,y,-20},camera,w,h)
        assert(sx>12 and sx<w-12)
        minY=math.min(minY,sy);maxY=math.max(maxY,sy);maxX=math.max(maxX,sx)
    end end
    assert(minY>50,"Keep the head clear of native top controls")
    if w>h then assert(maxX<w-p.width-p.right-8,"Keep the head beside the answer panel")
    else assert(maxY<h-p.height-p.bottom-8,"Keep the head above the portrait answer panel") end
end
-- Answers reserve their own visible space, independent of prompt/hint length.
for _,size in ipairs({{568,280},{724,320},{844,390},{1112,512},{390,760},{375,600},{1024,700}}) do
    local panel=Layout.panel(size[1],size[2])
    for count=1,3 do for _,promptHeight in ipairs({40,100,500}) do
        local area=Layout.questionArea(panel.height,count,promptHeight)
        assert(area.answerHeight>=44,"Each answer needs a touch target")
        assert(area.answerTop+area.answerTotal<=panel.height-40,"All answers must be above feedback/skip")
        assert(area.prompt>=28,"Question/hint remains independently scrollable")
    end end
end
local retryDelays={}
for attempt=1,20 do
    local delay=Layout.connectionRetryDelay(attempt)
    assert(delay>=.4 and delay<=5,"Connection retry delay must stay bounded")
    assert(attempt==1 or delay>=retryDelays[attempt-1],"Connection retry backoff must be monotonic")
    retryDelays[attempt]=delay
end
assert(retryDelays[1]==.4 and retryDelays[5]==5 and retryDelays[20]==5)
print("PASS: 18 staff, 134 valid server-only questions, seven device-safe panels, unobstructed study-camera head bounds and bounded startup recovery")
