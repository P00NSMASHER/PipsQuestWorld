--!strict
-- Renders baked RGB portrait rows without Roblox image assets or EditableImage.
-- Crop-aware rendering lets the same source portrait wrap across front/cheek head panels.
local Renderer={}

local function colorAt(row:string,index:number):Color3
    local offset=(index-1)*6+1
    local r=tonumber(string.sub(row,offset,offset+1),16) or 0
    local g=tonumber(string.sub(row,offset+2,offset+3),16) or 0
    local b=tonumber(string.sub(row,offset+4,offset+5),16) or 0
    return Color3.fromRGB(r,g,b)
end

local function renderInternal(parent:Instance,portrait:any,props:any?)
    if type(portrait)~="table" or type(portrait.rows)~="table" or #portrait.rows==0 then return nil end
    props=props or {}

    local width=portrait.width or 48
    local height=portrait.height or #portrait.rows
    local segment=math.max(1,math.floor(props.Segment or portrait.segment or 16))
    local sampleStep=math.max(1,math.floor(props.SampleStep or 1))

    local x0=math.clamp(props.X0 or 0,0,1)
    local x1=math.clamp(props.X1 or 1,x0,1)
    local y0=math.clamp(props.Y0 or 0,0,1)
    local y1=math.clamp(props.Y1 or 1,y0,1)

    local startX=math.clamp(math.floor(x0*(width-1))+1,1,width)
    local endX=math.clamp(math.ceil(x1*width),startX,width)
    local startY=math.clamp(math.floor(y0*(height-1))+1,1,height)
    local endY=math.clamp(math.ceil(y1*height),startY,height)
    local cropWidth=endX-startX+1
    local cropHeight=endY-startY+1

    local root=Instance.new("Frame")
    root.Name=props.Name or "BakedPortrait"
    root.Position=props.Position or UDim2.fromScale(0,0)
    root.Size=props.Size or UDim2.fromScale(1,1)
    root.BackgroundColor3=props.BackgroundColor3 or Color3.fromRGB(24,28,33)
    root.BorderSizePixel=0
    root.ClipsDescendants=true
    root.ZIndex=props.ZIndex or 2
    root.Parent=parent

    if props.CornerRadius then
        local corner=Instance.new("UICorner")
        corner.CornerRadius=UDim.new(0,props.CornerRadius)
        corner.Parent=root
    end

    for y=startY,endY,sampleStep do
        local row=portrait.rows[y]
        if type(row)=="string" and #row>=width*6 then
            for x=startX,endX,segment do
                local count=math.min(segment,endX-x+1)
                local strip=Instance.new("Frame")
                strip.Name="PortraitStrip"
                strip.Position=UDim2.fromScale((x-startX)/cropWidth,(y-startY)/cropHeight)
                strip.Size=UDim2.fromScale(
                    count/cropWidth,
                    math.min(sampleStep,endY-y+1)/cropHeight+0.0005
                )
                strip.BackgroundColor3=colorAt(row,x)
                strip.BorderSizePixel=0
                strip.ZIndex=root.ZIndex+1
                strip.Parent=root

                if count>1 then
                    local keypoints={}
                    local last=count-1
                    table.insert(keypoints,ColorSequenceKeypoint.new(0,colorAt(row,x)))
                    for i=sampleStep,last-1,sampleStep do
                        table.insert(keypoints,ColorSequenceKeypoint.new(i/last,colorAt(row,x+i)))
                    end
                    table.insert(keypoints,ColorSequenceKeypoint.new(1,colorAt(row,x+last)))
                    local gradient=Instance.new("UIGradient")
                    gradient.Name="PortraitGradient"
                    gradient.Rotation=0
                    gradient.Color=ColorSequence.new(keypoints)
                    gradient.Parent=strip
                end
            end
        end
    end
    return root
end

function Renderer.render(parent:Instance,portrait:any,props:any?)
    return renderInternal(parent,portrait,props)
end

function Renderer.renderCrop(parent:Instance,portrait:any,props:any?)
    return renderInternal(parent,portrait,props)
end

return Renderer
