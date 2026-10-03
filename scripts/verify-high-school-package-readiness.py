#!/usr/bin/env python3
"""Deterministic verifier for canonical High School school/** release checkpoints.

This tool never publishes Roblox and never decides QA/Smoke eligibility. It only
proves source-tree identity/isolation so Release/Package can reuse an unchanged
checkpoint instead of rebuilding it.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import PurePosixPath


FORBIDDEN_MARKERS = (
    "phase2",
    "phase-2",
    "phase_2",
    "schoolwork",
    "second-grade",
    "second_grade",
    "secondgrade",
    "starblox",
    "brookhaven",
    "pipsquest",
)


def git(*args: str) -> str:
    p = subprocess.run(
        ["git", *args],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if p.returncode:
        raise RuntimeError(p.stderr.strip() or "git command failed")
    return p.stdout.strip()


def normalize(path: str) -> str:
    return "/".join(part.lower() for part in PurePosixPath(path).parts)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--canonical-ref", required=True)
    ap.add_argument("--expected-school-tree", required=True)
    ap.add_argument("--packaged-ref")
    ap.add_argument("--artifact-name")
    ap.add_argument("--manifest-out")
    args = ap.parse_args()

    canonical_sha = git("rev-parse", f"{args.canonical_ref}^{{commit}}")
    school_tree = git("rev-parse", f"{canonical_sha}:school")
    if school_tree != args.expected_school_tree:
        print(
            f"SCHOOL_TREE_MISMATCH expected={args.expected_school_tree} actual={school_tree}",
            file=sys.stderr,
        )
        return 2

    school_files = [
        x for x in git("ls-tree", "-r", "--name-only", f"{canonical_sha}:school").splitlines()
        if x
    ]
    if not school_files:
        print("EMPTY_SCHOOL_TREE", file=sys.stderr)
        return 3

    forbidden = sorted(
        p for p in school_files if any(marker in normalize(p) for marker in FORBIDDEN_MARKERS)
    )
    if forbidden:
        print("FORBIDDEN_SCHOOL_PATHS " + json.dumps(forbidden), file=sys.stderr)
        return 4

    changed_school_paths: list[str] = []
    packaged_sha = None
    if args.packaged_ref:
        packaged_sha = git("rev-parse", f"{args.packaged_ref}^{{commit}}")
        changed_school_paths = [
            x for x in git(
                "diff", "--name-only", packaged_sha, canonical_sha, "--", "school/"
            ).splitlines()
            if x
        ]
        if changed_school_paths:
            print(
                "SCHOOL_TREE_CHANGED_SINCE_PACKAGED "
                + json.dumps(sorted(changed_school_paths)),
                file=sys.stderr,
            )
            return 5

    manifest = {
        "schemaVersion": 1,
        "kind": "HIGH_SCHOOL_PACKAGE_READINESS_TREE_PROOF",
        "checkpointOnly": True,
        "nonPublish": True,
        "sourceRoot": "school/**",
        "canonicalSha": canonical_sha,
        "schoolTreeGitSha": school_tree,
        "schoolFileCount": len(school_files),
        "forbiddenPathMatches": 0,
        "packagedSha": packaged_sha,
        "changedSchoolPathsSincePackaged": 0 if packaged_sha else None,
        "artifactName": args.artifact_name,
        "result": "PASS_DETERMINISTIC_TREE_IDENTITY",
    }
    payload = json.dumps(manifest, sort_keys=True, separators=(",", ":")) + "\n"
    digest = hashlib.sha256(payload.encode("utf-8")).hexdigest()

    if args.manifest_out:
        with open(args.manifest_out, "w", encoding="utf-8", newline="\n") as f:
            f.write(payload)

    print(payload, end="")
    print(f"manifestSha256={digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
