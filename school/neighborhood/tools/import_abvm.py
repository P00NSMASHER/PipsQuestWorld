#!/usr/bin/env python3
"""Build the server-only neighborhood QuestionBank from a pinned ABVM snapshot."""
from __future__ import annotations
import argparse, collections, hashlib, json, re, subprocess
from pathlib import Path

REV="aa2fe3fbcb9b25205948073ee284b96910733d79"
EXPECTED_FILES={
    "data/study-pack.json":"88a12e26228287349c6eeadfd0682a5b073bba9862d7dac0e709be06b2a67c31",
    "data/schoolwork.json":"39526716b06113d22dbee60bb2f14d39239679f6891ea7ee9af4037305023927",
    "data/study-archive.json":"c84e09f01f05a37b93a655937292065dc4a2be046a8c0dbdaf9f0e186b7a283d",
    "star-practice.mjs":"a3ec7572069f91aa32b91aa32b91aa32b91aa32b91aa32b91aa32b91aa32b91",
}
# Correct hash kept separately to make accidental edits obvious.
EXPECTED_FILES["star-practice.mjs"]="a3ec7572069f91aa32b91f271b74bd84076da107eb3193b0f6be3b34b968632e"

ROOM_TO_SUBJECT={
    "Math":"math","Reading":"reading","Grammar":"grammar",
    "Religion":"religion","Vocabulary":"vocabulary","Spelling":"spelling",
}

def room_for(row:dict)->str:
    subject=str(row.get("subject","")).lower()
    skill=str(row.get("skill","")).lower()
    if "math" in subject: return "Math"
    if "religion" in subject: return "Religion"
    if any(x in skill for x in ("grammar","predicate","subject-predicate","sentence","punctuation","capital","noun","verb")): return "Grammar"
    if any(x in skill for x in ("vocabulary","context","synonym","antonym","word-meaning")): return "Vocabulary"
    if "spelling" in subject or any(x in skill for x in ("vowel","phonics","blend","cvc","suffix","syllable","ending","consonant","silent")): return "Spelling"
    if "read" in subject or "ela" in subject: return "Reading"
    raise ValueError("unmapped subject")

def q(value:str)->str:
    return json.dumps(value,ensure_ascii=False)

