#!/usr/bin/env python3
"""Fail closed on the owner-requested nine-photo polish and teacher badge fix.

This executes the real showroom constructors with pinned Luau. It proves source
geometry and native UI structure, not final Roblox/iPhone rendering quality.
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
        if p:IsA("BasePart") and p.Name==name then table.insert(out,p) end
    end
    return out
end
local function one(name)
    local found=parts(name)
    assert(#found==1,"OWNER_POLISH_COUNT_INVALID "..name.." "..#found)
    return found[1]
end
local function near(a,b,tolerance)
    return math.abs(a-b)<(tolerance or .035)
end
local function check()
    -- Round 3: move, do not duplicate, the reading banner; match the pair.
    assert(#parts("Cubbies label")==0,"READING_BANNER_OLD_LOCATION_REMAINED")
    local reading=one("Reading window banner")
    local faith=one("Classroom faith window banner")
    assert(near(reading.Position.Z,-19) and near(faith.Position.Z,6)
        and near(reading.Position.Y,faith.Position.Y)
        and near(reading.Size.X,faith.Size.X) and near(reading.Size.Y,faith.Size.Y)
        and near(reading.Size.Z,faith.Size.Z)
        and near(reading.Color.R,faith.Color.R) and near(reading.Color.G,faith.Color.G)
        and near(reading.Color.B,faith.Color.B),
        "WINDOW_BANNERS_NOT_MATCHED")
    local infill=one("Staff door upper gap infill")
    local header=one("Staff door header")
    assert(near(infill.Position.Y-infill.Size.Y/2,header.Position.Y+header.Size.Y/2)
        and near(infill.Position.Y+infill.Size.Y/2,13),"STAFF_HEADER_GAP")
    assert(#parts("Staff doorway exterior brick")==2
        and one("Staff doorway exterior brick header").Material==Enum.Material.Brick,
        "STAFF_EXTERIOR_FINISH_MISSING")
    -- Photo 1: no freestanding cabinet may obstruct the staff-door corner.
    assert(#parts("Tall storage cabinet")==0 and #parts("Cabinet door panel")==0,
        "OWNER_POLISH_OBSTRUCTING_CABINET_RETURNED")

    -- Photos 2/8: two flush, centered, mirrored supply-closet leaves.
    local leaves=parts("Closed classroom closet door")
    assert(#leaves==2 and #parts("Closet door center astragal")==1,
        "OWNER_POLISH_CLOSET_DOOR_ASSEMBLY_INVALID")
    table.sort(leaves,function(a,b) return a.Position.X<b.Position.X end)
    assert(near(leaves[1].Position.X,-2.55) and near(leaves[2].Position.X,2.55)
        and near(leaves[1].Position.Z,leaves[2].Position.Z)
        and leaves[1]:GetAttribute("ClosedSupplyClosetLeaf")==true
        and leaves[2]:GetAttribute("ClosedSupplyClosetLeaf")==true
        and #parts("Closet door raised panel stile")==4
        and #parts("Closet door raised panel rail")==4,
        "OWNER_POLISH_CLOSET_DOORS_NOT_FLUSH_OR_MIRRORED")

    -- Photo 3: clean white tissue and no striped wooden stationery board.
    local tissue=one("Folded tissue")
    assert(tissue.Color.R>.98 and tissue.Color.G>.98 and tissue.Color.B>.97,
        "OWNER_POLISH_TISSUE_COLOR_INVALID")
    assert(tissue.Material==Enum.Material.SmoothPlastic and tissue.CastShadow==false,
        "OWNER_POLISH_TISSUE_MUST_RENDER_CLEAN_WHITE")
    assert(#parts("Teacher desk wooden stationery tray")==0
        and #parts("Teacher wooden colored pencil")==0,
        "OWNER_POLISH_STRIPED_BOARD_RETURNED")

    -- Photos 5/6: every desk has four simple, separated supply zones.
    local desks=parts("Student desk top")
    local pages=parts("Ruled notebook page")
    local pencils=parts("Desk pencil")
    local erasers=parts("Desk eraser")
    local books={}
    for _,book in ipairs(parts("Classroom book")) do
        if book.Position.Y>3.10 and book.Position.Y<3.50 then
            table.insert(books,book)
        end
    end
    assert(#desks==16 and #pages==16 and #pencils==16
        and #erasers==16 and #books>=16,
        "OWNER_POLISH_DESK_SET_COUNT_INVALID desks="..#desks
        .." pages="..#pages.." pencils="..#pencils
        .." erasers="..#erasers.." books="..#books)
    assert(#parts("Supply basket")==0 and #parts("Basket long rim")==0
        and #parts("Basket end rim")==0 and #parts("Basket pencil")==0
        and #parts("Desk name strip")==0
        and #parts("Emma desk nameplate")==0
        and #parts("Emma pink water bottle")==0,
        "OWNER_POLISH_DESK_EXTRA_OBJECT_RETURNED")
    for _,desk in ipairs(desks) do
        local nearestPage,nearestPencil,nearestEraser,nearestBook=nil,nil,nil,nil
        local pageDistance,pencilDistance,eraserDistance,bookDistance=
            math.huge,math.huge,math.huge,math.huge
        for _,p in ipairs(pages) do
            local d=(p.Position.X-desk.Position.X)^2+(p.Position.Z-desk.Position.Z)^2
            if d<pageDistance then pageDistance=d nearestPage=p end
        end
        for _,p in ipairs(pencils) do
            local d=(p.Position.X-desk.Position.X)^2+(p.Position.Z-desk.Position.Z)^2
            if d<pencilDistance then pencilDistance=d nearestPencil=p end
        end
        for _,p in ipairs(erasers) do
            local d=(p.Position.X-desk.Position.X)^2+(p.Position.Z-desk.Position.Z)^2
            if d<eraserDistance then eraserDistance=d nearestEraser=p end
        end
        for _,p in ipairs(books) do
            local d=(p.Position.X-desk.Position.X)^2+(p.Position.Z-desk.Position.Z)^2
            if d<bookDistance then bookDistance=d nearestBook=p end
        end
        assert(nearestPage and nearestPencil and nearestEraser and nearestBook
            and nearestBook.Position.X<desk.Position.X-1.30
            and nearestBook.Position.Z>desk.Position.Z+.18
            and nearestPage.Position.X>desk.Position.X+.40
            and nearestPage.Position.Z<desk.Position.Z-.60
            and nearestPencil.Position.X>desk.Position.X+1.60
            and nearestPencil.Position.Z>desk.Position.Z+.30
            and nearestEraser.Position.X>desk.Position.X+1.60
            and nearestEraser.Position.Z<desk.Position.Z-.65,
            "OWNER_POLISH_DESK_ITEMS_OVERLAP")
    end

    -- Photo 6: every teaching-wall landmark shares x=0.
    for _,name in ipairs({"Main chalkboard","Interactive smartboard",
        "Smartboard white composite bezel",
        "Center chalkboard cross vertical","Center chalkboard cross horizontal"}) do
        assert(near(one(name).Position.X,0),"OWNER_POLISH_FRONT_WALL_NOT_CENTERED "..name)
    end
    local alphabet=parts("Alphabet tile")
    local sum=0
    assert(#alphabet==26,"OWNER_POLISH_ALPHABET_COUNT_INVALID")
    for _,tile in ipairs(alphabet) do sum+=tile.Position.X end
    assert(near(sum/#alphabet,0),"OWNER_POLISH_ALPHABET_NOT_CENTERED")

    -- Photo 7: three right-wall displays share height/center and equal gaps.
    local jobs=one("Jobs board frame")
    local kindness=one("ABVM classroom values oak surround")
    local word=one("Class notice board")
    assert(near(jobs.Position.Y,9.6) and near(kindness.Position.Y,9.6)
        and near(word.Position.Y,9.6)
        and near(jobs.Size.Y,7.05) and near(kindness.Size.Y,7.05)
        and near(word.Size.Y+.40,7.05),
        "OWNER_POLISH_RIGHT_WALL_HEIGHTS_INVALID")
    local gapA=(kindness.Position.Z-kindness.Size.Z/2)-(jobs.Position.Z+jobs.Size.Z/2)
    local gapB=(word.Position.Z-word.Size.Z/2-.20)-(kindness.Position.Z+kindness.Size.Z/2)
    assert(near(gapA,gapB,.06) and gapA>1.35,
        "OWNER_POLISH_RIGHT_WALL_SPACING_INVALID")
    local art=one("ABVM classroom values paper art")
    local gui=art:FindFirstChild("InWorldSignage")
    local rows=0
    if gui then
        for _,node in ipairs(gui:GetDescendants()) do
            if node.Name=="KindnessValueRow" then rows+=1 end
        end
    end
    assert(rows==4,"OWNER_POLISH_KINDNESS_POSTER_LOW_DETAIL")

    -- Photo 8: the closet and both decoration bands mirror around x=0.
    local leftStrip=one("Library counting strip backing")
    local rightStrip=one("Photo-guided cabinet counting strip")
    assert(near(leftStrip.Position.X,-rightStrip.Position.X)
        and near(leftStrip.Size.X,rightStrip.Size.X),
        "OWNER_POLISH_BACK_WALL_NOT_SYMMETRIC")
    local leftCards=parts("Photo-guided wall shape card")
    local rightCards=parts("Photo-guided right cabinet shape card")
    assert(#leftCards==9 and #rightCards==9,
        "OWNER_POLISH_BACK_WALL_CARD_COUNT_INVALID")
    table.sort(leftCards,function(a,b) return a.Position.X<b.Position.X end)
    table.sort(rightCards,function(a,b) return a.Position.X<b.Position.X end)
    for i=1,9 do
        assert(near(leftCards[i].Position.X,-rightCards[10-i].Position.X),
            "OWNER_POLISH_BACK_WALL_CARDS_NOT_MIRRORED")
    end

    -- Photo 9: the clock is the exact midpoint between equal window bays,
    -- and both decoration spans are equal and centered above their windows.
    local glass=parts("Window glass")
    assert(#glass==2,"OWNER_POLISH_WINDOW_COUNT_INVALID")
    table.sort(glass,function(a,b) return a.Position.Z<b.Position.Z end)
    local clock=one("Classroom wall clock")
    local faith=one("Classroom faith window banner")
    assert(near(clock.Position.Z,(glass[1].Position.Z+glass[2].Position.Z)/2)
        and near(faith.Position.Z,glass[2].Position.Z)
        and #parts("Smore classroom main title")==0
        and #parts("Smore faith headline")==0
        and #parts("Smore mural pine trunk")==0
        and #parts("Smore mural green canopy")==0,
        "OWNER_POLISH_WINDOW_WALL_NOT_SYMMETRIC")
    return one("Interactive smartboard")
end
local smart=check()
print("OWNER_POLISH_RUNTIME_PASS photos=8 desks=16 centered_walls=3 teacher_badge_source_separate=true")
local old=smart.CFrame
smart.CFrame=CFrame.new(1,smart.Position.Y,smart.Position.Z)
local ok,err=pcall(check)
smart.CFrame=old
assert(not ok and string.find(tostring(err),"OWNER_POLISH_FRONT_WALL_NOT_CENTERED",1,true),
    "OWNER_POLISH_CENTERLINE_MUTATION_NOT_REJECTED")
check()
print("OWNER_POLISH_NEGATIVE_PASS moved_smartboard_rejected=true")
'''


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau", required=True)
    args = parser.parse_args()
    staff = (Path(__file__).resolve().parents[1] / "server" / "StaffModel.lua").read_text()
    assert 'label.StudsOffset=Vector3.new(0,4.65,0)' in staff
    assert 'PlacementContract","Above hairline with clear visual gap"' in staff
    with tempfile.TemporaryDirectory(prefix="emma-owner-polish-") as folder:
        script = Path(folder) / "audit.luau"
        script.write_text(generate_luau() + "\n" + PROBE + "\n", encoding="utf-8")
        result = subprocess.run(
            [args.luau, str(script)], capture_output=True, text=True,
            timeout=115, check=False,
        )
    if result.returncode:
        raise RuntimeError("Owner polish audit failed:\n" + result.stderr[-3500:] + "\n" + result.stdout[-1800:])
    for marker in ("OWNER_POLISH_RUNTIME_PASS", "OWNER_POLISH_NEGATIVE_PASS"):
        assert any(line.startswith(marker) for line in result.stdout.splitlines()), marker
    for line in result.stdout.splitlines():
        if line.startswith("OWNER_POLISH_"):
            print(line, flush=True)


if __name__ == "__main__":
    main()
