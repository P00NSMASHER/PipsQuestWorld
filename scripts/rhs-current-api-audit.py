#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import xml.etree.ElementTree as ET
from pathlib import Path

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--xml", required=True)
    ap.add_argument("--api-dump", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    root = ET.parse(args.xml).getroot()
    counts = collections.Counter(
        item.attrib.get("class", "")
        for item in root.iter("Item")
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
            missing.append({"class": name, "instances": count})
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
        "schemaVersion": 1,
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
    print("DEPRECATED_CLASSES_PRESENT", len(deprecated))
    for rec in deprecated:
        print("DEPRECATED_CLASS", rec["class"], rec["instances"])
    print("=== END_RHS_CURRENT_API_CLASS_AUDIT ===")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
