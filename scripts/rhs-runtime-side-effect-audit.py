#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}

RULES = {
    "teleport": re.compile(r"\bTeleport(?:Async|ToPlaceInstance|ToPrivateServer)?\s*\(", re.I),
    "purchase_prompt": re.compile(r"\bPrompt(?:Product|GamePass)Purchase\s*\(", re.I),
    "process_receipt": re.compile(r"\bProcessReceipt\b"),
    "badge_award": re.compile(r"\bAwardBadge\s*\(", re.I),
    "datastore_open": re.compile(r"\bGet(?:Ordered)?DataStore\s*\(", re.I),
    "datastore_write": re.compile(r"\b(?:SetAsync|UpdateAsync|IncrementAsync|RemoveAsync)\s*\(", re.I),
    "insert_load_asset": re.compile(r"\bLoadAsset\s*\(", re.I),
    "group_lookup": re.compile(r"\b(?:GetGroupInfoAsync|GetGroupsAsync|GetRankInGroup|GetRoleInGroup)\s*\(", re.I),
    "numeric_require": re.compile(r"\brequire\s*\(\s*(\d{4,})\s*\)", re.I),
    "http_call": re.compile(r"(?:\bHttp\b|\bHTTP\b)\s*:\s*(?:GetAsync|PostAsync|RequestAsync)\s*\(|game\s*:\s*(?:HttpGet|HttpPost)\s*\(", re.I),
}

NUMBER = re.compile(r"(?<![A-Za-z_])(\d{4,})(?![A-Za-z_])")
STRING = re.compile(r"(['\"])(.*?)\1")

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

def compact_line(line: str) -> str:
    line = line.strip().replace("\t", " ")
    return re.sub(r"\s+", " ", line)[:500]

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--xml", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    root = ET.parse(args.xml).getroot()
    findings = []
    counts = collections.Counter()

    for item, path in walk_items(root):
        cls = item.attrib.get("class", "")
        if cls not in SCRIPT_CLASSES:
            continue
        source = prop_text(item, "Source")
        if not source:
            continue

        for line_no, line in enumerate(source.splitlines(), start=1):
            for category, regex in RULES.items():
                matches = list(regex.finditer(line))
                if not matches:
                    continue
                ids = sorted(set(NUMBER.findall(line)))
                strings = [m.group(2) for m in STRING.finditer(line)]
                finding = {
                    "category": category,
                    "path": path,
                    "class": cls,
                    "line": line_no,
                    "text": compact_line(line),
                    "numericIds": ids,
                    "stringLiterals": strings[:10],
                }
                if category == "numeric_require":
                    finding["requiredAssetIds"] = sorted({m.group(1) for m in matches})
                findings.append(finding)
                counts[category] += 1

    report = {
        "schemaVersion": 1,
        "workingBuildSha256": "04efd02d60dbf2388c230402888a21f0f3240efdf1b8971abcb0bc582b4ad8c4",
        "summary": dict(sorted(counts.items())),
        "findings": findings,
    }
    Path(args.output).write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print("=== RHS_RUNTIME_SIDE_EFFECT_AUDIT ===")
    for category in sorted(counts):
        print("CATEGORY", category, counts[category])
        for f in [x for x in findings if x["category"] == category][:80]:
            suffix = ""
            if f["numericIds"]:
                suffix += " ids=" + ",".join(f["numericIds"])
            if f["stringLiterals"]:
                suffix += " strings=" + json.dumps(f["stringLiterals"], ensure_ascii=False)
            print("FINDING", category, f["class"], f["path"], f"line={f['line']}", suffix)
    print("=== END_RHS_RUNTIME_SIDE_EFFECT_AUDIT ===")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
