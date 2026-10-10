#!/usr/bin/env python3
"""Constructed-Luau proof of the photo-guided back-wall carpentry and classroom landmarks.

Uses actual showroom constructors, not source grep. The source photographs
show identifiable children and never enter the public repository or this test.
Static geometry safety is not native Roblox/iPhone visual acceptance.
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
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") and p.Name==name then
            table.insert(found,p)
        end
    end
    return found
end
local function one(name)
    local hits=parts(name)
    assert(#hits==1,"PHOTO_WOOD_COUNT_INVALID "..name.." "..#hits)
    return hits[1]
end
local function signText(target)
    local gui=target:FindFirstChildOfClass("SurfaceGui")
    assert(gui and gui.Face==Enum.NormalId.Front,
        "PHOTO_WOOD_STRIP_FACE_INVALID")
    local label=gui:FindFirstChildOfClass("TextLabel")
    assert(label,"PHOTO_WOOD_STRIP_TEXT_MISSING")
    return label.Text
end
local function verify()
    local shelf=one("Reading shelf back")
    local cubbies=one("Cubbies wood surround")
    local inset=one("Library built-in display backing")
    local left=one("Library counting strip backing")
    local right=one("Photo-guided cabinet counting strip")
    assert(math.abs(shelf.Position.X+22)<.03
        and math.abs(cubbies.Position.X-21)<.03
        and math.abs(shelf.Position.Z-cubbies.Position.Z)<2.5,
        "PHOTO_WOOD_BUILTINS_NOT_ON_SAME_BACK_WALL")
    assert(math.abs(inset.Position.X+22)<.03
        and math.abs(inset.Position.Y-10.05)<.03
        and math.abs(inset.Position.Z-26.10)<.03
        and inset.Size.X>18 and inset.Size.Y>=4.2,
        "PHOTO_WOOD_INSET_GEOMETRY_INVALID")
    assert(inset.Position.Y-inset.Size.Y/2>6.7,
        "PHOTO_WOOD_INSET_COVERS_EXISTING_READING_BOOKS")
    assert(#parts("Library built-in dark inset frame stile")==2
        and #parts("Library built-in dark inset frame rail")==2
        and #parts("Library built-in anonymous paper")==3
        and #parts("Library built-in paper heading")==3,
        "PHOTO_WOOD_INSET_COMPONENTS_MISSING")
    assert(math.abs(left.Position.X+22)<.03
        and math.abs(right.Position.X-20.2)<.03
        and math.abs(left.Position.Y-right.Position.Y)<.03,
        "PHOTO_WOOD_TWO_STRIPS_MISALIGNED")
    assert(signText(left)=="0  10  20  30  40  50  60"
        and signText(right)=="70  80  90  100  110  120",
        "PHOTO_WOOD_COUNTING_SEQUENCE_INVALID")
    assert(left.Position.X+left.Size.X/2 < -9.4
        and right.Position.X-right.Size.X/2 > 7.0,
        "PHOTO_WOOD_COUNTING_STRIP_HIDES_DOOR_OPENING")
    assert(#parts("Photo-guided wall shape card")==9,
        "PHOTO_WOOD_SHAPES_MISSING")
    for _,p in ipairs(parts("Photo-guided wall shape card")) do
        assert(p.Position.X+p.Size.X/2 < -9.0 and p.Position.X-p.Size.X/2>-37,
            "PHOTO_WOOD_SHAPES_OVER_REAR_DOORWAY")
    end
    local decorative={
        "Library built-in display backing",
        "Library built-in dark inset frame stile",
        "Library built-in dark inset frame rail",
        "Library built-in anonymous paper",
        "Library built-in paper heading",
        "Library counting strip backing",
        "Library counting strip top rail",
        "Library counting strip bottom rail",
    }
    for _,name in ipairs(decorative) do
        for _,p in ipairs(parts(name)) do
            assert(p.Anchored and not p.CanCollide and not p.CanTouch,
                "PHOTO_WOOD_NEW_DETAIL_COLLIDES "..name)
        end
    end
    assert(#parts("Student desk top")==16
        and #parts("Student chair seat")==16
        and #parts("Purple corner chair seat")==1
        and #parts("Window glass")==2
        and #parts("Alphabet rug")==1
        and #parts("Front teaching rug")==1,
        "PHOTO_WOOD_ORIGINAL_LAYOUT_REGRESSION")
    return inset,left
end
local inset,left=verify()
print("PHOTO_WOOD_LANDMARK_RUNTIME_PASS builtins=2 inset=1 "
    .."paper=3 distinct_number_ranges=true cards=9 "
    .."doorway_clear=true original_desks=16")
local saved=inset.CanCollide
inset.CanCollide=true
local ok,err=pcall(verify)
inset.CanCollide=saved
assert(not ok and string.find(tostring(err),"PHOTO_WOOD_NEW_DETAIL_COLLIDES",1,true),
    "PHOTO_WOOD_COLLISION_NEGATIVE_NOT_REJECTED")
print("PHOTO_WOOD_ADVERSARIAL_REJECTED display_collider")
local before=left.CFrame
left.CFrame=CFrame.new(-6,14.55,26.24)
ok,err=pcall(verify)
left.CFrame=before
assert(not ok and string.find(tostring(err),"PHOTO_WOOD_TWO_STRIPS_MISALIGNED",1,true),
    "PHOTO_WOOD_WRONG_LOCATION_NOT_REJECTED")
print("PHOTO_WOOD_ADVERSARIAL_REJECTED counting_strip_moved")
local label=left:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
local textBefore=label.Text
label.Text="0  20  10"
ok,err=pcall(verify)
label.Text=textBefore
assert(not ok and string.find(tostring(err),"PHOTO_WOOD_COUNTING_SEQUENCE_INVALID",1,true),
    "PHOTO_WOOD_WRONG_NUMBER_ORDER_NOT_REJECTED")
verify()
print("PHOTO_WOOD_LANDMARK_NEGATIVE_TESTS_PASS collider location number_order")
'''
def main() -> None:
    p=argparse.ArgumentParser()
    p.add_argument("--luau",required=True)
    args=p.parse_args()
    with tempfile.TemporaryDirectory(prefix="emma-wood-") as tmp:
        script=Path(tmp)/"photo_landmarks.lua"
        script.write_text(generate_luau()+"\n"+PROBE+"\n",encoding="utf-8")
        r=subprocess.run([args.luau,str(script)],capture_output=True,
            text=True,timeout=115,check=False)
    if r.returncode:
        raise RuntimeError("Constructed photo landmarks failed:\n"
            +r.stderr[-3300:]+"\n"+r.stdout[-1900:])
    markers=("PHOTO_WOOD_LANDMARK_RUNTIME_PASS",
        "PHOTO_WOOD_ADVERSARIAL_REJECTED display_collider",
        "PHOTO_WOOD_ADVERSARIAL_REJECTED counting_strip_moved",
        "PHOTO_WOOD_LANDMARK_NEGATIVE_TESTS_PASS")
    for marker in markers:
        assert any(line.startswith(marker) for line in r.stdout.splitlines()),marker
    for line in r.stdout.splitlines():
        if line.startswith(("PHOTO_WOOD_LANDMARK_RUNTIME_PASS",
            "PHOTO_WOOD_ADVERSARIAL_REJECTED",
            "PHOTO_WOOD_LANDMARK_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)
if __name__=="__main__":
    main()
