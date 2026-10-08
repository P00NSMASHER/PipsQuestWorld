#!/usr/bin/env python3
"""Snapshot the REAL showroom Luau-created physical parts, without Studio.

Uses the existing tested Luau math/Instance doubles only to construct the
actual showroom scripts. This is not the Roblox engine or its renderer.
Snapshot contains physical parts and their true source geometry/colours.
Dynamic SurfaceGui text/assets/shadows and engine runtime remain unverified.
"""
from __future__ import annotations

import argparse
import math
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]  # repository/school
SCHOOL = ROOT / "school"
SHOWROOM = SCHOOL / "emma-classroom" / "showroom"
TEMPLATE = SCHOOL / "emma-classroom" / "tests" / "geometry_behavior.py"

def generate_luau() -> str:
    tests = TEMPLATE.read_text(encoding="utf-8")
    assert "harness=r'''" in tests and "local assets=Instance.new" in tests, "geometry test fixture changed"
    fixture = tests.split("harness=r'''", 1)[1].split("'''", 1)[0]
    fixture = fixture.split("local assets=Instance.new", 1)[0]
    # Load the actual same Luau modules as the classroom-only Rojo project.
    art = (SHOWROOM / "ArtPass.lua").read_text(encoding="utf-8")
    room = (SHOWROOM / "Room.lua").read_text(encoding="utf-8")
    gallery = (SHOWROOM / "GalleryPass.lua").read_text(encoding="utf-8")
    script = fixture + "\n" + """
local function loadArtPass()
""" + art + """
end
local ArtPass=loadArtPass()
local script={Parent={WaitForChild=function(_,name)
    assert(name=="ArtPass","Only real showroom art is permitted")
    return ArtPass
end}}
local nativeRequire=require
local require=function(module)
    if module==ArtPass then return ArtPass end
    return nativeRequire(module)
end
local function loadRoom()
""" + room + """
end
local Room=loadRoom()
local function loadGallery()
""" + gallery + """
end
local GalleryPass=loadGallery()
Room.build()
GalleryPass.decorate(Room.Root)

local total=0
for _,part in ipairs(Room.Root:GetDescendants()) do
    if part:IsA("BasePart") then
        total+=1
        local cf=part.CFrame
        local m=cf.m
        local c=part.Color or Color3.fromRGB(160,160,160)
        local size=part.Size
        local p=cf.Position
        local safeName=string.gsub(tostring(part.Name),"[|\\r\\n]"," ")
        local fields={
            "PART",safeName,tostring(part.ClassName),
            tostring(part.Shape or "Block"),tostring(part.Material or "SmoothPlastic"),
            string.format("%.6f",part.Transparency or 0),
            string.format("%.6f",size.X),string.format("%.6f",size.Y),string.format("%.6f",size.Z),
            string.format("%.6f",p.X),string.format("%.6f",p.Y),string.format("%.6f",p.Z),
            string.format("%.6f",c.R),string.format("%.6f",c.G),string.format("%.6f",c.B),
        }
        for i=1,9 do fields[#fields+1]=string.format("%.6f",m[i]) end
        print(table.concat(fields,"|"))
    end
end
print("SCENE_COUNT|"..total)
"""
    return script

def item_props(parent: ET.Element, name: str, v: str, tag: str = "string"):
    ET.SubElement(parent, tag, {"name": name}).text = v

def write_part(parent: ET.Element, entry: list[str], idx: int):
    (_, name, cls, shape, material, alpha, sx, sy, sz, x, y, z,
     red, green, blue, *matrix) = entry
    assert cls in {"Part", "Seat", "SpawnLocation", "MeshPart"}
    # Mesh assets cannot be loaded by independent renderers without an
    # authorized asset resolver. Use source-visible Part shape fallback.
    node = ET.SubElement(parent, "Item", {"class": "Part", "referent": "RBX"+str(idx)})
    props = ET.SubElement(node, "Properties")
    item_props(props, "Name", name)
    item_props(props, "Anchored", "true", "bool")
    item_props(props, "CanCollide", "false", "bool")
    item_props(props, "Transparency", alpha, "float")
    col = ET.SubElement(props, "Color3", {"name": "Color"})
    for key, val in zip("RGB", (red, green, blue)):
        ET.SubElement(col, key).text = val
    size = ET.SubElement(props, "Vector3", {"name": "Size"})
    for key, val in zip("XYZ", (sx, sy, sz)):
        ET.SubElement(size, key).text = val
    transform = ET.SubElement(props, "CoordinateFrame", {"name": "CFrame"})
    for key, val in zip("XYZ", (x, y, z)):
        ET.SubElement(transform, key).text = val
    for key, val in zip(
        ["R00","R01","R02","R10","R11","R12","R20","R21","R22"], matrix
    ):
        ET.SubElement(transform, key).text = val
    # Roblox's PartType enum uses Ball=0, Block=1, Cylinder=2.
    kind = shape.rsplit(".", 1)[-1]
    item_props(props, "shape", str({"Ball": 0, "Block": 1, "Cylinder": 2}.get(kind, 1)), "token")
    if material:
        mapping = {
            "Plastic":256,"SmoothPlastic":272,"Neon":288,"Wood":512,
            "WoodPlanks":528,"Slate":800,"Concrete":816,"Brick":848,
            "Metal":1088,"Grass":1280,"Sand":1296,"Fabric":1312,
            "Glass":1568
        }
        item_props(props,"Material",str(mapping.get(material.rsplit(".",1)[-1],272)),"token")
    return name

