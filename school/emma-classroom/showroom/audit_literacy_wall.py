#!/usr/bin/env python3
"""Runtime Luau validation of original classroom phonics/signage art."""
from __future__ import annotations
import argparse
import subprocess
import tempfile
from pathlib import Path
from export_source_scene import generate_luau

PROBE = r'''
local function collect(name)
    local all={}
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") and p.Name==name then table.insert(all,p) end
    end
    return all
end
local expected={"apple","ball","cat","dog","egg","fish","goat","hat",
    "igloo","jam","kite","leaf","moon","nest","owl","pig","queen",
    "rain","sun","tree","umbrella","violin","whale","x-ray","yarn","zebra"}
local function verify()
    local tiles=collect("Alphabet tile")
    assert(#tiles==26,"PHOTO_LITERACY_TILE_COUNT")
    table.sort(tiles,function(a,b) return a.Position.X<b.Position.X end)
    for i,tile in ipairs(tiles) do
        assert(tile.Anchored and not tile.CanCollide
            and math.abs(tile.Position.Y-13.4)<.02,
            "PHOTO_LITERACY_GEOMETRY")
        local g=tile:FindFirstChildOfClass("SurfaceGui")
        assert(g and g.Face==Enum.NormalId.Back,
            "PHOTO_LITERACY_FACE")
        local letter=g:FindFirstChild("PhonicsLetter")
        local word=g:FindFirstChild("PhonicsExample")
        local c=string.char(64+i)
        assert(letter and letter.Text==c..string.lower(c)
            and word and word.Text==expected[i],
            "PHOTO_LITERACY_CONTENT")
        assert(g.CanvasSize.X==260 and g.CanvasSize.Y==170,
            "PHOTO_LITERACY_READABILITY_CANVAS")
    end
    local banners=collect("Handwriting alphabet strip")
    assert(#banners==1 and banners[1].Size.X==29
        and math.abs(banners[1].Position.Y-15)<.02,
        "PHOTO_HANDWRITING_GEOMETRY")
    local surface=banners[1]:FindFirstChildOfClass("SurfaceGui")
    local lettering=surface and surface:FindFirstChild("HandwritingSequence")
    assert(lettering and lettering.Text==
        "a b c d e f g h i j k l m n o p q r s t u v w x y z"
        and lettering.Font==Enum.Font.Garamond,
        "PHOTO_HANDWRITING_CONTENT")
    assert(#collect("Student chair seat")==16
        and #collect("Student desk top")==16
        and #collect("Purple corner chair seat")==1,
        "PHOTO_LITERACY_DESKS_REGRESSION")
    return tiles[1],banners[1]
end
local tile,banner=verify()
print("PHOTO_LITERACY_RUNTIME_PASS phonics=26 handwriting=1 "
    .."source_only=true curriculum_authority=false")
local label=tile:FindFirstChildOfClass("SurfaceGui"):FindFirstChild("PhonicsExample")
local old=label.Text
label.Text="INCORRECT"
local ok,err=pcall(verify)
label.Text=old
assert(not ok and string.find(tostring(err),"PHOTO_LITERACY_CONTENT",1,true),
    "PHOTO_LITERACY_BAD_WORD_NOT_REJECTED")
print("PHOTO_LITERACY_ADVERSARIAL_REJECTED example")
local before=banner.CFrame
banner.CFrame=CFrame.new(0,3,-33.85)
ok,err=pcall(verify)
banner.CFrame=before
assert(not ok and string.find(tostring(err),"PHOTO_HANDWRITING_GEOMETRY",1,true),
    "PHOTO_LITERACY_BAD_BANNER_NOT_REJECTED")
verify()
print("PHOTO_LITERACY_NEGATIVE_TESTS_PASS example and banner")
'''
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    script=generate_luau()+"\n"+PROBE+"\n"
    with tempfile.TemporaryDirectory(prefix="emma-lit-") as tmp:
        p=Path(tmp)/"probe.lua"
        p.write_text(script,encoding="utf-8")
        run=subprocess.run([args.luau,str(p)],capture_output=True,text=True,
                           timeout=115,check=False)
    if run.returncode:
        raise RuntimeError("Constructed literacy audit failed:\n"
            +run.stderr[-3000:]+"\n"+run.stdout[-1500:])
    required=("PHOTO_LITERACY_RUNTIME_PASS",
      "PHOTO_LITERACY_ADVERSARIAL_REJECTED example",
      "PHOTO_LITERACY_NEGATIVE_TESTS_PASS")
    for marker in required:
        assert any(s.startswith(marker) for s in run.stdout.splitlines()),marker
    for row in run.stdout.splitlines():
        if row.startswith(("PHOTO_LITERACY_RUNTIME_PASS",
             "PHOTO_LITERACY_ADVERSARIAL_REJECTED",
             "PHOTO_LITERACY_NEGATIVE_TESTS_PASS")):
            print(row,flush=True)
if __name__=="__main__":
    main()
