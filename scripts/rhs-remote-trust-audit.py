#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES={"Script","ModuleScript"}
REMOTE_CLASSES={"RemoteEvent","RemoteFunction"}

HANDLER_PATTERNS=[
    ("event", re.compile(
        r'(?P<remote>[A-Za-z0-9_\.\[\]"\' :]+?)\.OnServerEvent\s*:\s*(?:connect|Connect)\s*\(\s*function\s*\((?P<args>[^)]*)\)',
        re.I,
    )),
    ("invoke", re.compile(
        r'(?P<remote>[A-Za-z0-9_\.\[\]"\' :]+?)\.OnServerInvoke\s*=\s*\(?\s*function\s*\((?P<args>[^)]*)\)',
        re.I,
    )),
]

DANGEROUS={
    "datastore_write": re.compile(r'\b(?:SetAsync|UpdateAsync|IncrementAsync|RemoveAsync)\s*\(',re.I),
    "cash_or_value_change": re.compile(r'\b(?:ChangeCash|cash|currency|money|points?)\b',re.I),
    "asset_load": re.compile(r'\b(?:LoadAsset|InsertService|require\s*\(\s*\d{4,})',re.I),
    "teleport": re.compile(r'\bTeleport(?:Async|ToPlaceInstance|ToPrivateServer)?\s*\(',re.I),
    "kick": re.compile(r'\bKick\s*\(',re.I),
    "award": re.compile(r'\b(?:AwardBadge|AwardPoints|PurchaseGranted)\b',re.I),
    "clone_or_parent": re.compile(r'\bClone\s*\(|\.Parent\s*=',re.I),
    "destroy": re.compile(r'\b(?:Destroy|Remove)\s*\(',re.I),
    "server_remote_fire": re.compile(r'\b(?:FireClient|FireAllClients|InvokeClient|Fire)\s*\(',re.I),
}
VALIDATION={
    "type_check": re.compile(r'\b(?:type|typeof)\s*\(',re.I),
    "numeric_check": re.compile(r'\b(?:tonumber|math\.clamp|math\.min|math\.max)\b',re.I),
    "string_check": re.compile(r'\b(?:match|find|sub|len)\s*\(',re.I),
    "instance_check": re.compile(r'\b(?:FindFirstChild|WaitForChild|IsA|IsDescendantOf|GetPlayerFromCharacter)\s*\(',re.I),
    "distance_check": re.compile(r'\b(?:Magnitude|DistanceFromCharacter)\b',re.I),
    "ownership_check": re.compile(r'\b(?:userId|UserId|PlayerHasPass|Owns|owner|Owner|IsAdmin|admin)\b',re.I),
    "guard_branch": re.compile(r'\bif\b.+\b(?:then|return)\b',re.I),
    "pcall": re.compile(r'\bpcall\s*\(',re.I),
}
RATE={
    "cooldown": re.compile(r'\b(?:cooldown|debounce|throttle|rate.?limit|lastCall|lastRequest)\b',re.I),
    "time_gate": re.compile(r'\b(?:tick|time|os\.clock|os\.time)\s*\(',re.I),
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

def line_no(text,offset):
    return text.count("\n",0,offset)+1

def signals(text,patterns):
    return sorted(name for name,rx in patterns.items() if rx.search(text))

def context_window(source,start_line,lines_after=100):
    lines=source.splitlines()
    start=max(0,start_line-1)
    end=min(len(lines),start+lines_after)
    return "\n".join(lines[start:end])

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--output",required=True)
    args=ap.parse_args()

    root=ET.parse(args.xml).getroot()
    remote_inventory=[]
    handlers=[]

    for item,path in walk(root):
        cls=item.attrib.get("class","")
        if cls in REMOTE_CLASSES:
            remote_inventory.append({"path":path,"class":cls})
        if cls not in SCRIPT_CLASSES:
            continue
        source=prop_text(item,"Source")
        if not source:
            continue

        for handler_kind,rx in HANDLER_PATTERNS:
            for m in rx.finditer(source):
                ln=line_no(source,m.start())
                args_list=[a.strip() for a in m.group("args").split(",") if a.strip()]
                player_arg=args_list[0] if args_list else None
                window=context_window(source,ln,100)
                danger=signals(window,DANGEROUS)
                validation=signals(window,VALIDATION)
                rate=signals(window,RATE)
                player_refs=(window.count(player_arg) if player_arg else 0)

                score=0
                score+=3*len(danger)
                score-=min(5,len(validation))
                score-=2*min(2,len(rate))
                if player_arg is None:
                    score+=5
                elif player_refs<=1:
                    score+=2

                attention=(
                    "high" if score>=8 else
                    "medium" if score>=4 else
                    "low"
                )

                handlers.append({
                    "scriptPath":path,
                    "scriptClass":cls,
                    "handlerKind":handler_kind,
                    "line":ln,
                    "remoteExpression":" ".join(m.group("remote").split())[-300:],
                    "arguments":args_list,
                    "playerArgument":player_arg,
                    "playerArgumentReferencesInWindow":player_refs,
                    "dangerSignals":danger,
                    "validationSignals":validation,
                    "rateLimitSignals":rate,
                    "attention":attention,
                    "score":score,
                })

    counts=collections.Counter(h["attention"] for h in handlers)
    dangerous_counts=collections.Counter(sig for h in handlers for sig in h["dangerSignals"])
    high=[h for h in handlers if h["attention"]=="high"]
    medium=[h for h in handlers if h["attention"]=="medium"]

    report={
        "schemaVersion":1,
        "scope":"Static triage only. Findings are review priorities, not proof of exploitability.",
        "workingBuildSha256":json.loads((Path(__file__).resolve().parents[1]/"rhs/working/BUILD_STATE.json").read_text(encoding="utf-8"))["expectedWorkingSha256"],
        "summary":{
            "remoteInstances":len(remote_inventory),
            "serverHandlersFound":len(handlers),
            "attentionCounts":dict(sorted(counts.items())),
            "dangerSignalCounts":dict(sorted(dangerous_counts.items())),
        },
        "remoteInventory":remote_inventory,
        "handlers":sorted(handlers,key=lambda h:(-h["score"],h["scriptPath"],h["line"])),
        "highAttention":sorted(high,key=lambda h:(-h["score"],h["scriptPath"],h["line"])),
        "mediumAttention":sorted(medium,key=lambda h:(-h["score"],h["scriptPath"],h["line"])),
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_REMOTE_TRUST_AUDIT ===")
    print("REMOTE_INSTANCES",len(remote_inventory))
    print("SERVER_HANDLERS",len(handlers))
    for k,v in sorted(counts.items()):
        print("ATTENTION",k,v)
    for k,v in sorted(dangerous_counts.items()):
        print("DANGER_SIGNAL",k,v)
    for h in report["handlers"][:100]:
        print(
            "HANDLER",
            h["attention"],
            "score="+str(h["score"]),
            h["handlerKind"],
            h["scriptClass"],
            h["scriptPath"],
            "line="+str(h["line"]),
            "remote="+h["remoteExpression"],
            "danger="+",".join(h["dangerSignals"]),
            "validation="+",".join(h["validationSignals"]),
            "rate="+",".join(h["rateLimitSignals"]),
        )
    print("=== END_RHS_REMOTE_TRUST_AUDIT ===")

if __name__=="__main__":
    main()
