#!/usr/bin/env python3
from __future__ import annotations

import argparse
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

def walk(parent, prefix=""):
    for item in parent.findall("Item"):
        name = item_name(item).replace("/", "_")
        path = f"{prefix}/{name}" if prefix else name
        yield item, path
        yield from walk(item, path)

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--xml", required=True)
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--manifest", required=True)
    args = ap.parse_args()

    root = ET.parse(args.xml).getroot()
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    manifest = []
    index = 0
    for item, path in walk(root):
        cls = item.attrib.get("class", "")
        if cls not in SCRIPT_CLASSES:
            continue
        source = prop_text(item, "Source")
        if not source:
            continue
        index += 1
        filename = f"{index:04d}.luau"
        target = out_dir / filename
        target.write_text(source, encoding="utf-8")
        manifest.append({
            "file": filename,
            "path": path,
            "class": cls,
            "sourceBytes": len(source.encode("utf-8")),
        })

    Path(args.manifest).write_text(
        json.dumps({"schemaVersion": 1, "scripts": manifest}, indent=2) + "\n",
        encoding="utf-8",
    )

    print("RHS_LUAU_EXTRACT_OK", len(manifest))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
