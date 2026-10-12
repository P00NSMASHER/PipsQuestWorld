#!/usr/bin/env python3
"""Verify reclaimed mobile geometry contains no buried student-chair rubber feet.

The previous sixteen student chairs and one purple corner chair each spawned
four 0.19-stud rubber-foot cylinders at y=.13, entirely below the existing
hardwood floor top y=.50. Removing them recovers 68 replicated physical Parts
without removing a visible foot,
moving a chair, affecting metal chair-leg collisions, or activating meshes.
The audit executes the actual constructed showroom Luau plus adversarial
mutations. It is not a Roblox physics/FPS or iPhone visual acceptance test.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import tempfile

from export_source_scene import generate_luau

PROBE = r'''
local root=Room.Root
local function find(name)
    local results={}
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") and p.Name==name then
            results[#results+1]=p
        end
    end
    return results
end
local floor=find("Warm oak classroom floor")
assert(#floor==1,"CHAIR_FINISHED_OAK_FLOOR_MISSING")
local floorPart=floor[1]
local floorTop=floorPart.Position.Y+floorPart.Size.Y/2
assert(math.abs(floorTop-.50)<.02 and floorPart.CanCollide,
    "CHAIR_FLOOR_HEIGHT_OR_COLLISION_CHANGED")
local function verify()
    local seats=find("Student chair seat")
    local legs=find("Student chair tubular leg")
    local hiddenFeet=find("Student chair rubber foot")
    local purpleSeats=find("Purple corner chair seat")
    local purpleLegs=find("Purple corner chair tubular leg")
    local purpleFeet=find("Purple corner chair rubber foot")
    assert(#seats==16,"CHAIR_VISIBLE_SEAT_COUNT_CHANGED")
    assert(#legs==64,"CHAIR_COLLIDABLE_METAL_LEG_COUNT_CHANGED")
    assert(#hiddenFeet==0,"CHAIR_BURIED_RUBBER_FEET_RECREATED")
    assert(#purpleSeats==1,"PURPLE_VISIBLE_CORNER_SEAT_COUNT_CHANGED")
    assert(#purpleLegs==4,"PURPLE_COLLIDABLE_METAL_LEG_COUNT_CHANGED")
    assert(#purpleFeet==0,"PURPLE_BURIED_RUBBER_FEET_RECREATED")
    local allLegs={}
    for _,p in ipairs(legs) do allLegs[#allLegs+1]=p end
    for _,p in ipairs(purpleLegs) do allLegs[#allLegs+1]=p end
    for _,p in ipairs(allLegs) do
        assert(p.Material==Enum.Material.Metal
            and p.CanCollide and p.CanTouch
            and math.abs(p.Size.X-1.43)<.02
            and math.abs(p.Size.Y-.14)<.02
            and math.abs(p.Size.Z-.14)<.02,
            "CHAIR_METAL_LEG_SHAPE_OR_COLLISION_CHANGED")
        -- The metal cylinder is oriented along its local X axis, which is
        -- rotated into world Y. Its underside still intersects the floor
        -- exactly as before the buried decorative foot removal.
        local m=p.CFrame.m
        assert(math.abs(math.abs(m[4])-1)<.03,
            "CHAIR_METAL_LEG_ORIENTATION_CHANGED")
        local lowest=p.Position.Y-p.Size.X/2*math.abs(m[4])
        local highest=p.Position.Y+p.Size.X/2*math.abs(m[4])
        assert(lowest<=floorTop+.02 and highest>=floorTop+.70,
            "CHAIR_METAL_LEG_FLOATS_ABOVE_FLOOR")
        assert(p.Position.X>floorPart.Position.X-floorPart.Size.X/2
            and p.Position.X<floorPart.Position.X+floorPart.Size.X/2
            and p.Position.Z>floorPart.Position.Z-floorPart.Size.Z/2
            and p.Position.Z<floorPart.Position.Z+floorPart.Size.Z/2,
            "CHAIR_METAL_LEG_OUTSIDE_REAL_FLOOR")
    end
    local total=0
    for _,p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") then total+=1 end
    end
    assert(total<=3050,"CHAIR_HIDDEN_PART_OPTIMIZATION_LOST_HEADROOM")
    return total,seats,legs
end

local total,seats,legs=verify()
print("CHAIR_BURIED_GEOMETRY_SOURCE_PASS chairs=17 student_seats=16 "
    .."metal_legs=68 buried_foot_parts_removed=68 "
    .."rubber_foot_parts=0 part_count="..total
    .." headroom_to_3100="..(3100-total)
    .." full_chair_collision_preserved=true native_iphone_pending=true")

local function reject(mutator,restorer,expected,label)
    mutator()
    local ok,err=pcall(verify)
    restorer()
    assert(not ok and string.find(tostring(err),expected,1,true),
        "CHAIR_HIDDEN_PART_FALSE_ACCEPT "..label.." "..tostring(err))
    print("CHAIR_BURIED_GEOMETRY_NEGATIVE_REJECTED "..label)
end

local recreated=Instance.new("Part")
recreated.Name="Student chair rubber foot"
recreated.Size=Vector3.new(.19,.20,.20)
reject(function() recreated.Parent=root end,
       function() recreated.Parent=nil end,
       "CHAIR_BURIED_RUBBER_FEET_RECREATED","old_buried_foot_restored")

recreated.Name="Purple corner chair rubber foot"
reject(function() recreated.Parent=root end,
       function() recreated.Parent=nil end,
       "PURPLE_BURIED_RUBBER_FEET_RECREATED",
       "purple_chair_buried_foot_restored")

local oldPosition=legs[1].CFrame
reject(function()
    legs[1].CFrame=CFrame.new(legs[1].Position.X,legs[1].Position.Y+1,
        legs[1].Position.Z)*CFrame.Angles(0,0,math.pi/2)
end,
       function() legs[1].CFrame=oldPosition end,
       "CHAIR_METAL_LEG_FLOATS_ABOVE_FLOOR","floating_chair_leg")

local oldCollides=legs[1].CanCollide
reject(function() legs[1].CanCollide=false end,
       function() legs[1].CanCollide=oldCollides end,
       "CHAIR_METAL_LEG_SHAPE_OR_COLLISION_CHANGED",
       "chair_leg_collision_removed")

local oldSeatName=seats[1].Name
reject(function() seats[1].Name="Test removed seat" end,
       function() seats[1].Name=oldSeatName end,
       "CHAIR_VISIBLE_SEAT_COUNT_CHANGED","student_seat_removed")

verify()
print("CHAIR_BURIED_GEOMETRY_ADVERSARIAL_PASS "
    .."student_foot,purple_foot,leg_height,leg_collision,seat_count_rejected=true")
'''


def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True,
                        help="Pinned Luau interpreter executable")
    args=parser.parse_args()
    script=generate_luau()+"\n"+PROBE+"\n"
    with tempfile.TemporaryDirectory(prefix="abvm-buried-chair-") as folder:
        path=Path(folder)/"audit.luau"
        path.write_text(script,encoding="utf-8")
        proc=subprocess.run([args.luau,str(path)],
                            capture_output=True,text=True,timeout=115)
    if proc.returncode:
        raise RuntimeError(
            "Actual constructed showroom chair geometry audit failed:\n"
            +proc.stderr[-4500:]+"\n"+proc.stdout[-2000:])
    lines=proc.stdout.splitlines()
    required=("CHAIR_BURIED_GEOMETRY_SOURCE_PASS",
              "CHAIR_BURIED_GEOMETRY_ADVERSARIAL_PASS")
    for marker in required:
        assert any(line.startswith(marker) for line in lines), marker
    assert sum(line.startswith("CHAIR_BURIED_GEOMETRY_NEGATIVE_REJECTED")
               for line in lines)==5, "Missing adverse chair-mutation detection"
    for line in lines:
        if line.startswith("CHAIR_BURIED_GEOMETRY_"):
            print(line,flush=True)


if __name__=="__main__":
    main()
