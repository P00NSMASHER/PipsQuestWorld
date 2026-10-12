#!/usr/bin/env python3
"""Fail closed if historical Roblox publishing can be re-enabled via GitHub Actions.

This audits the default-branch PR tree and the original deployment/installer refs.
It NEVER uses a Roblox credential and NEVER contacts the Roblox API.
"""
import base64
import json
import os
from pathlib import Path
import sys
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request, urlopen

OLD_UNIVERSE = "10768955678"
OLD_PLACE = "87245440673982"
CURRENT_UNIVERSE = "10769455759"
CURRENT_PLACE = "114603280760042"
EMMA_BRANCH = "visual/emma-hallway-photo-faithful-20261010"
EMMA_FILE = "publish-emma-classroom.yml"
GUARD_BLOB_SHA = "02c9796422543cf1d5507cc84233774d96869a8e"

RETIRED = {
    "deploy/abvm-playtest-a74278f": {"publish-abvm-playtest.yml"},
    "deploy/neighborhood-playtest-6b1016c": {"publish-neighborhood-playtest.yml"},
    "deploy/rhs-rescue-ad07fb5": {"publish-rhs-rescue.yml"},
    "deploy/rhs-rescue-mobile-a70c": {"publish-rhs-rescue.yml", "publish-roblox.yml"},
    "deploy/roblox-open-cloud-33a5a11": {"publish-roblox.yml"},
    "ops/install-abvm-playtest-publisher": {
        "publish-abvm-playtest.yml", "publish-rhs-rescue.yml", "publish-roblox.yml"
    },
    "ops/install-rhs-rescue-publisher": {
        "publish-rhs-rescue.yml", "publish-roblox.yml"
    },
    "ops/install-roblox-publisher": {"publish-roblox.yml"},
}
ORIGINAL_MAIN_PUBLISHERS = {
    "publish-abvm-playtest.yml", "publish-rhs-rescue.yml", "publish-roblox.yml"
}
DANGEROUS = (
    "versionType=Published",
    "apis.roblox.com/universes/v1/",
    "secrets.ROBLOX_API_KEY",
    "ROBLOX_API_KEY:",
)

def check(condition, message):
    if not condition:
        raise RuntimeError(message)

def github_json(api_path):
    repo = os.environ.get("GITHUB_REPOSITORY", "P00NSMASHER/PipsQuestWorld")
    url = "https://api.github.com/repos/" + repo + "/" + api_path
    headers = {"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}
    token = os.environ.get("GITHUB_TOKEN", "")
    if token:
        headers["Authorization"] = "Bearer " + token
    request = Request(url, headers=headers)
    try:
        with urlopen(request, timeout=18) as response:
            return json.load(response)
    except HTTPError as error:
        if error.code == 404:
            return None  # A removed historical branch or file cannot publish.
        raise

def fetch_file(branch, name):
    path = "contents/.github/workflows/" + quote(name, safe="")
    ref = "?ref=" + quote(branch, safe="")
    data = github_json(path + ref)
    if data is None:
        return None
    check(data.get("encoding") == "base64", "Unexpected GitHub file encoding: " + branch + "/" + name)
    body = base64.b64decode(data["content"]).decode("utf-8")
    return data["sha"], body

def branch_workflow_names(branch):
    data = github_json("contents/.github/workflows?ref=" + quote(branch, safe=""))
    if data is None:
        return set()
    check(isinstance(data, list), "Unexpected workflow listing for " + branch)
    return {entry["name"] for entry in data if entry.get("type") == "file" and entry["name"].endswith((".yml", ".yaml"))}

def audit_retired(branch, file, sha, body):
    identity = branch + "/" + file
    check(sha == GUARD_BLOB_SHA, "Retired workflow changed since security review: " + identity)
    check("refuse-legacy-publish:" in body and "exit 1" in body, "Reject-only job missing: " + identity)
    check("workflow_dispatch:" in body, "Unexpected workflow triggers: " + identity)
    check(not any(item in body for item in DANGEROUS), "Roblox upload/credential detected: " + identity)

def audit_remote_retired_branches():
    count = 0
    for branch, known_files in RETIRED.items():
        names = branch_workflow_names(branch)
        for name in sorted(names):
            remote = fetch_file(branch, name)
            check(remote is not None, "Historical workflow unreadable: " + branch + "/" + name)
            sha, body = remote
            if name in known_files:
                audit_retired(branch, name, sha, body)
                count += 1
            else:
                check(not name.startswith("publish-"), "New historical publish entry point: " + branch + "/" + name)
                check(not any(item in body for item in DANGEROUS), "Undocumented legacy writer: " + branch + "/" + name)
    print("LEGACY_REF_LOCKDOWN_PASS refs=" + str(len(RETIRED)) + " guarded_workflows=" + str(count))

def audit_local_main_candidate():
    folder = Path(".github/workflows")
    check(folder.is_dir(), "Workflow directory missing from candidate")
    for filename in ORIGINAL_MAIN_PUBLISHERS:
        check(not (folder / filename).exists(), "Legacy publisher restored on main: " + filename)
    for file in folder.iterdir():
        if not file.is_file() or file.suffix not in (".yml", ".yaml"):
            continue
        body = file.read_text(encoding="utf-8")
        if file.name == EMMA_FILE:
            audit_emma(body)
            continue
        check(not any(item in body for item in DANGEROUS), "Unapproved Roblox publisher on main: " + file.name)
    print("DEFAULT_BRANCH_LEGACY_PUBLISHERS_ABSENT_PASS")

def audit_emma(body):
    required = (
        CURRENT_UNIVERSE, CURRENT_PLACE, EMMA_BRANCH,
        "school/emma-showroom.project.json",
        "source-parent-sha:",
        "visual-acceptance: pending-real-device-review",
        "PREVIEW_REQUEST",
        "EXPLICIT_CLASSROOM_HALLWAY_PREVIEW_GUARD_PASS",
    )
    for marker in required:
        check(marker in body, "Emma authorisation/target safeguard missing: " + marker)
    check(OLD_PLACE not in body and OLD_UNIVERSE not in body, "Emma publisher targeting old place")

def audit_current_emma():
    remote = fetch_file(EMMA_BRANCH, EMMA_FILE)
    check(remote is not None, "Current Emma publisher missing")
    audit_emma(remote[1])
    print("EMMA_AUTHORIZED_PUBLISH_LANE_UNCHANGED_PASS")

def selftest():
    # The original and a plausible reactivated workflow must both be rejected.
    good = "name: retired\\non:\\n  workflow_dispatch:\\njobs:\\n  refuse-legacy-publish:\\n    steps:\\n      - run: exit 1"
    audit_retired("fixture", "file.yml", GUARD_BLOB_SHA, good)
    for sha, body in (
        ("a" * 40, good),
        (GUARD_BLOB_SHA, good + "\\n" + "secrets.ROBLOX_API_KEY"),
        (GUARD_BLOB_SHA, good + "\\n" + "versionType=Published"),
        (GUARD_BLOB_SHA, "on: push\\njobs: publish:"),
    ):
        try:
            audit_retired("fixture", "file.yml", sha, body)
        except RuntimeError:
            continue
        raise RuntimeError("Regression fixture unexpectedly accepted")
    print("REACTIVATION_NEGATIVE_TESTS_PASS")

if __name__ == "__main__":
    try:
        selftest()
        audit_local_main_candidate()
        audit_remote_retired_branches()
        audit_current_emma()
    except Exception as e:
        print("LEGACY_PUBLISH_LOCKDOWN_FAILED: " + str(e), file=sys.stderr)
        raise SystemExit(1)
