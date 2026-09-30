#!/usr/bin/env python3
from __future__ import annotations
import json, sys
from pathlib import Path

EXPECTED_CANDIDATE="3ffa9b75f18f51fc26feb0b1e3ec03862b46e5e3"

def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: test_rhs_class_activity_contract.py <diagnostic.json>")
    data=json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    actual=data.get("candidateSha")
    if actual != EXPECTED_CANDIDATE:
        raise SystemExit(f"candidate mismatch: {actual} != {EXPECTED_CANDIDATE}")

    activities=data.get("strictServerClassActivityCandidates", [])
    if not activities:
        raise SystemExit(
            "BLOCKED: no qualifying server-authoritative class activity. "
            "Required: a server-side class/subject flow that owns question semantics "
            "and grade/points authority; client must not own the answer key."
        )

    print("RHS_CLASS_ACTIVITY_CONTRACT_PASS", len(activities))
    return 0

if __name__=="__main__":
    raise SystemExit(main())
