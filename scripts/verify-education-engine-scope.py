#!/usr/bin/env python3
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parents[1]
engine = root / "school/src/server/EducationEngine.lua"
spec = root / "school/tests/education_engine_spec.lua"
project = root / "school/default.project.json"
api_doc = root / "docs/HIGH_SCHOOL_EDUCATION_ENGINE_API.md"

for path in (engine, spec, project, api_doc):
    if not path.exists():
        raise SystemExit(f"missing education-engine artifact: {path.relative_to(root)}")

engine_text = engine.read_text()
spec_text = spec.read_text()
project_text = project.read_text()
project_json = json.loads(project_text)

if project_json.get("name") != "PipHigh":
    raise SystemExit("education engine is not attached to the PipHigh project")

server_tree = (
    project_json.get("tree", {})
    .get("ServerScriptService", {})
    .get("SchoolFoundation", {})
)
engine_mapping = server_tree.get("EducationEngine", {})
if engine_mapping.get("$path") != "src/server/EducationEngine.lua":
    raise SystemExit("EducationEngine must be mapped only under ServerScriptService/SchoolFoundation")

if "EducationEngine" in json.dumps(
    project_json.get("tree", {}).get("ReplicatedStorage", {})
):
    raise SystemExit("EducationEngine must not be mapped into ReplicatedStorage")

forbidden_runtime_tokens = (
    "game:GetService",
    "Workspace",
    "Players",
    "DataStore",
    "RemoteEvent",
    "RemoteFunction",
    "Instance.new",
    "leaderstats",
    "Points",
    "SchoolDay",
    "SchoolPeriod",
    "attendance",
    "grade",
    "reward",
    "os.clock",
    "tick(",
    "task.wait",
    "task.spawn",
)
for token in forbidden_runtime_tokens:
    if token in engine_text:
        raise SystemExit(f"education engine owns out-of-scope runtime concern: {token}")

required_api_tokens = (
    "function EducationEngine.new",
    "function EducationEngine:beginSession",
    "function EducationEngine:nextActivity",
    "function EducationEngine:submit",
    "function EducationEngine:getSessionSnapshot",
    "function EducationEngine:closeSession",
)
for token in required_api_tokens:
    if token not in engine_text:
        raise SystemExit(f"missing public API member: {token}")

safe_activity_match = re.search(
    r"local function safeActivity\(activity\)(.*?)\nend",
    engine_text,
    flags=re.DOTALL,
)
if not safe_activity_match:
    raise SystemExit("safeActivity boundary not found")
safe_activity_body = safe_activity_match.group(1)
for secret in ("correctIndex", "misconceptions", "explanation", "hint"):
    if secret in safe_activity_body:
        raise SystemExit(f"server-only answer data leaked through safeActivity: {secret}")

for proof_token in (
    'assertNil(publicActivity.correctIndex',
    'assertEqual(duplicateStatus, "duplicate"',
    'assertEqual(afterDuplicateWrong.activeAttempts, 1',
    'assertEqual(supportedSnapshot.history[1].independent, false',
    'assertEqual(second.id, "math-sum-2"',
):
    if proof_token not in spec_text:
        raise SystemExit(f"deterministic test is missing required proof: {proof_token}")

print("EDUCATION_ENGINE_SCOPE_GUARDS_OK")
