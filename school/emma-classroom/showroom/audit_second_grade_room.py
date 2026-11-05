#!/usr/bin/env python3
"""Audit the actual constructed second-grade classroom and across-hall route.

This is source-built geometry/privacy evidence, not native Roblox rendering,
physics, phone performance, or final visual acceptance.
"""
from __future__ import annotations

import argparse
import subprocess
import tempfile
from pathlib import Path

from export_source_scene import generate_luau


PROBE = r'''
local root=Room.Root
local room=root:FindFirstChild("SecondGradeClassroom")
assert(room and room:GetAttribute("Grade")==2,
    "SECOND_GRADE_ROOM_FOLDER_MISSING")

local function parts(name)
    local found={}
    for _,obj in ipairs(root:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name==name then
            found[#found+1]=obj
        end
    end
    return found
end
local function one(name)
    local found=parts(name)
    assert(#found==1,"SECOND_GRADE_EXPECTED_ONE "..name.." "..#found)
    return found[1]
end
local function bounds(part)
    local p,s=part.Position,part.Size
    return p.X-s.X/2,p.X+s.X/2,p.Y-s.Y/2,p.Y+s.Y/2,
        p.Z-s.Z/2,p.Z+s.Z/2
end
local function positiveVolumeOverlap(left,right)
    local lx0,lx1,ly0,ly1,lz0,lz1=bounds(left)
    local rx0,rx1,ry0,ry1,rz0,rz1=bounds(right)
    local epsilon=.001
    return math.min(lx1,rx1)-math.max(lx0,rx0)>epsilon
        and math.min(ly1,ry1)-math.max(ly0,ry0)>epsilon
        and math.min(lz1,rz1)-math.max(lz0,rz0)>epsilon
end
local function prefixed(prefix)
    local found={}
    for _,obj in ipairs(room:GetDescendants()) do
        if obj:IsA("BasePart")
            and string.sub(obj.Name,1,#prefix)==prefix then
            found[#found+1]=obj
        end
    end
    return found
end
local function append(into,from)
    for _,obj in ipairs(from) do into[#into+1]=obj end
end
local function assertNoCrossOverlap(left,right,label)
    for _,a in ipairs(left) do
        for _,b in ipairs(right) do
            if positiveVolumeOverlap(a,b) then
                error("SECOND_GRADE_UNINTENDED_OVERLAP "..label.." "
                    ..a.Name.." <> "..b.Name)
            end
        end
    end
end
local function assertNoInternalOverlap(group,label)
    for i=1,#group do
        for j=i+1,#group do
            if positiveVolumeOverlap(group[i],group[j]) then
                error("SECOND_GRADE_UNINTENDED_OVERLAP "..label.." "
                    ..group[i].Name.." <> "..group[j].Name)
            end
        end
    end
end
local function doorwayIsClear()
    for _,obj in ipairs(root:GetDescendants()) do
        if obj:IsA("BasePart") and obj.CanCollide then
            local x0,x1,y0,y1,z0,z1=bounds(obj)
            if x0<59.65 and x1>59.55 and y0<7.5 and y1>1.0
                and z0<15.65 and z1>15.35 then
                error("SECOND_GRADE_ACROSS_HALL_ENTRY_BLOCKED "..obj.Name)
            end
        end
    end
end

local function verify()
    assert(room:GetAttribute("StudentDeskCount")==20
        and room:GetAttribute("HasPolkaDotRug")==true
        and room:GetAttribute("HasDualWindowBanks")==true
        and room:GetAttribute("HasBlackboardSmartboardWall")==true
        and room:GetAttribute("HasAcrossHallWalkableEntry")==true,
        "SECOND_GRADE_ROOM_CONTRACT_ATTRIBUTES_MISSING")
    assert(#parts("Second grade dark varnished hardwood floor")==1
        and #parts("Second grade full chalkboard wall")==1
        and #parts("Second grade interactive Smartboard")==1
        and #parts("Second grade Smartboard glass display")==1
        and #parts("Second grade Smartboard pen tray")==1
        and #parts("Second grade Smartboard lower brace")==1
        and #parts("Second grade alphabet strip carrier")==1
        and #parts("Second grade black multicolor polka-dot rug")==1,
        "SECOND_GRADE_DEFINING_LANDMARK_MISSING")
    local smartboard=one("Second grade interactive Smartboard")
    local smartDisplay=one("Second grade Smartboard glass display")
    assert(smartboard.Color.R>.80 and smartboard.Color.G>.80
        and smartboard.Size.Y>=6.4 and smartboard.Size.Z>=11.7
        and smartDisplay.Color.B>.75 and smartDisplay.Size.Y<smartboard.Size.Y
        and smartDisplay.Size.Z<smartboard.Size.Z,
        "SECOND_GRADE_SMARTBOARD_VISUAL_REGRESSION")
    assert(#parts("Second grade cursive alphabet banner")==0
        and #parts("Second grade amazing things lettering carrier")==0
        and #parts("Second grade seasonal classroom banner")==0,
        "SECOND_GRADE_TEACHING_WALL_CLUTTER_RETURNED")
    assert(#parts("Second grade window glass")==2
        and #parts("Second grade cream vertical blind")==12
        and #parts("Second grade window radiator body")==2
        and #parts("Second grade window radiator fin")==16,
        "SECOND_GRADE_WINDOW_WALL_INCOMPLETE")
    assert(#parts("Second grade desk 01 laminate top")==1
        and #parts("Second grade desk 20 laminate top")==1
        and #parts("Second grade desk 01 burgundy chair seat")==1
        and #parts("Second grade desk 20 burgundy chair seat")==1,
        "SECOND_GRADE_TWENTY_STATIONS_INCOMPLETE")
    local indexed=0
    for _,child in ipairs(room:GetChildren()) do
        if child:GetAttribute("StudentSeatIndex") then indexed+=1 end
    end
    assert(indexed==20,"SECOND_GRADE_DESK_FOLDER_COUNT_CHANGED")

    local wallSegments=parts("Second grade hall-facing entry wall")
    local brickSegments=parts("Second grade hall-facing glazed brick")
    assert(#wallSegments==2 and #brickSegments==2
        and #parts("Second grade hall-facing door header wall")==1
        and #parts("Second grade hall-facing upper wall closure")==1
        and #parts("Second grade hall-facing upper glazed brick")==1
        and #parts("Second grade entry oak jamb")==2
        and #parts("Second grade entry oak lintel")==1
        and #parts("Second grade entry brass threshold")==1,
        "SECOND_GRADE_TRUE_ENTRY_FRAME_INCOMPLETE")
    assert(#parts("Staff entry outer east wall")==0
        and #parts("Staff entry east wall glazed brick")==0,
        "SECOND_GRADE_ENTRY_STILL_BEHIND_SOLID_OLD_WALL")
    doorwayIsClear()
    local upperClosure=one("Second grade hall-facing upper wall closure")
    assert(upperClosure.CanCollide and upperClosure.Position.Y==15.5
        and upperClosure.Size.Y>=5 and upperClosure.Size.Z>=23,
        "SECOND_GRADE_ENTRY_UPPER_WALL_GAP_RETURNED")

    local floor=one("Second grade dark varnished hardwood floor")
    assert(floor.CanCollide and floor.Material==Enum.Material.Wood
        and math.abs(floor.Position.X-94.1)<.03
        and math.abs(floor.Position.Z-15.5)<.03
        and floor.Size.X>=68.9 and floor.Size.Z>=67.9,
        "SECOND_GRADE_FLOOR_SCALE_OR_FINISH_CHANGED")
    local rug=one("Second grade black multicolor polka-dot rug")
    assert(not rug.CanCollide and rug.Material==Enum.Material.Fabric
        and rug:FindFirstChild("SecondGradePolkaDotRugArt"),
        "SECOND_GRADE_POLKA_RUG_ART_OR_SAFETY_MISSING")

    local radiators=parts("Second grade window radiator body")
    append(radiators,parts("Second grade window radiator fin"))
    local bookcases=prefixed("Second grade window bookcase")
    assertNoCrossOverlap(radiators,bookcases,"radiator_bookcase")
    assertNoInternalOverlap(bookcases,"bookcase_internal")
    assertNoCrossOverlap({rug},radiators,"rug_radiator")
    assertNoCrossOverlap({rug},bookcases,"rug_bookcase")

    local entryDecor=prefixed("Second grade west wall anchor chart")
    assertNoInternalOverlap(entryDecor,"entry_decor_internal")
    local entryParts=prefixed("Second grade entry oak")
    append(entryParts,prefixed("Second grade open classroom door"))
    append(entryParts,parts("Second grade reading wave banner"))
    assertNoCrossOverlap(entryDecor,entryParts,"entry_chart")

    local worksheets=parts("Second grade window clipped worksheet")
    append(worksheets,parts("Second grade window worksheet clip"))
    assertNoCrossOverlap(parts("Second grade cream vertical blind"),worksheets,
        "blind_worksheet")
    for _,blind in ipairs(parts("Second grade cream vertical blind")) do
        assert(blind.Position.Z>=-17.59,
            "SECOND_GRADE_BLIND_EMBEDDED_IN_WINDOW_SASH")
    end

    local teacherChair=prefixed("Second grade teacher purple chair")
    local teacherDesk=prefixed("Second grade teacher desk")
    assertNoCrossOverlap(teacherChair,teacherDesk,"teacher_chair_desk")

    local teacherPapers=parts("Second grade teacher paper stack")
    assertNoInternalOverlap(teacherPapers,"teacher_paper_internal")
    local deskObjects=parts("Second grade teacher computer monitor")
    append(deskObjects,parts("Second grade teacher monitor stand"))
    append(deskObjects,parts("Second grade teacher planning book"))
    assertNoCrossOverlap(teacherPapers,deskObjects,"teacher_desk_clutter")
    assertNoInternalOverlap(parts("Second grade teacher colored pencil"),
        "teacher_pencil_internal")
    assertNoInternalOverlap(parts("Second grade teacher flower stem"),
        "teacher_flower_stem_internal")
    assertNoInternalOverlap(parts("Second grade teacher sunflower"),
        "teacher_sunflower_internal")

    local studentPapers=parts("Second grade coat wall student paper")
    assertNoCrossOverlap(studentPapers,
        parts("Second grade coat wall student paper heading"),"student_paper_heading")
    assertNoCrossOverlap(studentPapers,
        parts("Second grade coat wall student work carrier"),"student_paper_carrier")

    local teachingCarriers=parts("Second grade alphabet strip carrier")
    append(teachingCarriers,parts("Second grade cursive alphabet banner"))
    append(teachingCarriers,parts("Second grade amazing things lettering carrier"))
    assertNoInternalOverlap(teachingCarriers,"teaching_carriers")
    local crucifix=parts("Second grade front crucifix vertical")
    append(crucifix,parts("Second grade front crucifix horizontal"))
    assertNoCrossOverlap(teachingCarriers,crucifix,"teaching_carrier_crucifix")
    assertNoInternalOverlap(parts("Second grade activity table color mat"),
        "activity_mats")

    local northReturn=one("Second grade west wall north")
    assertNoCrossOverlap({northReturn},
        parts("Photo hall continuous east brick wall"),"duplicate_hall_wall")
    assert(northReturn.Position.Y-northReturn.Size.Y/2>=13.379,
        "SECOND_GRADE_NORTH_RETURN_DUPLICATES_HALL_WALL")
    local waveBanner=one("Second grade reading wave banner")
    assert(waveBanner.Position.X-waveBanner.Size.X/2>=60.219
        and waveBanner.Size.Y<=4.7 and waveBanner.Size.Z<=13.6,
        "SECOND_GRADE_WEST_DECOR_EMBEDDED_IN_HALL_WALL")
    local teacherMonitor=one("Second grade teacher computer monitor")
    assert(teacherMonitor.Size.Y<=2.3 and teacherMonitor.Size.Z<=3.8,
        "SECOND_GRADE_TEACHER_MONITOR_OVERSIZED")

    local roomParts=0
    local externalImages=0
    for _,obj in ipairs(room:GetDescendants()) do
        if obj:IsA("BasePart") then roomParts+=1 end
        if obj.ClassName=="Decal" or obj.ClassName=="Texture"
            or obj.ClassName=="ImageLabel" or obj.ClassName=="ImageButton" then
            externalImages+=1
        end
    end
    assert(roomParts>=620 and roomParts<=650,
        "SECOND_GRADE_MOBILE_PART_BUDGET_CHANGED "..roomParts)
    assert(externalImages==0,
        "SECOND_GRADE_PRIVATE_PHOTO_OR_EXTERNAL_IMAGE_EMBEDDED")
    return rug,roomParts
end

local rug,roomParts=verify()
print("SECOND_GRADE_ROOM_SOURCE_PASS desks=20 windows=2 radiators=2 "
    .."across_hall_entry=true private_images_embedded=false parts="..roomParts
    .." native_phone_pending=true")

local function reject(change,restore,expected,label)
    change()
    local ok,err=pcall(verify)
    restore()
    assert(not ok and string.find(tostring(err),expected,1,true),
        "SECOND_GRADE_FALSE_ACCEPT "..label.." "..tostring(err))
    print("SECOND_GRADE_NEGATIVE_REJECTED "..label)
end

local oldRugName=rug.Name
reject(function() rug.Name="Test missing rug" end,
    function() rug.Name=oldRugName end,
    "SECOND_GRADE_DEFINING_LANDMARK_MISSING","polka_rug_removed")

local smartboard=one("Second grade interactive Smartboard")
local oldSmartColor=smartboard.Color
reject(function() smartboard.Color=Color3.fromRGB(22,26,28) end,
    function() smartboard.Color=oldSmartColor end,
    "SECOND_GRADE_SMARTBOARD_VISUAL_REGRESSION","black_smartboard_placeholder")

local barrier=Instance.new("Part")
barrier.Name="Test entry barrier"
barrier.Size=Vector3.new(1,8,7)
barrier.CFrame=CFrame.new(59.6,4.5,15.5)
barrier.CanCollide=true
reject(function() barrier.Parent=room end,
    function() barrier.Parent=nil end,
    "SECOND_GRADE_ACROSS_HALL_ENTRY_BLOCKED","entry_blocked")

local decal=Instance.new("Decal")
decal.Name="Test forbidden private image"
reject(function() decal.Parent=rug end,
    function() decal.Parent=nil end,
    "SECOND_GRADE_PRIVATE_PHOTO_OR_EXTERNAL_IMAGE_EMBEDDED","external_image_added")

local bookcaseSide=parts("Second grade window bookcase side")[1]
local oldBookcaseCF=bookcaseSide.CFrame
reject(function()
        bookcaseSide.CFrame=CFrame.new(bookcaseSide.Position.X,
            bookcaseSide.Position.Y,-16.65)
    end,
    function() bookcaseSide.CFrame=oldBookcaseCF end,
    "SECOND_GRADE_UNINTENDED_OVERLAP radiator_bookcase",
    "radiator_bookcase_overlap")

local chart=parts("Second grade west wall anchor chart")[1]
local oldChartCF=chart.CFrame
reject(function() chart.CFrame=CFrame.new(60.16,10.2,15.5) end,
    function() chart.CFrame=oldChartCF end,
    "SECOND_GRADE_UNINTENDED_OVERLAP entry_chart","entry_chart_overlap")

local worksheet=parts("Second grade window clipped worksheet")[1]
local oldWorksheetCF=worksheet.CFrame
reject(function()
        worksheet.CFrame=CFrame.new(worksheet.Position.X,4.0,-17.58)
    end,
    function() worksheet.CFrame=oldWorksheetCF end,
    "SECOND_GRADE_UNINTENDED_OVERLAP blind_worksheet",
    "blind_worksheet_overlap")

local chairSeat=one("Second grade teacher purple chair seat")
local oldChairCF=chairSeat.CFrame
reject(function() chairSeat.CFrame=CFrame.new(66.5,2.05,-13.6) end,
    function() chairSeat.CFrame=oldChairCF end,
    "SECOND_GRADE_UNINTENDED_OVERLAP teacher_chair_desk",
    "teacher_chair_desk_overlap")

local oldRugCF=rug.CFrame
reject(function() rug.CFrame=CFrame.new(112.0,.70,-11.1) end,
    function() rug.CFrame=oldRugCF end,
    "SECOND_GRADE_UNINTENDED_OVERLAP rug_radiator","rug_window_overlap")

local northReturn=one("Second grade west wall north")
local oldNorthReturnSize=northReturn.Size
local oldNorthReturnCF=northReturn.CFrame
reject(function()
        northReturn.Size=Vector3.new(1,18,22.20)
        northReturn.CFrame=CFrame.new(59.6,9,38.40)
    end,
    function()
        northReturn.Size=oldNorthReturnSize
        northReturn.CFrame=oldNorthReturnCF
    end,
    "SECOND_GRADE_UNINTENDED_OVERLAP duplicate_hall_wall",
    "duplicate_hall_wall_overlap")

local waveBanner=one("Second grade reading wave banner")
local oldWaveCF=waveBanner.CFrame
reject(function() waveBanner.CFrame=CFrame.new(60.18,10.15,38.0) end,
    function() waveBanner.CFrame=oldWaveCF end,
    "SECOND_GRADE_WEST_DECOR_EMBEDDED_IN_HALL_WALL",
    "hall_wall_decor_overlap")

local oldWaveSize=waveBanner.Size
reject(function() waveBanner.Size=Vector3.new(.16,7.3,22) end,
    function() waveBanner.Size=oldWaveSize end,
    "SECOND_GRADE_WEST_DECOR_EMBEDDED_IN_HALL_WALL",
    "oversized_reading_banner")

local upperClosure=one("Second grade hall-facing upper wall closure")
local oldUpperSize=upperClosure.Size
reject(function() upperClosure.Size=Vector3.new(1,1,23.05) end,
    function() upperClosure.Size=oldUpperSize end,
    "SECOND_GRADE_ENTRY_UPPER_WALL_GAP_RETURNED","entry_upper_gap")

local teacherMonitor=one("Second grade teacher computer monitor")
local oldMonitorSize=teacherMonitor.Size
reject(function() teacherMonitor.Size=Vector3.new(.35,3.2,5.4) end,
    function() teacherMonitor.Size=oldMonitorSize end,
    "SECOND_GRADE_TEACHER_MONITOR_OVERSIZED","oversized_teacher_monitor")

local pencils=parts("Second grade teacher colored pencil")
local oldPencilCF=pencils[2].CFrame
reject(function() pencils[2].CFrame=pencils[1].CFrame end,
    function() pencils[2].CFrame=oldPencilCF end,
    "SECOND_GRADE_UNINTENDED_OVERLAP teacher_pencil_internal",
    "teacher_pencil_overlap")

local blooms=parts("Second grade teacher sunflower")
local oldBloomCF=blooms[2].CFrame
reject(function() blooms[2].CFrame=blooms[1].CFrame end,
    function() blooms[2].CFrame=oldBloomCF end,
    "SECOND_GRADE_UNINTENDED_OVERLAP teacher_sunflower_internal",
    "teacher_flower_overlap")

local studentPaper=parts("Second grade coat wall student paper")[1]
local paperHeading=parts("Second grade coat wall student paper heading")[1]
local oldHeadingCF=paperHeading.CFrame
reject(function() paperHeading.CFrame=studentPaper.CFrame end,
    function() paperHeading.CFrame=oldHeadingCF end,
    "SECOND_GRADE_UNINTENDED_OVERLAP student_paper_heading",
    "student_paper_heading_overlap")

verify()
print("SECOND_GRADE_ROOM_ADVERSARIAL_PASS "
    .."rug,doorway,external_image,overlap_mutations_rejected=true")
'''


def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    source=(Path(__file__).with_name("SecondGradeRoom.lua")
            .read_text(encoding="utf-8"))
    assert "rbxassetid://" not in source and "http://" not in source and "https://" not in source
    with tempfile.TemporaryDirectory(prefix="abvm-second-grade-") as folder:
        script=Path(folder)/"audit.luau"
        script.write_text(generate_luau()+"\n"+PROBE,encoding="utf-8")
        result=subprocess.run([args.luau,str(script)],capture_output=True,
                              text=True,timeout=120)
    if result.returncode:
        raise RuntimeError("Second-grade constructed-room audit failed:\n"
                           +result.stderr[-5000:]+"\n"+result.stdout[-2500:])
    output=result.stdout.splitlines()
    assert any(line.startswith("SECOND_GRADE_ROOM_SOURCE_PASS") for line in output)
    assert any(line.startswith("SECOND_GRADE_ROOM_ADVERSARIAL_PASS") for line in output)
    assert sum(line.startswith("SECOND_GRADE_NEGATIVE_REJECTED") for line in output)==17
    for line in output:
        if line.startswith("SECOND_GRADE_"):
            print(line,flush=True)


if __name__=="__main__":
    main()
