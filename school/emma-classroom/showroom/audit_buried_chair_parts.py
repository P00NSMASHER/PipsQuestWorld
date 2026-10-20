#!/usr/bin/env python3
"""Verify reclaimed mobile geometry contains no buried chair or desk feet.

The previous seventeen molded chairs each spawned
four 0.19-stud rubber-foot cylinders at y=.13, entirely below the existing
hardwood floor top y=.50. The sixteen student desks also retained two invisible
T-foot Parts each at y=.18, entirely below the same floor, even though their
visible steel runners already rest on the finished surface. A 27x3-stud cubby
shelf ended at y=.39, also entirely below the finished floor. Removing those
objects recovers 101 replicated physical Parts without removing visible
furniture, moving a desk or chair, changing the metal-leg collision contract,
or activating meshes. The audit executes the actual constructed showroom Luau
plus adversarial mutations. It is not a Roblox physics/FPS or iPhone visual
acceptance test.
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
    local comfyBases=find("Purple comfy chair base collision")
    local purpleFeet=find("Purple corner chair rubber foot")
    local deskTops=find("Student desk top")
    local deskLegs=find("Desk tubular leg")
    local deskRunners=find("Desk contoured base runner")
    local buriedDeskFeet=find("Desk foot")
    local cubbyShelves=find("Cubbie open shelf")
    assert(#seats==16,"CHAIR_VISIBLE_SEAT_COUNT_CHANGED")
    assert(#legs==64,"CHAIR_COLLIDABLE_METAL_LEG_COUNT_CHANGED")
    assert(#hiddenFeet==0,"CHAIR_BURIED_RUBBER_FEET_RECREATED")
    assert(#comfyBases==1
        and comfyBases[1].CanCollide
        and not comfyBases[1].CanTouch
        and not comfyBases[1].CanQuery,
        "PURPLE_COMFY_COLLISION_BASE_CHANGED")
    assert(#purpleFeet==0,"PURPLE_BURIED_RUBBER_FEET_RECREATED")
    assert(#cubbyShelves==2,"CUBBIE_VISIBLE_SHELF_COUNT_CHANGED")
    for _,p in ipairs(cubbyShelves) do
        assert(p.Position.Y-p.Size.Y/2>floorTop,
            "CUBBIE_BURIED_SHELF_RECREATED")
    end
    assert(#deskTops==16,"DESK_VISIBLE_TOP_COUNT_CHANGED")
    assert(#deskLegs==32,"DESK_COLLIDABLE_METAL_LEG_COUNT_CHANGED")
    assert(#deskRunners==32,"DESK_VISIBLE_RUNNER_COUNT_CHANGED")
    assert(#buriedDeskFeet==0,"DESK_BURIED_T_FEET_RECREATED")
    for _,p in ipairs(deskLegs) do
        assert(p.Material==Enum.Material.Metal
            and p.CanCollide and p.CanQuery and not p.CanTouch,
            "DESK_METAL_LEG_COLLISION_CHANGED")
        local m=p.CFrame.m
        local lowest=p.Position.Y-p.Size.X/2*math.abs(m[4])
        assert(lowest<=floorTop+.02,
            "DESK_METAL_LEG_FLOATS_ABOVE_FLOOR")
    end
    for _,p in ipairs(deskRunners) do
        assert(p.Material==Enum.Material.Metal and not p.CanCollide
            and not p.CanQuery and not p.CanTouch
            and math.abs((p.Position.Y-p.Size.Y/2)-floorTop)<.02,
            "DESK_VISIBLE_RUNNER_SURFACE_OR_QUERY_CHANGED")
    end
    for _,p in ipairs(legs) do
        assert(p.Material==Enum.Material.Metal
            and p.CanCollide and p.CanQuery and not p.CanTouch
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
    return total,seats,legs,deskTops,deskLegs,deskRunners
end

local total,seats,legs,deskTops,deskLegs,deskRunners=verify()
print("CHAIR_BURIED_GEOMETRY_SOURCE_PASS student_chairs=16 comfy_chairs=1 student_seats=16 "
    .."metal_legs=64 buried_chair_feet_removed=68 "
    .."desks=16 desk_legs=32 visible_desk_runners=32 "
    .."buried_desk_feet_removed=32 buried_cubby_shelves_removed=1 "
    .."hidden_foot_parts=0 part_count="..total
    .." headroom_to_3100="..(3100-total)
    .." student_leg_collision_preserved=true comfy_base_collision=true native_iphone_pending=true")

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

recreated.Name="Desk foot"
reject(function() recreated.Parent=root end,
       function() recreated.Parent=nil end,
       "DESK_BURIED_T_FEET_RECREATED","desk_buried_t_foot_restored")

recreated.Name="Cubbie open shelf"
recreated.Size=Vector3.new(27,.22,3)
recreated.CFrame=CFrame.new(21,.28,25.2)
reject(function() recreated.Parent=root end,
       function() recreated.Parent=nil end,
       "CUBBIE_VISIBLE_SHELF_COUNT_CHANGED","buried_cubby_shelf_restored")

local oldDeskRunnerName=deskRunners[1].Name
reject(function() deskRunners[1].Name="Test removed desk runner" end,
       function() deskRunners[1].Name=oldDeskRunnerName end,
       "DESK_VISIBLE_RUNNER_COUNT_CHANGED","visible_desk_runner_removed")

local oldDeskCollision=deskLegs[1].CanCollide
reject(function() deskLegs[1].CanCollide=false end,
       function() deskLegs[1].CanCollide=oldDeskCollision end,
       "DESK_METAL_LEG_COLLISION_CHANGED","desk_leg_collision_removed")

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

local oldCanTouch=legs[1].CanTouch
reject(function() legs[1].CanTouch=true end,
       function() legs[1].CanTouch=oldCanTouch end,
       "CHAIR_METAL_LEG_SHAPE_OR_COLLISION_CHANGED",
       "chair_leg_unused_touch_restored")

local oldSeatName=seats[1].Name
reject(function() seats[1].Name="Test removed seat" end,
       function() seats[1].Name=oldSeatName end,
       "CHAIR_VISIBLE_SEAT_COUNT_CHANGED","student_seat_removed")

verify()
print("CHAIR_BURIED_GEOMETRY_ADVERSARIAL_PASS "
    .."student_foot,purple_foot,leg_height,leg_collision,leg_touch,seat_count_rejected=true")
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
               for line in lines)==10, "Missing adverse furniture-mutation detection"
    for line in lines:
        if line.startswith("CHAIR_BURIED_GEOMETRY_"):
            print(line,flush=True)


if __name__=="__main__":
    main()
