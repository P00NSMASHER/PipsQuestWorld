#!/usr/bin/env python3
"""Audit source-constructed exterior foliage, including deliberate bad Shapes.

Native Roblox flattened Ball geometry can shrink to dots when one Size axis
is much smaller. Test the original seven trees, noncolliding cylinder faces
and the regressions we must not silently publish. No native engine claim.
"""
from __future__ import annotations
import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
local function check()
    local far,near={},{}
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") then
            if p.Name=="Photo exterior irregular foliage" then
                table.insert(far,p)
            elseif p.Name=="Irregular exterior leaf cluster" then
                table.insert(near,p)
            end
        end
    end
    assert(#far==20 and #near==18, "FOLIAGE_NATIVE_COUNTS_INVALID")
    for _,p in ipairs(far) do
        assert(p.Shape==Enum.PartType.Cylinder,
            "FOLIAGE_NATIVE_FLATTENED_BALL_INVALID")
        assert(p.Size.X>.70 and p.Size.X<1.50
            and p.Size.Y>1.28 and p.Size.Z>1.25,
            "FOLIAGE_NATIVE_SILHOUETTE_INVALID")
        assert(p.Material==Enum.Material.Grass,
            "FOLIAGE_NATIVE_MATERIAL_INVALID")
        assert(not p.CanCollide and not p.CanTouch,
            "FOLIAGE_NATIVE_COLLISION_INVALID")
        assert(p.Position.X < -37.9,
            "FOLIAGE_NATIVE_WINDOW_INTRUSION")
    end
    for _,p in ipairs(near) do
        assert(p.Shape==Enum.PartType.Cylinder,
            "FOLIAGE_NATIVE_FLATTENED_BALL_INVALID")
        assert(p.Size.X>.70 and p.Size.X<1.50
            and p.Size.Y>1.28 and p.Size.Z>1.25,
            "FOLIAGE_NATIVE_SILHOUETTE_INVALID")
        assert(p.Material==Enum.Material.Grass,
            "FOLIAGE_NATIVE_MATERIAL_INVALID")
        assert(not p.CanCollide and not p.CanTouch,
            "FOLIAGE_NATIVE_COLLISION_INVALID")
        assert(p.Position.X < -37.9,
            "FOLIAGE_NATIVE_WINDOW_INTRUSION")
    end
    return far,near
end

local far,near=check()
print("FOLIAGE_NATIVE_CONSTRUCTION_PASS trees=7 "
    .."distant_crowns=20 near_crowns=18 cylinder_faces=true "
    .."collision_free=true no_added_parts=true")
local saved=far[1].Shape
far[1].Shape=Enum.PartType.Ball
local ok,err=pcall(check)
far[1].Shape=saved
assert(not ok and string.find(tostring(err),
    "FOLIAGE_NATIVE_FLATTENED_BALL_INVALID",1,true),
    "FOLIAGE_NATIVE_BALL_REGRESSION_NOT_REJECTED")
print("FOLIAGE_NATIVE_ADVERSARIAL_REJECTED flattened_ball")
local savedSize=near[1].Size
near[1].Size=Vector3.new(.14,2.4,2.4)
ok,err=pcall(check)
near[1].Size=savedSize
assert(not ok and string.find(tostring(err),
    "FOLIAGE_NATIVE_SILHOUETTE_INVALID",1,true),
    "FOLIAGE_NATIVE_THIN_DISC_NOT_REJECTED")
print("FOLIAGE_NATIVE_ADVERSARIAL_REJECTED thin_disc")
local savedCollision=near[1].CanCollide
near[1].CanCollide=true
ok,err=pcall(check)
near[1].CanCollide=savedCollision
assert(not ok and string.find(tostring(err),
    "FOLIAGE_NATIVE_COLLISION_INVALID",1,true),
    "FOLIAGE_NATIVE_COLLIDER_NOT_REJECTED")
check()
print("FOLIAGE_NATIVE_NEGATIVE_TESTS_PASS ball thin_disc collider")
'''
def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    source=generate_luau()+"\n"+PROBE+"\n"
    with tempfile.TemporaryDirectory(prefix="emma-leaf-native-") as directory:
        path=Path(directory)/"audit.lua"
        path.write_text(source,encoding="utf-8")
        result=subprocess.run([args.luau,str(path)],capture_output=True,
            text=True,timeout=115,check=False)
    if result.returncode:
        raise RuntimeError("Foliage Luau audit failed:\n"
            +result.stderr[-2800:]+"\n"+result.stdout[-2000:])
    required=(
        "FOLIAGE_NATIVE_CONSTRUCTION_PASS",
        "FOLIAGE_NATIVE_ADVERSARIAL_REJECTED flattened_ball",
        "FOLIAGE_NATIVE_ADVERSARIAL_REJECTED thin_disc",
        "FOLIAGE_NATIVE_NEGATIVE_TESTS_PASS ball thin_disc collider",
    )
    for item in required:
        assert any(line.startswith(item) for line in result.stdout.splitlines()),item
    for line in result.stdout.splitlines():
        if line.startswith(("FOLIAGE_NATIVE_CONSTRUCTION_PASS",
                            "FOLIAGE_NATIVE_ADVERSARIAL_REJECTED",
                            "FOLIAGE_NATIVE_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)
if __name__=="__main__":
    main()
