#!/usr/bin/env python3
"""Constructed source native-photo guard for the photographed classroom word wall.

The school event photos are used only for architectural/color reference; no
people or photos are shipped. Luau geometry checks are NOT native visual QA.
"""
from __future__ import annotations
import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
local function parts(name)
    local result={}
    for _,part in ipairs(Room.Root:GetDescendants()) do
        if part:IsA("BasePart") and part.Name==name then
            table.insert(result,part)
        end
    end
    return result
end
local function check()
    local board=parts("Class notice board")
    assert(#board==1,"PHOTO_WORD_WALL_BOARD_COUNT_INVALID")
    board=board[1]
    assert(board.Material==Enum.Material.SmoothPlastic
        and board.Color.R>.45 and board.Color.G>.64
        and board.Color.B>.78 and board.Color.B>board.Color.R
        and not board.CanCollide and board.Anchored,
        "PHOTO_WORD_WALL_BLUE_MATERIAL_INVALID")
    local title=parts("Photo word wall title paper art")
    assert(#title==1,"PHOTO_WORD_WALL_TITLE_COUNT_INVALID")
    title=title[1]
    local titleFrame=title:FindFirstChildOfClass("SurfaceGui")
    local titleBackground=titleFrame and titleFrame:FindFirstChildOfClass("Frame")
    local heading=titleBackground and titleBackground:FindFirstChild("DecorativeHeading")
    assert(title.Color.G>.76 and title.Color.G>title.Color.R
        and title.Color.G>title.Color.B
        and title.Material==Enum.Material.SmoothPlastic
        and math.abs(title.Position.Y-11.48)<.03
        and math.abs(title.Position.Z-board.Position.Z)<.03
        and title.Position.Y>board.Position.Y+board.Size.Y/2
        and math.abs(title.Size.Z-5.4)<.03
        and math.abs(title.Size.Y-1.20)<.03,
        "PHOTO_WORD_WALL_TITLE_GEOMETRY_INVALID")
    assert(titleFrame and titleFrame.Face==Enum.NormalId.Left
        and heading and heading.Text=="FIRST GRADE\nWORD WALL",
        "PHOTO_WORD_WALL_TITLE_TEXT_INVALID")
    local markers=parts("Word wall apple")
    local stems=parts("Word wall apple stem")
    assert(#markers==26 and #stems==26,
        "PHOTO_WORD_WALL_ALPHABET_COUNT_INVALID")
    local found={}
    local rows={}
    for _,p in ipairs(markers) do
        assert(p.Shape==Enum.PartType.Cylinder
            and p.Size.X<.10 and p.Size.Y>=.42 and p.Size.Z>=.42
            and p.Anchored and not p.CanCollide
            and not p.CanTouch and not p.CanQuery,
            "PHOTO_WORD_WALL_NATIVE_APPLE_SHAPE_INVALID")
        assert(math.abs(p.Position.X-35.91)<.05
            and p.Position.Z>-4.10 and p.Position.Z<5.75,
            "PHOTO_WORD_WALL_APPLE_OUTSIDE_BOARD")
        local gui=p:FindFirstChildOfClass("SurfaceGui")
        assert(gui and gui.Face==Enum.NormalId.Left,
            "PHOTO_WORD_WALL_APPLE_TEXT_FACE_INVALID")
        local frame=gui:FindFirstChildOfClass("Frame")
        local heading=frame and frame:FindFirstChild("DecorativeHeading")
        assert(heading and #heading.Text==1,
            "PHOTO_WORD_WALL_MISSING_APPLE_LETTER")
        assert(not found[heading.Text],"PHOTO_WORD_WALL_DUPLICATE_LETTER")
        found[heading.Text]=true
        local row=(p.Position.Y>8) and "upper" or "lower"
        rows[row]=(rows[row] or 0)+1
    end
    assert(rows.upper==13 and rows.lower==13,
        "PHOTO_WORD_WALL_WRONG_APPLE_ROWS")
    for i=65,90 do
        assert(found[string.char(i)],"PHOTO_WORD_WALL_MISSING_LETTER")
    end
    assert(#parts("Word wall word card")==15
        and #parts("Window glass")==2
        and #parts("Student desk top")==16,
        "PHOTO_WORD_WALL_CLASSROOM_REGRESSION")
    return board,markers
end
local board,markers=check()
print("PHOTO_WORD_WALL_RUNTIME_PASS blue_smooth=true "
    .."native_cylinder_apples=26 rows=2 no_collisions=true ")
local material=board.Material
board.Material=Enum.Material.Fabric
local ok,err=pcall(check)
board.Material=material
assert(not ok and string.find(tostring(err),
    "PHOTO_WORD_WALL_BLUE_MATERIAL_INVALID",1,true),
    "PHOTO_WORD_WALL_FABRIC_REGRESSION_NOT_REJECTED")
print("PHOTO_WORD_WALL_ADVERSARIAL_REJECTED fabric_backing")
local shape=markers[1].Shape
markers[1].Shape=Enum.PartType.Ball
ok,err=pcall(check)
markers[1].Shape=shape
assert(not ok and string.find(tostring(err),
    "PHOTO_WORD_WALL_NATIVE_APPLE_SHAPE_INVALID",1,true),
    "PHOTO_WORD_WALL_FLATTENED_BALL_NOT_REJECTED")
print("PHOTO_WORD_WALL_ADVERSARIAL_REJECTED flattened_ball")
local sign=parts("Photo word wall title paper art")[1]
local gui=sign:FindFirstChildOfClass("SurfaceGui")
local layer=gui:FindFirstChildOfClass("Frame")
local headline=layer:FindFirstChild("DecorativeHeading")
local oldText=headline.Text
headline.Text="WELCOME"
ok,err=pcall(check)
headline.Text=oldText
assert(not ok and string.find(tostring(err),
    "PHOTO_WORD_WALL_TITLE_TEXT_INVALID",1,true),
    "PHOTO_WORD_WALL_GENERIC_TITLE_NOT_REJECTED")
print("PHOTO_WORD_WALL_ADVERSARIAL_REJECTED generic_heading")
check()
print("PHOTO_WORD_WALL_NEGATIVE_TESTS_PASS material shape heading")
'''
def main() -> None:
    p=argparse.ArgumentParser()
    p.add_argument("--luau",required=True)
    args=p.parse_args()
    with tempfile.TemporaryDirectory(prefix="emma-wordwall-") as tmp:
        file=Path(tmp)/"audit.lua"
        file.write_text(generate_luau()+"\n"+PROBE+"\n",encoding="utf-8")
        result=subprocess.run([args.luau,str(file)],capture_output=True,
            text=True,timeout=115,check=False)
    if result.returncode:
        raise RuntimeError("Constructed word-wall QA failed:\n"
            +result.stderr[-3200:]+"\n"+result.stdout[-2500:])
    for marker in ("PHOTO_WORD_WALL_RUNTIME_PASS",
                   "PHOTO_WORD_WALL_ADVERSARIAL_REJECTED fabric_backing",
                   "PHOTO_WORD_WALL_ADVERSARIAL_REJECTED flattened_ball",
                   "PHOTO_WORD_WALL_ADVERSARIAL_REJECTED generic_heading",
                   "PHOTO_WORD_WALL_NEGATIVE_TESTS_PASS"):
        assert any(x.startswith(marker) for x in result.stdout.splitlines()),marker
    for line in result.stdout.splitlines():
        if line.startswith(("PHOTO_WORD_WALL_RUNTIME_PASS",
                            "PHOTO_WORD_WALL_ADVERSARIAL_REJECTED",
                            "PHOTO_WORD_WALL_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)
if __name__=="__main__":
    main()
