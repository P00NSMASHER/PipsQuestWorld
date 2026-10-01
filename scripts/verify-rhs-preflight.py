#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def load(rel: str):
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))

errors: list[str] = []

baseline = load("rhs/BASELINE.json")
state = load("rhs/working/BUILD_STATE.json")
manifest = load("rhs/compatibility/PATCH_MANIFEST.json")
preflight = load("rhs/compatibility/PREFLIGHT.json")

baseline_sha = baseline["identity"]["sha256"]
baseline_bytes = baseline["identity"]["bytes"]
working_sha = state["expectedWorkingSha256"]
repairs = list(state.get("compatibilityRepairs") or [])
patch_ids = [p["id"] for p in manifest.get("patches") or []]

if preflight["baseline"]["sha256"] != baseline_sha:
    errors.append("preflight baseline SHA does not match BASELINE.json")
if preflight["baseline"]["bytes"] != baseline_bytes:
    errors.append("preflight baseline byte count does not match BASELINE.json")
if preflight["baseline"].get("immutable") is not True:
    errors.append("preflight baseline must be marked immutable")
if state["baselineSha256"] != baseline_sha:
    errors.append("BUILD_STATE baseline SHA does not match BASELINE.json")
if manifest["baselineSha256"] != baseline_sha:
    errors.append("PATCH_MANIFEST baseline SHA does not match BASELINE.json")
if preflight["working"]["sha256"] != working_sha:
    errors.append("preflight working SHA does not match BUILD_STATE.json")
if preflight["working"]["compatibilityPatchCount"] != len(patch_ids):
    errors.append("preflight patch count does not match PATCH_MANIFEST.json")
if repairs != patch_ids:
    errors.append("BUILD_STATE compatibilityRepairs order/content does not match PATCH_MANIFEST patch ids")
if preflight["working"]["runtimeVerified"] != state["runtimeVerified"]:
    errors.append("preflight runtimeVerified does not match BUILD_STATE.json")
if preflight["working"]["published"] != state["published"]:
    errors.append("preflight published does not match BUILD_STATE.json")

working_path = ROOT / "rhs/working/ROBLOX High School.rbxl"
h = hashlib.sha256()
with working_path.open("rb") as f:
    for chunk in iter(lambda: f.read(1024 * 1024), b""):
        h.update(chunk)
actual_working_sha = h.hexdigest()
if actual_working_sha != working_sha:
    errors.append("working binary SHA does not match BUILD_STATE.json")

baseline_path = ROOT / "rhs/baseline/ROBLOX High School.rbxl"
if baseline_path.stat().st_size != baseline_bytes:
    errors.append("baseline binary byte count does not match BASELINE.json")

if (ROOT / ".github/workflows/bootstrap-rhs-licensed-baseline.yml").exists():
    errors.append("retired RHS bootstrap writer has reappeared")
if (ROOT / ".github/workflows/import-pinned-maze-world.yml").exists():
    errors.append("retired Maze importer has reappeared")

checks = preflight.get("staticChecks") or {}
required_passes = [
    "baselineIntegrity",
    "structuralParity",
    "compatibilityAudit",
    "runtimeSideEffectAudit",
    "startupRiskAudit",
    "activeDirectionGuard",
]
for name in required_passes:
    if checks.get(name) != "PASS":
        errors.append(f"preflight static check is not PASS: {name}")

luau = checks.get("luauSyntax") or {}
if luau.get("status") != "PASS":
    errors.append("preflight Luau syntax status is not PASS")
if luau.get("embeddedScripts") != 1192:
    errors.append("preflight Luau embedded script count changed")
if luau.get("syntaxFailures") != 0:
    errors.append("preflight records Luau syntax failures")

current_api = checks.get("currentApiClassAudit") or {}
if current_api.get("status") != "PASS":
    errors.append("preflight current API class audit is not PASS")
if current_api.get("apiDumpCommit") != "fcd6994996bb655bef047c69f456463d94faa569":
    errors.append("preflight current API class audit is not pinned to the accepted API dump")
if current_api.get("classesPresent") != 121:
    errors.append("preflight current API class count changed")
if current_api.get("classesMissing") != 1:
    errors.append("preflight current API missing-class count changed")
