#!/usr/bin/env python3
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parents[1]
school = root / "school"
project = school / "default.project.json"
config = school / "src/shared/SchoolConfig.lua"
campus = school / "src/server/CampusBuilder.server.lua"
runtime = school / "src/server/FoundationBootstrap.server.lua"

for path in (project, config, campus, runtime):
    if not path.exists():
        raise SystemExit(f"missing foundation file: {path.relative_to(root)}")

project_text = project.read_text()
project_json = json.loads(project_text)
if project_json.get("name") != "PipHigh":
    raise SystemExit("unexpected project name")

for path in (
    "src/shared/SchoolConfig.lua",
    "src/server/CampusBuilder.server.lua",
    "src/server/FoundationBootstrap.server.lua",
):
    if path not in project_text:
        raise SystemExit(f"project does not map {path}")

for old_path in ("src/client", "SchoolLoop.server.lua", "QuestionBank.lua", "../game"):
    if old_path in project_text:
        raise SystemExit(f"project maps non-foundation path: {old_path}")

config_text = config.read_text()
campus_text = campus.read_text()
runtime_text = runtime.read_text()

period_rooms = re.findall(r'room\s*=\s*"([^"]+)"', config_text)
room_defs = set(re.findall(r'^\s{4}([A-Za-z0-9_]+)\s*=\s*\{\s*position\s*=', config_text, flags=re.MULTILINE))
if not period_rooms:
    raise SystemExit("no schedule periods found")
if set(period_rooms) - room_defs:
    raise SystemExit("schedule references a room with no configured location")

for token in ('Instance.new("SpawnLocation")', 'spawn.Name = "MainSpawn"', 'roomSpawns.Name = "RoomSpawns"'):
    if token not in campus_text:
        raise SystemExit(f"missing campus seam: {token}")

for token in (
    "Players.PlayerAdded:Connect(setupPlayer)",
    "Players.PlayerRemoving:Connect(removePlayer)",
    "player.RespawnLocation = spawn",
    "SchoolConfig.PERIOD_SECONDS",
    'Workspace:SetAttribute("SchoolDay"',
    'Workspace:SetAttribute("SchoolPeriodIndex"',
):
    if token not in runtime_text:
        raise SystemExit(f"missing runtime seam: {token}")

active = "\n".join((config_text, campus_text, runtime_text)).lower()
for term in ("questionbank", "leaderstats", "rbxassetid://", "currentcamera", "walkspeed", "jumppower"):
    if term in active:
        raise SystemExit(f"out-of-scope foundation term found: {term}")

print("PIP_HIGH_FOUNDATION_GUARDS_OK")
