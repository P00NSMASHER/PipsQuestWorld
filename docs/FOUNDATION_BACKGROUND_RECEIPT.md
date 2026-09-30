# Maze World Foundation — Background Certification Receipt

Canonical source SHA: `a5631eea0d514f7383921d7e664a9aaeb6715c37`  
Pristine behavioral baseline: `7ebfd2f81ddfc3d740eee1641b859f49dc087323`  
Canonical branch: `rebuild/maze-world-foundation`  
Execution mode: background/headless only on PAAM-L044.

## Current exact-head results

- Maze World Foundation Guard GitHub Actions run `36750232847`: **PASS**.
- Protected Maze World gameplay files vs pristine baseline: **unchanged / PASS**.
- Foundation static verifier: **PASS**.
- First-party Luau syntax: **147 files, 0 failures**.
- Required foundation assets: **14/14 present**.
- Maze World model files: **38**.
- Legacy custom-world markers in first-party source: **0**.
- Server-only education authority boundary: **PASS**.
- Native coin seam guard: **PASS**.
- Native CoinBrick handlers observed: **1 authoritative handler**.
- Pips competing CoinBrick handlers: **0**.
- Education Engine smoke: **PASS**.
- Education + content contract: **PASS — 12 active material items / 3 direct / 125 max points**.
- LearningSession lifecycle smoke: **PASS**.
- Deterministic learning coin selector smoke: **PASS**.
- Release content QA: **PASS — 12 current-material items**.

## Build evidence

The current game tree is unchanged between `a912b379bd1d99df43413bd83063132f51155587`
and `a5631eea0d514f7383921d7e664a9aaeb6715c37`; the only intervening change is the
location-safe verifier script `scripts/verify-server-only-education.mjs`.

The same game tree completed a headless Rojo build successfully on PAAM-L044.

## Architecture boundaries

Current canonical preparation includes only:

- server-only Education Engine;
- server-only curated/full question banks;
- server-only LearningSession core;
- deterministic server-only native normal-coin selector;
- native coin seam/static regression guards;
- shadow-only telemetry/observation;
- documentation and CI.

It does **not** authorize or implement:

- a replacement maze/corridor;
- a finish interception;
- a replacement chest/reward loop;
- a persistent Pips HUD;
- a live learning coin touch hook;
- question UI/RemoteEvents;
- Pip reward integration;
- Roblox publication.

## Canonical branch authority

`rebase/maze-world-chassis`, old `feat/*` Pips branches, and v132 custom-world
code are quarantined legacy evidence and are not eligible integration bases or sources.

See `docs/CANONICAL_BRANCH_AUTHORITY.md`.

## Remaining Phase-0 gate

Fresh target-device Maze World gameplay acceptance remains required before the first
live learning seam is authorized. The standing background-only rule prevents producing
new foreground Roblox Studio/device evidence from PAAM-L044.

Verdict: **BACKGROUND FOUNDATION GREEN; RUNTIME/TARGET-DEVICE ACCEPTANCE DEFERRED**.
