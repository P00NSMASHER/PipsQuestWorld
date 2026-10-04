# P1 exact-candidate post-integration runtime plan

- Owner: Roblox High School Integration Smoke
- Input SHA: `f9910fae5c672fea3b0569d228d986eb4e701401` (PR 188)
- Input base SHA: `43230492964ea637f69747e25a3e72d6cb268ebe`
- Reference clip/time: A@00:05 frontage/steps/crest; A@00:25 bright atrium/circular display; A@00:45 corridor/staircase; A@02:05 stairwell/items; A/B/C recurring compact HUD
- Acceptance criteria: after independent QA and protected Integration of this exact candidate, exercise the implemented spawn -> entrance -> atrium -> corridor/stair -> class/free roam -> menus -> save/rejoin route; collect candidate-specific waypoint, collision, camera, and mobile-obstruction evidence; keep rendered/device/live-rejoin results pending until actually executed.
- Output location: `coordination/smoke/p1-f9910fae-runtime-plan.md`
- Blocker: PR 188 is not QA-approved or integrated. Smoke must not execute or certify the candidate before CI -> independent QA -> Integration complete on the same exact head. Live WIP schema 50 still records the authorized producer branch as pending; Control Tower must reconcile the actual PR 188 branch before protected handoff.
- Next handoff: Roblox High School QA & Contract reviews exact `f9910fae5c672fea3b0569d228d986eb4e701401`; Integration consumes only that approved head; Smoke then tests the exact integrated canonical.

This is coordination-only preparation. It does not edit `school/**`, merge PR 188, claim runtime execution, or claim RHS2 parity.

## Exact changed surfaces

PR 188 changes exactly:

- `school/src/server/CampusBuilder.server.lua`
- `school/src/client/CanonicalSchoolClient.client.lua`
- `school/tests/foundation_world_contract_spec.lua`
- `school/tests/legacy_hud_contract_spec.lua`

All three pull-request workflows currently succeed on exact head `f9910fae5c672fea3b0569d228d986eb4e701401`:

- Foundation run `37233567154`
- Class/Education run `37233567169`
- Progression run `37233567202`

No independent QA review exists yet. Static success is not a Smoke PASS.

## Harness coverage gap closed

The existing schema-15 Smoke receipt pins generic camera and normalized UI-obstruction measurements, but it predates PR 188 and does not bind runtime waypoints to the candidate's new coordinates and named geometry. This plan adds that exact-candidate mapping.

### Route and collision probes

After Integration, run with an ordinary avatar and capture each waypoint in order:

1. `MainSpawn` at candidate center `(0, 1.15, 177)`: character materializes upright without overlap, forced displacement, or blocked camera.
2. Exterior approach: walk the centerline toward the seven decorative `EntryStep*` parts and record whether their non-collidable implementation produces a visually plausible, physically continuous path.
3. Door plane and threshold: cross the existing entrance without touching `EntryMat`; prove the PR 179 spawn/mat overlap is gone in runtime.
4. Atrium display: traverse both left and right circulation arcs around `AtriumDisplayTier1..3`; record minimum avatar clearance and camera occlusion.
5. Central hall: proceed from the atrium into the existing hall without teleport, seam duplication, or authority change.
6. Corridor staircase: ascend `CorridorStairStep1..10`, reach `UpperHallLanding`, reverse direction, and confirm no snag, fall-through, or unguarded route exit.
7. Class/free roam: enter and leave one implemented class/activity flow, returning to the same free-roam route.
8. Menus: open and close Shop, Avatar, House, Travel, class/cafe, and vehicle surfaces as implemented; server-owned boundaries must remain unchanged.
9. Save/rejoin: commit one supported durable state change, leave, rejoin, and verify only the committed state restores. Live DataStore evidence remains required.

For each failed transition, record the last successful waypoint, avatar root position, camera position/yaw/pitch/FOV, visible UI state, and the first blocking instance name. Do not infer pass/fail from source geometry alone.

### Timestamp-matched camera captures

At comparable 1112x512 aspect ratio and FOV, record:

- A@00:05: full frontage silhouette, crest, symmetric stairs/approach, red/white/blue massing.
- A@00:25: atrium center display, ceiling-light rhythm, both circulation arcs.
- A@00:45: corridor axis and complete staircase sightline.
- A@02:05: stair/landing view with menu closed and bottom quick slots visible.

Playback contains visible 2x segments; do not use the clips to certify movement speed or animation timing without correction.

### iPhone/iPad obstruction probes

For iPhone landscape and iPad landscape, capture menu-closed frames at spawn, atrium, corridor, and stair landing plus one frame per implemented modal. Record viewport pixels, safe insets, orientation, Roblox movement/jump bounds, and normalized bounds for:

- `CompactSchoolStatus` (candidate fixed size 226x122, top-right)
- `RHS2ActionRail` (candidate fixed size 56x226)
- `RHS2QuickBar` (candidate fixed size 238x54)
- each open modal and the Roblox touch controls

Fail obstruction review if any Pip High control overlaps Roblox movement, jump, or gesture regions; if the closed HUD blocks the central navigation sightline; or if a required control is unreachable after safe-area adjustment. Fixed pixel sizes are evidence targets, not proof of mobile fitness.

## Gate order

1. PR 188 stays at exact head `f9910fae5c672fea3b0569d228d986eb4e701401` with all required CI green.
2. Independent QA records PASS_EXACT_HEAD on that same SHA.
3. Integration mechanically merges only that SHA and hands the exact new canonical to Smoke.
4. Smoke runs the route, collision, camera, menu, save/rejoin, and device plan above.
5. Package consumes only the exact Smoke-passed canonical.
6. Rendered/device parity remains open unless the required captures actually exist.
