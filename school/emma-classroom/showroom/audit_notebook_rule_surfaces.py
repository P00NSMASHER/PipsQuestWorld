#!/usr/bin/env python3
"""Verify lightweight printed ruled paper in the actual classroom Luau.

The 16 desks retain a compact loose-paper sheet, while 64 invisible micro
Parts (three blue rules + red margin on each sheet) become normal Top
SurfaceGui Frames. This frees mobile geometry for real hallway displays and
keeps the paper separate from each desk's closed book.
The probe checks real assembly and mutation rejections, not a source grep.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import tempfile

from export_source_scene import generate_luau

PROBE=r'''
local pages={}
local disallowed={}
for _,p in ipairs(Room.Root:GetDescendants()) do
    if p:IsA("BasePart") then
        if p.Name=="Ruled notebook page" then
            table.insert(pages,p)
        elseif p.Name=="Notebook red margin"
            or p.Name=="Notebook ruled line" then
            table.insert(disallowed,p)
        end
    end
end
assert(#pages==16,"NOTEBOOK_PRINTED_PAGE_COUNT_LOST")
assert(#disallowed==0,"NOTEBOOK_MICRO_PARTS_NOT_REMOVED")
local function verify()
    for _,page in ipairs(pages) do
        assert(page.Material==Enum.Material.SmoothPlastic
            and not page.CanCollide and page.Size.X>1.2
            and page.Size.Z>1.0,
            "NOTEBOOK_PAPER_GEOMETRY_LOST")
        local gui=page:FindFirstChild("OriginalNotebookPaperRules")
        assert(gui and gui:IsA("SurfaceGui")
            and gui.Face==Enum.NormalId.Top
            and gui.LightInfluence<.20,
            "NOTEBOOK_PRINTED_TOP_RULES_MISSING")
        local blue=0
        local margin=0
        for _,c in ipairs(gui:GetChildren()) do
            if c.Name=="NotebookPrintedBlueRule" then
                blue+=1
                assert(c.BackgroundTransparency<.20
                    and c.BackgroundColor3.B>c.BackgroundColor3.R,
                    "NOTEBOOK_PRINTED_BLUE_RULE_COLOR_LOST")
            elseif c.Name=="NotebookPrintedRedMargin" then
                margin+=1
                assert(c.BackgroundColor3.R>c.BackgroundColor3.G
                    and c.Size[1]>.005 and c.Size[1]<.02,
                    "NOTEBOOK_PRINTED_RED_MARGIN_LOST")
            else
                error("NOTEBOOK_UNEXPECTED_STUDENT_CONTENT")
            end
        end
        assert(blue==3 and margin==1,
            "NOTEBOOK_PRINTED_RULE_OR_MARGIN_COUNT")
    end
end
verify()
local gui=pages[1]:FindFirstChild("OriginalNotebookPaperRules")
local prior=gui.Face
gui.Face=Enum.NormalId.Front
local ok,err=pcall(verify)
gui.Face=prior
assert(not ok and string.find(tostring(err),
    "NOTEBOOK_PRINTED_TOP_RULES_MISSING",1,true),
    "NOTEBOOK_PRINTED_FACE_NEGATIVE_NOT_REJECTED")
print("NOTEBOOK_PRINTED_NEGATIVE_REJECTED wrong_face")
local before=pages[1].CanCollide
pages[1].CanCollide=true
ok,err=pcall(verify)
pages[1].CanCollide=before
assert(not ok and string.find(tostring(err),
    "NOTEBOOK_PAPER_GEOMETRY_LOST",1,true),
    "NOTEBOOK_PRINTED_COLLISION_NEGATIVE_NOT_REJECTED")
print("NOTEBOOK_PRINTED_NEGATIVE_REJECTED collision")
verify()
print("NOTEBOOK_PRINTED_RUNTIME_PASS pages=16 rules=48 "
    .."red_margins=16 physical_marking_parts=0 "
    .."parts_saved=64 compact_loose_paper=true")
'''


def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    options=parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="notebook-surface-") as tmp:
        file=Path(tmp)/"probe.lua"
        file.write_text(generate_luau()+"\n"+PROBE,encoding="utf-8")
        proc=subprocess.run(
            [options.luau,str(file)],
            capture_output=True,text=True,timeout=115
        )
    if proc.returncode:
        raise RuntimeError(
            "Actual shipped notebook constructor regression:\n"
            +proc.stderr[-3000:]+"\n"+proc.stdout[-1500:]
        )
    for marker in (
        "NOTEBOOK_PRINTED_NEGATIVE_REJECTED wrong_face",
        "NOTEBOOK_PRINTED_NEGATIVE_REJECTED collision",
        "NOTEBOOK_PRINTED_RUNTIME_PASS",
    ):
        assert marker in proc.stdout, "Missing required notebook probe: "+marker
    for row in proc.stdout.splitlines():
        if row.startswith("NOTEBOOK_PRINTED_"):
            print(row,flush=True)

if __name__=="__main__":
    main()
