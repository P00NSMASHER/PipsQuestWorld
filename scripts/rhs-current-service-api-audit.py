#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}

GET_SERVICE = re.compile(
    r'(?:local\s+)?([A-Za-z_]\w*)\s*=\s*game\s*:\s*(?:GetService|service)\s*\(\s*["\']([^"\']+)["\']\s*\)(?!\s*[:.])',
    re.I,
)
DIRECT_CALL = re.compile(
    r'game\s*:\s*(?:GetService|service)\s*\(\s*["\']([^"\']+)["\']\s*\)\s*:\s*([A-Za-z_]\w*)\s*\(',
    re.I,
)
ALIAS_CALL_TEMPLATE = r'\b{alias}\s*:\s*([A-Za-z_]\w*)\s*\('
ASSIGN_TEMPLATE = r'\b{alias}\s*\.\s*([A-Za-z_]\w*)\s*='

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

def build_member_index(api: dict):
    classes = {c["Name"]: c for c in api.get("Classes", []) if c.get("Name")}
    memo = {}

    def members_for(class_name: str):
        if class_name in memo:
            return memo[class_name]
        cls = classes.get(class_name)
        if cls is None:
            memo[class_name] = {}
            return memo[class_name]

        members = {}
        parent = cls.get("Superclass")
        if parent and parent != "<<<ROOT>>>":
            members.update(members_for(parent))
        for m in cls.get("Members", []):
            name = m.get("Name")
            if name:
                members[name] = m
        memo[class_name] = members
        return members

    return classes, members_for

def line_no(source: str, offset: int) -> int:
    return source.count("\n", 0, offset) + 1

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml", required=True)
    ap.add_argument("--api-dump", required=True)
    ap.add_argument("--output", required=True)
    args=ap.parse_args()

    api=json.loads(Path(args.api_dump).read_text(encoding="utf-8"))
    classes, members_for = build_member_index(api)

    records=[]
    summary=collections.Counter()

    for item,path in walk(ET.parse(args.xml).getroot()):
        cls=item.attrib.get("class","")
        if cls not in SCRIPT_CLASSES:
            continue
        source=prop_text(item,"Source")
        if not source:
            continue

        aliases={}
        ambiguous=set()
        for m in GET_SERVICE.finditer(source):
            alias, service=m.group(1),m.group(2)
            if alias in aliases and aliases[alias] != service:
                ambiguous.add(alias)
            else:
                aliases[alias]=service
        for alias in list(aliases):
            assignment_rx = re.compile(
                r'(?<![A-Za-z0-9_.])(?:local\s+)?' + re.escape(alias) + r'\s*='
            )
            if len(list(assignment_rx.finditer(source))) != 1:
                ambiguous.add(alias)

        for alias in ambiguous:
            aliases.pop(alias,None)

        uses=[]
        for m in DIRECT_CALL.finditer(source):
            uses.append({
                "service":m.group(1),
                "member":m.group(2),
                "kind":"direct_method_call",
                "line":line_no(source,m.start()),
            })

        for alias,service in aliases.items():
            call_rx=re.compile(ALIAS_CALL_TEMPLATE.format(alias=re.escape(alias)))
            for m in call_rx.finditer(source):
                uses.append({
                    "service":service,
                    "member":m.group(1),
                    "kind":"aliased_method_call",
                    "alias":alias,
                    "line":line_no(source,m.start()),
                })

            assign_rx=re.compile(ASSIGN_TEMPLATE.format(alias=re.escape(alias)))
            for m in assign_rx.finditer(source):
                uses.append({
                    "service":service,
                    "member":m.group(1),
                    "kind":"service_property_assignment",
                    "alias":alias,
                    "line":line_no(source,m.start()),
                })

        dedupe=set()
        for use in uses:
            key=(use["service"],use["member"],use["kind"],use["line"])
            if key in dedupe:
                continue
            dedupe.add(key)

            service=use["service"]
            member=use["member"]
            service_cls=classes.get(service)
            member_meta=members_for(service).get(member) if service_cls else None
            tags=sorted(set((member_meta or {}).get("Tags") or []))
            status=(
                "missing_service"
                if service_cls is None
                else "unresolved_property_assignment"
                if use["kind"] == "service_property_assignment" and member_meta is None
                else "missing_member"
                if member_meta is None
                else "deprecated"
                if "Deprecated" in tags
                else "current"
            )
            summary[status]+=1
            records.append({
                **use,
                "scriptPath":path,
                "scriptClass":cls,
                "status":status,
                "memberType":(member_meta or {}).get("MemberType"),
                "tags":tags,
                "security":(member_meta or {}).get("Security"),
            })

    report={
        "schemaVersion":1,
        "workingBuildSha256":"04efd02d60dbf2388c230402888a21f0f3240efdf1b8971abcb0bc582b4ad8c4",
        "apiDump":{
            "repository":"MaximumADHD/Roblox-Client-Tracker",
            "commit":"fcd6994996bb655bef047c69f456463d94faa569",
            "robloxVersion":"0.741.19.7411056",
            "commitDate":"2026-09-29T19:57:18Z",
        },
        "summary":dict(sorted(summary.items())),
        "uses":records,
        "missingOrDeprecated":[
            r for r in records if r["status"] in {"missing_service","missing_member","deprecated"}
        ],
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_CURRENT_SERVICE_API_AUDIT ===")
    for status,count in sorted(summary.items()):
        print("STATUS",status,count)
    risky=report["missingOrDeprecated"]
    print("MISSING_OR_DEPRECATED",len(risky))
    for r in risky[:300]:
        print(
            "API_USE",
            r["status"],
            r["service"],
            r["member"],
            r["kind"],
            r["scriptClass"],
            r["scriptPath"],
            "line="+str(r["line"]),
        )
    print("=== END_RHS_CURRENT_SERVICE_API_AUDIT ===")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
