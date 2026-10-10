#!/usr/bin/env python3
"""Run an ephemeral native Roblox engine smoke test WITHOUT publishing.

The script reads ONLY committed, creator-verified asset IDs. It creates a
headless Luau Execution task against the existing private place version,
and deliberately never uses SavePlaceAsync or changes any published place.
Secret values and raw API error response bodies are never printed.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
UNIVERSE = "10769455759"
PLACE = "114603280760042"
BASE = f"https://apis.roblox.com/cloud/v2/universes/{UNIVERSE}/places/{PLACE}"
RECEIPT = HERE / "imported_models.json"
SCRIPT = HERE / "native_engine_smoke.luau"


def request_json(url: str, key: str, payload: dict | None = None):
    headers = {"x-api-key": key, "Accept": "application/json"}
    method = "GET"
    data = None
    if payload is not None:
        data = json.dumps(payload, separators=(",", ":")).encode()
        headers["Content-Type"] = "application/json"
        method = "POST"
    r = urllib.request.Request(url, headers=headers, data=data, method=method)
    try:
        with urllib.request.urlopen(r, timeout=30) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as exc:
        # No response body or key in diagnostics.
        return exc.code, {}
    except urllib.error.URLError:
        return 0, {}


def render_script():
    manifest = json.loads(RECEIPT.read_text())
    assert manifest["productionEnabled"] is False
    assert str(manifest["universeId"]) == UNIVERSE
    assert str(manifest["rootPlaceId"]) == PLACE
    assert manifest["creator"]["userId"] == "6064228083"
    items = {x["name"]: x for x in manifest["assets"]}
    assert set(items) == {"abvm_student_chair", "abvm_student_desk"}
    assert all(x["operationModeration"] == "Approved" for x in items.values())
    chair = str(int(items["abvm_student_chair"]["assetId"]))
    desk = str(int(items["abvm_student_desk"]["assetId"]))
    assert chair != desk
    script = SCRIPT.read_text()
    assert script.count("__CHAIR_ASSET_ID__") == 1
    assert script.count("__DESK_ASSET_ID__") == 1
    # Fail closed if this test gains anything that writes to the Roblox place
    # or pulls gameplay code. It can only instantiate transient local models.
    forbidden = ("SavePlaceAsync", "DataStoreService", "SetAsync", "UpdateAsync",
                 "InsertService:Insert", "HttpService", "PlayerAdded")
    assert not any(term in script for term in forbidden)
    # Insert the exact production adapter source into an ephemeral engine-only
    # function. In this task ONLY, a local configuration table enables it;
    # the committed Roblox game's FurnitureMeshConfig.Enabled stays false.
    module = (HERE.parent / "showroom" / "FurnitureMeshAdapter.lua").read_text()
    config_line = 'local Config = require(script.Parent:WaitForChild("FurnitureMeshConfig"))'
    assert module.count(config_line) == 1, "Unexpected production adapter configuration wiring"
    temporary = ("local Config = { Enabled = true, ChairModelAssetId = " +
                 chair + ", DeskModelAssetId = " + desk +
                 ", MaxMeshPartsPerModel = 8 }")
    module = module.replace(config_line, temporary)
    assert script.count("__ACTUAL_ADAPTER_SOURCE__") == 1
    assert not any(term in module for term in forbidden)
    script = script.replace("__CHAIR_ASSET_ID__", chair).replace("__DESK_ASSET_ID__", desk)
    script = script.replace("__ACTUAL_ADAPTER_SOURCE__", module)
    return script, chair, desk


def credentials():
    candidates = (
        ("ROBLOX_QA_API_KEY", os.getenv("ROBLOX_QA_API_KEY", "")),
        ("ROBLOX_API_KEY", os.getenv("ROBLOX_PLACE_API_KEY", "")),
        ("ROBLOX_ASSET_API_KEY", os.getenv("ROBLOX_ASSET_API_KEY", "")),
    )
    return [(name, value.strip()) for name, value in candidates if len(value.strip()) > 20]


def run():
    script, chair, desk = render_script()
    print("NATIVE_ENGINE_SCRIPT_SHA256", hashlib.sha256(script.encode()).hexdigest(), flush=True)
    print("VERIFIED_APPROVED_MODEL_IDS", chair, desk, flush=True)
    candidates = credentials()
    if not candidates:
        raise RuntimeError("NO_CREDENTIAL_FOR_LUAU_EXECUTION available through GitHub Actions")
    task = None
    chosen = None
    for label, key in candidates:
        status, result = request_json(BASE + "/luau-execution-session-tasks", key,
                                      {"script": script})
        if status in (401, 403):
            print("NATIVE_ENGINE_SCOPE_DENIED", label, "HTTP", status, flush=True)
            continue
        if status not in (200, 201):
            raise RuntimeError("Engine task creation HTTP " + str(status) +
                               " (credential " + label + ")")
        path = result.get("path", "")
        if not isinstance(path, str) or not re.fullmatch(
                r"universes/[0-9]+/places/[0-9]+/versions/[0-9]+/"
                r"luau-execution-sessions/[A-Za-z0-9_\-]+/tasks/[A-Za-z0-9_\-]+", path):
            # Result path varies with API versions. A safe prefix and absence
            # of path traversal are the critical constraints.
            if not path.startswith("universes/" + UNIVERSE + "/places/" + PLACE + "/") \
                    or ".." in path or not re.fullmatch(r"[a-zA-Z0-9_/\-]+", path):
                raise RuntimeError("Unexpected Roblox engine task path")
        task = path
        chosen = (label, key)
        print("NATIVE_ENGINE_TASK_CREATED", label, flush=True)
        break
    if task is None or chosen is None:
        raise RuntimeError("LUAU_EXECUTION_SCOPE_MISSING: no existing key authorized")
    label, key = chosen
    url = "https://apis.roblox.com/cloud/v2/" + task
    finished = None
    for _ in range(54):
        time.sleep(3)
        code, current = request_json(url, key)
        if code != 200:
            raise RuntimeError("Engine task status HTTP " + str(code))
        state = str(current.get("state", ""))
        if state in ("COMPLETE", "FAILED", "CANCELLED"):
            finished = current
            break
    if finished is None:
        raise RuntimeError("Native Roblox task still processing; task path not persisted")
    state = str(finished.get("state", ""))
    lstatus, logs = request_json(url + "/logs", key)
    messages = []
    if lstatus == 200:
        for group in logs.get("luauExecutionSessionTaskLogs", []):
            messages.extend(str(x) for x in group.get("messages", []))
    allowed_lines = [s for s in messages if
                     s.startswith("NATIVE_ASSET_MODEL_VERIFIED")
                     or s.startswith("NATIVE_ASSET_STAGING_VERIFIED")
                     or s.startswith("NATIVE_ASSET_ENGINE_NO_SAVE")
                     or s.startswith("NATIVE_ACTUAL_ADAPTER_ACCEPTED")]
    for line in allowed_lines:
        print(line, flush=True)
    if state != "COMPLETE":
        # Trace only the disposable task's own error. It contains no credentials,
        # model contents, user records or external game data.
        err = finished.get("error") or {}
        code = str(err.get("code", "UNKNOWN"))
        detail = re.sub(r"[A-Za-z0-9+/=_-]{40,}", "[REDACTED]",
                        str(err.get("message", "")))[:500]
        print("NATIVE_ENGINE_TASK_FAILURE", code, detail, flush=True)
        for message in messages[-12:]:
            if ("stacktrace" in message.lower() or "attempt to" in message.lower()
                    or "expected" in message.lower() or "error" in message.lower()):
                print("NATIVE_ENGINE_DEBUG", message[:450], flush=True)
        raise RuntimeError("Native Roblox Luau engine task state: " + state)
    expected = ("NATIVE_ASSET_MODEL_VERIFIED student_chair",
                "NATIVE_ASSET_MODEL_VERIFIED student_desk",
                "NATIVE_ASSET_STAGING_VERIFIED pairs=16",
                "NATIVE_ASSET_ENGINE_NO_SAVE_NO_WORKSPACE_MUTATION",
                "NATIVE_ACTUAL_ADAPTER_ACCEPTED models=32",
                "NATIVE_ASSET_ENGINE_NO_SAVE_NO_WORKSPACE_MUTATION_CONFIRMED")
    combined = "\n".join(allowed_lines)
    if not all(x in combined for x in expected):
        raise RuntimeError("Native task completed without all model, staging, and nonmutation evidence")
    receipt = {
        "universe_id": UNIVERSE, "place_id": PLACE,
        "original_models": {"chair": chair, "desk": desk},
        "engine_task_state": state,
        "cloud_luau_execution_key_source": label,
        "mode": "ephemeral nonpublishing native engine smoke",
        "tests": allowed_lines,
        "script_sha256": hashlib.sha256(script.encode()).hexdigest(),
    }
    out = Path(os.getenv("RUNNER_TEMP", "/tmp")) / "abvm-native-engine-receipt.json"
    out.write_text(json.dumps(receipt, indent=2))
    print("NATIVE_ENGINE_ACCEPTANCE_PASSED", flush=True)


if __name__ == "__main__":
    try:
        run()
    except Exception as exc:
        print("NATIVE_ENGINE_SMOKE_BLOCKED", str(exc), file=sys.stderr, flush=True)
        raise SystemExit(1)
