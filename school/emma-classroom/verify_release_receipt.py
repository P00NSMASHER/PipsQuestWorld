#!/usr/bin/env python3
"""Audit a historical GitHub-confirmed Roblox publish receipt, without publishing.

This is a repo-local release *consistency* check, not a Roblox Open Cloud
live-version query or native/iPhone acceptance. Never infer current production
state from a candidate branch head.
"""
from __future__ import annotations

import argparse
import copy
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RECEIPT = HERE / "RELEASE_RECEIPT.json"
HEX40 = re.compile(r"[0-9a-f]{40}")
HEX64 = re.compile(r"[0-9a-f]{64}")
IMMUTABLE_PUBLISH_FIELDS = (
    "sourceCommit", "workflowRunId", "workflowUrl", "placeId",
    "universeId", "mode", "visualAcceptance", "binarySha256",
)


def validate_receipt(data: dict) -> dict:
    assert data.get("schemaVersion") == 1, "Unknown release receipt schema"
    latest = data.get("lastConfirmedPublication")
    assert isinstance(latest, dict), "Missing recorded publication"
    assert type(latest.get("versionNumber")) is int and latest["versionNumber"] >= 1
    assert type(latest.get("workflowRunId")) is int and latest["workflowRunId"] > 0
    assert isinstance(latest.get("sourceCommit"), str) and (
        HEX40.fullmatch(latest["sourceCommit"])
    ), "Not an exact source SHA"
    assert isinstance(latest.get("binarySha256"), str) and (
        HEX64.fullmatch(latest["binarySha256"])
    ), "Published binary SHA-256 must be a real 64-character digest"
    assert latest.get("placeId") == "114603280760042"
    assert latest.get("universeId") == "10769455759"
    assert latest.get("mode") in ("classroom-progress-preview-only",
                                  "classroom-and-hallway-preview-only"), (
        "Unknown classroom publication mode"
    )
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


def validate_comparable_base_receipt(data: dict) -> dict:
    """Validate a base receipt, including the one legacy pre-digest format.

    Candidate receipts always use validate_receipt() and therefore always
    require the published binary digest. A historic PR base may omit that
    field because it predates binary provenance; all of its other release
    and safety assertions remain subject to the strict validator.
    """
    latest = data.get("lastConfirmedPublication")
    assert isinstance(latest, dict), "Missing recorded publication"
    if "binarySha256" in latest:
        return validate_receipt(data)

    legacy = copy.deepcopy(data)
    legacy["lastConfirmedPublication"]["binarySha256"] = "0" * 64
    checked = copy.deepcopy(validate_receipt(legacy))
    checked["binarySha256"] = None
    return checked


def compare_publication_receipts(candidate: dict, base: dict) -> str:
    """Detect rollback/evidence substitution against a comparable base branch.

    This is consistency checking, not verification that a *newer* publication
    actually happened. Only a successful publish run and its binary artifact
    can establish that. The baseline comes from the PR base branch, not an
    untrusted filename or self-declared candidate publication.
    """
    current=validate_receipt(candidate)
    previous=validate_comparable_base_receipt(base)
    now,then=current["versionNumber"],previous["versionNumber"]
    assert now>=then, (
        f"RELEASE_RECEIPT_VERSION_ROLLBACK candidate_v={now} base_v={then}"
    )
    if now==then:
        for field in IMMUTABLE_PUBLISH_FIELDS:
            if field == "binarySha256" and previous[field] is None:
                continue
            assert current[field]==previous[field], (
                f"RELEASE_RECEIPT_SAME_VERSION_EVIDENCE_MISMATCH {field}"
            )
        if previous["binarySha256"] is None:
            return "same_legacy_publication_base_without_binary_digest"
        return "same_verified_publication_as_base"
    # A later version must not reuse the previous version's source SHA,
    # workflow run ID or published binary. CI cannot independently attest
    # a new Roblox API publication merely because these strings changed.
    assert current["workflowRunId"]>previous["workflowRunId"], (
        "RELEASE_RECEIPT_NEW_VERSION_RUN_NOT_LATER"
    )
    assert current["sourceCommit"]!=previous["sourceCommit"], (
        "RELEASE_RECEIPT_NEW_VERSION_SOURCE_UNCHANGED"
    )
    if previous["binarySha256"] is not None:
        assert current["binarySha256"]!=previous["binarySha256"], (
            "RELEASE_RECEIPT_NEW_VERSION_BINARY_UNCHANGED"
        )
        return "newer_reported_requires_independent_publish_artifact_verification"
    return (
        "newer_reported_vs_legacy_base_requires_independent_"
        "publish_artifact_verification"
    )


