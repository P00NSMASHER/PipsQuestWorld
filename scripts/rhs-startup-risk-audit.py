#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}
SIDE_EFFECTS = {
    "http_call": re.compile(r"(?:\bHttp\b|\bHTTP\b)\s*:\s*(?:GetAsync|PostAsync|RequestAsync)\s*\(|game\s*:\s*(?:HttpGet|HttpPost)\s*\(", re.I),
    "datastore": re.compile(r"DataStoreService|Get(?:Ordered)?DataStore\s*\(|(?:GetAsync|SetAsync|UpdateAsync|IncrementAsync|RemoveAsync)\s*\(", re.I),
    "teleport": re.compile(r"TeleportService|(?:\.|:)Teleport(?:Async|ToPlaceInstance|ToPrivateServer)?\s*\(", re.I),
    "purchase": re.compile(r"Prompt(?:Product|GamePass)Purchase\s*\(|ProcessReceipt", re.I),
    "badge": re.compile(r"AwardBadge\s*\(", re.I),
    "numeric_require": re.compile(r"require\s*\(\s*(\d{4,})\s*\)", re.I),
    "insert_asset": re.compile(r"InsertService|LoadAsset\s*\(", re.I),
}

def prop_node(item, name):
    props = item.find("Properties")
    if props is None:
        return None
    for p in props:
        if p.attrib.get("name") == name:
            return p
    return None

def prop_text(item, name):
    p = prop_node(item, name)
    if p is None:
        return ""
    if p.tag == "Content":
        child = next(iter(p), None)
        return (child.text or "") if child is not None else ""
    return p.text or ""

def item_name(item):
    return prop_text(item, "Name") or "(unnamed)"

def disabled(item):
    v = prop_text(item, "Disabled").strip().lower()
    return v == "true"

def walk_items(parent, prefix=""):
    for item in parent.findall("Item"):
        name = item_name(item).replace("/", "_")
        here = f"{prefix}/{name}" if prefix else name
        yield item, here
        yield from walk_items(item, here)

def startup_lane(cls: str, path: str, is_disabled: bool) -> str:
    if is_disabled:
        return "disabled"
    root = path.split("/", 1)[0]
    if cls == "Script":
        if root in {"ServerScriptService", "Workspace"}:
            return "auto_server"
        return "dormant_or_moved_server"
    if cls == "LocalScript":
        if root in {"StarterGui", "StarterPlayer", "ReplicatedFirst"}:
            return "auto_client"
        if root == "StarterPack":
            return "player_backpack"
        return "dormant_or_moved_client"
    return "module_dependency"

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--output",required=True)
    args=ap.parse_args()

    root=ET.parse(args.xml).getroot()
    records=[]
    lane_counts=collections.Counter()
    effect_counts=collections.Counter()
    risky=[]

    for item,path in walk_items(root):
        cls=item.attrib.get("class","")
        if cls not in SCRIPT_CLASSES:
            continue
        src=prop_text(item,"Source")
        lane=startup_lane(cls,path,disabled(item))
        lane_counts[lane]+=1
        effects={}
        for name,rx in SIDE_EFFECTS.items():
            matches=list(rx.finditer(src))
            if matches:
                effects[name]=len(matches)
                effect_counts[f"{lane}:{name}"]+=len(matches)
        rec={"path":path,"class":cls,"lane":lane,"disabled":disabled(item),"effects":effects}
        records.append(rec)
        if lane in {"auto_server","auto_client","player_backpack"} and effects:
            risky.append(rec)

    report={
        "schemaVersion":1,
        "workingBuildSha256":"04efd02d60dbf2388c230402888a21f0f3240efdf1b8971abcb0bc582b4ad8c4",
        "laneCounts":dict(sorted(lane_counts.items())),
        "effectCounts":dict(sorted(effect_counts.items())),
        "startupRiskScripts":risky,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_STARTUP_RISK_AUDIT ===")
    for lane,count in sorted(lane_counts.items()):
        print("LANE",lane,count)
    for key,count in sorted(effect_counts.items()):
        print("EFFECT",key,count)
    print("STARTUP_RISK_SCRIPTS",len(risky))
    for rec in risky[:150]:
        print("RISK",rec["lane"],rec["class"],rec["path"],json.dumps(rec["effects"],sort_keys=True))
    print("=== END_RHS_STARTUP_RISK_AUDIT ===")

if __name__=="__main__":
    main()
