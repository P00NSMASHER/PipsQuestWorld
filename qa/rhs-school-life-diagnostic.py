#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES={"Script","LocalScript","ModuleScript"}
SERVER_ROOTS={"ServerScriptService","ServerStorage","Workspace"}
CLIENT_ROOTS={"StarterGui","StarterPlayer","StarterPack","ReplicatedFirst"}

def prop_text(item,name):
    props=item.find("Properties")
    if props is None: return ""
    for p in props:
        if p.attrib.get("name")!=name: continue
        if p.tag=="Content":
            c=next(iter(p),None); return (c.text or "") if c is not None else ""
        return p.text or ""
    return ""

def item_name(item): return prop_text(item,"Name") or "(unnamed)"

def walk(parent,prefix=""):
    for item in parent.findall("Item"):
        name=item_name(item).replace("/","_")
        here=f"{prefix}/{name}" if prefix else name
        yield item,here
        yield from walk(item,here)

def role(cls,path):
    root=path.split("/",1)[0]
    if cls=="LocalScript" or root in CLIENT_ROOTS: return "client"
    if cls=="Script" and root in SERVER_ROOTS: return "server"
    if cls=="ModuleScript" and root in {"ServerScriptService","ServerStorage"}: return "server"
    if cls=="ModuleScript" and root in {"StarterGui","StarterPlayer","StarterPack","ReplicatedFirst"}: return "client"
    if root=="ReplicatedStorage": return "replicated"
    return "other"

TOKENS={
 "schedule": re.compile(r"\b(schedule|period|school\s*time|bell|timetable)\b",re.I),
 "class_flow": re.compile(r"\b(classroom|class\s*start|class\s*end|attendance|attend|teacher|period)\b",re.I),
 "question": re.compile(r"\b(question|prompt|quiz|answer|choice|correct)\b",re.I),
 "grading": re.compile(r"\b(grade|score|points?|xp|credit)\b",re.I),
 "persistence": re.compile(r"\b(DataStoreService|GetDataStore|GetOrderedDataStore|GetAsync|SetAsync|UpdateAsync|IncrementAsync)\b",re.I),
 "remote_server": re.compile(r"\bOnServerEvent\b"),
 "remote_client": re.compile(r"\bFireServer\s*\("),
 "correct_key": re.compile(r"\b(correctIndex|correctAnswer|answerKey|rightAnswer)\b",re.I),
}
DATASTORE_KEY=re.compile(r'Get(?:Ordered)?DataStore\s*\(\s*["\']([^"\']+)["\']')
EVENT_HANDLER=re.compile(r'OnServerEvent\s*:\s*Connect|OnServerEvent\s*=')

def compact(s):
    return re.sub(r"\s+"," ",s.strip())[:260]

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--xml",required=True)
    ap.add_argument("--output",required=True)
    args=ap.parse_args()
    root=ET.parse(args.xml).getroot()
    scripts=[]
    for item,path in walk(root):
        cls=item.attrib.get("class","")
        if cls not in SCRIPT_CLASSES: continue
        src=prop_text(item,"Source")
        rec={"path":path,"class":cls,"role":role(cls,path),"len":len(src)}
        rec["tokens"]={k:len(rx.findall(src)) for k,rx in TOKENS.items() if rx.search(src)}
        rec["datastores"]=sorted(set(DATASTORE_KEY.findall(src)))
        if rec["tokens"] or rec["datastores"]:
            rec["sample"]=compact(src)
        scripts.append(rec)

    def filt(token,roles=None):
        out=[r for r in scripts if token in r["tokens"] and (roles is None or r["role"] in roles)]
        return sorted(out,key=lambda r:(r["role"],r["path"]))

    schedule=filt("schedule",{"server","replicated","client"})
    classflow=filt("class_flow",{"server","replicated","client"})
    server_activity=[r for r in scripts if r["role"]=="server" and "question" in r["tokens"] and "grading" in r["tokens"]]
    client_answer=[r for r in scripts if r["role"] in {"client","replicated"} and "correct_key" in r["tokens"]]
    server_grade_remote=[r for r in scripts if r["role"]=="server" and "remote_server" in r["tokens"] and "grading" in r["tokens"]]
    client_grade_remote=[r for r in scripts if r["role"]=="client" and "remote_client" in r["tokens"] and "grading" in r["tokens"]]
    persistence=[r for r in scripts if "persistence" in r["tokens"] or r["datastores"]]
    datastore_owners={}
    for r in persistence:
        for k in r["datastores"]:
            datastore_owners.setdefault(k,[]).append({"path":r["path"],"role":r["role"],"class":r["class"]})

    report={
      "schemaVersion":1,
      "candidateSha":"3ffa9b75f18f51fc26feb0b1e3ec03862b46e5e3",
      "scriptCount":len(scripts),
      "scheduleCandidates":schedule,
      "classFlowCandidates":classflow,
      "serverAuthoritativeActivityCandidates":server_activity,
      "clientOrReplicatedAnswerKeyCandidates":client_answer,
      "serverGradeRemoteCandidates":server_grade_remote,
      "clientGradeRemoteCandidates":client_grade_remote,
      "persistenceCandidates":persistence,
      "datastoreOwners":datastore_owners,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_SCHOOL_LIFE_QA_DIAGNOSTIC ===")
    print("CANDIDATE",report["candidateSha"])
    print("SCRIPTS",len(scripts))
    print("SCHEDULE_CANDIDATES",len(schedule))
    for r in schedule[:25]: print("SCHEDULE",r["role"],r["class"],r["path"])
    print("CLASS_FLOW_CANDIDATES",len(classflow))
    for r in classflow[:35]: print("CLASS_FLOW",r["role"],r["class"],r["path"])
    print("SERVER_ACTIVITY_CANDIDATES",len(server_activity))
    for r in server_activity[:25]: print("SERVER_ACTIVITY",r["class"],r["path"])
    print("CLIENT_ANSWER_KEY_CANDIDATES",len(client_answer))
    for r in client_answer[:25]: print("CLIENT_ANSWER_KEY",r["role"],r["class"],r["path"])
    print("SERVER_GRADE_REMOTE_CANDIDATES",len(server_grade_remote))
    for r in server_grade_remote[:25]: print("SERVER_GRADE_REMOTE",r["class"],r["path"])
    print("CLIENT_GRADE_REMOTE_CANDIDATES",len(client_grade_remote))
    for r in client_grade_remote[:25]: print("CLIENT_GRADE_REMOTE",r["class"],r["path"])
    print("DATASTORE_KEYS",len(datastore_owners))
    for k,owners in sorted(datastore_owners.items()):
        print("DATASTORE",json.dumps(k),len(owners),",".join(o["path"] for o in owners[:8]))
    print("=== END_RHS_SCHOOL_LIFE_QA_DIAGNOSTIC ===")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
