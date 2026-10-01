#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path

TARGET="ServerScriptService/PhoneTextingScript"
EXPECTED_SOURCE_SHA256="f180cb9f794e0a7157a9311f4ed692814d13ddb2a6e915e9d34ccb47e2a0cf66"

REQUIRED=[
    'local textrequesttime = {}',
    'game.Players.PlayerRemoving:connect(function(plr)',
    'typeof(targetplr) ~= "Instance"',
    'not targetplr:IsA("Player")',
    'targetplr.Parent ~= game.Players',
    'targetplr == plr',
    'type(input) ~= "string"',
    '#input < 1 or #input > 160',
    'not textingdata:FindFirstChild("messages")',
    'not textingdata:FindFirstChild("blocklist")',
    'now - lastrequest < .25',
    'textrequesttime[plr] = now',
    'CanUserChatAsync(plr.userId)',
    'CanUsersChatAsync(plr.userId, targetplr.userId)',
    'FilterStringAsync(input,plr,targetplr)',
    'if filteredstring == nil then return end',
    'if not targetplr.textingdata.blocklist:FindFirstChild(plr.Name) then',
    'local blocklist = textingdata and textingdata:FindFirstChild("blocklist")',
]

def prop_text(item,name):
    props=item.find("Properties")
    if props is None: return ""
    for p in props:
        if p.attrib.get("name")!=name: continue
        if p.tag=="Content":
            child=next(iter(p),None)
            return (child.text or "") if child is not None else ""
        return p.text or ""
    return ""

def item_name(item):
    return prop_text(item,"Name") or "(unnamed)"

def walk(parent,prefix=""):
    for item in parent.findall("Item"):
        nm=item_name(item).replace("/","_")
        path=f"{prefix}/{nm}" if prefix else nm
        yield item,path
        yield from walk(item,path)

def require_order(source,first,second,errors):
    a=source.find(first); b=source.find(second)
    if a<0 or b<0 or a>=b:
        errors.append(f"expected {first!r} before {second!r}")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--manifest",required=True)
    ap.add_argument("--build-state",required=True)
    ap.add_argument("--output",required=True)
    args=ap.parse_args()

    source=None
    for item,path in walk(ET.parse(args.xml).getroot()):
        if path==TARGET:
            source=prop_text(item,"Source")
            break

    errors=[]
    if source is None:
        errors.append("missing target script")
        source=""

    sha=hashlib.sha256(source.encode()).hexdigest()
    if sha!=EXPECTED_SOURCE_SHA256:
        errors.append(f"source SHA changed: {sha}")

    for token in REQUIRED:
        if token not in source:
            errors.append(f"required token missing: {token!r}")

    require_order(source,'#input < 1 or #input > 160','CanUserChatAsync(plr.userId)',errors)
    require_order(source,'now - lastrequest < .25','CanUserChatAsync(plr.userId)',errors)
    require_order(source,'CanUsersChatAsync(plr.userId, targetplr.userId)','FilterStringAsync(input,plr,targetplr)',errors)

    manifest=json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    patches=[p for p in manifest.get("patches",[]) if p.get("id")=="harden-phone-text-remotes"]
    if len(patches)!=1:
        errors.append(f"expected exactly one phone patch, found {len(patches)}")
    else:
        p=patches[0]
        if p.get("targetPath")!=TARGET:
            errors.append("phone patch target changed")
        if p.get("expectedSourceSha256")!="571e84308d007a1775aa14a281f92b6c177560bf97de308ec7347353d1d9d170":
            errors.append("phone baseline source hash changed")
        if len(p.get("replacements") or [])!=3:
            errors.append("phone deterministic replacement count changed")

    state=json.loads(Path(args.build_state).read_text(encoding="utf-8"))
    repairs=state.get("compatibilityRepairs") or []
    if repairs != [p.get("id") for p in manifest.get("patches",[])]:
        errors.append("BUILD_STATE repairs do not exactly match manifest IDs")
    if "harden-phone-text-remotes" not in repairs:
        errors.append("BUILD_STATE missing phone repair")
    if state.get("runtimeVerified") is not False:
        errors.append("runtimeVerified must remain false")
    if state.get("published") is not False:
        errors.append("published must remain false")

    report={
        "schemaVersion":1,
        "targetPath":TARGET,
        "sourceSha256":sha,
        "workingBuildSha256":state.get("expectedWorkingSha256"),
        "repairPresent":"harden-phone-text-remotes" in repairs,
        "status":"PASS" if not errors else "FAIL",
        "errors":errors,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_PHONE_TEXT_HARDENING_CONTRACT ===")
    print("SOURCE_SHA256",sha)
    print("WORKING_SHA256",state.get("expectedWorkingSha256"))
    print("FAILURES",len(errors))
    for e in errors:
        print("FAIL",e)
    print("STATUS",report["status"])
    print("=== END_RHS_PHONE_TEXT_HARDENING_CONTRACT ===")
    if errors:
        raise SystemExit(1)

if __name__=="__main__":
    main()
