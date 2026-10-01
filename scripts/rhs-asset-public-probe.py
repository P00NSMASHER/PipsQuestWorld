#!/usr/bin/env python3
from __future__ import annotations

import argparse
import concurrent.futures
import json
import socket
import time
import urllib.error
import urllib.request
from pathlib import Path

URL = "https://assetdelivery.roblox.com/v1/asset/?id={asset_id}"

def classify_status(status: int | None, error: str | None) -> str:
    if status in (200, 206):
        return "public_anonymous"
    if status == 401:
        return "auth_required"
    if status == 403:
        return "forbidden_anonymous"
    if status == 404:
        return "not_found"
    if status == 429:
        return "rate_limited"
    if status is not None:
        return "other_http"
    if error:
        low=error.lower()
        if "timed out" in low or "timeout" in low:
            return "timeout"
    return "network_error"

def probe(asset_id: str, timeout: float) -> dict:
    req=urllib.request.Request(
        URL.format(asset_id=asset_id),
        headers={
            "User-Agent":"PipsQuestWorld-RHS-Compatibility-Audit/1.0",
            "Range":"bytes=0-63",
            "Accept":"*/*",
        },
        method="GET",
    )
    status=None
    final_url=None
    content_type=None
    content_length=None
    first_bytes=""
    error=None
    started=time.monotonic()
    try:
        with urllib.request.urlopen(req,timeout=timeout) as resp:
            status=getattr(resp,"status",None)
            final_url=resp.geturl()
            content_type=resp.headers.get("Content-Type")
            content_length=resp.headers.get("Content-Length")
            first_bytes=resp.read(64).hex()
    except urllib.error.HTTPError as exc:
        status=exc.code
        final_url=exc.geturl()
        content_type=exc.headers.get("Content-Type") if exc.headers else None
        content_length=exc.headers.get("Content-Length") if exc.headers else None
        try:
            first_bytes=exc.read(64).hex()
        except Exception:
            pass
        error=str(exc)
    except (urllib.error.URLError,socket.timeout,TimeoutError,OSError) as exc:
        error=str(exc)
    elapsed_ms=round((time.monotonic()-started)*1000)
    return {
        "assetId":asset_id,
        "classification":classify_status(status,error),
        "httpStatus":status,
        "finalUrl":final_url,
        "contentType":content_type,
        "contentLengthHeader":content_length,
        "firstBytesHex":first_bytes,
        "elapsedMs":elapsed_ms,
        "error":error,
    }

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--map",required=True)
    ap.add_argument("--output",required=True)
    ap.add_argument("--workers",type=int,default=4)
    ap.add_argument("--timeout",type=float,default=8.0)
    args=ap.parse_args()

    asset_map=json.loads(Path(args.map).read_text(encoding="utf-8"))
    refs={a["assetId"]:a for a in asset_map["assets"]}
    ids=sorted(refs,key=int)

    results=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1,args.workers)) as pool:
        futures={pool.submit(probe,asset_id,args.timeout):asset_id for asset_id in ids}
        for future in concurrent.futures.as_completed(futures):
            asset_id=futures[future]
            try:
                result=future.result()
            except Exception as exc:
                result={
                    "assetId":asset_id,
                    "classification":"probe_exception",
                    "httpStatus":None,
                    "finalUrl":None,
                    "contentType":None,
                    "contentLengthHeader":None,
                    "firstBytesHex":"",
                    "elapsedMs":None,
                    "error":repr(exc),
                }
            result["referenceCount"]=refs[asset_id]["referenceCount"]
            result["priorities"]=refs[asset_id]["priorities"]
            result["propertyNames"]=refs[asset_id]["propertyNames"]
            result["classes"]=refs[asset_id]["classes"]
            results.append(result)

    results.sort(key=lambda r:int(r["assetId"]))
    classes={}
    priority_summary={}
    for result in results:
        cls=result["classification"]
        classes[cls]=classes.get(cls,0)+1
        for priority in result["priorities"]:
            bucket=priority_summary.setdefault(priority,{})
            bucket[cls]=bucket.get(cls,0)+1

    unresolved=[
        r for r in results
        if r["classification"] != "public_anonymous"
    ]
    unresolved.sort(key=lambda r:(
        0 if "startup_surface" in r["priorities"] else
        1 if "player_backpack" in r["priorities"] else
        2 if "runtime_storage" in r["priorities"] else 3,
        -r["referenceCount"],
        int(r["assetId"]),
    ))

    report={
        "schemaVersion":1,
        "scope":"Anonymous public asset-delivery probe only. A non-200 result does not prove the asset fails inside an authorized Roblox experience.",
        "workingBuildSha256":asset_map["workingBuildSha256"],
        "probe":{
            "endpoint":"https://assetdelivery.roblox.com/v1/asset/?id=<assetId>",
            "workers":args.workers,
            "timeoutSeconds":args.timeout,
            "range":"bytes=0-63",
        },
        "summary":{
            "probed":len(results),
            "classificationCounts":dict(sorted(classes.items())),
            "classificationCountsByPriority":{
                k:dict(sorted(v.items())) for k,v in sorted(priority_summary.items())
            },
            "nonPublicAnonymous":len(unresolved),
        },
        "results":results,
        "unresolvedPriorityOrder":unresolved,
    }
    Path(args.output).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_ASSET_PUBLIC_PROBE ===")
    print("PROBED",len(results))
    for k,v in sorted(classes.items()):
        print("CLASSIFICATION",k,v)
    for priority,bucket in sorted(priority_summary.items()):
        print("PRIORITY",priority,json.dumps(bucket,sort_keys=True,separators=(",",":")))
    print("NON_PUBLIC_ANONYMOUS",len(unresolved))
    for r in unresolved[:100]:
        print(
            "UNRESOLVED",
            r["assetId"],
            r["classification"],
            "http="+str(r["httpStatus"]),
            "refs="+str(r["referenceCount"]),
            "priorities="+json.dumps(r["priorities"],sort_keys=True,separators=(",",":")),
        )
    print("=== END_RHS_ASSET_PUBLIC_PROBE ===")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
