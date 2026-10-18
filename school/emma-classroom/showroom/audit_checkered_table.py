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
    local warp,weft=0,0
    for _,child in ipairs(bg:GetChildren()) do
        assert(child.Name~="GinghamRed","GINGHAM_FLAT_CHECKERBOARD_RETURNED")
        if child.Name=="GinghamWarp" or child.Name=="GinghamWeft" then
            assert(child:IsA("Frame"),"GINGHAM_STRIPE_TYPE_INVALID")
            local c=child.BackgroundColor3
            assert(c.R>.63 and c.R<.75 and c.G<.29 and c.B<.30,
                "GINGHAM_CHECK_COLOR_INVALID")
            assert(math.abs(child.BackgroundTransparency-.42)<.001,
                "GINGHAM_WEAVE_OPACITY_INVALID")
            if child.Name=="GinghamWarp" then
                assert(math.abs(child.Size[1]-1/columns)<.001
                    and child.Size[2]==1
                    and math.abs(child.Position[1]-warp*2/columns)<.001
                    and child.Position[2]==0,"GINGHAM_WARP_SPACING_INVALID")
                warp+=1
            else
                assert(child.Size[1]==1
                    and math.abs(child.Size[2]-1/rows)<.001
                    and child.Position[1]==0
                    and math.abs(child.Position[2]-weft*2/rows)<.001,
                    "GINGHAM_WEFT_SPACING_INVALID")
                weft+=1
            end
        end
    end
    assert(warp==math.ceil(columns/2) and weft==math.ceil(rows/2),
        "GINGHAM_WEAVE_STRIPE_COUNT_INVALID "..p.Name)
    -- Check scale continuity between desktop and hanging aprons.
    local w=(face==Enum.NormalId.Left or face==Enum.NormalId.Right)
        and p.Size.Z or p.Size.X
    local h=(face==Enum.NormalId.Top) and p.Size.Z or p.Size.Y
    assert(w/columns>.30 and w/columns<.36
        and h/rows>.30 and h/rows<.36,"GINGHAM_CHECK_SCALE_INVALID")
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
    -- The enlarged blue board now extends from z=-11.5 to +6.5.
    -- The table remains deliberately OFFSET toward the staff-door side,
    -- still entirely under that photographed board, without shifting any
    -- desk, doorway or teacher circulation.
    assert(top.Position.X+top.Size.X/2<36.0
        and math.abs(top.Position.Z-wall.Position.Z-3.375)<.03
        and math.abs(top.Position.X-wall.Position.X)<3.4
        and top.Position.Z-top.Size.Z/2>wall.Position.Z-wall.Size.Z/2
        and top.Position.Z+top.Size.Z/2<wall.Position.Z+wall.Size.Z/2,
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
    pattern(top,Enum.NormalId.Top,12,22)
    for _,spec in ipairs({
        {"Photo gingham table aisle apron",Enum.NormalId.Left,22,4},
        {"Photo gingham table wall apron",Enum.NormalId.Right,22,4},
        {"Photo gingham table near apron",Enum.NormalId.Front,12,4},
        {"Photo gingham table far apron",Enum.NormalId.Back,12,4},
    }) do
        local apron=only(spec[1])
        assert(apron.Anchored and not apron.CanCollide and
            not apron.CanTouch and not apron.CanQuery,
            "GINGHAM_APRON_COLLISION_INVALID")
        pattern(apron,spec[2],spec[3],spec[4])
    end
    -- All the authored red edging stays on the table, not in the aisle.
    -- Decorative geometry is explicitly excluded from touch/raycast work.
    local piping=parts("Photo gingham stitched piping")
    local hems=parts("Photo gingham sewn apron hem")
    assert(#piping==4 and #hems==2,
        "GINGHAM_STITCHED_EDGE_COUNT_INVALID")
    for _,detail in ipairs(piping) do
        assert(detail.Anchored and not detail.CanCollide
            and not detail.CanTouch and not detail.CanQuery
            and detail.Material==Enum.Material.Fabric
            and math.abs(detail.Position.Y-top.Position.Y)<.01
            and math.abs(detail.Position.X-top.Position.X)<2.15
            and math.abs(detail.Position.Z-top.Position.Z)<3.85,
            "GINGHAM_STITCHED_PIPING_INVALID")
    end
    for _,detail in ipairs(hems) do
        assert(detail.Anchored and not detail.CanCollide
            and not detail.CanTouch and not detail.CanQuery
            and detail.Material==Enum.Material.Fabric
            and math.abs(detail.Position.Y-1.61)<.01,
            "GINGHAM_APRON_HEM_INVALID")
    end
    local note=only("Teacher note paper")
    local notesGui=note:FindFirstChild("TeacherNoteRules")
    assert(notesGui and notesGui:IsA("SurfaceGui")
        and notesGui.Face==Enum.NormalId.Top
        and #parts("Teacher note ruled line")==0,
        "TEACHER_NOTE_MICROPARTS_RETURNED")
    local lines=0
    for _,child in ipairs(notesGui:GetChildren()) do
        if child.Name=="TeacherNoteRule" and child:IsA("Frame") then
            lines+=1
            assert(child.BackgroundColor3.B>.48,
                "TEACHER_NOTE_INK_COLOR_INVALID")
        end
    end
    assert(lines==4,"TEACHER_NOTE_VISIBLE_RULE_COUNT_INVALID")
    local floor=only("Warm oak classroom floor")
    assert(floor.CanCollide and floor.CanQuery,
        "ROOM_ARCHITECTURAL_COLLIDER_NOT_QUERYABLE")
    local grid=parts("Ceiling grid line")
    assert(#grid==5,"ROOM_CEILING_GRID_REGRESSION")
    for _,detail in ipairs(grid) do
        assert(not detail.CanCollide and not detail.CanTouch
            and not detail.CanQuery,"ROOM_DECORATIVE_QUERY_INVALID")
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
        and #parts("Purple comfy chair seat cushion")==1
        and #parts("Purple corner chair seat")==0
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
local piping=parts("Photo gingham stitched piping")[1]
piping.CanQuery=true
local rejected,why=pcall(verify)
piping.CanQuery=false
assert(not rejected and string.find(tostring(why),
    "GINGHAM_STITCHED_PIPING_INVALID",1,true),
    "GINGHAM_STITCHED_PIPING_RAYCAST_MUTATION_FALSE_ACCEPT")
local grid=parts("Ceiling grid line")[1]
grid.CanQuery=true
rejected,why=pcall(verify)
grid.CanQuery=false
assert(not rejected and string.find(tostring(why),
    "ROOM_DECORATIVE_QUERY_INVALID",1,true),
    "ROOM_DECORATIVE_RAYCAST_MUTATION_FALSE_ACCEPT")
print("GINGHAM_TABLE_ADVERSARIAL_REJECTED decorative_raycast_queries")
local apron=only("Photo gingham table aisle apron")
local oldFace=apron:FindFirstChild("PhotoGingham").Face
apron:FindFirstChild("PhotoGingham").Face=Enum.NormalId.Top
ok,err=pcall(verify)
apron:FindFirstChild("PhotoGingham").Face=oldFace
assert(not ok and string.find(tostring(err),
    "GINGHAM_NATIVE_GUI_MISSING",1,true),
    "GINGHAM_MISSING_APRON_FACE_NOT_REJECTED")
print("GINGHAM_TABLE_ADVERSARIAL_REJECTED wrong_facing_apron")
local bg=top:FindFirstChild("PhotoGingham"):FindFirstChild("GinghamIvory")
local warp=bg:FindFirstChild("GinghamWarp")
warp.BackgroundTransparency=0
ok,err=pcall(verify)
warp.BackgroundTransparency=.42
assert(not ok and string.find(tostring(err),"GINGHAM_WEAVE_OPACITY_INVALID",1,true),
    "GINGHAM_OPAQUE_CHECKER_FALSE_ACCEPT")
local weft=bg:FindFirstChild("GinghamWeft")
weft.Parent=nil
ok,err=pcall(verify)
weft.Parent=bg
assert(not ok,"GINGHAM_LOST_WEFT_FALSE_ACCEPT")
-- Restore child ordering used by the deterministic stripe-spacing check.
for _,child in ipairs(bg:GetChildren()) do
    if child.Name=="GinghamWeft" and child~=weft then
        child.Parent=nil;child.Parent=bg
    end
end
print("GINGHAM_TABLE_ADVERSARIAL_REJECTED opaque_or_missing_weave")
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
        "GINGHAM_TABLE_ADVERSARIAL_REJECTED decorative_raycast_queries",
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

