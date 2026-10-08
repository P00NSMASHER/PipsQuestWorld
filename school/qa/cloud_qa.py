#!/usr/bin/env python3
"""Fail-closed Roblox cloud QA: never writes to a live place, and never publishes."""
import argparse
import json
import os
from pathlib import Path
import re
import sys
import time
import urllib.error
import urllib.request

API = "https://apis.roblox.com"
PRODUCTION_UNIVERSES = {"10768955678", "6027194615"}
PRODUCTION_PLACES = {"87245440673982", "17602626136"}

def verify_target(universe, place, key):
    for label, value in (("universe", universe), ("place", place)):
        if not re.fullmatch(r"[1-9][0-9]*", value or ""):
            raise ValueError(f"QA {label} must be a numeric ID")
    if universe == place or universe in PRODUCTION_UNIVERSES or place in PRODUCTION_PLACES:
        raise ValueError("QA target is a known production identifier: blocked")
    if not key or len(key) < 20:
        raise ValueError("ROBLOX_QA_API_KEY is absent or invalid")
    if os.getenv("ROBLOX_API_KEY") and key == os.getenv("ROBLOX_API_KEY"):
        raise ValueError("QA key equals production key: blocked")


def verify_key_permissions(universe, key):
    """Require a live, narrowly scoped QA-only key before any place mutation."""
    body = json.dumps({"apiKey": key}).encode("utf-8")
    req = urllib.request.Request(API + "/api-keys/v1/introspect", data=body,
                                 headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=40) as response:
            info = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"QA key introspection failed: HTTP {error.code}") from None

    if info.get("enabled") is not True or info.get("expired") is True:
        raise ValueError("QA key is disabled or expired")
    required = {"universe.places:write", "universe.place.luau-execution-session:write"}
    discovered = set()
    for scope in info.get("scopes", []):
        name = scope.get("name", "")
        operations = scope.get("operations", []) or []
        if ":" in name and not operations:
            permissions = {name}
        else:
            permissions = {name + ":" + operation for operation in operations}
        discovered.update(permissions)
        ids = set(str(i) for i in scope.get("universeIds", []))
        if ids != {universe}:
            raise ValueError("QA API key does not restrict every scope to the exact QA universe")
    if discovered != required:
        raise ValueError("QA key has wrong or excessive API permissions")
    print("QA key scope introspection passed (restricted to isolated universe)")

def request(method, path, key, data=None, content_type="application/json"):
    headers = {"x-api-key": key, "Accept": "application/json"}
    if data is not None:
        headers["Content-Type"] = content_type
    req = urllib.request.Request(API + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=40) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        # Never log secrets, full API response headers, or arbitrary response bodies.
        raise RuntimeError(f"Open Cloud HTTP {error.code} for {method} {path.split('?')[0]}") from None

def run(universe, place, key, place_file, test_file):
    verify_target(universe, place, key)
    if not place_file.is_file() or not test_file.is_file():
        raise ValueError("Expected place and script files")
    place_xml = place_file.read_bytes()
    if not place_xml.startswith(b"<roblox"):
        raise ValueError("Expected an XML Rojo place: refusing upload")
    script = test_file.read_text(encoding="utf-8")
    if "__QA_UNIVERSE_ID__" not in script or "__QA_PLACE_ID__" not in script:
        raise ValueError("Missing runtime QA target guards in test script")
    script = script.replace("__QA_UNIVERSE_ID__", universe).replace("__QA_PLACE_ID__", place)
    verify_key_permissions(universe, key)

    print(f"Running engine QA against isolated universe={universe}, place={place}")
    saved = request("POST", f"/universes/v1/{universe}/places/{place}/versions?versionType=Saved",
                    key, place_xml, "application/xml")
    version = saved.get("versionNumber")
    if type(version) is not int or version <= 0:
        raise RuntimeError("Saved version response missing versionNumber")
    print(f"Saved test-only version {version} (never Published)")

    task = request("POST", f"/cloud/v2/universes/{universe}/places/{place}/versions/{version}/luau-execution-session-tasks",
                   key, json.dumps({"script": script}).encode("utf-8"))
    path = task.get("path", "")
    prefix = f"universes/{universe}/places/{place}/versions/{version}/"
    if not path.startswith(prefix) or not re.fullmatch(
        r"universes/[0-9]+/places/[0-9]+/versions/[0-9]+/luau-execution-sessions/[^/]+/tasks/[^/]+", path
    ):
        raise RuntimeError("Cloud returned an unexpected task path")

    deadline = time.monotonic() + 240
    while time.monotonic() < deadline:
        task = request("GET", "/cloud/v2/" + path, key)
        state = task.get("state")
        if state != "PROCESSING":
            break
        time.sleep(3)
    else:
        raise RuntimeError("Engine QA timed out")
    if state != "COMPLETE":
        raise RuntimeError("Engine task failed in state " + str(state))

    output = task.get("output", {}).get("results", [])
    if "EMMA_CLOUD_QA_PASS:" not in json.dumps(output):
        raise RuntimeError("Task completed without an actual PASS receipt")
    print(f"EMMA_CLOUD_QA_SUCCESS savedVersion={version}")

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--place", type=Path, required=True)
    p.add_argument("--script", type=Path, required=True)
    args = p.parse_args()
    try:
        run(os.getenv("ROBLOX_QA_UNIVERSE_ID", ""), os.getenv("ROBLOX_QA_PLACE_ID", ""),
            os.getenv("ROBLOX_QA_API_KEY", ""), args.place, args.script)
    except (ValueError, RuntimeError, OSError) as error:
        print("EMMA_CLOUD_QA_FAILED: " + str(error), file=sys.stderr)
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
