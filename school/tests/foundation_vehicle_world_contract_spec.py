#!/usr/bin/env python3
from pathlib import Path
import math
import re

root = Path(__file__).resolve().parents[2]
config_path = root / "school/src/shared/SchoolConfig.lua"
campus_path = root / "school/src/server/CampusBuilder.server.lua"

config = config_path.read_text()
campus = campus_path.read_text()

for token in (
    'SchoolConfig.VehicleWorld = {',
    'spawnLocation = "AutoShopVehicleSpawn"',
    'roadEntryLocation = "AutoShopRoadEntry"',
    'AutoShopVehicleSpawn = { position = Vector3.new(',
    'AutoShopRoadEntry = { position = Vector3.new(',
):
    if token not in config:
        raise SystemExit(f"missing vehicle world contract token: {token}")

def position(name):
    pattern = rf'{name}\s*=\s*\{{\s*position\s*=\s*Vector3\.new\(([-\d.]+),\s*([-\d.]+),\s*([-\d.]+)\)'
    match = re.search(pattern, config)
    if not match:
        raise SystemExit(f"cannot parse location: {name}")
    return tuple(float(value) for value in match.groups())

auto_shop = position("AutoShop")
spawn = position("AutoShopVehicleSpawn")
road_entry = position("AutoShopRoadEntry")
market = position("Market")

if spawn != (120.0, 3.0, 350.0):
    raise SystemExit(f"unexpected vehicle spawn contract: {spawn}")
if road_entry != (120.0, 3.0, 390.0):
    raise SystemExit(f"unexpected road entry contract: {road_entry}")

# AutoShop is 66x48 and Market is 64x46 in CampusBuilder. The spawn bay must remain
# in the clear gap between those storefront footprints instead of inside either shop.
auto_east = auto_shop[0] + 33
market_west = market[0] - 32
if not (auto_east + 4 < spawn[0] < market_west - 4):
    raise SystemExit("vehicle spawn is not in the clear AutoShop/Market gap")

# Town Main Street is centered on z=390 with depth 38, so the handoff point must
# remain directly on that road while the spawn itself stays off-road.
if abs(road_entry[2] - 390) > 19:
    raise SystemExit("vehicle road entry is outside Town Main Street")
if abs(spawn[2] - 390) <= 19:
    raise SystemExit("vehicle spawn must remain off the active road surface")
if spawn[0] != road_entry[0]:
    raise SystemExit("spawn and road entry should align for a straight road handoff")
if math.dist((spawn[0], spawn[2]), (road_entry[0], road_entry[2])) > 45:
    raise SystemExit("vehicle spawn is too far from its road entry")

for token in (
    'local vehicleWorld = SchoolConfig.VehicleWorld',
    'SchoolConfig.WorldLocations[vehicleWorld.spawnLocation].position',
    'SchoolConfig.WorldLocations[vehicleWorld.roadEntryLocation].position',
    '"AutoShopVehicleSpawnPad"',
    '"AutoShopVehicleSpawnMark"',
):
    if token not in campus:
        raise SystemExit(f"CampusBuilder does not consume vehicle world contract: {token}")

for forbidden in (
    "VehicleSeat",
    "spawnVehicle",
    "despawnVehicle",
    "Players.PlayerAdded",
    "DataStoreService",
):
    if forbidden in campus:
        raise SystemExit(f"Foundation crossed into vehicle/runtime authority: {forbidden}")

print("PIP_HIGH_VEHICLE_WORLD_CONTRACT_OK")
