#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import xml.etree.ElementTree as ET
from pathlib import Path

TARGETS = {
    "ServerScriptService/ApartmentPurchaseScript": "Script",
    "ServerScriptService/OutfitHandler": "Script",
}

def prop_text(item, name: str) -> str:
    props = item.find("Properties")
    if props is None:
        return ""
    for prop in props:
        if prop.attrib.get("name") != name:
            continue
        if prop.tag == "Content":
            child = next(iter(prop), None)
            return (child.text or "") if child is not None else ""
        return prop.text or ""
    return ""

def item_name(item) -> str:
    return prop_text(item, "Name") or "(unnamed)"

def walk(parent, prefix=""):
    for item in parent.findall("Item"):
        name = item_name(item).replace("/", "_")
        path = f"{prefix}/{name}" if prefix else name
        yield item, path
        yield from walk(item, path)

def require(source: str, token: str, label: str, failures: list[str]) -> None:
    if token not in source:
        failures.append(f"{label}: missing {token!r}")

def forbid(source: str, token: str, label: str, failures: list[str]) -> None:
    if token in source:
        failures.append(f"{label}: forbidden legacy token remains: {token!r}")

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml", required=True)
    ap.add_argument("--output", required=True)
    args=ap.parse_args()

    found={}
    for item,path in walk(ET.parse(args.xml).getroot()):
        if path in TARGETS:
            found[path]=prop_text(item,"Source")

    failures=[]
    for path in TARGETS:
        if path not in found:
            failures.append(f"missing target script: {path}")

    apartment=found.get("ServerScriptService/ApartmentPurchaseScript","")
    outfit=found.get("ServerScriptService/OutfitHandler","")

    apartment_required=[
        'apartment:IsA("Model")',
        "apartment.Parent == game.Workspace",
        'apartment.Name == "Apartment"',
        'apartment:FindFirstChild("BuyDoor")',
        'buyDoor:IsA("BasePart")',
        'apartment:FindFirstChild("Lock Button")',
        'apartment["Lock Button"]:FindFirstChild("LockButton")',
        'character:FindFirstChild("HumanoidRootPart")',
        'character:FindFirstChild("Torso")',
        "(root.Position - buyDoor.Position).Magnitude <= 30",
    ]
    for token in apartment_required:
        require(apartment,token,"ApartmentPurchaseScript",failures)
    forbid(
        apartment,
        'if apartment and apartment.Name == "Apartment" and not game.Workspace:FindFirstChild',
        "ApartmentPurchaseScript",
        failures,
    )

    outfit_required=[
        "if count > 0 then return false end",
        "local allowedOutfitInputs = {",
        "OutfitName = true",
        "Hat1 = true",
        "Hat2 = true",
        "Hat3 = true",
        "Shirt = true",
        "Pants = true",
        "Face = true",
        "Package = true",
        "RPName = true",
        "RPDesc = true",
        "RemoveShirt = true",
        'if type(inputs) ~= "table" then',
        "if allowedOutfitInputs[key] ~= true then",
        'type(value) ~= "boolean"',
        "local slotNumber = tonumber(slot)",
        "slotNumber < 1 or slotNumber > 24",
        "local loaded = pcall(function()",
        'obj = game:GetService("InsertService"):LoadAsset(v)',
        "if not loaded or not obj then",
        'statuses[i] = "invalid"',
        "return false,statuses",
    ]
    for token in outfit_required:
        require(outfit,token,"OutfitHandler",failures)
    forbid(outfit,"if count > 1 then return false end","OutfitHandler",failures)

    whitelist=[
        "OutfitName","Hat1","Hat2","Hat3","Shirt","Pants","Face",
        "Package","RPName","RPDesc","RemoveShirt",
    ]

    state=json.loads(
        (Path(__file__).resolve().parents[1]/"rhs/working/BUILD_STATE.json").read_text(encoding="utf-8")
    )
    report={
        "schemaVersion":1,
        "candidateSha256":state["expectedWorkingSha256"],
        "compatibilityRepairs":state.get("compatibilityRepairs") or [],
        "apartmentPurchase":{
            "workspaceModelRequired":'apartment.Parent == game.Workspace' in apartment,
            "buyDoorRequired":'apartment:FindFirstChild("BuyDoor")' in apartment,
            "playerRootRequired":'character:FindFirstChild("HumanoidRootPart")' in apartment,
            "maxDistanceStuds":30,
        },
        "outfitRemote":{
            "oneInflightPerPlayer":"if count > 0 then return false end" in outfit,
            "whitelist":whitelist,
            "rejectsNonTableInputs":'if type(inputs) ~= "table" then' in outfit,
            "saveSlotBounds":[1,24],
            "hatLoadFailClosed":"if not loaded or not obj then" in outfit,
        },
        "failures":failures,
        "status":"PASS" if not failures else "FAIL",
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_CORE_REMOTE_HARDENING_CONTRACT ===")
    print("STATUS",report["status"])
    print("CANDIDATE_SHA256",report["candidateSha256"])
    print("COMPATIBILITY_REPAIRS",len(report["compatibilityRepairs"]))
    print("OUTFIT_WHITELIST",",".join(whitelist))
    for failure in failures:
        print("FAIL",failure)
    print("=== END_RHS_CORE_REMOTE_HARDENING_CONTRACT ===")
    if failures:
        raise SystemExit(1)
    return 0

if __name__=="__main__":
    raise SystemExit(main())
