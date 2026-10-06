#!/usr/bin/env python3
"""Adversarial tests using temporary synthetic files, never runtime evidence."""

from __future__ import annotations

import copy
import hashlib
import json
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

import validate_runtime_capture_contract as validator


HERE = Path(__file__).resolve().parent
TEMPLATE = HERE / "PR214_RUNTIME_CAPTURE_CONTRACT_V1.json"
CANONICAL = json.loads((HERE.parent / "state" / "WIP.json").read_text(encoding="utf-8"))["canonical"]["sha"]
FINAL_TOKEN = "SMOKE_RUNTIME_CAPTURE_PASS_OK"
DRAFT_TOKEN = "SMOKE_RUNTIME_CAPTURE_CONTRACT_DRAFT_OK"


def synthetic_png(label: str) -> bytes:
    """A valid tiny PNG labeled as a test fixture, not a rendered capture."""
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)
    color = hashlib.sha256(label.encode()).digest()[:3]
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
            + chunk(b"tEXt", b"Purpose\x00SYNTHETIC_UNIT_TEST_ONLY:" + label.encode())
            + chunk(b"IDAT", zlib.compress(b"\x00" + color))
            + chunk(b"IEND", b""))


class RuntimeCaptureContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.pending = json.loads(TEMPLATE.read_text(encoding="utf-8"))
        self.temp = tempfile.TemporaryDirectory(prefix="smoke-contract-synthetic-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / CANONICAL
        self.root.mkdir()
        self.fixture = copy.deepcopy(self.pending)
        self.fixture.update(overallStatus="PASS", runtimeExecuted=True,
                            renderedParityEstablished=True, physicalDeviceEvidenceEstablished=True)
        startup = self.fixture["startupCheck"]
        startup["status"] = "PASS"
        startup["observations"] = {
            "clientStarted": True, "startupErrorCount": 0,
            "canonicalScreenGuiCount": 1, "canonicalClientMountCount": 1,
            "playerId": 1234, "universeId": validator.UNIVERSE_ID, "placeId": validator.PLACE_ID,
        }
        self.write_trace(startup, "startup")
        for profile in self.fixture["deviceProfiles"]:
            profile["captureMode"] = "ROBLOX_CLIENT" if profile["id"] == "desktop" else "PHYSICAL_DEVICE"
            for capture in profile["captures"]:
                capture.update(status="PASS", fov=70,
                               camera={"position": [0, 5, 0], "yaw": 0, "pitch": 0})
                capture["evidence"] = self.write_evidence(
                    f"cameras/{profile['id']}/{capture['id']}.png",
                    "RENDERED_DEVICE_CAPTURE",
                    synthetic_png(f"{profile['id']}/{capture['id']}"))
        for route in self.fixture["routeChecks"]:
            route["status"] = "PASS"
            if route["id"] == "save_rejoin":
                route["observedRejoinMatch"] = True
                route["observations"] = {
                    "playerIdBefore": 1234, "playerIdAfter": 1234,
                    "committedStateSha256": "a" * 64, "restoredStateSha256": "a" * 64,
                    "durableAwardCountBefore": 1, "durableAwardCountAfter": 1,
                    "completionIdBefore": "synthetic-completion-1",
                    "completionIdAfter": "synthetic-completion-1",
                }
            else:
                route["observations"] = {"completed": True}
            self.write_trace(route, f"route/{route['id']}")
        for panel in self.fixture["panelChecks"]:
            panel["status"] = "PASS"
            for capture in panel["captures"]:
                capture["status"] = "PASS"
                path = f"panels/{panel['id']}/{capture['profileId']}.png"
                capture["evidence"] = self.write_evidence(
                    path, "RENDERED_DEVICE_CAPTURE", synthetic_png(path))

    def write_evidence(self, relative: str, kind: str, payload: bytes) -> dict:
        target = self.root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(payload)
        return {"kind": kind, "path": relative, "canonicalSha": CANONICAL,
                "sha256": hashlib.sha256(payload).hexdigest()}

    def write_trace(self, check: dict, check_id: str, **overrides: object) -> None:
        trace = {"canonicalSha": CANONICAL, "checkId": check_id,
                 "observations": check["observations"],
                 "fixturePurpose": "SYNTHETIC_UNIT_TEST_ONLY"}
        trace.update(overrides)
        relative = f"traces/{check_id.replace('/', '-')}.json"
        kind = "LIVE_DATASTORE_REJOIN" if check_id == "route/save_rejoin" else "RUNTIME_TRACE"
        check["evidence"] = self.write_evidence(relative, kind, json.dumps(trace).encode())

    def validate(self, data: dict | None = None, **kwargs: object) -> None:
        options = {"require_pass": True, "expected_canonical": CANONICAL, "evidence_root": self.root}
        options.update(kwargs)
        validator.validate_contract(self.fixture if data is None else data, **options)

    def reject(self, data: dict, reason: str) -> None:
        with self.assertRaisesRegex(validator.ContractError, reason):
            self.validate(data)

    def cli(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run([sys.executable, "-B", str(HERE / "validate_runtime_capture_contract.py"), *args],
                              text=True, capture_output=True, check=False)

    def receipt_path(self, data: dict | None = None) -> Path:
        path = self.root / "capture-receipt.json"
        path.write_text(json.dumps(self.fixture if data is None else data), encoding="utf-8")
        return path

    def strict_args(self, receipt: Path) -> list[str]:
        return [str(receipt), "--require-pass", "--expected-canonical", CANONICAL,
                "--evidence-root", str(self.root)]

    def test_real_template_stays_pending_and_draft_only(self) -> None:
        validator.validate_contract(self.pending)
        self.assertEqual(self.pending["overallStatus"], "HOLD")
        self.assertFalse(self.pending["runtimeExecuted"])
        self.assertFalse(self.pending["renderedParityEstablished"])
        self.assertFalse(self.pending["physicalDeviceEvidenceEstablished"])
        self.assertEqual(self.pending["startupCheck"]["status"], "PENDING")
        for group in ("routeChecks", "panelChecks"):
            self.assertTrue(all(row["status"] == "PENDING" for row in self.pending[group]))
        for profile in self.pending["deviceProfiles"]:
            self.assertIsNone(profile["captureMode"])
            self.assertTrue(all(row["status"] == "PENDING" for row in profile["captures"]))
        self.reject(self.pending, "overallStatus=PASS")

    def test_complete_synthetic_integrity_fixture_passes_only_strict_mode(self) -> None:
        self.validate()
        with self.assertRaisesRegex(validator.ContractError, "require-pass"):
            validator.validate_contract(self.fixture)
        for flag in ("runtimeExecuted", "renderedParityEstablished", "physicalDeviceEvidenceEstablished"):
            data = copy.deepcopy(self.fixture)
            data[flag] = False
            with self.subTest(flag=flag):
                with self.assertRaises(validator.ContractError):
                    self.validate(data)

    def test_cli_tokens_are_separated_and_self_test_cannot_accept(self) -> None:
        for args in ([str(TEMPLATE)], [str(TEMPLATE), "--self-test"]):
            result = self.cli(*args)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.strip(), DRAFT_TOKEN)
            self.assertNotIn(FINAL_TOKEN, result.stdout)
        receipt = self.receipt_path()
        accepted = self.cli(*self.strict_args(receipt))
        self.assertEqual(accepted.returncode, 0, accepted.stderr)
        self.assertEqual(accepted.stdout.strip(), FINAL_TOKEN)
        for args in ([str(receipt)], [str(receipt), "--self-test"],
                     [*self.strict_args(receipt), "--self-test"]):
            result = self.cli(*args)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn(FINAL_TOKEN, result.stdout)

    def test_cli_requires_external_identity_root_and_final_receipt_location(self) -> None:
        receipt = self.receipt_path()
        cases = [
            [str(receipt), "--require-pass"],
            [str(receipt), "--require-pass", "--expected-canonical", CANONICAL],
            [str(receipt), "--require-pass", "--evidence-root", str(self.root)],
            self.strict_args(TEMPLATE),
        ]
        for args in cases:
            with self.subTest(args=args):
                result = self.cli(*args)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn(FINAL_TOKEN, result.stdout)

    def test_both_receipt_shas_changed_together_still_fail(self) -> None:
        data = copy.deepcopy(self.fixture)
        data["integratedCanonicalSha"] = data["testedCanonicalSha"] = "2" * 40
        self.reject(data, "expected live canonical")

    def test_evidence_sha_must_match_expected_canonical(self) -> None:
        data = copy.deepcopy(self.fixture)
        data["deviceProfiles"][0]["captures"][0]["evidence"]["canonicalSha"] = "2" * 40
        self.reject(data, "evidence canonical SHA mismatch")

    def test_required_travel_camera_vehicle_and_panel_profiles(self) -> None:
        for profile_id in validator.REQUIRED_PROFILES:
            data = copy.deepcopy(self.fixture)
            profile = next(row for row in data["deviceProfiles"] if row["id"] == profile_id)
            profile["captures"] = [row for row in profile["captures"] if row["id"] != "C_0005"]
            with self.subTest(missing_travel_profile=profile_id):
                self.reject(data, "camera checkpoints incomplete")
        data = copy.deepcopy(self.fixture)
        data["panelChecks"] = [row for row in data["panelChecks"] if row["id"] != "vehicle"]
        self.reject(data, "panel checks incomplete")
        for profile_id in validator.REQUIRED_PROFILES:
            data = copy.deepcopy(self.fixture)
            vehicle = next(row for row in data["panelChecks"] if row["id"] == "vehicle")
            vehicle["captures"] = [row for row in vehicle["captures"] if row["profileId"] != profile_id]
            with self.subTest(missing_vehicle_profile=profile_id):
                self.reject(data, "all three device captures required")

    def test_exact_geometry_and_safe_insets_are_required(self) -> None:
        for profile_id in validator.REQUIRED_PROFILES:
            for field, key in (("viewport", "width"), ("safeInsets", "top")):
                data = copy.deepcopy(self.fixture)
                profile = next(row for row in data["deviceProfiles"] if row["id"] == profile_id)
                profile[field][key] += 1
                with self.subTest(profile=profile_id, field=field):
                    self.reject(data, "pinned device fixture")

    def test_mobile_emulation_cannot_be_full_device_pass(self) -> None:
        data = copy.deepcopy(self.fixture)
        for profile in data["deviceProfiles"]:
            if profile["id"] != "desktop":
                profile["captureMode"] = "STUDIO_EMULATION"
        self.reject(data, "cannot be established from Studio emulation")
        data["physicalDeviceEvidenceEstablished"] = False
        self.reject(data, "full PASS requires physical")
        data["overallStatus"] = "HOLD"
        validator.validate_contract(data, expected_canonical=CANONICAL, evidence_root=self.root)

    def test_missing_or_wrong_capture_mode_is_rejected(self) -> None:
        for mode in (None, "HEADLESS", "ROBLOX_STUDIO"):
            data = copy.deepcopy(self.fixture)
            next(row for row in data["deviceProfiles"] if row["id"] == "iphone_landscape")["captureMode"] = mode
            with self.subTest(mode=mode):
                with self.assertRaises(validator.ContractError):
                    self.validate(data)

    def test_missing_empty_or_changed_evidence_file_is_rejected(self) -> None:
        evidence = self.fixture["deviceProfiles"][0]["captures"][0]["evidence"]
        path = self.root / evidence["path"]
        original = path.read_bytes()
        for payload, reason in ((None, "file missing"), (b"", "file is empty"), (b"changed", "sha256 mismatch")):
            if payload is None:
                path.unlink()
            else:
                path.write_bytes(payload)
            with self.subTest(reason=reason):
                self.reject(self.fixture, reason)
            path.write_bytes(original)

    def test_path_escape_absolute_path_and_symlink_escape_are_rejected(self) -> None:
        original = self.fixture["deviceProfiles"][0]["captures"][0]["evidence"]
        outside = Path(self.temp.name) / "outside.png"
        outside.write_bytes((self.root / original["path"]).read_bytes())
        symlink = self.root / "escape.png"
        symlink.symlink_to(outside)
        for path in ("../outside.png", str(outside), "escape.png"):
            data = copy.deepcopy(self.fixture)
            data["deviceProfiles"][0]["captures"][0]["evidence"]["path"] = path
            with self.subTest(path=path):
                with self.assertRaises(validator.ContractError):
                    self.validate(data)

    def test_distinct_capture_path_and_image_content_are_required(self) -> None:
        data = copy.deepcopy(self.fixture)
        first, second = data["deviceProfiles"][0]["captures"][:2]
        second["evidence"] = copy.deepcopy(first["evidence"])
        self.reject(data, "image reused")
        second["evidence"] = self.write_evidence(
            "copied-image.png", "RENDERED_DEVICE_CAPTURE",
            (self.root / first["evidence"]["path"]).read_bytes())
        self.reject(data, "image reused")

    def test_exact_same_profile_travel_alias_is_allowed(self) -> None:
        data = copy.deepcopy(self.fixture)
        travel = next(row for row in data["panelChecks"] if row["id"] == "travel")
        for capture in travel["captures"]:
            profile = next(row for row in data["deviceProfiles"] if row["id"] == capture["profileId"])
            reference = next(row for row in profile["captures"] if row["id"] == "C_0005")
            capture["evidence"] = copy.deepcopy(reference["evidence"])
        self.validate(data)

    def test_cross_profile_and_other_panel_aliases_are_rejected(self) -> None:
        for panel_id in ("travel", "shop"):
            data = copy.deepcopy(self.fixture)
            desktop = next(row for row in data["deviceProfiles"] if row["id"] == "desktop")
            reference = next(row for row in desktop["captures"] if row["id"] == "C_0005")
            panel = next(row for row in data["panelChecks"] if row["id"] == panel_id)
            phone = next(row for row in panel["captures"] if row["profileId"] == "iphone_landscape")
            phone["evidence"] = copy.deepcopy(reference["evidence"])
            with self.subTest(panel=panel_id):
                self.reject(data, "image reused")

    def test_headless_kind_and_nonimage_payload_are_rejected(self) -> None:
        data = copy.deepcopy(self.fixture)
        capture = data["deviceProfiles"][0]["captures"][0]
        capture["evidence"]["kind"] = "HEADLESS"
        self.reject(data, "cannot prove runtime PASS")
        capture["evidence"] = self.write_evidence("not-an-image.png", "RENDERED_DEVICE_CAPTURE", b"not an image")
        self.reject(data, "PNG/JPEG signature")

    def test_invalid_camera_observations_are_rejected(self) -> None:
        for field, value in (("fov", float("nan")), ("fov", True), ("fov", 180),
                             ("camera", {"position": [0, None, 0], "yaw": 0, "pitch": 0})):
            data = copy.deepcopy(self.fixture)
            data["deviceProfiles"][0]["captures"][0][field] = value
            with self.subTest(field=field, value=value):
                self.reject(data, "finite")

    def test_startup_failures_and_wrong_identity_are_rejected(self) -> None:
        for key, value in (("clientStarted", False), ("startupErrorCount", 1),
                           ("canonicalScreenGuiCount", 0), ("canonicalClientMountCount", 2),
                           ("placeId", "0"), ("playerId", 0)):
            data = copy.deepcopy(self.fixture)
            startup = data["startupCheck"]
            startup["observations"][key] = value
            self.write_trace(startup, "startup")
            with self.subTest(key=key):
                with self.assertRaises(validator.ContractError):
                    self.validate(data)
            self.write_trace(self.fixture["startupCheck"], "startup")

    def test_startup_and_route_traces_are_bound_to_specific_check(self) -> None:
        data = copy.deepcopy(self.fixture)
        route = next(row for row in data["routeChecks"] if row["id"] == "stair_up")
        route["evidence"] = copy.deepcopy(data["startupCheck"]["evidence"])
        self.reject(data, "trace check identity mismatch")
        self.write_trace(route, "route/stair_up", canonicalSha="2" * 40)
        self.reject(data, "trace canonical SHA mismatch")
        self.write_trace(next(row for row in self.fixture["routeChecks"] if row["id"] == "stair_up"), "route/stair_up")

    def test_route_completion_requires_matching_observations(self) -> None:
        data = copy.deepcopy(self.fixture)
        route = next(row for row in data["routeChecks"] if row["id"] == "stair_up")
        route["observations"] = {"completed": False}
        self.write_trace(route, "route/stair_up")
        self.reject(data, "observed runtime route completion required")
        self.write_trace(next(row for row in self.fixture["routeChecks"] if row["id"] == "stair_up"), "route/stair_up")
        route["evidence"] = copy.deepcopy(next(row for row in self.fixture["routeChecks"] if row["id"] == "stair_up")["evidence"])
        route["observations"] = {"completed": False}
        self.reject(data, "observations do not match trace")
        route["evidence"] = self.write_evidence(
            "bare-trace.json", "RUNTIME_TRACE", json.dumps({"canonicalSha": CANONICAL}).encode())
        self.reject(data, "trace check identity mismatch")

    def test_rejoin_player_state_award_and_completion_must_match(self) -> None:
        changes = (("playerIdAfter", 9999), ("restoredStateSha256", "b" * 64),
                   ("durableAwardCountAfter", 2), ("durableAwardCountBefore", 0),
                   ("completionIdAfter", "different"), ("completionIdBefore", ""))
        for key, value in changes:
            data = copy.deepcopy(self.fixture)
            rejoin = next(row for row in data["routeChecks"] if row["id"] == "save_rejoin")
            rejoin["observations"][key] = value
            self.write_trace(rejoin, "route/save_rejoin")
            with self.subTest(key=key):
                with self.assertRaises(validator.ContractError):
                    self.validate(data)
            self.write_trace(next(row for row in self.fixture["routeChecks"] if row["id"] == "save_rejoin"), "route/save_rejoin")

    def test_missing_or_unmatched_rejoin_trace_is_rejected(self) -> None:
        data = copy.deepcopy(self.fixture)
        rejoin = next(row for row in data["routeChecks"] if row["id"] == "save_rejoin")
        rejoin["observations"]["playerIdAfter"] = 4321
        self.reject(data, "observations do not match trace")
        rejoin["evidence"] = None
        self.reject(data, "PASS requires evidence object")

    def test_prohibited_action_flags_are_explicit_and_false(self) -> None:
        for flag in ("moneySpent", "robloxPublished", "taskStateChanged"):
            for value in (True, None):
                data = copy.deepcopy(self.fixture)
                data[flag] = value
                with self.subTest(flag=flag, value=value):
                    self.reject(data, flag)

    def test_pending_or_failed_required_check_cannot_pass(self) -> None:
        mutations = []
        data = copy.deepcopy(self.fixture)
        data["startupCheck"]["status"] = "PENDING"
        mutations.append(data)
        data = copy.deepcopy(self.fixture)
        data["routeChecks"][0]["status"] = "FAIL"
        mutations.append(data)
        data = copy.deepcopy(self.fixture)
        data["panelChecks"][0]["captures"][0]["status"] = "HOLD"
        mutations.append(data)
        for data in mutations:
            with self.assertRaises(validator.ContractError):
                self.validate(data)


if __name__ == "__main__":
    unittest.main()
