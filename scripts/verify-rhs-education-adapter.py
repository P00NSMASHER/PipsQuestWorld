#!/usr/bin/env python3
from pathlib import Path
import re

root=Path(__file__).resolve().parents[1]
engine=root/"rhs/education/EducationEngine.lua"
spec=root/"rhs/education/tests/education_engine_spec.lua"
doc=root/"docs/RHS_EDUCATION_ADAPTER.md"

for path in (engine,spec,doc):
    if not path.exists():
        raise SystemExit(f"missing RHS education adapter artifact: {path.relative_to(root)}")

engine_text=engine.read_text(encoding="utf-8")
spec_text=spec.read_text(encoding="utf-8")
doc_text=doc.read_text(encoding="utf-8")

for token in (
    "game:GetService",
    "Workspace",
    "Players",
    "DataStore",
    "RemoteEvent",
    "RemoteFunction",
    "Instance.new",
    "leaderstats",
    "SchoolCampus",
    "CampusBuilder",
    "Time_ScheduleScript",
    "task.wait",
    "task.spawn",
):
    if token in engine_text:
        raise SystemExit(f"education engine owns forbidden runtime concern: {token}")

for token in (
    "function EducationEngine.new",
    "function EducationEngine:beginSession",
    "function EducationEngine:nextActivity",
    "function EducationEngine:submit",
    "function EducationEngine:getSessionSnapshot",
    "function EducationEngine:closeSession",
):
    if token not in engine_text:
        raise SystemExit(f"missing EducationEngine API member: {token}")

safe_activity=re.search(r"local function safeActivity\(activity\)(.*?)\nend",engine_text,re.DOTALL)
if not safe_activity:
    raise SystemExit("safeActivity boundary not found")
for secret in ("correctIndex","misconceptions","explanation","hint"):
    if secret in safe_activity.group(1):
        raise SystemExit(f"server-only field leaks through safeActivity: {secret}")

for proof in (
    'assertNil(publicActivity.correctIndex',
    'assertNil(publicActivity.hint',
    'assertNil(publicActivity.explanation',
    'assertEqual(afterDuplicateWrong.activeAttempts, 1',
    'assertEqual(conflict.code, "idempotency_conflict"',
    'assertEqual(supportedSnapshot.history[1].independent, false',
    'assertEqual(closeStatus, "closed"',
):
    if proof not in spec_text:
        raise SystemExit(f"missing deterministic proof: {proof}")

for forbidden_doc_claim in (
    "injected into RHS binary: yes",
    "Roblox Studio proof: yes",
):
    if forbidden_doc_claim.lower() in doc_text.lower():
        raise SystemExit(f"adapter documentation overclaims state: {forbidden_doc_claim}")

print("RHS_EDUCATION_ADAPTER_SCOPE_OK")
