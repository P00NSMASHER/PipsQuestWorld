#!/usr/bin/env python3
from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path

CATEGORY_BY_PROPERTY = {
    "MeshId": "mesh",
    "MeshContent": "mesh",
    "TextureId": "texture",
    "Texture": "texture",
    "TextureContent": "texture",
    "BaseTextureContent": "texture",
    "Image": "ui_image",
    "ImageContent": "ui_image",
    "TopImageContent": "ui_image",
    "MidImageContent": "ui_image",
    "BottomImageContent": "ui_image",
    "SoundId": "sound",
    "AudioContent": "sound",
    "AnimationId": "animation",
    "AnimationContent": "animation",
    "ShirtTemplate": "clothing",
    "PantsTemplate": "clothing",
    "Graphic": "clothing",
    "SkyboxBk": "sky",
    "SkyboxDn": "sky",
    "SkyboxFt": "sky",
    "SkyboxLf": "sky",
    "SkyboxRt": "sky",
    "SkyboxUp": "sky",
}

PRIORITY_WEIGHT = {
    "startup_surface": 1000,
    "player_backpack": 250,
    "runtime_storage": 100,
    "other": 10,
}

def classify_asset(rec: dict) -> str:
    props = rec.get("propertyNames") or {}
    scored = collections.Counter()
    for name, count in props.items():
        scored[CATEGORY_BY_PROPERTY.get(name, "other")] += int(count)
    return scored.most_common(1)[0][0] if scored else "unknown"

def impact_score(rec: dict) -> int:
    priorities = rec.get("priorities") or {}
    weighted = sum(PRIORITY_WEIGHT.get(k, 1) * int(v) for k, v in priorities.items())
    return weighted + int(rec.get("referenceCount", 0))

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    ap.add_argument("--probe", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--top", type=int, default=100)
    args = ap.parse_args()

    asset_map = json.loads(Path(args.map).read_text(encoding="utf-8"))
    probe = json.loads(Path(args.probe).read_text(encoding="utf-8"))

    map_by_id = {a["assetId"]: a for a in asset_map["assets"]}
    probe_by_id = {a["assetId"]: a for a in probe["results"]}

    terminal_non_public_classes = {
        "auth_required",
        "forbidden_anonymous",
        "not_found",
        "api_error_payload",
        "other_http",
    }
    transient_classes = {
        "rate_limited",
        "timeout",
        "network_error",
        "probe_exception",
        "not_probed",
    }

    rows = []
    indeterminate = []
    for asset_id, mapped in map_by_id.items():
        pr = probe_by_id.get(asset_id) or {}
        classification = pr.get("classification", "not_probed")
        if classification == "public_anonymous":
            continue

        category = classify_asset(mapped)
        refs = mapped.get("references") or []
        sample_refs = []
        for ref in refs[:15]:
            sample_refs.append({
                "path": ref.get("path"),
                "class": ref.get("class"),
                "property": ref.get("property"),
                "priority": ref.get("priority"),
                "value": ref.get("value"),
            })

        row = {
            "assetId": asset_id,
            "classification": classification,
            "httpStatus": pr.get("httpStatus"),
            "category": category,
            "impactScore": impact_score(mapped),
            "referenceCount": mapped.get("referenceCount", 0),
            "priorities": mapped.get("priorities", {}),
            "propertyNames": mapped.get("propertyNames", {}),
            "classes": mapped.get("classes", {}),
            "sampleReferences": sample_refs,
        }

        if classification in transient_classes:
            indeterminate.append(row)
            continue
        if classification not in terminal_non_public_classes:
            indeterminate.append(row)
            continue
        rows.append(row)

    rows.sort(key=lambda r: (-r["impactScore"], -r["referenceCount"], int(r["assetId"])))
    indeterminate.sort(key=lambda r: (-r["impactScore"], -r["referenceCount"], int(r["assetId"])))

    by_category = {}
    by_classification = {}
    by_priority_category = {}
    for row in rows:
        by_category[row["category"]] = by_category.get(row["category"], 0) + 1
        by_classification[row["classification"]] = by_classification.get(row["classification"], 0) + 1
        for priority in row["priorities"]:
            bucket = by_priority_category.setdefault(priority, {})
            bucket[row["category"]] = bucket.get(row["category"], 0) + 1

    startup = [r for r in rows if "startup_surface" in r["priorities"]]
    startup_refs = sum(int(r["priorities"].get("startup_surface", 0)) for r in startup)
    indeterminate_startup = [r for r in indeterminate if "startup_surface" in r["priorities"]]
    indeterminate_startup_refs = sum(
        int(r["priorities"].get("startup_surface", 0))
        for r in indeterminate_startup
    )

    report = {
        "schemaVersion": 1,
        "scope": "Impact ranking of non-public-anonymous external asset references. This does not prove authorized Roblox runtime loading will fail.",
        "workingBuildSha256": asset_map["workingBuildSha256"],
        "summary": {
            "nonPublicAnonymousAssetIds": len(rows),
            "nonPublicAnonymousStartupAssetIds": len(startup),
            "nonPublicAnonymousStartupReferences": startup_refs,
            "indeterminateAssetIds": len(indeterminate),
            "indeterminateStartupAssetIds": len(indeterminate_startup),
            "indeterminateStartupReferences": indeterminate_startup_refs,
            "countsByCategory": dict(sorted(by_category.items())),
            "countsByClassification": dict(sorted(by_classification.items())),
            "countsByPriorityAndCategory": {
                k: dict(sorted(v.items())) for k, v in sorted(by_priority_category.items())
            },
        },
        "priorityOrder": rows[: max(1, args.top)],
        "indeterminatePriorityOrder": indeterminate[: max(1, args.top)],
    }

    Path(args.output).write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print("=== RHS_ASSET_IMPACT_REPORT ===")
    print("NON_PUBLIC_ASSETS", len(rows))
    print("STARTUP_ASSETS", len(startup))
    print("STARTUP_REFERENCES", startup_refs)
    print("INDETERMINATE_ASSETS", len(indeterminate))
    print("INDETERMINATE_STARTUP_ASSETS", len(indeterminate_startup))
    print("INDETERMINATE_STARTUP_REFERENCES", indeterminate_startup_refs)
    for category, count in sorted(by_category.items()):
        print("CATEGORY", category, count)
    for row in rows[: min(args.top, 100)]:
        props = ",".join(f"{k}:{v}" for k, v in sorted(row["propertyNames"].items()))
        classes = ",".join(f"{k}:{v}" for k, v in sorted(row["classes"].items()))
        print(
            "IMPACT",
            row["assetId"],
            row["classification"],
            "http=" + str(row["httpStatus"]),
            "category=" + row["category"],
            "score=" + str(row["impactScore"]),
            "refs=" + str(row["referenceCount"]),
            "priorities=" + json.dumps(row["priorities"], sort_keys=True, separators=(",", ":")),
            "properties=" + props,
            "classes=" + classes,
        )
        for ref in row["sampleReferences"][:3]:
            print(
                "REF",
                row["assetId"],
                ref["priority"],
                ref["class"],
                ref["property"],
                ref["path"],
            )
    print("=== END_RHS_ASSET_IMPACT_REPORT ===")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
