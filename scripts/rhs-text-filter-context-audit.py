#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import xml.etree.ElementTree as ET

TARGETS = {
    "ServerScriptService/NameChangerScript": [151],
    "ServerScriptService/GlobalBanScript": [120],
    "ServerScriptService/CustomHouseScript_NEW": [637,701],
    "ServerScriptService/Idle+EnforcerCheck": [74],
    "ServerScriptService/ItemBuyScript": [67,355],
    "ServerScriptService/Time_ScheduleScript": [90,102],
}

def prop_text(item,name):
    props=item.find("Properties")
    if props is None:
        return ""
    for p in props:
        if p.attrib.get("name") != name:
            continue
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

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    args=ap.parse_args()

    root=ET.parse(args.xml).getroot()
    sources={}
    for item,path in walk(root):
        if path in TARGETS:
            sources[path]=prop_text(item,"Source")

    print("=== RHS_TEXT_FILTER_CONTEXT_AUDIT ===")
    for path,lines_wanted in TARGETS.items():
        source=sources.get(path)
        if not source:
            print("MISSING_TARGET",path)
            continue
        lines=source.splitlines()
        print("SCRIPT",path,"lines="+str(len(lines)))
        for center in lines_wanted:
            start=max(1,center-30)
            end=min(len(lines),center+90)
            print("CONTEXT",path,"center="+str(center),"range="+str(start)+"-"+str(end))
            for i in range(start,end+1):
                print(f"{i:04d}: {lines[i-1]}")
    print("=== END_RHS_TEXT_FILTER_CONTEXT_AUDIT ===")

if __name__=="__main__":
    main()
