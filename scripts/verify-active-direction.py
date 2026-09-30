#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

active_docs = [
    ROOT / "README.md",
    ROOT / "STATUS.md",
    ROOT / "AGENTS.md",
    ROOT / "DEVELOPMENT.md",
]

errors: list[str] = []

for path in active_docs:
    text = path.read_text(encoding="utf-8")
    if "Maze World direction: **RETIRED**" in text or "ARCHIVED" in text:
        continue
    if re.search(r"(?i)\bMaze World\b.*(?:active|foundation|chassis)", text):
        errors.append(f"{path.relative_to(ROOT)} still describes Maze World as active")

workflow_dir = ROOT / ".github" / "workflows"
allowed_write_workflows = {"build-rhs-working-copy.yml"}
for path in workflow_dir.glob("*.yml"):
    name = path.name.lower()
    text = path.read_text(encoding="utf-8")
    if "maze" in name and "rhs" not in name:
        errors.append(f"obsolete Maze workflow remains active: {path.relative_to(ROOT)}")
    if re.search(r"(?i)git push origin HEAD:main", text):
        errors.append(f"workflow can push directly to main: {path.relative_to(ROOT)}")
    if re.search(r"(?m)^\s*contents:\s*write\s*$", text) and path.name not in allowed_write_workflows:
        errors.append(f"unexpected contents:write workflow: {path.relative_to(ROOT)}")

required = {
    "README.md": "licensed archived **ROBLOX High School**",
    "STATUS.md": "Active foundation: **licensed archived ROBLOX High School build**",
    "AGENTS.md": "Licensed RHS Rebuild",
    "DEVELOPMENT.md": "Licensed RHS Rebuild",
    "docs/RHS_RUNTIME_SMOKE.md": "Licensed RHS Runtime Smoke Gate",
}
for rel, marker in required.items():
    path = ROOT / rel
    if not path.exists():
        errors.append(f"missing active-direction file: {rel}")
        continue
    if marker not in path.read_text(encoding="utf-8"):
        errors.append(f"active-direction marker missing from {rel}: {marker!r}")

if errors:
    print("ACTIVE_DIRECTION_GUARD_FAILED")
    for err in errors:
        print("-", err)
    raise SystemExit(1)

print("ACTIVE_DIRECTION_GUARD_OK")
print("ACTIVE_FOUNDATION rhs/working/ROBLOX High School.rbxl")
print("ARCHIVED_FOUNDATION game/")
