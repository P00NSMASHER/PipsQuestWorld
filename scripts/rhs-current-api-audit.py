#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}

LEGACY_SYMBOLS = [
    ("GamePassService", "PlayerHasPass"),
    ("PointsService", "AwardPoints"),
    ("BadgeService", "AwardBadge"),
    ("TeleportService", "CustomizedTeleportUI"),
    ("GlobalDataStore", "OnUpdate"),
    ("InsertService", "LoadAsset"),
    ("MarketplaceService", "PromptProductPurchase"),
    ("DataStoreService", "GetDataStore"),
]

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
    ap.add_argument("--allow-inert-missing-class", action="append", default=[])
    ap.add_argument("--fail-on-unexpected-missing", action="store_true")
    args = ap.parse_args()

    root = ET.parse(args.xml).getroot()
    walked = list(walk_items(root))
    counts = collections.Counter()
    class_paths = collections.defaultdict(list)
    script_sources = []

    for item, path in walked:
        cls = item.attrib.get("class", "")
        if not cls:
            continue
        counts[cls] += 1
        class_paths[cls].append(path)
        if cls in SCRIPT_CLASSES:
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
            details = []
            for item, path in walked:
                if item.attrib.get("class", "") != name:
                    continue
                details.append(
                    {
                        "path": path,
                        "directChildren": len(item.findall("Item")),
                        "descendantItems": sum(1 for _ in item.iter("Item")) - 1,
                        "propertyNames": property_names(item),
                    }
                )
            refs = [
                {"path": path, "class": script_class}
                for path, script_class, source in script_sources
                if name in source
            ]
            missing.append(
                {
                    "class": name,
                    "instances": count,
                    "paths": class_paths[name][:50],
                    "instanceDetails": details[:50],
                    "scriptReferences": refs[:50],
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

    member_audit = []
    for class_name, member_name in LEGACY_SYMBOLS:
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
                rec.update(
                    {
                        "memberPresent": True,
                        "memberType": member.get("MemberType"),
                        "deprecated": "Deprecated" in tags,
                        "tags": tags,
                        "security": member.get("Security"),
                    }
                )
                break
        member_audit.append(rec)

    allowed_inert=set(args.allow_inert_missing_class or [])
    unexpected_missing=[]
    non_inert_allowed=[]
    for rec in missing:
        if rec["class"] not in allowed_inert:
            unexpected_missing.append(rec["class"])
            continue
        details=rec.get("instanceDetails") or []
        inert=(
            not rec.get("scriptReferences")
            and len(details)==rec.get("instances",0)
            and all(
                d.get("directChildren")==0
                and d.get("descendantItems")==0
                and d.get("propertyNames")==["Name"]
                for d in details
            )
        )
        if not inert:
            non_inert_allowed.append(rec["class"])

    repo_root=Path(__file__).resolve().parents[1]
    build_state=json.loads((repo_root/"rhs/working/BUILD_STATE.json").read_text(encoding="utf-8"))

    report = {
        "schemaVersion": 3,
        "workingBuildSha256": build_state["expectedWorkingSha256"],
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
        "unexpectedMissingClasses": unexpected_missing,
        "nonInertAllowedMissingClasses": non_inert_allowed,
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
        for ref in rec["scriptReferences"]:
            print("MISSING_CLASS_SCRIPT_REFERENCE", rec["class"], ref["class"], ref["path"])

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
    if args.fail_on_unexpected_missing and (unexpected_missing or non_inert_allowed):
        raise SystemExit(
            "CURRENT_API_UNEXPECTED_MISSING "
            + ",".join(unexpected_missing + non_inert_allowed)
        )
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
