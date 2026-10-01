#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", required=True)
    ap.add_argument("--build-state", default="rhs/working/BUILD_STATE.json")
    args = ap.parse_args()

    report = json.loads(Path(args.report).read_text(encoding="utf-8"))
    state = json.loads(Path(args.build_state).read_text(encoding="utf-8"))

    errors = []
    if report.get("candidateWorkingSha256") != state.get("expectedWorkingSha256"):
        errors.append("QA report working SHA does not match BUILD_STATE")

    strict = report.get("strictServerClassActivityCandidates") or []
    strict_paths = [
        item.get("path") if isinstance(item, dict) else item
        for item in strict
    ]
    if not strict_paths:
        errors.append("QA detector still finds zero strict server-authoritative class activities")
    if "ServerScriptService/Time_ScheduleScript" not in strict_paths:
        errors.append("QA detector does not identify Time_ScheduleScript as a strict server class activity")

    if report.get("clientOrReplicatedAnswerKeyCandidates"):
        errors.append("QA detector found client/replicated answer-key candidates")

    if errors:
        print("RHS_CLASS_ACTIVITY_QA_REGRESSION_FAILED")
        for error in errors:
            print("-", error)
        raise SystemExit(1)

    print("RHS_CLASS_ACTIVITY_QA_REGRESSION_PASS")
    print("WORKING_SHA256", state.get("expectedWorkingSha256"))
    print("STRICT_SERVER_CLASS_ACTIVITY_CANDIDATES", len(strict_paths))
    for path in strict_paths:
        print("STRICT_ACTIVITY", path)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
