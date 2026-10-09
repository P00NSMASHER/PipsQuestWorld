#!/usr/bin/env python3
"""Audit five actual Lua-constructed storybook GUI faces, no native rendering."""
from __future__ import annotations
import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
local function check()
    local covers={}
    local pages={}
    for _,v in ipairs(Room.Root:GetDescendants()) do
        if v:IsA("BasePart") then
            if v.Name=="Illustrated storybook cover" then
                table.insert(covers,v)
            elseif v.Name=="Storybook page edges" then
                table.insert(pages,v)
            end
        end
    end
    assert(#covers==5 and #pages==5,"STORYBOOK_COUNT_REGRESSION")
    local titles={}
    for _,cover in ipairs(covers) do
        local gui=cover:FindFirstChildOfClass("SurfaceGui")
        assert(gui~=nil and gui.Name=="Printed detail",
            "STORYBOOK_PRINTED_GUI_MISSING")
        assert(gui.Face==Enum.NormalId.Front,"STORYBOOK_FACE_REGRESSION")
        -- The source-derived math fixture uses row-major local frame;
        -- Front is local -Z, which must point to the player's +Z aisle.
        assert(cover.CFrame.m[9]<-.94,"STORYBOOK_WORLD_NORMAL_REVERSED")
        local label=gui:FindFirstChildOfClass("TextLabel")
        assert(label~=nil and #label.Text>2,
            "STORYBOOK_TITLE_MISSING")
        titles[label.Text]=true
        local page=nil
        for _,v in ipairs(pages) do
            if math.abs(v.Position.X-cover.Position.X)<.03 then
                page=v
                break
            end
        end
        assert(page~=nil,"STORYBOOK_PAGE_MISSING")
        assert(cover.Position.Z>page.Position.Z+.11,
            "STORYBOOK_WHITE_PAGES_IN_FRONT")
    end
    for _,name in ipairs({"SPACE","PETS","OCEAN","STARS","GARDEN"}) do
        assert(titles[name]==true,"STORYBOOK_TITLE_SET_REGRESSION")
    end
end
check()
print("STORYBOOK_FACING_RUNTIME_PASS covers=5 front=positive_Z "
    .."original_titles=5 page_backs_hidden=true")
local first=nil
for _,v in ipairs(Room.Root:GetDescendants()) do
    if v:IsA("BasePart") and v.Name=="Illustrated storybook cover" then
        first=v;break
    end
end
local gui=first:FindFirstChildOfClass("SurfaceGui")
local saved=gui.Face
gui.Face=Enum.NormalId.Back
local ok,err=pcall(check)
gui.Face=saved
assert(not ok and string.find(tostring(err),
    "STORYBOOK_FACE_REGRESSION",1,true),
    "STORYBOOK_NEGATIVE_CASE_NOT_REJECTED")
check()
print("STORYBOOK_FACING_NEGATIVE_PASS reverse_face_rejected=true")
'''

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    source=generate_luau()+"\n"+PROBE+"\n"
    with tempfile.TemporaryDirectory(prefix="emma-book-face-") as tmp:
        path=Path(tmp)/"check.lua"
        path.write_text(source,encoding="utf-8")
        result=subprocess.run([args.luau,str(path)],
            capture_output=True,text=True,timeout=115,check=False)
    if result.returncode:
        raise RuntimeError("Constructed Luau book-facing failure:\n"+
            result.stderr[-3500:]+"\n"+result.stdout[-1700:])
    for token in ("STORYBOOK_FACING_RUNTIME_PASS",
                  "STORYBOOK_FACING_NEGATIVE_PASS"):
        assert any(s.startswith(token) for s in result.stdout.splitlines()),token
    for line in result.stdout.splitlines():
        if line.startswith(("STORYBOOK_FACING_RUNTIME_PASS",
                            "STORYBOOK_FACING_NEGATIVE_PASS")):
            print(line,flush=True)

if __name__=="__main__":
    main()
