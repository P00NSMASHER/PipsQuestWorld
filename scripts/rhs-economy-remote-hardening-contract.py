#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path

TARGET="ServerScriptService/ItemBuyScript"
BASELINE_SHA="c92d824aea342350a940a14c74d151accca9bb0058932fc7df55b9b8557fbddf"
EXPECTED_SHA="876d7ae8f1fa746780e81e1457c8c7870d4092d532edb3bd94588c4316fa7169"

REQUIRED=[
    "local economyrequesttime = {}",
    "local function allowEconomyRequest(plr,key,interval)",
    "economyrequesttime[plr] = nil",
    'type(shopname) ~= "string" or type(itemname) ~= "string"',
    'allowEconomyRequest(plr,"temporary",.25)',
    'item:FindFirstChild("ItemCost")',
    'item:FindFirstChild("Tool")',
    'item.Tool:IsA("Tool")',
    'type(itemid) ~= "number" or itemid <= 0 or itemid ~= math.floor(itemid)',
    'allowEconomyRequest(plr,"permanent",.5)',
    'allowEconomyRequest(plr,"loyalty",.5)',
    'allowEconomyRequest(plr,"special-guitar",10)',
    'game.ServerStorage.RemoteFunctions.AwardItemAsync:Invoke(plr, 332)',
    'type(code) ~= "string" or #code < 1 or #code > 64',
    'allowEconomyRequest(plr,"twitter-code",.5)',
    "local price = item.ItemCost.Value",
    "local price = item.LPCost.Value",
]

FORBIDDEN=[
    'game.ServerStorage.RemoteFunctions.AwardItem:Fire(plr, 332)',
]

def prop_text(item,name):
    props=item.find("Properties")
    if props is None:return ""
    for p in props:
        if p.attrib.get("name")!=name:continue
        if p.tag=="Content":
            child=next(iter(p),None)
            return (child.text or "") if child is not None else ""
        return p.text or ""
    return ""

def item_name(item):return prop_text(item,"Name") or "(unnamed)"

def walk(parent,prefix=""):
    for item in parent.findall("Item"):
        nm=item_name(item).replace("/","_")
        path=f"{prefix}/{nm}" if prefix else nm
        yield item,path
        yield from walk(item,path)

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
    if sha != EXPECTED_SHA:
        errors.append(f"patched source SHA changed: {sha}")

    for token in REQUIRED:
        if token not in source:
            errors.append(f"required token missing: {token!r}")
    for token in FORBIDDEN:
        if token in source:
            errors.append(f"forbidden legacy token remains: {token!r}")

    # Server price sources must remain authoritative.
    if source.count("local price = item.ItemCost.Value") < 2:
        errors.append("server ItemCost pricing markers changed")
    if source.count("local price = item.LPCost.Value") != 1:
        errors.append("server LPCost pricing marker changed")

    manifest=json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    patches=[p for p in manifest.get("patches",[]) if p.get("id")=="harden-economy-remote-inputs"]
    if len(patches)!=1:
        errors.append(f"expected one economy patch, found {len(patches)}")
    else:
        p=patches[0]
        if p.get("targetPath") != TARGET:
            errors.append("economy target changed")
        if p.get("expectedSourceSha256") != BASELINE_SHA:
            errors.append("economy baseline source hash changed")
        if len(p.get("replacements") or []) != 7:
            errors.append("economy deterministic replacement count changed")

    state=json.loads(Path(args.build_state).read_text(encoding="utf-8"))
    repairs=state.get("compatibilityRepairs") or []
    if repairs != [p.get("id") for p in manifest.get("patches",[])]:
        errors.append("BUILD_STATE repairs do not match manifest")
    if "harden-economy-remote-inputs" not in repairs:
        errors.append("BUILD_STATE missing economy repair")
    if state.get("runtimeVerified") is not False:
        errors.append("runtimeVerified must remain false")
    if state.get("published") is not False:
        errors.append("published must remain false")

    report={
        "schemaVersion":1,
        "targetPath":TARGET,
        "sourceSha256":sha,
        "workingBuildSha256":state.get("expectedWorkingSha256"),
        "repairPresent":"harden-economy-remote-inputs" in repairs,
        "serverPricingPreserved":(
            source.count("local price = item.ItemCost.Value") >= 2
            and source.count("local price = item.LPCost.Value") == 1
        ),
        "status":"PASS" if not errors else "FAIL",
        "errors":errors,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_ECONOMY_REMOTE_HARDENING_CONTRACT ===")
    print("SOURCE_SHA256",sha)
    print("WORKING_SHA256",state.get("expectedWorkingSha256"))
    print("SERVER_PRICING_PRESERVED",str(report["serverPricingPreserved"]).lower())
    print("FAILURES",len(errors))
    for e in errors: print("FAIL",e)
    print("STATUS",report["status"])
    print("=== END_RHS_ECONOMY_REMOTE_HARDENING_CONTRACT ===")
    if errors: raise SystemExit(1)

if __name__=="__main__":
    main()
