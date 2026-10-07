--!strict
-- Gold-standard responsive geometry in the already-safe ScreenGui coordinate space.
local Layout = {}

function Layout.compute(width, height)
    local landscape = width >= height
    local compact = height < 520
    local narrow = width < 600

    local goldLandscape = landscape and width >= 720
    local compactLandscape = goldLandscape and compact
    local railHeight = compactLandscape and 34 or (narrow and 88 or 46)
    local railWidth = compactLandscape and 104
        or (goldLandscape and math.min(360,math.max(300,width*.32)) or math.min(790,math.max(280,width-24)))
    local navWidth = compactLandscape and 58 or (goldLandscape and 78 or railWidth)
    local goalHeight = compactLandscape and 34 or (compact and 38 or (narrow and 50 or 44))
    local contentLeft = compactLandscape and 74 or (goldLandscape and 98 or 12)
    local modalWidth = math.min(goldLandscape and 780 or 840, math.max(260, width - contentLeft - 14))
    local modalY = compactLandscape and 42 or (railHeight+10)
    local modalHeight = math.max(150, math.min(680, height - modalY - 10))
    local columns = goldLandscape and 2 or 1

    return {
        compact = compact,
        landscape = landscape,
        narrow = narrow,
        headerHeight = railHeight,
        goldLandscape = goldLandscape,
        compactLandscape = compactLandscape,
        rail = {
            x=compactLandscape and (width-railWidth)/2 or (goldLandscape and math.max(116,(width-railWidth)/2) or (width-railWidth)/2),
            y=4,
            width=railWidth,
            height=railHeight,
        },
        nav = {
            x=compactLandscape and 8 or 12,
            y=compactLandscape and 48 or (goldLandscape and 64 or (railHeight+6)),
            width=navWidth,
            height=compactLandscape and 176 or (goldLandscape and 166 or 44),
        },
        goal = {
            x=compactLandscape and (width-204) or (goldLandscape and (width-290) or 12),
            y=compactLandscape and 44 or (goldLandscape and 54 or (railHeight+10)),
            width=compactLandscape and 196 or math.min(compact and 220 or 286,math.max(200,width-24)),
            height=goalHeight,
        },
        modal = {
            x=goldLandscape and contentLeft or (width-modalWidth)/2,
            y=modalY,
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
