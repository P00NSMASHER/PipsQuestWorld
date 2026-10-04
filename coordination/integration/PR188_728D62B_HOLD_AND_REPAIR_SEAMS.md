# PR 188 exact-head integration hold and repair seam inventory

## Artifact contract

- **Owner:** Roblox High School Integration Director
- **Input candidate:** PR 188 at `728d62b909bf8d8b7bd9d0466f3fb18c80ebb895`
- **Canonical base:** `rebuild/high-school-foundation@43230492964ea637f69747e25a3e72d6cb268ebe`
- **Coordination input:** `coordination/high-school-control-tower@71026729f4634ff3c38ea4e35d88cc5183a041eb`
- **Reference clip/time:** A@00:45 corridor/stair sightline and A@02:05 blue flight-side rails with red/blue stairwell bands
- **Acceptance criteria:** consume only a changed PR 188 head that closes `PR188_STAIR_FLIGHT_REFERENCE_COMPOSITION_GAP`, has all three exact-head guards green, and receives independent QA approval on that same SHA; enforce the expected head on merge; wait for all three push guards before handing the exact integrated canonical to Smoke
- **Output:** `coordination/integration/PR188_728D62B_HOLD_AND_REPAIR_SEAMS.md`
- **Blocker:** independent QA result on exact `728d62b` is `PASS_FUNCTIONAL_STATIC_EXACT_HEAD__FAIL_VISUAL_SOURCE_CONTRACT__HOLD_INTERACTION_DEVICE`; Integration is explicitly not authorized
- **Next handoff:** Pip High Free Roam repairs the existing sole producer PR 188; Roblox High School QA & Contract rechecks the changed exact head before Integration acts
- **Status:** `BLOCKED_QA_HOLD__NO_PRODUCT_MERGE`

## Live exact-head decision

PR 188 is open and mergeable at exact head `728d62b909bf8d8b7bd9d0466f3fb18c80ebb895`, directly ahead of canonical `43230492964ea637f69747e25a3e72d6cb268ebe`. Its Foundation, Class/Education, and Progression runs `37237332258`, `37237332337`, and `37237332270` are successful.

Those green runs do not authorize integration. Independent QA review `5408581109` and receipt PR 203 bind the same exact candidate to a blocking visual source-contract failure: the candidate has ten corridor steps and transverse landing rails, but no blue rails following the stair flight and no stair-local red/blue wall bands visible in A@02:05. Rendered comparison, physical traversal, panel restoration, and desktop/iPhone/iPad evidence also remain open.

Therefore this lane does not merge PR 188 and does not modify `school/**`.

## Changed-surface inventory

| Surface | Current PR 188 role | Repair collision risk | Integration rule |
| --- | --- | --- | --- |
| `school/src/server/CampusBuilder.server.lua` | Owns the P1 frontage, atrium, corridor stairs, landing rails, and singular `MainSpawn` placement | The required stair-flight rails/bands belong here; bad geometry can narrow the 25-stud tread route, snag ascent/descent, obstruct A@00:45 sightline, or introduce duplicate named authorities | Permit only the existing producer to amend it. Preserve one `SpawnLocation`, existing spawn AABB clearance, central stair run, route openings, and mapped Foundation authority |
| `school/tests/foundation_world_contract_spec.lua` | Proves singular spawn and named-surface AABB clearance plus current P1 presence | A weak presence check could confuse transverse landing rails with required flight-side rails | Require distinct assertions for flight-side rails and stair-local bands, plus retained spawn/AABB checks; do not weaken existing clauses |
| `school/default.project.json` | Adds the single `ResponsiveHudLayout` mapping | Unrelated repair edits could remap runtime roots or introduce a second clock/spawn/client authority | No repair change expected. Any change requires renewed mapping/authority review |
| `school/src/client/CanonicalSchoolClient.client.lua` | Mounts the responsive compact HUD while preserving existing server boundaries | Unrelated repair edits could disturb the repaired `LegacyOutfitEntry` startup path, panel restoration, or server-owned actions | No stair repair change expected. Any change reopens client startup, authority, interaction, and HUD QA |
| `school/src/shared/ResponsiveHudLayout.lua` and HUD tests | Supply deterministic desktop/iPhone/iPad safe-bound and overlap contracts | Stair repair should not touch them; a change would invalidate the exact responsive-HUD certification | Freeze during the stair repair unless QA separately identifies a new HUD defect |

Expected minimal repair delta is limited to `CampusBuilder.server.lua` and `foundation_world_contract_spec.lua`. Any broader product delta is not automatically rejected, but it invalidates this preparation and requires a fresh exact-head collision inventory and corresponding QA.

## Mechanical conflict checks after repair

Integration must re-read live evidence and reject stale preparation if any of these conditions fail:

1. PR 188 base remains exact canonical `43230492964ea637f69747e25a3e72d6cb268ebe`, with no divergence or unrelated merge commit.
2. The live candidate head differs from `728d62b`; all prior CI and QA evidence is treated as stale for authorization.
3. The repair keeps one mapped `CampusBuilder`, one mapped `FoundationBootstrap`, one `SpawnLocation`, and no second client runtime.
4. Flight-side rail geometry remains outside the usable tread envelope and does not block the centerline, landing, doors, or circulation lanes.
5. Stair-local red/blue bands do not cover route openings or erase the broad A@00:45 central sightline.
6. Existing spawn clearance, responsive HUD, `LegacyOutfitEntry` parse/mount, class/session, progression, economy, and persistence gates remain intact.
7. Foundation, Class/Education, and Progression workflows all succeed on the exact changed head.
8. Independent QA submits an approval/receipt bound to that same changed SHA. A static-only pass, a visual hold, or evidence bound to `728d62b` is insufficient.
9. The protected merge uses the expected candidate head. Any head move stops integration.
10. The canonical branch emits successful push guards on the resulting exact canonical before Smoke is handed the SHA.

## Ordered handoff

1. Pip High Free Roam amends only the existing PR 188 producer branch to add the bounded flight-side rails/bands and stronger Foundation contract.
2. CI runs all three guards on the changed exact head.
3. Independent QA rechecks functional, visual, interaction, and device gates on that same SHA; rendered/device gaps remain explicit until actually executed.
4. Integration revalidates base lineage, live changed paths, authority uniqueness, collision seams, exact-head CI, and exact-head QA.
5. If and only if every gate authorizes the same SHA, Integration merges PR 188 with the expected-head guard.
6. Integration waits for the three canonical push guards and hands the exact resulting canonical SHA to Roblox High School Integration Smoke immediately.
7. Smoke executes the implemented spawn -> entrance -> atrium -> corridor -> class/free-roam -> menus -> save/rejoin path and keeps any unavailable rendered/device checks pending.
