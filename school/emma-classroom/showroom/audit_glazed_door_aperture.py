#!/usr/bin/env python3
"""Audit real glass apertures in both the rear closet and left staff doors.

The photographed school-door glazing is only transparent if NO full-height
opaque wooden slab sits behind it. Construct the actual showroom Luau source
and mutate the framed leaves to ensure the audit rejects opaque panes, obstructed
apertures, collidable door artwork and missing staff frames. This remains
independent geometric QA, NOT native Roblox/iPhone visual acceptance.
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
local doors=all("Closed classroom closet door")
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

-- The left/staff door is the ONLY passage from the classroom into the photo
-- hallway. Its previous 10-stud-high Wood slab hid the nominal glass even
-- though the SurfaceGui/Glass overlay looked transparent in source.
local function only(name)
    local items=all(name)
    assert(#items==1,"STAFF_APERTURE_PART_COUNT "..name.."="..#items)
    return items[1]
end
local staffPanel=only("Open staff classroom door")
local staffGlass=only("Staff door glass")
local staffRails=all("Staff door oak rail")
local staffStiles=all("Staff door oak side stile")
local staffDivider=only("Staff door glazing crossbar")
local staffPull=only("Staff door brass pull")
assert(#staffRails==2 and #staffStiles==2,
    "STAFF_APERTURE_FRAME_PART_COUNT")
local function verifyStaff()
    assert(staffPanel.Material==Enum.Material.Wood
        and staffPanel.Size.Y>=4.25 and staffPanel.Size.Y<=4.35
        and math.abs(staffPanel.Size.X-.55)<.02
        and math.abs(staffPanel.Size.Z-6.60)<.03
        and not staffPanel.CanCollide and not staffPanel.CanTouch
        and staffPanel:GetAttribute("StaffDoorPanel")~=nil,
        "STAFF_APERTURE_OPAQUE_FULL_HEIGHT_SLAB")
    assert(math.abs(staffPanel.Position.X-35.90)<.05
        and math.abs(staffPanel.Position.Y-2.45)<.05
        and math.abs(staffPanel.Position.Z-17.00)<.05,
        "STAFF_APERTURE_HINGE_OR_LOWER_LEAF_MOVED")
    assert(staffGlass.Material==Enum.Material.Glass
        and staffGlass.Transparency>.20 and staffGlass.Transparency<.45
        and staffGlass.Reflectance<.06
        and not staffGlass.CanCollide and not staffGlass.CanTouch
        and not staffGlass.CastShadow
        and staffGlass:GetAttribute("GlazedOpening")~=nil,
        "STAFF_APERTURE_GLASS_OPAQUE_OR_BLOCKING")
    assert(staffGlass.Size.Z>=4.50 and staffGlass.Size.Z<=4.70
        and staffGlass.Size.Y>=4.25 and staffGlass.Size.Y<=4.40,
        "STAFF_APERTURE_GLASS_TOO_NARROW")
    assert(math.abs(staffGlass.Position.Y-6.94)<.06,
        "STAFF_APERTURE_GLASS_VERTICALLY_SHIFTED")
    -- A real glass opening must begin ABOVE the solid lower panel. The
    -- sill overlaps their small 0.18-stud separation without a sky gap.
    local gap=(staffGlass.Position.Y-staffGlass.Size.Y/2)
              -(staffPanel.Position.Y+staffPanel.Size.Y/2)
    assert(gap>.08 and gap<.26,
        "STAFF_APERTURE_OPAQUE_WOOD_BEHIND_GLASS")
    local sill,head=0,0
    for _,r in ipairs(staffRails) do
        assert(r.Material==Enum.Material.Wood
            and not r.CanCollide and not r.CanTouch
            and math.abs(r.Size.Z-6.6)<.05,
            "STAFF_APERTURE_FRAME_COLLIDER")
        if r:GetAttribute("StaffDoorRail")=="Sill" then
            sill+=1
            assert(math.abs(r.Position.Y-4.65)<.07
                and r.Size.Y>.35,
                "STAFF_APERTURE_SILL_NOT_CLOSING_GAP")
        elseif r:GetAttribute("StaffDoorRail")=="Head" then
            head+=1
            assert(math.abs(r.Position.Y-9.65)<.07
                and r.Size.Y>=1.35,
                "STAFF_APERTURE_HEAD_MISSING")
        else
            error("STAFF_APERTURE_UNLABELED_RAIL")
        end
    end
    assert(sill==1 and head==1,
        "STAFF_APERTURE_FRAME_RAILS_INCOMPLETE")
    for _,s in ipairs(staffStiles) do
        assert(not s.CanCollide and not s.CanTouch
            and s.Material==Enum.Material.Wood
            and s.Size.Y>=4.25 and s.Size.Z>=.95,
            "STAFF_APERTURE_FRAME_COLLIDER")
    end
    assert(not staffDivider.CanCollide and not staffDivider.CanTouch
        and staffDivider.Material==Enum.Material.Wood
        and staffDivider.Size.Y<.22,
        "STAFF_APERTURE_CROSSBAR_BLOCKING")
    assert(not staffPull.CanCollide and not staffPull.CanTouch
        and staffPull.Material==Enum.Material.Metal,
        "STAFF_APERTURE_HANDLE_BLOCKING")
    local parts=0
    for _,v in ipairs(Room.Root:GetDescendants()) do
        if v:IsA("BasePart") then parts+=1 end
    end
    assert(parts<=3100,"STAFF_APERTURE_EXCEEDED_MOBILE_PART_CAP")
    return parts
end
local sourceParts=verifyStaff()
local oldPanelSize=staffPanel.Size
staffPanel.Size=Vector3.new(.55,10,6.6)
local ok,err=pcall(verifyStaff)
staffPanel.Size=oldPanelSize
assert(not ok and string.find(tostring(err),
    "STAFF_APERTURE_OPAQUE_FULL_HEIGHT_SLAB",1,true),
    "STAFF_APERTURE_NEGATIVE_FULL_WOOD_SLAB_ACCEPTED")
print("STAFF_APERTURE_ADVERSARIAL_REJECTED opaque_full_height_wood")
local priorGlassAlpha=staffGlass.Transparency
staffGlass.Transparency=0
ok,err=pcall(verifyStaff)
staffGlass.Transparency=priorGlassAlpha
assert(not ok and string.find(tostring(err),
    "STAFF_APERTURE_GLASS_OPAQUE_OR_BLOCKING",1,true),
    "STAFF_APERTURE_NEGATIVE_GLASS_OPACITY_ACCEPTED")
print("STAFF_APERTURE_ADVERSARIAL_REJECTED opaque_glass")
local originalStileCollision=staffStiles[1].CanCollide
staffStiles[1].CanCollide=true
ok,err=pcall(verifyStaff)
staffStiles[1].CanCollide=originalStileCollision
assert(not ok and string.find(tostring(err),
    "STAFF_APERTURE_FRAME_COLLIDER",1,true),
    "STAFF_APERTURE_NEGATIVE_FRAME_COLLIDER_ACCEPTED")
print("STAFF_APERTURE_ADVERSARIAL_REJECTED collidable_frame")
local priorPaneSize=staffGlass.Size
staffGlass.Size=Vector3.new(.16,4.32,2.10)
ok,err=pcall(verifyStaff)
staffGlass.Size=priorPaneSize
assert(not ok and string.find(tostring(err),
    "STAFF_APERTURE_GLASS_TOO_NARROW",1,true),
    "STAFF_APERTURE_NEGATIVE_GLASS_SLIT_ACCEPTED")
print("STAFF_APERTURE_ADVERSARIAL_REJECTED collapsed_glass_aperture")
verifyStaff()
print("STAFF_APERTURE_RUNTIME_PASS true_open_staff_door_glazing=true "
    .."extra_parts=6 all_decorations_noncolliding=true "
    .."physical_part_count="..sourceParts.." native_iphone_pending=true")

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
        "STAFF_APERTURE_RUNTIME_PASS",
        "STAFF_APERTURE_ADVERSARIAL_REJECTED opaque_full_height_wood",
        "STAFF_APERTURE_ADVERSARIAL_REJECTED opaque_glass",
        "STAFF_APERTURE_ADVERSARIAL_REJECTED collidable_frame",
        "STAFF_APERTURE_ADVERSARIAL_REJECTED collapsed_glass_aperture",
    ):
        assert marker in proc.stdout, marker
    for line in proc.stdout.splitlines():
        if line.startswith(("PHOTO_APERTURE", "STAFF_APERTURE")):
            print(line,flush=True)


if __name__=="__main__":
    main()
