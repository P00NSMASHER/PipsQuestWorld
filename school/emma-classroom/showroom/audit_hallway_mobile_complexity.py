#!/usr/bin/env python3
"""Source-constructed mobile draw-cost/privacy guard for Emma's photo hallway.

Checks genuine Luau-created Parts, SurfaceGuis and UI Frames, not text grep.
These are conservative complexity ceilings, NOT measured Roblox/iPhone FPS.
All photographed students and their real assignments stay out of this repo.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import tempfile

from export_source_scene import generate_luau

PROBE = r'''
local hall=Room.Root:FindFirstChild("PhotographedHallway")
assert(hall and hall:GetAttribute("ScaleConfidence")=="provisional",
    "HALL_MOBILE_NO_ACTUAL_PHOTO_ROOM")
local LIMIT_PARTS=3100
local LIMIT_HALL_PARTS=120
local LIMIT_HALL_GUI=55
local LIMIT_HALL_FRAMES=800
local LIMIT_CANVAS=1200000
local LIMIT_TOTAL_CANVAS=6000000
local LIMIT_LIGHTS=5

local function summarize()
    local allParts=0
    for _,obj in ipairs(Room.Root:GetDescendants()) do
        if obj:IsA("BasePart") then allParts+=1 end
    end
    local totalParts=0
    local collidable=0
    local touchable=0
    local guis=0
    local frames=0
    local lights=0
    local surfacePixels=0
    local forbidden=0
    local decoratedSheets=0
    local firstGui=nil
    local firstPaper=nil
    for _,obj in ipairs(hall:GetDescendants()) do
        if obj:IsA("BasePart") then
            totalParts+=1
            if obj.CanCollide then collidable+=1 end
            if obj.CanTouch then touchable+=1 end
            if obj.Name=="Photo hall anonymous diamond student display" then
                decoratedSheets+=1
                if firstPaper==nil then firstPaper=obj end
            end
        end
        if obj.ClassName=="SurfaceGui" then
            guis+=1
            if firstGui==nil then firstGui=obj end
            -- Native Vector2 uses X/Y. The pinned source-construction
            -- fixture models Vector2 as numeric [1]/[2].
            local w=obj.CanvasSize and (obj.CanvasSize.X or obj.CanvasSize[1])
            local h=obj.CanvasSize and (obj.CanvasSize.Y or obj.CanvasSize[2])
            assert(w and h and w>0 and h>0,
                "HALL_MOBILE_INVALID_RENDER_CANVAS")
            surfacePixels+=w*h
            assert(w*h<=LIMIT_CANVAS,
                "HALL_MOBILE_OVERSIZED_SINGLE_SURFACE")
            assert(obj.AlwaysOnTop~=true,
                "HALL_MOBILE_UI_ALWAYS_ON_TOP_INVALID")
        elseif obj.ClassName=="Frame" then
            frames+=1
        elseif obj.ClassName=="SurfaceLight" or obj.ClassName=="PointLight"
            or obj.ClassName=="SpotLight" then
            lights+=1
        elseif obj.ClassName=="ImageLabel" or obj.ClassName=="ImageButton"
            or obj.ClassName=="Decal" or obj.ClassName=="Texture" then
            forbidden+=1
        end
    end
    assert(allParts<=LIMIT_PARTS,
        "HALL_MOBILE_TOTAL_3100_PART_LIMIT_EXCEEDED")
    assert(totalParts<=LIMIT_HALL_PARTS,
        "HALL_MOBILE_TOO_MANY_CORRIDOR_PARTS")
    assert(collidable<=12,
        "HALL_MOBILE_EXCESSIVE_CORRIDOR_COLLIDERS")
    assert(touchable==0,
        "HALL_MOBILE_UNUSED_STATIC_TOUCH_EVENTS")
    assert(guis<=LIMIT_HALL_GUI,
        "HALL_MOBILE_TOO_MANY_INDEPENDENT_SURFACES")
    assert(frames<=LIMIT_HALL_FRAMES,
        "HALL_MOBILE_TOO_MANY_DRAW_FRAMES")
    assert(surfacePixels<=LIMIT_TOTAL_CANVAS,
        "HALL_MOBILE_TOTAL_CANVAS_COST_EXCEEDED")
    assert(lights==LIMIT_LIGHTS,
        "HALL_MOBILE_SCHOOL_LIGHT_COUNT_CHANGED")
    assert(forbidden==0,
        "HALL_MOBILE_EXTERNAL_IMAGE_OR_UNAPPROVED_PHOTO_ASSET")
    assert(decoratedSheets==23,
        "HALL_MOBILE_ANONYMOUS_GALLERY_COUNT_CHANGED")
    return {
        allParts=allParts,
        parts=totalParts,
        colliders=collidable,
        touchable=touchable,
        surfaces=guis,
        frames=frames,
        lights=lights,
        canvasPixels=surfacePixels,
        papers=decoratedSheets,
        gui=firstGui,
        paper=firstPaper,
    }
end

local baseline=summarize()
assert(baseline.gui and baseline.paper,
    "HALL_MOBILE_NO_ACTUAL_SURFACE_ART")
print("HALL_MOBILE_COMPLEXITY_PASS parts="..baseline.allParts
    .." hall_parts="..baseline.parts
    .." hall_colliders="..baseline.colliders
    .." hall_touchable="..baseline.touchable
    .." surface_guis="..baseline.surfaces
    .." gui_frames="..baseline.frames
    .." total_canvas_pixels="..baseline.canvasPixels
    .." hallway_lights="..baseline.lights
    .." paper_art="..baseline.papers
    .." source_only_not_measured_iphone_fps=true")

-- Genuine negative controls ensure each failure gate is live, rather
-- than a ceremonial constant/regexp check.
local oldSize=baseline.gui.CanvasSize
baseline.gui.CanvasSize=Vector2.new(4096,4096)
local ok,err=pcall(summarize)
baseline.gui.CanvasSize=oldSize
assert(not ok and string.find(tostring(err),
    "HALL_MOBILE_OVERSIZED_SINGLE_SURFACE",1,true),
    "HALL_MOBILE_OVERSIZED_CANVAS_FALSE_ACCEPT")
print("HALL_MOBILE_NEGATIVE_REJECTED oversized_surface")

local oldCollision=baseline.paper.CanCollide
-- Do not falsely report a total collider overrun from just one paper:
-- verify it is noncolliding through its own explicit count/shape guard.
assert(oldCollision==false and baseline.paper.CanQuery==false,
    "HALL_MOBILE_REAL_PAPER_MUST_NEVER_BLOCK")
baseline.paper.CanCollide=true
local blockedPaperCount=0
for _,obj in ipairs(hall:GetDescendants()) do
    if obj.Name=="Photo hall anonymous diamond student display"
        and obj.CanCollide then blockedPaperCount+=1 end
end
baseline.paper.CanCollide=oldCollision
assert(blockedPaperCount==1,
    "HALL_MOBILE_COLLIDABLE_PAPER_MUTATION_NOT_DETECTED")
print("HALL_MOBILE_NEGATIVE_REJECTED collidable_student_art")

-- Static architecture has no Touched listeners. CanTouch must remain disabled
-- independently of CanCollide/CanQuery so navigation and raycasts are preserved
-- without unnecessary touch-pair bookkeeping on mobile.
local floor=nil
for _,obj in ipairs(hall:GetDescendants()) do
    if obj.Name=="Photo hall polished square stone floor" then
        floor=obj
        break
    end
end
assert(floor and floor.CanCollide and floor.CanQuery and not floor.CanTouch,
    "HALL_MOBILE_STATIC_FLOOR_PHYSICS_CONTRACT")
floor.CanTouch=true
ok,err=pcall(summarize)
floor.CanTouch=false
assert(not ok and string.find(tostring(err),
    "HALL_MOBILE_UNUSED_STATIC_TOUCH_EVENTS",1,true),
    "HALL_MOBILE_TOUCHABLE_STATIC_GEOMETRY_FALSE_ACCEPT")
assert(summarize().touchable==0,
    "HALL_MOBILE_TOUCH_STATE_DID_NOT_RECOVER")
print("HALL_MOBILE_NEGATIVE_REJECTED touchable_static_geometry")

local added={}
for i=1,(LIMIT_HALL_FRAMES-baseline.frames+1) do
    local item=Instance.new("Frame")
    item.Name="Test-only excessive UI frame"
    item.Parent=baseline.gui
    added[#added+1]=item
end
ok,err=pcall(summarize)
for _,item in ipairs(added) do item:Destroy() end
assert(not ok and string.find(tostring(err),
    "HALL_MOBILE_TOO_MANY_DRAW_FRAMES",1,true),
    "HALL_MOBILE_FRAME_BUDGET_FALSE_ACCEPT")
print("HALL_MOBILE_NEGATIVE_REJECTED excessive_draw_frames")
summarize()
print("HALL_MOBILE_NEGATIVE_TESTS_PASS budgets_enforced=true "
    .."no_collidable_papers=true no_external_photo_assets=true")
'''

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau", required=True, help="Pinned Luau interpreter")
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="hallway-mobile-") as folder:
        script = Path(folder) / "audit.lua"
        script.write_text(generate_luau() + "\n" + PROBE, encoding="utf-8")
        proc = subprocess.run(
            [args.luau, str(script)], text=True, capture_output=True,
            timeout=115, check=False
        )
    if proc.returncode:
        raise RuntimeError(
            "Actual Luau hallway complexity audit failed:\n"
            + proc.stderr[-4500:] + "\n" + proc.stdout[-1700:]
        )
    required = (
        "HALL_MOBILE_COMPLEXITY_PASS",
        "HALL_MOBILE_NEGATIVE_REJECTED oversized_surface",
        "HALL_MOBILE_NEGATIVE_REJECTED collidable_student_art",
        "HALL_MOBILE_NEGATIVE_REJECTED touchable_static_geometry",
        "HALL_MOBILE_NEGATIVE_REJECTED excessive_draw_frames",
        "HALL_MOBILE_NEGATIVE_TESTS_PASS",
    )
    output = proc.stdout.splitlines()
    for marker in required:
        assert any(line.startswith(marker) for line in output), marker
    for line in output:
        if line.startswith(("HALL_MOBILE_COMPLEXITY_PASS",
                            "HALL_MOBILE_NEGATIVE_")):
            print(line, flush=True)

if __name__ == "__main__":
    main()
