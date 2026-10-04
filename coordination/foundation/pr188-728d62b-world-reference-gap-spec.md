# PR 188 exact-head world/reference gap specification

## Artifact contract

- **Owner:** Roblox High School Foundation
- **Input candidate SHA:** `728d62b909bf8d8b7bd9d0466f3fb18c80ebb895` (PR 188)
- **Canonical base SHA:** `43230492964ea637f69747e25a3e72d6cb268ebe`
- **Reference clip/time:** A@00:05 frontage/entrance, A@00:25 atrium, A@00:45 corridor/stairs, A@02:05 stair flight/item-slot view
- **Acceptance criteria:** preserve one mapped campus builder, one mapped school clock/schedule authority, one `MainSpawn`, the existing server-owned interfaces, and the static spawn-clearance contract; bind any visual repair to exact-head CI and later rendered/runtime comparison
- **Output location:** `coordination/foundation/pr188-728d62b-world-reference-gap-spec.md`
- **Blocker:** Foundation is not the WIP-authorized product producer; PR 188 has no independent QA approval on exact head `728d62b`; physical traversal and rendered desktop/iPhone/iPad comparisons are pending
- **Next handoff:** Roblox High School QA & Contract reviews this source-grounded gap on exact `728d62b`; only if QA returns a concrete defect may the existing sole Free Roam producer amend PR 188
- **Status:** `EVIDENCE_ONLY__NO_PRODUCT_WRITE__RUNTIME_AND_RENDERED_PENDING`

The durable Content QA pack at `a2ed245455176a2dad83f2a87c477b1f5b3b1158` supplies the exact frame hashes and bounded observations used here. A direct fresh materialization attempt returned transient HTTP 502 twice, so this artifact does not invent additional pixel, color, lighting, or hierarchy claims.

## Live gate snapshot

- WIP schema 53 keeps PR 188 as the sole product producer at the 3-item cap.
- Exact head `728d62b` is green in Foundation run `37237332258`, Class/Education run `37237332337`, and Progression run `37237332270`.
- No independent PR review is bound to `728d62b`; the earlier `3aad19e` QA receipt is stale for authorization.
- Canonical remains `43230492964ea637f69747e25a3e72d6cb268ebe`.
- Exact parity is not established.

## Authority audit

Static authority result: **PASS, no new authority introduced by PR 188**.

- `school/default.project.json` maps one `CampusBuilder` and one `FoundationBootstrap` under `ServerScriptService.SchoolFoundation`.
- `SchoolLoop.server.lua` exists in the source tree but is not mapped into the active project; it is not a second runtime clock/schedule authority.
- `CampusBuilder.server.lua` creates exactly one `SpawnLocation`, named `MainSpawn`.
- `FoundationBootstrap.server.lua` remains the mapped owner of school day, period progression, state publication, spawn assignment, and Foundation travel.
- PR 188 does not add a second clock, spawn, location registry, economy, progression, or persistence writer.

## Exact source-to-reference inventory

### A@00:05 — frontage, broad stairs, crest, red/white/blue massing

Current exact-head source provides:

- blue facade slabs at x `-49` and `49`, each `64×25×1.2`;
- four red columns at x `-80/-18/18/80`;
- a `174×2×2.2` red roofline and `38×4×2` white header;
- one `15×17×1.5` rectangular `SchoolCrest` panel at x `49` with generated `PH / star` text;
- a `44×1.2×16` white canopy;
- seven centered decorative tread parts, narrowing from 72 to 48 studs;
- symmetric red planters at x `-43/43` with four total evergreen crowns;
- one exterior `MainSpawn` at `(0, 1.55, 177)`.

Static disposition:

- The palette, symmetry, broad centered approach, crest zone, landscaping, and entrance massing are source-present.
- The code supplies a rectangular text panel, not a proven shield silhouette or an authorized crest asset. The footage does not establish an asset ID, so QA must compare silhouette and placement without demanding an invented asset.
- The seven `EntryStep` parts are all `CanCollide=false`. Their top surfaces rise above the approximately 0.9-stud approach/plaza surface, so the player may visually pass through the decorative treads even when traversal remains mechanically unblocked. This is a **runtime foot/leg clipping risk**, not a static failure claim.
- The existing source-parsed AABB contract still proves that the single spawn does not positively overlap `CampusGround`, `EntryWalk`, `DropOffLane`, or `ParkingLot`.

