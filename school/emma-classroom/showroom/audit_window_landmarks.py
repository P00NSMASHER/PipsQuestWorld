#!/usr/bin/env python3
"""Verify photo-specific school window details using constructed Luau.

No uploaded photos, student data, or publishing operations are involved.
One negative test deliberately collides the AC; a second moves the S'more
banner to the wrong window, and a third deletes its classroom wording.
"""
from __future__ import annotations

import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
local function parts(name)
    local out={}
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") and p.Name==name then
            table.insert(out,p)
        end
    end
    return out
end
local function one(name)
    local v=parts(name)
    assert(#v==1,"WINDOW_CUE_COUNT_INVALID "..name)
    return v[1]
end
local function signText(p)
    local g=p:FindFirstChildOfClass("SurfaceGui")
    assert(g and g.Face==Enum.NormalId.Right,
        "WINDOW_CUE_TEXT_FACE_INVALID "..p.Name)
    local text=g:FindFirstChildOfClass("TextLabel")
    assert(text~=nil,"WINDOW_CUE_TEXT_MISSING "..p.Name)
    return text
end
local function check()
    local left=one("Smore classroom main title")
    local headline=one("Smore faith headline")
    local faith=one("Classroom faith window banner")
    assert(signText(left).Text=="S'MORE" and
        signText(headline).Text=="JESUS LOVES YOU" and
        signText(faith).Text=="I AM A CHILD OF GOD. I MAKE A DIFFERENCE!",
        "WINDOW_CUE_WORDING_INVALID")
    assert(math.abs(left.Position.Z+19)<.03 and
        math.abs(headline.Position.Z+19)<.03 and
        math.abs(faith.Position.Z-6)<.03,
        "WINDOW_CUE_BAY_POSITION_INVALID")
    assert(left.Position.Y>14.90 and headline.Position.Y>15.90
        and faith.Position.Y>14.90,
        "WINDOW_CUE_SIGN_HEIGHT_INVALID")
    assert(#parts("Smore mural pine trunk")==2 and
        #parts("Smore mural green canopy")==4,
        "WINDOW_CUE_MURAL_TREES_MISSING")
    local ac=one("Photo window air conditioner housing")
    assert(math.abs(ac.Position.Z+19)<.03
        and math.abs(ac.Position.X+35.55)<.03
        and math.abs(ac.Position.Y-5.23)<.03,
        "WINDOW_CUE_AC_LOCATION_INVALID")
    assert(ac.Size.X>1.0 and ac.Size.Y>1.20
        and ac.Size.Z>4.70 and ac.Size.Z<4.90,
        "WINDOW_CUE_AC_SCALE_INVALID")
    local sill=nil
    for _,p in ipairs(parts("Deep window sill")) do
        if math.abs(p.Position.Z+19)<.03 then sill=p end
    end
    assert(sill~=nil,"WINDOW_CUE_SILL_MISSING")
    local clearance=ac.Position.Y-ac.Size.Y/2-
        (sill.Position.Y+sill.Size.Y/2)
    assert(clearance>=0 and clearance<.06,
        "WINDOW_CUE_AC_SUPPORT_INVALID")
    assert(#parts("Photo AC horizontal vent louver")==5
        and #parts("Photo AC control dial")==2
        and #parts("Photo AC control fascia")==1,
        "WINDOW_CUE_AC_FACE_INCOMPLETE")
    local seen={"Classroom faith window banner","Smore faith headline",
        "Smore classroom main title","Smore mural pine trunk",
        "Smore mural green canopy","Photo window air conditioner housing",
        "Photo AC inset front grille","Photo AC horizontal vent louver",
        "Photo AC control fascia","Photo AC control dial"}
    for _,name in ipairs(seen) do
        for _,p in ipairs(parts(name)) do
            assert(p.Anchored and not p.CanCollide and
                not p.CanTouch and not p.CanQuery,
                "WINDOW_CUE_DECOR_COLLIDES "..name)
        end
    end
    assert(#parts("Window glass")==2 and
        #parts("Navy curtain fabric panel")==4 and
        #parts("Purple corner chair seat")==1 and
        #parts("Student desk top")==16,
        "WINDOW_CUE_ORIGINAL_ROOM_REGRESSION")
    return left,ac
end
local left,ac=check()
print("WINDOW_CUE_RUNTIME_PASS banners=2 pines=2 "
    .."photo_ac=1 louvers=5 controls=2 collision_free=true "
    .."windows=2 purple_chair=1 desk_pairs=16")
local old=ac.CanCollide
ac.CanCollide=true
local ok,err=pcall(check)
ac.CanCollide=old
assert(not ok and string.find(tostring(err),
    "WINDOW_CUE_DECOR_COLLIDES",1,true),
    "WINDOW_CUE_COLLIDING_AC_NOT_REJECTED")
print("WINDOW_CUE_ADVERSARIAL_REJECTED collidable_ac")
local before=left.CFrame
left.CFrame=CFrame.new(-36.28,15.39,6)
ok,err=pcall(check)
left.CFrame=before
assert(not ok and string.find(tostring(err),
    "WINDOW_CUE_BAY_POSITION_INVALID",1,true),
    "WINDOW_CUE_WRONG_WINDOW_NOT_REJECTED")
print("WINDOW_CUE_ADVERSARIAL_REJECTED wrong_window")
local label=signText(left)
local saved=label.Text
label.Text="WELCOME"
ok,err=pcall(check)
label.Text=saved
assert(not ok and string.find(tostring(err),
    "WINDOW_CUE_WORDING_INVALID",1,true),
    "WINDOW_CUE_WRONG_TEXT_NOT_REJECTED")
check()
print("WINDOW_CUE_NEGATIVE_TESTS_PASS collision location lettering")
'''
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    source=generate_luau()+"\n"+PROBE+"\n"
    with tempfile.TemporaryDirectory(prefix="emma-window-landmarks-") as d:
        script=Path(d)/"probe.lua"
        script.write_text(source,encoding="utf-8")
        r=subprocess.run([args.luau,str(script)],capture_output=True,
                         text=True,timeout=115,check=False)
    if r.returncode:
        raise RuntimeError("Window landmark audit failed:\n"+
            r.stderr[-3300:]+"\n"+r.stdout[-1800:])
    required=("WINDOW_CUE_RUNTIME_PASS",
              "WINDOW_CUE_ADVERSARIAL_REJECTED collidable_ac",
              "WINDOW_CUE_ADVERSARIAL_REJECTED wrong_window",
              "WINDOW_CUE_NEGATIVE_TESTS_PASS")
    for marker in required:
        assert any(row.startswith(marker) for row in r.stdout.splitlines()),marker
    for row in r.stdout.splitlines():
        if row.startswith(("WINDOW_CUE_RUNTIME_PASS",
                           "WINDOW_CUE_ADVERSARIAL_REJECTED",
                           "WINDOW_CUE_NEGATIVE_TESTS_PASS")):
            print(row,flush=True)
if __name__=="__main__":
    main()
