#!/usr/bin/env python3
"""Audit a historical GitHub-confirmed Roblox publish receipt, without publishing.

This is a repo-local release *consistency* check, not a Roblox Open Cloud
live-version query or native/iPhone acceptance. Never infer current production
state from a candidate branch head.
"""
from __future__ import annotations

import copy
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RECEIPT = HERE / "RELEASE_RECEIPT.json"
HEX40 = re.compile(r"[0-9a-f]{40}")


def validate_receipt(data: dict) -> dict:
    assert data.get("schemaVersion") == 1, "Unknown release receipt schema"
    latest = data.get("lastConfirmedPublication")
    assert isinstance(latest, dict), "Missing recorded publication"
    assert type(latest.get("versionNumber")) is int and latest["versionNumber"] >= 1
    assert type(latest.get("workflowRunId")) is int and latest["workflowRunId"] > 0
    assert HEX40.fullmatch(latest.get("sourceCommit", "")), "Not an exact source SHA"
    assert latest.get("placeId") == "114603280760042"
    assert latest.get("universeId") == "10769455759"
    assert latest.get("mode") == "classroom-progress-preview-only"
    assert latest.get("visualAcceptance") == "pending-real-device-review"
    assert latest.get("workflowUrl") == (
        "https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/"
        + str(latest["workflowRunId"])
    ), "Unrelated or unaudited workflow URL"
    assert data.get("productionFurnitureMeshesEnabled") is False
    assert data.get("nativeIphoneAcceptanceVerified") is False
    assert "unpublished candidate" in data.get("nextCandidatePolicy", "").lower(), (
        "Historical preview cannot attest that new PR source has been published"
    )
    return latest


def audit() -> None:
    latest = validate_receipt(json.loads(RECEIPT.read_text(encoding="utf-8")))
    preview = (HERE / "PREVIEW_REQUEST").read_text(encoding="utf-8")
    for exact in (
        "requested-mode: classroom-progress-preview-only",
        "visual-acceptance: pending-real-device-review",
        "target-universe: " + latest["universeId"],
        "target-place: " + latest["placeId"],
    ):
        assert exact in preview.splitlines(), "Preview request diverges: " + exact

    config = (HERE / "showroom" / "FurnitureMeshConfig.lua").read_text(encoding="utf-8")
    assets = json.loads((HERE / "mesh" / "imported_models.json").read_text(encoding="utf-8"))
    assert re.search(r"(?m)^\s*Enabled\s*=\s*false\s*,?\s*$", config), (
        "Unreviewed model activation violates release hold"
    )
    assert assets["productionEnabled"] is False, "Approved models were silently enabled"
    assert assets["universeId"] == latest["universeId"]
    assert assets["rootPlaceId"] == latest["placeId"]

    workflow = (ROOT / ".github/workflows/publish-emma-classroom.yml").read_text(
        encoding="utf-8"
    )
    # Fail closed if someone allows an ordinary push to PR #339 to republish
    # an unaccepted candidate. The historical preview required a dedicated
    # commit changing PREVIEW_REQUEST only, plus an exact source-parent lease.
    for guard in (
        'request=school/emma-classroom/PREVIEW_REQUEST',
        'test "$changed" = "$request"',
        'grep -qx "source-parent-sha: $parent" "$request"',
        "USER_AUTHORIZED_PREVIEW_WITHOUT_FINAL_VISUAL_ACCEPTANCE",
        "grep -q 'Enabled = false'",
    ):
        assert guard in workflow, "Missing gated preview publication rule: " + guard

    print(
        "RELEASE_PROVENANCE_PASS",
        "last_confirmed_version=" + str(latest["versionNumber"]),
        "published_source=" + latest["sourceCommit"],
        "publish_run=" + str(latest["workflowRunId"]),
        "candidate_branch_is_not_proof_of_publication",
        "native_iphone_acceptance_pending",
        "mesh_activation_disabled",
        flush=True,
    )


def self_test() -> None:
    original = json.loads(RECEIPT.read_text(encoding="utf-8"))
    validate_receipt(original)
    cases = (
        ("versionNumber", 0),
        ("sourceCommit", "not-a-sha"),
        ("workflowRunId", -1),
        ("visualAcceptance", "approved"),
    )
    for field, broken in cases:
        tampered = copy.deepcopy(original)
        tampered["lastConfirmedPublication"][field] = broken
        try:
            validate_receipt(tampered)
        except AssertionError:
            continue
        raise AssertionError("Tampered release receipt accepted: " + field)
    for field in ("productionFurnitureMeshesEnabled", "nativeIphoneAcceptanceVerified"):
        tampered = copy.deepcopy(original)
        tampered[field] = True
        try:
            validate_receipt(tampered)
        except AssertionError:
            continue
        raise AssertionError("Unsupported release approval accepted: " + field)
    print("RELEASE_PROVENANCE_SELF_TEST_PASS forged status and activation rejected")


if __name__ == "__main__":
    try:
        if "--self-test" in sys.argv:
            self_test()
        else:
            audit()
    except (AssertionError, KeyError, ValueError) as exc:
        print("RELEASE_PROVENANCE_FAIL", str(exc), file=sys.stderr)
        sys.exit(1)
