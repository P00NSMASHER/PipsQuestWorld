#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES={"Script","LocalScript","ModuleScript"}
AUTO_SERVER_ROOTS={"ServerScriptService","Workspace"}
AUTO_CLIENT_ROOTS={"StarterGui","StarterPlayer","ReplicatedFirst"}

WAIT_FOR_CHILD=re.compile(r'WaitForChild\\s*\\(([^\\n)]*)\\)',re.I)
WAIT_LITERAL=re.compile(
    r'(?P<receiver>(?:game(?::(?:GetService|service)\\s*\\(\\s*["\\\'][^"\\\']+["\\\']\\s*\\)|(?:\\.[A-Za-z_]\\w*)+)|workspace|script(?:\\.Parent)*|[A-Za-z_]\\w*(?:\\.[A-Za-z_]\\w*)*))'
    r'\\s*:\\s*WaitForChild\\s*\\(\\s*["\\\'](?P<name>[^"\\\']+)["\\\'](?P<rest>[^)]*)\\)',
    re.I,
)
REPEAT_WAIT_UNTIL=re.compile(r'repeat\s+(?:wait|task\.wait)\s*\([^)]*\)\s+until\s+(.+)',re.I)
WHILE_WAIT=re.compile(r'while\s+(?:true|wait\s*\([^)]*\)|task\.wait\s*\([^)]*\))\s+do',re.I)
REPEAT_LINE=re.compile(r'^\s*repeat\s*(?:--.*)?$',re.I)
UNTIL_LINE=re.compile(r'^\s*until\s+(.+)$',re.I)
BOUNDED_HINT=re.compile(
    r'counter|tries|attempt|timeout|deadline|elapsed|tick\s*\(|time\s*\(|os\.(?:clock|time)|#'
    r'|\b[A-Za-z_]\w*\s*(?:>=|>)\s*\d+',
    re.I,
)

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

def lane_for(cls,path):
    root=path.split("/",1)[0]
    if cls=="Script" and root in AUTO_SERVER_ROOTS:
        return "auto_server"
    if cls=="LocalScript" and root in AUTO_CLIENT_ROOTS:
        return "auto_client"
    if cls=="LocalScript" and root=="StarterPack":
        return "player_backpack"
    if cls=="ModuleScript":
        return "module_dependency"
    return "dormant_or_feature"

def indent_width(line):
    prefix=line[:len(line)-len(line.lstrip())]
    return prefix.count("\t")*4 + prefix.count(" ")

