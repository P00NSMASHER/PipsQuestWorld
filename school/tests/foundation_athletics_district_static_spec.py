#!/usr/bin/env python3
from pathlib import Path
import json

root = Path(__file__).resolve().parents[2]
project_path = root / "school/default.project.json"
config_path = root / "school/src/shared/SchoolConfig.lua"
district_path = root / "school/src/server/AthleticsDistrict.server.lua"

for path in (project_path, config_path, district_path):
    if not path.exists():
        raise SystemExit(f"missing athletics foundation file: {path.relative_to(root)}")

project = json.loads(project_path.read_text())
config = config_path.read_text()
district = district_path.read_text()

foundation = project["tree"]["ServerScriptService"]["SchoolFoundation"]
mapping = foundation.get("AthleticsDistrict")
if mapping != {"$path": "src/server/AthleticsDistrict.server.lua"}:
    raise SystemExit("AthleticsDistrict must map exactly once under SchoolFoundation")

required_locations = {
    "AthleticsEntrance": "Athletics Entrance",
    "FootballField": "Football Field",
    "SoccerField": "Soccer Field",
    "OutdoorPool": "Outdoor Pool",
}
for key, label in required_locations.items():
    if f"{key} = {{ position = Vector3.new(" not in config:
        raise SystemExit(f"missing canonical world location: {key}")
    if f'displayName = "{label}"' not in config:
        raise SystemExit(f"missing canonical world label: {label}")
    if f'loc("{key}")' not in district:
        raise SystemExit(f"athletics district does not consume location registry entry: {key}")

for token in (
    'campus:WaitForChild("Geometry")',
    'district.Name = "AthleticsDistrict"',
    '"AthleticsWalk"',
    '"AthleticsDrive"',
    '"FootballTurf"',
    '"SoccerTurf"',
    '"PoolDeck"',
    '"PoolWater"',
    '"AthleticsLightPole"',
):
    if token not in district:
        raise SystemExit(f"missing athletics world behavior: {token}")

for forbidden in (
    "DataStoreService",
    "RemoteEvent",
    "RemoteFunction",
    "leaderstats",
    "PERIOD_SECONDS",
    "periodChanged",
    "correctIndex",
    "EconomyRepository",
    "ProgressionRepository",
    "VehicleSeat",
):
    if forbidden in district:
        raise SystemExit(f"athletics district crosses Foundation ownership: {forbidden}")

print("PIP_HIGH_ATHLETICS_DISTRICT_STATIC_OK")
