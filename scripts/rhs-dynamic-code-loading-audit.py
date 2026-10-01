#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES={"Script","LocalScript","ModuleScript"}

PATTERNS={
    "loadstring": re.compile(r"\bloadstring\s*\(",re.I),
    "http_get_post": re.compile(r"(?:HttpGet|HttpPost|GetAsync|PostAsync|RequestAsync)\s*\(",re.I),
    "numeric_require": re.compile(r"\brequire\s*\(\s*(\d{4,})\s*\)",re.I),
    "dynamic_require": re.compile(r"\brequire\s*\(\s*([^\n)]+)\s*\)",re.I),
    "insert_load_asset": re.compile(r"\bLoadAsset(?:Async)?\s*\(",re.I),
    "get_objects": re.compile(r"\bGetObjects\s*\(",re.I),
    "new_script_instance": re.compile(r"Instance\.new\s*\(\s*[\"'](?:Script|LocalScript|ModuleScript)[\"']",re.I),
    "source_assignment": re.compile(r"\.Source\s*=",re.I),
    "setfenv": re.compile(r"\bsetfenv\s*\(",re.I),
    "getfenv": re.compile(r"\bgetfenv\s*\(",re.I),
}

HIGH_COMBOS=[
    ("loadstring","http_get_post"),
    ("loadstring","source_assignment"),
]

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

def lane(cls,path):
    root=path.split("/",1)[0]
    if cls=="Script" and root in {"ServerScriptService","Workspace"}:
        return "auto_server"
    if cls=="LocalScript" and root in {"StarterGui","StarterPlayer","ReplicatedFirst"}:
        return "auto_client"
    if cls=="LocalScript" and root=="StarterPack":
        return "player_backpack"
    if cls=="ModuleScript":
        return "module_dependency"
    return "feature_or_storage"

def line_no(text,offset):
    return text.count("\n",0,offset)+1

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--output",required=True)
    args=ap.parse_args()

    root=ET.parse(args.xml).getroot()
    records=[]
    summary=collections.Counter()
    numeric_ids=collections.Counter()

    for item,path in walk(root):
        cls=item.attrib.get("class","")
        if cls not in SCRIPT_CLASSES:
            continue
        source=prop_text(item,"Source")
        if not source:
            continue

        hits={}
        for name,rx in PATTERNS.items():
            found=list(rx.finditer(source))
            if found:
                hits[name]=found

        if not hits:
            continue

        script_lane=lane(cls,path)
        signal_names=set(hits)
        high_reasons=[]
        for a,b in HIGH_COMBOS:
            if a in signal_names and b in signal_names:
                high_reasons.append(f"{a}+{b}")
        if "loadstring" in signal_names:
            attention="high"
        elif "new_script_instance" in signal_names and "source_assignment" in signal_names:
            attention="high"
            high_reasons.append("runtime-script-source")
        elif "numeric_require" in signal_names or "insert_load_asset" in signal_names or "get_objects" in signal_names:
            attention="medium"
        elif "dynamic_require" in signal_names:
            attention="review"
        else:
            attention="low"

        details={}
        contexts={}
        source_lines=source.splitlines()
        for name,found in hits.items():
            detail_lines=[line_no(source,m.start()) for m in found[:80]]
            details[name]=detail_lines
            if name in {"loadstring","new_script_instance","source_assignment","insert_load_asset","numeric_require"}:
                snippets=[]
                for ln in detail_lines[:20]:
                    start=max(1,ln-4)
                    end=min(len(source_lines),ln+5)
                    snippets.append({
                        "line":ln,
                        "startLine":start,
                        "endLine":end,
                        "lines":[
                            {"line":i,"text":source_lines[i-1][:800]}
                            for i in range(start,end+1)
                        ],
                    })
                contexts[name]=snippets
            summary[name]+=len(found)
            if name=="numeric_require":
                for m in found:
                    numeric_ids[m.group(1)]+=1

        rec={
            "scriptPath":path,
            "scriptClass":cls,
            "lane":script_lane,
            "sourceSha256":hashlib.sha256(source.encode("utf-8")).hexdigest(),
            "attention":attention,
            "highReasons":high_reasons,
            "signals":details,
            "contexts":contexts,
        }
        records.append(rec)
        summary["scriptsWithSignals"]+=1
        summary["attention_"+attention]+=1
        summary["lane_"+script_lane]+=1

    records.sort(key=lambda r:(
        {"high":0,"medium":1,"review":2,"low":3}.get(r["attention"],9),
        0 if r["lane"] in {"auto_server","auto_client"} else 1,
        r["scriptPath"],
    ))

    build_state=json.loads(
        (Path(__file__).resolve().parents[1]/"rhs/working/BUILD_STATE.json").read_text(encoding="utf-8")
    )
    report={
        "schemaVersion":1,
        "scope":"Static inventory of dynamic/external code-loading signals. Findings are review priorities, not proof of exploitability.",
        "workingBuildSha256":build_state["expectedWorkingSha256"],
        "summary":dict(sorted(summary.items())),
        "numericRequireAssetIds":[
            {"assetId":aid,"occurrences":count}
            for aid,count in numeric_ids.most_common()
        ],
        "records":records,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_DYNAMIC_CODE_LOADING_AUDIT ===")
    for k,v in sorted(summary.items()):
        print("SUMMARY",k,v)
    for aid,count in numeric_ids.most_common():
        print("NUMERIC_REQUIRE",aid,count)
    for rec in records[:250]:
        print(
            "DYNAMIC_CODE",
            rec["attention"],
            rec["lane"],
            rec["scriptClass"],
            rec["scriptPath"],
            "signals="+json.dumps({k:len(v) for k,v in rec["signals"].items()},sort_keys=True,separators=(",",":")),
            "reasons="+json.dumps(rec["highReasons"],separators=(",",":")),
        )
        if rec["attention"]=="high":
            for signal,snippets in rec.get("contexts",{}).items():
                for snippet in snippets:
                    print("HIGH_CONTEXT",rec["scriptPath"],signal,"line="+str(snippet["line"]))
                    for row in snippet["lines"]:
                        print(f'{row["line"]:04d}: {row["text"]}')
    # Targeted legacy-admin context for deciding whether loadstring paths are reachable.
    for rec in records:
        if rec["scriptPath"] != "ServerScriptService/Kohl's Admin Commands V2":
            continue
        print("=== RHS_KOHLS_ADMIN_REACHABILITY_CONTEXT ===")
        target_lines = [(1,140),(330,380),(430,530),(1370,1440),(2550,2625)]
        # Re-read the source for this exact script.
        target_source = None
        for item,path in walk(root):
            if path == rec["scriptPath"]:
                target_source = prop_text(item,"Source")
                break
        if target_source:
            src_lines=target_source.splitlines()
            for start,end in target_lines:
                print("ADMIN_RANGE",start,end)
                for i in range(start,min(end,len(src_lines))+1):
                    print(f"{i:04d}: {src_lines[i-1]}")
        print("=== END_RHS_KOHLS_ADMIN_REACHABILITY_CONTEXT ===")
        break
    print("=== END_RHS_DYNAMIC_CODE_LOADING_AUDIT ===")

if __name__=="__main__":
    main()
