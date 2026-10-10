#!/usr/bin/env python3
"""Execute the shipped Luau constructors and reject opaque rear classroom doors.

The October 10 source-derived child-eye screenshot exposed an opaque full-height
Wood slab behind every supposedly translucent glazed panel. This audit checks
the actual geometry and deliberately breaks it twice to prove regression
detection. It is still NOT native Roblox/iPhone visual acceptance.
"""
from __future__ import annotations

import argparse
import subprocess
import tempfile
from pathlib import Path

from export_source_scene import generate_luau


PROBE = r'''
local function all(name)
    local found={}
    for _,v in ipairs(Room.Root:GetDescendants()) do
        if v:IsA("BasePart") and v.Name==name then
            table.insert(found,v)
        end
    end
    return found
end
local doors=all("Open classroom door")
local panes=all("Door glass")
local rails=all("Glazed door solid oak rail")
local stiles=all("Glazed door oak side stile")
local dividers=all("Glazed door glass divider")
local pulls=all("Glazed door brass pull")
local thresholds=all("Classroom doorway brass threshold")
assert(#doors==2 and #panes==2 and #rails==4
    and #stiles==4 and #dividers==2 and #pulls==2
    and #thresholds==1,"PHOTO_APERTURE_PIECE_COUNT")
local function verify()
    local topRails=0
    local sillRails=0
    for _,r in ipairs(rails) do
        assert(not r.CanCollide and r.Material==Enum.Material.Wood
            and math.abs(r.Size.X-4.65)<.04,
            "PHOTO_APERTURE_FRAME_RAIL_INVALID")
        if r:GetAttribute("DoorRailType")=="Top" then
            topRails+=1
            assert(math.abs(r.Size.Y-1.30)<.04)
        elseif r:GetAttribute("DoorRailType")=="Sill" then
            sillRails+=1
            assert(math.abs(r.Size.Y-.32)<.04)
        else
            error("PHOTO_APERTURE_UNKNOWN_FRAME_RAIL")
        end
    end
    assert(topRails==2 and sillRails==2,
        "PHOTO_APERTURE_MISSING_TOP_OR_SILL")
    for _,side in ipairs(stiles) do
        assert(side.Size.X>1 and side.Size.X<1.1
            and side.Size.Y>4.3 and not side.CanCollide,
            "PHOTO_APERTURE_MARGINAL_OAK_MISSING")
    end
    for _,p in ipairs(panes) do
        assert(p.Material==Enum.Material.Glass
            and p.Transparency>.20 and p.Transparency<.45
            and not p.CanCollide and not p.CanTouch
            and p.CastShadow==false,
            "PHOTO_APERTURE_GLASS_IS_OPAQUE_OR_BLOCKING")
        assert(p:GetAttribute("GlazedOpening")~=nil,
            "PHOTO_APERTURE_NOT_MARKED")
        local closest=nil
        local distance=1e9
        for _,d in ipairs(doors) do
            local delta=math.abs(d.Position.X-p.Position.X)
            if delta<distance then closest=d;distance=delta end
        end
        assert(closest~=nil and distance<.25,
            "PHOTO_APERTURE_DOOR_LEAF_AND_GLASS_DISCONNECTED")
        local d=closest
        assert(d.Material==Enum.Material.Wood
            and d.Size.Y>4.18 and d.Size.Y<4.35
            and not d.CanCollide and not d.CanTouch,
            "PHOTO_APERTURE_OPAQUE_FULL_HEIGHT_SLAB")
        assert(math.abs(d.Position.Y-2.41)<.05
            and math.abs(p.Position.Y-6.70)<.05,
            "PHOTO_APERTURE_LEAF_VERTICAL_MISALIGNMENT")
        local top=d.Position.Y+d.Size.Y/2
        local glassBottom=p.Position.Y-p.Size.Y/2
        assert(glassBottom>top-.09 and glassBottom<top+.09,
            "PHOTO_APERTURE_GLASS_LOWER_EDGE_CONCEALED")
        assert(p.Size.X>2.5 and p.Size.Y>4.3,
            "PHOTO_APERTURE_LIGHT_TOO_SMALL")
    end
    for _,p in ipairs(dividers) do
        assert(not p.CanCollide and p.Size.Y<.22
            and p.Material==Enum.Material.Wood,
            "PHOTO_APERTURE_GLASS_DIVIDER_OBSTRUCTS")
    end
    for _,p in ipairs(pulls) do
        assert(not p.CanCollide and p.Material==Enum.Material.Metal,
            "PHOTO_APERTURE_DOOR_PULL_BLOCKS_AVATAR")
    end
end

verify()
local prior=doors[1].Size
doors[1].Size=Vector3.new(4.65,10,.36)
local ok,err=pcall(verify)
doors[1].Size=prior
assert(not ok and string.find(tostring(err),
    "PHOTO_APERTURE_OPAQUE_FULL_HEIGHT_SLAB",1,true),
    "PHOTO_APERTURE_NEGATIVE_OPAQUE_SLAB_NOT_REJECTED")
print("PHOTO_APERTURE_ADVERSARIAL_REJECTED opaque_wood_slab")
local former=panes[1].Transparency
panes[1].Transparency=0
ok,err=pcall(verify)
panes[1].Transparency=former
assert(not ok and string.find(tostring(err),
    "PHOTO_APERTURE_GLASS_IS_OPAQUE_OR_BLOCKING",1,true),
    "PHOTO_APERTURE_NEGATIVE_OPAQUE_PANE_NOT_REJECTED")
print("PHOTO_APERTURE_ADVERSARIAL_REJECTED zero_transparency")
verify()
print("PHOTO_APERTURE_RUNTIME_PASS two_true_glass_apertures "
    .."two_oak_dividers two_brass_pulls open_leaf_collision_free "
    .."source_render_not_roblox_device_acceptance")
'''


def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True,help="Pinned Luau binary")
    args=parser.parse_args()
    script=generate_luau()+"\n"+PROBE
    with tempfile.TemporaryDirectory(prefix="photo-glass-door-") as tmp:
        probe=Path(tmp)/"probe.luau"
        probe.write_text(script,encoding="utf-8")
        proc=subprocess.run(
            [args.luau,str(probe)],
            capture_output=True,text=True,timeout=110,
            check=False
        )
    if proc.returncode:
        raise RuntimeError("Real Lua door constructors failed:\n"
                           +proc.stderr[-4500:]+"\n"+proc.stdout[-2500:])
    for marker in (
        "PHOTO_APERTURE_ADVERSARIAL_REJECTED opaque_wood_slab",
        "PHOTO_APERTURE_ADVERSARIAL_REJECTED zero_transparency",
        "PHOTO_APERTURE_RUNTIME_PASS",
    ):
        assert marker in proc.stdout, marker
    for line in proc.stdout.splitlines():
        if line.startswith("PHOTO_APERTURE"):
            print(line,flush=True)


if __name__=="__main__":
    main()
