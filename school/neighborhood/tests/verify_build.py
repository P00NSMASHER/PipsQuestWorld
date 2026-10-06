#!/usr/bin/env python3
"""Compile and test the isolated neighborhood preview; never certify runtime play."""
from __future__ import annotations
import argparse
import copy
import hashlib
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
MODE = ROOT / "school/neighborhood"
PROJECT = ROOT / "school/neighborhood.project.json"
SOURCES = {
    "shared/Catalog.lua", "shared/Layout.lua", "server/Garage.lua",
    "server/Learning.lua", "server/Leaderboards.lua", "server/Main.server.lua", "server/ProfileStore.lua",
    "server/QuestionBank.lua", "server/Wardrobe.lua", "server/World.lua",
    "client/Main.client.lua", "client/UI.lua",
}
EXPECTED_SCRIPTS = {
    "ReplicatedStorage/NeighborhoodShared/Catalog": "ModuleScript",
    "ReplicatedStorage/NeighborhoodShared/Layout": "ModuleScript",
    **{f"ServerScriptService/Neighborhood/{name}": "ModuleScript" for name in
       ("Garage", "Learning", "Leaderboards", "ProfileStore", "QuestionBank", "Wardrobe", "World")},
    "ServerScriptService/Neighborhood/Main": "Script",
    "StarterPlayer/StarterPlayerScripts/NeighborhoodClient/Main": "LocalScript",
    "StarterPlayer/StarterPlayerScripts/NeighborhoodClient/UI": "ModuleScript",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_project(project: dict) -> None:
    mappings = {}
    def visit(node: dict, path: str = "") -> None:
        require(isinstance(node, dict), f"invalid project node: {path}")
        if "$path" in node:
            mappings[path] = node["$path"]
        for name, child in node.items():
            if not name.startswith("$"):
                visit(child, f"{path}/{name}".strip("/"))
    visit(project["tree"])
    require(mappings == {
        "ReplicatedStorage/NeighborhoodShared": "neighborhood/shared",
        "ServerScriptService/Neighborhood": "neighborhood/server",
        "StarterPlayer/StarterPlayerScripts/NeighborhoodClient": "neighborhood/client",
    }, "project must map only the three neighborhood source directories")
    require(project["tree"]["$className"] == "DataModel", "place must be a DataModel")


def inspect_place(root: ET.Element) -> dict[str, str]:
    scripts = {}
    def visit(parent: ET.Element, prefix: str = "") -> None:
        for item in parent.findall("Item"):
            node = item.find('./Properties/string[@name="Name"]')
            name = node.text if node is not None else item.get("class", "")
            path = f"{prefix}/{name}".strip("/")
            cls = item.get("class")
            if cls in {"Script", "LocalScript", "ModuleScript"}:
                require(path not in scripts, f"duplicate script path: {path}")
                scripts[path] = cls
                source = item.find('./Properties/*[@name="Source"]')
                require(source is not None and bool(source.text), f"missing source: {path}")
            visit(item, path)
    visit(root)
    require(scripts == EXPECTED_SCRIPTS,
            "built place contains missing, extra, misplaced, or old-mode scripts")
    return scripts


def validate_abvm_contract() -> dict:
    """Protect photo-critical source intent; this is not a rendered-fidelity assertion."""
    world = (MODE / "server/World.lua").read_text(encoding="utf-8")
    catalog = (MODE / "shared/Catalog.lua").read_text(encoding="utf-8")
    main = (MODE / "client/Main.client.lua").read_text(encoding="utf-8")
    server_main = (MODE / "server/Main.server.lua").read_text(encoding="utf-8")
    required_world = (
        "makeFrontArch(root,-27,false)",
        "makeFrontArch(root,-9,true)",
        "makeFrontArch(root,9,true)",
        "makeFrontArch(root,27,false)",
        '"1928"',
        "Howard outer brick arch",
        "Howard inner stone arch",
        "ENTRANCE ON HOWARD AVENUE",
        "School parking lot",
        "Howard retaining wall",
        "Brick chimney",
        "Front stone belt",
        "Dr. McBreen — Principal",
        "Mrs. Thompson — Secretary",
        "Mrs. Boyer — Assistant Principal",
        "World.schoolDoor=CFrame.new(0,3,18)",
        "Central hall floor stair side",
        "Stair opening side guard",
    )
    missing = [marker for marker in required_world if marker not in world]
    require(not missing, f"ABVM photo/admin contract markers missing: {missing}")
    require('"Second floor slab"' not in world and '"Third floor slab"' not in world,
            "redundant full upper slabs would cap the playable stairwells")
    expected_arch_calls = (
        "makeFrontArch(root,-27,false)",
        "makeFrontArch(root,-9,true)",
        "makeFrontArch(root,9,true)",
        "makeFrontArch(root,27,false)",
    )
    require(all(world.count(call) == 1 for call in expected_arch_calls),
            "formal facade must retain the four exact configured arched bays")

    expected_room_calls = (
        'classroom(root,"math","Math","Mrs. Campion",-49,4,',
        'classroom(root,"reading","Reading","Mrs. Russek",49,4,',
        'classroom(root,"grammar","Grammar","Mrs. Benulis",-49,20,',
        'classroom(root,"religion","Religion","Mr. Bolich",49,20,',
        'classroom(root,"vocabulary","Vocabulary","Mr. Yordy",-49,36,',
        'classroom(root,"spelling","Spelling","Mrs. Kochol",49,36,',
    )
    require(all(world.count(call) == 1 for call in expected_room_calls),
            "six classroom volumes must remain on their intended floors")
    require('World.shopPosition=Vector3.new(31,5,-49)' in world,
            "ABVM School Shop position moved outside its guarded lobby zone")
    required_subjects = {
        "math": "Mrs. Campion", "reading": "Mrs. Russek",
        "grammar": "Mrs. Benulis", "religion": "Mr. Bolich",
        "vocabulary": "Mr. Yordy", "spelling": "Mrs. Kochol",
    }
    for subject, teacher in required_subjects.items():
        require(f'id="{subject}"' in catalog and f'teacher="{teacher}"' in catalog,
                f"missing ABVM classroom mapping: {subject} / {teacher}")
    require("ASSUMPTION BVM CATHOLIC SCHOOL" in main,
            "mobile classroom identity lost full school name")
    duplicate_start = server_main.find("if pending.wrongChoices[args.choice] then")
    miss_start = server_main.find("local missId=", duplicate_start)
    require(duplicate_start >= 0 and miss_start > duplicate_start,
            "duplicate wrong-answer branch missing")
    duplicate_body = server_main[duplicate_start:miss_start]
    require("duplicate=true" in duplicate_body and "penalty=0" in duplicate_body and
            "deducted=0" in duplicate_body and "hint=pending.q.hint" in duplicate_body and
            "explanation=" not in duplicate_body,
            "duplicate wrong-answer path must stay hint-only and penalty-free")
    return {
        "frontArchedBays": 4,
        "centerDoorBays": 2,
        "subjectClassrooms": len(required_subjects),
        "photoContractStaticOnly": True,
    }


def check_guard_mutations(project: dict, place: ET.Element) -> int:
    bad_project = copy.deepcopy(project)
    bad_project["tree"]["ServerScriptService"]["Neighborhood"]["$path"] = "src/server"
    try:
        validate_project(bad_project)
    except ValueError:
        pass
    else:
        raise ValueError("project guard accepted legacy source mapping")
    bad_place = copy.deepcopy(place)
    bad_item = ET.SubElement(bad_place, "Item", {"class": "ModuleScript"})
    props = ET.SubElement(bad_item, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = "QuestionBank"
    ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = "return {}"
    try:
        inspect_place(bad_place)
    except ValueError:
        pass
    else:
        raise ValueError("place guard accepted an extra exposed question module")
    bad_place = copy.deepcopy(place)
    for item in bad_place.iter("Item"):
        if item.get("class") == "LocalScript":
            item.set("class", "ModuleScript")
            break
    try:
        inspect_place(bad_place)
    except ValueError:
        return 3
    raise ValueError("place guard accepted a missing client entrypoint")


def run(argv: list[str], log_path: Path, append: bool = False) -> str:
    result = subprocess.run(argv, cwd=ROOT, text=True, capture_output=True, timeout=120)
    with log_path.open("a" if append else "w", encoding="utf-8") as output:
        output.write(result.stdout + result.stderr)
    require(result.returncode == 0, f"command failed; see {log_path.name}: {argv[0]}")
    return result.stdout


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compiler", required=True, type=Path)
    parser.add_argument("--luau", required=True, type=Path)
    parser.add_argument("--rojo", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--expected-sha")
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    report = {"status": "FAIL", "runtimeExecuted": False,
              "physicalIPhoneTested": False, "visualPolishApproved": False,
              "robloxPublished": False, "sourceCommit": None}
    try:
        if args.expected_sha:
            require(re.fullmatch(r"[0-9a-f]{40}", args.expected_sha) is not None,
                    "expected SHA must be a full commit")
            head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
            require(head == args.expected_sha, "checkout differs from expected commit")
            report["sourceCommit"] = head
        project = json.loads(PROJECT.read_text(encoding="utf-8"))
        validate_project(project)
        abvm_contract = validate_abvm_contract()
        actual = {str(p.relative_to(MODE)) for subdir in ("shared", "server", "client")
                  for p in (MODE / subdir).rglob("*.lua")}
        require(actual == SOURCES, "mapped source inventory changed; review expected scripts")
        compile_log = args.out / "compile.log"
        compile_log.write_text("", encoding="utf-8")
        for path in sorted(SOURCES):
            run([str(args.compiler.resolve()), "--null", str(MODE / path)], compile_log, True)
        test_output = run([str(args.luau.resolve()), str(MODE / "tests/core.spec.lua")],
                          args.out / "core-tests.log")
        require("NEIGHBORHOOD_CORE_TESTS_PASS 27" in test_output, "complete model-test marker missing")
        place_path = args.out / "PipHigh-Neighborhood-preview.rbxlx"
        run([str(args.rojo.resolve()), "build", str(PROJECT), "-o", str(place_path)],
            args.out / "rojo-build.log")
        place = ET.parse(place_path).getroot()
        script_inventory = inspect_place(place)
        mutations = check_guard_mutations(project, place)
        files = [PROJECT, *[MODE / path for path in sorted(SOURCES)],
                 MODE / "tests/core.spec.lua", Path(__file__).resolve()]
        report.update(status="PASS_STATIC_PREVIEW_ONLY", sourceFilesCompiled=len(SOURCES),
                      coreTests=27, buildGuardNegativeControls=mutations,
                      abvmStaticContract=abvm_contract,
                      scriptInventory=script_inventory,
                      fileSha256={str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                                  for p in files},
                      placeSha256=hashlib.sha256(place_path.read_bytes()).hexdigest())
        print("NEIGHBORHOOD_STATIC_PREVIEW_OK: 27 model tests; 12 compiled sources; 3 negative controls")
    except (ValueError, OSError, subprocess.SubprocessError, ET.ParseError) as exc:
        report["error"] = str(exc)
        print(f"NEIGHBORHOOD_STATIC_PREVIEW_FAIL: {exc}", file=sys.stderr)
    (args.out / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return 0 if report["status"] == "PASS_STATIC_PREVIEW_ONLY" else 1


if __name__ == "__main__":
    raise SystemExit(main())