Runtime checkpoint:

1. Walk directly from `MainSpawn` through the seven tread volumes and the three noncollidable glass doors.
2. Record any foot/leg occlusion, camera bump, snag, drop, or unexpected route deviation.
3. Fail interaction smoke only on observed clipping/blocking; do not infer it from source alone.

### A@00:25 — bright atrium and circular focal display

Current exact-head source provides:

- a `54×32` marble lobby floor;
- one three-tier cylinder display centered at `(0, z=91)`, with diameters `26/24/21`;
- a `13×0.7×9` display top;
- sixteen noncollidable Neon ceiling strips in a 4×4 arrangement at y `16.2`;
- paired blue and red vertical bands at x `-27/27`;
- about 14 studs of lateral floor width on each side of the 26-stud display within the 54-stud lobby width.

Static disposition:

- One low circular multi-tier focal display, repeated linear ceiling strips, school-color bands, and circulation on both sides are source-present.
- The ceiling strips are Neon parts, but the candidate adds no `PointLight`, `SurfaceLight`, or `SpotLight`. Project lighting remains `Brightness=2`, `ClockTime=10.5`, `GlobalShadows=true`, `ShadowMap`. Therefore source inspection cannot certify the reference's bright atrium luminance or shadow readability.
- Rendered comparison must record camera/FOV, display clearance, perceived brightness, and whether the display or HUD blocks either circulation lane.

### A@00:45 and A@02:05 — corridor/stair sightline and blue-railed flight

Current exact-head source provides:

- a `34×218` central hall spine;
- ten `25×0.9×2.8` concrete stair steps from z `-91` to `-113.5`, rising from center y `1.15` to `7.0`;
- a `32×1×13` upper landing at z `-119`;
- one blue and one red **transverse upper-landing rail** at z `-112.8`;
- repeated hall beams and locker banks.

Concrete reference gap:

- A@02:05 visibly shows a stair flight with blue rails and red/blue wall bands.
- The candidate has no rail following either side of the ascending stair run and no stair-local red/blue wall bands. The existing `UpperHallRailBlue` and `UpperHallRailRed` span x at a single z position and describe the landing edge, not side rails along the flight.
- Presence-only tests currently accept the landing rails and stair loop; they do not prove the A@02:05 stair-flight composition.

Bounded repair specification, only if exact-head QA returns this as a defect:

1. Keep the existing ten-step run, central axis, landing, and 25-stud clear tread width.
2. Add blue rail geometry following both flight edges outside the usable tread envelope; keep rail collision from narrowing or snagging the route.
3. Continue a red/blue band motif through the stairwell without covering doors, route openings, or the central A@00:45 sightline.
4. Do not add a second spawn, clock, period loop, location registry, travel handler, or runtime root.
5. Extend the Foundation world contract to distinguish stair-flight side rails/bands from the existing transverse landing rails.
6. Re-run all three exact-head guards, then require comparable-FOV rendered captures at A@00:45 and A@02:05 plus physical ascent/descent smoke.

## QA decision table

| Check | Static state at 728d62b | Required next evidence |
| --- | --- | --- |
| Single spawn and mapped Foundation authority | PASS | Preserve |
| Spawn AABB clear of named approach geometry | PASS | Physical traversal |
| Frontage palette/massing/crest zone | PRESENT | A@00:05 rendered comparison |
| Decorative exterior treads | NONCOLLIDABLE | Runtime clipping/sightline check |
| Circular atrium display and repeated ceiling strips | PRESENT | A@00:25 luminance and clearance capture |
| Corridor stair run | PRESENT | A@00:45 traversal/sightline capture |
| Blue rails and red/blue bands along stair flight | SOURCE GAP | QA defect decision; producer repair only if confirmed |
| Exact RHS2 parity | NOT ESTABLISHED | Rendered desktop/iPhone/iPad and runtime comparison |
