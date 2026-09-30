#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}

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
        name = item_name(item)
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

    for item, path in walk(root):
        cls = item.attrib.get("class", "")
        hierarchy[(path, cls)] += 1
        classes[cls] += 1

        if cls in SCRIPT_CLASSES:
            scripts.setdefault((path, cls), []).append(
                source_sha(prop_text(item, "Source"))
            )

    for values in scripts.values():
        values.sort()

    return {
        "total": sum(classes.values()),
        "hierarchy": hierarchy,
        "classes": classes,
        "scripts": scripts,
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
            f"hierarchy drift: missing={list(missing.items())[:20]} "
            f"extra={list(extra.items())[:20]}"
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
