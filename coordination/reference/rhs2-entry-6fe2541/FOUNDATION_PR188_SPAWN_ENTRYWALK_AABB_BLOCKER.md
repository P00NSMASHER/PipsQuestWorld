# Foundation PR 188 spawn/EntryWalk AABB blocker

- Owner: Roblox High School Foundation
- Input SHA: `f9910fae5c672fea3b0569d228d986eb4e701401` (PR 188)
- Input base SHA: `43230492964ea637f69747e25a3e72d6cb268ebe`
- Reference clip/time: A@00:05 school frontage, broad steps, crest, red/white/blue approach; A@00:25 bright atrium; A@00:45 corridor/staircase; A@02:05 stairwell/items
- Acceptance criteria: preserve exactly one spawn/clock/location/Lighting authority; place `MainSpawn` on the exterior approach without intersecting any collidable geometry; preserve a continuous spawn -> approach -> entrance -> atrium -> corridor/stair route; retain existing room/town seams; require exact-head CI, independent QA, Integration, Smoke and rendered/device comparison.
- Output location: `coordination/reference/rhs2-entry-6fe2541/FOUNDATION_PR188_SPAWN_ENTRYWALK_AABB_BLOCKER.md`
- Blocker: exact PR 188 head still intersects the collidable `EntryWalk`; independent QA must not record PASS_EXACT_HEAD until a changed candidate fixes the geometry and adds a deterministic clearance assertion.
- Next handoff: Pip High Free Roam repairs PR 188 on its sole authorized producer branch; all three exact-head guards rerun; Roblox High School QA & Contract reviews only the changed exact head.

This is coordination-only Foundation evidence. It does not modify `school/**`, approve PR 188, claim runtime execution, or close visual parity.

## Exact geometry on PR 188 head

The exact candidate source defines:

| Part | Center | Size | AABB |
| --- | --- | --- | --- |
| `MainSpawn` | `(0, 1.15, 177)` | `(10, 1, 10)` | X `[-5, 5]`; Y `[0.65, 1.65]`; Z `[172, 182]` |
| `EntryWalk` | `(0, 0.75, 171)` | `(18, 0.3, 82)` | X `[-9, 9]`; Y `[0.60, 0.90]`; Z `[130, 212]` |

The intersection is therefore:

- X: `[-5, 5]` = 10 studs
- Y: `[0.65, 0.90]` = 0.25 studs
- Z: `[172, 182]` = 10 studs

The entire 10-by-10 spawn footprint penetrates the walk vertically by 0.25 studs.

`makePart` does not override `Part.CanCollide`, so `EntryWalk` retains Roblox's collidable default. `MainSpawn` also does not override `SpawnLocation.CanCollide`. This is the same defect class as the canonical spawn/EntryMat overlap recorded by Foundation PR 179: the named decorative collision changed, but the exact candidate still fails the required spawn-clearance contract.

## Guard gap

`school/tests/foundation_world_contract_spec.lua` on the candidate checks the literal spawn coordinate and that exactly one `SpawnLocation` exists. It does not calculate the spawn AABB or compare it against collidable geometry. The three successful PR workflows therefore do not prove spawn clearance.

The repair must add a deterministic assertion that fails for the current coordinate. A string-presence check for a relocated coordinate is insufficient.

## Required repair

On the sole PR 188 producer branch:

1. Keep one `SchoolCampus.MainSpawn`; do not add a second spawn or respawn writer.
2. Reposition the existing spawn so its AABB has no positive-volume intersection with `EntryWalk`, `EntryStep*`, planters, trunks/crowns, curbs, doors, mats, rails, or other collidable approach geometry.
3. Add a deterministic contract that derives the spawn AABB and rejects positive-volume overlap with collidable named geometry. Preserve the existing one-spawn assertion and all AutoShop/room/town seams.
4. Rerun Foundation, Class/Education and Progression guards on the changed exact head.
5. Require independent QA on the changed SHA; prior green runs for `f9910fae5c672fea3b0569d228d986eb4e701401` become stale after the repair.
6. Keep physical collision and rendered comparison pending until actual Roblox runtime/device execution.

A safe implementation may adjust the spawn vertical placement above the walk or otherwise remove the collidable intersection, but the exact value must satisfy the computed clearance contract and still be validated in runtime.

## Additional rendered/runtime risk

The seven new `EntryStep*` parts explicitly set `CanCollide = false`. Static source proves only their visual presence; it does not prove the broad stair approach observed at A@00:05 feels like stairs or forms a physically continuous elevation change. Smoke must retain the PR 189 runtime waypoint check from exterior spawn through the approach and threshold. This is a runtime/rendered parity risk, not a substitute for the deterministic spawn-overlap fix above.
