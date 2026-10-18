#!/usr/bin/env python3
"""Constructed-Luau regression for the four original classroom radiator vents.

The shallow decorative slats are native SurfaceGui ink, not 20 micro Parts.
This verifies the SHIPPED room code and adversarial failure cases, not
Roblox/iPhone pixels or native performance measurements.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import tempfile

from export_source_scene import generate_luau

PROBE = r'''
local root=Room.Root
local function named(name)
    local found={}
    for _,object in ipairs(root:GetDescendants()) do
        if object.Name==name and object:IsA("BasePart") then
            table.insert(found,object)
        end
    end
    return found
end
local function near(a,b,tol)
    return math.abs(a-b)<(tol or .002)
end
local function verify()
    local panels=named("Radiator grilles under classroom windows")
    assert(#panels==4,"RADIATOR_FOUR_EXISTING_FRONTS_MISSING")
    assert(#named("Radiator grille slot")==0,
        "RADIATOR_TWENTY_MICRO_PARTS_RETURNED")
    local byZ={}
    local sample=nil
    local ink=nil
    for _,panel in ipairs(panels) do
        assert(panel.Anchored and not panel.CanCollide
            and not panel.CanTouch and not panel.CanQuery
            and near(panel.Position.X,-34.35,.03)
            and near(panel.Position.Y,1.70,.03)
            and near(panel.Size.X,.07,.01)
            and near(panel.Size.Y,1.6,.01)
            and near(panel.Size.Z,1.2,.01),
            "RADIATOR_BODY_GEOMETRY_OR_COLLISION_CHANGED")
        byZ[math.floor(panel.Position.Z+.5)]=true
        local surface=panel:FindFirstChild("RadiatorSlots")
        assert(surface and surface:IsA("SurfaceGui")
            and surface.Face==Enum.NormalId.Right
            and surface.SizingMode==Enum.SurfaceGuiSizingMode.FixedSize
            and surface.AlwaysOnTop==false
            and surface.CanvasSize[1]==288
            and surface.CanvasSize[2]==384,
            "RADIATOR_NATIVE_FACE_OR_CANVAS_INVALID")
        assert(near(surface.LightInfluence,.25),
            "RADIATOR_LIGHT_INFLUENCE_CHANGED")
        -- These vents are authored geometric ink, never asset downloads,
        -- externally-sourced images, scripts or additional controls.
        for _,node in ipairs(surface:GetDescendants()) do
            assert(node:IsA("Frame") and node.Name=="Radiator vent slat",
                "RADIATOR_NONSLAT_UI_OR_EXTERNAL_ASSET_REJECTED")
        end
        local slats={}
        for _,item in ipairs(surface:GetChildren()) do
            if item.Name=="Radiator vent slat" then
                assert(item:IsA("Frame")
                    and item.BorderSizePixel==0
                    and item.BackgroundTransparency==0
                    and near(item.Size[1],.65)
                    and near(item.Size[2],.075)
                    and near(item.Position[1],.175)
                    and near(item.BackgroundColor3.R,153/255,.005),
                    "RADIATOR_INK_SHAPE_OR_VISIBILITY_CHANGED")
                table.insert(slats,item)
                ink=ink or item
            end
        end
        assert(#slats==5,"RADIATOR_FIVE_VENTS_MISSING")
        table.sort(slats,function(a,b)
            return a.Position[2]<b.Position[2]
        end)
        for i,slat in ipairs(slats) do
            assert(near(slat.Position[2],.4625+(i-3)*.15),
                "RADIATOR_SLOT_SPACING_CHANGED")
        end
        sample=sample or panel
    end
    assert(byZ[-23] and byZ[-13] and byZ[1] and byZ[14],
        "RADIATOR_ORIGINAL_PLACEMENT_CHANGED")
    return sample,ink
end

local panel,ink=verify()
print("RADIATOR_NATIVE_GUI_PASS fronts=4 slots=20 physical_slots=0"
    .." saved_parts=20 collisions_unchanged=true"
    .." native_iphone_qa_required=true")

local function reject(change,restore,reason,marker)
    change()
    local ok,err=pcall(verify)
    restore()
    assert(not ok and string.find(tostring(err),reason,1,true),
        "RADIATOR_ADVERSARIAL_MUTATION_NOT_REJECTED "..marker
        ..": "..tostring(err))
    print("RADIATOR_ADVERSARIAL_REJECTED "..marker)
end

local gui=panel:FindFirstChild("RadiatorSlots")
reject(function() gui.Face=Enum.NormalId.Left end,
    function() gui.Face=Enum.NormalId.Right end,
    "RADIATOR_NATIVE_FACE_OR_CANVAS_INVALID","wrong_sided_graphic")

reject(function() gui.AlwaysOnTop=true end,
    function() gui.AlwaysOnTop=false end,
    "RADIATOR_NATIVE_FACE_OR_CANVAS_INVALID","floating_overlay")

reject(function() panel.CanCollide=true end,
    function() panel.CanCollide=false end,
    "RADIATOR_BODY_GEOMETRY_OR_COLLISION_CHANGED","blocking_vent")

reject(function() gui.LightInfluence=1 end,
    function() gui.LightInfluence=.25 end,
    "RADIATOR_LIGHT_INFLUENCE_CHANGED","unreadable_lighting")

local unapproved=Instance.new("ImageLabel")
unapproved.Name="UnapprovedAsset"
reject(function() unapproved.Parent=gui end,
    function() unapproved.Parent=nil end,
    "RADIATOR_NONSLAT_UI_OR_EXTERNAL_ASSET_REJECTED","external_image_asset")

reject(function() ink.Parent=nil end,
    function() ink.Parent=gui end,
    "RADIATOR_FIVE_VENTS_MISSING","lost_vent")

reject(function() ink.BackgroundTransparency=1 end,
    function() ink.BackgroundTransparency=0 end,
    "RADIATOR_INK_SHAPE_OR_VISIBILITY_CHANGED","invisible_vent")

verify()
print("RADIATOR_NATIVE_GUI_NEGATIVE_TESTS_PASS")
'''

def main() -> None:
    ap=argparse.ArgumentParser()
    ap.add_argument("--luau",required=True)
    opts=ap.parse_args()
    with tempfile.TemporaryDirectory(prefix="abvm-radiator-") as directory:
        file=Path(directory)/"radiator.lua"
        file.write_text(generate_luau()+"\n"+PROBE+"\n",encoding="utf-8")
        result=subprocess.run([opts.luau,str(file)],capture_output=True,
                              text=True,timeout=110,check=False)
    if result.returncode:
        raise RuntimeError("Constructed radiator regression failed:\n"
            +result.stderr[-2500:]+"\n"+result.stdout[-1400:])
    required=("RADIATOR_NATIVE_GUI_PASS",
              "RADIATOR_ADVERSARIAL_REJECTED wrong_sided_graphic",
              "RADIATOR_ADVERSARIAL_REJECTED floating_overlay",
              "RADIATOR_ADVERSARIAL_REJECTED blocking_vent",
              "RADIATOR_ADVERSARIAL_REJECTED unreadable_lighting",
              "RADIATOR_ADVERSARIAL_REJECTED external_image_asset",
              "RADIATOR_ADVERSARIAL_REJECTED lost_vent",
              "RADIATOR_ADVERSARIAL_REJECTED invisible_vent",
              "RADIATOR_NATIVE_GUI_NEGATIVE_TESTS_PASS")
    for token in required:
        assert token in result.stdout,token
    for line in result.stdout.splitlines():
        if line.startswith(("RADIATOR_NATIVE_GUI_PASS",
                            "RADIATOR_ADVERSARIAL_REJECTED",
                            "RADIATOR_NATIVE_GUI_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)

if __name__=="__main__":
    main()
