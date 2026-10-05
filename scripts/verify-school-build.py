#!/usr/bin/env python3
"""Compile every explicitly mapped school source and build a validation-only place.

This does not run Roblox, approve rendering, publish a place, or certify a release.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def mapped_sources(project: Path) -> list[Path]:
    root = project.parent.resolve()
    source_root = (root / "src").resolve()
    data = json.loads(project.read_text(encoding="utf-8"))
    if not isinstance(data.get("tree"), dict):
        raise ValueError("Project must contain a tree object")
    paths: list[Path] = []

    def walk(node: dict) -> None:
        if "$path" in node:
            raw = node["$path"]
            if not isinstance(raw, str):
                raise ValueError("Mapped source path must be a string")
            path = (root / raw).resolve()
            if not path.is_relative_to(source_root):
                raise ValueError(f"Mapped source leaves school/src: {raw}")
            if not path.is_file() or path.suffix not in (".lua", ".luau"):
                raise ValueError(f"Missing or unsupported mapped source: {raw}")
            if path in paths:
                raise ValueError(f"Duplicate runtime source mapping: {raw}")
            paths.append(path)
        for key, child in node.items():
            if not key.startswith("$") and isinstance(child, dict):
                walk(child)

    walk(data["tree"])
    if not paths:
        raise ValueError("No mapped runtime sources found")
    return sorted(paths)


def run_checked(command: list[str], cwd: Path, timeout: int = 30) -> str:
    return subprocess.check_output(command, cwd=cwd, text=True, timeout=timeout).strip()


def validate(repo: Path, output: Path, compiler: Path, rojo: Path, expected: str) -> int:
    repo, output = repo.resolve(), output.resolve()
    if output.is_relative_to(repo):
        raise ValueError("Validation artifacts must be outside the checkout")
    output.mkdir(parents=True, exist_ok=True)
    report: dict = {
        "schemaVersion": 1, "status": "FAIL", "compiledSources": [],
        "runtimeExecuted": False, "renderedParityEstablished": False,
        "releaseApproved": False, "published": False,
    }
    try:
        head = run_checked(["git", "rev-parse", "HEAD"], repo)
        if head != expected:
            raise ValueError(f"Source identity mismatch: {head} != {expected}")
        report["sourceCommit"] = head
        report["schoolTree"] = run_checked(["git", "rev-parse", "HEAD:school"], repo)
        project = repo / "school/default.project.json"
        paths = mapped_sources(project)
        before = {str(p.relative_to(repo)): digest(p) for p in [project, *paths]}
        report["sourceSha256"] = before
        report["tools"] = {
            "luauRelease": "0.741", "compilerSha256": digest(compiler),
            "rojoVersion": run_checked([str(rojo), "--version"], repo),
            "rojoSha256": digest(rojo),
        }
        for path in paths:
            relative = str(path.relative_to(repo))
            result = subprocess.run(
                [str(compiler), str(path)], cwd=repo, stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE, text=True, timeout=20, check=False,
            )
            report["compiledSources"].append({
                "path": relative, "exitCode": result.returncode,
                "diagnostics": result.stderr[:20000],
            })
            print(f"{'PASS' if result.returncode == 0 else 'FAIL'} compile {relative}", flush=True)
        if any(item["exitCode"] != 0 for item in report["compiledSources"]):
            raise ValueError("Mapped-source compilation failed; place build not attempted")
        artifact = output / "PipHigh-validation-only.rbxlx"
        build = subprocess.run(
            [str(rojo), "build", str(project), "--output", str(artifact)],
            cwd=repo, capture_output=True, text=True, timeout=90, check=False,
        )
        (output / "rojo-build.log").write_text(build.stdout + build.stderr, encoding="utf-8")
        if build.returncode != 0 or not artifact.is_file() or not artifact.stat().st_size:
            raise ValueError(f"Rojo place build failed with exit code {build.returncode}")
        model = ET.parse(artifact).getroot()
        containers = [node for node in model.iter("Item")
                      if node.get("class") in ("Script", "LocalScript", "ModuleScript")]
        if model.tag != "roblox" or len(containers) != len(paths):
            raise ValueError("Built place source-container count does not match project mapping")
        after = {str(p.relative_to(repo)): digest(p) for p in [project, *paths]}
        if after != before:
            raise ValueError("Source changed during compilation/build")
        run_checked(["git", "diff", "--exit-code", "HEAD", "--", "school"], repo)
        report["build"] = {"file": artifact.name, "sha256": digest(artifact),
                           "bytes": artifact.stat().st_size, "sourceContainers": len(containers)}
        report["status"] = "PASS_COMPILE_AND_BUILD_ONLY"
    except (ValueError, OSError, subprocess.SubprocessError, ET.ParseError) as exc:
        report["error"] = str(exc)
        print(str(exc), file=sys.stderr, flush=True)
    finally:
        (output / "build-validation.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(report["status"], flush=True)
    return 0 if report["status"] == "PASS_COMPILE_AND_BUILD_ONLY" else 1


class InventoryTests(unittest.TestCase):
    def test_valid_and_fail_closed_inventory(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "src").mkdir()
            source = root / "src/Client.lua"
            source.write_text("return {}\n", encoding="utf-8")
            project = root / "default.project.json"
            def save(tree: dict) -> None:
                project.write_text(json.dumps({"tree": tree}), encoding="utf-8")
            save({"Client": {"$path": "src/Client.lua"}})
            self.assertEqual(mapped_sources(project), [source.resolve()])
            for tree in (
                {}, {"Client": {"$path": "src/Missing.lua"}},
                {"Client": {"$path": "../Client.lua"}},
                {"Client": {"$path": 7}},
                {"A": {"$path": "src/Client.lua"}, "B": {"$path": "src/Client.lua"}},
            ):
                save(tree)
                with self.assertRaises(ValueError):
                    mapped_sources(project)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--out", type=Path)
    parser.add_argument("--compiler", type=Path)
    parser.add_argument("--rojo", type=Path)
    parser.add_argument("--expected-sha")
    args = parser.parse_args()
    if args.self_test:
        result = unittest.TextTestRunner().run(unittest.defaultTestLoader.loadTestsFromTestCase(InventoryTests))
        return 0 if result.wasSuccessful() else 1
    if not all((args.out, args.compiler, args.rojo, args.expected_sha)):
        parser.error("--out, --compiler, --rojo and --expected-sha are required")
    return validate(args.repo, args.out, args.compiler.resolve(), args.rojo.resolve(), args.expected_sha)


if __name__ == "__main__":
    raise SystemExit(main())
