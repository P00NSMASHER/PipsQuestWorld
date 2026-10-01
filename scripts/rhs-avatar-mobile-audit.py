#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES={"Script","LocalScript","ModuleScript"}
R6_TERMS={
    "Torso": re.compile(r'(?<!Upper)(?<!Lower)\bTorso\b'),
    "Right Arm": re.compile(r'["\']Right Arm["\']|\.Right\s+Arm'),
    "Left Arm": re.compile(r'["\']Left Arm["\']|\.Left\s+Arm'),
    "Right Leg": re.compile(r'["\']Right Leg["\']|\.Right\s+Leg'),
    "Left Leg": re.compile(r'["\']Left Leg["\']|\.Left\s+Leg'),
}
R15_TERMS={
    "UpperTorso": re.compile(r'\bUpperTorso\b'),
    "LowerTorso": re.compile(r'\bLowerTorso\b'),
    "RightUpperArm": re.compile(r'\bRightUpperArm\b'),
    "LeftUpperArm": re.compile(r'\bLeftUpperArm\b'),
    "RightUpperLeg": re.compile(r'\bRightUpperLeg\b'),
    "LeftUpperLeg": re.compile(r'\bLeftUpperLeg\b'),
    "RigType": re.compile(r'\bRigType\b|HumanoidRigType'),
}
MOBILE_TERMS={
    "TouchEnabled": re.compile(r'\bTouchEnabled\b'),
    "UserInputService": re.compile(r'\bUserInputService\b'),
    "ContextActionService": re.compile(r'\bContextActionService\b'),
    "TouchTap": re.compile(r'\bTouchTap\b'),
    "TouchPan": re.compile(r'\bTouchPan\b'),
    "GamepadMode": re.compile(r'\bGamepadMode\b'),
    "KeyboardEmulation": re.compile(r'\bKeyboardEmulation\b'),
    "MouseButton1Click": re.compile(r'\bMouseButton1Click\b'),
    "MouseButton1Down": re.compile(r'\bMouseButton1Down\b'),
}
CONTROL_TERMS={
    "custom_ControlScript": re.compile(r'ControlScript'),
    "MasterControl": re.compile(r'MasterControl'),
    "BindActionToInputTypes": re.compile(r'BindActionToInputTypes'),
    "CameraSubject": re.compile(r'CameraSubject'),
    "CameraType": re.compile(r'CameraType'),
}
FIXED_VIEWPORT_TERMS={
    "absolute_800": re.compile(r'\b800\b'),
    "absolute_600": re.compile(r'\b600\b'),
    "absolute_1024": re.compile(r'\b1024\b'),
    "absolute_768": re.compile(r'\b768\b'),
}

def prop_text(item,name):
    props=item.find("Properties")
    if props is None:
        return ""
    for p in props:
        if p.attrib.get("name")!=name:
            continue
        if p.tag=="Content":
            child=next(iter(p),None)
            return (child.text or "") if child is not None else ""
        return p.text or ""
    return ""

def name(item):
    return prop_text(item,"Name") or "(unnamed)"

def walk(parent,prefix=""):
    for item in parent.findall("Item"):
        nm=name(item).replace("/","_")
        path=f"{prefix}/{nm}" if prefix else nm
        yield item,path
        yield from walk(item,path)

def hit_lines(source,rx):
    return [i for i,line in enumerate(source.splitlines(),1) if rx.search(line)]