def main()->int:
    ap=argparse.ArgumentParser()
    ap.add_argument("source",type=Path)
    ap.add_argument("--out",type=Path,required=True)
    ap.add_argument("--receipt",type=Path,required=True)
    args=ap.parse_args()
    source=args.source

    for relative,expected in EXPECTED_FILES.items():
        actual=hashlib.sha256((source/relative).read_bytes()).hexdigest()
        if actual!=expected:
            raise SystemExit(f"Pinned ABVM artifact mismatch: {relative}: {actual}")

    pack=json.loads((source/"data/study-pack.json").read_text())["pack"]
    work=json.loads((source/"data/schoolwork.json").read_text())
    archive=json.loads((source/"data/study-archive.json").read_text())
    module=(source/"star-practice.mjs").resolve().as_uri()
    js="import {buildStarBank} from "+json.dumps(module)+";console.log(JSON.stringify(buildStarBank()));"
    star=json.loads(subprocess.check_output(["node","--input-type=module","-e",js],text=True))
    pools=[
        ("current",pack["contentPipeline"]["questions"]),
        ("worksheet",[item for lesson in work["lessons"] for item in lesson.get("questions",[])]),
        ("archive",archive["questions"]),
        ("practice",star),
    ]

    output=[];seen={};rejected=[];duplicates=0
    for origin,rows in pools:
        for row in rows:
            try:
                room=room_for(row)
                subject=ROOM_TO_SUBJECT[room]
                prompt=str(row["prompt"]).strip()
                choices=[str(c).strip() for c in row["choices"]]
                answer=str(row["answer"]).strip()
                if not 8<=len(prompt)<=1400: raise ValueError("prompt length")
                if not 2<=len(choices)<=4: raise ValueError("choice count")
                if any(not c for c in choices) or len({c.casefold() for c in choices})!=len(choices): raise ValueError("duplicate/empty choice")
                if choices.count(answer)!=1: raise ValueError("answer not unique in choices")
                if re.search(r"current .*page|upcoming test|what day|when is .*test",prompt,re.I): raise ValueError("schedule/meta question")
                explanation=str(row.get("explanation","")).strip()
                hint=str(row.get("hint","")).strip()
                if len(explanation)<6: raise ValueError("explanation missing")
                if len(hint)<4: raise ValueError("hint missing")
                stem=(room,re.sub(r"\s+"," ",prompt).casefold())
                if stem in seen:
                    if seen[stem]!=answer.casefold(): raise ValueError("conflicting answer for same prompt")
                    duplicates+=1;continue
                seen[stem]=answer.casefold()
                fingerprint=hashlib.sha256((room+"\0"+stem[1]+"\0"+answer.casefold()).encode()).hexdigest()
                ident="abvm-"+fingerprint[:20]
                difficulty=row.get("difficulty",2)
                if isinstance(difficulty,str): difficulty={"easy":1,"medium":2,"hard":3}.get(difficulty,2)
                output.append({
                    "id":ident,"subject":subject,"room":room,
                    "skill":str(row.get("skill",room)),
                    "prompt":prompt,"choices":choices,"answer":choices.index(answer)+1,
                    "explanation":explanation,"hint":hint,
                    "difficulty":max(1,min(3,int(difficulty))),
                    "sourceTier":origin,"sourceId":str(row.get("id","")),
                })
            except (KeyError,TypeError,ValueError) as exc:
                rejected.append({"sourceTier":origin,"sourceId":str(row.get("id","")),"reason":str(exc)})

    counts=collections.Counter(x["room"] for x in output)
    required=("Math","Reading","Grammar","Religion","Vocabulary","Spelling")
    if not all(counts[r]>=10 for r in required):
        raise SystemExit(f"Insufficient subject coverage: {dict(counts)}")
    if len(output)!=338:
        raise SystemExit(f"Expected 338 imported questions, got {len(output)}")

    lines=[
        "--!strict",
        "-- Generated from pinned ABVM curriculum sources. SERVER ONLY.",
        "local bank={",
        '    Source={repository="P00NSMASHER/abvmschoolstarworld",commit="'+REV+'",grade=2,scope="Pinned curriculum-only import; no roster, email, student identity, progress, calendar or worksheet-image metadata.",officialStarItems=false},',
        "    Questions={}",
        "}",
        "local function add(id,subject,room,skill,prompt,choices,answer,explanation,hint,difficulty,sourceTier,sourceId)",
        "    table.insert(bank.Questions,{id=id,subject=subject,room=room,skill=skill,prompt=prompt,choices=choices,answer=answer,explanation=explanation,hint=hint,difficulty=difficulty,sourceTier=sourceTier,sourceId=sourceId})",
        "end",
    ]
    for item in output:
        choices="{"+",".join(q(c) for c in item["choices"])+"}"
        lines.append(
            "add("+",".join([
                q(item["id"]),q(item["subject"]),q(item["room"]),q(item["skill"]),
                q(item["prompt"]),choices,str(item["answer"]),q(item["explanation"]),
                q(item["hint"]),str(item["difficulty"]),q(item["sourceTier"]),q(item["sourceId"]),
            ])+")"
        )
    lines.append("return bank")
    content="\n".join(lines)+"\n"
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(content)

    receipt={
        "sourceRepository":"P00NSMASHER/abvmschoolstarworld",
        "sourceCommit":REV,
        "sourceBankFingerprint":pack["contentPipeline"]["bankFingerprint"],
        "rawPoolCounts":{name:len(rows) for name,rows in pools},
        "imported":len(output),
        "rooms":dict(sorted(counts.items())),
        "duplicatePromptsRemoved":duplicates,
        "excluded":rejected,
        "sourceFilesSha256":{p:hashlib.sha256((source/p).read_bytes()).hexdigest() for p in EXPECTED_FILES},
        "outputSha256":hashlib.sha256(content.encode()).hexdigest(),
        "privateMetadataExported":False,
        "officialStarItems":False,
        "validation":"schema, answer membership, unique choices/prompts, pinned file hashes and deterministic provenance; not a replacement for independent content review",
    }
    args.receipt.parent.mkdir(parents=True,exist_ok=True)
    args.receipt.write_text(json.dumps(receipt,indent=2)+"\n")
    print(json.dumps(receipt,indent=2))
    return 0

if __name__=="__main__":
    raise SystemExit(main())
