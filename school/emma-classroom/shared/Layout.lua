--!strict
-- Pure sizing and study composition for the phone-safe GUI area.
local Layout={}
function Layout.panel(w:number,h:number)
    local landscape=w>h
    if landscape then
        local width=math.min(420,math.max(290,math.floor(w*.42)))
        return {width=math.min(width,w-24),height=math.max(150,h-132),right=12,bottom=74,landscape=true}
    end
    return {width=w-24,height=math.min(440,math.floor(h*.55)),right=12,bottom=76,landscape=false}
end
function Layout.studyCamera(w:number,h:number)
    if w>h then
        return {eye={-13,6.7,-10},target={-2,5.4,-26},fov=58}
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
