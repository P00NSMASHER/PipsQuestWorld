# Maze World Foundation — Background Certification Receipt

Tested source SHA: `ac6161bd8e9780cb32d4f6cecb290ac1a247ab88`  
Pristine baseline: `7ebfd2f81ddfc3d740eee1641b859f49dc087323`  
Execution mode: background/headless only on PAAM-L044.

## Results

- Foundation Guard GitHub Actions: **PASS**.
- Protected Maze World core diff vs pristine baseline: **PASS / byte-identical**.
- First-party Luau syntax: **142 files compiled, 0 failures**.
- Required foundation assets: **14/14 present**.
- Maze World model files observed: **38**.
- Legacy custom-world markers in first-party source: **0**.
- Pips integration mode: **shadow only**; gameplay mutation flags false.
- Rojo build: **PASS**, output size **109,665,484 bytes**.
- Built artifact structural prefix SHA-256: `0cbbbe53349afa6dbfac38e1a126bdf383ab08c754a318f1f9f97297ac2887d6`.
- SharedStrings section: **2,934,809 bytes / 145 entries**.

## Build determinism note

Two consecutive Rojo builds from the same exact source produced the same byte length,
the same SharedStrings offset/count/size, and the same structural-prefix SHA-256,
but different raw SHA-256 values inside the serialized SharedStrings payload.

Therefore raw `.rbxlx` SHA-256 is **not** used as the sole reproducibility identity.
Canonical identity is the exact Git source SHA + protected-file diff + structural build
fingerprint + successful build result. This avoids treating serializer-level
SharedStrings variation as source drift.

## Remaining Phase 0 blocker

Fresh interactive target-device gameplay acceptance is still not produced because the
standing background-only rule forbids foreground Roblox Studio/device interaction.
No educational gate, Pip reward replacement, custom corridor, custom persistent HUD,
or custom chest has been approved for integration.

Verdict: **BACKGROUND FOUNDATION CERT PASS**.
