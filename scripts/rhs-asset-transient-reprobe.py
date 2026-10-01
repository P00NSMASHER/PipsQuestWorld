#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import socket
import time
import urllib.error
import urllib.request
from collections import Counter
from pathlib import Path

URL = "https://assetdelivery.roblox.com/v2/assetId/{asset_id}"

def classify(status, body, error):
    payload=None
    try:
        payload=json.loads(body.decode("utf-8","replace")) if body else None
    except Exception:
        payload=None
    if isinstance(payload,dict) and payload.get("errors"):
        first=payload["errors"][0] if payload["errors"] else {}
        try:
            code=int(first.get("code"))
        except (TypeError,ValueError,AttributeError):
            code=None
        if code == 401:
            return "auth_required"
        if code == 403:
            return "forbidden_anonymous"
        if code == 404:
            return "not_found"
        return "api_error_payload"
    if status in (200,206):
        return "public_anonymous"
    if status == 401:
        return "auth_required"
    if status == 403:
        return "forbidden_anonymous"
    if status == 404:
        return "not_found"
    if status == 429:
        return "rate_limited"
    if status is None:
        return "network_error"
    return "other_http"

def probe(asset_id: str, timeout: float, retries: int, interval: float):
    last={}
    for attempt in range(retries+1):
        time.sleep(interval)
        req=urllib.request.Request(
            URL.format(asset_id=asset_id),
            headers={
                "Accept":"application/json,*/*",
                "User-Agent":"PipsQuestWorld-RHS-Transient-Asset-Reprobe/1.0",
            },
        )
        status=None; body=b""; error=None; headers={}
        try:
            with urllib.request.urlopen(req,timeout=timeout) as resp:
                status=getattr(resp,"status",None)
                headers=dict(resp.headers.items())
                body=resp.read(4096)
        except urllib.error.HTTPError as exc:
            status=exc.code
            headers=dict(exc.headers.items()) if exc.headers else {}
            try: body=exc.read(4096)
            except Exception: body=b""
            error=str(exc)
        except (urllib.error.URLError,socket.timeout,TimeoutError,OSError) as exc:
            error=str(exc)

        cls=classify(status,body,error)
        response_errors=[]
        if body:
            try:
                payload=json.loads(body.decode("utf-8","replace"))
                for e in (payload.get("errors") or [])[:10]:
                    if isinstance(e,dict):
                        response_errors.append({"code":e.get("code"),"message":e.get("message")})
            except Exception:
                pass

        last={
            "classification":cls,
            "httpStatus":status,
            "responseErrors":response_errors,
            "bodyPrefix":body[:256].decode("utf-8","replace"),
            "error":error,
            "retryCount":attempt,
        }
        if cls != "rate_limited":
            return last
        retry_after=headers.get("Retry-After") or headers.get("retry-after")
        try: extra=float(retry_after or 0)
        except (TypeError,ValueError): extra=0
        time.sleep(max(extra,min(16.0,2**attempt)))
    return last

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--input",required=True)
    ap.add_argument("--output",required=True)
    ap.add_argument("--timeout",type=float,default=10)
    ap.add_argument("--retries",type=int,default=5)
    ap.add_argument("--interval",type=float,default=1.0)
    args=ap.parse_args()

    data=json.loads(Path(args.input).read_text(encoding="utf-8"))
    targets=[r for r in data.get("results",[]) if r.get("classification")=="rate_limited"]
    changes=[]
    for row in targets:
        fresh=probe(str(row["assetId"]),args.timeout,args.retries,args.interval)
        before=row.get("classification")
        for key in ("classification","httpStatus","responseErrors","bodyPrefix","error","retryCount"):
            row[key]=fresh.get(key)
        changes.append({
            "assetId":row.get("assetId"),
            "before":before,
            "after":row.get("classification"),
            "httpStatus":row.get("httpStatus"),
            "responseErrors":row.get("responseErrors"),
        })

    counts=Counter(r.get("classification") for r in data.get("results",[]))
    data["transientReprobe"]={
        "targetCount":len(targets),
        "intervalSeconds":args.interval,
        "maxRetries":args.retries,
        "changes":changes,
        "finalClassificationCounts":dict(sorted(counts.items())),
    }
    data["summary"]={
        **(data.get("summary") or {}),
        "classificationCounts":dict(sorted(counts.items())),
        "indeterminate":sum(1 for r in data.get("results",[]) if r.get("classification") in {
            "rate_limited","timeout","network_error","probe_exception"
        }),
    }
    Path(args.output).write_text(json.dumps(data,indent=2,sort_keys=True)+"\n",encoding="utf-8")

    print("=== RHS_ASSET_TRANSIENT_REPROBE ===")
    print("TARGETS",len(targets))
    for change in changes:
        print(
            "REPROBE",
            change["assetId"],
            change["before"]+"->"+str(change["after"]),
            "http="+str(change["httpStatus"]),
            "errors="+json.dumps(change["responseErrors"],separators=(",",":")),
        )
    for k,v in sorted(counts.items()):
        print("FINAL_CLASSIFICATION",k,v)
    print("FINAL_INDETERMINATE",data["summary"]["indeterminate"])
    print("=== END_RHS_ASSET_TRANSIENT_REPROBE ===")

if __name__=="__main__":
    main()
