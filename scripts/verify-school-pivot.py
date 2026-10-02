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
class_education = school / "src/server/ClassEducation.server.lua"

for path in (project, config, campus, runtime, class_education):
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

def collect_mapped_paths(node):
    if isinstance(node, dict):
        if isinstance(node.get("$path"), str):
            yield node["$path"]
        for value in node.values():
            yield from collect_mapped_paths(value)
    elif isinstance(node, list):
        for value in node:
            yield from collect_mapped_paths(value)

mapped_paths = set(collect_mapped_paths(project_json))

for old_path in ("src/client/SchoolHud.client.lua", "SchoolLoop.server.lua", "QuestionBank.lua", "../game"):
    if any(old_path in path for path in mapped_paths):
        raise SystemExit(f"project maps retired runtime path: {old_path}")

allowed_client_paths = {"src/client/CanonicalSchoolClient.client.lua"}
client_paths = {path for path in mapped_paths if path.startswith("src/client/")}
unexpected_client_paths = client_paths - allowed_client_paths
if unexpected_client_paths:
    raise SystemExit(
        "project maps unapproved client path(s): "
        + ", ".join(sorted(unexpected_client_paths))
    )

if "src/client/CanonicalSchoolClient.client.lua" in client_paths:
    canonical_client = school / "src/client/CanonicalSchoolClient.client.lua"
    if not canonical_client.exists():
        raise SystemExit("canonical client mapping has no source file")
    client_text = canonical_client.read_text()
    for forbidden in (
        "correctIndex",
        "correctChoiceId",
        "QuestionBank",
        "DataStoreService",
        "UpdateAsync",
        "SetAsync",
    ):
        if forbidden in client_text:
            raise SystemExit(f"canonical client owns forbidden authority: {forbidden}")
    for required in (
        'WaitForChild("StateSnapshot")',
        'WaitForChild("RequestTravel")',
        'WaitForChild("GetClassState")',
        'WaitForChild("GetProgressionState")',
        'WaitForChild("EnterClass")',
        'WaitForChild("SubmitAnswer")',
        'WaitForChild("LeaveClass")',
        "InvokeServer",
        "getProgressionState:InvokeServer()",
        'result.code == "progression_commit_failed"',
        "submissionId = pendingProgression.submissionId",
        "setPoints(result.progressionState.totalPoints)",
    ):
        if required not in client_text:
            raise SystemExit(f"canonical client missing server-authoritative seam: {required}")

config_text = config.read_text()
campus_text = campus.read_text()
runtime_text = runtime.read_text()
class_education_text = class_education.read_text()

for required in (
    'getOrCreateRemoteFunction(classRemoteFolder, "GetProgressionState")',
    "getProgressionState.OnServerInvoke",
    "ProgressionRepository.open(progressionStore, player.UserId)",
    "state = repository:getState()",
):
    if required not in class_education_text:
        raise SystemExit(f"class/progression read seam missing: {required}")

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
    'Workspace:WaitForChild("SchoolCampus")',
    'campus:WaitForChild("MainSpawn")',
    'assert(spawn:IsA("SpawnLocation")',
    "player.RespawnLocation = getMainSpawn()",
    "SchoolConfig.PERIOD_SECONDS",
    'Workspace:SetAttribute("SchoolDay"',
    'Workspace:SetAttribute("SchoolPeriodIndex"',
    "SchoolConfig.Interfaces.remoteFolder",
    "SchoolConfig.Interfaces.stateSnapshot",
    "SchoolConfig.Interfaces.requestTravel",
    "requestTravel.OnServerInvoke",
    'campus:WaitForChild("RoomSpawns")',
    "character:PivotTo(roomSpawn.CFrame + SchoolConfig.TRAVEL_OFFSET)",
    "SchoolConfig.Interfaces.serverEventFolder",
    "SchoolConfig.Interfaces.sessionStarted",
    "SchoolConfig.Interfaces.sessionEnded",
    "SchoolConfig.Interfaces.periodChanged",
    'Instance.new("RemoteFunction")',
    'Instance.new("BindableEvent")',
    "stateSnapshot.OnServerInvoke",
    "sessionStarted:Fire(player",
    "sessionEnded:Fire(player",
    "periodChanged:Fire({",
    "while now - periodStartedAt >= SchoolConfig.PERIOD_SECONDS do",
    "periodStartedAt += SchoolConfig.PERIOD_SECONDS",
    "publishState(os.clock())",
):
    if token not in runtime_text:
        raise SystemExit(f"missing runtime seam: {token}")

if runtime_text.count("periodChanged:Fire({") != 1:
    raise SystemExit("period lifecycle hook must have exactly one authoritative emission site")

for racing_lookup in (
    'Workspace:FindFirstChild("SchoolCampus")',
    'campus and campus:FindFirstChild("MainSpawn")',
):
    if racing_lookup in runtime_text:
        raise SystemExit("foundation spawn lookup may race CampusBuilder startup")

active = "\n".join((config_text, campus_text, runtime_text)).lower()
for term in ("questionbank", "leaderstats", "rbxassetid://", "currentcamera", "walkspeed", "jumppower"):
    if term in active:
        raise SystemExit(f"out-of-scope foundation term found: {term}")

print("PIP_HIGH_FOUNDATION_GUARDS_OK")
