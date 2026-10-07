--!strict
-- Gold-standard responsive geometry in the already-safe ScreenGui coordinate space.
local Layout = {}

function Layout.compute(width, height)
    local landscape = width >= height
    local compact = height < 520
    local narrow = width < 600

    local goldLandscape = landscape and width >= 720
    local railHeight = narrow and 88 or (compact and 40 or 46)
    local railWidth = goldLandscape and math.min(420,math.max(330,width*.38)) or math.min(790, math.max(280, width - 24))
    local navWidth = goldLandscape and 84 or railWidth
    local goalHeight = compact and 38 or (narrow and 50 or 44)
    local contentLeft = goldLandscape and 104 or 12
    local modalWidth = math.min(goldLandscape and 780 or 840, math.max(260, width - contentLeft - 14))
    local modalHeight = math.max(150, math.min(680, height - railHeight - 22))
    local columns = goldLandscape and 2 or 1

    return {
        compact = compact,
        landscape = landscape,
        narrow = narrow,
        headerHeight = railHeight,
        goldLandscape = goldLandscape,
        rail = {
            x=goldLandscape and math.max(132,(width-railWidth)/2) or (width-railWidth)/2,
            y=4,
            width=railWidth,
            height=railHeight,
        },
        nav = {
            x=12,
            y=goldLandscape and 68 or (railHeight+6),
            width=navWidth,
            height=goldLandscape and 170 or 44,
        },
        goal = {
            x=goldLandscape and (width-(compact and 232 or 298)) or 12,
            y=goldLandscape and (compact and 5 or 58) or (railHeight+10),
            width=math.min(compact and 220 or 286,math.max(200,width-24)),
            height=goalHeight,
        },
        modal = {
            x=goldLandscape and contentLeft or (width-modalWidth)/2,
            y=railHeight+10,
            width=modalWidth,
            height=modalHeight,
        },
        answerHeight = compact and 54 or 60,
        columns = columns,
        shopCardHeight = compact and 156 or 166,
        shopGap = 10,
        textSize = compact and 17 or 20,
        drive = {
            width = 92,
            height = 174,
            right = 12,
            yScale = compact and .47 or .58,
        },
    }
end

return Layout
