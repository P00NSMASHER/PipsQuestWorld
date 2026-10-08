#!/usr/bin/env python3
"""Resolve where the immutable reviewed Emma curriculum API is consumed.

This runs only from the default branch. Never let a source artifact or an
arbitrary branch ref cause the privileged content-preparation job to run code.
"""
import json
import os
from pathlib import Path
import re
import sys

ALLOWED_FIELDS = {"schemaVersion", "activeBranch", "contractRoot"}
CONTRACT_ROOT = "school/emma-classroom"
BRANCH_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9._/-]{0,127}\Z")

def resolve(config):
    if not isinstance(config, dict) or set(config) != ALLOWED_FIELDS:
        raise ValueError("Unexpected curriculum routing fields")
    if type(config["schemaVersion"]) is not int or config["schemaVersion"] != 1:
        raise ValueError("Unsupported curriculum routing schema")
    if config["contractRoot"] != CONTRACT_ROOT:
        raise ValueError("The stable curriculum adapter path cannot silently move")
    branch = config["activeBranch"]
    if not isinstance(branch, str) or not BRANCH_RE.fullmatch(branch):
        raise ValueError("Unsafe curriculum target branch")
    segments = branch.split("/")
    if any(not s or s.startswith(".") or s.endswith(".") or s.endswith(".lock") for s in segments):
        raise ValueError("Unsafe or ambiguous branch path")
    if ".." in branch or "@{" in branch or branch.lower() in {"main", "master", "develop", "head"}:
        raise ValueError("A reviewed game branch, not a default branch, is required")
    return branch

def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: emma_curriculum_target.py CONFIG.json")
    branch = resolve(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")))
    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
            output.write("branch=" + branch + "\n")
    print("Reviewed Emma curriculum consumer: " + branch)

if __name__ == "__main__":
    main()
