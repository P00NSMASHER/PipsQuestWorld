#!/usr/bin/env python3
"""Validate exact-canonical rendered/device Smoke capture receipts.

The validator deliberately treats static, compiler, source-inspection, and
headless evidence as insufficient for a rendered/device PASS.
"""

from __future__ import annotations

import argparse
import copy
import json
import re
import sys
from pathlib import Path


SHA_RE = re.compile(r"^[0-9a-f]{40}$")
REQUIRED_SOURCES = {
    "A": "libfile_94cb10b32d9c819186b9ad708b9d4736",
    "B": "libfile_427a25a0e78881919c3128e193b9df4d",
    "C": "libfile_a5903480efe88191a87e5f98ec9729bc",
}
REQUIRED_PROFILES = {"desktop", "iphone_landscape", "ipad_landscape"}
REQUIRED_CAPTURES = {"A_0005", "A_0025", "A_0045", "A_0125"}
REQUIRED_ROUTE = {
    "spawn",
    "entrance",
    "atrium_left",
    "atrium_right",
    "corridor",
    "stair_up",
    "stair_down",
    "class_free_roam",
    "menus",
    "save_rejoin",
}
REQUIRED_PANELS = {"shop", "travel", "avatar", "house", "housing_editor"}
ALLOWED_STATUS = {"PENDING", "HOLD", "PASS", "FAIL"}
FORBIDDEN_RENDERED_KINDS = {"STATIC", "HEADLESS", "COMPILER", "SOURCE_INSPECTION"}


class ContractError(ValueError):
    pass


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def _index_unique(items: list[dict], label: str) -> dict[str, dict]:
    result: dict[str, dict] = {}
    for item in items:
        item_id = item.get("id")
        _require(isinstance(item_id, str) and item_id, f"{label}: missing id")
        _require(item_id not in result, f"{label}: duplicate id {item_id}")
        result[item_id] = item
    return result


def _validate_evidence(evidence: object, required_kind: str, label: str) -> None:
    _require(isinstance(evidence, dict), f"{label}: PASS requires evidence object")
    kind = evidence.get("kind")
    _require(kind not in FORBIDDEN_RENDERED_KINDS, f"{label}: {kind} cannot prove rendered/runtime PASS")
    _require(kind == required_kind, f"{label}: evidence kind must be {required_kind}")
    _require(isinstance(evidence.get("path"), str) and evidence["path"], f"{label}: evidence path required")


def validate_contract(data: dict) -> None:
    _require(data.get("schemaVersion") == 1, "schemaVersion must be 1")
    _require(data.get("owner") == "Roblox High School Integration Smoke", "owner mismatch")
    _require(SHA_RE.fullmatch(str(data.get("inputCanonicalSha", ""))) is not None, "input canonical SHA invalid")

    producer = data.get("producerCandidate")
    _require(isinstance(producer, dict), "producerCandidate required")
    _require(isinstance(producer.get("pr"), int), "producer PR required")
    _require(SHA_RE.fullmatch(str(producer.get("sha", ""))) is not None, "producer SHA invalid")

    integrated = data.get("integratedCanonicalSha")
    tested = data.get("testedCanonicalSha")
    if integrated is not None:
        _require(SHA_RE.fullmatch(str(integrated)) is not None, "integrated canonical SHA invalid")
    if tested is not None:
        _require(SHA_RE.fullmatch(str(tested)) is not None, "tested canonical SHA invalid")
    if integrated is not None and tested is not None:
        _require(integrated == tested, "tested SHA must equal integrated canonical SHA")

    sources = {item.get("clip"): item.get("libraryId") for item in data.get("referenceSources", [])}
    _require(sources == REQUIRED_SOURCES, "reference source identities must match A/B/C Library IDs")
    source_a = next(item for item in data["referenceSources"] if item.get("clip") == "A")
    _require(set(source_a.get("checkpoints", [])) == {"00:05", "00:25", "00:45", "02:05"}, "A checkpoints incomplete")

    profiles = _index_unique(data.get("deviceProfiles", []), "deviceProfiles")
    _require(set(profiles) == REQUIRED_PROFILES, "device profiles must be desktop, iPhone landscape, and iPad landscape")
    for profile_id, profile in profiles.items():
        viewport = profile.get("viewport")
        insets = profile.get("safeInsets")
        _require(isinstance(viewport, dict) and viewport.get("width", 0) > 0 and viewport.get("height", 0) > 0, f"{profile_id}: viewport invalid")
        _require(isinstance(insets, dict) and all(isinstance(insets.get(k), int) and insets[k] >= 0 for k in ("left", "top", "right", "bottom")), f"{profile_id}: safe insets invalid")
        captures = _index_unique(profile.get("captures", []), f"{profile_id}.captures")
        _require(set(captures) == REQUIRED_CAPTURES, f"{profile_id}: required camera checkpoints incomplete")
        for capture_id, capture in captures.items():
            _require(capture.get("status") in ALLOWED_STATUS, f"{profile_id}/{capture_id}: invalid status")
            if capture.get("status") == "PASS":
                _require(isinstance(capture.get("fov"), (int, float)), f"{profile_id}/{capture_id}: FOV required")
                camera = capture.get("camera")
                _require(isinstance(camera, dict), f"{profile_id}/{capture_id}: camera transform required")
                _require(all(k in camera for k in ("position", "yaw", "pitch")), f"{profile_id}/{capture_id}: camera position/yaw/pitch required")
                _validate_evidence(capture.get("evidence"), "RENDERED_DEVICE_CAPTURE", f"{profile_id}/{capture_id}")

    route = _index_unique(data.get("routeChecks", []), "routeChecks")
    _require(set(route) == REQUIRED_ROUTE, "route checks incomplete")
    for route_id, check in route.items():
        _require(check.get("status") in ALLOWED_STATUS, f"route/{route_id}: invalid status")
        if check.get("status") == "PASS":
            kind = "LIVE_DATASTORE_REJOIN" if route_id == "save_rejoin" else "RUNTIME_TRACE"
            _validate_evidence(check.get("evidence"), kind, f"route/{route_id}")
            if route_id == "save_rejoin":
                _require(check.get("observedRejoinMatch") is True, "save_rejoin: observedRejoinMatch must be true")

    panels = _index_unique(data.get("panelChecks", []), "panelChecks")
    _require(set(panels) == REQUIRED_PANELS, "panel checks incomplete")
    for panel_id, check in panels.items():
        _require(check.get("status") in ALLOWED_STATUS, f"panel/{panel_id}: invalid status")
        if check.get("status") == "PASS":
            _validate_evidence(check.get("evidence"), "RENDERED_DEVICE_CAPTURE", f"panel/{panel_id}")

    overall = data.get("overallStatus")
    _require(overall in ALLOWED_STATUS, "overallStatus invalid")
    if overall == "PASS":
        _require(integrated is not None and tested == integrated, "PASS requires exact integrated/tested canonical identity")
        _require(data.get("runtimeExecuted") is True, "PASS requires runtimeExecuted=true")
        _require(data.get("renderedParityEstablished") is True, "PASS requires renderedParityEstablished=true")
        _require(all(c["status"] == "PASS" for p in profiles.values() for c in p["captures"]), "PASS requires every camera capture PASS")
        _require(all(check["status"] == "PASS" for check in route.values()), "PASS requires every route check PASS")
        _require(all(check["status"] == "PASS" for check in panels.values()), "PASS requires every panel check PASS")


