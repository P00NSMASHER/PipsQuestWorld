#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}

PATTERNS = {
    "cindering_backend": re.compile(r"cindering\.xyz", re.I),
    "gameanalytics_backend": re.compile(r"gameanalytics", re.I),
    "deprecated_gamepass_service": re.compile(r"GamePassService"),
    "deprecated_points_service": re.compile(r"PointsService"),
    "datastore_service": re.compile(r"DataStoreService"),
    "marketplace_service": re.compile(r"MarketplaceService"),
    "badge_service": re.compile(r"BadgeService"),
    "teleport_service": re.compile(r"TeleportService"),
    "insert_service": re.compile(r"InsertService|LoadAsset"),
    "group_service": re.compile(r"GroupService"),
    "numeric_require": re.compile(r"require\s*\(\s*(\d{4,})\s*\)"),
    "insecure_http": re.compile(r"http://", re.I),
    "legacy_character_fetch": re.compile(r"CharacterFetch\.ashx", re.I),
    "process_receipt": re.compile(r"ProcessReceipt"),
    "purchase_prompt": re.compile(r"Prompt(?:Product|GamePass)Purchase"),
}

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

def line_numbers(source: str, regex: re.Pattern) -> list[int]:
    out = []
    for idx, line in enumerate(source.splitlines(), start=1):
        if regex.search(line):
            out.append(idx)
    return out

def walk_items(parent, prefix: str = ""):
    for item in parent.findall("Item"):
        name = item_name(item).replace("/", "_")
        here = f"{prefix}/{name}" if prefix else name
        yield item, here
        yield from walk_items(item, here)

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xml", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    root = ET.parse(args.xml).getroot()

    report = {
        "schemaVersion": 1,
        "sourceSha256": "d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360",
        "categories": {},
        "summary": {},
    }

    for item, path in walk_items(root):
        cls = item.attrib.get("class", "")
        if cls not in SCRIPT_CLASSES:
            continue

        source = prop_text(item, "Source")
        if not source:
            continue

        for category, regex in PATTERNS.items():
            matches = list(regex.finditer(source))
            if not matches:
                continue

            entry = {
                "path": path,
                "class": cls,
                "name": item_name(item),
                "occurrences": len(matches),
                "lineNumbers": line_numbers(source, regex),
            }

            if category == "numeric_require":
                entry["assetIds"] = sorted({m.group(1) for m in matches})

            report["categories"].setdefault(category, []).append(entry)

    for category, entries in report["categories"].items():
        report["summary"][category] = {
            "scriptCount": len(entries),
            "occurrences": sum(e["occurrences"] for e in entries),
        }

    Path(args.output).write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print("=== RHS_COMPATIBILITY_AUDIT ===")
    for category in sorted(report["summary"]):
        summary = report["summary"][category]
        print("CATEGORY", category, "scripts", summary["scriptCount"], "occurrences", summary["occurrences"])
        for entry in report["categories"][category][:30]:
            suffix = ""
            if "assetIds" in entry:
                suffix = " assetIds=" + ",".join(entry["assetIds"])
            print("HIT", category, entry["class"], entry["path"], "lines=" + ",".join(map(str, entry["lineNumbers"])) + suffix)
    print("=== END_RHS_COMPATIBILITY_AUDIT ===")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
