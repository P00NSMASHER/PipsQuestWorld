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
local function get(name)
    local matches={}
    for _,item in ipairs(root:GetDescendants()) do
        if item:IsA("BasePart") and item.Name==name then
            matches[#matches+1]=item
        end
    end
    assert(#matches==1,
        "JUNCTION_EXPECTED_ONE_PART "..name.." got "..#matches)
    return matches[1]
end
local function count(name)
    local n=0
    for _,item in ipairs(root:GetDescendants()) do
        if item:IsA("BasePart") and item.Name==name then n+=1 end
    end
    return n
end
local function near(a,b,tol)
    return math.abs(a-b)<(tol or .04)
end
local function boundsZ(p)
    local m=p.CFrame.m
    assert(near(m[1],1) and near(m[5],1) and near(m[9],1),
        "JUNCTION_FLOOR_OR_ROOF_ROTATED")
    return p.Position.Z-p.Size.Z/2,p.Position.Z+p.Size.Z/2
end
local function check()
    local photoFloor=get("Photo hall polished square stone floor")
    local sideFloor=get("Side hall floor")
    local photoRoof=get("Photo hall ivory ceiling")
    local sideRoof=get("Side hall ceiling")
    local southCap=get("Side corridor end wall")
    local corner=get("Left hallway outside corner return")
    local closet=get("Supply closet solid rear wall")

    local flS,flN=boundsZ(sideFloor)
    local pmS,pmN=boundsZ(photoFloor)
    local roofS,roofN=boundsZ(sideRoof)
    local prS,prN=boundsZ(photoRoof)
    local floorOverlap=math.min(flN,pmN)-math.max(flS,pmS)
    local roofOverlap=math.min(roofN,prN)-math.max(roofS,prS)
    assert(near(flS,5.5) and near(pmS,26.75)
        and floorOverlap>=.3 and floorOverlap<1.2
        and sideFloor.Size.X>=17.8
        and photoFloor.Size.X>=107.9
        and sideFloor.CanCollide and photoFloor.CanCollide,
        "LEFT_HALL_JUNCTION_UNSUPPORTED_FLOOR_GAP")
    assert(near(roofS,5.5) and near(prS,26.75)
        and roofOverlap>=.3 and roofOverlap<1.2
        and sideRoof.Size.X>=17.8
        and sideRoof.CanCollide==false
        and photoRoof.CanCollide==false,
        "LEFT_HALL_JUNCTION_CEILING_SKY_GAP")
    local sideTop=sideFloor.Position.Y+sideFloor.Size.Y/2
    local photoTop=photoFloor.Position.Y+photoFloor.Size.Y/2
    assert(near(sideTop,.48,.025) and near(photoTop,.5,.025)
        and math.abs(sideTop-photoTop)<=.06,
        "LEFT_HALL_JUNCTION_AVATAR_STEP_TOO_HIGH")
    local sideCeilingBottom=sideRoof.Position.Y-sideRoof.Size.Y/2
    local photoCeilingBottom=photoRoof.Position.Y-photoRoof.Size.Y/2
    assert(near(sideCeilingBottom,13,.045)
        and math.abs(sideCeilingBottom-photoCeilingBottom)<=.06,
        "LEFT_HALL_JUNCTION_ROOF_HEIGHT_STEP")
    assert(count("Side corridor end wall")==1
        and near(southCap.Position.Z,5.65)
        and southCap.CanCollide
        and count("Photo hall front outer wall")==1,
        "LEFT_HALL_JUNCTION_OLD_NORTH_CAP_RETURNED")
    assert(corner.CanCollide and corner.Position.X>53.6
        and corner.Position.Z>25.5
        and corner.Size.Z>=2.1,
        "LEFT_HALL_JUNCTION_EXTERIOR_CORNER_SKY_LEAK")
    assert(closet.CanCollide and closet.Position.Z>35.5
        and closet.Size.X>12 and closet.Size.Y>=12.9,
        "RIGHT_CLOSET_REAR_WALL_LEAKS_TO_HALL")
    local worldParts=0
    for _,obj in ipairs(root:GetDescendants()) do
        if obj:IsA("BasePart") then worldParts+=1 end
    end
    assert(worldParts<=3100,
        "LEFT_HALL_JUNCTION_MOBILE_3100_PART_BUDGET_EXCEEDED")
    return floorOverlap,roofOverlap,worldParts,sideFloor,sideRoof,closet,corner
end

local floorGapClosed,roofGapClosed,total,floor,roof,closet,corner=check()
print("LEFT_HALL_JUNCTION_SOURCE_PASS supported_floor_overlap="
    ..string.format("%.2f",floorGapClosed)
    .." enclosed_ceiling_overlap="..string.format("%.2f",roofGapClosed)
    .." total_parts="..total
    .." north_turn_open=true rear_double_doors_closet=true "
    .." native_iphone_qa_still_required=true")

local function rejectMutation(mutator,restore,expected,label)
    mutator()
    local ok,err=pcall(check)
    restore()
    assert(not ok and string.find(tostring(err),expected,1,true),
        "LEFT_HALL_JUNCTION_MUTATION_FALSE_ACCEPT "..label..": "..tostring(err))
    print("LEFT_HALL_JUNCTION_NEGATIVE_REJECTED "..label)
end

local originalFloorSize=floor.Size
rejectMutation(
    function() floor.Size=Vector3.new(18,.48,20) end,
    function() floor.Size=originalFloorSize end,
    "LEFT_HALL_JUNCTION_UNSUPPORTED_FLOOR_GAP",
    "former_unsupported_floor_seam")
local originalRoofSize=roof.Size
rejectMutation(
    function() roof.Size=Vector3.new(18,.36,20) end,
    function() roof.Size=originalRoofSize end,
    "LEFT_HALL_JUNCTION_CEILING_SKY_GAP",
    "former_open_ceiling_seam")
local originalFloorY=floor.CFrame
rejectMutation(
    function() floor.CFrame=CFrame.new(45.5,-.55,16.4) end,
    function() floor.CFrame=originalFloorY end,
    "LEFT_HALL_JUNCTION_AVATAR_STEP_TOO_HIGH",
    "drop_at_doorway")
rejectMutation(
    function() closet.CanCollide=false end,
    function() closet.CanCollide=true end,
    "RIGHT_CLOSET_REAR_WALL_LEAKS_TO_HALL",
    "closet_rear_wall_deleted")
rejectMutation(
    function() corner.CanCollide=false end,
    function() corner.CanCollide=true end,
    "LEFT_HALL_JUNCTION_EXTERIOR_CORNER_SKY_LEAK",
    "outside_corner_missing")
check()
print("LEFT_HALL_JUNCTION_ADVERSARIAL_PASS "
    .."floor,ceiling,step,closet_wall,exterior_corner_rejected=true")
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
