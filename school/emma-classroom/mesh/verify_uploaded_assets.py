#!/usr/bin/env python3
"""Read-only verification of Roblox's OWN metadata for approved ABVM furniture.

No asset creation, game deployment or credential printing. Compare the
published asset IDs, creator identity, moderation, and type to the exact
authorization receipt and the live universe-to-place mapping.
"""
from __future__ import annotations
import json
import os
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

HERE = Path(__file__).resolve().parent
MANIFEST = HERE / "imported_models.json"


def fetch(url: str, api_key: str | None = None) -> dict:
    headers = {"Accept": "application/json"}
    if api_key is not None:
        headers["x-api-key"] = api_key
    try:
        with urlopen(Request(url, headers=headers, method="GET"), timeout=25) as response:
            if response.status != 200:
                raise RuntimeError("Unexpected HTTP status " + str(response.status))
            return json.load(response)
    except HTTPError as exc:
        # Do not print body/headers. Never print a token.
        raise RuntimeError("Roblox metadata access HTTP " + str(exc.code)) from None
    except URLError:
        raise RuntimeError("Roblox metadata endpoint unreachable") from None


def verify() -> None:
    data = json.loads(MANIFEST.read_text())
    assert data["productionEnabled"] is False, "Production model use is not authorized"
    assert data["source"]["githubRunId"] == 37813670543
    creator = data["creator"]
    assert creator["type"] == "User" and creator["userId"] == "6064228083"
    universe_id, place_id = data["universeId"], data["rootPlaceId"]
    universe = fetch(f"https://develop.roblox.com/v1/universes/{universe_id}")
    place = fetch(f"https://apis.roblox.com/universes/v1/places/{place_id}/universe")
    if (str(universe.get("id")) != universe_id
        or str(universe.get("rootPlaceId")) != place_id
        or str(universe.get("creatorTargetId")) != creator["userId"]
        or universe.get("creatorType", "").lower() != "user"
        or str(place.get("universeId")) != universe_id):
        raise RuntimeError("Live Roblox universe/place/creator ownership mismatch")
    print("ASSET_VERIFICATION_CREATOR_CONFIRMED", creator["userId"], flush=True)

    token = os.environ.get("ROBLOX_ASSET_API_KEY", "").strip()
    if len(token) < 20:
        raise RuntimeError("Dedicated Assets API key missing; do not substitute publish credentials")

    approved = {"Approved", "MODERATION_STATE_APPROVED"}
    allowed_types = {"Model", "ASSET_TYPE_MODEL"}
    expected_names = {"abvm_student_chair", "abvm_student_desk"}
    assets = data.get("assets", [])
    if len(assets) != 2 or {item["name"] for item in assets} != expected_names:
        raise RuntimeError("Receipt must contain exactly two original furniture models")
    # Imported model IDs may be staged in the source, but their runtime must
    # remain disabled until actual Roblox/iPhone visual acceptance.
    config=(HERE.parent/"showroom/FurnitureMeshConfig.lua").read_text()
    if "Enabled = false" not in config:
        raise RuntimeError("Roblox models enabled without engine acceptance")
    config_fields={
        "abvm_student_chair": "ChairModelAssetId",
        "abvm_student_desk": "DeskModelAssetId",
    }
    import re
    for item in assets:
        field=config_fields[item["name"]]
        match=re.search(r"(?m)^\s*"+re.escape(field)+r"\s*=\s*(\d+)\s*,?\s*$",config)
        if not match or match.group(1)!=item["assetId"]:
            raise RuntimeError("Configured asset ID does not match independently verified receipt")
    if len({item["assetId"] for item in assets}) != 2:
        raise RuntimeError("Duplicate asset ID in receipt")
    for item in assets:
        asset_id = item["assetId"]
        if not str(asset_id).isdigit() or int(asset_id) <= 0:
            raise RuntimeError("Invalid imported asset ID")
        if item["operationModeration"] not in approved:
            raise RuntimeError("Asset operation did not report approval")
        asset = fetch(f"https://apis.roblox.com/assets/v1/assets/{asset_id}", token)
        if str(asset.get("assetId", "")) != asset_id:
            raise RuntimeError("Asset ID mismatch in metadata")
        kind = str(asset.get("assetType", ""))
        if kind not in allowed_types:
            raise RuntimeError("Uploaded Roblox asset is not a Model")
        actual_creator = (asset.get("creationContext") or {}).get("creator") or {}
        if str(actual_creator.get("userId", "")) != creator["userId"]:
            raise RuntimeError("Roblox asset's own creator differs from game owner")
        moderation = str((asset.get("moderationResult") or {}).get("moderationState", ""))
        if moderation not in approved:
            raise RuntimeError("Roblox direct asset moderation is not approved")
        print(
            "ASSET_METADATA_VERIFIED",
            item["name"],
            "asset_id", asset_id,
            "creator", creator["userId"],
            "moderation", moderation,
            flush=True,
        )
    print("TWO_ASSETS_VERIFIED_READ_ONLY_GAME_UNCHANGED", flush=True)


if __name__ == "__main__":
    try:
        verify()
    except (KeyError, AssertionError, ValueError, RuntimeError) as exc:
        print("ASSET_METADATA_VERIFICATION_BLOCKED", str(exc), file=sys.stderr)
        raise SystemExit(1)
