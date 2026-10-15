#!/usr/bin/env python3
"""Independently reject reactivated historical Roblox publishers.

The verifier itself is checked out from the pull request's exact base SHA by
`pull_request_target`. Candidate files are treated only as data. This script
never uses a Roblox credential and never contacts the Roblox API.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
TRUSTED_ROOT = HERE.parents[1]

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
    "deploy/rhs-rescue-mobile-a70c": {
        "publish-rhs-rescue.yml", "publish-roblox.yml"
    },
    "deploy/roblox-open-cloud-33a5a11": {"publish-roblox.yml"},
    "ops/install-abvm-playtest-publisher": {
        "publish-abvm-playtest.yml", "publish-rhs-rescue.yml",
        "publish-roblox.yml",
    },
    "ops/install-rhs-rescue-publisher": {
        "publish-rhs-rescue.yml", "publish-roblox.yml"
    },
    "ops/install-roblox-publisher": {"publish-roblox.yml"},
}
ORIGINAL_MAIN_PUBLISHERS = {
    "publish-abvm-playtest.yml", "publish-rhs-rescue.yml",
    "publish-roblox.yml",
}
DANGEROUS = (
    "versionType=Published",
    "apis.roblox.com/universes/v1/",
    "secrets.ROBLOX_API_KEY",
    "ROBLOX_API_KEY:",
)


def check(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def git_output(*args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(TRUSTED_ROOT), *args],
        capture_output=True,
        text=True,
        check=True,
        timeout=60,
    )
    return result.stdout


def fetch_remote_branch(branch: str) -> str:
    """Fetch only canonical-repository refs through the trusted checkout."""
    remote_ref = "refs/remotes/origin/" + branch
    subprocess.run(
        [
            "git", "-C", str(TRUSTED_ROOT), "-c", "protocol.version=2",
            "fetch", "--no-tags", "--quiet", "--depth=1", "--filter=blob:none",
            "origin", "+refs/heads/" + branch + ":" + remote_ref,
        ],
        capture_output=True,
        text=True,
        check=True,
        timeout=120,
    )
    return remote_ref


def fetch_file(branch: str, name: str):
    ref = "refs/remotes/origin/" + branch
    path = ".github/workflows/" + name
    try:
        sha = git_output("rev-parse", ref + ":" + path).strip()
        body = git_output("show", ref + ":" + path)
        return sha, body
    except subprocess.CalledProcessError:
        return None


def branch_workflow_names(branch: str) -> set[str]:
    ref = fetch_remote_branch(branch)
    paths = git_output(
        "ls-tree", "-r", "--name-only", ref, ".github/workflows"
    ).splitlines()
    return {
        name[len(".github/workflows/"):]
        for name in paths
        if name.startswith(".github/workflows/")
        and name.endswith((".yml", ".yaml"))
    }


def audit_retired(branch: str, filename: str, sha: str, body: str) -> None:
    identity = branch + "/" + filename
    check(
        sha == GUARD_BLOB_SHA,
        "Retired workflow changed since security review: " + identity,
    )
    check(
        "refuse-legacy-publish:" in body and "exit 1" in body,
        "Reject-only job missing: " + identity,
    )
    check("workflow_dispatch:" in body, "Unexpected workflow triggers: " + identity)
    check(
        not any(item in body for item in DANGEROUS),
        "Roblox upload/credential detected: " + identity,
    )


def audit_remote_retired_branches() -> None:
    count = 0
    for branch, known_files in RETIRED.items():
        names = branch_workflow_names(branch)
        for name in sorted(names):
            remote = fetch_file(branch, name)
            check(
                remote is not None,
                "Historical workflow unreadable: " + branch + "/" + name,
            )
            sha, body = remote
            if name in known_files:
                audit_retired(branch, name, sha, body)
                count += 1
            else:
                check(
                    not name.startswith("publish-"),
                    "New historical publish entry point: " + branch + "/" + name,
                )
                check(
                    not any(item in body for item in DANGEROUS),
                    "Undocumented legacy writer: " + branch + "/" + name,
                )
    print(
        "LEGACY_REF_LOCKDOWN_PASS refs="
        + str(len(RETIRED))
        + " guarded_workflows="
        + str(count)
    )


def audit_emma(body: str) -> None:
    required = (
        CURRENT_UNIVERSE,
        CURRENT_PLACE,
        EMMA_BRANCH,
        "school/emma-showroom.project.json",
        "source-parent-sha:",
        "visual-acceptance: pending-real-device-review",
        "PREVIEW_REQUEST",
        "EXPLICIT_CLASSROOM_HALLWAY_PREVIEW_GUARD_PASS",
    )
    for marker in required:
        check(marker in body, "Emma authorisation/target safeguard missing: " + marker)
    check(
        OLD_PLACE not in body and OLD_UNIVERSE not in body,
        "Emma publisher targeting old place",
    )


def audit_local_candidate(candidate_root: Path) -> None:
    """Parse candidate workflow text without importing or executing candidate code."""
    folder = candidate_root / ".github/workflows"
    check(folder.is_dir(), "Workflow directory missing from candidate")
    for filename in ORIGINAL_MAIN_PUBLISHERS:
        check(
            not (folder / filename).exists(),
            "Legacy publisher restored on main: " + filename,
        )
    for file in folder.iterdir():
        if not file.is_file() or file.suffix not in (".yml", ".yaml"):
            continue
        body = file.read_text(encoding="utf-8")
        if file.name == EMMA_FILE:
            audit_emma(body)
            continue
        check(
            not any(item in body for item in DANGEROUS),
            "Unapproved Roblox publisher on main: " + file.name,
        )
    print("UNTRUSTED_CANDIDATE_LEGACY_PUBLISHERS_ABSENT_PASS")


def audit_current_emma() -> None:
    fetch_remote_branch(EMMA_BRANCH)
    remote = fetch_file(EMMA_BRANCH, EMMA_FILE)
    check(remote is not None, "Current Emma publisher missing")
    audit_emma(remote[1])
    print("EMMA_AUTHORIZED_PUBLISH_LANE_UNCHANGED_PASS")


def selftest() -> None:
    good = (
        "name: retired\\non:\\n  workflow_dispatch:\\njobs:\\n"
        "  refuse-legacy-publish:\\n    steps:\\n      - run: exit 1"
    )
    audit_retired("fixture", "file.yml", GUARD_BLOB_SHA, good)
    for sha, body in (
        ("a" * 40, good),
        (GUARD_BLOB_SHA, good + "\\nsecrets.ROBLOX_API_KEY"),
        (GUARD_BLOB_SHA, good + "\\nversionType=Published"),
        (GUARD_BLOB_SHA, "on: push\\njobs: publish:"),
    ):
        try:
            audit_retired("fixture", "file.yml", sha, body)
        except RuntimeError:
            continue
        raise RuntimeError("Regression fixture unexpectedly accepted")

    # Adversarial trust-boundary regression: even when a candidate replaces its
    # own verifier with an unconditional pass, the trusted verifier still
    # rejects a publisher added to that candidate tree.
    with tempfile.TemporaryDirectory() as temporary:
        candidate = Path(temporary)
        workflows = candidate / ".github/workflows"
        scripts = candidate / "scripts"
        workflows.mkdir(parents=True)
        scripts.mkdir()
        (scripts / "verify_legacy_roblox_publishers.py").write_text(
            "raise SystemExit(0)\\n", encoding="utf-8"
        )
        (workflows / "candidate-self-attested.yml").write_text(
            "jobs:\\n  publish:\\n    steps:\\n"
            "      - run: echo versionType=Published\\n",
            encoding="utf-8",
        )
        try:
            audit_local_candidate(candidate)
        except RuntimeError as exc:
            check(
                "Unapproved Roblox publisher" in str(exc),
                "Wrong adversarial failure: " + str(exc),
            )
        else:
            raise RuntimeError("Candidate-controlled verifier bypass was accepted")
    print("TRUSTED_VERIFIER_ADVERSARIAL_TEST_PASS")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--candidate-root",
        type=Path,
        default=TRUSTED_ROOT,
        help="Candidate repository tree to inspect as untrusted data",
    )
    args = parser.parse_args()
    candidate_root = args.candidate_root.resolve()
    check(candidate_root.is_dir(), "Candidate root missing")
    selftest()
    audit_local_candidate(candidate_root)
    audit_remote_retired_branches()
    audit_current_emma()


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print("LEGACY_PUBLISH_LOCKDOWN_FAILED: " + str(exc), file=sys.stderr)
        raise SystemExit(1)
