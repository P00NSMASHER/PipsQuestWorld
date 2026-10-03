#!/usr/bin/env python3
"""Deterministic verifier for canonical High School school/** release checkpoints.

This tool never publishes Roblox and never decides QA/Smoke eligibility. It proves
source-tree identity/isolation, distinguishes safe artifact reuse from changed-tree
candidate prep, and emits stable hashes for release manifests.
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


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def tree_inventory(commit_sha: str) -> tuple[list[str], str]:
    raw = git("ls-tree", "-r", commit_sha, "school")
    lines = [line for line in raw.splitlines() if line]
    files = [line.split("\t", 1)[1] for line in lines]
    normalized = "\n".join(lines) + ("\n" if lines else "")
    return files, sha256_text(normalized)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--canonical-ref", required=True)
    ap.add_argument("--mode", choices=("reuse", "candidate"), default="reuse")
    ap.add_argument("--expected-school-tree")
    ap.add_argument("--packaged-ref")
    ap.add_argument("--artifact-name")
    ap.add_argument("--manifest-out")
    args = ap.parse_args()

    canonical_sha = git("rev-parse", f"{args.canonical_ref}^{{commit}}")
    school_tree = git("rev-parse", f"{canonical_sha}:school")

    if args.expected_school_tree and school_tree != args.expected_school_tree:
        print(
            f"SCHOOL_TREE_MISMATCH expected={args.expected_school_tree} actual={school_tree}",
            file=sys.stderr,
        )
        return 2

    school_files, content_sha256 = tree_inventory(canonical_sha)
    if not school_files:
        print("EMPTY_SCHOOL_TREE", file=sys.stderr)
        return 3

    forbidden = sorted(
        p for p in school_files if any(marker in normalize(p) for marker in FORBIDDEN_MARKERS)
    )
    if forbidden:
        print("FORBIDDEN_SCHOOL_PATHS " + json.dumps(forbidden), file=sys.stderr)
        return 4

    packaged_sha = None
    packaged_school_tree = None
    changed_school_paths: list[str] = []
    if args.packaged_ref:
        packaged_sha = git("rev-parse", f"{args.packaged_ref}^{{commit}}")
        packaged_school_tree = git("rev-parse", f"{packaged_sha}:school")
        changed_school_paths = sorted(
            x for x in git(
                "diff", "--name-only", packaged_sha, canonical_sha, "--", "school/"
            ).splitlines()
            if x
        )

    changed = bool(changed_school_paths)
    if args.mode == "reuse":
        if not args.packaged_ref:
            print("REUSE_MODE_REQUIRES_PACKAGED_REF", file=sys.stderr)
            return 5
        if changed or packaged_school_tree != school_tree:
            print(
                "SCHOOL_TREE_CHANGED_SINCE_PACKAGED "
                + json.dumps(changed_school_paths),
                file=sys.stderr,
            )
            return 6
        disposition = "REUSE_EXISTING_UNCHANGED_SCHOOL_TREE"
    else:
        disposition = (
            "PREP_NEW_ARTIFACT_REQUIRED_IF_GATES_PASS"
            if changed or packaged_school_tree not in (None, school_tree)
            else "CANDIDATE_TREE_MATCHES_EXISTING_CHECKPOINT"
        )

    artifact_name = args.artifact_name or (
        f"pip-high-school-{canonical_sha[:7]}-source-tree-{school_tree[:8]}"
    )
    manifest = {
        "schemaVersion": 2,
        "kind": "HIGH_SCHOOL_PACKAGE_READINESS_TREE_PROOF",
        "checkpointOnly": True,
        "nonPublish": True,
        "sourceRoot": "school/**",
        "mode": args.mode,
        "canonicalSha": canonical_sha,
        "schoolTreeGitSha": school_tree,
        "schoolInventorySha256": content_sha256,
        "schoolFileCount": len(school_files),
        "forbiddenPathMatches": 0,
        "packagedSha": packaged_sha,
        "packagedSchoolTreeGitSha": packaged_school_tree,
        "schoolChangedSincePackaged": changed if packaged_sha else None,
        "changedSchoolPaths": changed_school_paths,
        "artifactName": artifact_name,
        "artifactDisposition": disposition,
        "eligibilityDecision": "NOT_EVALUATED_BY_THIS_TOOL",
        "result": "PASS_DETERMINISTIC_TREE_READINESS",
    }
    payload = json.dumps(manifest, sort_keys=True, separators=(",", ":")) + "\n"
    digest = sha256_text(payload)

    if args.manifest_out:
        with open(args.manifest_out, "w", encoding="utf-8", newline="\n") as f:
            f.write(payload)

    print(payload, end="")
    print(f"manifestSha256={digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
