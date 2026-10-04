# P1 spawn / school / HUD integration seams — exact canonical 4323049

- Owner: Roblox High School Integration Director
- Input SHA: `43230492964ea637f69747e25a3e72d6cb268ebe` on `rebuild/high-school-foundation`
- Coordination input: `322066d29837a8c975831e3603e9b4b079668afe`
- Reference clip/time: A@00:05 frontage/steps/crest; A@00:25 bright atrium/circular display; A@00:45 broad corridor/staircase; A@02:05 stairwell/item view; B/C recurring compact right icon rail, top-right balances/status, and bottom item slots
- Acceptance criteria: integrate only one Control-Tower-authorized P1 candidate at the exact independently approved SHA; preserve one spawn, clock, location registry, progression/economy/persistence authority, and all existing guards; require rendered/device comparison after deterministic gates.
- Output location: `coordination/integration/P1_SPAWN_SCHOOL_HUD_SEAMS_4323049.md`
- Blocker: there is no active product producer or QA-approved P1 candidate. Exact canonical Smoke and deterministic Package must complete before Control Tower activates Pip High Free Roam as the sole P1 producer.
- Next handoff: Pip High Free Roam after Control Tower activation; then independent QA -> Integration -> Smoke -> Package on one exact candidate lineage.

This is integration readiness only. It contains no product implementation, stale merge preparation, or visual-parity claim.

## Live gate

- Canonical remains `43230492964ea637f69747e25a3e72d6cb268ebe`.
- PR 170 head `dfbbb5e2c52930beae7ebaea66d9ab5019c8914f` is already consumed; Integration receipt schema 12 and the three exact canonical push guards remain the frozen evidence.
- No new producer PR or independent QA approval exists. Integration must not merge or create product code.
- Foundation PR 179 is coordination-only evidence. It adds a new exact-code collision finding, not a product candidate.

## Exact baseline and ownership seams

| Surface | Exact baseline blob | Expected P1 use | Integration collision rule |
| --- | --- | --- | --- |
| `school/src/server/CampusBuilder.server.lua` | `402bc78ab622464e2f6ee12cc737ad32b6e8143a` | frontage, entrance stair, atrium, display, stair core, relocation of the one `MainSpawn` | One writer in the P1 producer. Never instantiate a second spawn or import retired geometry. |
| `school/src/shared/SchoolConfig.lua` | `334705e54cab66bd586f356d3f6ba0cfe28a5340` | update the existing `SchoolEntrance` only if the raised approach requires it | Preserve all rooms, `WorldSpawnSeams.AutoShopRoad`, housing plots, and one location registry. |
| `school/src/server/FoundationBootstrap.server.lua` | `64f45e7a7957fe2bada9b6eedffa05b4e575d120` | preferably unchanged; consumes `SchoolCampus.MainSpawn` via `Player.RespawnLocation` | Any change requires Foundation authority review; no second respawn or schedule loop. |
| `school/default.project.json` | `ba5e85e82652f137cb17e76016f062731c033761` | optional global Lighting tuning only | Preserve the sole Lighting mapping, runtime tree, and startup mappings. No runtime `Lighting.ClockTime` writer. |
| `school/src/client/CanonicalSchoolClient.client.lua` | `86ef317f8cae9cd3ae0051fdc103e06fc3c6a55a` | replace the always-visible legacy school card with the compact recurring HUD and bounded modals | This 54,788-byte monolith also owns class, jobs, vehicles, housing, travel, shopping boundary, and startup. Avoid broad rewrites and preserve remote names/order. |
| `school/src/shared/LegacyOutfitEntry.lua` | `8cad0a6d510a98f9af3a1d3f243ec310acbed05e` | no expected P1 change | Keep the repaired syntax closure and `LegacyOutfitEntry(player, UserInputService)` startup call intact. |
| `school/tests/foundation_world_contract_spec.lua` | `bbf5f7ed9a8bcb55556e0280eb1690b9bed1634a` | extend with unique-spawn, exterior-clearance, entrance-anchor, and route checks | Retain the existing AutoShop road-surface assertions verbatim in effect. |
| `.github/workflows/high-school-progression-ci.yml` | candidate repair already consumed into canonical | no expected semantic weakening | Preserve the parse/mount guard added by PR 170. |

## Two concrete integration hazards

### 1. Spawn and entry geometry must change atomically

At the exact baseline:

- `MainSpawn` footprint is X [-5, 5], Z [100, 110], inside the lobby.
- `EntryMat` footprint is X [-8, 8], Z [107, 115].
- Both are collidable and overlap across a 10-by-3-stud horizontal region; their Y volumes also intersect.
- The door plane is at Z=121.6 and the exterior `SchoolEntrance` seam is at (0, 3, 142).

Integration must reject a candidate that only moves the decorative mat, adds another spawn, or moves the travel seam without keeping a continuous exterior spawn -> stairs -> doors -> atrium -> corridor/stair route. Geometry, the singular spawn relocation, the existing entrance seam (if changed), and the deterministic route contract are one atomic P1 unit.

### 2. Compact HUD work shares a broad client startup surface

The exact client creates an always-visible `LegacySchoolMenu` at bottom-left, size 236x184, with touch bottom margin 112. The same file mounts `LegacyOutfitEntry`, `LegacyShoppingBoundary`, class state/remotes, and later job/vehicle/housing UI.

Integration must reject a candidate that obtains a compact appearance by deleting or bypassing those existing interactions, changing server-authoritative contracts, or reordering startup so the repaired outfit entry can fail again. The compact right rail, top-right status/balances, and bottom item slots should be composition/navigation changes; large activity/editor panels may remain modal and hidden during free roam.

## Required candidate evidence

Before Integration may consume P1, the exact producer head must have:

1. WIP authorization naming Pip High Free Roam as the sole producer and an exact packaged canonical base.
2. A bounded changed-file list with no retired runtime root and no unrelated authority rewrite.
3. Deterministic proof of exactly one `SchoolCampus.MainSpawn`, one `SchoolEntrance` record, one respawn assignment path, and no second schedule or Lighting clock writer.
4. A collision-safe sampled route through both sides of the circular atrium display into `CentralHall` and the guarded stair landing.
5. Existing AutoShop, housing, room-spawn, class, progression, shopping, outfit-mount, save/rejoin, and startup contracts retained.
6. Compact-HUD assertions for right rail, top-right status/balances, bottom slots, modal hidden state, and target-phone/tablet safe-area obstruction rules.
7. All required exact-head CI green.
8. Independent QA approval on the identical head, with rendered and iPhone/iPad results explicitly pending unless actually captured.

## Ordered protected handoff

1. Smoke and Package finish exact canonical `4323049`; Control Tower publishes the exact packaged base and activates one P1 producer.
2. Pip High Free Roam implements the atomic geometry/spawn/HUD slice and its narrow contracts on that base.
3. Independent QA validates the exact producer head and records any unavailable visual/device checks as pending.
4. Integration re-reads live WIP, candidate head, changed paths, reviews, and exact-head CI; any head movement invalidates approval.
5. Integration merges only the approved exact head through the protected path, authors no product changes, then verifies the resulting canonical and all three exact push guards.
6. Integration hands that exact canonical immediately to Smoke.
7. Smoke executes the implemented flow and rendered/device plan without converting headless success into visual PASS; Package follows only on exact Smoke PASS.

No merge is authorized by this preparation alone.
