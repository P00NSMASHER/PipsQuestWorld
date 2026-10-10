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
local function pieces(name)
    local out={}
    for _,obj in ipairs(Room.Root:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name==name then
            table.insert(out,obj)
        end
    end
    return out
end
local function expect(name,n)
    local p=pieces(name)
    assert(#p==n,"PHOTO_HALL_PART_COUNT "..name.." got="..#p.." want="..n)
    return p
end
local function one(name) return expect(name,1)[1] end
local function near(x,y) return math.abs(x-y)<.055 end
local function gui(part,name,face)
    local child=part:FindFirstChild(name)
    assert(child and child:IsA("SurfaceGui")
        and child.Face==face,"PHOTO_HALL_SURFACE_GUI "..name)
    return child
end
local hall=Room.Root:FindFirstChild("PhotographedHallway")
assert(hall and hall:GetAttribute("ScaleConfidence")=="provisional",
    "PHOTO_HALL_SURVEY_FIDELITY_MISLABELED")
local floor=one("Photo hall polished square stone floor")
assert(floor.CanCollide and floor.Material==Enum.Material.SmoothPlastic
    and near(floor.Size.X,108) and near(floor.Size.Z,22.5),
    "PHOTO_HALL_FLOOR_GEOMETRY")
local grid=gui(floor,"Photo square-stone tile grout",Enum.NormalId.Top)
local long=0
local cross=0
for _,line in ipairs(grid:GetChildren()) do
    if line.Name=="Stone long tile joint" then long+=1 end
    if line.Name=="Stone cross tile joint" then cross+=1 end
end
assert(long==25 and cross==6,"PHOTO_HALL_MISSING_STONE_GRID")
assert(#pieces("Photo hall stone tile joint")==0,
    "PHOTO_HALL_TILE_JOINTS_REGRESSED_TO_PHYSICAL_PARTS")
assert(near(one("Classroom doorway brass threshold").Position.Y,.556))
local rear=one("Photo hall rear blue-gray wall")
assert(rear.CanCollide and near(rear.Position.Z,49.25)
    and rear.Size.X>=108,"PHOTO_HALL_SKY_GAP")
local caps=expect("Photo hall end cap",2)
for _,wall in ipairs(caps) do
    assert(wall.CanCollide and math.abs(wall.Position.X)>=53.9,
        "PHOTO_HALL_END_SKY_GAP")
end
expect("Side corridor end wall",2)
assert(#pieces("Rear corridor end wall")==0 and
       #pieces("Hall left wall")==0,
       "OLD_DEAD_END_HALLWAY_RETURNED")
expect("Open classroom door",2)
expect("Photo hall classroom exterior blue-gray paint",2)
expect("Photo hall adjacent oak door",2)
local picturedDoors=expect("Photo hall adjacent oak door",2)
for _,door in ipairs(picturedDoors) do
    assert(not door.CanCollide and door.Material==Enum.Material.Wood,
        "PHOTO_HALL_DECORATIVE_DOOR_BLOCKS")
    local pictured=gui(door,"Frosted glass and oak door trim",
        Enum.NormalId.Back)
    assert(pictured:FindFirstChild("School door frosted glazing")
        and pictured:FindFirstChild("School door oak center rail")
        and pictured:FindFirstChild("School door brass push plate"),
        "PHOTO_HALL_OAK_DOOR_DETAILS_MISSING")
end
local glass=expect("Door glass",2)
for _,panel in ipairs(glass) do
    local faces=0
    for _,g in ipairs(panel:GetChildren()) do
        if g.Name=="Photo green shamrock on glass" then
            assert(g:IsA("SurfaceGui"),"PHOTO_HALL_GLASS_SHAMROCK_NOT_GUI")
            local petals=0
            for _,d in ipairs(g:GetChildren()) do
                if d.Name=="Shamrock leaf" then petals+=1 end
            end
            assert(petals==4 and g:FindFirstChild("Shamrock stem"),
                "PHOTO_HALL_GREEN_SHAMROCK_INCOMPLETE")
            faces+=1
        end
    end
    assert(faces==2,"PHOTO_HALL_SHAMROCK_MUST_FACE_BOTH_SIDES")
end
local segments={
    {"Photo hall rear glazed brick",1},
    {"Photo hall classroom exterior glazed brick",2},
    {"Photo hall front outer glazed brick",2},
    {"Photo hall left end glazed brick",1},
    {"Photo hall right end glazed brick",1},
}
local count=0
for _,s in ipairs(segments) do
    for _,wall in ipairs(expect(s[1],s[2])) do
        assert(not wall.CanCollide and wall.Material==Enum.Material.SmoothPlastic,
            "PHOTO_HALL_BRICK_BECAME_PHYSICAL_COLLIDER")
        local g=wall:FindFirstChild("Photo glazed offset brick bond")
        assert(g and g:IsA("SurfaceGui"),
            "PHOTO_HALL_BRICK_GUI_MISSING")
        local field=g:FindFirstChild("Warm mortar field")
        assert(field and field.ClipsDescendants,
            "PHOTO_HALL_MORTAR_MISSING")
        local tiles=0
        for _,c in ipairs(field:GetChildren()) do
            if c.Name=="Photo glazed brick" then tiles+=1 end
        end
        assert(tiles>=18,"PHOTO_HALL_BRICK_PATTERN_INCOMPLETE")
        count+=tiles
    end
end
assert(count>=300,"PHOTO_HALL_BRICK_DETAIL_TOO_SPARSE "..count)
expect("Photo hall rear dado cap",1)
expect("Photo hall front dado cap",2)
expect("Photo hall student work hanging rail",1)
local paperUI=gui(rear,"Anonymous rotated schoolwork",Enum.NormalId.Front)
local paper=0
for _,p in ipairs(paperUI:GetChildren()) do
    if p.Name=="Photo hall anonymous diamond paper" then
        assert(p.Rotation==45 and #p:GetChildren()==3,
            "PHOTO_HALL_PAPER_NOT_ANONYMOUS_DIAMOND")
        paper+=1
    end
end
assert(paper==23,"PHOTO_HALL_ORIGINAL_DIAMOND_SHEETS_LOST")
assert(#pieces("Photo hall anonymous diamond student display")==0,
    "PHOTO_HALL_PAPERS_MUST_NOT_WASTE_PHYSICAL_PARTS")
one("Photo hall vertical welcome plaque")
local ceiling=one("Photo hall ivory ceiling")
assert(not ceiling.CanCollide and ceiling.Size.X>=108,
    "PHOTO_HALL_CEILING_NOT_ENCLOSED")
for _,lamp in ipairs(expect("Photo hall fluorescent diffuser",5)) do
    assert(not lamp.CanCollide and lamp.Material==Enum.Material.Glass
        and near(lamp.Position.Y,12.85)
        and lamp:FindFirstChildOfClass("SurfaceLight"),
        "PHOTO_HALL_ILLUMINATION_REGRESSION")
    gui(lamp,"Inset silver fluorescent rim",Enum.NormalId.Bottom)
end
local endGui=nil
for _,cap in ipairs(caps) do
    local g=cap:FindFirstChild("Photo hallway yellow end-window motif")
    if g then endGui=g;break end
end
assert(endGui and endGui.Face==Enum.NormalId.Right,
    "PHOTO_HALL_YELLOW_GLASS_END_MISSING")
local sash=endGui:FindFirstChild("Mustard window frame")
assert(sash and sash:FindFirstChild("Photo hall abstract sunrise"),
    "PHOTO_HALL_YELLOW_SUNBURST_LOST")
local rays=0
for _,c in ipairs(sash:GetChildren()) do
    if c.Name=="Photo hall drawn sun ray" then rays+=1 end
end
assert(rays==8,"PHOTO_HALL_SUN_RAYS_MISSING")
local notices=0
for _,cap in ipairs(caps) do
    if cap:FindFirstChild("Original school noticeboard") then notices+=1 end
end
assert(notices==1,"PHOTO_HALL_FAR_ANNOUNCEMENT_LOST")
print("HALLWAY_SOURCE_PROBE_PASS rear_corridor=108_studs "
    .."tile_grid=25x6 bond_tiles="..count
    .." paper_diamonds=23 frosted_oak_doors=2 "
    .."in_game_children_identifiable=none native_iPhone_review_pending=true")
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
