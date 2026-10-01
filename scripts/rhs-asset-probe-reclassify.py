#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path

CODE_CLASS = {
    401: "auth_required",
    403: "forbidden_anonymous",
    404: "not_found",
}

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--output", required=True)
    args=ap.parse_args()

    data=json.loads(Path(args.input).read_text(encoding="utf-8"))
    changed=[]
    for row in data.get("results", []):
        before=row.get("classification")
        errors=row.get("responseErrors") or []
        after=before
        if before == "api_error_payload" and errors:
            try:
                code=int(errors[0].get("code"))
            except (TypeError, ValueError):
                code=None
            after=CODE_CLASS.get(code, before)
        if after != before:
            row["classification"]=after
            changed.append({
                "assetId":row.get("assetId"),
                "before":before,
                "after":after,
                "responseErrors":errors,
            })

    counts=collections.Counter(r.get("classification") for r in data.get("results", []))
    priority=collections.defaultdict(collections.Counter)
    for row in data.get("results", []):
        for p in row.get("priorities") or {}:
            priority[p][row.get("classification")] += 1

    terminal={
        "auth_required","forbidden_anonymous","not_found","api_error_payload","other_http",
    }
    transient={"rate_limited","timeout","network_error","probe_exception"}
    unresolved=[r for r in data.get("results", []) if r.get("classification") in terminal]
    indeterminate=[r for r in data.get("results", []) if r.get("classification") in transient]

    data["schemaVersion"]=3
    data["reclassification"]={
        "source":"Existing run evidence only; no new Roblox requests.",
        "changedCount":len(changed),
        "changesByNewClass":dict(sorted(collections.Counter(x["after"] for x in changed).items())),
        "changes":changed,
    }
    data["summary"]={
        **(data.get("summary") or {}),
        "classificationCounts":dict(sorted(counts.items())),
        "classificationCountsByPriority":{
            k:dict(sorted(v.items())) for k,v in sorted(priority.items())
        },
        "nonPublicAnonymous":len(unresolved),
        "indeterminate":len(indeterminate),
    }

    Path(args.output).write_text(json.dumps(data,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("=== RHS_ASSET_PROBE_RECLASSIFY ===")
    print("CHANGED",len(changed))
    for k,v in sorted(collections.Counter(x["after"] for x in changed).items()):
        print("RECLASSIFIED",k,v)
    for k,v in sorted(counts.items()):
        print("CLASSIFICATION",k,v)
    print("NON_PUBLIC_ANONYMOUS",len(unresolved))
    print("INDETERMINATE",len(indeterminate))
    print("=== END_RHS_ASSET_PROBE_RECLASSIFY ===")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
