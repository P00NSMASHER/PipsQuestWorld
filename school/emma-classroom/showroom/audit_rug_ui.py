#!/usr/bin/env python3
"""Inspect actual constructed classroom SurfaceGuis, without publishing.

Runs the same original Luau Room/Gallery constructor and math/Instance
fixtures as export_source_scene.py. Tests constructed UI properties that the
static 3D image renderer cannot represent (not pixel legibility on iPhone).
No gameplay, network, Studio, secrets, or real student records are used.
"""
from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

from export_source_scene import generate_luau

RUG_GUI_PROBE = r'''
local function getRugParts()
    local letters={}
    local clouds={}
    local ordinaryBanner=nil
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p:IsA("BasePart") then
            if p.Name=="Reading rug alphabet border" then
                table.insert(letters,p)
            elseif p.Name=="Photo rug number cloud numeral" then
                table.insert(clouds,p)
            elseif p.Name=="Classroom faith window banner" then
                ordinaryBanner=p
            end
        end
    end
    return letters,clouds,ordinaryBanner
end

local function inspectOne(part,cloud)
    local gui=part:FindFirstChildOfClass("SurfaceGui")
    assert(gui~=nil and gui.Name=="Surface",
        "RUG_SURFACE_MISSING "..part.Name)
    assert(gui.Face==Enum.NormalId.Top,
        "RUG_FACE_INVALID "..part.Name)
    assert(gui.CanvasSize[1]==180 and gui.CanvasSize[2]==120,
        "RUG_CANVAS_INVALID "..part.Name)
    assert(gui.SizingMode==Enum.SurfaceGuiSizingMode.FixedSize,
        "RUG_SIZING_INVALID "..part.Name)
    assert(gui.LightInfluence==0,
        "RUG_LIGHT_INFLUENCE_INVALID "..part.Name)
    local text=gui:FindFirstChildOfClass("TextLabel")
    assert(text~=nil,"RUG_LABEL_MISSING "..part.Name)
    assert(text.TextScaled==false and text.TextWrapped==false,
        "RUG_TEXT_SCALING_INVALID "..part.Name)
    assert(text.TextSize==(cloud and 104 or 92),
        "RUG_FONT_SIZE_INVALID "..part.Name)
    assert(text.Font==Enum.Font.GothamBold,
        "RUG_FONT_INVALID "..part.Name)
    assert(text.TextStrokeTransparency<=.46,
        "RUG_STROKE_INVALID "..part.Name)
    local padding=text:FindFirstChildOfClass("UIPadding")
    assert(padding~=nil and
        padding.PaddingLeft[2]==4 and padding.PaddingRight[2]==4 and
        padding.PaddingTop[2]==2 and padding.PaddingBottom[2]==2,
        "RUG_PADDING_INVALID "..part.Name)
    if cloud then
        assert(part.Transparency>=.99 and
            text.BackgroundTransparency==1,
            "RUG_CLOUD_ANCHOR_OPAQUE")
        assert(text.TextSize==104 and #text.Text>=1,
            "RUG_NUMBER_CONTENT_INVALID")
        assert(text.TextColor3.R<.10 and text.TextColor3.B<.36,
            "RUG_NUMERAL_CONTRAST_INVALID")
    else
        assert(text.BackgroundTransparency<=.05,
            "RUG_LETTER_BACKGROUND_INVALID")
        assert(#text.Text==1,
            "RUG_LETTER_CONTENT_INVALID")
    end
    assert(part.CanCollide==false and part.CanTouch==false,
        "RUG_DECORATIVE_COLLISION_INVALID "..part.Name)
    return gui,text
end

local function audit()
    local letterParts,cloudParts,banner=getRugParts()
    assert(#letterParts==26 and #cloudParts==10,
        "RUG_UI_COUNTS_INVALID")
    local letters,numbers={},{}
    for _,p in ipairs(letterParts) do
        local _,label=inspectOne(p,false)
        table.insert(letters,label.Text)
    end
    for _,p in ipairs(cloudParts) do
        local _,label=inspectOne(p,true)
        assert(tonumber(label.Text)~=nil,
            "RUG_NUMBER_CONTENT_INVALID")
        table.insert(numbers,label.Text)
    end
    table.sort(letters)
    table.sort(numbers,function(a,b) return tonumber(a)<tonumber(b) end)
    assert(table.concat(letters)=="ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "RUG_ALPHABET_CONTENT_INVALID")
    assert(table.concat(numbers,",")=="1,2,3,4,5,6,7,8,9,10",
        "RUG_NUMBER_CONTENT_INVALID")
    -- Carpet labels use special phone-scale rules. All other signs must
    -- retain the original global CanvasSize / TextScaled behavior.
    assert(banner~=nil,"RUG_GENERIC_SIGN_MISSING")
    local gui=banner:FindFirstChildOfClass("SurfaceGui")
    local lbl=gui and gui:FindFirstChildOfClass("TextLabel")
    assert(gui and gui.CanvasSize[1]==1000 and lbl
        and lbl.TextScaled==true,
        "RUG_GENERIC_SIGN_REGRESSION")
    return letterParts,cloudParts
end

local alphabet,clouds=audit()
print("RUG_UI_RUNTIME_PASS alphabet=26 clouds=10 canvas=180x120"
    .." letter_size=92 numeral_size=104 cloud_anchors_transparent=10"
    .." ordinary_signs_unchanged=true")
local firstLetter=alphabet[1]
local firstCloud=clouds[1]
local alphabetGui=firstLetter:FindFirstChildOfClass("SurfaceGui")
local alphabetLabel=alphabetGui:FindFirstChildOfClass("TextLabel")
local cloudGui=firstCloud:FindFirstChildOfClass("SurfaceGui")
local cloudLabel=cloudGui:FindFirstChildOfClass("TextLabel")
local function expectRejected(label,code,change,restore)
    change()
    local ok,err=pcall(audit)
    restore()
    assert(not ok and string.find(tostring(err),code,1,true),
        "RUG_NEGATIVE_CASE_NOT_REJECTED "..label.." "..tostring(err))
    print("RUG_UI_ADVERSARIAL_REJECTED "..label)
end
local originalFont=alphabetLabel.TextSize
expectRejected("tiny_font","RUG_FONT_SIZE_INVALID",
    function() alphabetLabel.TextSize=10 end,
    function() alphabetLabel.TextSize=originalFont end)
local originalCanvas=alphabetGui.CanvasSize
expectRejected("oversized_canvas","RUG_CANVAS_INVALID",
    function() alphabetGui.CanvasSize=Vector2.new(1000,600) end,
    function() alphabetGui.CanvasSize=originalCanvas end)
local originalCloudAlpha=firstCloud.Transparency
expectRejected("white_sticker","RUG_CLOUD_ANCHOR_OPAQUE",
    function() firstCloud.Transparency=0 end,
    function() firstCloud.Transparency=originalCloudAlpha end)
local originalText=cloudLabel.Text
expectRejected("missing_number","RUG_NUMBER_CONTENT_INVALID",
    function() cloudLabel.Text="" end,
    function() cloudLabel.Text=originalText end)
audit()
print("RUG_UI_NEGATIVE_TESTS_PASS font_size canvas_size cloud_backing missing_number")
'''

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau", required=True)
    args = parser.parse_args()
    source = generate_luau() + "\n" + RUG_GUI_PROBE + "\n"
    with tempfile.TemporaryDirectory(prefix="emma-rug-ui-") as folder:
        path = Path(folder) / "audit.lua"
        path.write_text(source, encoding="utf-8")
        result = subprocess.run(
            [args.luau, str(path)],
            capture_output=True, text=True, timeout=115, check=False
        )
    if result.returncode:
        raise RuntimeError(
            "Constructed carpet GUI audit failed:\n"
            + result.stderr[-3500:] + "\n" + result.stdout[-1800:]
        )
    lines = result.stdout.splitlines()
    required = (
        "RUG_UI_RUNTIME_PASS alphabet=26 clouds=10 canvas=180x120",
        "RUG_UI_ADVERSARIAL_REJECTED tiny_font",
        "RUG_UI_ADVERSARIAL_REJECTED oversized_canvas",
        "RUG_UI_ADVERSARIAL_REJECTED white_sticker",
        "RUG_UI_ADVERSARIAL_REJECTED missing_number",
        "RUG_UI_NEGATIVE_TESTS_PASS font_size canvas_size cloud_backing missing_number",
    )
    for item in required:
        assert any(line.startswith(item) for line in lines), (
            "Expected runtime/negative-test evidence absent: " + item
        )
    assert any(line.startswith("SCENE_COUNT|") for line in lines), (
        "The source-only fixture did not construct the actual room"
    )
    for line in lines:
        if line.startswith(("RUG_UI_RUNTIME_PASS", "RUG_UI_ADVERSARIAL_REJECTED",
                            "RUG_UI_NEGATIVE_TESTS_PASS")):
            print(line, flush=True)

if __name__ == "__main__":
    try:
        main()
    except (AssertionError, RuntimeError, subprocess.TimeoutExpired) as exc:
        print("RUG_UI_AUDIT_FAIL", str(exc), file=sys.stderr, flush=True)
        raise SystemExit(1)
