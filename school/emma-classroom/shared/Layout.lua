--!strict
-- Pure sizing and study composition for the phone-safe GUI area.
local Layout={}
function Layout.panel(w:number,h:number)
    local landscape=w>h
    local width=landscape and math.min(460,math.max(280,math.floor(w*.50))) or w-24
    return {width=math.min(width,w-24),height=landscape and h-8 or math.min(480,math.floor(h*.62)),right=12,bottom=4,landscape=landscape}
end

-- Reserve the answers first. Only the question/hint may scroll; choices never
-- disappear below the fold, including on an iPhone in landscape orientation.
function Layout.questionArea(panelHeight:number,count:number,desiredPromptHeight:number)
    local columns=count==4 and panelHeight<310 and 2 or 1
    local rows=math.max(1,math.ceil(count/columns))
    local available=panelHeight-80
    local prompt=math.max(28,math.min(desiredPromptHeight,available-rows*44-(rows-1)*6-8))
    local answerHeight=math.max(44,math.floor((available-prompt-8-(rows-1)*6)/rows))
    return {columns=columns,prompt=prompt,answerHeight=answerHeight,answerTop=34+prompt+8,answerTotal=rows*answerHeight+(rows-1)*6}
end
function Layout.studyCamera(w:number,h:number)
    if w>h then
        -- A real Studio Play capture showed the entire character below the
        -- viewport while the chalkboard filled the frame. Look toward the
        -- visiting teacher's full body and preserve the board to the right.
        -- Wider FOV clears the head AND feet at short iPhone aspect ratios.
        return {eye={-13,6.7,-10},target={-5,3.2,-24},fov=64}
    end
    return {eye={-13,6.7,-10},target={-9,2,-20},fov=70}
end

-- A live DataStore load can legitimately outlast the first few client calls.
-- Keep reconnect attempts gentle and bounded per attempt without ever forcing
-- Emma to leave a healthy server just because startup was slow.
function Layout.connectionRetryDelay(attempt:number):number
    local step=math.max(0,math.floor(attempt)-1)
    return math.min(5,.4*2^math.min(step,4))
end
return Layout
