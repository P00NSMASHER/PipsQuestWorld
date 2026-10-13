-- Execute against an isolated, constructed classroom in native Studio.
-- Checks existing signage without relocating any geometry.
local root=assert(workspace:FindFirstChild("ABVMClassroomReplica"),"ROOM_MISSING")
local counts={PhonicsLetter=0,PhonicsExample=0,NumberStripUnit=0,ShapeCaption=0,HandwritingSequence=0}
local signs=0
for _,object in ipairs(root:GetDescendants()) do
    if object:IsA("TextLabel") and counts[object.Name]~=nil then
        assert(object.TextScaled,"NATIVE_SIGN_SCALING_DISABLED "..object.Name)
        assert(object.TextTransparency==0,"NATIVE_SIGN_INVISIBLE "..object.Name)
        counts[object.Name]+=1
    end
    if object:IsA("BasePart") and (object.Name=="Word wall apple" or object.Name=="Word wall word card") then
        local gui=assert(object:FindFirstChildOfClass("SurfaceGui"),"WORD_GUI_MISSING")
        local maximum=object.Name=="Word wall apple" and 180 or 400
        assert(gui.CanvasSize.X<=maximum,"SIGN_CANVAS_SHRINKS_FONT_LIMIT "..object.Name)
        signs+=1
    end
end
assert(counts.PhonicsLetter==26 and counts.PhonicsExample==26,"PHONICS_COUNT_CHANGED")
assert(counts.NumberStripUnit==121 and counts.ShapeCaption==8,"FRIEZE_COUNT_CHANGED")
assert(counts.HandwritingSequence==1 and signs==41,"SIGNAGE_COUNT_CHANGED")
return {native=true,restoredScaling=counts,proportionalWordWallCanvases=signs}