def _synthetic_pass(pending: dict) -> dict:
    data = copy.deepcopy(pending)
    integrated = "1" * 40
    data["integratedCanonicalSha"] = integrated
    data["testedCanonicalSha"] = integrated
    data["runtimeExecuted"] = True
    data["renderedParityEstablished"] = True
    data["overallStatus"] = "PASS"
    for profile in data["deviceProfiles"]:
        for capture in profile["captures"]:
            capture.update({
                "status": "PASS",
                "fov": 70,
                "camera": {"position": [0, 5, 0], "yaw": 0, "pitch": 0},
                "evidence": {"kind": "RENDERED_DEVICE_CAPTURE", "path": f"evidence/{profile['id']}/{capture['id']}.png"},
            })
    for check in data["routeChecks"]:
        kind = "LIVE_DATASTORE_REJOIN" if check["id"] == "save_rejoin" else "RUNTIME_TRACE"
        check.update({"status": "PASS", "evidence": {"kind": kind, "path": f"evidence/routes/{check['id']}.json"}})
        if check["id"] == "save_rejoin":
            check["observedRejoinMatch"] = True
    for check in data["panelChecks"]:
        check.update({"status": "PASS", "evidence": {"kind": "RENDERED_DEVICE_CAPTURE", "path": f"evidence/panels/{check['id']}.png"}})
    return data


def self_test(pending: dict) -> None:
    validate_contract(pending)
    valid_pass = _synthetic_pass(pending)
    validate_contract(valid_pass)

    mutations = []
    false_pass = copy.deepcopy(pending)
    false_pass["overallStatus"] = "PASS"
    mutations.append(("false rendered PASS", false_pass))

    missing_iphone = copy.deepcopy(pending)
    iphone = next(p for p in missing_iphone["deviceProfiles"] if p["id"] == "iphone_landscape")
    iphone["captures"] = [c for c in iphone["captures"] if c["id"] != "A_0025"]
    mutations.append(("missing iPhone checkpoint", missing_iphone))

    sha_mismatch = _synthetic_pass(pending)
    sha_mismatch["testedCanonicalSha"] = "2" * 40
    mutations.append(("canonical SHA mismatch", sha_mismatch))

    missing_rejoin = _synthetic_pass(pending)
    rejoin = next(c for c in missing_rejoin["routeChecks"] if c["id"] == "save_rejoin")
    rejoin["evidence"] = None
    mutations.append(("missing live save/rejoin evidence", missing_rejoin))

    static_as_rendered = _synthetic_pass(pending)
    static_as_rendered["deviceProfiles"][0]["captures"][0]["evidence"]["kind"] = "HEADLESS"
    mutations.append(("headless evidence promoted to rendered", static_as_rendered))

    for label, mutation in mutations:
        try:
            validate_contract(mutation)
        except ContractError:
            continue
        raise AssertionError(f"validator accepted forbidden mutation: {label}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("receipt", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    data = json.loads(args.receipt.read_text(encoding="utf-8"))
    try:
        validate_contract(data)
        if args.self_test:
            self_test(data)
    except (ContractError, AssertionError) as exc:
        print(f"SMOKE_RUNTIME_CAPTURE_CONTRACT_FAIL: {exc}", file=sys.stderr)
        return 1
    print("SMOKE_RUNTIME_CAPTURE_CONTRACT_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
