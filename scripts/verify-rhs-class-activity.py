#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}
SERVER_ROOTS = {"ServerScriptService", "ServerStorage", "Workspace"}
CLIENT_ROOTS = {"StarterGui", "StarterPlayer", "StarterPack", "ReplicatedFirst"}

def prop_text(item, name: str) -> str:
    props = item.find("Properties")
    if props is None:
        return ""
    for p in props:
        if p.attrib.get("name") != name:
            continue
        if p.tag == "Content":
            child = next(iter(p), None)
            return (child.text or "") if child is not None else ""
        return p.text or ""
    return ""

def item_name(item) -> str:
    return prop_text(item, "Name") or "(unnamed)"

def walk(parent, prefix=""):
    for item in parent.findall("Item"):
        name = item_name(item).replace("/", "_")
        path = f"{prefix}/{name}" if prefix else name
        yield item, path
        yield from walk(item, path)

def role(cls: str, path: str) -> str:
    root = path.split("/", 1)[0]
    if cls == "LocalScript" or root in CLIENT_ROOTS:
        return "client"
    if cls == "Script" and root in SERVER_ROOTS:
        return "server"
    if cls == "ModuleScript" and root in {"ServerScriptService", "ServerStorage"}:
        return "server"
    if root == "ReplicatedStorage":
        return "replicated"
    return "other"

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--xml", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--build-state", default="rhs/working/BUILD_STATE.json")
    args = ap.parse_args()

    state = json.loads(Path(args.build_state).read_text(encoding="utf-8"))
    root = ET.parse(args.xml).getroot()
    scripts = {}
    generic_candidates = []
    client_secret_hits = []

    question_rx = re.compile(r"\b(question|prompt|quiz|answer|choice|correct)\b", re.I)
    grading_rx = re.compile(r"\b(grade|score|points?|xp|credit)\b", re.I)
    class_rx = re.compile(r"\b(classroom|class|attendance|teacher|period|math|english|science|history)\b", re.I)
    secret_rx = re.compile(r"\b(correctIndex|correctAnswer|answerKey|rightAnswer)\b", re.I)

    for item, path in walk(root):
        cls = item.attrib.get("class", "")
        if cls not in SCRIPT_CLASSES:
            continue
        source = prop_text(item, "Source")
        scripts[path] = {"class": cls, "role": role(cls, path), "source": source}

        if role(cls, path) == "server" and question_rx.search(source) and grading_rx.search(source) and class_rx.search(source):
            generic_candidates.append(path)
        if role(cls, path) in {"client", "replicated"} and secret_rx.search(source):
            client_secret_hits.append(path)

    errors = []
    server_path = "ServerScriptService/Time_ScheduleScript"
    client_path = "StarterGui/ClassNotification/LocalScript"
    server = scripts.get(server_path, {}).get("source", "")
    client = scripts.get(client_path, {}).get("source", "")

    if not server:
        errors.append(f"missing server activity owner: {server_path}")
    if not client:
        errors.append(f"missing client activity view: {client_path}")

    server_required = [
        'id = "rhs-math-place-value-1"',
        'subject = "Math"',
        'correctIndex = 2',
        'points = 1',
        'local function classActivityPublicPayload()',
        'local function handleClassActivitySubmission',
        'PlayerIsInZone',
        'classActivityReceipts',
        'classActivityCompleted',
        'ClassActivityPoints',
        'pointsValue.Value = pointsValue.Value + classActivityQuestion.points',
        'classname == "__RHS_CLASS_ACTIVITY__"',
        'event:FireClient(plr,"__RHS_CLASS_ACTIVITY__"',
        'event:FireClient(plr,"__RHS_CLASS_ACTIVITY_RESULT__"',
        'period.Changed:connect(beginClassActivity)',
    ]
    for token in server_required:
        if token not in server:
            errors.append(f"server class-activity contract missing token: {token}")

    schedule_binding_required = [
        'if type(periodNumber) ~= "number" or periodNumber < 1 or periodNumber > 6 or periodNumber == 4 then',
        'local slot = schedule:FindFirstChild("P"..periodNumber)',
        'if not slot or slot.Value ~= classActivityQuestion.subject then',
        'local slot = schedule:FindFirstChild("P"..classActivityCurrentPeriod)',
        'if not classActivityCurrentPeriod or period.Value ~= classActivityCurrentPeriod then',
        'zoneCheck:Invoke(plr,classActivityQuestion.subject)',
    ]
    for token in schedule_binding_required:
        if token not in server:
            errors.append(f"server class-activity schedule/zone binding missing token: {token}")

    if re.search(r'classActivityCurrentPeriod\s*=\s*[1-6]\b', server):
        errors.append("class activity hard-codes a period instead of following the scheduled subject")

    client_required = [
        'local function showClassActivity(payload)',
        'local function showClassActivityResult(payload)',
        'Instance.new("TextButton")',
        'ClassTeleport:FireServer("__RHS_CLASS_ACTIVITY__"',
        'period == "__RHS_CLASS_ACTIVITY__"',
        'period == "__RHS_CLASS_ACTIVITY_RESULT__"',
    ]
    for token in client_required:
        if token not in client:
            errors.append(f"client class-activity contract missing token: {token}")

    if secret_rx.search(client):
        errors.append("client class activity leaks an answer-key identifier")

    plr_decl = client.find("local plr = game.Players.LocalPlayer")
    activity_fn = client.find("local function showClassActivity(payload)")
    if plr_decl < 0 or activity_fn < 0 or plr_decl > activity_fn:
        errors.append("client activity closures are not bound to the local player declaration")

    public_fn = re.search(
        r"local function classActivityPublicPayload\(\)(.*?)\nend",
        server,
        re.DOTALL,
    )
    if not public_fn:
        errors.append("server public activity payload function not found")
    else:
        public_body = public_fn.group(1)
        for secret in ("correctIndex", "hint", "explanation", "points"):
            if secret in public_body:
                errors.append(f"server public activity payload leaks private field: {secret}")

    completion_pos = server.find("classActivityCompleted[playerKey] = true")
    award_pos = server.find("pointsValue.Value = pointsValue.Value + classActivityQuestion.points")
    if completion_pos < 0 or award_pos < 0 or completion_pos > award_pos:
        errors.append("completion guard must be committed before points award")

    prior_pos = server.find("local prior = classActivityReceipts[playerKey][submissionId]")
    prior_return_pos = server.find("sendClassActivityResult(plr,prior)")
    if prior_pos < 0 or prior_return_pos < prior_pos:
        errors.append("idempotent submission receipt replay is missing")

    if not generic_candidates:
        errors.append("no generic strict server class-activity candidate detected")

    expected_repairs = {
        "add-server-authoritative-class-activity",
        "add-client-class-activity-ui",
    }
    actual_repairs = set(state.get("compatibilityRepairs") or [])
    missing_repairs = sorted(expected_repairs - actual_repairs)
    if missing_repairs:
        errors.append("working build missing class-activity repair ids: " + ", ".join(missing_repairs))

    report = {
        "schemaVersion": 1,
        "workingSha256": state.get("expectedWorkingSha256"),
        "runtimeVerified": state.get("runtimeVerified"),
        "published": state.get("published"),
        "genericStrictServerClassActivityCandidates": sorted(generic_candidates),
        "clientOrReplicatedAnswerKeyCandidates": sorted(client_secret_hits),
        "serverOwner": server_path,
        "clientView": client_path,
        "scheduleBinding": {
            "subject": "Math",
            "dynamicPeriodLookup": 'schedule:FindFirstChild("P"..periodNumber)' in server,
            "lunchExcluded": 'periodNumber == 4' in server,
            "submissionRevalidatesPeriod": 'period.Value ~= classActivityCurrentPeriod' in server,
            "submissionRevalidatesSubject": 'schedule:FindFirstChild("P"..classActivityCurrentPeriod)' in server,
            "submissionRequiresSubjectZone": 'zoneCheck:Invoke(plr,classActivityQuestion.subject)' in server,
        },
        "contractErrors": errors,
    }
    Path(args.output).write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print("=== RHS_CLASS_ACTIVITY_CONTRACT ===")
    print("WORKING_SHA256", report["workingSha256"])
    print("STRICT_SERVER_CLASS_ACTIVITY_CANDIDATES", len(generic_candidates))
    for path in sorted(generic_candidates)[:30]:
        print("STRICT_CLASS_ACTIVITY", path)
    print("SCHEDULE_BINDING_DYNAMIC", str(report["scheduleBinding"]["dynamicPeriodLookup"]).lower())
    print("SCHEDULE_LUNCH_EXCLUDED", str(report["scheduleBinding"]["lunchExcluded"]).lower())
    print("SUBMISSION_PERIOD_REVALIDATED", str(report["scheduleBinding"]["submissionRevalidatesPeriod"]).lower())
    print("SUBMISSION_SUBJECT_REVALIDATED", str(report["scheduleBinding"]["submissionRevalidatesSubject"]).lower())
    print("SUBMISSION_ZONE_REVALIDATED", str(report["scheduleBinding"]["submissionRequiresSubjectZone"]).lower())
    print("CLIENT_ANSWER_KEY_CANDIDATES", len(client_secret_hits))
    for path in sorted(client_secret_hits)[:30]:
        print("CLIENT_ANSWER_KEY", path)
    print("CONTRACT_ERRORS", len(errors))
    for error in errors:
        print("ERROR", error)
    if errors:
        raise SystemExit(1)
    print("RHS_CLASS_ACTIVITY_CONTRACT_PASS")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
