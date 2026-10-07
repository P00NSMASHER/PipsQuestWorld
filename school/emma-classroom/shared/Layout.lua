--!strict
-- Pure sizing for the device-safe GUI area, independent of the 3D camera.
local Layout={}
function Layout.panel(w:number,h:number)
    local landscape=w>h
    if landscape then
        local width=math.min(420,math.max(290,math.floor(w*.42)))
        return {width=math.min(width,w-24),height=math.max(150,h-132),right=12,bottom=74,landscape=true}
    end
    return {width=w-24,height=math.min(440,math.floor(h*.55)),right=12,bottom=76,landscape=false}
end
return Layout
