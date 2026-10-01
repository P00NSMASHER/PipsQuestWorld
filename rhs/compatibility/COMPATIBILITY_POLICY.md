# RHS Compatibility Policy

The restoration goal is behavioral fidelity with the smallest necessary compatibility changes.

## Rule: deprecated does not mean broken

Do **not** replace a Roblox API solely because it is marked deprecated.

A compatibility patch requires at least one of:

1. direct Roblox Studio runtime evidence that the original call fails or blocks intended behavior;
2. current Roblox API documentation showing the member has been removed or cannot support the original behavior;
3. a security/safety requirement that makes the original behavior inappropriate to execute during testing.

Every patch must remain deterministic, target the working copy only, and preserve the immutable baseline.

## Current verified backward-compatible APIs

Checked against current Roblox Creator Hub/API references on 2026-09-30:

- `TeleportService.CustomizedTeleportUI` — still present; deprecated; currently documented as having no effect.
- `TeleportService:Teleport(...)` — still present; deprecated.
- `GamePassService:PlayerHasPass(...)` — still present for legacy game passes; deprecated.
- `PointsService` / `AwardPoints(...)` — service and method still present; deprecated.
- `ServiceProvider:service(...)` / `game:service(...)` — still present; deprecated alias of service retrieval.

These are **not compatibility defects by themselves**.

## Already-approved deviations

The current exact-restoration working build intentionally changes four script sources:

1. historical Cindering ranking-login outbound request;
2. historical Cindering group-ranking outbound request;
3. historical GameAnalytics outbound telemetry;
4. `ServerScriptService/CarSpawnScript` remote ownership validation for lock, driver-lock, and removal requests.

The first three changes prevent obsolete external-network behavior during restoration work. The fourth is a security hardening change that requires client-supplied car instances to equal the exact server-tracked `Workspace` vehicle for the requesting player. None of these changes exist merely because an API is deprecated.

Educational/class-activity additions live on separate candidate branches/PRs and are not part of this exact-restoration four-patch receipt until explicitly integrated.

## Runtime-first repair order

When Studio is available:

1. launch the exact working SHA recorded in `rhs/working/BUILD_STATE.json`;
2. capture the first reproducible blocker;
3. identify the exact script/member responsible;
4. confirm whether the API is actually unavailable or behaviorally incompatible;
5. add the smallest possible patch through `rhs/compatibility/PATCH_MANIFEST.json`;
6. rebuild from the immutable binary;
7. rerun structural parity and runtime smoke.

Do not bulk-modernize syntax, APIs, UI, or architecture before runtime proves a need.
