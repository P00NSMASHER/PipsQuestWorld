#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}

def prop_node(item, name: str):
    props = item.find("Properties")
    if props is None:
        return None
    for prop in props:
        if prop.attrib.get("name") == name:
            return prop
    return None

def prop_text(item, name: str) -> str:
    prop = prop_node(item, name)
    if prop is None:
        return ""
    if prop.tag == "Content":
        child = next(iter(prop), None)
        return (child.text or "") if child is not None else ""
    return prop.text or ""

def set_prop_text(item, name: str, value: str) -> None:
    prop = prop_node(item, name)
    if prop is None:
        raise RuntimeError(f"missing property {name}")
    if prop.tag == "Content":
        child = next(iter(prop), None)
        if child is None:
            raise RuntimeError(f"content property {name} has no child")
        child.text = value
    else:
        prop.text = value

def item_name(item) -> str:
    return prop_text(item, "Name") or "(unnamed)"

def walk(parent, prefix: str = ""):
    for item in parent.findall("Item"):
        name = item_name(item)
        here = f"{prefix}/{name}" if prefix else name
        yield item, here
        yield from walk(item, here)

def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--xml", required=True)
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--output-xml", required=True)
    ap.add_argument("--receipt", required=True)
    args = ap.parse_args()

    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    tree = ET.parse(args.xml)
    root = tree.getroot()

    scripts = []
    for item, path in walk(root):
        cls = item.attrib.get("class", "")
        if cls in SCRIPT_CLASSES:
            scripts.append((item, path, cls, prop_text(item, "Source")))

    receipt = {
        "schemaVersion": 1,
        "baselineSha256": manifest["baselineSha256"],
        "appliedPatches": [],
    }

    for patch in manifest.get("patches", []):
        target = patch["targetPath"]
        expected_sha = patch["expectedSourceSha256"]
        matches = [
            (item, path, cls, src)
            for item, path, cls, src in scripts
            if path == target and sha256_text(src) == expected_sha
        ]
        if len(matches) != 1:
            raise SystemExit(
                f"patch {patch['id']}: expected exactly one target for {target} "
                f"with source SHA {expected_sha}, found {len(matches)}"
            )

        item, path, cls, source = matches[0]
        before_sha = sha256_text(source)
        updated = source

        replacement_receipt = []
        for repl in patch.get("replacements", []):
            old = repl["old"]
            new = repl["new"]
            expected_count = repl["expectedCount"]
            actual_count = updated.count(old)
            if actual_count != expected_count:
                raise SystemExit(
                    f"patch {patch['id']}: replacement count mismatch for {target}: "
                    f"{actual_count} != {expected_count}"
                )
            updated = updated.replace(old, new)
            replacement_receipt.append({
                "expectedCount": expected_count,
                "oldSha256": sha256_text(old),
                "newSha256": sha256_text(new),
            })

        after_sha = sha256_text(updated)
        expected_after = patch.get("expectedPostSourceSha256")
        if expected_after and after_sha != expected_after:
            raise SystemExit(
                f"patch {patch['id']}: post-patch source hash mismatch: "
                f"{after_sha} != {expected_after}"
            )

        set_prop_text(item, "Source", updated)
        receipt["appliedPatches"].append({
            "id": patch["id"],
            "targetPath": path,
            "class": cls,
            "beforeSourceSha256": before_sha,
            "afterSourceSha256": after_sha,
            "replacements": replacement_receipt,
        })

    tree.write(args.output_xml, encoding="utf-8", xml_declaration=True)
    Path(args.receipt).write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print("RHS_SCRIPT_PATCHES_APPLIED", len(receipt["appliedPatches"]))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
