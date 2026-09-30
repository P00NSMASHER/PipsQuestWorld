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
    counts = collections.Counter()
    class_paths = collections.defaultdict(list)
    script_sources = []

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

    def walk(parent, prefix: str = ""):
        for item in parent.findall("Item"):
            name = item_name(item).replace("/", "_")
            path = f"{prefix}/{name}" if prefix else name
            yield item, path
            yield from walk(item, path)

    for item, path in walk(root):
        cls = item.attrib.get("class", "")
        if not cls:
            continue
        counts[cls] += 1
        class_paths[cls].append(path)
        if cls in {"Script", "LocalScript", "ModuleScript"}:
            source = prop_text(item, "Source")
            if source:
                script_sources.append((path, cls, source))

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
            refs = []
            for path, script_class, source in script_sources:
                if name in source:
                    refs.append({"path": path, "class": script_class})
            missing.append({
                "class": name,
                "instances": count,
                "paths": class_paths[name][:50],
                "scriptReferences": refs[:50],
            })
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

    legacy_symbols = [
        ("GamePassService", "PlayerHasPass"),
        ("PointsService", "AwardPoints"),
        ("BadgeService", "AwardBadge"),
        ("TeleportService", "CustomizedTeleportUI"),
        ("GlobalDataStore", "OnUpdate"),
        ("InsertService", "LoadAsset"),
        ("MarketplaceService", "PromptProductPurchase"),
        ("DataStoreService", "GetDataStore"),
    ]
    member_audit = []
    for class_name, member_name in legacy_symbols:
        cls = api_classes.get(class_name)
        rec = {
            "class": class_name,
            "member": member_name,
            "classPresent": cls is not None,
            "memberPresent": False,
            "memberType": None,
            "deprecated": False,
            "tags": [],
            "security": None,
        }
        if cls is not None:
            for member in cls.get("Members", []):
                if member.get("Name") != member_name:
                    continue
                tags = sorted(set(member.get("Tags") or []))
                rec.update({
                    "memberPresent": True,
                    "memberType": member.get("MemberType"),
                    "deprecated": "Deprecated" in tags,
                    "tags": tags,
                    "security": member.get("Security"),
                })
                break
        member_audit.append(rec)

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
        "legacyMemberAudit": member_audit,
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
    print("LEGACY_MEMBER_AUDIT")
    for rec in member_audit:
        print(
            "LEGACY_MEMBER",
            rec["class"],
            rec["member"],
            "class_present=" + str(rec["classPresent"]).lower(),
            "member_present=" + str(rec["memberPresent"]).lower(),
            "deprecated=" + str(rec["deprecated"]).lower(),
            "type=" + str(rec["memberType"]),
        )
    print("DEPRECATED_CLASSES_PRESENT", len(deprecated))
    for rec in deprecated:
        print("DEPRECATED_CLASS", rec["class"], rec["instances"])
    print("=== END_RHS_CURRENT_API_CLASS_AUDIT ===")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
