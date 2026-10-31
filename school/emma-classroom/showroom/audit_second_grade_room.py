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
        and #parts("Second grade alphabet strip carrier")==1
        and #parts("Second grade black multicolor polka-dot rug")==1,
        "SECOND_GRADE_DEFINING_LANDMARK_MISSING")
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
        and #parts("Second grade entry oak jamb")==2
        and #parts("Second grade entry oak lintel")==1
        and #parts("Second grade entry brass threshold")==1,
        "SECOND_GRADE_TRUE_ENTRY_FRAME_INCOMPLETE")
    assert(#parts("Staff entry outer east wall")==0
        and #parts("Staff entry east wall glazed brick")==0,
        "SECOND_GRADE_ENTRY_STILL_BEHIND_SOLID_OLD_WALL")
    doorwayIsClear()

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

    local roomParts=0
    local externalImages=0
    for _,obj in ipairs(room:GetDescendants()) do
        if obj:IsA("BasePart") then roomParts+=1 end
        if obj.ClassName=="Decal" or obj.ClassName=="Texture"
            or obj.ClassName=="ImageLabel" or obj.ClassName=="ImageButton" then
            externalImages+=1
        end
    end
    assert(roomParts>=500 and roomParts<=600,
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

verify()
print("SECOND_GRADE_ROOM_ADVERSARIAL_PASS "
    .."rug,doorway,external_image_mutations_rejected=true")
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
    assert sum(line.startswith("SECOND_GRADE_NEGATIVE_REJECTED") for line in output)==3
    for line in output:
        if line.startswith("SECOND_GRADE_"):
            print(line,flush=True)


if __name__=="__main__":
    main()
