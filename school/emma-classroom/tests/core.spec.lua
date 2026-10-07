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
for _,size in ipairs({{568,280},{724,320},{844,390},{1112,512},{390,760},{375,600},{1024,700}}) do
    local w,h=size[1],size[2]
    local p=Layout.panel(w,h)
    assert(p.width>0 and p.height>104)
    assert(p.width+p.right<=w and p.height+p.bottom<=h)
    if w>h then assert(p.width/w<.55,"Leave the left classroom and thumbstick area clear") end
end
print("PASS: 18 staff, 134 valid server-only questions, seven device-safe panel sizes")
