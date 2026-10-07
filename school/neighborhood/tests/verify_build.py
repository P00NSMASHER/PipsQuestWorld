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
    leaderboards_source = (MODE / "server/Leaderboards.lua").read_text(encoding="utf-8")
    required_world = (
        "makeFrontArch(root,-17,false)",
        "makeFrontArch(root,17,true)",
        "makeFrontArch(root,51,true)",
        '"1928"',
        "Howard outer brick arch",
        "Howard inner stone arch",
        "ENTRANCE ON HOWARD AVENUE",
        "School parking lot",
        "Howard retaining wall",
        "Brick chimney",
        "Front stone belt",
        "Gold standard front cornice",
        "Gold standard parapet pier",
        "Gold standard parapet pier cap",
        "Roof parapet east",
        "East side stone cornice",
        "Gold standard side parapet pier",
        "Gold standard side parapet cap",
        "Gold standard distant ridge",
        "Distant water tower tank",
        "Distant radio mast antenna",
        "Front foundation west",
        "Front west fence post",
        "Gold standard facade banner",
        "Gold standard front school sign",
        "Gold standard entrance strip",
        "Gold standard sign flourish ",
        "Gold standard sign leaf ",
        "Front school sign arched crown",
        "Front garden terrace west",
        "Front garden terrace west upper",
        "Front lower stair",
        "Front middle landing",
        "Front upper stair",
        "Front middle landing handrail",
        "Gold standard stair planter wall",
        "Gold standard front sidewalk",
        "Gold standard front curb",
        "Gold standard front hydrant",
        "Gold standard street sign plate",
        "Gold standard east sidewalk",
        "Gold standard east curb",
        "Gold standard east street lane",
        "Gold standard east far curb",
        "Gold standard east corner tower",
        "Front pilaster stone cap",
        "School window warm glow",
        "School window sill",
        "Arch segmented glazing",
        "Arch segmented warm backlight",
        "GoldStandardClouds",
        "ABVMGoldBloom",
        "ABVMGoldGrade",
        "ABVMSunRays",
        "Tree canopy chunk",
        "Dr. McBreen — Principal",
        "Mrs. Thompson — Secretary",
        "Mrs. Boyer — Assistant Principal",
        "local arrivalCf=CFrame.lookAt(arrivalPosition,arrivalFocus)",
        "World.schoolDoor=arrivalCf",
        "Central hall floor stair side",
        "Stair opening side guard",
        "SCHOOL INFO",
        "★  ABVM SCHOOL LEADERS  ★",
        "Leaderboard gold top trim",
        "Credits leaderboard",
        "Classroom area rug",
        "Teacher desk top",
        "Student work board",
        "Classroom doorway jamb",
        "Hall navy inlay",
        "Hall wainscot",
        "Hall classroom door jamb",
        "Water fountain body",
        "Lobby terrazzo floor",
        "Lobby welcome rug",
        "Trophy case backing",
        "Stair landing light",
        "Classroom acoustic ceiling",
        "Classroom vision glass",
        "Upper hall locker bank",
        "Lower hall cubby bank",
        "Hall student gallery",
        "Lobby acoustic ceiling",
        "Lobby reception front",
        "Lobby mission frame",
    )
    missing = [marker for marker in required_world if marker not in world]
    require(not missing, f"ABVM photo/admin contract markers missing: {missing}")
    require('"Second floor slab"' not in world and '"Third floor slab"' not in world,
            "redundant full upper slabs would cap the playable stairwells")
    require('"Arched upper glazing"' not in world and '"Arch warm backlight"' not in world,
            "rectangular upper glazing returned; arched windows must keep segmented curve-following panels")
    expected_arch_calls = (
        "makeFrontArch(root,-17,false)",
        "makeFrontArch(root,17,true)",
        "makeFrontArch(root,51,true)",
    )
    require(all(world.count(call) == 1 for call in expected_arch_calls),
            "formal facade must retain the three exact gold-standard arched bays")
    require(all(marker in world for marker in (
        '"Front lower far west"', '"Front lower interbay west"', '"Front lower interbay east"', '"Front lower far east"',
        "local stairCenterX=17", "stairCenterX-40", "stairCenterX+40", "stairCenterX-18", "stairCenterX+18"
    )), "gold-standard lower facade openings / stair alignment regressed")
    require("for _,x in ipairs({-51,-17,17,51}) do" in world and
            "local facadeWindowWidth=x==-51 and 9.6 or 15.2" in world and
            "schoolWindowPanel(root,CFrame.new(x,floorY,-33.68),facadeWindowWidth,5.9)" in world,
            "gold-standard four-bay upper facade rhythm regressed")

    require('World.shopPosition=Vector3.new(31,5,-49)' in world,
            "ABVM School Shop position moved outside its guarded lobby zone")
    required_subjects = {
        "math": ("Math", "Mrs. Campion", "-49,4"),
        "reading": ("Reading", "Mrs. Russek", "49,4"),
        "grammar": ("Grammar", "Mrs. Benulis", "-49,20"),
        "religion": ("Religion", "Mr. Bolich", "49,20"),
        "vocabulary": ("Vocabulary", "Mr. Yordy", "-49,36"),
        "spelling": ("Spelling", "Mrs. Kochol", "49,36"),
    }
    for subject, (title, teacher, position) in required_subjects.items():
        require(f'id="{subject}"' in catalog and f'teacher="{teacher}"' in catalog,
                f"missing ABVM classroom mapping: {subject} / {teacher}")
        literal_call = f'classroom(root,"{subject}","{title}","{teacher}",{position},'
        bound_call = f'classroom(root,"{subject}","{title}",(active.{subject} and active.{subject}.teacher) or "{teacher}",{position},'
        require(
            literal_call in world or bound_call in world,
            f"world classroom lost approved teacher/position contract: {subject} / {teacher}"
        )
    require("Catalog.Faculty = {" not in catalog and "Catalog.ByStaffId" not in catalog,
            "broad real-faculty directory scope must remain absent")
    require("ASSUMPTION BVM CATHOLIC SCHOOL" in main,
            "mobile classroom identity lost full school name")
    require("Learning Lab" not in main and "Faculty & Staff Directory" not in main and "Catalog.Faculty" not in main,
            "rejected generic Learning Lab / broad faculty directory UI reintroduced")
    for teacher in ("Mrs. Campion","Mrs. Russek","Mrs. Benulis","Mr. Bolich","Mr. Yordy","Mrs. Kochol"):
        require(teacher in catalog, f"approved classroom teacher missing from Catalog.Subjects: {teacher}")
    require('Name="PrimaryNav"' in main and 'BackgroundColor3=UI.P.ink' in main,
            "gold-standard dark primary navigation rail missing")
    require('nav.Parent=canvas' in main and 'layout.goldLandscape' in main,
            "landscape navigation must detach from the top header into the right rail")
    require('IgnoreGuiInset=true' in main and 'ScreenInsets=Enum.ScreenInsets.None' in main,
            "top capsule must be able to align vertically with Roblox CoreGui")
    require('goalCard=UI.new("Frame",header' in main and 'CornerRadius=999' in main,
            "approved capsule-integrated reward composition regressed")
    require('nav.Position=UDim2.fromOffset(layout.nav.x,layout.nav.y)' in main,
            "approved far-right navigation placement regressed")
    require('Size=UDim2.fromOffset(760,50)' not in main,
            "legacy wide white-toolbar HUD pattern returned")

    ui_source = (MODE / "client/UI.lua").read_text(encoding="utf-8")
    layout_source = (MODE / "shared/Layout.lua").read_text(encoding="utf-8")
    gold_ui_markers = (
        "function UI.surface", "function UI.chip", "function UI.iconButton",
        "function UI.answerCard", "function UI.feedbackCard", "function UI.flyout",
        "function UI.avatarViewport", "function UI.vectorIcon", "function UI.tintIcon",
    )
    require(all(marker in ui_source for marker in gold_ui_markers),
            "gold-standard reusable UI primitives regressed")
    require(all(marker in layout_source for marker in (
        "rail = {", "goal = {", "drive = {", "shopCardHeight", "columns = columns",
    )), "gold-standard responsive layout contract regressed")
    require(all(marker in main for marker in (
        'Name="ProductGrid"', 'Name="AnswerGrid"', 'FillDirectionMaxCells=2',
        'visual.color:Lerp(UI.P.white,.88)', 'cardStroke.Transparency=.58',
        '"ABVM UNIFORM PREVIEW"', 'local equippedDefs={', '"✓  Save Outfit"',
        'showClasses=function()', 'showAvatar=function()',
        '"▲\\nDRIVE","go"', '"▼\\nREVERSE","back"', '"P  PARK"', 'pedalDefs={',
        'local subjectVisuals={', '"Starter","Family","Luxury"',
        '"Starter","Sport","Premium"',
        'shopTabs.BackgroundColor3=UI.P.navySoft',
        'shopSubtabs.BackgroundColor3=UI.P.soft',
        'badgeText=equipped and "✓ EQUIPPED" or owned and "OWNED"',
        'state.goal==item.id and "★" or "☆"',
        'local coinIcon=UI.frame(wallet',
        'local streakIcon=UI.frame(streakPill',
        'streakCaption.Text="WRONG STREAK"',
        'streakCaption.Text="STREAK"',
        'local wrapFilters=layout.narrow and not layout.landscape and #subfilters>4',
        'nav.Size=UDim2.fromOffset(layout.nav.width,layout.nav.height)',
        'gui:SetAttribute("RobloxPlaceVersion",game.PlaceVersion)',
        '"GRADE 2  •  ABVM  •  v"..tostring(game.PlaceVersion)',
        'local bonusChip=UI.frame(goalCard',
        'bonusText.Text="★ "..tostring(state.lessonCount or 0).."/5"',
        'IconKind=iconKind',
        'UI.tintIcon(iconBox,UI.P.white)',
        '{"school","School","school"',
        '{"home","Home","home"',
        '{"shop","Shop","shop"',
        '{"vehicle","Ride","vehicle"',
    )), "gold-standard player-facing screen contract regressed")
    require('{"Left","left"}' not in main and '{"Right","right"}' not in main,
            "debug steering toolbar returned; native thumbstick steering is required")
    require('{"▦","School"' not in main and '{"⌂","Home"' not in main and
            '{"▣","Shop"' not in main and '{"◆","Ride"' not in main,
            "abstract primary-nav glyphs returned; native vector icon family is required")
    require(all(marker in leaderboards_source for marker in (
        "silver=Color3.fromRGB", "bronze=Color3.fromRGB",
        'make("UIStroke",root,{Color=palette.gold',
        "medalColor=rank==1 and palette.gold",
        'Text="★"',
    )), "gold-standard leaderboard framing/medal hierarchy regressed")
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
        "frontArchedBays": 3,
        "frontUpperWindowBays": 4,
        "doorBays": 2,
        "frontBrandedSign": True,
        "frontEntranceStrip": True,
        "archedSignCrown": True,
        "verticalFacadeBanner": True,
        "heavyEastCornerPier": True,
        "warmWindowDepth": True,
        "segmentedNativeArchGlazing": True,
        "nativeSkyPolish": True,
        "heroArrivalComposition": True,
        "rightBiasedEntranceComposition": True,
        "overscaleForegroundSchoolSign": True,
        "ornamentedGoldStandardSign": True,
        "terracedEntrancePlanters": True,
        "continuousEastSidewalk": True,
        "eastHeroStreetCorridor": True,
        "recessedParkingLot": True,
        "frontSidewalkAndCurb": True,
        "heroStreetFurniture": True,
        "narrowFirstUpperWindowBay": True,
        "broadenedCeremonialStair": True,
        "twoStageCeremonialStair": True,
        "trueFrontArchOpenings": True,
        "layeredFacadeCornice": True,
        "steppedParapetSilhouette": True,
        "wrappedSideParapets": True,
        "distantPottsvilleSkyline": True,
        "chunkyRobloxTreeCanopy": True,
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
        require("NEIGHBORHOOD_CORE_TESTS_PASS 29" in test_output, "complete model-test marker missing")
        place_path = args.out / "PipHigh-Neighborhood-preview.rbxlx"
        run([str(args.rojo.resolve()), "build", str(PROJECT), "-o", str(place_path)],
            args.out / "rojo-build.log")
        place = ET.parse(place_path).getroot()
        script_inventory = inspect_place(place)
        mutations = check_guard_mutations(project, place)
        files = [PROJECT, *[MODE / path for path in sorted(SOURCES)],
                 MODE / "tests/core.spec.lua", Path(__file__).resolve()]
        report.update(status="PASS_STATIC_PREVIEW_ONLY", sourceFilesCompiled=len(SOURCES),
                      coreTests=29, buildGuardNegativeControls=mutations,
                      abvmStaticContract=abvm_contract,
                      scriptInventory=script_inventory,
                      fileSha256={str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                                  for p in files},
                      placeSha256=hashlib.sha256(place_path.read_bytes()).hexdigest())
        print("NEIGHBORHOOD_STATIC_PREVIEW_OK: 29 model tests; 12 compiled sources; 3 negative controls")
    except (ValueError, OSError, subprocess.SubprocessError, ET.ParseError) as exc:
        report["error"] = str(exc)
        print(f"NEIGHBORHOOD_STATIC_PREVIEW_FAIL: {exc}", file=sys.stderr)
    (args.out / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return 0 if report["status"] == "PASS_STATIC_PREVIEW_ONLY" else 1


if __name__ == "__main__":
    raise SystemExit(main())