missing_classes = current_api.get("missingClasses") or []
if len(missing_classes) != 1 or missing_classes[0].get("class") != "RenderHooksService":
    errors.append("preflight missing current-API class is not the known RenderHooksService singleton")
elif (
    missing_classes[0].get("instances") != 1
    or missing_classes[0].get("directChildren") != 0
    or missing_classes[0].get("descendants") != 0
    or missing_classes[0].get("scriptReferences") != 0
):
    errors.append("RenderHooksService no longer matches the accepted inert singleton evidence")
if current_api.get("allLegacyMembersPresent") is not True:
    errors.append("preflight records one or more targeted legacy members as absent")

service_api = checks.get("currentServiceApiAudit") or {}
if service_api.get("status") != "PASS":
    errors.append("preflight current service API audit is not PASS")
if service_api.get("apiDumpCommit") != "fcd6994996bb655bef047c69f456463d94faa569":
    errors.append("preflight current service API audit is not pinned to the accepted API dump")
if service_api.get("missingServices") != 0:
    errors.append("preflight current service API audit reports missing services")
if service_api.get("missingMembers") != 0:
    errors.append("preflight current service API audit reports missing service members")


api_check = checks.get("currentRobloxApi") or {}
if api_check.get("status") != "PASS_WITH_NONBLOCKING_SERIALIZED_RESIDUE":
    errors.append("preflight current Roblox API status is not the expected reviewed state")
class_audit = api_check.get("classAudit") or {}
if class_audit.get("classesPresent") != 121 or class_audit.get("classesMissing") != 1:
    errors.append("preflight current Roblox class counts changed")
missing = class_audit.get("missing") or []
if len(missing) != 1:
    errors.append("preflight current Roblox missing-class set changed")
else:
    residue = missing[0]
    if residue.get("class") != "RenderHooksService":
        errors.append("unexpected missing Roblox class in preflight")
    if residue.get("instances") != 1 or residue.get("directChildren") != 0 or residue.get("descendants") != 0:
        errors.append("RenderHooksService residue shape changed")
    if residue.get("propertyNames") != ["Name"] or residue.get("scriptReferences") != 0:
        errors.append("RenderHooksService residue is no longer inert by static evidence")
    if residue.get("blocking") is not False:
        errors.append("RenderHooksService residue must remain marked non-blocking until runtime evidence says otherwise")

service_audit = api_check.get("serviceUseAudit") or {}
if service_audit.get("missingServiceUses") != 0:
    errors.append("preflight records missing Roblox service uses")
if service_audit.get("missingMemberUses") != 0:
    errors.append("preflight records missing Roblox service-member uses")

house_hardening = checks.get("houseFurnitureHardening") or {}
if house_hardening.get("status") != "PASS_BUILD_PARITY":
    errors.append("preflight house/furniture hardening status is not PASS_BUILD_PARITY")
if house_hardening.get("repairId") != "harden-house-furniture-remotes":
    errors.append("preflight house/furniture repair id changed")
if house_hardening.get("targetPath") != "ServerScriptService/CustomHouseScript_NEW":
    errors.append("preflight house/furniture target changed")
if house_hardening.get("baselineSourceSha256") != "5c9e905672a3644ce70d14394202b63283fe9de23e907c336fd8d5275d59227c":
    errors.append("preflight house/furniture baseline source hash changed")
if house_hardening.get("patchedSourceSha256") != "66f73eeb7972411c905289b02cc9052f004251d277870323dfe46cb4f946d016":
    errors.append("preflight house/furniture patched source hash changed")
if house_hardening.get("deterministicReplacementCount") != 8:
    errors.append("preflight house/furniture replacement count changed")
if house_hardening.get("handlerCount") != 11:
    errors.append("preflight house/furniture handler count changed")
if house_hardening.get("contractRunId") != 36895670608:
    errors.append("preflight house/furniture contract run id changed")
if house_hardening.get("runtimeVerified") is not False:
    errors.append("house/furniture hardening must remain runtime-unverified until Studio proof")

painting_hardening = checks.get("paintingRemoteHardening") or {}
if painting_hardening.get("status") != "PASS_BUILD_PARITY":
    errors.append("preflight painting hardening status is not PASS_BUILD_PARITY")
if painting_hardening.get("repairId") != "harden-painting-remotes":
    errors.append("preflight painting repair id changed")
