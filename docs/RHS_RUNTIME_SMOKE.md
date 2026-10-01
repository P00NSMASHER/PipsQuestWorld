# Licensed RHS Runtime Smoke Gate

This is the first runtime acceptance gate for `rhs/working/ROBLOX High School.rbxl`.

## Candidate identity

- Immutable baseline SHA-256: `d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360`
- Current working SHA-256: `fbc6206282e082af6a5caf9d40fd3805b69b4776ca4d8d6c545d8a9812d55c0d`
- Approved compatibility changes: 4
- Runtime verified: no
- Published: no
- Car remote ownership hardening: lock, driver-lock, and removal handlers require the exact server-tracked `Workspace` vehicle for the requesting player

## Test-safety rules

1. Open the **working** copy only. Never modify the immutable baseline.
2. Keep Studio API-service access disabled for the first smoke.
3. Do not publish as part of this gate.
4. Do not trigger any Marketplace purchase or game-pass prompt deliberately.
5. Do not authorize or complete purchases.
6. Do not deliberately invoke external-place teleports.
7. Treat DataStore failures with API access disabled as compatibility evidence, not as permission to enable access.
8. Capture the exact first fatal error and its script path before making any repair.
9. Repair only reproducible blockers and regenerate the working copy from the immutable baseline + patch manifest.

## Legacy persistence retry behavior

With Studio API-service access disabled, old DataStore calls can fail immediately. The central persistence helpers wrap reads/writes in `pcall` and cap their retry loops at 10 attempts, with legacy delays between attempts. A DataStore-related warning or delay during this smoke is evidence to capture; it is **not** a reason to enable Studio API access against any live experience.

## Gate A — load / spawn

Required evidence:

- the exact working file opens without conversion or corruption errors;
- Play starts;
- one player character spawns;
- character movement works;
- jump works;
- camera control works;
- the main HUD appears;
- no startup error prevents normal play.

## Gate B — school loop

Required evidence:

- school map is present and navigable;
- schedule/class UI is visible;
- the current period advances normally;
- Math, English, Science, and History classroom zones exist;
- class teleport/navigation behavior does not soft-lock the player;
- cafeteria and lockers remain present.

## Gate C — preserved social/world systems

After A and B pass:

- team selection;
- Club Red / dance area;
- inventory/outfit UI;
- car UI and at least one ordinary vehicle;
- house UI and edit-mode entry;
- one non-purchase tool interaction.

## Deferred dependency probes

These are **not** prerequisites for Gate A:

- `633112728` — skateboard/hoverboard support module; anonymous asset delivery returns 403.
- `633111804` — hoverboard support module; anonymous asset delivery returns 403.
- `633111180` — NewHoverboard support module; anonymous asset delivery returns 403.
- `399944445` — NewPinkHoverboard support module; anonymous asset delivery returns 403.
- `258548692` — optional extra item-data loader; anonymous asset delivery returns 401, but the original require is wrapped in `pcall` and already fails soft.
- `191816425` — shared gear module; public asset retrieval succeeds.

Do not replace unavailable module IDs until Roblox runtime proves that the corresponding feature fails.

## Current side-effect inventory

Static audit currently finds:

- 18 purchase-prompt call sites;
- 14 badge-award call sites;
- 32 DataStore write call sites;
- 9 syntactic teleport call sites;
- 13 InsertService/LoadAsset sites;
- 11 numeric require call sites;
- 1 ProcessReceipt assignment.

The first Studio smoke is deliberately configured so DataStore access remains disabled and Roblox external-place teleports are not a supported Studio playtest path. This makes the first goal startup/player-experience compatibility rather than external-service integration.

## Completion rule

Do not call the licensed build playable or restored until Gates A and B have direct runtime evidence from the exact candidate.
