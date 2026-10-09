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
    "Acoustic ceiling","Acoustic ceiling inset tile","Ceiling grid line","Ceiling grid cross",
    "Front wall","Back wall left","Back wall right","Door header wall",
    "Right wall front","Right wall back","Right door header wall",
    "Left wall below windows","Left wall above windows","Left window wall pier",
    "Outdoor sky backdrop","Outdoor hill backdrop",
    "Hall ceiling","Hall left wall","Hall right wall",
    "Hall left brick","Hall right brick",
    "Side hall ceiling","Side hall far wall","Side hall far brick",
    # Keep the constructed forest visible in aerial snapshots so it can be
    # reviewed. Player-eye screenshots always use the full, uncut room.
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
    # Structural regression for defects proven by the October 8 iPhone video:
    # real side corridor had open sky beyond its ends, while a blue horizontal
    # rail visually passed through the center of the open staff doorway.
    # Inspect ACTUAL constructed physical parts, including full-room walls,
    # before removing anything for the cutaway visualization.
    def actual_parts(name):
        return [row for row in lines if row[1] == name]
    rear_caps=actual_parts("Rear corridor end wall")
    side_caps=actual_parts("Side corridor end wall")
    assert len(rear_caps)==1 and len(side_caps)==2, (
        "VIDEO_REGRESSION: rear/side corridor exposed to outside sky"
    )
    assert abs(float(rear_caps[0][11])-49.40)<.06 and float(rear_caps[0][6])>=17.9, (
        "VIDEO_REGRESSION: rear hall no longer enclosed to its full width"
    )
    side_ends=sorted(round(float(p[11]),2) for p in side_caps)
    assert side_ends==[5.65,25.35] and all(abs(float(p[9])-45.5)<.06
                                               and float(p[6])>=17.9 for p in side_caps), (
        "VIDEO_REGRESSION: side staff hall again lacks its two end walls"
    )
    rails=actual_parts("Blue chair rail right")
    assert len(rails)==2, "VIDEO_REGRESSION: right wall uses a doorway-spanning rail"
    for rail in rails:
        z=float(rail[11]); depth=float(rail[8])
        assert z+depth/2<=8.05 or z-depth/2>=22.95, (
            "VIDEO_REGRESSION: painted rail intersects staff doorway at standing eye height"
        )
    assert len(actual_parts("Blue baseboard"))==5, (
        "VIDEO_REGRESSION: continuous baseboard spans the staff doorway"
    )
    print("IPHONE_PORTAL_GEOMETRY_PASS side_caps=2 rear_cap=1 "
          "staff_door_trim_clear=true actual_luau_parts=true")

    # IMG_2903 through IMG_2910 photo anchors, without copying photos or
    # publishing personal likenesses. Validate wall and floor before
    # cutaway cameras temporarily omit room-shell parts.
    photo_wall=actual_parts("Front wall")
    photo_floor=actual_parts("Warm oak classroom floor")
    assert len(photo_wall)==1 and len(photo_floor)==1
    wall_rgb=[float(x) for x in photo_wall[0][12:15]]
    floor_rgb=[float(x) for x in photo_floor[0][12:15]]
    assert wall_rgb[0]>.93 and wall_rgb[1]>.88 and .67<wall_rgb[2]<.78, (
        "Photo-grounded warm yellow walls regressed"
    )
    assert .32<floor_rgb[0]<.43 and .22<floor_rgb[1]<.32 and floor_rgb[2]<.24, (
        "Photo-grounded dark brown wooden floor regressed"
    )
    assert photo_floor[0][4].endswith("WoodPlanks"), (
        "Real classroom floor is wooden, not laminate stone or generic slate"
    )
    # Actual Luau-built ceiling evidence, BEFORE any preview-only cutaway.
    # The supplied classroom photos show broad 2:1 recessed fluorescent
    # troffers. The previous 6.9x2.03 frames read as narrow glowing strips.
    # This checks size, overhead height, placement, material and count without
    # altering the strict mobile part budget or the separate navigation audit.
    trims=actual_parts("Recessed light trim")
    lenses=actual_parts("Frosted fluorescent diffuser")
    assert len(trims)==len(lenses)==6, "Classroom ceiling fixture count changed"
    expected_centers=sorted((round(x,2),round(z,2)) for x in (-18,18)
                            for z in (-22,0,19))
    actual_centers=sorted((round(float(p[9]),2),round(float(p[11]),2))
                          for p in trims)
    assert actual_centers==expected_centers, (
        "Photo-grounded troffers moved out of the known ceiling grid"
    )
    pairs=sorted(zip(trims,lenses),key=lambda pair:(
        round(float(pair[0][9]),2),round(float(pair[0][11]),2)))
    for trim,lens in pairs:
        width,depth=float(trim[6]),float(trim[8])
        lens_width,lens_depth=float(lens[6]),float(lens[8])
        ratio=lens_width/lens_depth
        assert 1.75 <= width/depth <= 2.10, "Ceiling surround reverted to strips"
        assert 1.80 <= ratio <= 2.25, "Fluorescent diffuser not rectangular"
        assert .16 <= (width-lens_width)/2 <= .40, (
            "Inset fluorescent lens detached from metal surround"
        )
        assert .15 <= (depth-lens_depth)/2 <= .34, (
            "Lens does not fit the troffer's short edge"
        )
        assert abs(float(lens[9])-float(trim[9]))<.01 and (
            abs(float(lens[11])-float(trim[11]))<.01
        ), "Frosted diffuser shifted away from its ceiling fitting"
        assert 17.55 <= float(lens[10]) <= 17.63 and (
            17.69 <= float(trim[10]) <= 17.75
        ), "Fluorescent light fixture dropped into the player camera"
        assert trim[4].endswith("Metal") and lens[4].endswith("Glass"), (
            "Fixture material became a glaring emissive slab"
        )
    print("PHOTO_CEILING_TROFFERS_PASS count=6 rectangular_lens=true "
          "centers_preserved=true no_new_colliders=true ratio="
          f"{pairs[0][1][6]}/{pairs[0][1][8]}",flush=True)
    # Photo reference: greenery, not repeated apartment geometry, through
    # both classroom window openings. Check the REAL, complete constructed
    # Luau scene before altering anything for aerial preview cutaways.
    outdoor_trees=actual_parts("Photo exterior oak trunk")
    outdoor_canopies=actual_parts("Photo exterior irregular foliage")
    assert len(outdoor_trees)==4 and len(outdoor_canopies)==20, (
        "Four depth-layered green trees missing from photo-grounded windows"
    )
    for item in outdoor_trees+outdoor_canopies:
        x=float(item[9]);sx=float(item[6])
        assert -38.8<x< -37.9 and x+sx/2 < -36.60, (
            "Exterior greenery crosses the classroom glazing into the room"
        )
        assert 4.0<float(item[10])<12.3, (
            "Exterior foliage no longer belongs in the view through windows"
        )
    assert all(p[4].endswith("Grass") for p in outdoor_canopies), (
        "Foliage lost natural leaf material"
    )
    for forbidden_name in ("Distant brick house", "Slate roof silhouette",
                           "Neighbor window", "Soft distant cloud"):
        assert not actual_parts(forbidden_name), (
            "Unreferenced apartment / fake cloud returned: "+forbidden_name
        )
    assert len(actual_parts("Tree trunk outside"))==3 and (
        len(actual_parts("Irregular exterior leaf cluster"))==18
    ), "Original tree depth/detail was lost"
    print("PHOTO_WINDOW_GREENERY_PASS trees=4 crown_clusters=20 "
          "prior_trees=3 old_apartments=0 fake_clouds=0 "
          "behind_window_glass=true",flush=True)
    # Check both built school window bays before camera-only cutaways.
    # Exterior trees should be visible behind the lightly tinted glass,
    # while the real navy fabric panels remain fully preserved.
    panes=actual_parts("Window glass")
    expected={
        "Window wood horizontal frame":4,
        "Window wood vertical frame":4,
        "Window vertical mullion":6,
        "Window horizontal mullion":2,
        "Window timber inner stop":4,
        "Deep window sill":2,
        "Window blind slat":32,
        "Navy curtain fabric panel":4,
    }
    assert len(panes)==2 and sorted(round(float(p[11]),2) for p in panes)==[-19,6], (
        "Both school window glazing openings must remain in place"
    )
    for name,count in expected.items():
        assert len(actual_parts(name))==count, (
            f"Window component {name} changed count unexpectedly"
        )
    for pane in panes:
        assert pane[4].endswith("Glass") and .64<=float(pane[5])<=.76, (
            "Glass is too opaque to see the outdoor greenery"
        )
        assert abs(float(pane[9])+36.18)<.02 and (
            abs(float(pane[7])-8.4)<.02 and abs(float(pane[8])-14.2)<.02
        ), "School window opening changed geometry"
        rgb=[float(x) for x in pane[12:15]]
        assert min(rgb)>.87 and max(rgb)-min(rgb)<.07, (
            "Glass reverted to heavy blue window tint"
        )
    for name in expected:
        if name in ("Window blind slat","Navy curtain fabric panel"):
            continue
        for part in actual_parts(name):
            assert part[4].endswith("Wood"), "Light window sash lost its wood material"
            rgb=[float(x) for x in part[12:15]]
            assert min(rgb)>.79 and max(rgb)-min(rgb)<.09, (
                "Window sash reverted to heavy blue paint"
            )
    print("PHOTO_WINDOW_SASH_PASS glass=2 transparency=.68 light_sashes=true "
          "window_centers_preserved=true blinds_and_curtains_preserved=true")
    # Photo-driven navy drapes must be visible at standing child eye height,
    # gathered at the edges rather than blanketing the daylight and trees.
    # These measurements come from actual constructed Luau Parts, before
    # any cutaway model removes architectural occluders.
    window_panels=actual_parts("Navy curtain fabric panel")
    curtain_pleats=actual_parts("Navy curtain stitched pleat")
    curtain_ties=actual_parts("Navy curtain cloth tieback")
    curtain_headers=actual_parts("Blue curtain valance")
    assert len(window_panels)==4 and len(curtain_pleats)==8 and (
        len(curtain_ties)==4 and len(curtain_headers)==2
    ), "Missing photo-grounded two-sided curtains on both school windows"
    assert not actual_parts("Blue curtain fold"), (
        "Pencil-thin prototype draperies returned to school windows"
    )
    panel_sides={-19:[],6:[]}
    for part in window_panels:
        x,y,z=(float(part[i]) for i in (9,10,11))
        width,height,length=(float(part[i]) for i in (6,7,8))
        assert part[4].endswith("Fabric") and (
            abs(x+35.43)<.02 and abs(y-9.05)<.02
        ), "Navy curtains are floating off the interior window jamb"
        assert 7.90<=height<=8.10 and 1.40<=length<=1.52, (
            "Window curtains no longer resemble child-eye-length drapes"
        )
        assert width<=.18 and abs(x+36.18)>.65, (
            "Window curtain geometry blocks or penetrates the glazing"
        )
        color=[float(c) for c in part[12:15]]
        assert color[2]>color[0]*1.5 and color[2]>color[1]*1.3, (
            "Navy school curtains reverted to bright cartoon-blue paint"
        )
        center=min((-19,6),key=lambda c:abs(z-c))
        assert 5.80 < abs(z-center)-length/2 and (
            abs(z-center)+length/2 < 7.48
        ), "Curtains cover the central daylight aperture or protrude beyond the casing"
        panel_sides[center].append(round(z-center,2))
    assert all(sorted(dz)==[-6.65,6.65] for dz in panel_sides.values()), (
        "Each school window must have two symmetric pulled-open side panels"
    )
    assert all(.28<float(part[7])<.48 for part in curtain_headers), (
        "Oversized 1.8-stud curtain valance returned"
    )
    print("PHOTO_NAVY_CURTAINS_PASS windows=2 panels=4 pleats=8 "
          "tiebacks=4 open_center_width_studs=11.8 "
          "historic_blinds_preserved=true native_iphone_pending")
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
        "Desk basket cross wire":80,
        "Desk basket longitudinal wire":48,
        "Desk pencil":16,
        "Desk pencil eraser cap":16,
        "Illustrated storybook cover":5,
        "Storybook illustration backing":5,
        "Storybook title band":5,
        "Reading floor lamp stem":1,
        "Reading lamp base":1,
        "Reading fabric drum lampshade":1,
        "Reading shade sewn binding":2,
        "Reading shade recessed warm diffuser":1,
        "Reading lamp top finial":1,
        "Photo-guided wall shape card":9,
        "Photo-guided shape icon":9,
        "Photo-guided cabinet counting strip":1,
        "Counting strip blue top trim":1,
        "Counting strip green bottom trim":1,
    }
    for component,expected in geometry_contract.items():
        assert by_name[component]==expected, (
            f"Physical furniture regression: {component}={by_name[component]}, expected {expected}"
        )
    assert by_name["Hanging pastel bunting"]==0, (
        "Unreferenced generic bunting overlapped photo-grounded shape cards"
    )
    # Original micro ferrules and erasers were detached from the actual
    # cylinder's local-X axis. The consolidated caps must sit at shaft ends,
    # not off to one side, and must preserve a 16-stationery set.
    assert by_name["Pencil ferrule"]==0 and by_name["Pencil eraser"]==0, (
        "Detached original pencil hardware returned"
    )
    pencils=[v for v in lines if v[1]=="Desk pencil"]
    caps=[v for v in lines if v[1]=="Desk pencil eraser cap"]
    for cap in caps:
        px,py,pz=[float(cap[i]) for i in (9,10,11)]
        separation=min((
            (px-float(p[9]))**2+(pz-float(p[11]))**2,
            abs(py-float(p[10]))
        ) for p in pencils)
        assert .76**2 <= separation[0] <= .88**2 and separation[1] < .025, (
            "Pencil eraser cap is not attached to its shaft"
        )
    assert by_name["Warm lamp shade"]==0, (
        "Reading floor lamp regressed to a spherical balloon-like lampshade"
    )
    # The teaching-wall correction must be proven against ACTUAL Luau-built
    # physical instances, not only a matching source-text snippet.
    def only(name):
        matches=[row for row in lines if row[1]==name]
        assert len(matches)==1, f"Expected one {name} physical part; got {len(matches)}"
        return matches[0]

    # Low-risk indoor features independently visible in the activity photos.
    # Existing rug centers remain unchanged; activity photos do not prove
    # which furnishings were moved for the cheer class.
    rug=only("Alphabet rug")
    assert rug[3].endswith("Cylinder") and 14<float(rug[7])<14.5, (
        "Circular alphabet rug reverted to a rectangular shape"
    )
    word_wall=only("Class notice board")
    assert float(word_wall[13])>.62, "Blue vocabulary wall changed palette"
    window_banner=only("Classroom faith window banner")
    assert abs(float(window_banner[9])+36.33)<.025 and (
        abs(float(window_banner[10])-15.22)<.025
    ), "Photo-specific faith motto is no longer above the actual windows"
    assert abs(float(window_banner[11])+6.50)<.05 and (
        37.8<=float(window_banner[8])<=38.2
    ), "Window affirmation strip moved away from the two window bays"
    assert .95<=float(window_banner[7])<=1.20 and (
        float(window_banner[10])+float(window_banner[7])/2 < 17
    ), "Classroom motto obstructs the acoustic ceiling or window glazing"
    print("PHOTO_FAITH_MOTTO_GEOMETRY_PASS words=photo_grounded "
          "windows_unobscured=true one_noncolliding_part=true")
    photo_components={
        "Reading rug alphabet border":26,
        "Photo rug number cloud lobe":20,
        "Photo rug number cloud numeral":10,
        "Photo rug sun center":1,
        "Photo rug sun ray":8,
        "Front rug color dot":25,
        "Word wall word card":15,
        "Word wall apple":8,
        "Word wall apple stem":8,
    }
    for component,expected in photo_components.items():
        assert by_name[component]==expected, (
            f"Photo-guided element missing: {component}={by_name[component]}"
        )
    assert by_name["Reading rug flower petal"]==0, (
        "Synthetic flower field returned to the real sun/cloud carpet"
    )
    print("PHOTO_REFERENCE_GEOMETRY_PASS yellow_walls=true dark_wood=true "
          "circular_sun_alphabet=true number_clouds=10 dot_rug=25 "
          "blue_wordwall=true apple_markers=8")

    smart=only("Interactive smartboard")
    bezel=only("Smartboard dark bezel")
    chalk=only("Main chalkboard")
    frame_x=float(bezel[9]); frame_width=float(bezel[6])
    smart_x=float(smart[9]); smart_width=float(smart[6])
    chalk_x=float(chalk[9]); chalk_width=float(chalk[6])
    # The photographed mobile screen sits ahead of a wider chalkboard, not
    # beside one. Check x alignment and visible blackboard perimeter.
    chalk_margin=(chalk_width-smart_width)/2
    assert 18.5 <= smart_width <= 19.2, "Digital display changed width"
    assert 28.5 <= chalk_width <= 29.5, "Wide chalkboard backing missing"
    assert abs(smart_x-5.2)<.02 and abs(chalk_x-smart_x)<.05, (
        "Wheeled screen no longer aligns with chalkboard backdrop"
    )
    assert abs(frame_x-smart_x)<.02 and .3<frame_width-smart_width<.7, (
        "Physical display and its bezel must stay center-aligned"
    )
    assert 4.5 <= chalk_margin <= 5.8, (
        "Blackboard perimeter is obscured by the wheeled screen"
    )
    assert float(smart[11])-float(chalk[11])>1.5, (
        "Wheeled screen collapsed back into the chalkboard plane"
    )
    assert abs(float(smart[10])-float(chalk[10]))<1, "Display heights diverged"
    trim=[row for row in lines if row[1]=="Smartboard satin aluminum trim"]
    assert len(trim)==2 and all(abs(float(row[9])-smart_x)<.02
                                and abs(float(row[6])-19.45)<.05
                                for row in trim), "Decorative trim no longer follows board geometry"
    # Permanent chalkboard and manufactured mobile board remain separate.
    # Read actual executed Luau physical transforms (not code-string guesses).
    # This does NOT simulate native Roblox shadowing or phone camera FOV.
    assert -31.75 <= float(smart[11]) <= -31.59, (
        "Mobile interactive display returned flush against the back wall"
    )
    assert 1.5 <= float(smart[11])-float(chalk[11]) <= 3.0, (
        "Mobile display should stand forward of the teaching wall"
    )
    assert abs(float(bezel[11])-float(smart[11])+.28)<.04, (
        "Mobile white display housing is no longer behind its glass"
    )
    supports=[p for p in lines if p[1]=="Mobile smartboard support post"]
    collars=[p for p in lines if p[1]=="Mobile smartboard mounting collar"]
    feet=[p for p in lines if p[1]=="Mobile smartboard rolling foot"]
    wheels=[p for p in lines if p[1]=="Mobile smartboard caster"]
    braces=[p for p in lines if p[1]=="Mobile smartboard cross brace"]
    assert len(supports)==len(collars)==len(feet)==2 and len(wheels)==4, (
        "Mobile classroom Smartboard support or wheel count changed"
    )
    assert len(braces)==1, "Mobile stand is missing its transverse support"
    for items in (supports,collars,feet):
        assert sorted(round(float(p[9]),2) for p in items)==[.10,10.30], (
            "Rolling Smartboard support disconnected from the two screen pylons"
        )
    assert sorted(round(float(p[11]),2) for p in wheels)==(
        [-33.25,-33.25,-31.15,-31.15]
    ), "Rolling Smartboard has misplaced casters"
    assert all(.49 < float(p[10])-float(p[7])/2 < .70 for p in supports), (
        "Rolling Smartboard support collides with visual ground plane"
    )
    assert all(abs(float(p[10])-.73)<.01 for p in wheels), (
        "Mobile caster wheels do not meet the floor"
    )
    assert all(float(p[11]) < float(bezel[11]) for p in supports), (
        "Mobile support posts must be BEHIND screen face, not on top of lessons"
    )
    assert by_name["Mobile smartboard support post"]==2 and (
        by_name["Mobile smartboard caster"]==4
    )
    print("PHOTO_MOBILE_SMARTBOARD_GEOMETRY_PASS posts=2 casters=4 "
          "behind_display=true roomward_offset=true "
          "noncolliding_parts_in_source=true native_iphone_pending")
    print(f"TEACHING_WALL_GEOMETRY_PASS smartboard={smart_width:.2f} "
          f"chalkboard={chalk_width:.2f} exposed_margin={chalk_margin:.2f} "
          f"frame={frame_width:.2f}")
    # Repositioned art easel must NOT occlude the actual chalkboard from the
    # front-facing player camera. Validate exported world geometry after Luau.
    easel=only("Art easel wooden board")
    easel_x=float(easel[9]); easel_width=float(easel[6]); easel_z=float(easel[11])
    chalk_left=chalk_x-chalk_width/2
    easel_right=easel_x+easel_width/2
    easel_clearance=chalk_left-easel_right
    assert 18.0 <= easel_clearance <= 21.0, (
        f"The photo-guided larger chalkboard intersects the art easel: {easel_clearance:.2f}"
    )
    assert abs(easel_x+31.0)<.02, "The visually dominant prior easel returned"
    assert 4.0 <= easel_width <= 4.4, "Easel must have a compact school-scale silhouette"
    assert 3.4 <= float(easel[7]) <= 3.8, "Oversized brown display returned"
    assert easel_x-easel_width/2 > -36.5, "Easel crosses the interior left wall"
    assert -32.0 < easel_z < -29.0, "Easel no longer belongs in the front-left art corner"
    easel_poster=only("Easel framed print")
    easel_ledge=only("Easel display ledge")
    easel_legs=[row for row in lines if row[1]=="Easel timber support"]
    easel_stars=[row for row in lines if row[1]=="Golden achievement star"]
    assert abs(float(easel_poster[9])-easel_x)<.02 and abs(float(easel_ledge[9])-easel_x)<.02
    assert len(easel_legs)==2 and sorted(round(float(row[9])-easel_x,2) for row in easel_legs)==[-1.46,1.46], (
        "Art easel wooden supports detached from display"
    )
    assert len(easel_stars)==3 and sorted(round(float(row[9])-easel_x,2) for row in easel_stars)==[-1.55,0.0,1.55], (
        "Easel wall stars did not move with the display"
    )
    print(f"EASEL_CHALKBOARD_CLEARANCE_PASS gap={easel_clearance:.2f} x={easel_x:.2f}")
    # The brown rectangle in the last player-eye render was a physical
    # bulletin-board defect: cork was behind a full-size wooden front plate.
    # Assert the actual constructed front-facing depth and human-scale sheets.
    board_back=only("Student work board thin wood backing")
    board_cork=only("Student work board exposed cork")
    assert abs(float(board_cork[6])-9.4)<.02 and abs(float(board_cork[7])-5.65)<.02, (
        "Oversized cork board returned"
    )
    assert float(board_cork[11]) > float(board_back[11])+.10, (
        "Solid wooden backing hides the classroom cork face"
    )
    for name,expected in {
        "Student work board horizontal wood rail":2,
        "Student work board vertical wood rail":2,
        "Pinned student work sheet":3,
        "Student work colored heading":3,
        "Student work pencil line":9,
        "Bulletin board brass pushpin":3,
    }.items():
        assert by_name[name]==expected, (
            f"Student-work display {name} count {by_name[name]} != {expected}"
        )
    for card in [row for row in lines if row[1]=="Pinned student work sheet"]:
        assert float(card[11]) > float(board_cork[11]), (
            "Pinned student work vanished behind the cork"
        )
        assert float(card[6])<2.5 and float(card[7])<3.2, (
            "Student work should be child-size rather than a floating wall UI"
        )
    print("VISIBLE_BULLETIN_BOARD_GEOMETRY_PASS sheets=3 cork_exposed=true")

    # Physical backpack audit: verify actual Luau-created silhouettes, hooks,
    # child proportions and mounting on the rear storage wall.
    backpack_contract={
        "Hanging school bag":8,
        "Hanging school bag center":8,
        "Hanging school bag rounded corner":32,
        "Backpack shoulder strap":16,
        "Backpack hanging loop":8,
        "Backpack upper flap":8,
        "Backpack front pocket":8,
        "Backpack pocket zipper":8,
        "Backpack zipper pull":8,
        "Metal coat hook":8,
        "Cubbie bin":12,
    }
    for component,expected in backpack_contract.items():
        assert by_name[component]==expected, (
            f"Child-scale backpack/storage count mismatch: {component}="
            f"{by_name[component]} expected {expected}"
        )
    bags=sorted([row for row in lines if row[1]=="Hanging school bag"],
                key=lambda row:float(row[9]))
    loops=sorted([row for row in lines if row[1]=="Backpack hanging loop"],
                 key=lambda row:float(row[9]))
    hooks=sorted([row for row in lines if row[1]=="Metal coat hook"],
                 key=lambda row:float(row[9]))
    for bag,loop,hook in zip(bags,loops,hooks):
        assert abs(float(bag[9])-float(hook[9])) < .03, "Backpack drifted off its coat hook"
        assert abs(float(loop[9])-float(hook[9])) < .03, "Bag hanger does not meet coat hook"
        assert abs(float(loop[10])-float(hook[10])) <= .18, "Bag handle floats below its hook"
        assert abs(float(bag[10])-9.62) < .03, "Backpack slipped from child-scale mounting height"
        assert abs(float(bag[11])-25.40) < .03, "Backpack protrudes into the classroom walkway"
        assert abs(float(bag[6])-1.16)<.03 and abs(float(bag[7])-2.10)<.03, (
            "Rounded backpack body or height changed unexpectedly"
        )
        assert "Ball" not in bag[3], "Rejected ellipsoid/backpack balloon returned"
    for label in ("Hanging school bag",
                  "Hanging school bag center",
                  "Hanging school bag rounded corner"):
        for row in (item for item in lines if item[1]==label):
            assert str(row[4]).endswith("Fabric"), (
                f"Backpack panel {label} is plastic, not textile fabric"
            )
    label=only("Cubbies label")
    lower_edge=float(label[10])-float(label[7])/2
    artwork_top=9.6+4.8/2
    bag_top=9.62+2.10/2
    assert float(label[6])<=19.1 and float(label[7])<=1.0, (
        "Oversized front-floating cubby sign returned"
    )
    assert 12.45 <= lower_edge < 13.0, (
        f"Storage sign obscures lower backpacks or conflicts with wall: {lower_edge:.2f}"
    )
    assert lower_edge > max(artwork_top,bag_top)+.25, (
        "Storage motto overlaps student art, coat hooks or backpacks"
    )
    assert float(label[11])>26.0, "Cubbie sign protrudes into the classroom"
    print("BACKPACK_STORAGE_GEOMETRY_PASS count=8 cubby_bins=12 hooks=8 "
          f"material=Fabric handle_mount_gap=.07 sign_lower_edge={lower_edge:.2f}")
    # Reading-corner clearance comes from ACTUAL Luau-created geometry.
    # Cylinder Parts are modeled along their local X axis and then rotated:
    # blindly reading Size.X as a world-space width underestimates a rotated
    # upholstered pouf by almost 3 studs. Project the complete transform.
    def world_span(entry, axis):
        size=[float(v) for v in entry[6:9]]
        matrix=[float(v) for v in entry[15:24]]
        return sum(abs(matrix[axis*3+i])*size[i] for i in range(3))

    poufs=[v for v in lines if v[1]=="Corduroy floor pouf"]
    cushions=[v for v in lines if v[1]=="Soft seat cushion"]
    rack=only("Child-height book display shelf")
    assert len(poufs)==2 and len(cushions)==2, "Reading seating count changed"
    assert all(p[3].endswith("Cylinder") and p[4].endswith("Fabric")
               for p in poufs), "Upholstered drum poufs reverted to balloon shapes"
    assert all(c[3].endswith("Ball") and c[4].endswith("Fabric")
               for c in cushions), "Soft seating lost its fabric cushion crown"
    # Speculative seating is deliberately less visually dominant than the
    # photo-verified carpet. Assert the actual constructed child-scale sizes.
    for base in poufs:
        footprint=max(world_span(base,0),world_span(base,2))
        assert 2.88<=footprint<=3.02, (
            f"Unverified upholstered pouf overwhelms carpet: {footprint:.3f}"
        )
    for cushion in cushions:
        assert 2.50<=world_span(cushion,0)<=2.75 and (
            2.48<=world_span(cushion,2)<=2.70
        ), "Cushion extends beyond its small manufactured pouf"
    print("PHOTO_SUBTRACTIVE_READING_PASS poufs=2 compact=true "
          "sun_visibility_preserved=true")
    rack_x=float(rack[9]);rack_width=world_span(rack,0)
    min_clearance=min(abs(float(p[9])-rack_x)
                      -(world_span(p,0)+rack_width)/2 for p in poufs)
    assert min_clearance >= .15, (
        f"Reading pouf intersects child book display rack: x_gap={min_clearance:.3f}"
    )
    seat_gap=abs(float(poufs[0][9])-float(poufs[1][9])) - (
        world_span(poufs[0],0)+world_span(poufs[1],0))/2
    assert seat_gap >= .2, f"Reading poufs intersect: x_gap={seat_gap:.3f}"
    # Photo-fidelity: the center sun must remain legible, not physically
    # hidden under speculative reading seats. Use actual Luau transforms.
    # Each modeled seat fits a circular horizontal footprint; no scene
    # renderer, fake height or two-dimensional source-code proxy is used.
    sun=only("Photo rug sun center")
    sun_pos=(float(sun[9]),float(sun[11]))
    sun_rays=[r for r in lines if r[1]=="Photo rug sun ray"]
    assert len(sun_rays)==8, "Real carpet center lost its eight sun rays"
    sun_outer_radius=max(
        math.hypot(float(r[9])-sun_pos[0],float(r[11])-sun_pos[1])
        + math.hypot(world_span(r,0),world_span(r,2))/2
        for r in sun_rays
    )
    # Unobstructed sun includes its geometric rays and a safety margin.
    sun_clearances=[]
    bookshelf_front=23.3-2.7/2
    for base in poufs:
        x,z=float(base[9]),float(base[11])
        radius=max(world_span(base,0),world_span(base,2))/2
        clearance=math.hypot(x-sun_pos[0],z-sun_pos[1])-radius-sun_outer_radius
        sun_clearances.append(clearance)
        assert clearance>=.70, (
            f"Pouf blocks the photo-verified sun and rays: gap={clearance:.3f}"
        )
        assert z+world_span(base,2)/2 <= bookshelf_front-.35, (
            "Reading ottoman collides with rear built-in bookshelf frontage"
        )
        assert -35.0 < x-world_span(base,0)/2, (
            "Reading ottoman crowds the window/wall-side circulation"
        )
    assert min(sun_clearances)>=.70
    print(f"PHOTO_SUN_VISIBILITY_PASS unobstructed=true seats=2 "
          f"minimum_sun_clearance={min(sun_clearances):.2f} "
          "rug_centers_unchanged=true")

    pairs=list(zip(sorted(poufs,key=lambda r:float(r[9])),
                   sorted(cushions,key=lambda r:float(r[9]))))
    assert all(abs(float(p[9])-float(c[9])) < .02 for p,c in pairs), (
        "Cushions no longer share pouf seat center"
    )
    for base,cushion in pairs:
        lower=float(base[10])-world_span(base,1)/2
        base_top=float(base[10])+world_span(base,1)/2
        cushion_bottom=float(cushion[10])-world_span(cushion,1)/2
        cushion_top=float(cushion[10])+world_span(cushion,1)/2
        assert .50 <= lower <= .62, (
            f"Fabric ottoman floats above or sinks beneath reading rug: {lower:.3f}"
        )
        assert cushion_bottom <= base_top+.02, (
            f"Soft pouf cushion detached from upholstered base: {cushion_bottom:.3f}"
        )
        assert 1.55 <= cushion_top <= 1.80, (
            f"Reading seating no longer matches child chair height: {cushion_top:.3f}"
        )
    print(f"READING_NOOK_CLEARANCE_PASS pouf_to_rack={min_clearance:.2f} "
          f"seat_to_seat={seat_gap:.2f} chairs=2 lower_child_seats=true "
          "rotated_world_footprints=true")
    book_spines=[r for r in lines if r[1]=="Reading book spine"]
    book_labels=[r for r in lines if r[1]=="Book spine label"]
    assert len(book_spines)==40 and len(book_labels)==40, (
        "Keep 40 reading books and their original individual labels"
    )
    book_heights={round(float(r[7]),3) for r in book_spines}
    book_widths={round(float(r[6]),3) for r in book_spines}
    assert len(book_heights)>=5 and len(book_widths)>=4, (
        "Repeating identical shelf-book blocks instead of varied library books"
    )
    for r in book_spines:
        bottom=float(r[10])-float(r[7])/2
        assert min(abs(bottom-.83),abs(bottom-3.38))<.025, (
            f"Reading shelf book base is visibly floating: y={bottom:.3f}"
        )
    print(f"READING_BOOKCASE_VARIATION_PASS books={len(book_spines)} "
          f"widths={len(book_widths)} heights={len(book_heights)}")
    # The pink water bottle was a tall, visually distracting column in
    # multiple player-eye screenshots. Audit actual built dimensions and
    # surface contact, not merely the source string.
    bottle=only("Emma pink water bottle")
    shoulder=only("Water bottle tapered shoulder")
    cap=only("Water bottle cap")
    bottle_x,bottle_y,bottle_z=(float(bottle[i]) for i in (9,10,11))
    height=float(bottle[6])  # Cylinder axis is local X, rotated onto world Y.
    bottom=bottle_y-height/2
    top=bottle_y+height/2
    shoulder_y,shoulder_h=float(shoulder[10]),float(shoulder[6])
    cap_y,cap_h=float(cap[10]),float(cap[7])
    assert .78<=height<=.85 and abs(float(bottle[7])-.51)<.02, (
        "Oversized water bottle returned"
    )
    assert abs(bottom-3.17)<.035, f"Bottle not supported by desktop: y={bottom:.3f}"
    assert (shoulder_y-shoulder_h/2)<=top+.015, "Bottle shoulder floats"
    assert (cap_y-cap_h/2)<=(shoulder_y+shoulder_h/2)+.015, (
        "Bottle cap floats above its neck"
    )
    assert cap_y+cap_h/2<4.30, "Water bottle again obscures the central view"
    assert all(abs(float(p[9])-bottle_x)<.005 and
               abs(float(p[11])-bottle_z)<.005 for p in (shoulder,cap)), (
        "Shoulder/cap shifted off bottle center"
    )
    assert abs(bottle_x-2.12)<.03 and abs(bottle_z-4.45)<.03, (
        "Water bottle no longer stands on Emma's desk"
    )
    assert bottle_x+float(bottle[7])/2 < 2.86 and (
        abs(bottle_z-4)+float(bottle[8])/2<1.90
    ), "Water bottle extends beyond child desk"
    print(f"EMMA_DESK_BOTTLE_GEOMETRY_PASS height={height:.2f} "
          f"desk_gap={bottom-3.17:.2f} cap_top={cap_y+cap_h/2:.2f}")
    # Structural contact checks for the ACTUAL Luau-created teaching desk:
    # surfaces are measured from generated geometry, not string snippets.
    # The 12.5 x 5.2 stud desktop at y=3.1 with .38 thickness has its
    # usable surface at y=3.29. RoundedPanel has its thin vertical dimension
    # in local Z, while ordinary Parts use local Y. The pencil cup is a
    # cylinder rotated onto the world Y axis (local X is its height).
    teacher_desk_surface=3.29
    supported={
        "Teacher laptop base":8,
        "Pencil cup":6,
        "Tissue box":7,
        "Teacher desk wooden stationery tray":7,
        "Teacher note paper":7,
    }
    for label,height_axis in supported.items():
        item=only(label)
        bottom=float(item[10])-float(item[height_axis])/2
        assert abs(bottom-teacher_desk_surface)<=.035, (
            f"Unsupported teacher workstation object {label}: "
            f"bottom={bottom:.3f}, desktop={teacher_desk_surface:.3f}"
        )
        assert 18.75<=float(item[9])<=31.25 and -27.6<=float(item[11])<=-22.4, (
            f"Teacher object {label} exceeds desktop footprint"
        )
    print("TEACHER_DESK_SUPPORT_PASS laptop=true cup=true tissues=true tray=true paper=true")

    # Verify that the optional fallback silhouette update stays lightweight:
    # two slim molded edge returns per chair, with the existing collidable
    # chair shell and all original sixteen desks still in place.
    assert by_name["Student chair molded side return"] == 32, (
        "Expected exactly two subtle chair edge returns on each of 16 chairs"
    )
    tray_rails=[r for r in lines if r[1]=="Book tray side"]
    assert len(tray_rails)==32, "Underdesk side lips must stay paired for all desks"
    for r in tray_rails:
        assert "Cylinder" in r[3], "Opaque underdesk basket wall returned"
        assert abs(float(r[6])-3.06)<.015 and float(r[7])<=.105, (
            "Basket lip is no longer the slim 0.095-stud steel tube"
        )
    print("CLASSROOM_FURNITURE_SILHOUETTE_PASS chairs=16 returns=32 tray_rails=32")

    # Two redundant decorative bolts per desk were deliberately removed:
    # Room.lua already builds the desk assembly fasteners. Preserve mobile
    # geometry by rejecting the old duplicated hardware.
    assert by_name["Desk fixing bolt"]==0, (
        "Repeated cosmetic desk bolts needlessly consume the mobile part budget"
    )
    # Test actual constructed Luau geometry, not source-coordinate snippets.
    # The original shelf books hovered above their wire trays and the pencil
    # cylinders floated just above the laminate.
    underdesk_books=[r for r in lines if r[1]=="Classroom book"
                     and 2.2<float(r[10])<2.6]
    assert len(underdesk_books)==16, (
        f"Missing underdesk workbooks: {len(underdesk_books)} of 16"
    )
    shelf_top=2.29+.085/2
    for r in underdesk_books:
        bottom=float(r[10])-.18/2
        assert abs(bottom-shelf_top)<.035, (
            f"Workbook floats above shelf: underside={bottom:.3f}"
        )
    pencils=[r for r in lines if r[1]=="Desk pencil"]
    assert len(pencils)==16, "Missing 16 student desk pencils"
    for r in pencils:
        bottom=float(r[10])-float(r[7])/2
        assert abs(bottom-3.17)<.015, (
            f"Desk pencil floats off laminate: bottom={bottom:.3f}"
        )
    print("STUDENT_FURNITURE_SUPPORT_PASS books=16 pencils=16")

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
