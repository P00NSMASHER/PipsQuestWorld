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



# The historical publisher was explicitly retired when ownership of the
# shared Emma place moved to the newer photo-classroom/hallway preview lane.
# A deny-only workflow is SAFER than the former guarded uploader; never
# require reinstating its credential-bearing steps merely to satisfy CI.
def verify_archived_replica_publisher(workflow: str) -> None:
    expected_branch = "visual/emma-classroom-replica-only-20261008"
    expected_place = "114603280760042"
    assert workflow.startswith(
        "# The live Emma Roblox place " + expected_place
    ), "Archived publisher ownership marker missing"
    assert "name: Emma Superseded Replica Publish Guard" in workflow
    expected_trigger = (
        "on:\n"
        "  push:\n"
        "    branches:\n"
        "      - " + expected_branch + "\n"
        "    paths:\n"
        "      - 'school/emma-classroom/PREVIEW_REQUEST'\n"
        "  workflow_dispatch:\n"
    )
    assert expected_trigger in workflow, "Archived publisher trigger scope changed"
    assert "\npermissions:\n  contents: read\n" in workflow
    assert "cancel-in-progress: false" in workflow
    assert "\njobs:\n" in workflow
    jobs_section = workflow.split("\njobs:\n", 1)[1]
    jobs = re.findall(r"(?m)^  ([a-zA-Z][a-zA-Z0-9_-]*):\s*$", jobs_section)
    assert jobs == ["archived-publish-guard"], (
        "Unexpected executable publisher job restored: " + str(jobs)
    )
    marker = (
        "      - name: Preserve legacy code but block shared-place publication\n"
        "        run: |\n"
    )
    assert jobs_section.count(marker) == 1, "Read-only refusal step missing"
    assert jobs_section.count("\n        run: |") == 1
    assert "uses:" not in jobs_section and "env:" not in jobs_section, (
        "Archived guard must not load deploy actions or credentials"
    )
    # Lock this obsolete workflow to four literal diagnostic echo commands.
    # Even a hidden extra curl, shell variable or secret reference is rejected.
    commands = [line.strip() for line in jobs_section.split(marker, 1)[1].splitlines()
                if line.strip()]
    expected = [
        "echo 'LEGACY_PUBLISH_BLOCKED place=" + expected_place +
        " branch=" + expected_branch + "'",
        "echo 'An older replica preview must not replace the newer "
        "photo-grounded classroom-and-hallway candidate.'",
        "echo 'No Roblox credential is loaded. No binary is uploaded.'",
        "echo 'This is intentionally not a scheduler or curriculum shutdown.'",
    ]
    assert commands == expected, "Archived publisher gained execution capability"

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
    # The archived workflow MUST remain deny-only; insisting on its old
    # credential-bearing preview upload would be a release-regression.
    verify_archived_replica_publisher(workflow)

    print(
        "RELEASE_PROVENANCE_PASS",
        "last_confirmed_version=" + str(latest["versionNumber"]),
        "published_source=" + latest["sourceCommit"],
        "publish_run=" + str(latest["workflowRunId"]),
        "candidate_branch_is_not_proof_of_publication",
        "legacy_shared_place_publisher_blocked",
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
    publisher = (ROOT / ".github/workflows/publish-emma-classroom.yml").read_text(
        encoding="utf-8"
    )
    verify_archived_replica_publisher(publisher)
    archive_mutants = {
        "write_permission": publisher.replace(
            "  contents: read", "  contents: write", 1
        ),
        "wrong_target": publisher.replace(
            "LEGACY_PUBLISH_BLOCKED place=114603280760042",
            "LEGACY_PUBLISH_BLOCKED place=999999", 1
        ),
        "resurrected_publish_job": publisher + (
            "\n  publish:\n    runs-on: ubuntu-24.04\n    steps:\n"
            "      - run: echo 'deploy'\n"
        ),
        "hidden_upload": publisher.replace(
            "          echo 'No Roblox credential is loaded. No binary is uploaded.'",
            "          curl -X POST https://apis.roblox.com/universes/v1",
            1,
        ),
    }
    for case, tampered in archive_mutants.items():
        assert tampered != publisher, "Broken archived-guard test fixture: " + case
        try:
            verify_archived_replica_publisher(tampered)
        except AssertionError:
            continue
        raise AssertionError("Unsafe archived publisher accepted: " + case)
    print(
        "RELEASE_PROVENANCE_SELF_TEST_PASS forged status and activation rejected "
        "archived_publisher_reactivation_rejected",
        flush=True,
    )


if __name__ == "__main__":
    try:
        if "--self-test" in sys.argv:
            self_test()
        else:
            audit()
    except (AssertionError, KeyError, ValueError) as exc:
        print("RELEASE_PROVENANCE_FAIL", str(exc), file=sys.stderr)
        sys.exit(1)
