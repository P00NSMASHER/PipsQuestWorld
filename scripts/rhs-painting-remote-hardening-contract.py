#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path

TARGET = "ServerScriptService/ServerPaintingManager"
EXPECTED_SOURCE_SHA256 = "e8025fce0fa0951ba373c72f58bf37bf96e2bd6b71cd7ada1faaf6083dd25a13"

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

def require(source: str, token: str, failures: list[str]) -> None:
    if token not in source:
        failures.append("missing token: " + repr(token))

def require_order(source: str, first: str, second: str, failures: list[str]) -> None:
    a=source.find(first)
    b=source.find(second)
    if a < 0 or b < 0 or a >= b:
        failures.append(f"expected {first!r} before {second!r}")

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--output",required=True)
    args=ap.parse_args()

    source=None
    for item,path in walk(ET.parse(args.xml).getroot()):
        if path==TARGET:
            source=prop_text(item,"Source")
            break

    failures=[]
    if source is None:
        failures.append("missing target script: "+TARGET)
        source=""

    sha=hashlib.sha256(source.encode("utf-8")).hexdigest()
    if sha != EXPECTED_SOURCE_SHA256:
        failures.append(f"source SHA mismatch: {sha} != {EXPECTED_SOURCE_SHA256}")

    required=[
        'local function isKnownCanvas(canvas)',
        'typeof(canvas) ~= "Instance"',
        'knowncanvas == canvas',
        'owner:IsA("ObjectValue")',
        'local function playerIsInArtZone(plr)',
        'PlayerIsInZone:Invoke(plr, "Art") == true',
        'if not playerIsInArtZone(plr) then',
        'if not isKnownCanvas(canvas) or typeof(position) ~= "Vector3" then',
        'if mode ~= "Paint" and mode ~= "Erase" then',
        'if mode == "Paint" and typeof(brickcolor) ~= "BrickColor" then',
        'if type(bool) ~= "boolean" then',
        'if bool == true and not playerIsInArtZone(plr) then',
    ]
    for token in required:
        require(source,token,failures)

    require_order(
        source,
        'if not playerIsInArtZone(plr) then',
        'return module.PlacePaint(plr, canvas, position, mode, brickcolor)',
        failures,
    )
    require_order(
        source,
        'if not isKnownCanvas(canvas) or typeof(position) ~= "Vector3" then',
        'return module.PlacePaint(plr, canvas, position, mode, brickcolor)',
        failures,
    )
    require_order(
        source,
        'if mode ~= "Paint" and mode ~= "Erase" then',
        'return module.PlacePaint(plr, canvas, position, mode, brickcolor)',
        failures,
    )

    state=json.loads(Path("rhs/working/BUILD_STATE.json").read_text(encoding="utf-8"))
    repairs=list(state.get("compatibilityRepairs") or [])
    if "harden-painting-remotes" not in repairs:
        failures.append("BUILD_STATE missing harden-painting-remotes repair")

    report={
        "schemaVersion":1,
        "targetPath":TARGET,
        "sourceSha256":sha,
        "workingBuildSha256":state.get("expectedWorkingSha256"),
        "repairPresent":"harden-painting-remotes" in repairs,
        "requiredGuards":required,
        "failures":failures,
        "status":"PASS" if not failures else "FAIL",
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_PAINTING_REMOTE_HARDENING_CONTRACT ===")
    print("SOURCE_SHA256",sha)
    print("WORKING_SHA256",state.get("expectedWorkingSha256"))
    print("REPAIR_PRESENT",str(report["repairPresent"]).lower())
    print("FAILURES",len(failures))
    for f in failures:
        print("FAIL",f)
    print("STATUS",report["status"])
    print("=== END_RHS_PAINTING_REMOTE_HARDENING_CONTRACT ===")

    if failures:
        raise SystemExit(1)
    return 0

if __name__=="__main__":
    raise SystemExit(main())
