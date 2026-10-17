#!/usr/bin/env python3
"""Constructed-Luau acceptance for Emma's unique purple classroom chair.

The child reports a purple chair in the corner; photographs of the crowded
cheer event do not reliably document exact chair style or floor coordinates.
Verify one distinguishable purple chair in the provisional window/storage
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
        if p:IsA("BasePart") and p.Name==name then
            table.insert(selected,p)
        end
    end
    return selected
end
local function one(name)
    local selected=parts(name)
    assert(#selected==1,"PURPLE_CHAIR_PART_COUNT_INVALID "..name)
    return selected[1]
end
local function check()
    local seat=one("Purple corner chair seat")
    local back=one("Purple corner chair school back shell")
    local collider=one("Purple corner chair contoured back collision")
    assert(#parts("Purple corner chair ventilation inset")==3
        and #parts("Purple corner chair tubular leg")==4,
        "PURPLE_CHAIR_MOLDED_SILHOUETTE_INVALID")
    assert(#parts("Student chair seat")==16
        and #parts("Student chair contoured back collision")==16,
        "PURPLE_CHAIR_REPLACED_STUDENT_CHAIR")
    local center=seat.Position
    assert(math.abs(center.X+25.0)<.03
        and math.abs(center.Z-18.35)<.03
        and math.abs(center.Y-1.62)<.03,
        "PURPLE_CHAIR_CORNER_POSITION_INVALID")
    -- The unique chair faces -Z toward the teacher desk; its backrest stays
    -- on the +Z side like the other classroom chairs.
    assert(math.abs(back.Position.X-center.X)<.04
        and math.abs(back.Position.Z-(center.Z+.93))<.06,
        "PURPLE_CHAIR_BACK_MUST_FACE_AWAY_FROM_TEACHER_DESK")
    local c=seat.Color
    assert(c.B>.57 and c.B<.78 and c.R>.40 and c.R<.60
        and c.G>.20 and c.G<.43 and c.B>c.R and c.R>c.G,
        "PURPLE_CHAIR_COLOR_INVALID")
    assert(seat.CanCollide and seat.Anchored
        and collider.CanCollide and collider.Transparency==1
        and collider.CanQuery==false and not back.CanCollide,
        "PURPLE_CHAIR_COLLISION_INVALID")
    local rug=one("Alphabet rug")
    local dx=center.X-rug.Position.X
    local dz=center.Z-rug.Position.Z
    assert(math.sqrt(dx*dx+dz*dz)>10.5,
        "PURPLE_CHAIR_OBSCURES_AUTHENTIC_ALPHABET_RUG")
    local gray=one("Photo gray corner storage cabinet")
    local files=one("Photo black filing cabinet")
    assert(math.abs(gray.Position.X+34.05)<.03
        and math.abs(gray.Position.Z+30.50)<.03
        and math.abs(files.Position.X+33.75)<.03
        and math.abs(files.Position.Z+26.25)<.03
        and #parts("Photo filing drawer face")==3,
        "PURPLE_CHAIR_PHOTO_STORAGE_MISSING_OR_MISPLACED")
    assert(#parts("Photo window worktable")==0
        and #parts("Photo worktable metal leg")==0
        and #parts("Photo worktable paper stack")==0
        and #parts("Photo worktable book")==0,
        "PURPLE_CHAIR_REMOVED_SILVER_TABLE_RETURNED")
    -- The forward seat roll must point toward the teacher desk (-Z).
    local front=one("Purple corner chair molded front seat roll")
    assert(math.abs(front.Position.X-center.X)<.04
        and front.Position.Z<center.Z-.90,
        "PURPLE_CHAIR_SEAT_FACES_AWAY_FROM_TEACHER_DESK")
    local teacherTop=one("Teacher desk top")
    assert(math.abs(teacherTop.Position.X+25)<.04
        and math.abs(teacherTop.Position.Z-14)<.04
        and center.Z-teacherTop.Position.Z>4.0,
        "PURPLE_CHAIR_NOT_BEHIND_TEACHER_DESK")
    assert(center.X-1.25>-34.40 and center.Z+1.8<26.5,
        "PURPLE_CHAIR_INTERSECTS_CLASSROOM_WALLS")
    return seat,collider
end
local seat,collider=check()
print("EMMA_PURPLE_CHAIR_RUNTIME_PASS purple_chairs=1 "
    .."original_student_seats=16 chair_style=molded "
    .."color=violet behind_teacher_desk=true "
    .."rug_clear=true silver_table_removed=true faces_teacher_desk=true")
local previousColor=seat.Color
seat.Color=Color3.fromRGB(52,73,108)
local ok,err=pcall(check)
seat.Color=previousColor
assert(not ok and string.find(tostring(err),
    "PURPLE_CHAIR_COLOR_INVALID",1,true),
    "PURPLE_CHAIR_WRONG_COLOR_NOT_REJECTED")
print("EMMA_PURPLE_CHAIR_ADVERSARIAL_REJECTED blue_repaint")
local previousCF=seat.CFrame
seat.CFrame=CFrame.new(-25,1.62,14)
ok,err=pcall(check)
seat.CFrame=previousCF
assert(not ok and string.find(tostring(err),
    "PURPLE_CHAIR_CORNER_POSITION_INVALID",1,true),
    "PURPLE_CHAIR_RUG_RELOCATION_NOT_REJECTED")
print("EMMA_PURPLE_CHAIR_ADVERSARIAL_REJECTED moved_into_rug")
local oldCollider=collider.CanCollide
collider.CanCollide=false
ok,err=pcall(check)
collider.CanCollide=oldCollider
assert(not ok and string.find(tostring(err),
    "PURPLE_CHAIR_COLLISION_INVALID",1,true),
    "PURPLE_CHAIR_MISSING_COLLIDER_NOT_REJECTED")
check()
print("EMMA_PURPLE_CHAIR_NEGATIVE_TESTS_PASS color position collision")

-- A separate BIG upholstered chair was requested at the rug's right corner.
-- The preexisting molded "Purple corner chair" remains in its old location.
local function verifyStorytime()
    local base=one("Storytime purple armchair base")
    local seat=one("Storytime purple armchair seat cushion")
    local back=one("Storytime purple armchair tall padded back")
    local pillow=one("Storytime purple armchair lumbar pillow")
    assert(#parts("Storytime purple armchair rolled arm")==2
        and #parts("Storytime purple armchair arm piping")==2
        and #parts("Storytime purple armchair tufted button")==2
        and #parts("Storytime purple armchair front cushion piping")==1
        and #parts("Storytime purple armchair seat cushion rounded corner")==4
        and #parts("Storytime purple armchair tall padded back rounded corner")==4
        and #parts("Storytime purple armchair lumbar pillow rounded corner")==4
        and #parts("Storytime purple armchair rolled arm rounded corner")==8,
        "STORYTIME_ARMCHAIR_PLUSH_DETAILS_MISSING")
    assert(math.abs(base.Position.X-33.10)<.03
        and math.abs(base.Position.Z+31.80)<.03
        and math.abs(base.Position.Y-1.22)<.03
        and base.Size.X>4.1 and base.Size.Z>3.5,
        "STORYTIME_ARMCHAIR_CORNER_POSITION_INVALID")
    assert(base.CFrame.m[1]>.93 and base.CFrame.m[1]<.96
        and base.CFrame.m[3]<-.30 and base.CFrame.m[3]>-.38,
        "STORYTIME_ARMCHAIR_NOT_ANGLED_TO_RUG")
    local baseColor=base.Color
    local seatColor=seat.Color
    assert(baseColor.R>.29 and baseColor.R<.40
        and baseColor.G<.28 and baseColor.B>.47 and baseColor.B<.57
        and seatColor.B>.73 and seatColor.R>.55
        and seatColor.B>seatColor.R and seatColor.R>seatColor.G,
        "STORYTIME_ARMCHAIR_PURPLE_UPHOLSTERY_INVALID")
    assert(base.Material==Enum.Material.Fabric and base.CanCollide
        and base.Anchored and base.Position.Y-base.Size.Y/2>=.50
        and base.Position.Y-base.Size.Y/2<.57,
        "STORYTIME_ARMCHAIR_COLLISION_OR_FLOOR_INVALID")
    assert(math.abs(seat.Position.Y-2.17)<.03
        and math.abs(seat.Position.X-(base.Position.X+base.CFrame.m[3]*.44))<.05
        and math.abs(seat.Position.Z-(base.Position.Z+base.CFrame.m[9]*.44))<.05
        -- roundedPanel's collidable core excludes its rounded X edges;
        -- horizontal core axes are X=width, Y=depth, Z=thickness.
        and seat.Size.X>2.70 and seat.Size.Y>2.55 and seat.Size.Z>.55
        and back.Size.Y>3.40 and back.Position.Y>3.25
        and pillow.Material==Enum.Material.Fabric,
        "STORYTIME_ARMCHAIR_SEAT_NOT_PADDED_OR_CENTERED")
    local count=0
    local prefix="Storytime purple armchair "
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") and string.sub(p.Name,1,#prefix)==prefix then
            count+=1
            assert(p.Anchored,"STORYTIME_ARMCHAIR_UNANCHORED")
            if p~=base then
                assert(not p.CanCollide and not p.CanTouch,
                    "STORYTIME_ARMCHAIR_DECOR_BLOCKS_PLAYERS")
            end
        end
    end
    assert(count>=34 and count<=42,"STORYTIME_ARMCHAIR_MOBILE_PART_BUDGET")
    local rug=one("Alphabet rug")
    for _,lx in ipairs({-2.25,2.25}) do
        for _,lz in ipairs({-2.0,2.0}) do
            local px=base.Position.X+base.CFrame.m[1]*lx+base.CFrame.m[3]*lz
            local pz=base.Position.Z+base.CFrame.m[7]*lx+base.CFrame.m[9]*lz
            assert(px<36.50 and px>-36.50 and pz>-34.50 and pz<26.50,
                "STORYTIME_ARMCHAIR_INTERSECTS_CLASSROOM_WALL")
            assert(math.sqrt((px-rug.Position.X)^2+(pz-rug.Position.Z)^2)>7.35,
                "STORYTIME_ARMCHAIR_COVERS_ALPHABET_RUG")
        end
    end
    return base,seat
end
local storyBase,storyCushion=verifyStorytime()
print("EMMA_STORYTIME_ARMCHAIR_RUNTIME_PASS adult_comfy=true purple_fabric=true "
    .."rolled_arms=2 cushions=3 buttons=2 clear_of_rug=true")
local originalPurple=storyBase.Color
storyBase.Color=Color3.fromRGB(57,108,172)
local good,errorText=pcall(verifyStorytime)
storyBase.Color=originalPurple
assert(not good and string.find(tostring(errorText),
    "STORYTIME_ARMCHAIR_PURPLE_UPHOLSTERY_INVALID",1,true),
    "STORYTIME_ARMCHAIR_REPAINT_NOT_REJECTED")
print("EMMA_STORYTIME_ARMCHAIR_ADVERSARIAL_REJECTED blue_repaint")
local cushionCF=storyCushion.CFrame
storyCushion.CFrame=CFrame.new(25,2.17,-25)
good,errorText=pcall(verifyStorytime)
storyCushion.CFrame=cushionCF
assert(not good and string.find(tostring(errorText),
    "STORYTIME_ARMCHAIR_SEAT_NOT_PADDED_OR_CENTERED",1,true),
    "STORYTIME_ARMCHAIR_RUG_COLLISION_NOT_REJECTED")
print("EMMA_STORYTIME_ARMCHAIR_ADVERSARIAL_REJECTED cushion_into_rug")
local originalCollision=storyBase.CanCollide
storyBase.CanCollide=false
good,errorText=pcall(verifyStorytime)
storyBase.CanCollide=originalCollision
assert(not good and string.find(tostring(errorText),
    "STORYTIME_ARMCHAIR_COLLISION_OR_FLOOR_INVALID",1,true),
    "STORYTIME_ARMCHAIR_MISSING_COLLIDER_NOT_REJECTED")
verifyStorytime()
print("EMMA_STORYTIME_ARMCHAIR_NEGATIVE_TESTS_PASS color position collision")
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
              "EMMA_PURPLE_CHAIR_NEGATIVE_TESTS_PASS",
              "EMMA_STORYTIME_ARMCHAIR_RUNTIME_PASS",
              "EMMA_STORYTIME_ARMCHAIR_ADVERSARIAL_REJECTED blue_repaint",
              "EMMA_STORYTIME_ARMCHAIR_ADVERSARIAL_REJECTED cushion_into_rug",
              "EMMA_STORYTIME_ARMCHAIR_NEGATIVE_TESTS_PASS")
    lines=result.stdout.splitlines()
    for marker in required:
        assert any(s.startswith(marker) for s in lines), marker
    for line in lines:
        if line.startswith(("EMMA_PURPLE_CHAIR_RUNTIME_PASS",
                            "EMMA_PURPLE_CHAIR_ADVERSARIAL_REJECTED",
                            "EMMA_PURPLE_CHAIR_NEGATIVE_TESTS_PASS",
                            "EMMA_STORYTIME_ARMCHAIR_RUNTIME_PASS",
                            "EMMA_STORYTIME_ARMCHAIR_ADVERSARIAL_REJECTED",
                            "EMMA_STORYTIME_ARMCHAIR_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)
if __name__=="__main__":
    main()