def audit(compare_base: Path | None = None) -> None:
    candidate=json.loads(RECEIPT.read_text(encoding="utf-8"))
    latest = validate_receipt(candidate)
    if compare_base is not None:
        base=json.loads(compare_base.read_text(encoding="utf-8"))
        status=compare_publication_receipts(candidate,base)
        print("RELEASE_PR_BASE_MONOTONIC_PASS",
              "base_version="+str(base["lastConfirmedPublication"]["versionNumber"]),
              "candidate_version="+str(latest["versionNumber"]),
              "comparison="+status,
              "native_phone_acceptance_not_inferred",flush=True)
    preview = (HERE / "PREVIEW_REQUEST").read_text(encoding="utf-8")
    request_lines = preview.splitlines()
    modes = {
        "requested-mode: classroom-progress-preview-only",
        "requested-mode: classroom-and-hallway-preview-only",
    }
    present_modes = set(request_lines) & modes
    assert len(present_modes) == 1, "Missing or ambiguous preview mode"
    for exact in (
        "visual-acceptance: pending-real-device-review",
        "target-universe: " + latest["universeId"],
        "target-place: " + latest["placeId"],
    ):
        assert exact in request_lines, "Preview request diverges: " + exact
    if "requested-mode: classroom-and-hallway-preview-only" in present_modes:
        for exact in (
            "authorization: user-approved-2026-10-11-hallway-preview",
            "source-branch: visual/emma-hallway-photo-faithful-20261010",
            "build-project: school/emma-showroom.project.json",
        ):
            assert exact in request_lines, "New preview lacks approval: " + exact
        pinned = [line.split(": ", 1)[1] for line in request_lines
                  if line.startswith("source-parent-sha: ")]
        assert len(pinned) == 1 and HEX40.fullmatch(pinned[0]), (
            "New preview lacks a pinned source-parent SHA"
        )

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
    # Confirm only the latest October 10 hallway branch may publish. Require
    # the one-file, parent-pinned, user-approved marker and strict source QA.
    # Historic receipt modes remain factual history, never a release bypass.
    for guard in (
        'request=school/emma-classroom/PREVIEW_REQUEST',
        'test "$GITHUB_EVENT_NAME" = \'push\'',
        'test "$changed" = "$request"',
        'grep -qx "source-parent-sha: $source_parent" "$request"',
        "EXPLICIT_CLASSROOM_HALLWAY_PREVIEW_GUARD_PASS",
        "authorization: user-approved-2026-10-11-hallway-preview",
        "visual/emma-hallway-photo-faithful-20261010",
        "python3 school/emma-classroom/showroom/audit_lighting.py",
        "python3 school/emma-classroom/showroom/audit_storybook_facing.py",
        "python3 school/emma-classroom/showroom/audit_native_rug_primitives.py",
        "python3 school/emma-classroom/showroom/audit_native_chair_vents.py",
        "python3 school/emma-classroom/showroom/audit_purple_corner_chair.py",
        "python3 school/emma-classroom/showroom/audit_window_landmarks.py",
        "python3 school/emma-classroom/showroom/audit_native_foliage_primitives.py",
        "python3 school/emma-classroom/showroom/audit_glazed_door_aperture.py",
        "python3 school/emma-classroom/showroom/audit_hallway_photo.py",
        "python3 school/emma-classroom/showroom/audit_notebook_rule_surfaces.py",
        "python3 school/emma-classroom/showroom/audit_rug_ui.py",
        "grep -q 'Enabled = false'",
    ):
        assert guard in workflow, "Missing gated preview publication rule: " + guard
    assert "rebuild/emma-classroom-study-v1" not in workflow, (
        "Archive study branch reintroduced to production publisher"
    )
    assert "workflow_dispatch" not in workflow, (
        "One-time preview can be retriggered without a new approved commit"
    )

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
        ("binarySha256", "not-a-real-256-bit-digest"),
        ("workflowRunId", -1),
        ("visualAcceptance", "approved"),
        ("mode", "legacy-neighborhood-game"),
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
    # A current PR must never roll the parent branch's verified release
    # history backwards, nor substitute a new source/run/hash for the SAME
    # Roblox version number. None of these test fixtures publish anything.
    old=copy.deepcopy(original)
    old_pub=old["lastConfirmedPublication"]
    old_pub["versionNumber"]=max(1,old_pub["versionNumber"]-1)
    old_pub["workflowRunId"]=max(1,old_pub["workflowRunId"]-1)
    old_pub["workflowUrl"]=(
        "https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/"
        +str(old_pub["workflowRunId"]))
    old_pub["sourceCommit"]="a"*40
    old_pub["binarySha256"]="b"*64
    try:
        compare_publication_receipts(old,original)
    except AssertionError as exc:
        assert "RELEASE_RECEIPT_VERSION_ROLLBACK" in str(exc)
    else:
        raise AssertionError("Backward version was accepted")
    assert compare_publication_receipts(original,original)==(
        "same_verified_publication_as_base"
    )
    legacy_same=copy.deepcopy(original)
    legacy_same["lastConfirmedPublication"].pop("binarySha256")
    assert compare_publication_receipts(original,legacy_same)==(
        "same_legacy_publication_base_without_binary_digest"
    )
    legacy_old=copy.deepcopy(old)
    legacy_old["lastConfirmedPublication"].pop("binarySha256")
    assert compare_publication_receipts(original,legacy_old).startswith(
        "newer_reported_vs_legacy_base_requires_independent_"
        "publish_artifact_verification"
    )
    malformed_legacy=copy.deepcopy(legacy_old)
    malformed_legacy["lastConfirmedPublication"]["binarySha256"]="not-a-digest"
    try:
        validate_comparable_base_receipt(malformed_legacy)
    except AssertionError:
        pass
    else:
        raise AssertionError("Malformed historic binary digest was accepted")
    for name,field,changed in (
        ("source_swap","sourceCommit","e"*40),
        ("binary_swap","binarySha256","f"*64),
        ("publish_run_swap","workflowRunId",original["lastConfirmedPublication"]["workflowRunId"]+1),
    ):
        forged=copy.deepcopy(original)
        forged["lastConfirmedPublication"][field]=changed
        if field=="workflowRunId":
            forged["lastConfirmedPublication"]["workflowUrl"]=(
                "https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/"
                +str(changed))
        try:
            compare_publication_receipts(forged,original)
        except AssertionError as exc:
            assert "SAME_VERSION_EVIDENCE_MISMATCH" in str(exc), (name,exc)
        else:
            raise AssertionError("Equal-version forged publisher accepted: "+name)
    forward=copy.deepcopy(original)
    fw=forward["lastConfirmedPublication"]
    fw["versionNumber"]+=1
    fw["workflowRunId"]+=1
    fw["workflowUrl"]=(
        "https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/"
        +str(fw["workflowRunId"]))
    fw["sourceCommit"]="c"*40
    fw["binarySha256"]="d"*64
    assert compare_publication_receipts(forward,original).startswith(
        "newer_reported_requires_independent_publish_artifact_verification"
    )
    forward["nativeIphoneAcceptanceVerified"]=True
    try:
        compare_publication_receipts(forward,original)
    except AssertionError:
        pass
    else:
        raise AssertionError("False native iPhone approval accepted")
    print("RELEASE_PROVENANCE_SELF_TEST_PASS forged status, activation, "
          "v81_rollback, same_version_source_run_hash_swap, "
          "legacy_base_digest_compatibility, native_approval_rejected")


if __name__ == "__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--self-test",action="store_true")
    parser.add_argument("--compare-base",type=Path,default=None,
                        help="PR target branch's committed release receipt JSON")
    args=parser.parse_args()
    try:
        if args.self_test:
            self_test()
        else:
            audit(compare_base=args.compare_base)
    except (AssertionError, KeyError, ValueError) as exc:
        print("RELEASE_PROVENANCE_FAIL", str(exc), file=sys.stderr)
        sys.exit(1)
