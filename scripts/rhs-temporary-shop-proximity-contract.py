#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path

TARGET = "ServerScriptService/ItemBuyScript"
BASELINE_SOURCE_SHA = "c92d824aea342350a940a14c74d151accca9bb0058932fc7df55b9b8557fbddf"
EXPECTED_SOURCE_SHA = "402c6ea746d485c4b27cd251757448accb287383270269358207e48a37f959ee"
EXPECTED_WORKING_SHA = "2246eb8e92906e68322f76a26f69821e456e206e466dc1e15358bb3b5bfd4b59"
PATCH_ID = "harden-economy-purchase-remotes"
MAX_DISTANCE = 32

SHOP_ANCHORS = {
    "Chef Umbra's": ["DIALOG_Umbra"],
    "Club Red": ["DIALOG_Dexter"],
    "School Cafeteria": [
        "DIALOG_Rude Lunch Lady",
        "DIALOG_Chill Lunch Lady",
        "DIALOG_Noob Lunch Lady",
    ],
    "Snack Shack": ["DIALOG_Wendy"],
    "Sunblox Cafe": ["DIALOG_Alyssa"],
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

def walk(parent, prefix: str = ""):
    for item in parent.findall("Item"):
        name = item_name(item).replace("/", "_")
        path = f"{prefix}/{name}" if prefix else name
        yield item, path
        yield from walk(item, path)

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--xml", required=True)
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--build-state", required=True)
    args = ap.parse_args()

    root = ET.parse(args.xml).getroot()
    source = None
    classes_by_path = {}

    for item, path in walk(root):
        classes_by_path.setdefault(path, []).append(item.attrib.get("class", ""))
        if path == TARGET:
            source = prop_text(item, "Source")

    errors = []
    if source is None:
        errors.append("missing ItemBuyScript")
        source = ""

    source_sha = hashlib.sha256(source.encode("utf-8")).hexdigest()
    if source_sha != EXPECTED_SOURCE_SHA:
        errors.append(f"patched source SHA changed: {source_sha}")

    required_tokens = [
        "local temporaryShopDialogAnchors = {",
        '["Chef Umbra\'s"] = {"DIALOG_Umbra"}',
        '["Club Red"] = {"DIALOG_Dexter"}',
        '["School Cafeteria"] = {"DIALOG_Rude Lunch Lady","DIALOG_Chill Lunch Lady","DIALOG_Noob Lunch Lady"}',
        '["Snack Shack"] = {"DIALOG_Wendy"}',
        '["Sunblox Cafe"] = {"DIALOG_Alyssa"}',
        "local function canAccessTemporaryShop(plr,shopname)",
        '(root.Position - anchor.Position).Magnitude <= 32',
        'if not canAccessTemporaryShop(plr,shopname) then',
        'return false,"Please move closer to the shopkeeper."',
        'if type(code) ~= "string" or #code > 64 then',
    ]
    for token in required_tokens:
        if token not in source:
            errors.append(f"required shop-proximity token missing: {token!r}")

    if source.count("PurchaseTemporaryItem.OnServerInvoke") != 1:
        errors.append("PurchaseTemporaryItem handler count changed")
    if source.count("RedeemTwitterCode.OnServerInvoke") != 1:
        errors.append("RedeemTwitterCode handler count changed")

    for shop, anchors in SHOP_ANCHORS.items():
        if not anchors:
            errors.append(f"shop has no anchors: {shop}")
        for anchor in anchors:
            path = "Workspace/" + anchor
            classes = classes_by_path.get(path, [])
            if len(classes) != 1:
                errors.append(f"expected exactly one serialized anchor {path}, found {len(classes)}")
            elif classes[0] not in {"Part", "MeshPart", "UnionOperation"}:
                errors.append(f"shop anchor is not a BasePart-like serialized class: {path} ({classes[0]})")

    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    patches = [p for p in manifest.get("patches", []) if p.get("id") == PATCH_ID]
    if len(patches) != 1:
        errors.append(f"expected exactly one economy patch, found {len(patches)}")
    else:
        patch = patches[0]
        if patch.get("targetPath") != TARGET:
            errors.append("economy patch target changed")
        if patch.get("expectedSourceSha256") != BASELINE_SOURCE_SHA:
            errors.append("economy patch baseline source SHA changed")
        if len(patch.get("replacements") or []) != 8:
            errors.append(f"expected 8 economy replacements, found {len(patch.get('replacements') or [])}")

    state = json.loads(Path(args.build_state).read_text(encoding="utf-8"))
    repair_ids = [p.get("id") for p in manifest.get("patches", [])]
    if state.get("compatibilityRepairs") != repair_ids:
        errors.append("BUILD_STATE repairs do not exactly match manifest patch IDs")
    if state.get("expectedWorkingSha256") != EXPECTED_WORKING_SHA:
        errors.append("working SHA is not the reviewed temporary-shop candidate")
    if state.get("runtimeVerified") is not False:
        errors.append("runtimeVerified must remain false")
    if state.get("published") is not False:
        errors.append("published must remain false")

    if errors:
        print("RHS_TEMPORARY_SHOP_PROXIMITY_CONTRACT_FAILED")
        for error in errors:
            print("-", error)
        return 1

    print("RHS_TEMPORARY_SHOP_PROXIMITY_CONTRACT_OK")
    print("TARGET_SOURCE_SHA256", source_sha)
    print("WORKING_SHA256", state["expectedWorkingSha256"])
    print("SHOP_COUNT", len(SHOP_ANCHORS))
    print("ANCHOR_COUNT", sum(len(v) for v in SHOP_ANCHORS.values()))
    print("MAX_DISTANCE", MAX_DISTANCE)
    print("RUNTIME_VERIFIED", str(state["runtimeVerified"]).lower())
    print("PUBLISHED", str(state["published"]).lower())
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
