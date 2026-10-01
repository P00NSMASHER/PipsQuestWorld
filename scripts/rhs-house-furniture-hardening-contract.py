#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path

TARGET = "ServerScriptService/CustomHouseScript_NEW"
EXPECTED_SOURCE_SHA256 = "66f73eeb7972411c905289b02cc9052f004251d277870323dfe46cb4f946d016"

REQUIRED = [
    'home == workspace:FindFirstChild("!home_"..plr.Name)',
    'home == workspace:FindFirstChild("apartment_"..plr.Name)',
    'if type(targetname) ~= "string" then',
    'typeof(model) == "Instance" and model:IsA("Model") and model.Parent == house and string.sub(model.Name,1,6) == "furni_"',
    'if type(objname) ~= "string" or string.sub(objname,1,6) ~= "furni_" then',
    'typeof(item) == "Instance" and item.Parent == house and typeof(color) == "BrickColor"',
    'local ismodel = typeof(selectedmodel) == "Instance" and selectedmodel:IsA("Model")',
    'and editing.Value == true',
    'and selectedmodel.Parent == house',
    'and string.sub(selectedmodel.Name,1,6) == "furni_"',
    'and typeof(newcframe) == "CFrame"',
    'and type(newrotval) == "number"',
    'findpart.Parent ~= house',
    'local currenthouse = workspace:FindFirstChild("!home_"..plr.Name)',
    'local placementmarker = currenthouse and currenthouse:FindFirstChild("HousePlacement")',
    'local request = loadHouse(plr,placementmarker.Value)',
]

FORBIDDEN = [
    'home.Name:match(plr.Name)',
    'local request = loadHouse(plr,placement)',
    'if item.Parent.Name == "!home_"..plr.Name then',
    'if selectedmodel then\n\t\tlocal pp = selectedmodel.PrimaryPart',
]

HANDLERS = [
    "ToggleHomeLock",
    "ToggleRestrictLock",
    "ToggleHomeRestrictedPlayer",
    "ReloadHouse",
    "HouseSave",
    "GetFurniture",
    "RemoveFurniture",
    "SellFurniture",
    "PaintHouseItem",
    "SendNewFurniturePosition",
    "EnterHouseEditMode",
]

def prop_text(item, name: str) -> str:
    props=item.find("Properties")
    if props is None:
        return ""
    for p in props:
        if p.attrib.get("name") != name:
            continue
        if p.tag == "Content":
            child=next(iter(p),None)
            return (child.text or "") if child is not None else ""
        return p.text or ""
    return ""

def item_name(item) -> str:
    return prop_text(item, "Name") or "(unnamed)"

def walk(parent, prefix=""):
    for item in parent.findall("Item"):
        name=item_name(item).replace("/", "_")
        path=f"{prefix}/{name}" if prefix else name
        yield item,path
        yield from walk(item,path)

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--manifest",required=True)
    ap.add_argument("--build-state",required=True)
    args=ap.parse_args()

    root=ET.parse(args.xml).getroot()
    source=None
    for item,path in walk(root):
        if path == TARGET:
            source=prop_text(item,"Source")
            break
    if source is None:
        raise SystemExit(f"missing target script: {TARGET}")

    errors=[]
    source_sha=hashlib.sha256(source.encode("utf-8")).hexdigest()
    if source_sha != EXPECTED_SOURCE_SHA256:
        errors.append(f"target source SHA changed: {source_sha}")

    for token in REQUIRED:
        if token not in source:
            errors.append(f"required hardening token missing: {token!r}")

    for token in FORBIDDEN:
        if token in source:
            errors.append(f"forbidden legacy trust pattern remains: {token!r}")

    for handler in HANDLERS:
        needle=f"RemoteFunctions.{handler}."
        if source.count(needle) != 1:
            errors.append(f"handler count changed for {handler}: {source.count(needle)}")

    if source.count('if type(objname) ~= "string" or string.sub(objname,1,6) ~= "furni_" then') != 2:
        errors.append("GetFurniture/SellFurniture furniture-name guards are not both present")

    if source.count('home == workspace:FindFirstChild("!home_"..plr.Name)') != 3:
        errors.append("exact custom-house ownership guard count is not 3")
    if source.count('home == workspace:FindFirstChild("apartment_"..plr.Name)') != 3:
        errors.append("exact apartment ownership guard count is not 3")

    manifest=json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    patch=[p for p in manifest.get("patches",[]) if p.get("id")=="harden-house-furniture-remotes"]
    if len(patch) != 1:
        errors.append(f"expected exactly one house/furniture patch, found {len(patch)}")
    else:
        p=patch[0]
        if p.get("targetPath") != TARGET:
            errors.append("house/furniture patch target changed")
        if p.get("expectedSourceSha256") != "5c9e905672a3644ce70d14394202b63283fe9de23e907c336fd8d5275d59227c":
            errors.append("house/furniture baseline source hash changed")
        if len(p.get("replacements") or []) != 8:
            errors.append(f"expected 8 deterministic replacements, found {len(p.get('replacements') or [])}")

    state=json.loads(Path(args.build_state).read_text(encoding="utf-8"))
    repairs=state.get("compatibilityRepairs") or []
    if repairs != [p.get("id") for p in manifest.get("patches",[])]:
        errors.append("BUILD_STATE compatibilityRepairs do not exactly match manifest patch IDs")
    if state.get("runtimeVerified") is not False:
        errors.append("runtimeVerified must remain false")
    if state.get("published") is not False:
        errors.append("published must remain false")

    if errors:
        print("RHS_HOUSE_FURNITURE_HARDENING_CONTRACT_FAILED")
        for err in errors:
            print("-",err)
        return 1

    print("RHS_HOUSE_FURNITURE_HARDENING_CONTRACT_OK")
    print("TARGET_SOURCE_SHA256",source_sha)
    print("HOUSE_HANDLER_COUNT",len(HANDLERS))
    print("DETERMINISTIC_REPLACEMENTS",8)
    print("WORKING_SHA256",state["expectedWorkingSha256"])
    print("RUNTIME_VERIFIED",str(state["runtimeVerified"]).lower())
    print("PUBLISHED",str(state["published"]).lower())
    return 0

if __name__=="__main__":
    raise SystemExit(main())
