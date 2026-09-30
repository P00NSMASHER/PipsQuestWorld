#!/usr/bin/env python3
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
RHS = ROOT / "rhs"

baseline_meta = json.loads((RHS / "BASELINE.json").read_text())
state = json.loads((RHS / "working" / "BUILD_STATE.json").read_text())

expected_sha = baseline_meta["identity"]["sha256"]
expected_size = baseline_meta["identity"]["bytes"]

baseline = RHS / "baseline" / "ROBLOX High School.rbxl"
working = RHS / "working" / "ROBLOX High School.rbxl"

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

if not baseline.exists():
    raise SystemExit("missing immutable RHS baseline")
if baseline.stat().st_size != expected_size:
    raise SystemExit(f"baseline size mismatch: {baseline.stat().st_size} != {expected_size}")

actual = sha256(baseline)
if actual != expected_sha:
    raise SystemExit(f"baseline SHA-256 mismatch: {actual} != {expected_sha}")

if baseline.read_bytes()[:14].hex() != baseline_meta["identity"]["binaryHeaderHex"]:
    raise SystemExit("baseline Roblox binary header mismatch")

if state["baselineSha256"] != expected_sha:
    raise SystemExit("BUILD_STATE baseline hash disagrees with BASELINE.json")

if not working.exists():
    raise SystemExit("working copy missing")

working_sha = sha256(working)
expected_working_sha = state.get("expectedWorkingSha256")
if expected_working_sha and working_sha != expected_working_sha:
    raise SystemExit(
        f"working SHA-256 mismatch: {working_sha} != {expected_working_sha}"
    )

if state["stage"] == "baseline_exact":
    if working.stat().st_size != expected_size:
        raise SystemExit("working copy size differs before repairs")
    if working_sha != expected_sha:
        raise SystemExit("working copy is not byte-for-byte baseline during baseline_exact stage")
    if state.get("modifiedFromBaseline"):
        raise SystemExit("baseline_exact stage cannot be marked modified")

if state["stage"] == "compatibility_repair":
    if not state.get("modifiedFromBaseline"):
        raise SystemExit("compatibility_repair stage must be marked modified")
    if working_sha == expected_sha:
        raise SystemExit("compatibility_repair stage unexpectedly equals immutable baseline")

print("RHS_BASELINE_IDENTITY_OK", expected_sha, expected_size)
print("RHS_WORKING_IDENTITY_OK", working_sha, state["stage"])
