--!strict
-- Renders baked 48x48 RGB portrait rows without Roblox image assets or EditableImage.
local Renderer={}

local function colorAt(row:string,index:number):Color3
    local offset=(index-1)*6+1
    local r=tonumber(string.sub(row,offset,offset+1),16) or 0
    local g=tonumber(string.sub(row,offset+2,offset+3),16) or 0
    local b=tonumber(string.sub(row,offset+4,offset+5),16) or 0
    return Color3.fromRGB(r,g,b)
end

function Renderer.render(parent:Instance,portrait:any,props:any?)
    if type(portrait)~="table" or type(portrait.rows)~="table" or #portrait.rows==0 then return nil end
    props=props or {}
    local width=portrait.width or 48
    local height=portrait.height or #portrait.rows
    local segment=portrait.segment or 16
    local sampleStep=math.max(1,math.floor(props.SampleStep or 1))

    local root=Instance.new("Frame")
    root.Name=props.Name or "BakedPortrait"
    root.Position=props.Position or UDim2.fromScale(0,0)
    root.Size=props.Size or UDim2.fromScale(1,1)
    root.BackgroundColor3=Color3.fromRGB(24,28,33)
    root.BorderSizePixel=0
    root.ClipsDescendants=true
    root.ZIndex=props.ZIndex or 2
    root.Parent=parent

    if props.CornerRadius then
        local corner=Instance.new("UICorner")
        corner.CornerRadius=UDim.new(0,props.CornerRadius)
        corner.Parent=root
    end

    for y=1,#portrait.rows,sampleStep do
        local row=portrait.rows[y]
        if type(row)=="string" and #row>=width*6 then
            for x=1,width,segment do
                local count=math.min(segment,width-x+1)
                local strip=Instance.new("Frame")
                strip.Name="PortraitStrip"
                strip.Position=UDim2.fromScale((x-1)/width,(y-1)/height)
                strip.Size=UDim2.fromScale(count/width,math.min(sampleStep,height-y+1)/height+0.0005)
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

return Renderer
