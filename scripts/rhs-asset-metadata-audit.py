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

URL = "https://apis.roblox.com/toolbox-service/v2/assets/{asset_id}"

def find_first(obj, wanted):
    if isinstance(obj, dict):
        for key, value in obj.items():
            if key in wanted and value not in (None, "", [], {}):
                return value
        for value in obj.values():
            found = find_first(value, wanted)
            if found not in (None, "", [], {}):
                return found
    elif isinstance(obj, list):
        for value in obj:
            found = find_first(value, wanted)
            if found not in (None, "", [], {}):
                return found
    return None

def compact_creator(payload):
    creator = find_first(payload, {"creator", "Creator"})
    if isinstance(creator, dict):
        return {
            "id": creator.get("id") or creator.get("Id") or creator.get("creatorId"),
            "name": creator.get("name") or creator.get("Name") or creator.get("creatorName"),
            "type": creator.get("type") or creator.get("Type") or creator.get("creatorType"),
        }
    return {
        "id": find_first(payload, {"creatorId", "creator_id", "CreatorId"}),
        "name": find_first(payload, {"creatorName", "creator_name", "CreatorName"}),
        "type": find_first(payload, {"creatorType", "creator_type", "CreatorType"}),
    }

def probe(asset_id: str, timeout: float, retries: int, interval: float) -> dict:
    attempts = 0
    last = {}
    for attempt in range(retries + 1):
        if interval:
            time.sleep(interval)
        attempts += 1
        req = urllib.request.Request(
            URL.format(asset_id=asset_id),
            headers={
                "Accept": "application/json",
                "User-Agent": "PipsQuestWorld-RHS-Asset-Metadata-Audit/1.0",
            },
            method="GET",
        )
        status = None
        body = b""
        headers = {}
        error = None
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                status = getattr(resp, "status", None)
                headers = dict(resp.headers.items())
                body = resp.read(262144)
        except urllib.error.HTTPError as exc:
            status = exc.code
            headers = dict(exc.headers.items()) if exc.headers else {}
            try:
                body = exc.read(262144)
            except Exception:
                body = b""
            error = str(exc)
        except (urllib.error.URLError, socket.timeout, TimeoutError, OSError) as exc:
            error = str(exc)

        payload = None
        if body:
            try:
                payload = json.loads(body.decode("utf-8", "replace"))
            except Exception:
                payload = None

        if status == 200 and isinstance(payload, dict):
            classification = "metadata_public"
        elif status == 404:
            classification = "no_public_creator_store_listing"
        elif status in (401, 403):
            classification = "metadata_restricted"
        elif status == 429:
            classification = "rate_limited"
        elif status is None:
            classification = "network_error"
        else:
            classification = "other_http"

        last = {
            "assetId": asset_id,
            "classification": classification,
            "httpStatus": status,
            "attempts": attempts,
            "error": error,
            "responseBytes": len(body),
            "contentType": headers.get("Content-Type") or headers.get("content-type"),
            "retryAfter": headers.get("Retry-After") or headers.get("retry-after"),
            "payload": payload if isinstance(payload, dict) else None,
        }

        if classification != "rate_limited" or attempt >= retries:
            break
        try:
            wait = float(last["retryAfter"] or 0)
        except (TypeError, ValueError):
            wait = 0
        time.sleep(max(wait, min(8.0, 2 ** attempt)))

    payload = last.get("payload") or {}
    if last["classification"] == "metadata_public":
        asset = payload.get("asset") if isinstance(payload.get("asset"), dict) else {}
        creator = payload.get("creator") if isinstance(payload.get("creator"), dict) else {}
        product = (
            payload.get("creatorStoreProduct")
            if isinstance(payload.get("creatorStoreProduct"), dict)
            else {}
        )
        last["metadata"] = {
            "name": asset.get("name") or asset.get("title"),
            "title": asset.get("title"),
            "assetTypeId": asset.get("assetTypeId"),
            "audioType": asset.get("audioType"),
            "durationSeconds": asset.get("durationSeconds"),
            "artist": asset.get("artist"),
            "description": asset.get("description"),
            "createTime": asset.get("createTime"),
            "updateTime": asset.get("updateTime"),
            "creator": {
                "resource": creator.get("creator"),
                "userId": creator.get("userId"),
                "groupId": creator.get("groupId"),
                "name": creator.get("name"),
                "verified": creator.get("verified"),
            },
            "creatorStore": {
                "purchasable": product.get("purchasable"),
                "purchasePrice": product.get("purchasePrice"),
            },
        }
        last["publicMetadataPayload"] = None
    else:
        last["metadata"] = None
        last["publicMetadataPayload"] = None

    last.pop("payload", None)
    return last

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--impact", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--top", type=int, default=100)
    ap.add_argument("--timeout", type=float, default=10)
    ap.add_argument("--retries", type=int, default=3)
    ap.add_argument("--interval", type=float, default=0.2)
    args = ap.parse_args()

    impact = json.loads(Path(args.impact).read_text(encoding="utf-8"))
    priority = list(impact.get("priorityOrder") or [])[: max(1, args.top)]

    results = []
    for idx, row in enumerate(priority, 1):
        asset_id = str(row["assetId"])
        result = probe(asset_id, args.timeout, args.retries, args.interval)
        result["impactRank"] = idx
        result["impactScore"] = row.get("impactScore")
        result["category"] = row.get("category")
        result["referenceCount"] = row.get("referenceCount")
        result["priorities"] = row.get("priorities")
        result["sampleReferences"] = row.get("sampleReferences")
        results.append(result)

    counts = Counter(r["classification"] for r in results)
    identified = [r for r in results if r["classification"] == "metadata_public"]

    report = {
        "schemaVersion": 1,
        "scope": (
            "Public metadata lookup only against Roblox's documented Creator Store "
            "asset-details endpoint. No authenticated access and no asset content retrieval."
        ),
        "sourceAssetSurvivabilityRunId": 36871253438,
        "sourceArtifactId": 11168394358,
        "workingBuildSha256": impact.get("workingBuildSha256"),
        "endpoint": "https://apis.roblox.com/toolbox-service/v2/assets/<id>",
        "selectedTopImpactCount": len(priority),
        "summary": {
            "classificationCounts": dict(sorted(counts.items())),
            "publicMetadataIdentified": len(identified),
        },
        "results": results,
    }
    Path(args.output).write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    print("=== RHS_ASSET_METADATA_AUDIT ===")
    print("SELECTED", len(priority))
    for key, value in sorted(counts.items()):
        print("CLASSIFICATION", key, value)
    for result in identified[:100]:
        meta = result.get("metadata") or {}
        creator = meta.get("creator") or {}
        print(
            "IDENTIFIED",
            result["assetId"],
            "rank=" + str(result["impactRank"]),
            "category=" + str(result["category"]),
            "name=" + json.dumps(meta.get("name"), ensure_ascii=False),
            "assetTypeId=" + json.dumps(meta.get("assetTypeId"), ensure_ascii=False),
            "creator=" + json.dumps(creator.get("name"), ensure_ascii=False),
            "creatorId=" + json.dumps(creator.get("userId") or creator.get("groupId"), ensure_ascii=False),
        )
    print("=== END_RHS_ASSET_METADATA_AUDIT ===")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
