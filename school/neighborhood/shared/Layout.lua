--!strict
-- Neighborhood adapter around the proven RHS2 responsive HUD geometry contract.
-- Landscape gameplay now derives from safe-area/exclusion-zone math rather than hand-tuned phone offsets.
local ResponsiveHudLayout
if script ~= nil and script.Parent ~= nil then
    ResponsiveHudLayout=require(script.Parent.ResponsiveHudLayout)
else
    ResponsiveHudLayout=require("./ResponsiveHudLayout")
end

local Layout={}

local function portraitFallback(width,height)
    local narrow=width<600
    local railHeight=narrow and 88 or 52
    local railWidth=math.min(790,math.max(280,width-24))
    local modalWidth=math.min(840,math.max(260,width-24))
    return {
        compact=height<520,
        landscape=false,
        narrow=narrow,
        headerHeight=railHeight,
        goldLandscape=false,
        compactLandscape=false,
        referenceHud=false,
        rail={x=(width-railWidth)/2,y=4,width=railWidth,height=railHeight},
        nav={x=12,y=railHeight+6,width=railWidth,height=44},
        goal={x=12,y=railHeight+10,width=math.min(286,math.max(200,width-24)),height=50},
        modal={x=(width-modalWidth)/2,y=railHeight+10,width=modalWidth,height=math.max(220,math.min(680,height-railHeight-22))},
        answerHeight=60,
        columns=1,
        shopCardHeight=166,
        shopGap=10,
        textSize=20,
        navButtonSize=40,
        drive={width=92,height=174,right=12,yScale=.58},
        exclusionZones={},
    }
end

function Layout.compute(width,height)
    width=math.max(1,width)
    height=math.max(1,height)
    if width<height or width<480 or height<300 then
        return portraitFallback(width,height)
    end

    local viewport={width=width,height=height}
    local insets={left=0,top=0,right=0,bottom=0}
    local exclusions=ResponsiveHudLayout.touchExclusionZones(viewport,insets)
    local base=ResponsiveHudLayout.compute(viewport,insets,exclusions)
    local modal=ResponsiveHudLayout.computeInteractionModal(base,{width=720,height=420})
    local driveCard=ResponsiveHudLayout.computeSafeFloatingCard(base,{width=92,height=174})

    return {
        compact=height<560,
        landscape=true,
        narrow=false,
        headerHeight=base.status.height,
        goldLandscape=true,
        compactLandscape=height<560,
        referenceHud=true,
        rail={x=base.status.x,y=base.status.y,width=base.status.width,height=base.status.height},
        nav={x=base.rail.x,y=base.rail.y,width=base.rail.width,height=base.rail.height},
        goal={x=base.quick.x,y=base.quick.y,width=base.quick.width,height=base.quick.height},
        modal={x=modal.x,y=modal.y,width=modal.width,height=modal.height,scale=modal.scale},
        answerHeight=height<520 and 54 or 60,
        columns=width>=780 and 2 or 1,
        shopCardHeight=height<520 and 156 or 166,
        shopGap=10,
        textSize=height<520 and 17 or 20,
        navButtonSize=base.railButtonSize,
        exclusionZones=base.exclusionZones,
        drive={
            width=driveCard.width,
            height=driveCard.height,
            right=math.max(0,width-driveCard.right),
            yScale=(driveCard.y+(driveCard.height/2))/height,
        },
        _responsive=base,
    }
end

return Layout
