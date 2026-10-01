#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path

TARGET = "ServerScriptService/ItemBuyScript"
BASELINE_SOURCE_SHA = "c92d824aea342350a940a14c74d151accca9bb0058932fc7df55b9b8557fbddf"
EXPECTED_SOURCE_SHA = "5af08afec4401423c9e4998bc2fe4460cb32c4e61046cb5409e9708ecf41151a"
EXPECTED_WORKING_SHA = "bc0025bc9bfec56a2250be30208d4deb74ec73f5b139b51df72dce790228becf"
PATCH_ID = "harden-economy-purchase-remotes"

REQUIRED = [
    'if type(shopname) ~= "string" or type(itemname) ~= "string" then',
    'processPermanentItemPurchase(plr,price,itemid,item)',
    'processLoyaltyItemPurchase(plr,price,itemid)',
    'function PurchasePermanentItemUnlocked(plr,itemid)',
    'local permanentPurchaseBusy = {}',
    'if permanentPurchaseBusy[plr] then',
    'local ok,result,reason = pcall(PurchasePermanentItemUnlocked,plr,itemid)',
    'permanentPurchaseBusy[plr] = nil',
    'function PurchaseLoyaltyItemUnlocked(plr,itemid)',
    'local loyaltyPurchaseBusy = {}',
    'if loyaltyPurchaseBusy[plr] then',
    'local ok,result,reason = pcall(PurchaseLoyaltyItemUnlocked,plr,itemid)',
    'loyaltyPurchaseBusy[plr] = nil',
]

FORBIDDEN = [
    'coroutine.resume(coroutine.create(processPermanentItemPurchase), plr,price,itemid,item)',
    'coroutine.resume(coroutine.create(processLoyaltyItemPurchase), plr,price,itemid)',
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
    return prop_text(item,"Name") or "(unnamed)"

def walk(parent,prefix=""):
    for item in parent.findall("Item"):
        nm=item_name(item).replace("/","_")
        path=f"{prefix}/{nm}" if prefix else nm
        yield item,path
        yield from walk(item,path)

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--manifest",required=True)
    ap.add_argument("--build-state",required=True)
    args=ap.parse_args()

    source=None
    for item,path in walk(ET.parse(args.xml).getroot()):
        if path == TARGET:
            source=prop_text(item,"Source")
            break
    if source is None:
        raise SystemExit("missing ItemBuyScript")

    errors=[]
    source_sha=hashlib.sha256(source.encode("utf-8")).hexdigest()
    if source_sha != EXPECTED_SOURCE_SHA:
        errors.append(f"patched source SHA changed: {source_sha}")

    for token in REQUIRED:
        if token not in source:
            errors.append(f"required economy hardening token missing: {token!r}")
    for token in FORBIDDEN:
        if token in source:
            errors.append(f"forbidden async purchase mutation remains: {token!r}")

    if source.count('game.ReplicatedStorage.RemoteFunctions.PurchaseTemporaryItem.OnServerInvoke') != 1:
        errors.append("PurchaseTemporaryItem handler count changed")
    if source.count('game.ReplicatedStorage.RemoteFunctions.PurchasePermanentItem.OnServerInvoke') != 1:
        errors.append("PurchasePermanentItem handler count changed")
    if source.count('game.ReplicatedStorage.RemoteFunctions.PurchaseLoyaltyItem.OnServerInvoke') != 1:
        errors.append("PurchaseLoyaltyItem handler count changed")

    manifest=json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    patches=[p for p in manifest.get("patches",[]) if p.get("id")==PATCH_ID]
    if len(patches) != 1:
        errors.append(f"expected exactly one economy patch, found {len(patches)}")
    else:
        p=patches[0]
        if p.get("targetPath") != TARGET:
            errors.append("economy patch target changed")
        if p.get("expectedSourceSha256") != BASELINE_SOURCE_SHA:
            errors.append("economy baseline source SHA changed")
        if len(p.get("replacements") or []) != 7:
            errors.append(f"expected 7 deterministic economy replacements, found {len(p.get('replacements') or [])}")

    state=json.loads(Path(args.build_state).read_text(encoding="utf-8"))
    repair_ids=[p.get("id") for p in manifest.get("patches",[])]
    if state.get("compatibilityRepairs") != repair_ids:
        errors.append("BUILD_STATE repairs do not exactly match manifest patch IDs")
    if state.get("expectedWorkingSha256") != EXPECTED_WORKING_SHA:
        errors.append("working SHA is not the reviewed economy candidate")
    if state.get("runtimeVerified") is not False:
        errors.append("runtimeVerified must remain false")
    if state.get("published") is not False:
        errors.append("published must remain false")

    if errors:
        print("RHS_ECONOMY_HARDENING_CONTRACT_FAILED")
        for err in errors:
            print("-",err)
        return 1

    print("RHS_ECONOMY_HARDENING_CONTRACT_OK")
    print("TARGET_SOURCE_SHA256",source_sha)
    print("DETERMINISTIC_REPLACEMENTS",7)
    print("WORKING_SHA256",state["expectedWorkingSha256"])
    print("RUNTIME_VERIFIED",str(state["runtimeVerified"]).lower())
    print("PUBLISHED",str(state["published"]).lower())
    return 0

if __name__=="__main__":
    raise SystemExit(main())
