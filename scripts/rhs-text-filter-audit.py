#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES={"Script","ModuleScript","LocalScript"}

FILTER_PATTERNS={
    "textservice_filter": re.compile(r'FilterStringAsync|GetNonChatStringForBroadcastAsync|GetNonChatStringForUserAsync|GetChatForUserAsync',re.I),
    "legacy_chat_filter": re.compile(r'FilterStringForBroadcast|FilterStringForPlayer|FilterStringAsync',re.I),
    "textservice_reference": re.compile(r'\bTextService\b',re.I),
    "chat_service_reference": re.compile(r'game\s*:\s*(?:GetService|service)\s*\(\s*["\']Chat["\']\s*\)|\bChat\s*:',re.I),
}
TEXT_SOURCE_PATTERNS={
    "textbox_text": re.compile(r'\.Text\b',re.I),
    "text_like_remote_arg": re.compile(r'\b(?:text|message|msg|name|desc|description|title|reason|status|bio|rpname|rpdesc|string|str)\b',re.I),
}
TEXT_SINK_PATTERNS={
    "gui_text_write": re.compile(r'\.Text\s*=',re.I),
    "stringvalue_write": re.compile(r'\.Value\s*=\s*[A-Za-z_]\w*',re.I),
    "notification_remote": re.compile(r'NotificationForClient\s*:\s*Fire(?:Client|AllClients)?\s*\(',re.I),
    "chat_remote": re.compile(r'(?:Chat|Message|RPName|RPDesc|Description).*?:\s*Fire(?:Client|AllClients|Server)?\s*\(',re.I),
    "billboard_or_label": re.compile(r'(?:TextLabel|TextButton|SurfaceGui|BillboardGui)',re.I),
}
HANDLER_PATTERNS=[
    re.compile(r'\.OnServerEvent\s*:\s*(?:connect|Connect)\s*\(\s*function\s*\(([^)]*)\)',re.I),
    re.compile(r'\.OnServerInvoke\s*=\s*\(?\s*function\s*\(([^)]*)\)',re.I),
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

def hit_lines(source,patterns):
    out={}
    lines=source.splitlines()
    for key,rx in patterns.items():
        hits=[i for i,line in enumerate(lines,1) if rx.search(line)]
        if hits:
            out[key]=hits
    return out

def line_no(source,offset):
    return source.count("\n",0,offset)+1

def window(source,start_line,size=120):
    lines=source.splitlines()
    start=max(0,start_line-1)
    return "\n".join(lines[start:min(len(lines),start+size)])

def text_like_params(params):
    out=[]
    for p in params:
        bare=re.sub(r'[^A-Za-z0-9_].*$', '', p.strip())
        if re.search(r'(?:text|message|msg|name|desc|description|title|reason|status|bio|rpname|rpdesc|string|str)',bare,re.I):
            out.append(bare)
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--output",required=True)
    args=ap.parse_args()

    root=ET.parse(args.xml).getroot()
    filtering_scripts=[]
    handler_records=[]
    sink_scripts=[]
    custom_chat_paths=[]
    summary=collections.Counter()

    for item,path in walk(root):
        cls=item.attrib.get("class","")
        if cls not in SCRIPT_CLASSES:
            continue
        source=prop_text(item,"Source")
        if not source:
            continue

        filter_hits=hit_lines(source,FILTER_PATTERNS)
        sink_hits=hit_lines(source,TEXT_SINK_PATTERNS)

        if filter_hits:
            filtering_scripts.append({
                "path":path,"class":cls,"filterSignals":filter_hits
            })
            summary["scriptsWithFilterSignals"]+=1
            summary["filterSignalOccurrences"]+=sum(len(v) for v in filter_hits.values())

        if sink_hits:
            sink_scripts.append({
                "path":path,"class":cls,"sinkSignals":sink_hits,
                "hasFilteringSignals":bool(filter_hits),
            })
            summary["scriptsWithTextSinkSignals"]+=1

        if re.search(r'(?i)(chat|rpname|rpdesc|roleplay|description|message)',path):
            custom_chat_paths.append(path)

        for rx in HANDLER_PATTERNS:
            for m in rx.finditer(source):
                params=[p.strip() for p in m.group(1).split(",") if p.strip()]
                text_params=text_like_params(params[1:] if len(params)>1 else params)
                if not text_params:
                    continue
                ln=line_no(source,m.start())
                w=window(source,ln)
                local_filters={k:bool(r.search(w)) for k,r in FILTER_PATTERNS.items()}
                local_sinks={k:bool(r.search(w)) for k,r in TEXT_SINK_PATTERNS.items()}
                filter_present=any(local_filters.values())
                sink_present=any(local_sinks.values())

                status=(
                    "filtered_path" if filter_present else
                    "review_unfiltered_sink" if sink_present else
                    "review_no_filter_detected"
                )
                summary["textLikeRemoteHandlers"]+=1
                summary[status]+=1
                handler_records.append({
                    "scriptPath":path,
                    "scriptClass":cls,
                    "line":ln,
                    "parameters":params,
                    "textLikeParameters":text_params,
                    "filterSignalsInWindow":[k for k,v in local_filters.items() if v],
                    "sinkSignalsInWindow":[k for k,v in local_sinks.items() if v],
                    "status":status,
                })

    handler_records.sort(key=lambda r:(
        {"review_unfiltered_sink":0,"review_no_filter_detected":1,"filtered_path":2}[r["status"]],
        r["scriptPath"],r["line"]
    ))

    report={
        "schemaVersion":1,
        "scope":"Static triage only. Review flags do not prove text is displayed unfiltered at runtime.",
        "workingBuildSha256":"04efd02d60dbf2388c230402888a21f0f3240efdf1b8971abcb0bc582b4ad8c4",
        "summary":dict(sorted(summary.items())),
        "customChatOrRoleplayScriptPaths":sorted(set(custom_chat_paths)),
        "filteringScripts":filtering_scripts,
        "textLikeRemoteHandlers":handler_records,
        "textSinkScripts":sink_scripts,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_TEXT_FILTER_AUDIT ===")
    for k,v in sorted(summary.items()):
        print("SUMMARY",k,v)
    for rec in handler_records[:150]:
        print(
            "TEXT_HANDLER",
            rec["status"],
            rec["scriptClass"],
            rec["scriptPath"],
            "line="+str(rec["line"]),
            "params="+json.dumps(rec["textLikeParameters"],separators=(",",":")),
            "filters="+json.dumps(rec["filterSignalsInWindow"],separators=(",",":")),
            "sinks="+json.dumps(rec["sinkSignalsInWindow"],separators=(",",":")),
        )
    for rec in filtering_scripts[:80]:
        print(
            "FILTER_SCRIPT",
            rec["class"],
            rec["path"],
            "signals="+json.dumps({k:len(v) for k,v in rec["filterSignals"].items()},sort_keys=True,separators=(",",":")),
        )
    print("=== END_RHS_TEXT_FILTER_AUDIT ===")

if __name__=="__main__":
    main()
