#!/usr/bin/env python3
"""Constructed-Luau test of the October 10 ABVM hallway photo landmarks.

This executes the same shipped Room.lua constructors used for the showroom
place, not a grep-only mock. The photos themselves contain children and remain
outside the public repository. Geometry is provisional until native iPhone QA.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import subprocess
import tempfile

from export_source_scene import generate_luau

PROBE = r'''
local function all(name)
    local output={}
    for _,obj in ipairs(Room.Root:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name==name then
            table.insert(output,obj)
        end
    end
    return output
end
local function exact(name,count)
    local hits=all(name)
    assert(#hits==count,"HALLWAY_COUNT "..name.." got="..#hits.." expected="..count)
    return hits
end
local function one(name)
    return exact(name,1)[1]
end
local function close(actual,expected)
    return math.abs(actual-expected)<.055
end
local photo=Room.Root:FindFirstChild("PhotographedHallway")
assert(photo,"HALLWAY_MISSING_PHOTO_ARCHITECTURE_FOLDER")
assert(photo:GetAttribute("ScaleConfidence")=="provisional",
    "HALLWAY_FALSE_SURVEY_PRECISION")

local floor=one("Photo hall polished square stone floor")
assert(close(floor.Size.X,108) and close(floor.Size.Z,22.5)
    and floor.CanCollide and floor.Material==Enum.Material.SmoothPlastic,
    "HALLWAY_FLOOR_COLLIDER_OR_MATERIAL_WRONG")
local joints=all("Photo hall stone tile joint")
assert(#joints>=25,"HALLWAY_GRID_MISSING")
for _,p in ipairs(joints) do
    assert(p.CanCollide==false and p.CanQuery==false
        and close(p.Position.Y,.509),
        "HALLWAY_GRID_BLOCKS_PLAYER_OR_FLOATS")
end
local rear=one("Photo hall rear blue-gray wall")
assert(close(rear.Position.Z,49.25) and rear.Size.X>=108
    and rear.CanCollide,"HALLWAY_REAR_SKY_LEAK")
local endcaps=exact("Photo hall end cap",2)
for _,cap in ipairs(endcaps) do
    assert(cap.CanCollide and math.abs(cap.Position.X)>=53.9,
        "HALLWAY_END_SKY_LEAK")
end
assert(#all("Rear corridor end wall")==0 and #all("Hall left wall")==0,
    "OBSOLETE_DEAD_END_GEOMETRY_PRESENT")
assert(#all("Open classroom door")==2,
    "ORIGINAL_CLASSROOM_ENTRANCE_WAS_CHANGED")
exact("Photo hall classroom exterior blue-gray paint",2)
exact("Photo hall adjacent oak door",2)
local glazed=exact("Photo hall adjacent frosted glazing",2)
for _,p in ipairs(glazed) do
    assert(p.Material==Enum.Material.Glass and p.CanCollide==false,
        "HALLWAY_DECORATIVE_DOORS_BLOCK_EXIT")
end
exact("Photo hallway green glass shamrock",8)
exact("Photo hallway shamrock stem",2)
local brickNames={
    "Photo hall rear glazed brick",
    "Photo hall classroom exterior glazed brick",
    "Photo hall front outer glazed brick",
    "Photo hall left end glazed brick",
    "Photo hall right end glazed brick",
}
local expected={1,2,2,1,1}
local totalTiles=0
for i,name in ipairs(brickNames) do
    for _,p in ipairs(exact(name,expected[i])) do
        assert(not p.CanCollide and p.Material==Enum.Material.SmoothPlastic,
            "HALLWAY_BRICK_COLLISION_OR_MATERIAL_CHANGED")
        local gui=p:FindFirstChildOfClass("SurfaceGui")
        assert(gui,"HALLWAY_BRICK_BOND_GUI_MISSING")
        local field=gui:FindFirstChild("Warm mortar")
        assert(field and field.ClipsDescendants,
            "HALLWAY_BRICK_MORTAR_BACKING_MISSING")
        local count=0
        for _,tile in ipairs(field:GetChildren()) do
            if tile.Name=="Glazed stretcher" then count+=1 end
        end
        assert(count>=18,"HALLWAY_BRICK_BOND_HAS_TOO_FEW_COURSES")
        totalTiles+=count
    end
end
assert(totalTiles>=300,"HALLWAY_GLAZED_COURSE_PATTERN_INCOMPLETE "..totalTiles)

local papers=exact("Photo hall anonymous diamond student display",23)
for _,p in ipairs(papers) do
    assert(p.CanCollide==false and close(p.Position.Z,48.58),
        "HALLWAY_STUDENT_DISPLAY_OBSTRUCTS")
    local gui=p:FindFirstChildOfClass("SurfaceGui")
    assert(gui and #gui:GetChildren()==3,
        "HALLWAY_PRIVATE_ASSIGNMENT_REPLACED_ANONYMOUS_ART")
end
one("Photo hall student work hanging rail")
one("Photo hall vertical welcome plaque")
exact("Photo hall fluorescent trim",5)
local lights=exact("Photo hall fluorescent diffuser",5)
for _,lens in ipairs(lights) do
    assert(not lens.CanCollide and lens.Material==Enum.Material.Glass
        and close(lens.Position.Y,12.85),
        "HALLWAY_TROFFER_DETACHED_OR_BLOCKING")
    assert(lens:FindFirstChildOfClass("SurfaceLight"),
        "HALLWAY_FLUORESCENT_UNLIT")
end
local ceiling=one("Photo hall ivory ceiling")
assert(not ceiling.CanCollide and ceiling.Size.X>=108,
    "HALLWAY_CEILING_LOST")
local sun=one("Photo hall end sunrise circle")
assert(not sun.CanCollide and sun.Shape==Enum.PartType.Cylinder,
    "HALLWAY_YELLOW_END_WINDOW_ART_WRONG")
exact("Photo hall end sun ray",8)
exact("Photo hall end dark glazed transom",1)
exact("Photo hall end mustard window surround",1)
exact("Side corridor end wall",2)
print("HALLWAY_SOURCE_PROBE_PASS 108_stud_corridor=true "
    .."brick_tiles="..totalTiles
    .." diamonds=23 closed_oak_doors=2 "
    .." original_classroom_entrance=2 native_device_QA_pending=true")
'''

def run(luau: str) -> str:
    with tempfile.TemporaryDirectory(prefix="emma-hallway-photo-") as tmp:
        script=Path(tmp)/"probe.lua"
        script.write_text(generate_luau()+"\n"+PROBE, encoding="utf-8")
        result=subprocess.run(
            [luau,str(script)],text=True,capture_output=True,timeout=115
        )
    if result.returncode:
        raise RuntimeError(
            "Photo hallway actual Luau constructors failed\n"
            +result.stderr[-6000:]+"\n"+result.stdout[-2500:]
        )
    assert "HALLWAY_SOURCE_PROBE_PASS" in result.stdout, (
        "Photo-grounded hallway did not complete its true source-level audit"
    )
    return result.stdout

def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True,help="Pinned Luau binary")
    args=parser.parse_args()
    for line in run(args.luau).splitlines():
        if line.startswith("HALLWAY_SOURCE_PROBE_PASS"):
            print(line,flush=True)

if __name__=="__main__":
    main()
