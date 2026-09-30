#!/usr/bin/env python3
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SCHOOL = ROOT / "school"

required = [
    SCHOOL / "default.project.json",
    SCHOOL / "src/shared/SchoolConfig.lua",
    SCHOOL / "src/server/QuestionBank.lua",
    SCHOOL / "src/server/CampusBuilder.server.lua",
    SCHOOL / "src/server/SchoolLoop.server.lua",
    SCHOOL / "src/client/SchoolHud.client.lua",
]

missing = [str(p.relative_to(ROOT)) for p in required if not p.exists()]
if missing:
    raise SystemExit("missing required school files: " + ", ".join(missing))

project = json.loads((SCHOOL / "default.project.json").read_text())
if project.get("name") != "PipHigh":
    raise SystemExit("active Rojo project must be named PipHigh")

project_text = (SCHOOL / "default.project.json").read_text().lower()
if "maze" in project_text or "../game" in project_text:
    raise SystemExit("active school project must not depend on legacy Maze World")

client_and_shared = "
".join(
    p.read_text(errors="ignore")
    for base in (SCHOOL / "src/client", SCHOOL / "src/shared")
    for p in base.rglob("*.lua")
)

for forbidden in ("correctIndex", "correctAnswer", "answerKey"):
    if forbidden in client_and_shared:
        raise SystemExit(f"answer-key token leaked into client/shared code: {forbidden}")

server = (SCHOOL / "src/server/SchoolLoop.server.lua").read_text()
if "choiceIndex == question.correctIndex" not in server:
    raise SystemExit("server-authoritative answer check not found")

if "QuestionBank" not in server:
    raise SystemExit("server is not using the server-only question bank")

school_text = "
".join(p.read_text(errors="ignore") for p in SCHOOL.rglob("*") if p.is_file())
protected_clone_terms = [
    r"Roblox\s+High\s+School\s*2",
    r"Roblox\s+High\s+School",
]
for pattern in protected_clone_terms:
    if re.search(pattern, school_text, flags=re.IGNORECASE):
        raise SystemExit("protected third-party game branding found inside active school source")

print("PIP_HIGH_STATIC_GUARDS_OK")
