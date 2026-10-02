#!/usr/bin/env python3
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
school = root / "school"
project = school / "default.project.json"

project_json = json.loads(project.read_text())

def collect_mapped_paths(node):
    if isinstance(node, dict):
        mapped = node.get("$path")
        if isinstance(mapped, str):
            yield mapped
        for value in node.values():
            yield from collect_mapped_paths(value)
    elif isinstance(node, list):
        for value in node:
            yield from collect_mapped_paths(value)

mapped_paths = sorted(set(collect_mapped_paths(project_json)))
if not mapped_paths:
    raise SystemExit("school/default.project.json has no mapped source paths")

for mapped in mapped_paths:
    path = Path(mapped)
    if path.is_absolute() or ".." in path.parts:
        raise SystemExit(f"unsafe project mapping: {mapped}")
    if not (school / path).exists():
        raise SystemExit(f"project mapping target missing: {mapped}")

print("PIP_HIGH_QA_PROJECT_MAPPINGS_OK")
