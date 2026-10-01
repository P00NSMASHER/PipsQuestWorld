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
 "subject": re.compile(r"\b(math|english|science|history|classroom)\b",re.I),
 "question": re.compile(r"\b(question|prompt|quiz|answer|choice|correct)\b",re.I),
 "grading": re.compile(r"\b(grade|score|points?|xp|credit)\b",re.I),
 "persistence": re.compile(r"\b(DataStoreService|GetDataStore|GetOrderedDataStore|GetAsync|SetAsync|UpdateAsync|IncrementAsync)\b",re.I),
 "remote_server": re.compile(r"\bOnServerEvent\b"),
 "remote_client": re.compile(r"\bFireServer\s*\("),
 "correct_key": re.compile(r"\b(correctIndex|correctAnswer|answerKey|rightAnswer)\b",re.I),
}
DATASTORE_KEY=re.compile(r'Get(?:Ordered)?DataStore\s*\(\s*["\']([^"\']+)["\']')

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
    server_question=[r for r in scripts if r["role"]=="server" and "question" in r["tokens"]]
    strict_class_activity=[
        r for r in scripts
        if r["role"]=="server"
        and "question" in r["tokens"]
        and "grading" in r["tokens"]
        and ("class_flow" in r["tokens"] or "subject" in r["tokens"])
    ]
    server_class_without_activity=[
        r for r in scripts
        if r["role"]=="server"
        and ("class_flow" in r["tokens"] or "subject" in r["tokens"])
        and not ("question" in r["tokens"] and "grading" in r["tokens"])
    ]
    client_answer=[r for r in scripts if r["role"] in {"client","replicated"} and "correct_key" in r["tokens"]]
    server_grade_remote=[r for r in scripts if r["role"]=="server" and "remote_server" in r["tokens"] and "grading" in r["tokens"]]
    client_grade_remote=[r for r in scripts if r["role"]=="client" and "remote_client" in r["tokens"] and "grading" in r["tokens"]]
    persistence=[r for r in scripts if "persistence" in r["tokens"] or r["datastores"]]
    datastore_owners={}
    for r in persistence:
        for k in r["datastores"]:
            datastore_owners.setdefault(k,[]).append({"path":r["path"],"role":r["role"],"class":r["class"]})

    report={
      "schemaVersion":2,
      "candidateWorkingSha256":json.loads((Path(__file__).resolve().parents[1]/"rhs/working/BUILD_STATE.json").read_text(encoding="utf-8"))["expectedWorkingSha256"],
      "scriptCount":len(scripts),
      "scheduleCandidates":schedule,
      "classFlowCandidates":classflow,
      "serverQuestionCandidates":server_question,
      "strictServerClassActivityCandidates":strict_class_activity,
      "serverClassFlowWithoutActivityCandidates":server_class_without_activity,
      "clientOrReplicatedAnswerKeyCandidates":client_answer,
      "serverGradeRemoteCandidates":server_grade_remote,
      "clientGradeRemoteCandidates":client_grade_remote,
      "persistenceCandidates":persistence,
      "datastoreOwners":datastore_owners,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_SCHOOL_LIFE_QA_DIAGNOSTIC ===")
    print("CANDIDATE_WORKING_SHA256",report["candidateWorkingSha256"])
    print("SCRIPTS",len(scripts))
    print("SCHEDULE_CANDIDATES",len(schedule))
    print("CLASS_FLOW_CANDIDATES",len(classflow))
    print("SERVER_QUESTION_CANDIDATES",len(server_question))
    for r in server_question[:30]: print("SERVER_QUESTION",r["class"],r["path"])
    print("STRICT_SERVER_CLASS_ACTIVITY_CANDIDATES",len(strict_class_activity))
    for r in strict_class_activity[:30]: print("STRICT_CLASS_ACTIVITY",r["class"],r["path"])
    print("SERVER_CLASS_FLOW_WITHOUT_ACTIVITY",len(server_class_without_activity))
    for r in server_class_without_activity[:30]: print("CLASS_WITHOUT_ACTIVITY",r["class"],r["path"])
    print("CLIENT_ANSWER_KEY_CANDIDATES",len(client_answer))
    print("SERVER_GRADE_REMOTE_CANDIDATES",len(server_grade_remote))
    print("CLIENT_GRADE_REMOTE_CANDIDATES",len(client_grade_remote))
    print("DATASTORE_KEYS",len(datastore_owners))
    print("=== END_RHS_SCHOOL_LIFE_QA_DIAGNOSTIC ===")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
