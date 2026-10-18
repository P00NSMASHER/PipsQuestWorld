#!/usr/bin/env python3
"""Constructed-Luau acceptance for Emma's unique purple classroom chair.

The owner reports a large purple comfy chair in the corner; photographs of the
crowded cheer event do not reliably document its exact upholstery or floor coordinates.
Verify one distinguishable upholstered chair in the provisional window/storage
corner without changing the original 16 desk pairs, carpet or routes.
This is source geometry and collision QA, NOT final native-iPhone approval.
"""
from __future__ import annotations
import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
local function parts(name)
    local selected={}
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") and p.Name==name then table.insert(selected,p) end
    end
    return selected
end
local function one(name)
    local selected=parts(name)
    assert(#selected==1,"PURPLE_CHAIR_PART_COUNT_INVALID "..name)
    return selected[1]
end
local function check()
    local seat=one("Purple comfy chair seat cushion")
    local back=one("Purple comfy chair back cushion")
    local base=one("Purple comfy chair base collision")
    local backCollider=one("Purple comfy chair back collision")
    local arms=parts("Purple comfy chair padded arm")
    local armRolls=parts("Purple comfy chair rounded arm roll")
    local seatFrontRoll=one("Purple comfy chair rounded seat front roll")
    local apron=one("Purple comfy chair upholstered front apron")
    local crown=one("Purple comfy chair rounded back crown")
    local backBolsters=parts("Purple comfy chair back side bolster")
    assert(#arms==2 and #armRolls==2 and #backBolsters==2
        and #parts("Purple comfy chair back tuft")==3
        and #parts("Purple corner chair seat")==0,
        "PURPLE_CHAIR_COMFY_SILHOUETTE_INVALID")
    assert(seatFrontRoll.Material==Enum.Material.Fabric
        and not seatFrontRoll.CanCollide and not seatFrontRoll.CanTouch
        and not seatFrontRoll.CanQuery
        and math.abs(seatFrontRoll.Size.X-3.24)<.03
        and seatFrontRoll.Position.X>seat.Position.X+1.40
        and math.abs(seatFrontRoll.Position.Z-seat.Position.Z)<.08
        and math.abs(seatFrontRoll.Position.Y-seat.Position.Y)<.16,
        "PURPLE_CHAIR_SEAT_FRONT_ROLL_INVALID")
    assert(apron.Material==Enum.Material.Fabric
        and not apron.CanCollide and not apron.CanTouch and not apron.CanQuery,
        "PURPLE_CHAIR_APRON_COLLISION_INVALID")
    assert(crown.Material==Enum.Material.Fabric
        and not crown.CanCollide and not crown.CanTouch and not crown.CanQuery
        and math.abs(crown.Size.X-3.55)<.03
        and crown.Position.Y>back.Position.Y+1.30
        and math.abs(crown.Position.Z-back.Position.Z)<.08,
        "PURPLE_CHAIR_BACK_CROWN_INVALID")
    for _,roll in ipairs(armRolls) do
        assert(roll.Material==Enum.Material.Fabric
            and not roll.CanCollide and not roll.CanTouch and not roll.CanQuery
            and math.abs(roll.Size.X-2.55)<.03,
            "PURPLE_CHAIR_ARM_ROLL_INVALID")
    end
    for _,bolster in ipairs(backBolsters) do
        assert(bolster.Material==Enum.Material.Fabric
            and not bolster.CanCollide and not bolster.CanTouch and not bolster.CanQuery
            and math.abs(bolster.Size.X-2.72)<.03
            and math.abs(bolster.Size.Y-.52)<.03,
            "PURPLE_CHAIR_BACK_BOLSTER_INVALID")
    end
    assert(#parts("Student chair seat")==16
        and #parts("Student chair contoured back collision")==16,
        "PURPLE_CHAIR_REPLACED_STUDENT_CHAIR")
    local center=seat.Position
    assert(math.abs(center.X+32.45)<.03
        and math.abs(center.Z+19.62)<.04
        and math.abs(center.Y-1.58)<.03,
        "PURPLE_CHAIR_CORNER_POSITION_INVALID")
    assert(back.Position.X<center.X-1.20
        and math.abs(back.Position.Z-center.Z)<.08,
        "PURPLE_CHAIR_BACK_MUST_FACE_AWAY_FROM_WORKTABLE")
    local c=seat.Color
    assert(c.B>.57 and c.B<.82 and c.R>.40 and c.R<.65
        and c.G>.20 and c.G<.50 and c.B>c.R and c.R>c.G,
        "PURPLE_CHAIR_COLOR_INVALID")
    assert(seat.Material==Enum.Material.Fabric
        and back.Material==Enum.Material.Fabric
        and not seat.CanCollide and not back.CanCollide
        and base.CanCollide and base.Transparency==1
        and base.CanQuery==false and not base.CanTouch
        and backCollider.CanCollide and backCollider.Transparency==1
        and backCollider.CanQuery==false and not backCollider.CanTouch,
        "PURPLE_CHAIR_COLLISION_INVALID")
    for _,arm in ipairs(arms) do
        assert(arm.Material==Enum.Material.Fabric and not arm.CanCollide
            and not arm.CanTouch and not arm.CanQuery,
            "PURPLE_CHAIR_ARM_COLLISION_INVALID")
    end
    local rug=one("Alphabet rug")
    local dx=center.X-rug.Position.X
    local dz=center.Z-rug.Position.Z
    assert(math.sqrt(dx*dx+dz*dz)>10.5,
        "PURPLE_CHAIR_OBSCURES_AUTHENTIC_ALPHABET_RUG")
    local ac=one("Photo window air conditioner housing")
    assert(math.abs(center.Z-ac.Position.Z)<1.20,
        "PURPLE_CHAIR_NOT_BESIDE_PHOTOGRAPHED_AC_WINDOW")
    local radiator
    for _,p in ipairs(parts("Radiator body")) do
        if math.abs(p.Position.Z-ac.Position.Z)<.10 then radiator=p end
    end
    assert(radiator and center.X-base.Size.Z/2 >
        radiator.Position.X+radiator.Size.X/2+.35,
        "PURPLE_CHAIR_OVERLAPS_WINDOW_RADIATOR")
    local gray=one("Photo gray corner storage cabinet")
    local files=one("Photo black filing cabinet")
    local tableTop=one("Photo window worktable")
    assert(math.abs(gray.Position.X+34.05)<.03
        and math.abs(gray.Position.Z+30.50)<.03
        and math.abs(files.Position.X+34.10)<.03
        and math.abs(files.Position.Z+26.25)<.03
        and #parts("Photo filing drawer face")==3,
        "PURPLE_CHAIR_PHOTO_STORAGE_MISSING_OR_MISPLACED")
    assert(math.abs(tableTop.Position.X+27.50)<.03
        and math.abs(tableTop.Position.Z+19.60)<.03
        and math.abs(tableTop.Position.Y-3.16)<.03
        and #parts("Photo worktable metal leg")==4,
        "PURPLE_CHAIR_WORKTABLE_MISSING_OR_MISPLACED")
    assert(base.Position.X+base.Size.Z/2 <
        tableTop.Position.X-tableTop.Size.X/2-.20,
        "PURPLE_CHAIR_INTERSECTS_WINDOW_WORKTABLE")
    for _,desk in ipairs(parts("Student desk edge")) do
        local xGap=math.abs(desk.Position.X-tableTop.Position.X)
        local zGap=math.abs(desk.Position.Z-tableTop.Position.Z)
        assert(xGap>(desk.Size.X+tableTop.Size.X)/2+.25
            or zGap>(desk.Size.Z+tableTop.Size.Z)/2+.25,
            "PURPLE_CHAIR_WORKTABLE_CLIPS_STUDENT_DESKS")
    end
    assert(center.X-base.Size.Z/2>-34.40 and center.Z-2.0>-26.0,
        "PURPLE_CHAIR_INTERSECTS_CLASSROOM_WALLS")
    return seat,base,armRolls[1],crown,backBolsters[1],seatFrontRoll
end
local seat,collider,armRoll,crown,backBolster,seatFrontRoll=check()
print("EMMA_PURPLE_CHAIR_RUNTIME_PASS purple_chairs=1 "
    .."original_student_seats=16 chair_style=upholstered_comfy "
    .."color=violet window_storage_corner=true "
    .."rug_clear=true radiator_clear=true faces_worktable=true photo_workstation=true "
    .."coordinates_provisional=true")
local previousColor=seat.Color
seat.Color=Color3.fromRGB(52,73,108)
local ok,err=pcall(check)
seat.Color=previousColor
assert(not ok and string.find(tostring(err),"PURPLE_CHAIR_COLOR_INVALID",1,true),
    "PURPLE_CHAIR_WRONG_COLOR_NOT_REJECTED")
print("EMMA_PURPLE_CHAIR_ADVERSARIAL_REJECTED blue_repaint")
local previousCF=seat.CFrame
local previousSeatFrontRollCF=seatFrontRoll.CFrame
local relocation=CFrame.new(-25,1.58,14)*CFrame.Angles(-math.pi/2,-math.pi/2,0)
local relocationDelta=relocation.Position-seat.Position
seat.CFrame=relocation
seatFrontRoll.CFrame=CFrame.new(relocationDelta.X,relocationDelta.Y,relocationDelta.Z)
    *seatFrontRoll.CFrame
ok,err=pcall(check)
seat.CFrame=previousCF
seatFrontRoll.CFrame=previousSeatFrontRollCF
assert(not ok and string.find(tostring(err),"PURPLE_CHAIR_CORNER_POSITION_INVALID",1,true),
    "PURPLE_CHAIR_RUG_RELOCATION_NOT_REJECTED")
print("EMMA_PURPLE_CHAIR_ADVERSARIAL_REJECTED moved_into_rug")
local oldCollider=collider.CanCollide
collider.CanCollide=false
ok,err=pcall(check)
collider.CanCollide=oldCollider
assert(not ok and string.find(tostring(err),"PURPLE_CHAIR_COLLISION_INVALID",1,true),
    "PURPLE_CHAIR_MISSING_COLLIDER_NOT_REJECTED")
check()
local oldRollCollision=armRoll.CanCollide
armRoll.CanCollide=true
ok,err=pcall(check)
armRoll.CanCollide=oldRollCollision
assert(not ok and string.find(tostring(err),"PURPLE_CHAIR_ARM_ROLL_INVALID",1,true),
    "PURPLE_CHAIR_COLLIDING_ARM_ROLL_NOT_REJECTED")
check()
print("EMMA_PURPLE_CHAIR_ADVERSARIAL_REJECTED colliding_arm_roll")
local oldCrownCollision=crown.CanCollide
crown.CanCollide=true
ok,err=pcall(check)
crown.CanCollide=oldCrownCollision
assert(not ok and string.find(tostring(err),"PURPLE_CHAIR_BACK_CROWN_INVALID",1,true),
    "PURPLE_CHAIR_COLLIDING_BACK_CROWN_NOT_REJECTED")
check()
print("EMMA_PURPLE_CHAIR_ADVERSARIAL_REJECTED colliding_back_crown")
local oldBolsterCollision=backBolster.CanCollide
backBolster.CanCollide=true
ok,err=pcall(check)
backBolster.CanCollide=oldBolsterCollision
assert(not ok and string.find(tostring(err),"PURPLE_CHAIR_BACK_BOLSTER_INVALID",1,true),
    "PURPLE_CHAIR_COLLIDING_BACK_BOLSTER_NOT_REJECTED")
check()
print("EMMA_PURPLE_CHAIR_ADVERSARIAL_REJECTED colliding_back_bolster")
print("EMMA_PURPLE_CHAIR_NEGATIVE_TESTS_PASS color position collision arm_roll back_crown back_bolster")
'''
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    source=generate_luau()+"\n"+PROBE+"\n"
    with tempfile.TemporaryDirectory(prefix="emma-purple-chair-") as tmp:
        path=Path(tmp)/"chair.lua"
        path.write_text(source,encoding="utf-8")
        result=subprocess.run([args.luau,str(path)],capture_output=True,
            text=True,timeout=115,check=False)
    if result.returncode:
        raise RuntimeError("Constructed purple chair audit failed:\n"
            +result.stderr[-3000:]+"\n"+result.stdout[-1500:])
    required=("EMMA_PURPLE_CHAIR_RUNTIME_PASS",
              "EMMA_PURPLE_CHAIR_ADVERSARIAL_REJECTED blue_repaint",
              "EMMA_PURPLE_CHAIR_ADVERSARIAL_REJECTED moved_into_rug",
              "EMMA_PURPLE_CHAIR_NEGATIVE_TESTS_PASS")
    lines=result.stdout.splitlines()
    for marker in required:
        assert any(s.startswith(marker) for s in lines), marker
    for line in lines:
        if line.startswith(("EMMA_PURPLE_CHAIR_RUNTIME_PASS",
                            "EMMA_PURPLE_CHAIR_ADVERSARIAL_REJECTED",
                            "EMMA_PURPLE_CHAIR_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)
if __name__=="__main__":
    main()
