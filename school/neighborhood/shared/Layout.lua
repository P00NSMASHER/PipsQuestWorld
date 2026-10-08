--!strict
-- User-approved responsive geometry: CoreGui-height top capsule + right-side nav on iPhone landscape.
local Layout = {}

function Layout.compute(width, height)
    local landscape = width >= height
    local compact = height < 520
    local narrow = width < 600

    -- The right-side rail is reserved for the actual iPhone-landscape acceptance shape.
    -- Shorter/narrower canvases keep a horizontal fallback so the rail never collides with jump controls.
    local goldLandscape = landscape and width >= 900 and height >= 400
    local topY = goldLandscape and 15 or 58
    local railHeight = narrow and 100 or 56
    local rightMargin = 8
    local coreGuiReserve = goldLandscape and math.min(360,math.max(290,width*.31)) or 12
    local topAvailable = math.max(280,width-coreGuiReserve-rightMargin)
    local railWidth = goldLandscape
        and math.min(650,math.max(400,topAvailable-20))
        or math.min(790,math.max(280,width-24))
    local railX = goldLandscape
        and (coreGuiReserve+(width-coreGuiReserve-rightMargin-railWidth)/2)
        or ((width-railWidth)/2)

    local navWidth = goldLandscape and 104 or math.min(width-24,railWidth)
    local navHeight = goldLandscape and 212 or (narrow and 46 or 44)
    local navX = goldLandscape and (width-navWidth-rightMargin) or 12
    local navY = topY+railHeight+(goldLandscape and 14 or 6)

    local topCompact = (not narrow) and railWidth < 520
    local goalX
    local goalY
    local goalWidth
    if narrow then
        goalX=8
        goalY=52
        goalWidth=railWidth-16
    else
        local profileWidth=topCompact and 126 or 204
        goalX=profileWidth+4
        goalY=5
        goalWidth=math.max(116,railWidth-goalX-124)
    end

    local contentRight = goldLandscape and (navX-12) or (width-12)
    local modalWidth = math.min(850,math.max(260,contentRight-24))
    local modalX = goldLandscape and math.max(12,(contentRight-modalWidth)/2) or ((width-modalWidth)/2)
    local modalY = goldLandscape and (topY+railHeight+10) or (navY+navHeight+8)
    local modalHeight = math.max(120,math.min(680,height-modalY-12))
    local columns = (landscape and width>=720) and 2 or 1

    return {
        compact = compact,
        landscape = landscape,
        narrow = narrow,
        topCompact = topCompact,
        headerHeight = topY+railHeight,
        goldLandscape = goldLandscape,
        rail = {
            x=railX,
            y=topY,
            width=railWidth,
            height=railHeight,
        },
        nav = {
            x=navX,
            y=navY,
            width=navWidth,
            height=navHeight,
        },
        goal = {
            x=goalX,
            y=goalY,
            width=goalWidth,
            height=46,
        },
        modal = {
            x=modalX,
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
