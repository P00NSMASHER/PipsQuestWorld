#!/usr/bin/env python3
"""Constructed-Luau proof of the photo-guided back-wall carpentry and classroom landmarks.

Uses actual showroom constructors, not source grep. The source photographs
show identifiable children and never enter the public repository or this test.
Static geometry safety is not native Roblox/iPhone visual acceptance.
"""
from __future__ import annotations
import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
local function parts(name)
    local found={}
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") and p.Name==name then
            table.insert(found,p)
        end
    end
    return found
end
local function one(name)
    local hits=parts(name)
    assert(#hits==1,"PHOTO_WOOD_COUNT_INVALID "..name.." "..#hits)
    return hits[1]
end
local function signText(target)
    local gui=target:FindFirstChildOfClass("SurfaceGui")
    assert(gui and gui.Face==Enum.NormalId.Front,
        "PHOTO_WOOD_STRIP_FACE_INVALID")
    local label=gui:FindFirstChildOfClass("TextLabel")
    assert(label,"PHOTO_WOOD_STRIP_TEXT_MISSING")
    return label.Text
end
local function numberedStrip(target,first,last)
    local gui=target:FindFirstChildOfClass("SurfaceGui")
    assert(gui and gui.Face==Enum.NormalId.Front
        and gui.SizingMode==Enum.SurfaceGuiSizingMode.FixedSize,
        "PHOTO_WOOD_NUMBER_STRIP_SURFACE_INVALID")
    local original=gui:FindFirstChild("Printed text")
    assert(original and original.TextTransparency>=.99
        and original.BackgroundTransparency>=.99,
        "PHOTO_WOOD_TENTH_ONLY_LABEL_VISIBLE")
    local units={}
    for _,label in ipairs(gui:GetChildren()) do
        if label.Name=="NumberStripUnit" then
            table.insert(units,label)
        end
    end
    local count=math.floor((last-first)/10)+1
    assert(#units==count,"PHOTO_WOOD_COUNTING_CELLS_INVALID")
    table.sort(units,function(a,b)
        return a.Position[1]<b.Position[1]
    end)
    for index,cell in ipairs(units) do
        local expected=first+(index-1)*10
        assert(cell:IsA("TextLabel") and
            cell.Text==tostring(expected)
            and cell.TextScaled and not cell.TextWrapped
            and math.abs(cell.Position[1]-((index-1)/count+.012))<.002
            and math.abs(cell.Size[1]-(1/count-.024))<.002,
            "PHOTO_WOOD_COUNTING_CELLS_INVALID")
    end
    return units
end
local function verify()
    -- The photo shows counting labels directly on the yellow wall below
    -- the colored shape cards, not a giant extra navy grade-wide poster.
    -- The old 18x2.5 panel occupied y=13.45..15.95 and obscured the actual
    -- number strip's vertical neighborhood at y=14.55. Removal is
    -- SUBTRACTIVE: do not replace it with another unverified wall display.
    assert(#parts("Room-wide grade 2 welcome")==0,
        "PHOTO_WOOD_UNVERIFIED_GRADE_BANNER_RETURNED")
    -- Older left-wall art frames used the exact same area as the new inset.
    -- Only the three right-of-door generic art frames may remain.
    assert(#parts("Student art walnut frame")==3,
        "PHOTO_WOOD_GALLERY_OVERLAYS_DARK_INSET")
    for _,p in ipairs(parts("Student art walnut frame")) do
        assert(p.Position.X>9,"PHOTO_WOOD_GALLERY_INSET_OVERLAP")
    end
    local shelf=one("Reading shelf back")
    local cubbies=one("Cubbies wood surround")
    local inset=one("Library built-in display backing")
    local left=one("Library counting strip backing")
    local right=one("Photo-guided cabinet counting strip")
    assert(math.abs(shelf.Position.X+22)<.03
        and math.abs(cubbies.Position.X-21)<.03
        and math.abs(shelf.Position.Z-cubbies.Position.Z)<2.5,
        "PHOTO_WOOD_BUILTINS_NOT_ON_SAME_BACK_WALL")
    local cornice=one("Library upper molded cornice")
    local upperShelf=one("Reading shelf back")
    local frameRails=parts("Library built-in dark inset frame rail")
    assert(math.abs(inset.Position.X+22)<.03
        and math.abs(inset.Position.Y-9.40)<.03
        and math.abs(inset.Position.Z-cornice.Position.Z)<.03
        and inset.Size.X>18 and inset.Size.Y>5.5,
        "PHOTO_WOOD_INSET_GEOMETRY_INVALID")
    local lowerEdge=inset.Position.Y-inset.Size.Y/2
    local corniceTop=cornice.Position.Y+cornice.Size.Y/2
    assert(math.abs(lowerEdge-corniceTop)<.12
        and math.abs(inset.Position.Z-upperShelf.Position.Z)<2.5,
        "PHOTO_WOOD_SUSPENDED_PANEL_GAP")
    assert(#frameRails==2,"PHOTO_WOOD_DARK_FRAME_RAIL_COUNT")
    local lowest=math.min(frameRails[1].Position.Y,frameRails[2].Position.Y)
    assert(math.abs(lowest-corniceTop)<.16
        and math.abs(frameRails[1].Position.Z-cornice.Position.Z)<.30
        and math.abs(frameRails[2].Position.Z-cornice.Position.Z)<.30,
        "PHOTO_WOOD_DARK_FRAME_DISCONNECTED")
    assert(lowerEdge>6.40,"PHOTO_WOOD_INSET_COVERS_EXISTING_READING_BOOKS")
    for _,p in ipairs(parts("Library built-in anonymous paper")) do
        assert(p.Position.Z<inset.Position.Z-.18
            and p.Position.Z>inset.Position.Z-.45,
            "PHOTO_WOOD_PAPER_HIDDEN_BEHIND_FRAME")
    end
    assert(#parts("Library built-in dark inset frame stile")==2
        and #parts("Library built-in dark inset frame rail")==2
        and #parts("Library built-in anonymous paper")==3
        and #parts("Library built-in paper heading")==3,
        "PHOTO_WOOD_INSET_COMPONENTS_MISSING")
    -- Real interior photos reveal a red vertical chart at the left edge
    -- and uneven, anonymous classroom papers across the black display.
    -- The old three plain beige rectangles were missing its focal color.
    local posters=parts("Library built-in anonymous paper")
    local headings=parts("Library built-in paper heading")
    assert(#posters==3 and #headings==3,
        "PHOTO_WOOD_NOTICE_PAPER_COUNT_INVALID")
    table.sort(posters,function(a,b) return a.Position.X<b.Position.X end)
    table.sort(headings,function(a,b) return a.Position.X<b.Position.X end)
    local reds=posters[1].Color
    assert(math.abs(posters[1].Position.X+27.4)<.03
        and math.abs(posters[1].Position.Y-9.55)<.03
        and math.abs(posters[1].Size.Y-3.30)<.03
        and reds.R>.60 and reds.R>.2+reds.G and reds.R>.2+reds.B,
        "PHOTO_WOOD_RED_POCKET_CHART_MISSING")
    local expectedY={9.55,9.95,9.65}
    for i,paper in ipairs(posters) do
        assert(math.abs(paper.Position.Y-expectedY[i])<.03
            and paper.Size.Y>2.4 and paper.Size.Y<3.4
            and paper.Position.Y-paper.Size.Y/2>corniceTop+.25
            and paper.Position.Y+paper.Size.Y/2<12.0
            and headings[i].Position.Y>paper.Position.Y
            and headings[i].Position.Y<
                paper.Position.Y+paper.Size.Y/2,
            "PHOTO_WOOD_NOTICE_PAPERS_OVERLAP_FRAME")
        local gui=paper:FindFirstChild("AnonymousNoticeArt")
        local layout=gui and gui:FindFirstChild("NoticeArtLayout")
        assert(gui and gui:IsA("SurfaceGui")
            and gui.Face==Enum.NormalId.Front
            and gui.SizingMode==Enum.SurfaceGuiSizingMode.FixedSize
            and gui.CanvasSize[1]==420 and gui.CanvasSize[2]==430
            and layout and layout:IsA("Frame")
            and layout.BackgroundTransparency==1,
            "PHOTO_WOOD_NOTICE_ART_MISSING")
        local slots,cards=0,0
        for _,node in ipairs(layout:GetDescendants()) do
            assert(not node:IsA("ImageLabel")
                and not node:IsA("ImageButton")
                and not node:IsA("TextLabel"),
                "PHOTO_WOOD_NOTICE_PRIVATE_OR_EXTERNAL_ASSET")
            if node.Name=="PocketChartCard" then
                slots+=1
                assert(node:IsA("Frame") and node.BackgroundTransparency==0,
                    "PHOTO_WOOD_POCKET_SLIP_INVISIBLE")
            elseif node.Name=="AnonymousPinboardCard" then
                cards+=1
            end
        end
        if i==1 then
            assert(slots==6 and cards==0,
                "PHOTO_WOOD_POCKET_SLOTS_MISSING")
        else
            assert(slots==0 and cards==4,
                "PHOTO_WOOD_ANONYMOUS_PINBOARD_INCOMPLETE")
        end
    end

    assert(math.abs(left.Position.X+22)<.03
        and math.abs(right.Position.X-20.2)<.03
        and math.abs(left.Position.Y-right.Position.Y)<.03,
        "PHOTO_WOOD_TWO_STRIPS_MISALIGNED")
    assert(signText(left)=="0  10  20  30  40  50  60"
        and signText(right)=="70  80  90  100  110  120",
        "PHOTO_WOOD_COUNTING_SEQUENCE_INVALID")
    numberedStrip(left,0,60)
    numberedStrip(right,70,120)
    assert(left.Position.X+left.Size.X/2 < -9.4
        and right.Position.X-right.Size.X/2 > 7.0,
        "PHOTO_WOOD_COUNTING_STRIP_HIDES_DOOR_OPENING")
    assert(#parts("Photo-guided wall shape card")==9,
        "PHOTO_WOOD_SHAPES_MISSING")
    for _,p in ipairs(parts("Photo-guided wall shape card")) do
        assert(p.Position.X+p.Size.X/2 < -9.0 and p.Position.X-p.Size.X/2>-37,
            "PHOTO_WOOD_SHAPES_OVER_REAR_DOORWAY")
    end

    -- Distinct teaching-color panels continue over the photo-confirmed
    -- RIGHT cabinet while the source's real central door remains open.
    local rightCards=parts("Photo-guided right cabinet shape card")
    local rightNames={"CIRCLE","OVAL","SQUARE","DIAMOND",
        "RECTANGLE","CROSS","CAPSULE","ARCH"}
    assert(#rightCards==8,"PHOTO_RIGHT_SHAPE_COUNT_INVALID")
    table.sort(rightCards,function(a,b) return a.Position.X<b.Position.X end)
    for i,card in ipairs(rightCards) do
        assert(math.abs(card.Position.X-(9.8+(i-1)*3.0))<.03
            and math.abs(card.Position.Y-16.48)<.03
            and math.abs(card.Position.Z-26.32)<.03
            and card.Position.X-card.Size.X/2>7.2
            and card.Position.X+card.Size.X/2<33.2,
            "PHOTO_RIGHT_SHAPE_CARD_OVER_DOOR")
        assert(card.Anchored and not card.CanCollide
            and not card.CanTouch and not card.CanQuery,
            "PHOTO_RIGHT_SHAPE_CARD_COLLIDES")
        local gui=card:FindFirstChild("RightCabinetShapeArt")
        assert(gui and gui:IsA("SurfaceGui")
            and gui.Face==Enum.NormalId.Front
            and gui.CanvasSize[1]==360 and gui.CanvasSize[2]==200,
            "PHOTO_RIGHT_SHAPE_ART_GUI_INVALID")
        local ground=gui:FindFirstChild("ShapeCardGround")
        local shape=ground and ground:FindFirstChild("ShapePicture")
        local caption=ground and ground:FindFirstChild("ShapeCaption")
        assert(ground and shape and shape:IsA("TextLabel") and
            shape.Text~="" and shape.BackgroundTransparency==1 and
            caption and caption:IsA("TextLabel") and
            caption.Text==rightNames[i] and
            caption.TextScaled and caption.BackgroundTransparency==1,
            "PHOTO_RIGHT_SHAPE_ART_CONTENT_INVALID")
    end
    local decorative={
        "Library built-in display backing",
        "Library built-in dark inset frame stile",
        "Library built-in dark inset frame rail",
        "Library built-in anonymous paper",
        "Library built-in paper heading",
        "Library counting strip backing",
        "Library counting strip top rail",
        "Library counting strip bottom rail",
    }
    for _,name in ipairs(decorative) do
        for _,p in ipairs(parts(name)) do
            assert(p.Anchored and not p.CanCollide and not p.CanTouch,
                "PHOTO_WOOD_NEW_DETAIL_COLLIDES "..name)
        end
    end
    assert(#parts("Photo flipchart white housing")==0
        and #parts("Photo flipchart dry erase face")==0
        and #parts("Photo flipchart blue cart support")==0,
        "REDUNDANT_CORNER_FLIPCHART_RETURNED")
    -- The teacher laptop formerly replicated 40 microscopic keyboard
    -- Parts for minimal visual return. Retain the same supported deck with
    -- a native noninteractive SurfaceGui 4x10 manufactured key pattern.
    local keyboard=one("Laptop native keyboard panel")
    assert(#parts("Laptop keyboard key")==0
        and math.abs(keyboard.Position.X+24)<.02
        and math.abs(keyboard.Position.Y-3.51)<.02
        and math.abs(keyboard.Position.Z-13.80)<.02
        and not keyboard.CanCollide and keyboard.Anchored,
        "PHOTO_LAPTOP_KEYBOARD_PHYSICAL_REGRESSION")
    local keyboardGui=keyboard:FindFirstChild("LaptopKeyboardDetail")
    local keyboardBg=keyboardGui and keyboardGui:FindFirstChild("LaptopKeyboardBackground")
    assert(keyboardGui and keyboardGui:IsA("SurfaceGui")
        and keyboardGui.Face==Enum.NormalId.Top
        and keyboardGui.CanvasSize[1]==840
        and keyboardGui.CanvasSize[2]==290
        and keyboardBg and keyboardBg:IsA("Frame"),
        "PHOTO_LAPTOP_NATIVE_KEYCAP_GUI_MISSING")
    local keyCount=0
    for _,key in ipairs(keyboardBg:GetChildren()) do
        if key.Name=="LaptopKeycap" then
            assert(key:IsA("Frame"),"PHOTO_LAPTOP_KEYCAP_WRONG_TYPE")
            keyCount+=1
        end
    end
    assert(keyCount==40,"PHOTO_LAPTOP_KEYCAP_COUNT_INVALID")
    -- IMG_2910 shows a LOW BOX FAN, not a tall round pedestal fan.
    -- Preserve noncollision and desk clearance while checking that silhouette.
    local fan=one("Photo portable fan back guard")
    local face=one("Photo portable fan translucent face")
    assert(math.abs(fan.Position.X-31)<.03
        and math.abs(fan.Position.Y-2.38)<.03
        and math.abs(fan.Position.Z+31.20)<.03,
        "PHOTO_PORTABLE_FAN_POSITION_INVALID")
    assert(fan.Shape==Enum.PartType.Cylinder
        and face.Shape==Enum.PartType.Cylinder
        and face.Transparency>.90
        and #parts("Photo portable fan blade")==3
        and #parts("Photo portable fan center hub")==1
        and #parts("Photo box fan housing side")==2
        and #parts("Photo box fan housing rail")==2
        and #parts("Photo box fan floor foot")==2
        and #parts("Photo box fan carry handle")==1
        and #parts("Photo portable fan upright")==0
        and #parts("Photo portable fan weighted foot")==0
        and #parts("Photo portable fan neck collar")==0,
        "PHOTO_PORTABLE_FAN_SILHOUETTE_INCOMPLETE")
    assert(fan.CFrame.m[7]>.99 and face.Position.Z>fan.Position.Z,
        "PHOTO_PORTABLE_FAN_FACES_AWAY_FROM_CLASSROOM")
    for _,foot in ipairs(parts("Photo box fan floor foot")) do
        assert(math.abs(foot.Position.Y-foot.Size.Y/2-.50)<.01,
            "PHOTO_BOX_FAN_FLOATS_ABOVE_FLOOR")
    end
    local grille=face:FindFirstChild("PhotoBoxFanGrille")
    assert(grille and grille.Face==Enum.NormalId.Right,
        "PHOTO_BOX_FAN_GRILLE_MISSING")
    local spokes,rings=0,0
    for _,d in ipairs(grille:GetChildren()) do
        if d.Name=="FanGrilleSpoke" then spokes+=1 end
        if d.Name=="FanGrilleRing" then rings+=1 end
    end
    assert(spokes==16 and rings==4,"PHOTO_BOX_FAN_GRILLE_INCOMPLETE")
    for _,name in ipairs({"Photo box fan housing side","Photo box fan housing rail",
        "Photo box fan floor foot","Photo box fan carry handle",
        "Photo portable fan back guard","Photo portable fan blade",
        "Photo portable fan center hub",
        "Photo portable fan translucent face"}) do
        for _,p in ipairs(parts(name)) do
            assert(p.Anchored and not p.CanCollide and not p.CanTouch,
                "PHOTO_PORTABLE_FAN_BLOCKS_AISLE")
        end
    end
    local teacherDesk=one("Teacher desk top")
    assert(math.abs(teacherDesk.Position.Z-fan.Position.Z)>5.0,
        "PHOTO_PORTABLE_FAN_OVERLAPS_TEACHER_DESK")
    assert(#parts("Student desk top")==16
        and #parts("Student chair seat")==16
        and #parts("Purple corner chair seat")==1
        and #parts("Window glass")==2
        and #parts("Alphabet rug")==1
        and #parts("Front teaching rug")==1
        and #parts("Photo rectangular alphabet sun rug")==0,
        "PHOTO_WOOD_ORIGINAL_LAYOUT_REGRESSION")
    return inset,left
end
local inset,left=verify()
print("PHOTO_WOOD_LANDMARK_RUNTIME_PASS builtins=2 inset=1 "
    .."paper=3 red_pocket_slips=6 pinboard_cards=8 distinct_number_ranges=true cards=17 "
    .."doorway_clear=true original_desks=16")
local saved=inset.CanCollide
inset.CanCollide=true
local ok,err=pcall(verify)
inset.CanCollide=saved
assert(not ok and string.find(tostring(err),"PHOTO_WOOD_NEW_DETAIL_COLLIDES",1,true),
    "PHOTO_WOOD_COLLISION_NEGATIVE_NOT_REJECTED")
print("PHOTO_WOOD_ADVERSARIAL_REJECTED display_collider")
local before=left.CFrame
left.CFrame=CFrame.new(-6,14.55,26.24)
ok,err=pcall(verify)
left.CFrame=before
assert(not ok and string.find(tostring(err),"PHOTO_WOOD_TWO_STRIPS_MISALIGNED",1,true),
    "PHOTO_WOOD_WRONG_LOCATION_NOT_REJECTED")
print("PHOTO_WOOD_ADVERSARIAL_REJECTED counting_strip_moved")
local units=numberedStrip(left,0,60)
local oldNumber=units[2].Text
units[2].Text="WRONG"
ok,err=pcall(verify)
units[2].Text=oldNumber
assert(not ok and string.find(tostring(err),
    "PHOTO_WOOD_COUNTING_CELLS_INVALID",1,true),
    "PHOTO_WOOD_MISSING_CONSECUTIVE_NUMBER_NOT_REJECTED")
print("PHOTO_WOOD_ADVERSARIAL_REJECTED scrambled_number_unit")
local obsolete=Instance.new("Part")
obsolete.Name="Room-wide grade 2 welcome"
obsolete.Size=Vector3.new(18,2.5,.18)
obsolete.CFrame=CFrame.new(-22.4,14.7,26.31)
obsolete.Anchored=true
obsolete.CanCollide=false
obsolete.Parent=Room.Root
ok,err=pcall(verify)
obsolete:Destroy()
assert(not ok and string.find(tostring(err),
    "PHOTO_WOOD_UNVERIFIED_GRADE_BANNER_RETURNED",1,true),
    "PHOTO_WOOD_GRADE_BANNER_REINTRODUCTION_NOT_REJECTED")
print("PHOTO_WOOD_ADVERSARIAL_REJECTED generic_grade_banner")
local rightCard=parts("Photo-guided right cabinet shape card")[1]
local oldRightCF=rightCard.CFrame
rightCard.CFrame=CFrame.new(2.0,16.48,26.32)
ok,err=pcall(verify)
rightCard.CFrame=oldRightCF
assert(not ok and string.find(tostring(err),
    "PHOTO_RIGHT_SHAPE_CARD_OVER_DOOR",1,true),
    "PHOTO_RIGHT_SHAPE_DOORWAY_REGRESSION_NOT_REJECTED")
print("PHOTO_RIGHT_SHAPES_ADVERSARIAL_REJECTED doorway")
local oldRightCollision=rightCard.CanCollide
rightCard.CanCollide=true
ok,err=pcall(verify)
rightCard.CanCollide=oldRightCollision
assert(not ok and string.find(tostring(err),
    "PHOTO_RIGHT_SHAPE_CARD_COLLIDES",1,true),
    "PHOTO_RIGHT_SHAPE_COLLISION_NOT_REJECTED")
print("PHOTO_RIGHT_SHAPES_ADVERSARIAL_REJECTED collidable_card")
local label=left:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
local textBefore=label.Text
label.Text="0  20  10"
ok,err=pcall(verify)
label.Text=textBefore
assert(not ok and string.find(tostring(err),"PHOTO_WOOD_COUNTING_SEQUENCE_INVALID",1,true),
    "PHOTO_WOOD_WRONG_NUMBER_ORDER_NOT_REJECTED")
local backing=one("Library built-in display backing")
local oldCF=backing.CFrame
backing.CFrame=CFrame.new(-22,9.40,26.10)
ok,err=pcall(verify)
backing.CFrame=oldCF
assert(not ok and string.find(tostring(err),
    "PHOTO_WOOD_INSET_GEOMETRY_INVALID",1,true),
    "PHOTO_WOOD_HOVERING_PANEL_NOT_REJECTED")
print("PHOTO_WOOD_ADVERSARIAL_REJECTED offset_backing")
-- Verify the red teacher chart cannot silently revert to three
-- identical blank sheets, and must retain six original pocket slips.
local pinboards=parts("Library built-in anonymous paper")
table.sort(pinboards,function(a,b) return a.Position.X<b.Position.X end)
local pocket=pinboards[1]
local originalTone=pocket.Color
pocket.Color=Color3.fromRGB(233,231,220)
ok,err=pcall(verify)
pocket.Color=originalTone
assert(not ok and string.find(tostring(err),
    "PHOTO_WOOD_RED_POCKET_CHART_MISSING",1,true),
    "PHOTO_WOOD_CHART_COLOR_REGRESSION_NOT_REJECTED")
print("PHOTO_WOOD_ADVERSARIAL_REJECTED missing_red_chart")
local layout=pocket:FindFirstChild("AnonymousNoticeArt")
    :FindFirstChild("NoticeArtLayout")
local slip
for _,node in ipairs(layout:GetChildren()) do
    if node.Name=="PocketChartCard" then slip=node break end
end
assert(slip,"PHOTO_WOOD_POCKET_MUTATION_FIXTURE_MISSING")
local originalSlipName=slip.Name
slip.Name="LostPocket"
ok,err=pcall(verify)
slip.Name=originalSlipName
assert(not ok and string.find(tostring(err),
    "PHOTO_WOOD_POCKET_SLOTS_MISSING",1,true),
    "PHOTO_WOOD_MISSING_POCKET_NOT_REJECTED")
print("PHOTO_WOOD_ADVERSARIAL_REJECTED lost_pocket_slip")

local keyboard=one("Laptop native keyboard panel")
local board=keyboard:FindFirstChild("LaptopKeyboardDetail"):FindFirstChild("LaptopKeyboardBackground")
local oneKey=nil
for _,k in ipairs(board:GetChildren()) do
    if k.Name=="LaptopKeycap" then oneKey=k break end
end
assert(oneKey,"PHOTO_LAPTOP_KEYCAP_NEGATIVE_FIXTURE_MISSING")
local oldName=oneKey.Name
oneKey.Name="LostKeycap"
ok,err=pcall(verify)
oneKey.Name=oldName
assert(not ok and string.find(tostring(err),
    "PHOTO_LAPTOP_KEYCAP_COUNT_INVALID",1,true),
    "PHOTO_LAPTOP_DROPPED_KEYCAP_NOT_REJECTED")
print("PHOTO_LAPTOP_ADVERSARIAL_REJECTED missing_keycap")
local portable=one("Photo portable fan back guard")
local oldCollision=portable.CanCollide
portable.CanCollide=true
ok,err=pcall(verify)
portable.CanCollide=oldCollision
assert(not ok and string.find(tostring(err),
    "PHOTO_PORTABLE_FAN_BLOCKS_AISLE",1,true),
    "PHOTO_PORTABLE_FAN_COLLISION_NOT_REJECTED")
print("PHOTO_FAN_ADVERSARIAL_REJECTED collider")
local foot=parts("Photo box fan floor foot")[1]
local oldFoot=foot.CFrame
foot.CFrame=oldFoot*CFrame.new(0,1,0)
ok,err=pcall(verify)
foot.CFrame=oldFoot
assert(not ok and string.find(tostring(err),"PHOTO_BOX_FAN_FLOATS_ABOVE_FLOOR",1,true),
    "PHOTO_BOX_FAN_FLOAT_FALSE_ACCEPT")
local grille=one("Photo portable fan translucent face"):FindFirstChild("PhotoBoxFanGrille")
local oldGrilleFace=grille.Face
grille.Face=Enum.NormalId.Left
ok,err=pcall(verify)
grille.Face=oldGrilleFace
assert(not ok and string.find(tostring(err),"PHOTO_BOX_FAN_GRILLE_MISSING",1,true),
    "PHOTO_BOX_FAN_BACKWARD_GRILLE_FALSE_ACCEPT")
print("PHOTO_BOX_FAN_ADVERSARIAL_REJECTED floating_or_backward")
verify()
print("PHOTO_WOOD_LANDMARK_NEGATIVE_TESTS_PASS collider location right_shapes number_order number_units panel_depth grade_banner red_chart pocket_slips laptop fan")
'''
def main() -> None:
    p=argparse.ArgumentParser()
    p.add_argument("--luau",required=True)
    args=p.parse_args()
    with tempfile.TemporaryDirectory(prefix="emma-wood-") as tmp:
        script=Path(tmp)/"photo_landmarks.lua"
        script.write_text(generate_luau()+"\n"+PROBE+"\n",encoding="utf-8")
        r=subprocess.run([args.luau,str(script)],capture_output=True,
            text=True,timeout=115,check=False)
    if r.returncode:
        raise RuntimeError("Constructed photo landmarks failed:\n"
            +r.stderr[-3300:]+"\n"+r.stdout[-1900:])
    markers=("PHOTO_WOOD_LANDMARK_RUNTIME_PASS",
        "PHOTO_WOOD_ADVERSARIAL_REJECTED display_collider",
        "PHOTO_WOOD_ADVERSARIAL_REJECTED counting_strip_moved",
        "PHOTO_WOOD_ADVERSARIAL_REJECTED offset_backing",
        "PHOTO_WOOD_ADVERSARIAL_REJECTED missing_red_chart",
        "PHOTO_WOOD_ADVERSARIAL_REJECTED lost_pocket_slip",
        "PHOTO_RIGHT_SHAPES_ADVERSARIAL_REJECTED doorway",
        "PHOTO_RIGHT_SHAPES_ADVERSARIAL_REJECTED collidable_card",
        "PHOTO_WOOD_ADVERSARIAL_REJECTED scrambled_number_unit",
        "PHOTO_WOOD_ADVERSARIAL_REJECTED generic_grade_banner",
        "PHOTO_LAPTOP_ADVERSARIAL_REJECTED missing_keycap",
        "PHOTO_FAN_ADVERSARIAL_REJECTED collider",
        "PHOTO_BOX_FAN_ADVERSARIAL_REJECTED floating_or_backward",
        "PHOTO_WOOD_LANDMARK_NEGATIVE_TESTS_PASS")
    for marker in markers:
        assert any(line.startswith(marker) for line in r.stdout.splitlines()),marker
    for line in r.stdout.splitlines():
        if line.startswith(("PHOTO_WOOD_LANDMARK_RUNTIME_PASS",
            "PHOTO_WOOD_ADVERSARIAL_REJECTED",
            "PHOTO_FLIPCHART_ADVERSARIAL_REJECTED",
            "PHOTO_BOX_FAN_ADVERSARIAL_REJECTED",
            "PHOTO_RIGHT_SHAPES_ADVERSARIAL_REJECTED",
            "PHOTO_WOOD_LANDMARK_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)
if __name__=="__main__":
    main()
