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
    local result={}
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") and p.Name==name then table.insert(result,p) end
    end
    return result
end
local function one(name)
    local p=parts(name)
    assert(#p==1,"CROSS_HALL_EXPECTED_ONE "..name.." got "..#p)
    return p[1]
end
local function near(a,b,tol) return math.abs(a-b)<(tol or .06) end
local function check()
    local hall=root:FindFirstChild("PhotographedHallway")
    assert(hall and hall:GetAttribute("Route")
        =="Left/right cross-corridor at ABVM STAFF threshold",
        "CROSS_HALL_OWNER_ROUTE_NOT_APPLIED")
    local floor=one("Photo hall polished square stone floor")
    local roof=one("Photo hall ivory ceiling")
    local bridge=one("Side hall floor")
    local bridgeRoof=one("Side hall ceiling")
    local nearSouth=one("Cross hall staff-side south wall")
    local nearNorth=one("Photo hall front outer wall")
    local farWall=one("Photo hall rear blue-gray wall")
    local closet=one("Supply closet solid rear wall")
    local caps=parts("Photo hall end cap")
    assert(near(floor.Position.X,48.5) and near(floor.Position.Z,15.5)
        and near(roof.Position.X,48.5)
        and floor.Size.X>=107.9 and near(floor.Size.Z,22.5)
        and floor.CanCollide and not roof.CanCollide,
        "CROSS_HALL_LONG_AXIS_NOT_PERPENDICULAR")
    -- The source floor is yawed 90: its long axis must be world Z.
    local m=floor.CFrame.m
    assert(m and math.abs(m[1])<.001 and math.abs(m[3])>.999
        and math.abs(m[5]-1)<.001,
        "CROSS_HALL_FLOOR_ROTATION_INCORRECT")
    assert(bridge.CanCollide and not bridgeRoof.CanCollide
        and bridge.Position.X-bridge.Size.X/2<=36.99
        and bridge.Position.X+bridge.Size.X/2>=37.26
        and bridgeRoof.Position.X-bridgeRoof.Size.X/2<=36.99
        and bridgeRoof.Position.X+bridgeRoof.Size.X/2>=37.26
        and bridgeRoof.Position.Z-bridgeRoof.Size.Z/2<=8.0
        and bridgeRoof.Position.Z+bridgeRoof.Size.Z/2>=23.0
        and bridge.Position.Z-bridge.Size.Z/2<=8.0
        and bridge.Position.Z+bridge.Size.Z/2>=23.0
        and roof.Position.Y-roof.Size.Y/2<13.05
        and bridgeRoof.Position.Y-bridgeRoof.Size.Y/2>=12.95
        and math.abs((bridgeRoof.Position.Y-bridgeRoof.Size.Y/2)
            -(roof.Position.Y-roof.Size.Y/2))<.08,
        "CROSS_HALL_UNSUPPORTED_OR_UNROOFED_THRESHOLD")
    local top=bridge.Position.Y+bridge.Size.Y/2
    assert(near(top,.48,.03) and near(floor.Position.Y+floor.Size.Y/2,.5,.03)
        and math.abs(top-(floor.Position.Y+floor.Size.Y/2))<.06,
        "CROSS_HALL_AVATAR_STEP_TOO_HIGH")
    -- Exactly two near-wall segments with an opening along z=8..23:
    -- old eastbound staff partition and the south cap must be gone.
    assert(near(nearSouth.Position.X,37.45)
        and near(nearSouth.Position.Z,-15.25)
        and near(nearSouth.Size.Z,46.5)
        and near(nearNorth.Position.X,37.45)
        and near(nearNorth.Position.Z,46.25)
        and near(nearNorth.Size.X,46.5)
        and near(farWall.Position.X,59.75) and farWall.CanCollide
        and nearSouth.CanCollide and nearNorth.CanCollide
        and #caps==2 and caps[1].CanCollide and caps[2].CanCollide
        and #parts("Side hall far wall")==0
        and #parts("Side corridor end wall")==0,
        "CROSS_HALL_OUTER_WALL_OR_ENTRY_NOT_SEALED")
    -- No collider or opaque barrier at the child-height center
    -- between doorway x=38 and opposite wall x=59.
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") and p.Size.Y>=3.0
            and p.Position.Y>2 and p.Position.Y<10
            and p.Position.X>38.25 and p.Position.X<58.5
            and math.abs(p.Position.Z-15.5)<1.0
            and p.Size.Z>=10 and p.Size.X<2 then
            error("CROSS_HALL_OPAQUE_DOORWAY_PARTITION "..p.Name)
        end
    end
    assert(closet.CanCollide and near(closet.Position.Z,36.05)
        and closet.Size.X>12 and closet.Size.Y>=12.9,
        "RIGHT_CLOSET_REAR_WALL_LEAKS_TO_HALL")
    local count=0
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") then count+=1 end
    end
    assert(count<=3050,"CROSS_HALL_MOBILE_3050_PART_BUDGET")
    return count,bridge,bridgeRoof,closet,nearSouth,farWall,floor
end
local count,bridge,roof,closet,south,far,floor=check()
print("LEFT_HALL_JUNCTION_SOURCE_PASS cross_hall_axis=Z "
    .."door_opens_left_right=true floor_supported=true roof_closed=true "
    .."right_double_doors_sealed=true parts="..count.." native_phone_pending=true")
local function reject(change,restore,expected,label)
    change()
    local ok,err=pcall(check)
    restore()
    assert(not ok and string.find(tostring(err),expected,1,true),
        "LEFT_HALL_JUNCTION_MUTATION_FALSE_ACCEPT "..label.." "..tostring(err))
    print("LEFT_HALL_JUNCTION_NEGATIVE_REJECTED "..label)
end
local oldBridge=bridge.Size
reject(function() bridge.Size=Vector3.new(.2,.48,15.8) end,
       function() bridge.Size=oldBridge end,
       "CROSS_HALL_UNSUPPORTED_OR_UNROOFED_THRESHOLD","floor_seam")
local oldRoof=roof.Size
reject(function() roof.Size=Vector3.new(.2,.36,15.8) end,
       function() roof.Size=oldRoof end,
       "CROSS_HALL_UNSUPPORTED_OR_UNROOFED_THRESHOLD","ceiling_seam")
local oldFloorPos=bridge.CFrame
reject(function() bridge.CFrame=CFrame.new(37.65,-.55,15.5) end,
       function() bridge.CFrame=oldFloorPos end,
       "CROSS_HALL_AVATAR_STEP_TOO_HIGH","floor_drop")
reject(function() closet.CanCollide=false end,
       function() closet.CanCollide=true end,
       "RIGHT_CLOSET_REAR_WALL_LEAKS_TO_HALL","closet_rear_wall")
reject(function() south.CanCollide=false end,
       function() south.CanCollide=true end,
       "CROSS_HALL_OUTER_WALL_OR_ENTRY_NOT_SEALED","south_outer_wall")
reject(function() far.CanCollide=false end,
       function() far.CanCollide=true end,
       "CROSS_HALL_OUTER_WALL_OR_ENTRY_NOT_SEALED","opposite_outer_wall")
check()
print("LEFT_HALL_JUNCTION_ADVERSARIAL_PASS "
    .."floor,roof,step,closet,south_wall,opposite_wall_rejected=true")
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
               for line in lines)==6
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
