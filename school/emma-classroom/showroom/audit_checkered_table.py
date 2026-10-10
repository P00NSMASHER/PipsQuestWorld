#!/usr/bin/env python3
"""Constructed Luau audit of the original gingham word-wall teaching table.

Photographs show this equipment during a cheer event, not a measured normal
daily furniture layout. This verifies source geometry and original Frame-based
checkered pattern, NOT native Roblox display or owner visual acceptance.
"""
from __future__ import annotations
import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
local function parts(name)
    local found={}
    for _,obj in ipairs(Room.Root:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name==name then
            table.insert(found,obj)
        end
    end
    return found
end
local function only(name)
    local found=parts(name)
    assert(#found==1,"GINGHAM_PART_COUNT_INVALID "..name)
    return found[1]
end
local function pattern(p,face,columns,rows)
    local gui=p:FindFirstChild("PhotoGingham")
    assert(gui and gui:IsA("SurfaceGui")
        and gui.Face==face and
        gui.SizingMode==Enum.SurfaceGuiSizingMode.FixedSize,
        "GINGHAM_NATIVE_GUI_MISSING "..p.Name)
    local bg=gui:FindFirstChild("GinghamIvory")
    assert(bg and bg:IsA("Frame")
        and bg.BackgroundColor3.R>.93,
        "GINGHAM_IVORY_BACKING_INVALID")
    local count=0
    for _,child in ipairs(bg:GetChildren()) do
        if child.Name=="GinghamRed" and child:IsA("Frame") then
            count+=1
            local c=child.BackgroundColor3
            assert(c.R>.63 and c.R<.75 and c.G<.29 and c.B<.30,
                "GINGHAM_CHECK_COLOR_INVALID")
        end
    end
    assert(count==columns*rows/2,
        "GINGHAM_PATTERN_TILE_COUNT_INVALID "..p.Name)
end
local function verify()
    local top=only("Photo gingham word wall table top")
    local wall=only("Class notice board")
    assert(math.abs(top.Position.X-33.2)<.03
        and math.abs(top.Position.Y-2.92)<.03
        and math.abs(top.Position.Z-1.0)<.03
        and math.abs(top.Size.X-4.2)<.03
        and math.abs(top.Size.Z-7.6)<.03,
        "GINGHAM_TABLE_GEOMETRY_INVALID")
    assert(top.Position.X+top.Size.X/2<36.0
        and math.abs(top.Position.Z-wall.Position.Z)<.03
        and math.abs(top.Position.X-wall.Position.X)<3.4,
        "GINGHAM_TABLE_NOT_BELOW_WORD_WALL")
    assert(top.CanCollide and top.Anchored
        and #parts("Photo gingham table steel leg")==4,
        "GINGHAM_TABLE_SUPPORT_INVALID")
    for _,leg in ipairs(parts("Photo gingham table steel leg")) do
        assert(leg.CanCollide and leg.Anchored
            and leg.Position.Y-leg.Size.Y/2>.50
            and leg.Position.Y+leg.Size.Y/2<=top.Position.Y,
            "GINGHAM_TABLE_LEG_COLLISION_INVALID")
    end
    pattern(top,Enum.NormalId.Top,6,10)
    for _,spec in ipairs({
        {"Photo gingham table aisle apron",Enum.NormalId.Left,10,3},
        {"Photo gingham table wall apron",Enum.NormalId.Right,10,3},
        {"Photo gingham table near apron",Enum.NormalId.Front,6,3},
        {"Photo gingham table far apron",Enum.NormalId.Back,6,3},
    }) do
        local apron=only(spec[1])
        assert(apron.Anchored and not apron.CanCollide and
            not apron.CanTouch and not apron.CanQuery,
            "GINGHAM_APRON_COLLISION_INVALID")
        pattern(apron,spec[2],spec[3],spec[4])
    end
    for _,desk in ipairs(parts("Student desk edge")) do
        local dx=math.abs(desk.Position.X-top.Position.X)
        local dz=math.abs(desk.Position.Z-top.Position.Z)
        assert(dx>(desk.Size.X+top.Size.X)/2+1.0 or
            dz>(desk.Size.Z+top.Size.Z)/2+1.0,
            "GINGHAM_TABLE_INTERSECTS_DESK")
    end
    assert(#parts("Student desk top")==16
        and #parts("Student chair seat")==16
        and #parts("Purple corner chair seat")==1
        and #parts("Window glass")==2,
        "GINGHAM_CLASSROOM_REGRESSION")
    return top
end
local top=verify()
print("GINGHAM_TABLE_RUNTIME_PASS top=1 steel_legs=4 "
    .."fabric_aprons=4 checkered_gui=5 desktop_clear=true "
    .."source_only=true native_iphone_pending=true")
local old=top.CanCollide
top.CanCollide=false
local ok,err=pcall(verify)
top.CanCollide=old
assert(not ok and string.find(tostring(err),
    "GINGHAM_TABLE_SUPPORT_INVALID",1,true),
    "GINGHAM_MISSING_TABLE_COLLISION_NOT_REJECTED")
print("GINGHAM_TABLE_ADVERSARIAL_REJECTED missing_table_collider")
local apron=only("Photo gingham table aisle apron")
local oldFace=apron:FindFirstChild("PhotoGingham").Face
apron:FindFirstChild("PhotoGingham").Face=Enum.NormalId.Top
ok,err=pcall(verify)
apron:FindFirstChild("PhotoGingham").Face=oldFace
assert(not ok and string.find(tostring(err),
    "GINGHAM_NATIVE_GUI_MISSING",1,true),
    "GINGHAM_MISSING_APRON_FACE_NOT_REJECTED")
print("GINGHAM_TABLE_ADVERSARIAL_REJECTED wrong_facing_apron")
verify()
print("GINGHAM_TABLE_NEGATIVE_TESTS_PASS collider apron_face")
'''
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="emma-gingham-") as tmp:
        path=Path(tmp)/"check.lua"
        path.write_text(generate_luau()+"\n"+PROBE+"\n",encoding="utf-8")
        r=subprocess.run([args.luau,str(path)],capture_output=True,
                         text=True,timeout=115,check=False)
    if r.returncode:
        raise RuntimeError("Constructed gingham audit failed:\n"
            +r.stderr[-2600:]+"\n"+r.stdout[-1200:])
    markers=("GINGHAM_TABLE_RUNTIME_PASS",
        "GINGHAM_TABLE_ADVERSARIAL_REJECTED missing_table_collider",
        "GINGHAM_TABLE_ADVERSARIAL_REJECTED wrong_facing_apron",
        "GINGHAM_TABLE_NEGATIVE_TESTS_PASS")
    for marker in markers:
        assert any(line.startswith(marker) for line in r.stdout.splitlines()),marker
    for line in r.stdout.splitlines():
        if line.startswith(("GINGHAM_TABLE_RUNTIME_PASS",
                            "GINGHAM_TABLE_ADVERSARIAL_REJECTED",
                            "GINGHAM_TABLE_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)
if __name__=="__main__":
    main()
