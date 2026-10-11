#!/usr/bin/env python3
"""Reject flattened Roblox Ball student-chair vent dots in constructed Luau.

The actual native Roblox Ball primitive renders at its smallest size axis,
so the historical .18 x .65 x .034 vent artwork collapses to a .034-stud
sphere. Verify the SAME 48 visible noncolliding vertical Block recesses
against the real 16 molded chair backs. This is source QA, not iPhone proof.
"""
from __future__ import annotations
import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
local function verify()
    local shells,vents,colliders={}, {}, {}
    for _,v in ipairs(Room.Root:GetDescendants()) do
        if v:IsA("BasePart") then
            if v.Name=="Student chair school back shell" then
                table.insert(shells,v)
            elseif v.Name=="Student chair ventilation inset" then
                table.insert(vents,v)
            elseif v.Name=="Student chair contoured back collision" then
                table.insert(colliders,v)
            end
        end
    end
    assert(#shells==16 and #vents==48 and #colliders==16,
        "NATIVE_CHAIR_PART_COUNT_INVALID")
    local attached={}
    for _,shell in ipairs(shells) do
        local offsets={}
        for _,vent in ipairs(vents) do
            local relative=(shell.CFrame:Inverse()*vent.CFrame).Position
            if math.abs(relative.X)<.68 and
               math.abs(relative.Y-.36)<.08 and
               math.abs(relative.Z-.154)<.06 then
                assert(vent.Shape==Enum.PartType.Block,
                    "NATIVE_CHAIR_FLATTENED_BALL_INVALID")
                assert(vent.Material==Enum.Material.SmoothPlastic,
                    "NATIVE_CHAIR_MATERIAL_INVALID")
                assert(vent.Size.X>=.17 and vent.Size.X<=.19
                    and vent.Size.Y>=.63 and vent.Size.Y<=.67
                    and vent.Size.Z>=.030 and vent.Size.Z<=.039,
                    "NATIVE_CHAIR_VENT_PROPORTIONS_INVALID")
                assert(relative.Z-vent.Size.Z/2>shell.Size.Z/2+.008,
                    "NATIVE_CHAIR_VENT_INSIDE_BACK_SURFACE")
                assert(vent.Anchored and not vent.CanCollide
                    and not vent.CanTouch and not vent.CanQuery
                    and vent.CastShadow==false,
                    "NATIVE_CHAIR_VENT_COLLISION_INVALID")
                assert((vent.Transparency or 0)<.03,
                    "NATIVE_CHAIR_VENT_INVISIBLE")
                table.insert(offsets,relative.X)
                assert(not attached[vent],"NATIVE_CHAIR_DUPLICATE_VENT")
                attached[vent]=true
            end
        end
        assert(#offsets==3,"NATIVE_CHAIR_MISSING_THREE_SLOTS")
        table.sort(offsets)
        for i,want in ipairs({-.54,0,.54}) do
            assert(math.abs(offsets[i]-want)<.012,
                "NATIVE_CHAIR_UNEVEN_VENT_SPACING")
        end
    end
    local matched=0
    for _ in pairs(attached) do matched+=1 end
    assert(matched==48,"NATIVE_CHAIR_UNATTACHED_VENT")
    for _,collider in ipairs(colliders) do
        assert(collider.CanCollide==true and collider.Transparency==1
            and collider.CanQuery==false,
            "NATIVE_CHAIR_BACK_COLLISION_REGRESSION")
    end
    return vents
end
local vents=verify()
print("NATIVE_CHAIR_VENTS_PASS chairs=16 recesses=48 "
    .."native_blocks=true elongated=true attached=true "
    .."no_new_parts=true colliders_unchanged=true")
local original=vents[1].Shape
vents[1].Shape=Enum.PartType.Ball
local ok,err=pcall(verify)
vents[1].Shape=original
assert(not ok and string.find(tostring(err),
    "NATIVE_CHAIR_FLATTENED_BALL_INVALID",1,true),
    "NATIVE_CHAIR_BALL_MUTATION_NOT_REJECTED")
print("NATIVE_CHAIR_ADVERSARIAL_REJECTED flattened_ball")
local saved=vents[1].Size
vents[1].Size=Vector3.new(.18,.034,.034)
ok,err=pcall(verify)
vents[1].Size=saved
assert(not ok and string.find(tostring(err),
    "NATIVE_CHAIR_VENT_PROPORTIONS_INVALID",1,true),
    "NATIVE_CHAIR_TINY_SLOT_NOT_REJECTED")
print("NATIVE_CHAIR_ADVERSARIAL_REJECTED tiny_vent")
local savedCollision=vents[1].CanCollide
vents[1].CanCollide=true
ok,err=pcall(verify)
vents[1].CanCollide=savedCollision
assert(not ok and string.find(tostring(err),
    "NATIVE_CHAIR_VENT_COLLISION_INVALID",1,true),
    "NATIVE_CHAIR_COLLISION_MUTATION_NOT_REJECTED")
verify()
print("NATIVE_CHAIR_NEGATIVE_TESTS_PASS ball tiny_slot collider")
'''
def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    source=generate_luau()+"\n"+PROBE+"\n"
    with tempfile.TemporaryDirectory(prefix="emma-chair-native-") as directory:
        path=Path(directory)/"chair.lua"
        path.write_text(source,encoding="utf-8")
        result=subprocess.run([args.luau,str(path)],capture_output=True,
            text=True,check=False,timeout=115)
    if result.returncode:
        raise RuntimeError("Constructed chair ventilation audit failed:\n"
            +result.stderr[-3000:]+"\n"+result.stdout[-2100:])
    required=("NATIVE_CHAIR_VENTS_PASS",
              "NATIVE_CHAIR_ADVERSARIAL_REJECTED flattened_ball",
              "NATIVE_CHAIR_ADVERSARIAL_REJECTED tiny_vent",
              "NATIVE_CHAIR_NEGATIVE_TESTS_PASS ball tiny_slot collider")
    lines=result.stdout.splitlines()
    for marker in required:
        assert any(s.startswith(marker) for s in lines),marker
    for line in lines:
        if line.startswith(("NATIVE_CHAIR_VENTS_PASS",
                            "NATIVE_CHAIR_ADVERSARIAL_REJECTED",
                            "NATIVE_CHAIR_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)
if __name__=="__main__":
    main()
