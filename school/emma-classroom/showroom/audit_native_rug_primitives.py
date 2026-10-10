#!/usr/bin/env python3
"""Native Roblox primitive safety audit: Ball minimum-axis size regression.

Roblox Ball Parts render a true sphere whose diameter is min(Size.X,Y,Z).
The old flattened cloud/ray Balls appeared as dots on native iPhone even
though the independent geometry renderer interpreted them as ellipsoids.
Run the real classroom Lua constructor and test physical Shape, orientation,
non-collision and negative regressions. This is not native visual acceptance.
"""
from __future__ import annotations
import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
local function check()
    local rays, tips, centers, lobes, labels={},{},{},{},{}
    for _,v in ipairs(Room.Root:GetDescendants()) do
        if v:IsA("BasePart") then
            if v.Name=="Photo rug sun ray" then table.insert(rays,v)
            elseif v.Name=="Photo rug sun ray rounded tip" then table.insert(tips,v)
            elseif v.Name=="Photo rug number cloud body" then table.insert(centers,v)
            elseif v.Name=="Photo rug number cloud lobe" then table.insert(lobes,v)
            elseif v.Name=="Photo rug number cloud numeral" then table.insert(labels,v)
            end
        end
    end
    assert(#rays==16 and #tips==16
        and #centers==10 and #lobes==20 and #labels==10,
        "RUG_NATIVE_PART_COUNT_INVALID")
    for _,p in ipairs(rays) do
        assert(p.Shape==Enum.PartType.Block,
            "RUG_NATIVE_FLATTENED_BALL_RAY")
        assert(p.Size.X>.75 and p.Size.Y<=.11 and p.Size.Z>.20
            and p.Size.Z<=.31,"RUG_NATIVE_RAY_DIMENSIONS_INVALID")
    end
    for _,p in ipairs(tips) do
        assert(p.Shape==Enum.PartType.Cylinder,
            "RUG_NATIVE_RAY_TIP_SHAPE_INVALID")
        assert(p.Size.X<=.11 and p.Size.Y>.20
            and math.abs(p.CFrame.m[4])>.99,
            "RUG_NATIVE_RAY_TIP_ORIENTATION_INVALID")
    end
    for _,p in ipairs(centers) do
        assert(p.Shape==Enum.PartType.Block,
            "RUG_NATIVE_CLOUD_BODY_BALL_INVALID")
        assert(p.Size.X>1.1 and p.Size.Y<.14
            and p.Size.Z>.60,"RUG_NATIVE_CLOUD_BODY_DIMENSIONS_INVALID")
    end
    for _,p in ipairs(lobes) do
        assert(p.Shape==Enum.PartType.Cylinder,
            "RUG_NATIVE_CLOUD_LOBE_BALL_INVALID")
        assert(p.Size.X<=.13 and p.Size.Y>.90 and p.Size.Z>.90
            and math.abs(p.CFrame.m[4])>.99,
            "RUG_NATIVE_CLOUD_LOBE_ORIENTATION_INVALID")
    end
    for _,p in ipairs(labels) do
        assert(p.Transparency>=.99 and p.Shape==Enum.PartType.Block
            and p.Size.Y<=.02,"RUG_NATIVE_NUMERAL_LABEL_INVALID")
        local gui=p:FindFirstChildOfClass("SurfaceGui")
        assert(gui and gui.Face==Enum.NormalId.Top,
            "RUG_NATIVE_NUMERAL_FACE_INVALID")
    end
    for _,set in ipairs({rays,tips,centers,lobes,labels}) do
        for _,p in ipairs(set) do
            assert(not p.CanCollide and not p.CanTouch,
                "RUG_NATIVE_DECORATIVE_COLLISION_INVALID")
        end
    end
    return rays,lobes
end
local rays,lobes=check()
print("RUG_NATIVE_PRIMITIVES_PASS rays=16 caps=16 "
    .."cloud_bodies=10 flat_cylinder_lobes=20 "
    .."transparent_numbers=10 collision_free=true")
local saved=lobes[1].Shape
lobes[1].Shape=Enum.PartType.Ball
local ok,err=pcall(check)
lobes[1].Shape=saved
assert(not ok and string.find(tostring(err),
    "RUG_NATIVE_CLOUD_LOBE_BALL_INVALID",1,true),
    "RUG_NATIVE_BALL_CLOUD_NOT_REJECTED")
print("RUG_NATIVE_ADVERSARIAL_REJECTED flattened_cloud_ball")
saved=rays[1].Shape
rays[1].Shape=Enum.PartType.Ball
ok,err=pcall(check)
rays[1].Shape=saved
assert(not ok and string.find(tostring(err),
    "RUG_NATIVE_FLATTENED_BALL_RAY",1,true),
    "RUG_NATIVE_BALL_RAY_NOT_REJECTED")
check()
print("RUG_NATIVE_NEGATIVE_TESTS_PASS cloud_ball ray_ball")
'''
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    source=generate_luau()+"\n"+PROBE+"\n"
    with tempfile.TemporaryDirectory(prefix="emma-native-rug-") as tmp:
        path=Path(tmp)/"verify.lua"
        path.write_text(source,encoding="utf-8")
        result=subprocess.run([args.luau,str(path)],capture_output=True,
            text=True,timeout=115,check=False)
    if result.returncode:
        raise RuntimeError("Native rug construction audit failed:\n"
            +result.stderr[-3000:]+"\n"+result.stdout[-2500:])
    markers=("RUG_NATIVE_PRIMITIVES_PASS",
             "RUG_NATIVE_ADVERSARIAL_REJECTED flattened_cloud_ball",
             "RUG_NATIVE_NEGATIVE_TESTS_PASS cloud_ball ray_ball")
    lines=result.stdout.splitlines()
    for marker in markers:
        assert any(x.startswith(marker) for x in lines), marker
    for line in lines:
        if line.startswith(("RUG_NATIVE_PRIMITIVES_PASS",
                            "RUG_NATIVE_ADVERSARIAL_REJECTED",
                            "RUG_NATIVE_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)
if __name__=="__main__":
    main()
