#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ASSET_PATTERNS = [
    re.compile(r"rbxassetid://(\d+)", re.I),
    re.compile(r"https?://(?:www\.)?roblox\.com/asset/\?id=(\d+)", re.I),
    re.compile(r"https?://assetdelivery\.roblox\.com/v\d+/asset/\?id=(\d+)", re.I),
    re.compile(r"https?://assetdelivery\.roblox\.com/v\d+/assetId/(\d+)", re.I),
]
STARTUP_ROOTS = {
    "Workspace", "StarterGui", "StarterPlayer", "ReplicatedFirst",
    "Lighting", "SoundService", "Teams", "Chat",
}
STORAGE_ROOTS = {"ReplicatedStorage", "ServerStorage"}
SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}

def prop_text(prop) -> str:
    if prop.tag == "Content":
        child = next(iter(prop), None)
        return (child.text or "") if child is not None else ""
    return prop.text or ""

def item_name(item) -> str:
    props = item.find("Properties")
    if props is None:
        return "(unnamed)"
    for prop in props:
        if prop.attrib.get("name") == "Name":
            return prop.text or "(unnamed)"
    return "(unnamed)"

def walk(parent, prefix=""):
    for item in parent.findall("Item"):
        name = item_name(item).replace("/", "_")
        path = f"{prefix}/{name}" if prefix else name
        yield item, path
        yield from walk(item, path)

def priority_for(path: str) -> str:
    root = path.split("/", 1)[0]
    if root in STARTUP_ROOTS:
        return "startup_surface"
    if root == "StarterPack":
        return "player_backpack"
    if root in STORAGE_ROOTS:
        return "runtime_storage"
    return "other"

def extract_ids(text: str) -> list[str]:
    out = set()
    for rx in ASSET_PATTERNS:
        out.update(rx.findall(text))
    return sorted(out, key=int)

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--output",required=True)
    args=ap.parse_args()

    root=ET.parse(args.xml).getroot()
    by_id={}
    total_refs=0
    priority_counts=collections.Counter()
    property_counts=collections.Counter()
    class_counts=collections.Counter()

    for item,path in walk(root):
        cls=item.attrib.get("class","")
        props=item.find("Properties")
        if props is None:
            continue
        priority=priority_for(path)

        for prop in props:
            name=prop.attrib.get("name","")
            if not name or name == "Source":
                continue
            text=prop_text(prop).strip()
            if not text:
                continue
            ids=extract_ids(text)
            if not ids:
                continue

            for asset_id in ids:
                total_refs += 1
                priority_counts[priority] += 1
                property_counts[name] += 1
                class_counts[cls] += 1
                rec=by_id.setdefault(asset_id,{
                    "assetId":asset_id,
                    "referenceCount":0,
                    "priorities":{},
                    "propertyNames":{},
                    "classes":{},
                    "references":[],
                })
                rec["referenceCount"] += 1
                rec["priorities"][priority]=rec["priorities"].get(priority,0)+1
                rec["propertyNames"][name]=rec["propertyNames"].get(name,0)+1
                rec["classes"][cls]=rec["classes"].get(cls,0)+1
                if len(rec["references"]) < 100:
                    rec["references"].append({
                        "path":path,
                        "class":cls,
                        "property":name,
                        "priority":priority,
                        "value":text[:500],
                    })

    assets=sorted(by_id.values(),key=lambda r:(-r["referenceCount"],int(r["assetId"])))
    priority_assets=collections.defaultdict(set)
    for rec in assets:
        for priority in rec["priorities"]:
            priority_assets[priority].add(rec["assetId"])

    report={
        "schemaVersion":1,
        "workingBuildSha256":"04efd02d60dbf2388c230402888a21f0f3240efdf1b8971abcb0bc582b4ad8c4",
        "summary":{
            "uniqueAssetIds":len(assets),
            "assetReferences":total_refs,
            "uniqueAssetIdsByPriority":{
                k:len(v) for k,v in sorted(priority_assets.items())
            },
            "referencesByPriority":dict(sorted(priority_counts.items())),
            "topPropertyNames":property_counts.most_common(50),
            "topClasses":class_counts.most_common(50),
        },
        "assets":assets,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_ASSET_REFERENCE_MAP ===")
    print("UNIQUE_ASSET_IDS",len(assets))
    print("ASSET_REFERENCES",total_refs)
    for k,v in sorted(report["summary"]["uniqueAssetIdsByPriority"].items()):
        print("PRIORITY_UNIQUE",k,v)
    for k,v in sorted(priority_counts.items()):
        print("PRIORITY_REFERENCES",k,v)
    for rec in assets[:50]:
        print(
            "ASSET",
            rec["assetId"],
            "refs="+str(rec["referenceCount"]),
            "priorities="+json.dumps(rec["priorities"],sort_keys=True,separators=(",",":")),
        )
    print("=== END_RHS_ASSET_REFERENCE_MAP ===")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
