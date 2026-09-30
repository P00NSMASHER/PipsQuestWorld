#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import xml.etree.ElementTree as ET
from pathlib import Path

def prop_text(item, name: str) -> str:
    props = item.find("Properties")
    if props is None:
        return ""
    for prop in props:
        if prop.attrib.get("name") != name:
            continue
        if prop.tag == "Content":
            child = next(iter(prop), None)
            return (child.text or "") if child is not None else ""
        return prop.text or ""
    return ""

def item_name(item) -> str:
    return prop_text(item, "Name") or "(unnamed)"

def walk_items(parent, prefix: str = ""):
    for item in parent.findall("Item"):
        name = item_name(item).replace("/", "_")
        here = f"{prefix}/{name}" if prefix else name
        yield item, here
        yield from walk_items(item, here)

def property_names(item) -> list[str]:
    props = item.find("Properties")
    if props is None:
        return []
    return sorted(
        {
            prop.attrib.get("name", "")
            for prop in props
            if prop.attrib.get("name")
        }
    )

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--xml", required=True)
    ap.add_argument("--api-dump", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    root = ET.parse(args.xml).getroot()
    walked = list(walk_items(root))
    counts = collections.Counter(
        item.attrib.get("class", "")
        for item, _ in walked
        if item.attrib.get("class")
    )

    api = json.loads(Path(args.api_dump).read_text(encoding="utf-8"))
    api_classes = {}
    for cls in api.get("Classes", []):
        name = cls.get("Name")
        if name:
            api_classes[name] = cls

    present = []
    missing = []
    deprecated = []
    not_creatable = []
    for name, count in sorted(counts.items()):
        cls = api_classes.get(name)
        if cls is None:
            instances = []
            for item, path in walked:
                if item.attrib.get("class", "") != name:
                    continue
                descendants = sum(1 for _ in item.iter("Item")) - 1
                instances.append(
                    {
                        "path": path,
                        "directChildren": len(item.findall("Item")),
                        "descendantItems": descendants,
                        "propertyNames": property_names(item),
                    }
                )
            missing.append(
                {
                    "class": name,
                    "instances": count,
                    "instanceDetails": instances,
                }
            )
            continue

        tags = set(cls.get("Tags") or [])
        rec = {
            "class": name,
            "instances": count,
            "superclass": cls.get("Superclass"),
            "tags": sorted(tags),
        }
        present.append(rec)
        if "Deprecated" in tags:
            deprecated.append(rec)
        if "NotCreatable" in tags:
            not_creatable.append(rec)

    report = {
        "schemaVersion": 2,
        "workingBuildSha256": "04efd02d60dbf2388c230402888a21f0f3240efdf1b8971abcb0bc582b4ad8c4",
        "apiDump": {
            "repository": "MaximumADHD/Roblox-Client-Tracker",
            "commit": "fcd6994996bb655bef047c69f456463d94faa569",
            "robloxVersion": "0.741.19.7411056",
            "commitDate": "2026-09-29T19:57:18Z",
        },
        "place": {
            "instanceCount": sum(counts.values()),
            "distinctClasses": len(counts),
        },
        "summary": {
            "classesPresentInCurrentApi": len(present),
            "classesMissingFromCurrentApi": len(missing),
            "deprecatedClassesPresent": len(deprecated),
            "notCreatableClassesPresent": len(not_creatable),
        },
        "missingClasses": missing,
        "deprecatedClasses": deprecated,
        "notCreatableClasses": not_creatable,
    }

    Path(args.output).write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    print("=== RHS_CURRENT_API_CLASS_AUDIT ===")
    print("PLACE_INSTANCES", report["place"]["instanceCount"])
    print("PLACE_DISTINCT_CLASSES", report["place"]["distinctClasses"])
    print("CURRENT_API_CLASSES_PRESENT", len(present))
    print("CURRENT_API_CLASSES_MISSING", len(missing))
    for rec in missing:
        print("MISSING_CLASS", rec["class"], rec["instances"])
        for detail in rec["instanceDetails"]:
            print(
                "MISSING_INSTANCE",
                rec["class"],
                detail["path"],
                "directChildren=" + str(detail["directChildren"]),
                "descendants=" + str(detail["descendantItems"]),
                "properties=" + ",".join(detail["propertyNames"]),
            )
    print("DEPRECATED_CLASSES_PRESENT", len(deprecated))
    for rec in deprecated:
        print("DEPRECATED_CLASS", rec["class"], rec["instances"])
    print("=== END_RHS_CURRENT_API_CLASS_AUDIT ===")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