if painting_hardening.get("targetPath") != "ServerScriptService/ServerPaintingManager":
    errors.append("preflight painting target changed")
if painting_hardening.get("baselineSourceSha256") != "c1b792c89d3fafd78772b81a2427d1fa283098f23537c75672d0423de9f4e72f":
    errors.append("preflight painting baseline source hash changed")
if painting_hardening.get("patchedSourceSha256") != "e8025fce0fa0951ba373c72f58bf37bf96e2bd6b71cd7ada1faaf6083dd25a13":
    errors.append("preflight painting patched source hash changed")
if painting_hardening.get("deterministicReplacementCount") != 2:
    errors.append("preflight painting replacement count changed")
if painting_hardening.get("contractRunId") != 36898615525:
    errors.append("preflight painting contract run id changed")
if painting_hardening.get("runtimeVerified") is not False:
    errors.append("painting hardening must remain runtime-unverified until Studio proof")

phone_hardening = checks.get("phoneTextHardening") or {}
if phone_hardening.get("status") != "PASS_BUILD_PARITY":
    errors.append("preflight phone/text hardening status is not PASS_BUILD_PARITY")
if phone_hardening.get("repairId") != "harden-phone-text-remotes":
    errors.append("preflight phone/text repair id changed")
if phone_hardening.get("targetPath") != "ServerScriptService/PhoneTextingScript":
    errors.append("preflight phone/text target changed")
if phone_hardening.get("baselineSourceSha256") != "571e84308d007a1775aa14a281f92b6c177560bf97de308ec7347353d1d9d170":
    errors.append("preflight phone/text baseline source hash changed")
if phone_hardening.get("patchedSourceSha256") != "f180cb9f794e0a7157a9311f4ed692814d13ddb2a6e915e9d34ccb47e2a0cf66":
    errors.append("preflight phone/text patched source hash changed")
if phone_hardening.get("deterministicReplacementCount") != 3:
    errors.append("preflight phone/text replacement count changed")
if phone_hardening.get("contractRunId") != 36899421646:
    errors.append("preflight phone/text contract run id changed")
if phone_hardening.get("filteredMessageFlowPreserved") is not True:
    errors.append("preflight phone/text filtering flow is not marked preserved")
if phone_hardening.get("runtimeVerified") is not False:
    errors.append("phone/text hardening must remain runtime-unverified until Studio proof")

economy_hardening = checks.get("economyRemoteHardening") or {}
if economy_hardening.get("status") != "PASS_BUILD_PARITY":
    errors.append("preflight economy hardening status is not PASS_BUILD_PARITY")
if economy_hardening.get("repairId") != "harden-economy-remote-inputs":
    errors.append("preflight economy repair id changed")
if economy_hardening.get("targetPath") != "ServerScriptService/ItemBuyScript":
    errors.append("preflight economy target changed")
if economy_hardening.get("baselineSourceSha256") != "c92d824aea342350a940a14c74d151accca9bb0058932fc7df55b9b8557fbddf":
    errors.append("preflight economy baseline source hash changed")
if economy_hardening.get("patchedSourceSha256") != "876d7ae8f1fa746780e81e1457c8c7870d4092d532edb3bd94588c4316fa7169":
    errors.append("preflight economy patched source hash changed")
if economy_hardening.get("deterministicReplacementCount") != 7:
    errors.append("preflight economy replacement count changed")
if economy_hardening.get("contractRunId") != 36901054838:
    errors.append("preflight economy contract run id changed")
if economy_hardening.get("serverPricingPreserved") is not True:
    errors.append("preflight economy server pricing is not marked preserved")
if economy_hardening.get("runtimeVerified") is not False:
    errors.append("economy hardening must remain runtime-unverified until Studio proof")

if errors:
    print("RHS_PREFLIGHT_STALE_OR_INVALID")
    for error in errors:
        print("-", error)
    raise SystemExit(1)

print("RHS_PREFLIGHT_STATE_OK")
print("BASELINE_SHA256", baseline_sha)
print("WORKING_SHA256", working_sha)
print("COMPATIBILITY_PATCHES", len(patch_ids))
print("RUNTIME_VERIFIED", str(state["runtimeVerified"]).lower())
print("PUBLISHED", str(state["published"]).lower())
