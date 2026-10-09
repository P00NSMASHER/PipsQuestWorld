#!/usr/bin/env python3
"""Audit the REAL constructed showroom lighting; no native visual claims.

Runs the same Room/Gallery Luau modules as the existing geometry exporter
under pinned Luau fixtures. This checks values, effect idempotence and lighting
counts, not actual Roblox shader, frame-rate or device exposure.
"""
from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

from export_source_scene import generate_luau

PROBE = r'''
local lighting=game:GetService("Lighting")
local function close(a,b,tolerance)
    return math.abs(a-b)<=tolerance
end
local function profile()
    assert(close(lighting.ClockTime,10.25,.01),
        "LIGHTING_DAYTIME_REGRESSION")
    assert(close(lighting.Brightness,1.62,.02),
        "LIGHTING_BRIGHTNESS_REGRESSION")
    assert(lighting.GlobalShadows==true
        and close(lighting.ShadowSoftness,.67,.02),
        "LIGHTING_SHADOWS_REGRESSION")
    assert(close(lighting.ExposureCompensation,.04,.015),
        "LIGHTING_EXPOSURE_REGRESSION")
    local ambient=lighting.Ambient
    local outdoor=lighting.OutdoorAmbient
    assert(ambient.R>.61 and ambient.G>.59 and ambient.B>.56
        and ambient.R>ambient.B and ambient.G>ambient.B,
        "LIGHTING_AMBIENT_REGRESSION")
    assert(outdoor.R>.70 and outdoor.G>.71 and outdoor.B>.68,
        "LIGHTING_WINDOW_DAYLIGHT_REGRESSION")
    assert(close(lighting.EnvironmentDiffuseScale,.72,.015)
        and close(lighting.EnvironmentSpecularScale,.25,.015),
        "LIGHTING_BOUNCE_REGRESSION")
    local expected={
        EmmaClassroomAtmosphere="Atmosphere",
        EmmaClassroomBloom="BloomEffect",
        EmmaClassroomGrade="ColorCorrectionEffect",
        EmmaClassroomSunRays="SunRaysEffect",
    }
    local effects={}
    for _,child in ipairs(lighting:GetChildren()) do
        assert(expected[child.Name]==child.ClassName,
            "LIGHTING_UNEXPECTED_EFFECT "..child.Name)
        assert(not effects[child.Name],
            "LIGHTING_DUPLICATE_EFFECT "..child.Name)
        effects[child.Name]=child
    end
    local count=0
    for name in pairs(expected) do
        assert(effects[name]~=nil, "LIGHTING_MISSING_EFFECT "..name)
        count+=1
    end
    assert(count==4, "LIGHTING_EFFECT_COUNT_REGRESSION")
    assert(effects.EmmaClassroomBloom.Intensity<=.04
        and effects.EmmaClassroomSunRays.Intensity<=.03,
        "LIGHTING_EXCESSIVE_GLOW")
    local grade=effects.EmmaClassroomGrade
    assert(close(grade.Contrast,.055,.015)
        and close(grade.Saturation,.015,.015)
        and grade.TintColor.R>.98 and grade.TintColor.B>.94,
        "LIGHTING_GRADE_REGRESSION")
    local lightCount=0
    local floorCount=0
    local uniqueCenters={}
    for _,p in ipairs(Room.Root:GetDescendants()) do
        if p.Name=="Frosted fluorescent diffuser" then
            lightCount+=1
            local l=p:FindFirstChildOfClass("SurfaceLight")
            assert(l and close(l.Brightness,.24,.015)
                and close(l.Range,25,.1) and l.Shadows==false,
                "LIGHTING_CEILING_FIXTURE_REGRESSION")
            local key=tostring(p.Position.X)..","..tostring(p.Position.Z)
            assert(not uniqueCenters[key],"LIGHTING_DUPLICATE_CEILING_LIGHT")
            uniqueCenters[key]=true
        elseif p.Name=="Warm oak classroom floor" then
            floorCount+=1
            assert(close(p.Reflectance,.08,.015)
                and p.Material==Enum.Material.WoodPlanks,
                "LIGHTING_FLOOR_FINISH_REGRESSION")
        end
    end
    assert(lightCount==6 and floorCount==1,
        "LIGHTING_ROOM_FIXTURE_COUNT_REGRESSION")
    return lightCount
end
local lightCount=profile()
print("DAYLIGHT_RUNTIME_PASS ceiling_diffusers="..lightCount
    .." profile=single_source effects=4 floor=polished_wood"
    .." exposure=0.04 non_native_review=true")

-- Deliberate negative tests: dim overrides or accidental duplicate
-- post-processing must fail before publication, regardless of static builds.
local originalExposure=lighting.ExposureCompensation
lighting.ExposureCompensation=-.17
local ok,err=pcall(profile)
lighting.ExposureCompensation=originalExposure
assert(not ok and string.find(tostring(err),
    "LIGHTING_EXPOSURE_REGRESSION",1,true),
    "LIGHTING_NEGATIVE_EXPOSURE_NOT_REJECTED")
print("DAYLIGHT_ADVERSARIAL_REJECTED dark_gallery_override")

local duplicate=Instance.new("BloomEffect")
duplicate.Name="EmmaClassroomBloom"
duplicate.Parent=lighting
ok,err=pcall(profile)
duplicate:Destroy()
assert(not ok and string.find(tostring(err),
    "LIGHTING_DUPLICATE_EFFECT",1,true),
    "LIGHTING_NEGATIVE_DUPLICATE_NOT_REJECTED")
print("DAYLIGHT_ADVERSARIAL_REJECTED duplicate_bloom")
assert(profile()==6,"Lighting profile failed after adversarial restoration")
print("DAYLIGHT_NEGATIVE_TESTS_PASS exposure_override duplicate_effect")
'''

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--luau",required=True)
    args=parser.parse_args()
    source=generate_luau()+"\n"+PROBE+"\n"
    with tempfile.TemporaryDirectory(prefix="emma-lighting-") as folder:
        path=Path(folder)/"audit.lua"
        path.write_text(source,encoding="utf-8")
        result=subprocess.run([args.luau,str(path)],
            capture_output=True,text=True,check=False,timeout=115)
    if result.returncode:
        raise RuntimeError("Constructed showroom lighting audit failed:\n"
            +result.stderr[-3500:]+"\n"+result.stdout[-2500:])
    output=result.stdout.splitlines()
    for code in ("DAYLIGHT_RUNTIME_PASS",
                 "DAYLIGHT_ADVERSARIAL_REJECTED dark_gallery_override",
                 "DAYLIGHT_ADVERSARIAL_REJECTED duplicate_bloom",
                 "DAYLIGHT_NEGATIVE_TESTS_PASS"):
        assert any(line.startswith(code) for line in output), (
            "Lighting acceptance evidence missing: "+code)
    for line in output:
        if line.startswith(("DAYLIGHT_RUNTIME_PASS",
                            "DAYLIGHT_ADVERSARIAL_REJECTED",
                            "DAYLIGHT_NEGATIVE_TESTS_PASS")):
            print(line,flush=True)

if __name__=="__main__":
    try:main()
    except (RuntimeError,AssertionError,subprocess.TimeoutExpired) as exc:
        print("DAYLIGHT_AUDIT_FAIL",str(exc),file=sys.stderr,flush=True)
        raise SystemExit(1)