def summarize_terms(source, terms):
    out={}
    for key,rx in terms.items():
        lines=hit_lines(source,rx)
        if lines:
            out[key]=lines
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--output",required=True)
    args=ap.parse_args()

    root=ET.parse(args.xml).getroot()
    records=[]
    counts=collections.Counter()
    top_level_guis=[]
    starterplayer_props={}
    controlscript_paths=[]

    for item,path in walk(root):
        cls=item.attrib.get("class","")
        if path=="StarterPlayer":
            props=item.find("Properties")
            if props is not None:
                for p in props:
                    key=p.attrib.get("name")
                    if key in {
                        "CharacterRigType","LoadCharacterAppearance","AutoJumpEnabled",
                        "DevComputerCameraMode","DevTouchCameraMode",
                        "DevComputerMovementMode","DevTouchMovementMode",
                        "CameraMode","EnableMouseLockOption"
                    }:
                        starterplayer_props[key]=prop_text(item,key)

        if cls=="ScreenGui" and path.startswith("StarterGui/"):
            top_level_guis.append({
                "path":path,
                "Enabled":prop_text(item,"Enabled"),
                "ResetOnSpawn":prop_text(item,"ResetOnSpawn"),
                "IgnoreGuiInset":prop_text(item,"IgnoreGuiInset"),
                "DisplayOrder":prop_text(item,"DisplayOrder"),
            })

        if "ControlScript" in path:
            controlscript_paths.append(path)

        if cls not in SCRIPT_CLASSES:
            continue
        source=prop_text(item,"Source")
        if not source:
            continue

        r6=summarize_terms(source,R6_TERMS)
        r15=summarize_terms(source,R15_TERMS)
        mobile=summarize_terms(source,MOBILE_TERMS)
        controls=summarize_terms(source,CONTROL_TERMS)
        viewport=summarize_terms(source,FIXED_VIEWPORT_TERMS)

        if not any([r6,r15,mobile,controls,viewport]):
            continue

        rec={
            "path":path,
            "class":cls,
            "r6":r6,
            "r15":r15,
            "mobile":mobile,
            "controls":controls,
            "fixedViewportLiterals":viewport,
        }
        records.append(rec)
        if r6:
            counts["scriptsWithR6Assumptions"]+=1
            counts["r6TermOccurrences"]+=sum(len(v) for v in r6.values())
        if r15:
            counts["scriptsWithR15Awareness"]+=1
            counts["r15TermOccurrences"]+=sum(len(v) for v in r15.values())
        if mobile:
            counts["scriptsWithMobileInputAwareness"]+=1
            counts["mobileTermOccurrences"]+=sum(len(v) for v in mobile.values())
        if controls:
            counts["scriptsTouchingControlsOrCamera"]+=1
            counts["controlTermOccurrences"]+=sum(len(v) for v in controls.values())
        if viewport:
            counts["scriptsWithFixedViewportLiterals"]+=1
            counts["fixedViewportLiteralOccurrences"]+=sum(len(v) for v in viewport.values())

    r6_records=[r for r in records if r["r6"]]
    no_r15=[r for r in r6_records if not r["r15"]]
    mobile_records=[r for r in records if r["mobile"]]

    report={
        "schemaVersion":1,
        "workingBuildSha256":"04efd02d60dbf2388c230402888a21f0f3240efdf1b8971abcb0bc582b4ad8c4",
        "summary":{
            **dict(sorted(counts.items())),
            "topLevelStarterGuiCount":len(top_level_guis),
            "controlScriptInstanceCount":len(controlscript_paths),
            "r6AssumptionScriptsWithoutLocalR15Awareness":len(no_r15),
        },
        "starterPlayerProperties":starterplayer_props,
        "topLevelStarterGuis":top_level_guis,
        "controlScriptPaths":controlscript_paths[:300],
        "r6RiskScripts":r6_records,
        "r6RiskWithoutLocalR15Awareness":no_r15,
        "mobileAwareScripts":mobile_records,
        "records":records,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_AVATAR_MOBILE_AUDIT ===")
    for k,v in sorted(report["summary"].items()):
        print("SUMMARY",k,v)
    for k,v in sorted(starterplayer_props.items()):
        print("STARTERPLAYER",k,repr(v))
    for path in controlscript_paths[:50]:
        print("CONTROL_PATH",path)
    for rec in no_r15[:100]:
        print(
            "R6_RISK",
            rec["class"],
            rec["path"],
            "terms="+json.dumps({k:len(v) for k,v in rec["r6"].items()},sort_keys=True,separators=(",",":")),
        )
    for rec in mobile_records[:100]:
        print(
            "MOBILE",
            rec["class"],
            rec["path"],
            "terms="+json.dumps({k:len(v) for k,v in rec["mobile"].items()},sort_keys=True,separators=(",",":")),
        )
    print("=== END_RHS_AVATAR_MOBILE_AUDIT ===")

if __name__=="__main__":
    main()