CUTAWAY_OCCLUDERS={
    "Acoustic ceiling","Ceiling grid line","Ceiling grid cross",
    "Front wall","Back wall left","Back wall right","Door header wall",
    "Right wall front","Right wall back","Right door header wall",
    "Left wall below windows","Left wall above windows","Left window wall pier",
    "Outdoor sky backdrop","Outdoor hill backdrop",
    "Hall ceiling","Hall left wall","Hall right wall",
    "Hall left brick","Hall right brick",
    "Side hall ceiling","Side hall far wall","Side hall far brick",
    "Distant brick house","Distant brick roof","Neighbor brick building",
}

def export_scene(luau: str, output: Path, cutaway: bool=False):
    script=generate_luau()
    with tempfile.TemporaryDirectory(prefix="abvm-geometry-") as folder:
        path=Path(folder)/"scene.lua"
        path.write_text(script,encoding="utf-8")
        proc=subprocess.run([luau,str(path)],capture_output=True,text=True,timeout=100)
    if proc.returncode:
        raise RuntimeError("Actual Luau showroom construction failed:\n"+proc.stderr[-6000:]+"\n"+proc.stdout[-2000:])
    lines=[line.split("|") for line in proc.stdout.splitlines() if line.startswith("PART|")]
    counts=[line for line in proc.stdout.splitlines() if line.startswith("SCENE_COUNT|")]
    assert counts and int(counts[-1].split("|")[1]) == len(lines), "Incomplete Luau snapshot"
    assert len(lines) >= 800, "This is not the full actual classroom (only "+str(len(lines))+" parts)"
    assert all(len(row) == 24 for row in lines), "Malformed or incomplete physical transform"
    if cutaway:
        # Only the independent CAMERA MODEL omits these massive occluders.
        # The playable Roblox game still contains its real solid walls/roof.
        lines=[entry for entry in lines if entry[1] not in CUTAWAY_OCCLUDERS]
    names=[v[1] for v in lines]
    from collections import Counter
    by_name=Counter(names)
    geometry_contract={
        "Student desk top":16,
        "Student chair contoured back collision":16,
        "Student chair school back shell":16,
        "Student chair school back shell center":16,
        "Student chair school back shell rounded corner":64,
        "Student chair underseat frame runner":32,
        "Desk laminated front bevel":16,
        "Desk shelf front restraint":16,
        "Desk back steel stretcher":16,
    }
    for component,expected in geometry_contract.items():
        assert by_name[component]==expected, (
            f"Physical furniture regression: {component}={by_name[component]}, expected {expected}"
        )
    # The teaching-wall correction must be proven against ACTUAL Luau-built
    # physical instances, not only a matching source-text snippet.
    def only(name):
        matches=[row for row in lines if row[1]==name]
        assert len(matches)==1, f"Expected one {name} physical part; got {len(matches)}"
        return matches[0]
    smart=only("Interactive smartboard")
    bezel=only("Smartboard dark bezel")
    chalk=only("Main chalkboard")
    frame_x=float(bezel[9]); frame_width=float(bezel[6])
    smart_x=float(smart[9]); smart_width=float(smart[6])
    chalk_x=float(chalk[9]); chalk_width=float(chalk[6])
    spacing=(smart_x-smart_width/2)-(chalk_x+chalk_width/2)
    assert 18.5 <= smart_width <= 19.2, "The giant pre-redesign Smartboard returned"
    assert abs(smart_x-5.2)<.02, "Smartboard displaced from framed wall design"
    assert abs(frame_x-smart_x)<.02 and .3<frame_width-smart_width<.7, (
        "Physical display and its bezel must stay center-aligned"
    )
    assert .7 < spacing < 2.5, f"Chalkboard/Smartboard gap not plausible: {spacing:.3f}"
    assert abs(float(smart[10])-float(chalk[10])) < 1, "Display heights diverged"
    trim=[row for row in lines if row[1]=="Smartboard satin aluminum trim"]
    assert len(trim)==2 and all(abs(float(row[9])-smart_x)<.02
                                and abs(float(row[6])-19.45)<.05
                                for row in trim), "Decorative trim no longer follows board geometry"
    print(f"TEACHING_WALL_GEOMETRY_PASS smartboard={smart_width:.2f} "
          f"chalkboard={chalk_width:.2f} gap={spacing:.2f} "
          f"frame={frame_width:.2f}")
    # Avoid converting one cheap school chair into hundreds of parts.
    assert len(lines)<=3100, f"Excessive mobile classroom geometry: {len(lines)}"
    for required in ("Student desk top", "Interactive smartboard", "ClassroomReplicaSpawn", "Front teaching rug"):
        assert required in names, "Missing room object "+required
    # Use an RBXMX scene with exactly the constructed physical parts.
    root=ET.Element("roblox",{"version":"4"})
    ET.SubElement(root,"External").text="null"
    ET.SubElement(root,"External").text="nil"
    model=ET.SubElement(root,"Item",{"class":"Model","referent":"RBX0"})
    p=ET.SubElement(model,"Properties")
    item_props(p,"Name","ABVM_CLASSROOM_SOURCE_SNAPSHOT")
    for idx, row in enumerate(lines,1):
        write_part(model,row,idx)
    ET.indent(root,space="  ")
    output.parent.mkdir(parents=True,exist_ok=True)
    ET.ElementTree(root).write(output,encoding="utf-8",xml_declaration=True)
    print("SNAPSHOT_OK",len(lines),"physical parts",output)

if __name__ == "__main__":
    args=argparse.ArgumentParser()
    args.add_argument("--luau",required=True)
    args.add_argument("--out",required=True,type=Path)
    args.add_argument("--cutaway",action="store_true",help="Omit walls/ceiling only from visual QA snapshot")
    opt=args.parse_args()
    export_scene(opt.luau,opt.out,cutaway=opt.cutaway)
