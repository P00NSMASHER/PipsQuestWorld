#!/usr/bin/env python3
"""Validate draft receipts or exact-canonical runtime evidence integrity.

The final token certifies receipt completeness, identity and local-file integrity.
It does not establish that images depict a real runtime, physical-device testing,
or visual parity. Independent review of the recorded evidence remains required.
Static/compiler/headless results and synthetic self-tests cannot grant acceptance.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
import re
import sys
from pathlib import Path, PurePosixPath


SHA_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
REQUIRED_SOURCES = {
    "A": "libfile_94cb10b32d9c819186b9ad708b9d4736",
    "B": "libfile_427a25a0e78881919c3128e193b9df4d",
    "C": "libfile_a5903480efe88191a87e5f98ec9729bc",
}
PROFILE_GEOMETRY = {
    "desktop": ({"width": 909, "height": 483}, {"left": 0, "top": 0, "right": 0, "bottom": 0}),
    "iphone_landscape": ({"width": 852, "height": 393}, {"left": 47, "top": 12, "right": 47, "bottom": 21}),
    "ipad_landscape": ({"width": 1024, "height": 768}, {"left": 24, "top": 24, "right": 24, "bottom": 20}),
}
REQUIRED_PROFILES = set(PROFILE_GEOMETRY)
REQUIRED_CAPTURES = {"A_0005", "A_0025", "A_0045", "A_0125", "C_0005"}
REQUIRED_ROUTE = {
    "spawn", "entrance", "atrium_left", "atrium_right", "corridor",
    "stair_up", "stair_down", "class_free_roam", "menus", "save_rejoin",
}
REQUIRED_PANELS = {"shop", "travel", "avatar", "house", "housing_editor", "class_activity_modal", "cafe", "vehicle"}
ALLOWED_STATUS = {"PENDING", "HOLD", "PASS", "FAIL"}
FORBIDDEN_RENDERED_KINDS = {"STATIC", "HEADLESS", "COMPILER", "SOURCE_INSPECTION"}
MOBILE_CAPTURE_MODES = {"PHYSICAL_DEVICE", "STUDIO_EMULATION"}
DESKTOP_CAPTURE_MODES = {"ROBLOX_CLIENT", "ROBLOX_STUDIO"}
UNIVERSE_ID = "10768955678"
PLACE_ID = "87245440673982"


class ContractError(ValueError):
    pass


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def _index_unique(items: object, label: str, key: str = "id") -> dict[str, dict]:
    _require(isinstance(items, list), f"{label}: list required")
    result: dict[str, dict] = {}
    for item in items:
        _require(isinstance(item, dict), f"{label}: object required")
        item_id = item.get(key)
        _require(isinstance(item_id, str) and bool(item_id), f"{label}: missing {key}")
        _require(item_id not in result, f"{label}: duplicate {key} {item_id}")
        result[item_id] = item
    return result


def _status(check: dict, label: str) -> str:
    status = check.get("status")
    _require(isinstance(status, str) and status in ALLOWED_STATUS, f"{label}: invalid status")
    return status


def _finite_number(value: object) -> bool:
    return type(value) in (int, float) and math.isfinite(value)


def _evidence_root(root: Path | None, canonical: str | None) -> Path:
    _require(isinstance(canonical, str) and SHA_RE.fullmatch(canonical) is not None,
             "PASS evidence requires --expected-canonical")
    _require(root is not None, "PASS evidence requires --evidence-root")
    resolved = Path(root).resolve()
    _require(resolved.is_dir() and resolved.name == canonical,
             "evidence root must be an existing directory named for the expected canonical SHA")
    return resolved


def _validate_evidence(evidence: object, required_kind: str, label: str,
                       canonical: str | None, root: Path | None,
                       used_images: set[tuple[str, object]]) -> dict | None:
    _require(isinstance(evidence, dict), f"{label}: PASS requires evidence object")
    kind = evidence.get("kind")
    _require(isinstance(kind, str) and kind not in FORBIDDEN_RENDERED_KINDS,
             f"{label}: static/headless/compiler/source evidence cannot prove runtime PASS")
    _require(kind == required_kind, f"{label}: evidence kind must be {required_kind}")
    resolved_root = _evidence_root(root, canonical)
    _require(evidence.get("canonicalSha") == canonical, f"{label}: evidence canonical SHA mismatch")
    relative = evidence.get("path")
    _require(isinstance(relative, str) and bool(relative.strip()), f"{label}: evidence path required")
    parts = PurePosixPath(relative)
    _require(not parts.is_absolute() and ".." not in parts.parts and "\\" not in relative and ":" not in relative,
             f"{label}: evidence path must remain relative to its canonical evidence root")
    path = (resolved_root / relative).resolve()
    _require(path.is_relative_to(resolved_root) and path.is_file(), f"{label}: evidence file missing or outside root")
    payload = path.read_bytes()
    _require(bool(payload), f"{label}: evidence file is empty")
    digest = evidence.get("sha256")
    _require(isinstance(digest, str) and SHA256_RE.fullmatch(digest) is not None,
             f"{label}: evidence sha256 required")
    _require(hashlib.sha256(payload).hexdigest() == digest, f"{label}: evidence sha256 mismatch")
    if required_kind == "RENDERED_DEVICE_CAPTURE":
        _require(path.suffix.lower() in {".png", ".jpg", ".jpeg"}, f"{label}: PNG/JPEG capture required")
        _require(payload.startswith(b"\x89PNG\r\n\x1a\n") or payload.startswith(b"\xff\xd8\xff"),
                 f"{label}: evidence does not have a PNG/JPEG signature")
        keys = {("path", str(path)), ("sha256", digest)}
        _require(not (keys & used_images), f"{label}: image reused for a distinct required capture")
        used_images.update(keys)
        return None
    _require(path.suffix.lower() == ".json", f"{label}: JSON runtime trace required")
    try:
        trace = json.loads(payload)
    except (ValueError, UnicodeError) as exc:
        raise ContractError(f"{label}: invalid JSON trace") from exc
    _require(isinstance(trace, dict) and trace.get("canonicalSha") == canonical,
             f"{label}: trace canonical SHA mismatch")
    _require(trace.get("checkId") == label, f"{label}: trace check identity mismatch")
    return trace


def _observations(check: dict, trace: dict, label: str) -> dict:
    observations = check.get("observations")
    _require(isinstance(observations, dict), f"{label}: observations required")
    _require(trace.get("observations") == observations, f"{label}: receipt observations do not match trace")
    return observations


def validate_contract(data: dict, *, require_pass: bool = False,
                      expected_canonical: str | None = None,
                      evidence_root: Path | None = None) -> None:
    _require(isinstance(data, dict), "receipt must be an object")
    _require(data.get("schemaVersion") == 2, "schemaVersion must be 2")
    _require(data.get("owner") == "Roblox High School Integration Smoke", "owner mismatch")
    _require(SHA_RE.fullmatch(str(data.get("inputCanonicalSha", ""))) is not None, "input canonical SHA invalid")
    producer = data.get("producerCandidate")
    _require(isinstance(producer, dict), "producerCandidate required")
    _require(type(producer.get("pr")) is int and producer["pr"] > 0, "producer PR required")
    _require(SHA_RE.fullmatch(str(producer.get("sha", ""))) is not None, "producer SHA invalid")

    integrated, tested = data.get("integratedCanonicalSha"), data.get("testedCanonicalSha")
    for label, sha in (("integrated", integrated), ("tested", tested)):
        _require(sha is None or (isinstance(sha, str) and SHA_RE.fullmatch(sha) is not None), f"{label} canonical SHA invalid")
    _require(integrated is None or tested is None or integrated == tested, "tested SHA must equal integrated canonical SHA")
    if expected_canonical is not None:
        _require(isinstance(expected_canonical, str) and SHA_RE.fullmatch(expected_canonical) is not None, "expected canonical SHA invalid")
        _require(integrated == tested == expected_canonical, "receipt must match the expected live canonical SHA")
    overall = data.get("overallStatus")
    _require(isinstance(overall, str) and overall in ALLOWED_STATUS, "overallStatus invalid")
    _require(overall != "PASS" or require_pass, "PASS receipts require --require-pass; draft validation cannot certify PASS")
    if require_pass:
        _require(overall == "PASS", "final acceptance requires overallStatus=PASS")
        _evidence_root(evidence_root, expected_canonical)
        _require(integrated == tested == expected_canonical, "PASS requires the expected integrated/tested canonical SHA")
    for flag in ("runtimeExecuted", "renderedParityEstablished", "physicalDeviceEvidenceEstablished",
                 "moneySpent", "robloxPublished", "taskStateChanged"):
        _require(type(data.get(flag)) is bool, f"{flag}: explicit boolean required")
    for flag in ("moneySpent", "robloxPublished", "taskStateChanged"):
        _require(data[flag] is False, f"{flag}: prohibited action prevents smoke acceptance")

    sources = _index_unique(data.get("referenceSources"), "referenceSources", "clip")
    _require({key: row.get("libraryId") for key, row in sources.items()} == REQUIRED_SOURCES, "reference source identities must match A/B/C Library IDs")
    _require(sources["A"].get("checkpoints") == ["00:05", "00:25", "00:45", "02:05"], "A checkpoints incomplete")
    _require(sources["C"].get("checkpoints") == ["00:05"], "C Travel checkpoint incomplete")

    used_images: set[tuple[str, object]] = set()
    startup = data.get("startupCheck")
    _require(isinstance(startup, dict), "startupCheck required")
    startup_status = _status(startup, "startup")
    startup_player = None
    if startup_status == "PASS":
        trace = _validate_evidence(startup.get("evidence"), "RUNTIME_TRACE", "startup", expected_canonical, evidence_root, used_images)
        observed = _observations(startup, trace, "startup")
        _require(observed.get("clientStarted") is True, "startup: client must have started")
        for key, value in (("startupErrorCount", 0), ("canonicalScreenGuiCount", 1), ("canonicalClientMountCount", 1)):
            _require(type(observed.get(key)) is int and observed[key] == value, f"startup: {key} must be {value}")
        startup_player = observed.get("playerId")
        _require(type(startup_player) is int and startup_player > 0, "startup: actual player identity required")
        _require(observed.get("universeId") == UNIVERSE_ID and observed.get("placeId") == PLACE_ID,
                 "startup: universe/place identity mismatch")

    profiles = _index_unique(data.get("deviceProfiles"), "deviceProfiles")
    _require(set(profiles) == REQUIRED_PROFILES, "device profiles must be desktop, iPhone landscape, and iPad landscape")
    camera_statuses = []
    for profile_id, profile in profiles.items():
        viewport, insets = PROFILE_GEOMETRY[profile_id]
        for field, expected in (("viewport", viewport), ("safeInsets", insets)):
            actual = profile.get(field)
            _require(isinstance(actual, dict) and actual == expected and all(type(v) is int for v in actual.values()),
                     f"{profile_id}: {field} must equal the pinned device fixture")
        modes = DESKTOP_CAPTURE_MODES if profile_id == "desktop" else MOBILE_CAPTURE_MODES
        mode = profile.get("captureMode")
        _require(mode is None or (isinstance(mode, str) and mode in modes), f"{profile_id}: invalid captureMode")
        captures = _index_unique(profile.get("captures"), f"{profile_id}.captures")
        _require(set(captures) == REQUIRED_CAPTURES, f"{profile_id}: required camera checkpoints incomplete")
        for capture_id, capture in captures.items():
            label = f"{profile_id}/{capture_id}"
            status = _status(capture, label)
            camera_statuses.append(status)
            if status == "PASS":
                _require(mode in modes, f"{label}: observed captureMode required")
                fov = capture.get("fov")
                _require(_finite_number(fov) and 0 < fov < 180, f"{label}: finite FOV between 0 and 180 required")
                camera = capture.get("camera")
                _require(isinstance(camera, dict), f"{label}: camera transform required")
                position = camera.get("position")
                _require(isinstance(position, list) and len(position) == 3 and all(_finite_number(v) for v in position)
                         and _finite_number(camera.get("yaw")) and _finite_number(camera.get("pitch")), f"{label}: finite camera position/yaw/pitch required")
                _validate_evidence(capture.get("evidence"), "RENDERED_DEVICE_CAPTURE", label, expected_canonical, evidence_root, used_images)

    if data["physicalDeviceEvidenceEstablished"]:
        _require(all(profiles[key].get("captureMode") == "PHYSICAL_DEVICE" for key in REQUIRED_PROFILES - {"desktop"}),
                 "physical-device evidence cannot be established from Studio emulation")
        _require(data["runtimeExecuted"] and all(status == "PASS" for status in camera_statuses),
                 "physical-device claim requires completed runtime captures")

    routes = _index_unique(data.get("routeChecks"), "routeChecks")
    _require(set(routes) == REQUIRED_ROUTE, "route checks incomplete")
    for route_id, check in routes.items():
        label = f"route/{route_id}"
        if _status(check, label) == "PASS":
            kind = "LIVE_DATASTORE_REJOIN" if route_id == "save_rejoin" else "RUNTIME_TRACE"
            trace = _validate_evidence(check.get("evidence"), kind, label, expected_canonical, evidence_root, used_images)
            if route_id == "save_rejoin":
                _require(check.get("observedRejoinMatch") is True, "save_rejoin: observedRejoinMatch must be true")
                observed = _observations(check, trace, "save_rejoin")
                before, after = observed.get("playerIdBefore"), observed.get("playerIdAfter")
                _require(type(before) is int and type(after) is int and before > 0 and before == after == startup_player,
                         "save_rejoin: same player as startup required before and after rejoin")
                committed, restored = observed.get("committedStateSha256"), observed.get("restoredStateSha256")
                _require(isinstance(committed, str) and SHA256_RE.fullmatch(committed) is not None and committed == restored,
                         "save_rejoin: committed/restored durable state digests must match")
                before_count, after_count = observed.get("durableAwardCountBefore"), observed.get("durableAwardCountAfter")
                _require(type(before_count) is int and type(after_count) is int and before_count > 0 and before_count == after_count,
                         "save_rejoin: durable award count must remain unchanged and include a committed award")
                completion = observed.get("completionIdBefore")
                _require(isinstance(completion, str) and bool(completion.strip()) and completion == observed.get("completionIdAfter"),
                         "save_rejoin: stable committed completion identity required")
            else:
                observed = _observations(check, trace, label)
                _require(observed.get("completed") is True, f"{label}: observed runtime route completion required")

    panels = _index_unique(data.get("panelChecks"), "panelChecks")
    _require(set(panels) == REQUIRED_PANELS, "panel checks incomplete")
    panel_capture_statuses = []
    for panel_id, panel in panels.items():
        status = _status(panel, f"panel/{panel_id}")
        captures = _index_unique(panel.get("captures"), f"panel/{panel_id}.captures", "profileId")
        _require(set(captures) == REQUIRED_PROFILES, f"panel/{panel_id}: all three device captures required")
        for profile_id, capture in captures.items():
            label = f"panel/{panel_id}/{profile_id}"
            capture_status = _status(capture, label)
            panel_capture_statuses.append(capture_status)
            if capture_status == "PASS":
                _require(profiles[profile_id].get("captureMode") is not None, f"{label}: observed captureMode required")
                travel_reference = next(row for row in profiles[profile_id]["captures"] if row["id"] == "C_0005")
                # This is the same Travel state on the same device; its image was
                # already validated above. Other state/profile reuse still fails.
                same_travel_capture = panel_id == "travel" and travel_reference["status"] == "PASS" and capture.get("evidence") == travel_reference.get("evidence")
                if not same_travel_capture:
                    _validate_evidence(capture.get("evidence"), "RENDERED_DEVICE_CAPTURE", label, expected_canonical, evidence_root, used_images)
        if status == "PASS":
            _require(all(row["status"] == "PASS" for row in captures.values()), f"panel/{panel_id}: PASS requires all device captures PASS")

    if require_pass:
        _require(data["runtimeExecuted"] and data["renderedParityEstablished"], "PASS requires completed runtime and independently reviewed rendered-parity flags")
        _require(data["physicalDeviceEvidenceEstablished"], "full PASS requires physical iPhone and iPad evidence; emulation remains HOLD")
        _require(startup_status == "PASS", "PASS requires actual startup evidence")
        _require(all(status == "PASS" for status in camera_statuses), "PASS requires every camera capture PASS")
        _require(all(check["status"] == "PASS" for check in routes.values()), "PASS requires every route check PASS")
        _require(all(check["status"] == "PASS" for check in panels.values()) and all(status == "PASS" for status in panel_capture_statuses),
                 "PASS requires every panel on every device PASS")


def self_test(pending: dict) -> None:
    """Exercise draft rejection cases only; never produce a runtime PASS fixture."""
    validate_contract(pending)
    mutations = []
    false_pass = copy.deepcopy(pending)
    false_pass["overallStatus"] = "PASS"
    mutations.append(false_pass)
    missing_travel = copy.deepcopy(pending)
    missing_travel["deviceProfiles"][0]["captures"] = [row for row in missing_travel["deviceProfiles"][0]["captures"] if row["id"] != "C_0005"]
    mutations.append(missing_travel)
    missing_vehicle = copy.deepcopy(pending)
    missing_vehicle["panelChecks"] = [row for row in missing_vehicle["panelChecks"] if row["id"] != "vehicle"]
    mutations.append(missing_vehicle)
    desktop_as_phone = copy.deepcopy(pending)
    phone = next(row for row in desktop_as_phone["deviceProfiles"] if row["id"] == "iphone_landscape")
    phone["viewport"] = {"width": 909, "height": 483}
    mutations.append(desktop_as_phone)
    for mutation in mutations:
        try:
            validate_contract(mutation)
        except ContractError:
            continue
        raise ContractError("self-test accepted a forbidden draft mutation")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("receipt", type=Path)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--self-test", action="store_true")
    modes.add_argument("--require-pass", action="store_true")
    parser.add_argument("--expected-canonical")
    parser.add_argument("--evidence-root", type=Path)
    args = parser.parse_args(argv)
    try:
        data = json.loads(args.receipt.read_text(encoding="utf-8"))
        if args.require_pass:
            root = _evidence_root(args.evidence_root, args.expected_canonical)
            _require(args.receipt.resolve().parent == root, "final receipt must be stored inside its canonical evidence root")
        validate_contract(data, require_pass=args.require_pass, expected_canonical=args.expected_canonical, evidence_root=args.evidence_root)
        if args.self_test:
            self_test(data)
    except (ContractError, OSError, ValueError) as exc:
        print(f"SMOKE_RUNTIME_CAPTURE_CONTRACT_FAIL: {exc}", file=sys.stderr)
        return 1
    print("SMOKE_RUNTIME_CAPTURE_PASS_OK" if args.require_pass else "SMOKE_RUNTIME_CAPTURE_CONTRACT_DRAFT_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
