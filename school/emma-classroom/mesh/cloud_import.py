#!/usr/bin/env python3
"""One-shot authorized Open Cloud model import. No Roblox game publication.

Requires an explicitly scoped GitHub Actions secret. Uses only creator identity
retrieved from the target Roblox universe via Roblox's public API. Never logs
API tokens and never attempts arbitrary assets or Roblox place publishing.
"""
import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

import requests

UNIVERSE_ID = 10769455759
MODEL_NAMES = ("abvm_student_chair", "abvm_student_desk")
BASE = "https://apis.roblox.com/assets/v1"


def owner():
    response = requests.get(
        "https://games.roblox.com/v1/games",
        params={"universeIds": str(UNIVERSE_ID)}, timeout=20
    )
    response.raise_for_status()
    record = next(
        (r for r in response.json().get("data", [])
         if int(r.get("id", 0)) == UNIVERSE_ID), None
    )
    if not record:
        raise RuntimeError("Cannot independently verify the owner of the target Roblox universe")
    creator = record.get("creator", {})
    creator_id = int(creator.get("id", 0))
    creator_type = str(creator.get("type", "")).lower()
    if creator_id <= 0 or creator_type not in ("user", "group"):
        raise RuntimeError("Unrecognized Roblox creator type or ID: import prohibited")
    return {"userId" if creator_type == "user" else "groupId": str(creator_id)}


def import_model(key, creator, path, session):
    if not path.is_file() or path.stat().st_size < 1024 or path.stat().st_size > 20_000_000:
        raise RuntimeError("Missing/invalid model payload")
    label = path.stem
    if label not in MODEL_NAMES:
        raise RuntimeError("Model filename outside original ABVM allowlist")
    request = {
        "assetType": "Model",
        "displayName": "ABVM Original " + label.replace("_", " ").title(),
        "description": "Original child-scale classroom furniture geometry, no scripts. ABVM classroom project.",
        "creationContext": {"creator": creator}
    }
    with path.open("rb") as f:
        result = session.post(
            BASE+"/assets",
            headers={"x-api-key": key},
            data={"request": json.dumps(request, separators=(",", ":"))},
            files={"fileContent": (path.name, f, "model/gltf-binary")},
            timeout=70
        )
    if result.status_code not in (200, 201):
        # Never print request headers, API token or raw server response.
        raise RuntimeError("Cloud Model import denied: HTTP " + str(result.status_code))
    operation = result.json().get("path", "")
    if not re.fullmatch(r"operations/[A-Za-z0-9_\-]+", operation):
        raise RuntimeError("Unexpected Roblox operation receipt; no asset ID accepted")
    for _ in range(25):
        time.sleep(3)
        status = session.get(BASE+"/"+operation,
                             headers={"x-api-key": key}, timeout=20)
        if status.status_code != 200:
            raise RuntimeError("Cloud operation verification HTTP "+str(status.status_code))
        payload = status.json()
        if payload.get("done") is not True:
            continue
        if payload.get("error"):
            raise RuntimeError("Roblox rejected uploaded GLB during asynchronous processing")
        response = payload.get("response", {})
        asset_id = int(response.get("assetId", 0))
        state = response.get("moderationResult", {}).get("moderationState", "UNAVAILABLE")
        if asset_id <= 0:
            raise RuntimeError("Cloud operation completed without verifiable asset ID")
        return {"asset_id":asset_id, "moderation":state, "name":label,
                "ownership_verified_from_universe":True}
    raise RuntimeError("Roblox import not finished after bounded poll; check operation status separately")


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--folder",type=Path,required=True)
    parser.add_argument("--out",type=Path,required=True)
    opts=parser.parse_args()
    key=os.getenv("ROBLOX_ASSET_API_KEY", "").strip()
    if len(key)<20:
        raise RuntimeError(
            "BLOCKED: ROBLOX_ASSET_API_KEY not available; do not reuse a place-publish key "
            "without confirmed Assets API permissions"
        )
    creator=owner()
    print("VERIFIED_UNIVERSE_CREATOR_TYPE",next(iter(creator)),flush=True)
    import hashlib
    manifest=json.loads((opts.folder/"manifest.json").read_text())
    expected={m["file"]:m["sha256"] for m in manifest["models"]}
    for name in MODEL_NAMES:
        path=opts.folder/(name+".glb")
        if hashlib.sha256(path.read_bytes()).hexdigest()!=expected.get(path.name):
            raise RuntimeError("Cloud import payload hash disagrees with independently generated receipt")
    successes=[]
    session=requests.Session()
    opts.out.parent.mkdir(parents=True,exist_ok=True)
    for name in MODEL_NAMES:
        success=import_model(key,creator,opts.folder/(name+".glb"),session)
        successes.append(success)
        # Persist even partial success to upload artifact (not to repository).
        opts.out.write_text(json.dumps({"universe_id":UNIVERSE_ID,
                                        "creator_type":next(iter(creator)),
                                        "assets":successes},indent=2))
        print("CLOUD_MODEL_CREATED",name,"ID",success["asset_id"],
              "moderation",success["moderation"],flush=True)
    print("TWO_ORIGINAL_MODELS_UPLOADED_NO_GAME_PUBLICATION",flush=True)


if __name__=="__main__":
    try: main()
    except Exception as e:
        print("CLOUD_MODEL_IMPORT_BLOCKED",str(e),file=sys.stderr)
        raise SystemExit(1)
