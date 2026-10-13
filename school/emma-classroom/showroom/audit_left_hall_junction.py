#!/usr/bin/env python3
"""Validate real Luau-built left-hallway junction and right-side closet.

October 11 owner direction: left classroom door connects to the long school
hallway; right double doors terminate inside a sealed supply closet.
Verify traversable horizontal floor and enclosed ceiling across the corner:
a connected 2D route alone did NOT detect the former 1.25-stud floor gap.

The test uses the actual classroom-only construction, not simulated
geometry declarations or native Roblox physics/FPS.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import tempfile

from export_source_scene import generate_luau

PROBE = r'''
local root=Room.Root
local function parts(name)
    local out={}
    for _,item in ipairs(root:GetDescendants()) do
        if item:IsA("BasePart") and item.Name==name then
            table.insert(out,item)
        end
    end
    return out
end
local function get(name)
    local matches=parts(name)
    assert(#matches==1,"JUNCTION_EXPECTED_ONE_PART "..name.." got "..#matches)
    return matches[1]
end
local function near(a,b,tol)
    return math.abs(a-b)<(tol or .05)
end
local function xBounds(part)
    return part.Position.X-part.Size.X/2,part.Position.X+part.Size.X/2
end
local function zBounds(part)
    return part.Position.Z-part.Size.Z/2,part.Position.Z+part.Size.Z/2
end
local function overlap(a,b)
    local la,ha=xBounds(a)
    local lb,hb=xBounds(b)
    return math.min(ha,hb)-math.max(la,lb)
end
local function check()
    local floor=get("Side hall floor")
    local mainFloor=get("Photo hall polished square stone floor")
    local roof=get("Side hall ceiling")
    local mainRoof=get("Photo hall ivory ceiling")
    local south=get("Side corridor end wall")
    local north=get("Staff entry straight north wall")
    local longNorth=get("Photo hall continuous north wall")
    local endWall=get("Photo hall end cap")
    local closet=get("Supply closet solid rear wall")
    local axisFloor=overlap(floor,mainFloor)
    local axisRoof=overlap(roof,mainRoof)
    local sMin,sMax=zBounds(floor)
    local pMin,pMax=zBounds(mainFloor)

    assert(near(floor.Position.X,45.5)
        and near(mainFloor.Position.X,108)
        and near(floor.Position.Z,15.775)
        and near(mainFloor.Position.Z,15.5)
        and near(roof.Position.X,45.5)
        and near(mainRoof.Position.X,108),
        "LEFT_HALL_JUNCTION_NOT_STRAIGHT_FROM_STAFF_EXIT")
    assert(axisFloor>.35 and axisFloor<1.05
        and near(sMin,4.25) and near(pMin,4.25)
        and sMax>=pMax and mainFloor.Size.X>=107.9
        and floor.CanCollide and mainFloor.CanCollide,
        "LEFT_HALL_JUNCTION_UNSUPPORTED_FLOOR_GAP")
    assert(axisRoof>.35 and axisRoof<1.05
        and roof.Size.Z>=23.0 and mainRoof.Size.X>=107.9
        and not roof.CanCollide and not mainRoof.CanCollide,
        "LEFT_HALL_JUNCTION_CEILING_SKY_GAP")
    local sideTop=floor.Position.Y+floor.Size.Y/2
    local mainTop=mainFloor.Position.Y+mainFloor.Size.Y/2
    assert(near(sideTop,.48,.03) and near(mainTop,.50,.03)
        and math.abs(sideTop-mainTop)<.06,
        "LEFT_HALL_JUNCTION_AVATAR_STEP_TOO_HIGH")
    assert(near(roof.Position.Y-roof.Size.Y/2,13,.05)
        and math.abs((roof.Position.Y-roof.Size.Y/2)
            -(mainRoof.Position.Y-mainRoof.Size.Y/2))<.06,
        "LEFT_HALL_JUNCTION_ROOF_HEIGHT_STEP")
    assert(south.CanCollide and near(south.Position.Z,4.25)
        and north.CanCollide and near(north.Position.Z,26.8)
        and longNorth.CanCollide and near(longNorth.Position.Z,26.75)
        and near(endWall.Position.X,162) and endWall.CanCollide,
        "LEFT_HALL_JUNCTION_EXTERIOR_WALL_GAP")
    assert(#parts("Side hall far wall")==0
        and #parts("Photo hall end cap")==1,
        "LEFT_HALL_JUNCTION_OLD_CROSS_WALL_RETURNED")
    -- A reintroduced collidable wall across the centerline at the former
    -- x=54.5 dead end must fail even if all floors and side walls remain.
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide and
            p.Position.Y>1.0 and p.Position.Y<12.0 and
            math.abs(p.Position.X-54.5)<1.2 and
            math.abs(p.Position.Z-15.5)<2 then
            error("LEFT_HALL_JUNCTION_STRAIGHT_AXIS_OBSTRUCTED "..p.Name)
        end
    end
    assert(closet.CanCollide and closet.Size.X>12
        and near(closet.Position.Z,36.05),
        "RIGHT_CLOSET_REAR_WALL_LEAKS_TO_HALL")
    local n=0
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") then n+=1 end
    end
    assert(n<=3050,"LEFT_HALL_JUNCTION_MOBILE_3050_PART_BUDGET_EXCEEDED")
    return axisFloor,axisRoof,n,floor,roof,closet,longNorth
end
local floorOverlap,roofOverlap,total,floor,roof,closet,longNorth=check()
print("LEFT_HALL_JUNCTION_SOURCE_PASS floor_overlap="
    ..string.format("%.2f",floorOverlap)
    .." roof_overlap="..string.format("%.2f",roofOverlap)
    .." parts="..total
    .." straight_staff_exit=true north_turn_removed=true "
    .." rear_double_doors_closet=true native_iphone_qa_still_required=true")
local function rejectMutation(change,restore,expected,label)
    change()
    local ok,err=pcall(check)
    restore()
    assert(not ok and string.find(tostring(err),expected,1,true),
        "LEFT_HALL_JUNCTION_MUTATION_FALSE_ACCEPT "..label.." "..tostring(err))
    print("LEFT_HALL_JUNCTION_NEGATIVE_REJECTED "..label)
end
local oldFloor=floor.Size
rejectMutation(
    function() floor.Size=Vector3.new(17.1,.48,23.05) end,
    function() floor.Size=oldFloor end,
    "LEFT_HALL_JUNCTION_UNSUPPORTED_FLOOR_GAP","eastward_floor_seam")
local oldRoof=roof.Size
rejectMutation(
    function() roof.Size=Vector3.new(17.1,.36,23.05) end,
    function() roof.Size=oldRoof end,
    "LEFT_HALL_JUNCTION_CEILING_SKY_GAP","eastward_roof_seam")
local oldCF=floor.CFrame
rejectMutation(
    function() floor.CFrame=CFrame.new(45.5,-.55,15.775) end,
    function() floor.CFrame=oldCF end,
    "LEFT_HALL_JUNCTION_AVATAR_STEP_TOO_HIGH","floor_drop")
rejectMutation(
    function() closet.CanCollide=false end,
    function() closet.CanCollide=true end,
    "RIGHT_CLOSET_REAR_WALL_LEAKS_TO_HALL","closet_rear_wall_removed")
rejectMutation(
    function() longNorth.CanCollide=false end,
    function() longNorth.CanCollide=true end,
    "LEFT_HALL_JUNCTION_EXTERIOR_WALL_GAP","long_hall_north_wall_missing")
check()
print("LEFT_HALL_JUNCTION_ADVERSARIAL_PASS "
    .."floor,ceiling,step,closet_wall,north_wall_rejected=true")
'''

def run(luau: str) -> list[str]:
    with tempfile.TemporaryDirectory(prefix="emma-hall-turn-") as folder:
        script=Path(folder)/"audit.lua"
        script.write_text(generate_luau()+"\n"+PROBE+"\n", encoding="utf-8")
        proc=subprocess.run([luau,str(script)],
                            capture_output=True,text=True,timeout=115)
    if proc.returncode:
        raise RuntimeError(
            "Left hall/right closet actual-constructor audit failed:\n"
            +proc.stderr[-4500:]+"\n"+proc.stdout[-1900:])
    lines=proc.stdout.splitlines()
    assert any(line.startswith("LEFT_HALL_JUNCTION_SOURCE_PASS") for line in lines)
    assert any(line.startswith("LEFT_HALL_JUNCTION_ADVERSARIAL_PASS") for line in lines)
    assert sum(line.startswith("LEFT_HALL_JUNCTION_NEGATIVE_REJECTED ")
               for line in lines)==5
    return [line for line in lines
            if line.startswith("LEFT_HALL_JUNCTION_")]

def main() -> None:
    ap=argparse.ArgumentParser()
    ap.add_argument("--luau",required=True)
    args=ap.parse_args()
    for line in run(args.luau):
        print(line,flush=True)

if __name__=="__main__":
    main()
