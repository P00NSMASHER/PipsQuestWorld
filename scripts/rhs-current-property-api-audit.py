#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import re
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

def walk(parent, prefix=""):
    for item in parent.findall("Item"):
        name = item_name(item).replace("/", "_")
        path = f"{prefix}/{name}" if prefix else name
        yield item, path
        yield from walk(item, path)

def build_indexes(api: dict):
    classes = {c["Name"]: c for c in api.get("Classes", []) if c.get("Name")}
    memo = {}

    def properties_for(class_name: str):
        if class_name in memo:
            return memo[class_name]
        cls = classes.get(class_name)
        if cls is None:
            memo[class_name] = {}
            return memo[class_name]
        props = {}
        parent = cls.get("Superclass")
        if parent and parent != "<<<ROOT>>>":
            props.update(properties_for(parent))
        for member in cls.get("Members", []):
            if member.get("MemberType") == "Property" and member.get("Name"):
                props[member["Name"]] = member
        memo[class_name] = props
        return props

    return classes, properties_for

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--xml", required=True)
    ap.add_argument("--api-dump", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    api = json.loads(Path(args.api_dump).read_text(encoding="utf-8"))
    classes, properties_for = build_indexes(api)
    root = ET.parse(args.xml).getroot()
    walked = list(walk(root))
    script_sources = []
    for script_item, script_path in walked:
        script_class = script_item.attrib.get("class", "")
        if script_class not in {"Script", "LocalScript", "ModuleScript"}:
            continue
        source = prop_text(script_item, "Source")
        if source:
            script_sources.append((script_path, script_class, source))

    summary = collections.Counter()
    by_key = {}
    class_missing = collections.Counter()

    for item, path in walked:
        class_name = item.attrib.get("class", "")
        if not class_name:
            continue
        api_class = classes.get(class_name)
        if api_class is None:
            class_missing[class_name] += 1
            continue

        api_props = properties_for(class_name)
        props = item.find("Properties")
        if props is None:
            continue

        for prop in props:
            name = prop.attrib.get("name", "")
            if not name:
                continue

            member = api_props.get(name)
            if member is None:
                status = "missing_property"
                tags = []
                serialization = None
            else:
                tags = sorted(set(member.get("Tags") or []))
                serialization = member.get("Serialization")
                if "Deprecated" in tags:
                    status = "deprecated_property"
                elif isinstance(serialization, dict) and serialization.get("CanLoad") is False:
                    status = "current_but_not_loadable"
                else:
                    status = "current"

            summary[status] += 1
            key = (class_name, name, status)
            rec = by_key.setdefault(key, {
                "class": class_name,
                "property": name,
                "status": status,
                "instances": 0,
                "tags": tags,
                "serialization": serialization,
                "paths": [],
                "xmlTags": collections.Counter(),
                "scriptReferences": [],
            })
            rec["instances"] += 1
            rec["xmlTags"][prop.tag] += 1
            if len(rec["paths"]) < 40:
                rec["paths"].append(path)

    # Build one script-property reference index for every missing serialized
    # property instead of rescanning all 1,192 scripts once per property.
    missing_property_names = {
        rec["property"]
        for rec in by_key.values()
        if rec["status"] == "missing_property"
    }
    reference_index = collections.defaultdict(list)
    dot_access_rx = re.compile(r"\.\s*([A-Za-z_]\w*)\b")
    bracket_access_rx = re.compile(r"\[\s*([\"'])(.*?)\1\s*\]")

    for script_path, script_class, source in script_sources:
        for line_no, line in enumerate(source.splitlines(), 1):
            candidates = set(dot_access_rx.findall(line))
            candidates.update(match.group(2) for match in bracket_access_rx.finditer(line))
            for candidate in candidates:
                if candidate not in missing_property_names:
                    continue
                bucket = reference_index[candidate]
                if len(bucket) >= 80:
                    continue
                bucket.append({
                    "scriptPath": script_path,
                    "scriptClass": script_class,
                    "line": line_no,
                    "text": line.strip()[:500],
                })

    for rec in by_key.values():
        if rec["status"] == "missing_property":
            rec["scriptReferences"] = list(reference_index.get(rec["property"], []))

    findings = []
    for rec in by_key.values():
        rec = dict(rec)
        rec["xmlTags"] = dict(sorted(rec["xmlTags"].items()))
        rec["scriptReferenceCount"] = len(rec.get("scriptReferences") or [])
        if rec["status"] == "missing_property":
            if rec["scriptReferenceCount"] > 0:
                summary["missing_property_script_referenced"] += rec["instances"]
            else:
                summary["missing_property_serializer_only"] += rec["instances"]
        findings.append(rec)

    priority = {
        "missing_property": 0,
        "current_but_not_loadable": 1,
        "deprecated_property": 2,
        "current": 3,
    }
    findings.sort(key=lambda r: (
        priority.get(r["status"], 9),
        -r["instances"],
        r["class"],
        r["property"],
    ))

    report = {
        "schemaVersion": 1,
        "scope": "Static compatibility inventory only. Missing/deprecated properties require Studio evidence before game changes.",
        "workingBuildSha256": json.loads(
            (Path(__file__).resolve().parents[1] / "rhs/working/BUILD_STATE.json").read_text(encoding="utf-8")
        )["expectedWorkingSha256"],
        "apiDump": {
            "repository": "MaximumADHD/Roblox-Client-Tracker",
            "commit": "fcd6994996bb655bef047c69f456463d94faa569",
            "robloxVersion": "0.741.19.7411056",
            "commitDate": "2026-09-29T19:57:18Z",
        },
        "summary": dict(sorted(summary.items())),
        "classesAbsentFromApi": dict(sorted(class_missing.items())),
        "findings": findings,
        "attention": [
            r for r in findings
            if r["status"] in {"missing_property", "current_but_not_loadable", "deprecated_property"}
        ],
        "scriptReferencedMissingProperties": [
            r for r in findings
            if r["status"] == "missing_property" and r.get("scriptReferenceCount", 0) > 0
        ],
    }

    Path(args.output).write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print("=== RHS_CURRENT_PROPERTY_API_AUDIT ===")
    for key, value in sorted(summary.items()):
        print("SUMMARY", key, value)
    for class_name, count in sorted(class_missing.items()):
        print("CLASS_ABSENT", class_name, count)
    for rec in report["attention"][:250]:
        print(
            "PROPERTY",
            rec["status"],
            rec["class"],
            rec["property"],
            "instances=" + str(rec["instances"]),
            "tags=" + ",".join(rec["tags"]),
            "xml_tags=" + json.dumps(rec["xmlTags"], separators=(",", ":")),
            "script_refs=" + str(rec.get("scriptReferenceCount", 0)),
        )
    print("=== END_RHS_CURRENT_PROPERTY_API_AUDIT ===")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
