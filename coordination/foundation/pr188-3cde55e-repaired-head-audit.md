# PR 188 repaired-head Foundation audit

## Artifact contract

- **Owner:** Roblox High School Foundation
- **Input candidate SHA:** `3cde55e5a40f24dd2386b8b78757992f6d32bfb3` (PR 188)
- **Canonical base SHA:** `43230492964ea637f69747e25a3e72d6cb268ebe`
- **Prior candidate SHA:** `728d62b909bf8d8b7bd9d0466f3fb18c80ebb895`
- **Reference clip/time:** A@00:05 frontage/entrance, A@00:25 atrium, A@00:45 corridor/stairs, A@02:05 stair flight/item-slot view
- **Acceptance criteria:** preserve one mapped campus builder, one mapped school clock/schedule authority, one `MainSpawn`, and all existing server-owned interfaces; implement the confirmed stair-flight composition without a collidable traversal narrowing; keep all three exact-head guards green; require independent same-SHA QA before Integration
- **Output location:** `coordination/foundation/pr188-3cde55e-repaired-head-audit.md`
- **Blocker:** independent QA has not reviewed exact `3cde55e`; rendered comparable-FOV desktop/iPhone/iPad evidence, physical traversal, panel restoration, and save/rejoin remain pending
- **Next handoff:** Roblox High School QA & Contract reviews exact `3cde55e`; Integration remains unauthorized until that same SHA is explicitly approved
- **Status:** `PASS_STATIC_AUTHORITY_CONTINUITY__PASS_BOUNDED_REPAIR_SHAPE__HOLD_RENDERED_TRAVERSAL_AND_QA`

No product file was written by Foundation. The existing Pip High Free Roam producer owns PR 188 and is now frozen at the repaired head pending independent QA.

## Live exact-head evidence

- PR 188 is open and mergeable at `3cde55e5a40f24dd2386b8b78757992f6d32bfb3`.
- The repaired head is exactly one commit ahead of `728d62b`, zero commits behind.
- The repair delta is bounded to:
  - `school/src/server/CampusBuilder.server.lua`: +78/-1, blob `1e49e99026352ffd5e412515636cc662097a3305`;
  - `school/tests/foundation_world_contract_spec.lua`: +28/-0, blob `015fc22d0f8a7deba9895d9ab1cb1f56ba843acf`.
- Exact-head guards all succeeded:
  - Foundation run `37242078845`;
  - Class/Education run `37242078873`;
  - Progression run `37242078844`.
- The only current PR 188 review, `5408581109`, is bound to prior `728d62b`. It confirms the defect that this change addresses but cannot authorize current `3cde55e`.

## Authority audit

Static authority result: **PASS — no new world, clock, spawn, economy, progression, persistence, or runtime-root authority is introduced by the repair commit.**

The exact delta changes only CampusBuilder geometry plus its Foundation contract. It does not change `default.project.json`, `FoundationBootstrap.server.lua`, client routing, shared remotes, persistence, economy, progression, or schedule code.

The repaired CampusBuilder still contains:

- exactly one `Instance.new("SpawnLocation")`;
- exactly one `MainSpawn` assignment;
- the existing stair run and upper landing;
- no second campus builder or school clock.

The prior exact-head authority findings therefore remain continuous. Any future product amendment must be triggered by a concrete same-head QA defect, not by this Foundation lane.

## Reference-bound repair audit

### A@00:45 and A@02:05 — stair-flight composition

The repaired source now contains:

- two separately named blue flight rails:
  - `CorridorStairFlightRailBlueLeft`;
  - `CorridorStairFlightRailBlueRight`;
- four sets of blue flight posts, at stair indices 0, 3, 6, and 9 on each side;
- four separately named stair-local wall bands:
  - `CorridorStairBlueBandLeft`;
  - `CorridorStairBlueBandRight`;
  - `CorridorStairRedBandLeft`;
  - `CorridorStairRedBandRight`;
- the existing transverse `UpperHallRailBlue` and `UpperHallRailRed`, still distinct from the flight-side components.

This closes the specific static source absence recorded against `728d62b`. It does **not** establish rendered parity.

### Geometry and navigation checks

- Stair tread width remains 25 studs, with half-width 12.5.
- Flight-rail centers are at x ±12.1 with 0.6-stud thickness, visually tracking the tread edges.
- Both long rails and every support post are `CanCollide=false`.
- Stairwell walls are centered at x ±16.5 with 0.6-stud thickness; their inner faces remain about 3.7 studs outside each tread edge.
- Wall bands are 0.18 studs thick, mounted against those walls, and `CanCollide=false`.
- The ten-step run, central axis, upper landing, and transverse landing rails remain present.

Static disposition: the repair adds the requested visual edge language while preserving the full collidable stair surface. Roblox runtime must still prove feet, character root, camera, and accessories do not visually clip through the noncollidable accents.

### Contract strength

The changed Foundation spec now requires:

- both flight-side rail names;
- flight-post generation;
- all four stair-local band names;
- the separately named transverse landing rail;
- noncollidable flight rails and bands;
- parsed stair/rail/wall geometry;
- exactly two flight-rail names versus one landing-rail name.

This prevents the prior false satisfaction in which a transverse landing rail could stand in for flight-side rails.

## Unchanged reference checkpoints

The repair commit is intentionally limited to A@00:45/A@02:05 stair composition. It does not add new evidence or make new claims for:

- A@00:05 frontage, crest silhouette, landscaped approach, or decorative tread clipping;
- A@00:25 atrium luminance, circular-display clearance, ceiling-light appearance, or shadow readability;
- compact HUD obstruction on desktop, iPhone, or iPad;
- physical spawn → entrance → atrium → corridor traversal;
- stair ascent/descent;
- panel restoration, camera rebinding, or save/rejoin.

Those states remain pending independent QA and post-integration Smoke. Static CI must not be promoted to rendered or device PASS.

## Exact-head QA checklist

1. Re-read PR 188 head and verify it is still exactly `3cde55e`.
2. Bind the QA verdict and every cited workflow run to that SHA.
3. Preserve the static authority PASS unless a concrete duplicate authority is found.
4. Verify the two flight rails, eight posts, four stair-local bands, and the distinct landing rail from exact source.
5. Record comparable-FOV A@00:45/A@02:05 rendered state separately from static state.
6. Physically ascend and descend the stair flight and inspect feet/root/camera/accessory clipping.
7. Keep desktop/iPhone/iPad, interaction, and save/rejoin states pending unless actually executed.
8. Authorize Integration only if the same exact SHA passes all required gates.

Exact RHS2 parity is not claimed.