def resolve_receiver(script_path, receiver, known_paths):
    receiver=re.sub(r"\s+","",receiver)

    if receiver=="script":
        return script_path
    if receiver.startswith("script.Parent"):
        path=script_path
        suffix=receiver[len("script"):]
        parent_count=suffix.count(".Parent")
        for _ in range(parent_count):
            if "/" not in path:
                return None
            path=path.rsplit("/",1)[0]
        return path

    if receiver in {"workspace","game.Workspace"}:
        return "Workspace"

    m=re.fullmatch(r'game:(?:GetService|service)\(["\']([^"\']+)["\']\)(.*)',receiver,re.I)
    if m:
        service=m.group(1)
        suffix=m.group(2)
        if suffix:
            if not re.fullmatch(r'(?:\.[A-Za-z_]\w*)+',suffix):
                return None
            parts=[service]+[p for p in suffix.split(".") if p]
            candidate="/".join(parts)
        else:
            candidate=service
        return candidate if candidate in known_paths or any(p.startswith(candidate+"/") for p in known_paths) else None

    m=re.fullmatch(r'game\.([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)',receiver,re.I)
    if m:
        candidate=m.group(1).replace(".","/")
        return candidate if candidate in known_paths or any(p.startswith(candidate+"/") for p in known_paths) else None

    return None

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--output",required=True)
    args=ap.parse_args()

    root=ET.parse(args.xml).getroot()
    walked=list(walk(root))
    known_paths={path for _,path in walked}
    findings=[]
    summary=collections.Counter()

    for item,path in walked:
        cls=item.attrib.get("class","")
        if cls not in SCRIPT_CLASSES:
            continue
        source=prop_text(item,"Source")
        if not source:
            continue
        lane=lane_for(cls,path)
        lines=source.splitlines()

        for i,line in enumerate(lines,1):
            literal_matches=list(WAIT_LITERAL.finditer(line))
            literal_spans=[m.span() for m in literal_matches]

            for m in literal_matches:
                rest=m.group("rest")
                bounded="," in rest
                if bounded:
                    summary["boundedWaitForChild"]+=1
                    continue

                receiver=m.group("receiver")
                child=m.group("name").replace("/","_")
                receiver_path=resolve_receiver(path,receiver,known_paths)
                target_path=(receiver_path+"/"+child) if receiver_path else None

                if target_path and target_path in known_paths:
                    resolution="serialized_present"
                    severity="verified"
                    summary["serializedPresentWaitForChild"]+=1
                elif receiver_path and receiver_path in known_paths:
                    resolution="serialized_parent_missing_child"
                    severity="high" if lane in {"auto_server","auto_client"} and indent_width(line)<=4 else "review"
                    summary["serializedMissingWaitForChild"]+=1
                else:
                    resolution="dynamic_or_unresolved_receiver"
                    severity="review"
                    summary["dynamicOrUnresolvedWaitForChild"]+=1

                findings.append({
                    "type":"unbounded_WaitForChild",
                    "severity":severity,
                    "resolution":resolution,
                    "receiver":receiver,
                    "targetName":m.group("name"),
                    "targetPath":target_path,
                    "lane":lane,
                    "scriptPath":path,
                    "scriptClass":cls,
                    "line":i,
                    "text":line.strip()[:500],
                })
                summary["unboundedWaitForChild"]+=1
                summary["severity_"+severity]+=1

            # Non-literal / complex WaitForChild calls cannot be proven missing statically.
            for m in WAIT_FOR_CHILD.finditer(line):
                if any(a <= m.start() and m.end() <= b for a,b in literal_spans):
                    continue
                args_text=m.group(1)
                if "," in args_text:
                    summary["boundedWaitForChild"]+=1
                    continue
                findings.append({
                    "type":"unbounded_WaitForChild",
                    "severity":"review",
                    "resolution":"nonliteral_or_complex",
                    "lane":lane,
                    "scriptPath":path,
                    "scriptClass":cls,
                    "line":i,
                    "text":line.strip()[:500],
                })
                summary["unboundedWaitForChild"]+=1
                summary["nonliteralOrComplexWaitForChild"]+=1
                summary["severity_review"]+=1

            m=REPEAT_WAIT_UNTIL.search(line)
            if m:
                cond=m.group(1)
                bounded=bool(BOUNDED_HINT.search(cond))
                severity=("high" if lane in {"auto_server","auto_client"} and not bounded else "review")
                findings.append({
                    "type":"repeat_wait_until",
                    "severity":severity,
                    "lane":lane,
                    "scriptPath":path,
                    "scriptClass":cls,
                    "line":i,
                    "condition":cond.strip()[:400],
                    "text":line.strip()[:500],
                })
                summary["repeatWaitUntil"]+=1
                summary["severity_"+severity]+=1

            if WHILE_WAIT.search(line):
                severity="review"
                findings.append({
                    "type":"while_wait_loop",
                    "severity":severity,
                    "lane":lane,
                    "scriptPath":path,
                    "scriptClass":cls,
                    "line":i,
                    "text":line.strip()[:500],
                })
                summary["whileWaitLoops"]+=1
                summary["severity_"+severity]+=1

        # Multiline repeat...until loops.
        for idx,line in enumerate(lines):
            if not REPEAT_LINE.match(line):
                continue
            for j in range(idx+1,min(len(lines),idx+80)):
                um=UNTIL_LINE.match(lines[j])
                if not um:
                    continue
                cond=um.group(1)
                bounded=bool(BOUNDED_HINT.search(cond))
                body="\n".join(lines[idx:j+1])
                has_wait=bool(re.search(r'\b(?:wait|task\.wait)\s*\(',body,re.I))
                if has_wait:
                    severity="high" if lane in {"auto_server","auto_client"} and not bounded and indent_width(line)<=4 else "review"
                    findings.append({
                        "type":"multiline_repeat_until",
                        "severity":severity,
                        "lane":lane,
                        "scriptPath":path,
                        "scriptClass":cls,
                        "line":idx+1,
                        "untilLine":j+1,
                        "condition":cond.strip()[:400],
                        "text":line.strip()[:300],
                    })
                    summary["multilineRepeatUntil"]+=1
                    summary["severity_"+severity]+=1
                break

    # Deduplicate same path/line/type.
    dedupe={}
    for f in findings:
        dedupe[(f["scriptPath"],f["line"],f["type"])]=f
    findings=list(dedupe.values())
    findings.sort(key=lambda f:(
        {"high":0,"review":1,"verified":2}.get(f["severity"],3),
        0 if f["lane"] in {"auto_server","auto_client"} else 1,
        f["scriptPath"],f["line"],f["type"]
    ))

    summary["findings"]=len(findings)
    summary["autoStartFindings"]=sum(1 for f in findings if f["lane"] in {"auto_server","auto_client"})
    summary["highAttention"]=sum(1 for f in findings if f["severity"]=="high")
    summary["verifiedSerializedWaits"]=sum(
        1 for f in findings
        if f.get("resolution")=="serialized_present"
    )

    repo_root=Path(__file__).resolve().parents[1]
    build_state=json.loads(
        (repo_root/"rhs/working/BUILD_STATE.json").read_text(encoding="utf-8")
    )

    report={
        "schemaVersion":2,
        "scope":"Static triage of waits that can stall an individual startup script. Findings require runtime/context review; not every unbounded wait is a defect.",
        "workingBuildSha256":build_state["expectedWorkingSha256"],
        "summary":dict(sorted(summary.items())),
        "findings":findings,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_STARTUP_WAIT_AUDIT ===")
    for k,v in sorted(summary.items()):
        print("SUMMARY",k,v)
    for f in [x for x in findings if x["severity"]!="verified"][:200]:
        print(
            "WAIT_RISK",
            f["severity"],
            f["type"],
            f["lane"],
            f["scriptClass"],
            f["scriptPath"],
            "line="+str(f["line"]),
            ("condition="+f.get("condition","")) if f.get("condition") else "",
        )
    print("=== END_RHS_STARTUP_WAIT_AUDIT ===")

if __name__=="__main__":
    main()
