#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES={"Script","LocalScript","ModuleScript"}

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

def matches_token(path,name,token):
    hay=(path+"\n"+name).lower()
    return token.lower() in hay

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--output",required=True)
    ap.add_argument("--require-core",action="store_true")
    args=ap.parse_args()

    root=ET.parse(args.xml).getroot()
    instances=[]
    scripts=[]
    for item,path in walk(root):
        cls=item.attrib.get("class","")
        nm=item_name(item)
        instances.append({"path":path,"name":nm,"class":cls})
        if cls in SCRIPT_CLASSES:
            source=prop_text(item,"Source")
            if source:
                scripts.append({"path":path,"name":nm,"class":cls,"source":source})

    requirements={
        "scheduleScript":{
            "tokens":["Time_ScheduleScript","ScheduleScript"],
            "required":True,
        },
        "classroomZones":{
            "tokens":["ClassroomZones"],
            "required":True,
        },
        "classNotificationGui":{
            "tokens":["ClassNotification"],
            "required":True,
        },
        "classTeleport":{
            "tokens":["ClassTeleport"],
            "required":True,
        },
        "scheduledTeleport":{
            "tokens":["ScheduledTeleport"],
            "required":True,
        },
        "changeClassSchedule":{
            "tokens":["ChangeClassSchedule"],
            "required":True,
        },
        "mathClass":{
            "tokens":["Math"],
            "required":True,
        },
        "englishClass":{
            "tokens":["English"],
            "required":True,
        },
        "scienceClass":{
            "tokens":["Science"],
            "required":True,
        },
        "historyClass":{
            "tokens":["History"],
            "required":True,
        },
        "cafeteria":{
            "tokens":["Cafeteria"],
            "required":True,
        },
        "lockers":{
            "tokens":["Locker"],
            "required":True,
        },
    }

    results={}
    for key,spec in requirements.items():
        found=[]
        for inst in instances:
            if any(matches_token(inst["path"],inst["name"],t) for t in spec["tokens"]):
                found.append(inst)
        # For remote/script names that may only be referenced from source, include source refs.
        source_refs=[]
        for scr in scripts:
            for token in spec["tokens"]:
                if re.search(re.escape(token),scr["source"],re.I):
                    source_refs.append({
                        "path":scr["path"],
                        "class":scr["class"],
                        "token":token,
                    })
                    break
        results[key]={
            "required":spec["required"],
            "instanceMatches":found[:100],
            "sourceReferences":source_refs[:100],
            "present":bool(found or source_refs),
        }

    # Stronger school-loop source signals. These do not replace runtime proof.
    source_signals={
        "classesAttended":re.compile(r"ClassesAttended",re.I),
        "badgeAfterTenClasses":re.compile(r"ClassesAttended\.Value\s*>=\s*10",re.I),
        "classRemoteFire":re.compile(r"(?:ClassTeleport|ScheduledTeleport|ChangeClassSchedule)",re.I),
        "periodOrSchedule":re.compile(r"(?:period|schedule|class)",re.I),
    }
    signal_hits={}
    for name,rx in source_signals.items():
        hits=[]
        for scr in scripts:
            if rx.search(scr["source"]):
                hits.append({"path":scr["path"],"class":scr["class"]})
        signal_hits[name]=hits[:100]

    missing=[key for key,rec in results.items() if rec["required"] and not rec["present"]]

    report={
        "schemaVersion":1,
        "scope":"Static school-loop acceptance preflight only; runtime Gates A/B remain required.",
        "workingBuildSha256":"04efd02d60dbf2388c230402888a21f0f3240efdf1b8971abcb0bc582b4ad8c4",
        "summary":{
            "requiredChecks":sum(1 for r in results.values() if r["required"]),
            "requiredPresent":sum(1 for r in results.values() if r["required"] and r["present"]),
            "requiredMissing":len(missing),
            "missingKeys":missing,
        },
        "requirements":results,
        "sourceSignals":signal_hits,
    }

    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_SCHOOL_LOOP_AUDIT ===")
    print("REQUIRED_CHECKS",report["summary"]["requiredChecks"])
    print("REQUIRED_PRESENT",report["summary"]["requiredPresent"])
    print("REQUIRED_MISSING",report["summary"]["requiredMissing"])
    for key,rec in results.items():
        print(
            "SCHOOL_CHECK",
            key,
            "present="+str(rec["present"]).lower(),
            "instances="+str(len(rec["instanceMatches"])),
            "source_refs="+str(len(rec["sourceReferences"])),
        )
        for inst in rec["instanceMatches"][:20]:
            print("INSTANCE",key,inst["class"],inst["path"])
        for ref in rec["sourceReferences"][:20]:
            print("SOURCE_REF",key,ref["class"],ref["path"],"token="+ref["token"])
    for name,hits in signal_hits.items():
        print("SOURCE_SIGNAL",name,len(hits))
    print("=== END_RHS_SCHOOL_LOOP_AUDIT ===")

    if args.require_core and missing:
        raise SystemExit("Missing required RHS school-loop markers: "+", ".join(missing))

if __name__=="__main__":
    main()
