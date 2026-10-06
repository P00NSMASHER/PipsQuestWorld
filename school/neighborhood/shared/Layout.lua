--!strict
-- Work in the already-inset ScreenGui coordinate space, not raw screen pixels.
local Layout = {}
function Layout.compute(width, height)
    local compact = height < 520
    local modalWidth = math.min(620, math.max(240, width - 24))
    local headerHeight = width < 600 and 104 or 52
    local modalHeight = math.max(120, math.min(650, height - headerHeight - 24))
    return {
        compact = compact,
        headerHeight = headerHeight,
        modal = {x=(width-modalWidth)/2, y=headerHeight+12, width=modalWidth, height=modalHeight},
        answerHeight = 54,
        columns = width >= 640 and 2 or 1,
        textSize = compact and 17 or 20,
    }
end
return Layout
