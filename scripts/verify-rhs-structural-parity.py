#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}

BLANK_LOOKUP_PATTERNS = [
    re.compile(r'(?:WaitForChild|FindFirstChild)\s*\(\s*["\']\s+["\']'),
    re.compile(r'\[\s*["\']\s+["\']\s*\]'),
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

def raw_item_name(item) -> str:
    return prop_text(item, "Name")

def canonical_item_name(item) -> str:
    raw = raw_item_name(item)
    if raw.strip() == "":
        return "(blank)"
    return raw

def walk(parent, prefix: str = ""):
    for item in parent.findall("Item"):
        name = canonical_item_name(item)
        here = f"{prefix}/{name}" if prefix else name
        yield item, here
        yield from walk(item, here)

def source_sha(source: str) -> str:
    return hashlib.sha256(source.encode("utf-8")).hexdigest()

def inventory(xml_path: str):
    root = ET.parse(xml_path).getroot()
    hierarchy = collections.Counter()
    classes = collections.Counter()
    scripts = {}
    blank_name_forms = collections.Counter()
    blank_lookup_hits = []

    for item, path in walk(root):
        cls = item.attrib.get("class", "")
        hierarchy[(path, cls)] += 1
        classes[cls] += 1

        raw_name = raw_item_name(item)
        if raw_name.strip() == "":
            if raw_name == "":
                blank_name_forms["empty"] += 1
            else:
                blank_name_forms["whitespace_only"] += 1

        if cls in SCRIPT_CLASSES:
            source = prop_text(item, "Source")
            scripts.setdefault((path, cls), []).append(source_sha(source))
            for regex in BLANK_LOOKUP_PATTERNS:
                for line_no, line in enumerate(source.splitlines(), start=1):
                    if regex.search(line):
                        blank_lookup_hits.append({
                            "path": path,
                            "class": cls,
                            "line": line_no,
                        })

    for values in scripts.values():
        values.sort()

    return {
        "total": sum(classes.values()),
        "hierarchy": hierarchy,
        "classes": classes,
        "scripts": scripts,
        "blankNameForms": blank_name_forms,
        "blankLookupHits": blank_lookup_hits,
    }

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--baseline-xml", required=True)
    ap.add_argument("--working-xml", required=True)
    ap.add_argument("--build-receipt", required=True)
    args = ap.parse_args()

    baseline = inventory(args.baseline_xml)
    working = inventory(args.working_xml)
    receipt = json.loads(Path(args.build_receipt).read_text(encoding="utf-8"))

    if baseline["total"] != working["total"]:
        raise SystemExit(
            f"instance-count drift: {baseline['total']} != {working['total']}"
        )

    if baseline["classes"] != working["classes"]:
        missing = baseline["classes"] - working["classes"]
        extra = working["classes"] - baseline["classes"]
        raise SystemExit(f"class-count drift: missing={dict(missing)} extra={dict(extra)}")

    if baseline["hierarchy"] != working["hierarchy"]:
        missing = baseline["hierarchy"] - working["hierarchy"]
        extra = working["hierarchy"] - baseline["hierarchy"]
        raise SystemExit(
            f"canonical hierarchy drift: missing={list(missing.items())[:20]} "
            f"extra={list(extra.items())[:20]}"
        )

    baseline_blank_total = sum(baseline["blankNameForms"].values())
    working_blank_total = sum(working["blankNameForms"].values())
    if baseline_blank_total != working_blank_total:
        raise SystemExit(
            f"blank-name instance count drift: {baseline_blank_total} != {working_blank_total}"
        )

    if baseline["blankNameForms"] != working["blankNameForms"]:
        if baseline["blankLookupHits"]:
            raise SystemExit(
                "converter normalized blank/whitespace-only instance names but baseline scripts "
                f"contain explicit whitespace-name lookups: {baseline['blankLookupHits'][:20]}"
            )
        print(
            "RHS_ALLOWED_SERIALIZER_NORMALIZATION blank_names",
            dict(baseline["blankNameForms"]),
            "->",
            dict(working["blankNameForms"]),
        )

    patched = {}
    for p in receipt["patchReceipt"]["appliedPatches"]:
        patched[(p["targetPath"], p["class"])] = p

    if set(baseline["scripts"]) != set(working["scripts"]):
        raise SystemExit("script path/class inventory drift")

    for key, baseline_hashes in baseline["scripts"].items():
        working_hashes = working["scripts"][key]
        if key in patched:
            p = patched[key]
            if len(baseline_hashes) != 1 or len(working_hashes) != 1:
                raise SystemExit(f"patched script path is not unique: {key}")
            if baseline_hashes[0] != p["beforeSourceSha256"]:
                raise SystemExit(f"patched script baseline source hash drift: {key}")
            if working_hashes[0] != p["afterSourceSha256"]:
                raise SystemExit(f"patched script working source hash drift: {key}")
        else:
            if baseline_hashes != working_hashes:
                raise SystemExit(f"unpatched script source drift: {key}")

    print("RHS_STRUCTURAL_PARITY_OK")
    print("INSTANCES", baseline["total"])
    print("DISTINCT_CLASSES", len(baseline["classes"]))
    print("SCRIPTS", sum(len(v) for v in baseline["scripts"].values()))
    print("INTENTIONAL_SCRIPT_CHANGES", len(patched))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
