#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES={"Script","ModuleScript","LocalScript"}
HANDLER_PATTERNS=[
    ("OnServerEvent", re.compile(r'\.OnServerEvent\s*:\s*(?:connect|Connect)\s*\(\s*function\s*\(([^)]*)\)', re.I)),
    ("OnServerInvoke", re.compile(r'\.OnServerInvoke\s*=\s*function\s*\(([^)]*)\)', re.I)),
]

VALIDATION_PATTERNS={
    "type_check": re.compile(r'\b(?:type|typeof)\s*\(|:IsA\s*\(',re.I),
    "numeric_coercion": re.compile(r'\btonumber\s*\(',re.I),
    "bounds_check": re.compile(r'(?:<=|>=|<|>)|\bmath\.(?:min|max|clamp)\s*\(',re.I),
    "string_validation": re.compile(r'\b(?:match|find)\s*\(|:match\s*\(|:find\s*\(',re.I),
    "player_state": re.compile(r'PlayerData|IsDataLoadedSuccessfully|loadsuccess|safetoload',re.I),
    "authorization": re.compile(r'IsAdmin|GetRankInGroup|GetRoleInGroup|PlayerHasPass|GamePassCheck|UserId|userId|\.Team\b|TeamColor',re.I),
    "object_existence": re.compile(r'FindFirstChild|WaitForChild',re.I),
    "server_owned_instance": re.compile(r'workspace\s*[:.]\s*FindFirstChild\s*\([^)]*plr\.Name|car\s*==\s*workspace\s*[:.]\s*FindFirstChild',re.I),
}
THROTTLE_PATTERNS={
    "cooldown": re.compile(r'cooldown|debounce|throttl',re.I),
    "time_gate": re.compile(r'\bos\.(?:time|clock)\s*\(|\btick\s*\(|\btime\s*\(',re.I),
}
MUTATION_PATTERNS={
    "datastore_write": re.compile(r'\b(?:SetAsync|UpdateAsync|IncrementAsync|RemoveAsync)\s*\(',re.I),
    "destroy": re.compile(r':Destroy\s*\(|:Remove\s*\(',re.I),
    "clone_parent": re.compile(r':Clone\s*\(|\.Parent\s*=',re.I),
    "value_write": re.compile(r'\.Value\s*=|\.CFrame\s*=|\.Position\s*=|\.Transparency\s*=|\.CanCollide\s*=',re.I),
    "economy": re.compile(r'cash|purchase|price|cost|award|item|object',re.I),
    "teleport": re.compile(r'TeleportService|:Teleport\s*\(',re.I),
    "kick_ban": re.compile(r':Kick\s*\(|\bBan',re.I),
}

def prop_text(item,name):
    props=item.find("Properties")
    if props is None:
        return ""
    for p in props:
        if p.attrib.get("name")!=name:
            continue
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

def lines_with_hits(text, patterns):
    out={}
    for key,rx in patterns.items():
        hits=[i for i,line in enumerate(text.splitlines(),1) if rx.search(line)]
        if hits:
            out[key]=hits
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--output",required=True)
    ap.add_argument("--window-lines",type=int,default=80)
    ap.add_argument("--fail-on-high",action="store_true")
    args=ap.parse_args()

    root=ET.parse(args.xml).getroot()
    build_state=json.loads(Path("rhs/working/BUILD_STATE.json").read_text(encoding="utf-8"))
    handlers=[]
    summary=collections.Counter()

    for item,path in walk(root):
        cls=item.attrib.get("class","")
        if cls not in SCRIPT_CLASSES:
            continue
        source=prop_text(item,"Source")
        if not source:
            continue
        src_lines=source.splitlines()

        for handler_type,rx in HANDLER_PATTERNS:
            for m in rx.finditer(source):
                line=source.count("\n",0,m.start())+1
                args_text=m.group(1).strip()
                params=[p.strip() for p in args_text.split(",") if p.strip()]
                start=max(1,line)
                end=min(len(src_lines),line+args.window_lines-1)
                window="\n".join(src_lines[start-1:end])

                validation=lines_with_hits(window,VALIDATION_PATTERNS)
                throttle=lines_with_hits(window,THROTTLE_PATTERNS)
                mutation=lines_with_hits(window,MUTATION_PATTERNS)

                has_player_param=bool(params)
                player_param=params[0] if params else None
                obvious_validation=bool(validation)
                obvious_throttle=bool(throttle)
                mutates=bool(mutation)

                if mutates and not obvious_validation:
                    severity="high"
                elif mutates and obvious_validation and not obvious_throttle:
                    severity="medium"
                elif not mutates and not obvious_validation:
                    severity="review"
                else:
                    severity="low"

                rec={
                    "scriptPath":path,
                    "sourceSha256":hashlib.sha256(source.encode("utf-8")).hexdigest(),
                    "scriptClass":cls,
                    "handlerType":handler_type,
                    "line":line,
                    "parameters":params,
                    "playerParameter":player_param,
                    "hasPlayerParameter":has_player_param,
                    "windowEndLine":end,
                    "validationSignals":validation,
                    "throttleSignals":throttle,
                    "mutationSignals":mutation,
                    "heuristicSeverity":severity,
                    "context":src_lines[max(0,line-3):min(len(src_lines),line+8)],
                }
                handlers.append(rec)
                summary["handlers"]+=1
                summary[handler_type]+=1
                summary["severity_"+severity]+=1
                if mutates:
                    summary["handlersWithMutationSignals"]+=1
                if obvious_validation:
                    summary["handlersWithValidationSignals"]+=1
                if obvious_throttle:
                    summary["handlersWithThrottleSignals"]+=1

    handlers.sort(key=lambda r:(
        {"high":0,"medium":1,"review":2,"low":3}[r["heuristicSeverity"]],
        r["scriptPath"],r["line"]
    ))

    report={
        "schemaVersion":1,
        "scope":"Heuristic static inventory. A flag is not proof of exploitability; handlers require manual/runtime review before changes.",
        "workingBuildSha256":build_state["expectedWorkingSha256"],
        "summary":dict(sorted(summary.items())),
        "handlers":handlers,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_REMOTE_SECURITY_AUDIT ===")
    for k,v in sorted(summary.items()):
        print("SUMMARY",k,v)
    for rec in handlers[:200]:
        print(
            "REMOTE_HANDLER",
            rec["heuristicSeverity"],
            rec["handlerType"],
            rec["scriptClass"],
            rec["scriptPath"],
            "line="+str(rec["line"]),
            "source_sha256="+rec["sourceSha256"],
            "params="+json.dumps(rec["parameters"],separators=(",",":")),
            "validation="+json.dumps(sorted(rec["validationSignals"]),separators=(",",":")),
            "throttle="+json.dumps(sorted(rec["throttleSignals"]),separators=(",",":")),
            "mutation="+json.dumps(sorted(rec["mutationSignals"]),separators=(",",":")),
        )
    print("=== END_RHS_REMOTE_SECURITY_AUDIT ===")
    if args.fail_on_high and summary.get("severity_high",0) > 0:
        raise SystemExit(f"RHS remote security audit found {summary[\"severity_high\"]} severity-high handler(s)")

if __name__=="__main__":
    main()
