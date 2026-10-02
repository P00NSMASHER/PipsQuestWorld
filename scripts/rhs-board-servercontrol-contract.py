#!/usr/bin/env python3
from __future__ import annotations

import argparse, hashlib, json, xml.etree.ElementTree as ET
from pathlib import Path

TARGETS = {
    "ServerScriptService/RemoveHats/NewHoverboard/SkateboardPlatform/ServerScript":
        "c700bd7ae5b11820f7790e7fb19a2c783c869e7d4aecca7a26716fbb0ac9d315",
    "ServerScriptService/RemoveHats/NewPinkHoverboard/SkateboardPlatform/ServerScript":
        "b77ac4bbf12ad9944cc7337035394a2d6cf6efbac59eae57ffab468abf922314",
}
PATCH_IDS = {
    "harden-new-hoverboard-servercontrol",
    "harden-new-pink-hoverboard-servercontrol",
}

REQUIRED = [
    'if typeof(Value) ~= "Instance" or not Value:IsA("Model") or Players:GetPlayerFromCharacter(Value) ~= player then',
    'if player ~= Player then',
    'if player ~= Player or type(Value) ~= "table" or typeof(Value.Key) ~= "EnumItem" or Value.Key.EnumType ~= Enum.KeyCode or type(Value.Down) ~= "boolean" then',
    'Equipped(Value)',
    'Unequipped()',
    'SkateboardFunctions.KeyPress(Key, Down)',
]
FORBIDDEN = [
'''ServerControl.OnServerInvoke = (function(player, Mode, Value)
	if Mode == "Equipped" then
		Equipped(Value)
	elseif Mode == "Unequipped" then
		Unequipped()
	elseif Mode == "KeyPress" then
		local Key = Value.Key''',
]

def prop_text(item,name):
    props=item.find("Properties")
    if props is None: return ""
    for p in props:
        if p.attrib.get("name") != name: continue
        if p.tag=="Content":
            child=next(iter(p),None)
            return (child.text or "") if child is not None else ""
        return p.text or ""
    return ""

def item_name(item):
    return prop_text(item,"Name") or "(unnamed)"

def walk(parent,prefix=""):
    for item in parent.findall("Item"):
        nm=item_name(item).replace("/","_")
        path=f"{prefix}/{nm}" if prefix else nm
        yield item,path
        yield from walk(item,path)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--manifest",required=True)
    ap.add_argument("--build-state",required=True)
    args=ap.parse_args()

    found={}
    for item,path in walk(ET.parse(args.xml).getroot()):
        if path in TARGETS:
            found[path]=prop_text(item,"Source")

    errors=[]
    for path,expected_sha in TARGETS.items():
        source=found.get(path)
        if source is None:
            errors.append("missing target: "+path)
            continue
        actual=hashlib.sha256(source.encode("utf-8")).hexdigest()
        if actual != expected_sha:
            errors.append(f"{path}: source SHA changed: {actual}")
        for token in REQUIRED:
            if token not in source:
                errors.append(f"{path}: missing guard token {token!r}")
        for token in FORBIDDEN:
            if token in source:
                errors.append(f"{path}: legacy unguarded handler remains")
        if source.count("ServerControl.OnServerInvoke") != 1:
            errors.append(f"{path}: ServerControl handler count changed")

    manifest=json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    by_id={p.get("id"):p for p in manifest.get("patches",[])}
    for pid in PATCH_IDS:
        p=by_id.get(pid)
        if not p:
            errors.append("missing manifest patch: "+pid)
        elif len(p.get("replacements") or []) != 1:
            errors.append(pid+": expected exactly one deterministic replacement")

    state=json.loads(Path(args.build_state).read_text(encoding="utf-8"))
    if not state.get("expectedWorkingSha256"):
        errors.append("BUILD_STATE is missing expectedWorkingSha256")
    if not PATCH_IDS.issubset(set(state.get("compatibilityRepairs") or [])):
        errors.append("BUILD_STATE missing board hardening patch IDs")
    if state.get("runtimeVerified") is not False:
        errors.append("runtimeVerified must remain false")
    if state.get("published") is not False:
        errors.append("published must remain false")

    if errors:
        print("RHS_BOARD_SERVERCONTROL_CONTRACT_FAILED")
        for e in errors: print("-",e)
        return 1

    print("RHS_BOARD_SERVERCONTROL_CONTRACT_OK")
    print("TARGETS",len(TARGETS))
    print("WORKING_SHA256",state["expectedWorkingSha256"])
    print("RUNTIME_VERIFIED",str(state["runtimeVerified"]).lower())
    print("PUBLISHED",str(state["published"]).lower())
    return 0

if __name__=="__main__":
    raise SystemExit(main())
