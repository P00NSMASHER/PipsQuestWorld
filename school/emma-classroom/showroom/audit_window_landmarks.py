#!/usr/bin/env python3
"""Verify photo-specific school window details using constructed Luau.

No uploaded photos, student data, or publishing operations are involved.
One negative test deliberately collides the AC; a second moves the S'more
banner to the wrong window, and a third deletes its classroom wording.
"""
from __future__ import annotations

import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
local function parts(name)
    local out={}
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") and p.Name==name then
            table.insert(out,p)
        end
    end
    return out
end
local function one(name)
    local v=parts(name)
    assert(#v==1,"WINDOW_CUE_COUNT_INVALID "..name)
    return v[1]
end
local function signText(p)
    local g=p:FindFirstChildOfClass("SurfaceGui")
    assert(g and g.Face==Enum.NormalId.Right,
        "WINDOW_CUE_TEXT_FACE_INVALID "..p.Name)
    local text=g:FindFirstChildOfClass("TextLabel")
    assert(text~=nil,"WINDOW_CUE_TEXT_MISSING "..p.Name)
    return text
end
local function check()
    assert(#parts("Smore classroom main title")==0,
        "WINDOW_CUE_OVERLAPPING_SMORE_BANNER_RETURNED")
    local headline=one("Smore faith headline")
    local faith=one("Classroom faith window banner")
    assert(signText(headline).Text=="JESUS LOVES YOU" and
        signText(faith).Text=="I AM A CHILD OF GOD. I MAKE A DIFFERENCE!",
        "WINDOW_CUE_WORDING_INVALID")
    assert(math.abs(headline.Position.Z+19)<.03 and
        math.abs(faith.Position.Z-6)<.03,
        "WINDOW_CUE_BAY_POSITION_INVALID")
    assert(headline.Position.Y>15.40 and faith.Position.Y>14.90,
        "WINDOW_CUE_SIGN_HEIGHT_INVALID")
    assert(math.abs(headline.Size.Z-faith.Size.Z)<.03
        and math.abs((headline.Position.Z+faith.Position.Z)/2+6.5)<.03,
        "WINDOW_CUE_DECOR_NOT_SYMMETRIC")
    assert(#parts("Smore mural pine trunk")==2 and
        #parts("Smore mural green canopy")==4,
        "WINDOW_CUE_MURAL_TREES_MISSING")
    local ac=one("Photo window air conditioner housing")
    assert(math.abs(ac.Position.Z+19)<.03
        and math.abs(ac.Position.X+35.55)<.03
        and math.abs(ac.Position.Y-5.23)<.03,
        "WINDOW_CUE_AC_LOCATION_INVALID")
    assert(ac.Size.X>1.0 and ac.Size.Y>1.20
        and ac.Size.Z>4.70 and ac.Size.Z<4.90,
        "WINDOW_CUE_AC_SCALE_INVALID")
    local sill=nil
    for _,p in ipairs(parts("Deep window sill")) do
        if math.abs(p.Position.Z+19)<.03 then sill=p end
    end
    assert(sill~=nil,"WINDOW_CUE_SILL_MISSING")
    local clearance=ac.Position.Y-ac.Size.Y/2-
        (sill.Position.Y+sill.Size.Y/2)
    assert(clearance>=0 and clearance<.06,
        "WINDOW_CUE_AC_SUPPORT_INVALID")
    assert(#parts("Photo AC horizontal vent louver")==5
        and #parts("Photo AC control dial")==2
        and #parts("Photo AC control fascia")==1,
        "WINDOW_CUE_AC_FACE_INCOMPLETE")
    -- The owner-provided window-wall photo shows the white analog clock
    -- between the two school windows. The former front-wall clock was a
    -- provenance error; verify the actual physically constructed five-part
    -- assembly rather than a text-only code search.
    local clock=one("Classroom wall clock")
    local rim=one("Clock rim")
    local dial=one("Clock visible dial")
    local minute=one("Clock minute hand")
    local hour=one("Clock hour hand")
    assert(clock.Shape==Enum.PartType.Cylinder
        and math.abs(clock.Position.X+36.38)<.03
        and math.abs(clock.Position.Y-11.60)<.03
        and math.abs(clock.Position.Z+6.50)<.03,
        "PHOTO_WINDOW_CLOCK_LOCATION_INVALID")
    assert(clock.Position.Z>left.Position.Z+8
        and clock.Position.Z<faith.Position.Z-7
        and clock.Position.X<-35.8,
        "PHOTO_WINDOW_CLOCK_NOT_BETWEEN_WINDOWS")
    local matrix=clock.CFrame.m
    assert(matrix and matrix[1]>.98,
        "PHOTO_WINDOW_CLOCK_FACING_AWAY_FROM_ROOM")
    assert(math.abs(rim.Position.X-clock.Position.X)<.03
        and dial.Position.X>clock.Position.X+.18
        and minute.Position.X>dial.Position.X+.06
        and hour.Position.X>dial.Position.X+.06,
        "PHOTO_WINDOW_CLOCK_FACE_ASSEMBLY_INVALID")
    -- The actual school's white analog clock has a red outer rim. The
    -- original 5-Part draft clock had a dark gray ring and blank dial.
    assert(rim.Material==Enum.Material.SmoothPlastic
        and rim.Color.R>.62 and rim.Color.R<.71
        and rim.Color.G>.20 and rim.Color.G<.27
        and rim.Color.B>.21 and rim.Color.B<.28,
        "PHOTO_WINDOW_CLOCK_RED_RIM_REGRESSION")
    local face= dial:FindFirstChild("PhotoSchoolClockFace")
    assert(face and face:IsA("SurfaceGui")
        and face.Face==Enum.NormalId.Right
        and face.SizingMode==Enum.SurfaceGuiSizingMode.FixedSize
        and face.CanvasSize[1]==384 and face.CanvasSize[2]==384,
        "PHOTO_WINDOW_CLOCK_DIAL_FACING_AWAY")
    local nCount,tickCount,seenNumbers=0,0,{}
    for _,node in ipairs(face:GetChildren()) do
        if node.Name=="ClockHourNumeral" then
            nCount+=1
            local n=tonumber(node.Text)
            assert(n and n>=1 and n<=12 and not seenNumbers[n]
                and node:IsA("TextLabel")
                and node.BackgroundTransparency==1
                and node.TextScaled and not node.TextWrapped,
                "PHOTO_WINDOW_CLOCK_NUMBER_ORDER_INVALID")
            seenNumbers[n]=true
            local theta=n*math.pi/6
            local x=.5+.372*math.sin(theta)-.073
            local y=.5-.372*math.cos(theta)-.064
            assert(math.abs(node.Position[1]-x)<.003
                and math.abs(node.Position[2]-y)<.003
                and node.Size[1]>.14 and node.Size[2]>.12,
                "PHOTO_WINDOW_CLOCK_NUMBER_PLACEMENT_INVALID")
        elseif node.Name=="ClockHourTick" then
            tickCount+=1
            assert(node:IsA("Frame")
                and node.BackgroundTransparency==0
                and node.Size[1]<.02 and node.Size[2]<.06,
                "PHOTO_WINDOW_CLOCK_TICK_INVALID")
        end
    end
    assert(nCount==12 and tickCount==12,
        "PHOTO_WINDOW_CLOCK_FACE_DETAILS_MISSING")
    for n=1,12 do
        assert(seenNumbers[n],"PHOTO_WINDOW_CLOCK_FACE_DETAILS_MISSING")
    end
    for _,p in ipairs({clock,rim,dial,minute,hour}) do
        assert(p.Anchored and not p.CanCollide and not p.CanTouch,
            "PHOTO_WINDOW_CLOCK_DECOR_COLLIDES")
    end
    local seen={"Classroom faith window banner","Smore faith headline",
        "Smore mural pine trunk",
        "Smore mural green canopy","Photo window air conditioner housing",
        "Photo AC inset front grille","Photo AC horizontal vent louver",
        "Photo AC control fascia","Photo AC control dial"}
    for _,name in ipairs(seen) do
        for _,p in ipairs(parts(name)) do
            assert(p.Anchored and not p.CanCollide and
                not p.CanTouch and not p.CanQuery,
                "WINDOW_CUE_DECOR_COLLIDES "..name)
        end
    end
    -- The classroom photographs show dark, soft, side-gathered window
    -- curtains. Test actual constructed and ROTATED visual bounds: the
    -- transparent center of both windows must remain at least 11 studs.
    local panels=parts("Navy curtain fabric panel")
    local pleats=parts("Navy curtain stitched pleat")
    local belts=parts("Navy curtain cloth tieback")
    local topValances=parts("Blue curtain valance")
    assert(#panels==4 and #pleats==8 and #belts==4
        and #topValances==2,
        "WINDOW_DRAPE_COMPONENTS_MISSING")
    local pairSides={[-19]={},[6]={}}
    for _,panel in ipairs(panels) do
        local nearest=math.abs(panel.Position.Z+19)<math.abs(panel.Position.Z-6)
            and -19 or 6
        local offset=panel.Position.Z-nearest
        local side=offset>0 and 1 or -1
        local m=panel.CFrame.m
        local halfZ=(math.abs(m[7])*panel.Size.X+
            math.abs(m[8])*panel.Size.Y+
            math.abs(m[9])*panel.Size.Z)/2
        assert(panel.Material==Enum.Material.Fabric
            and panel.Anchored and not panel.CanCollide
            and not panel.CanTouch and not panel.CanQuery
            and math.abs(panel.Position.X+35.43)<.02
            and math.abs(panel.Position.Y-9.05)<.02
            and math.abs(math.abs(offset)-6.65)<.02,
            "WINDOW_DRAPE_PANEL_LOST_JAMB")
        assert(side*m[8]>.045 and side*m[8]<.060,
            "WINDOW_DRAPE_FLAT_PANEL_RETURNED")
        assert(math.abs(offset)-halfZ>5.5
            and math.abs(offset)+halfZ<7.78,
            "WINDOW_DRAPE_DAYLIGHT_APERTURE_BLOCKED")
        pairSides[nearest][side]=true
    end
    assert(pairSides[-19][-1] and pairSides[-19][1]
        and pairSides[6][-1] and pairSides[6][1],
        "WINDOW_DRAPE_MISSING_SYMMETRIC_PANEL")
    for _,fold in ipairs(pleats) do
        local matrix=fold.CFrame.m
        assert(fold.Material==Enum.Material.Fabric
            and fold.Size.X>=.14 and fold.Size.Y>7.60
            and fold.Size.Z>=.24
            and math.abs(fold.Position.X+35.22)<.03
            and math.abs(matrix[8])>.095
            and fold.Anchored and not fold.CanCollide
            and not fold.CanTouch and not fold.CanQuery
            and not fold.CastShadow,
            "WINDOW_DRAPE_FLAT_OR_COLLIDING_PLEATS")
    end
    for _,tie in ipairs(belts) do
        assert(math.abs(tie.Position.X+35.13)<.03
            and math.abs(tie.Position.Y-7.70)<.03
            and tie.Size.Z>1.25 and tie.Size.Y>=.26
            and tie.Material==Enum.Material.Fabric
            and tie.Anchored and not tie.CanCollide
            and not tie.CanTouch and not tie.CanQuery,
            "WINDOW_DRAPE_TIEBACK_FLOATING")
    end
    assert(#parts("Window glass")==2 and
        #parts("Navy curtain fabric panel")==4 and
        #parts("Purple corner chair seat")==1 and
        #parts("Student desk top")==16,
        "WINDOW_CUE_ORIGINAL_ROOM_REGRESSION")
    return left,ac,clock
end
local left,ac,clock=check()
print("WINDOW_CUE_RUNTIME_PASS draped_windows=2 panels=4 folds=8 "..
    "banners=2 pines=2 "
    .."photo_ac=1 louvers=5 controls=2 collision_free=true "
    .."windows=2 purple_chair=1 desk_pairs=16")
local old=ac.CanCollide
ac.CanCollide=true
local ok,err=pcall(check)
ac.CanCollide=old
assert(not ok and string.find(tostring(err),
    "WINDOW_CUE_DECOR_COLLIDES",1,true),
    "WINDOW_CUE_COLLIDING_AC_NOT_REJECTED")
print("WINDOW_CUE_ADVERSARIAL_REJECTED collidable_ac")
local before=left.CFrame
left.CFrame=CFrame.new(-36.28,15.39,6)
ok,err=pcall(check)
left.CFrame=before
assert(not ok and string.find(tostring(err),
    "WINDOW_CUE_BAY_POSITION_INVALID",1,true),
    "WINDOW_CUE_WRONG_WINDOW_NOT_REJECTED")
print("WINDOW_CUE_ADVERSARIAL_REJECTED wrong_window")
local label=signText(left)
local saved=label.Text
label.Text="WELCOME"
ok,err=pcall(check)
label.Text=saved
assert(not ok and string.find(tostring(err),
    "WINDOW_CUE_WORDING_INVALID",1,true),
    "WINDOW_CUE_WRONG_TEXT_NOT_REJECTED")
local originalClock=clock.CFrame
clock.CFrame=CFrame.new(31.5,15.1,-34)*CFrame.Angles(0,math.pi/2,0)
ok,err=pcall(check)
clock.CFrame=originalClock
assert(not ok and string.find(tostring(err),
    "PHOTO_WINDOW_CLOCK_LOCATION_INVALID",1,true),
    "PHOTO_WINDOW_CLOCK_FRONT_WALL_REGRESSION_NOT_REJECTED")
print("WINDOW_CUE_ADVERSARIAL_REJECTED front_wall_clock")
local rim=one("Clock rim")
local oldRimColor=rim.Color
rim.Color=Color3.fromRGB(61,63,63)
ok,err=pcall(check)
rim.Color=oldRimColor
assert(not ok and string.find(tostring(err),
    "PHOTO_WINDOW_CLOCK_RED_RIM_REGRESSION",1,true),
    "PHOTO_WINDOW_CLOCK_OLD_GRAY_RIM_NOT_REJECTED")
print("WINDOW_CUE_ADVERSARIAL_REJECTED old_gray_clock_rim")
local dial=one("Clock visible dial")
local clockGUI=dial:FindFirstChild("PhotoSchoolClockFace")
local label
for _,child in ipairs(clockGUI:GetChildren()) do
    if child.Name=="ClockHourNumeral" and child.Text=="12" then
        label=child break
    end
end
assert(label,"PHOTO_WINDOW_CLOCK_TEST_12_MISSING")
local beforeNumeral=label.Text
label.Text="13"
ok,err=pcall(check)
label.Text=beforeNumeral
assert(not ok and string.find(tostring(err),
    "PHOTO_WINDOW_CLOCK_NUMBER_ORDER_INVALID",1,true),
    "PHOTO_WINDOW_CLOCK_BAD_NUMBER_NOT_REJECTED")
print("WINDOW_CUE_ADVERSARIAL_REJECTED wrong_analog_numeral")
local panels=parts("Navy curtain fabric panel")
local oldCurtainCF=panels[1].CFrame
panels[1].CFrame=CFrame.new(panels[1].Position)
ok,err=pcall(check)
panels[1].CFrame=oldCurtainCF
assert(not ok and string.find(tostring(err),
    "WINDOW_DRAPE_FLAT_PANEL_RETURNED",1,true),
    "WINDOW_DRAPE_STRAIGHT_BARS_NOT_REJECTED")
print("WINDOW_CUE_ADVERSARIAL_REJECTED flat_curtaindrape")
local off=panels[1].Position.Z>-19 and 6 or -19
local side=panels[1].Position.Z>off and 1 or -1
panels[1].CFrame=CFrame.new(panels[1].Position.X,9.05,
    off+side*5.45)*CFrame.Angles(math.rad(side*3),0,0)
ok,err=pcall(check)
panels[1].CFrame=oldCurtainCF
assert(not ok and (string.find(tostring(err),
    "WINDOW_DRAPE_PANEL_LOST_JAMB",1,true) or
    string.find(tostring(err),
    "WINDOW_DRAPE_DAYLIGHT_APERTURE_BLOCKED",1,true)),
    "WINDOW_DRAPE_COVERED_GLASS_NOT_REJECTED")
print("WINDOW_CUE_ADVERSARIAL_REJECTED blocked_window_aperture")
local pleat=parts("Navy curtain stitched pleat")[1]
local pleatCF=pleat.CFrame
pleat.CFrame=CFrame.new(pleat.Position)
ok,err=pcall(check)
pleat.CFrame=pleatCF
assert(not ok and string.find(tostring(err),
    "WINDOW_DRAPE_FLAT_OR_COLLIDING_PLEATS",1,true),
    "WINDOW_DRAPE_FLAT_SEAMS_NOT_REJECTED")
print("WINDOW_CUE_ADVERSARIAL_REJECTED flat_folds")
local oldFace=clockGUI.Face
clockGUI.Face=Enum.NormalId.Left
ok,err=pcall(check)
clockGUI.Face=oldFace
assert(not ok and string.find(tostring(err),
    "PHOTO_WINDOW_CLOCK_DIAL_FACING_AWAY",1,true),
    "PHOTO_WINDOW_CLOCK_REVERSED_GUI_NOT_REJECTED")
print("WINDOW_CUE_ADVERSARIAL_REJECTED reversed_analog_dial")
check()
print("WINDOW_CUE_NEGATIVE_TESTS_PASS collision location lettering clock rim numerals face drape_fold aperture")
'''
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    source=generate_luau()+"\n"+PROBE+"\n"
    with tempfile.TemporaryDirectory(prefix="emma-window-landmarks-") as d:
        script=Path(d)/"probe.lua"
        script.write_text(source,encoding="utf-8")
        r=subprocess.run([args.luau,str(script)],capture_output=True,
                         text=True,timeout=115,check=False)
    if r.returncode:
        raise RuntimeError("Window landmark audit failed:\n"+
            r.stderr[-3300:]+"\n"+r.stdout[-1800:])
    required=("WINDOW_CUE_RUNTIME_PASS",
              "WINDOW_CUE_ADVERSARIAL_REJECTED collidable_ac",
              "WINDOW_CUE_ADVERSARIAL_REJECTED wrong_window",
              "WINDOW_CUE_ADVERSARIAL_REJECTED front_wall_clock",
              "WINDOW_CUE_ADVERSARIAL_REJECTED old_gray_clock_rim",
              "WINDOW_CUE_ADVERSARIAL_REJECTED wrong_analog_numeral",
              "WINDOW_CUE_ADVERSARIAL_REJECTED reversed_analog_dial",
              "WINDOW_CUE_ADVERSARIAL_REJECTED flat_curtaindrape",
              "WINDOW_CUE_ADVERSARIAL_REJECTED blocked_window_aperture",
              "WINDOW_CUE_ADVERSARIAL_REJECTED flat_folds",
              "WINDOW_CUE_NEGATIVE_TESTS_PASS")
    for marker in required:
        assert any(row.startswith(marker) for row in r.stdout.splitlines()),marker
    for row in r.stdout.splitlines():
        if row.startswith(("WINDOW_CUE_RUNTIME_PASS",
                           "WINDOW_CUE_ADVERSARIAL_REJECTED",
                           "WINDOW_CUE_NEGATIVE_TESTS_PASS")):
            print(row,flush=True)
if __name__=="__main__":
    main()
