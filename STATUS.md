# Pip's Quest World Status

Updated: 2026-09-30

## Product direction

- Maze World direction: **RETIRED**
- Standalone/homegrown school prototype direction: **RETIRED**
- Active foundation: **licensed archived ROBLOX High School build**
- Source archive commit: `b817aef0eaf77d3382acacdc8f22537e54c76822`
- Source archive blob: `95ee3d762f419bb3572e18db57c03682651dc8c4`
- Canonical SHA-256: `d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360`
- Canonical byte size: `2,283,775`

## Verified static inventory

- 41,257 instances
- 122 instance classes
- 1,192 non-empty scripts
- 2,196,914 bytes of Lua source
- 1,835 GUI instances
- 278 remote/bindable objects
- 93 tools
- 8 teams
- 346 seats/vehicle seats
- 205 sounds
- 869 unique Roblox asset IDs / 4,248 references

Major systems present include school schedules/classes, vehicles, housing/furniture, clubs/dance/music, inventory/items, outfits, cash/data systems, companions, tools, gamepasses/products, teleports, and mobile/client control code.

## Known compatibility work

The archived build is substantial but not yet proven runtime-compatible in 2026. Known dependency families include:

- legacy `cindering.xyz` HTTP calls
- old GameAnalytics HTTP integration
- DataStoreService persistence
- Marketplace/GamePass/Badge logic
- TeleportService
- InsertService / numeric require(assetId) dependencies
- legacy services/APIs including GamePassService and PointsService
- thousands of externally hosted Roblox asset references

## Runtime status

- Exact baseline imported: **YES** — immutable baseline matches SHA-256 `d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360`
- Working copy created: **YES**
- Compatibility patches applied: **3** — legacy Cindering ranking login, group-ranking HTTP, and GameAnalytics outbound telemetry are sandboxed in the working copy only
- Working-copy SHA-256 after current patches: `04efd02d60dbf2388c230402888a21f0f3240efdf1b8971abcb0bc582b4ad8c4`
- Baseline integrity guard: **PASSING**
- Compatibility audit: **PASSING**
- Structural parity: **PASSING** — 41,258 instances, 1,062 unique script paths, exactly 3 approved script-source changes, no unapproved hierarchy/source drift
- Current Roblox documentation still exposes `GamePassService` and `PointsService` as deprecated services, so they are not being rewritten solely because they are deprecated
- Executable legacy HTTP calls: **0 detected** after the three sandbox patches; remaining `http://` matches are non-`HttpService` strings such as asset/documentation URLs
- Numeric module dependency probe: **COMPLETE** — 191816425 resolves publicly; 258548692 is unavailable anonymously but already fail-soft; four unavailable-anonymous modules are isolated to skateboard/hoverboard paths and require runtime proof before any replacement
- Runtime side-effect preflight: **COMPLETE** — purchase prompts are player-click driven; literal old-place teleports are remote/admin driven; startup-sensitive DataStore access is guarded by `pcall`, and the shared retry helpers cap attempts at 10 rather than retrying forever
- Startup risk audit: **COMPLETE** — 175 auto-server scripts, 464 auto-client scripts, 32 auto-running scripts containing side-effect-capable code; no new game patch was added from this audit
- Static preflight verdict: **READY FOR LOCAL STUDIO SMOKE** with Studio API-service access disabled; runtime behavior is still unproven
- Roblox Studio runtime proof: **NOT YET PERFORMED**
- Roblox publication: **NOT REQUESTED / NOT PERFORMED**
