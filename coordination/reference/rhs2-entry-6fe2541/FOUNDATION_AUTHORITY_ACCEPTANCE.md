# RHS2 entry slice — Foundation authority acceptance

- Owner: Roblox High School Foundation
- Input product SHA: `6fe254139ae3382f0ab71e6725df00c1c1a69822`
- Reference clips: A@00:05 frontage; A@00:25 atrium; A@00:45 corridor/staircase; A@02:05 stairwell/item view
- Acceptance scope: world geometry, spawn/location seams, lighting ownership, navigation clearance, and deterministic authority checks
- Output location: this coordination evidence file; future product changes only on the one Control-Tower-activated P1 producer branch
- Blocker: exact canonical `6fe2541` still requires Smoke and deterministic Package, then fresh Control Tower activation
- Next handoff: Pip High Free Roam implements the single P1 slice; Roblox High School QA & Contract validates the exact candidate independently

This is an authority-specific annex to `coordination/reference/rhs2-entry-6fe2541/HANDOFF.md`. It does not create product code, a producer branch, or a visual-parity claim.

## Evidence boundary

The durable reference index records the observable A timestamps above. The existing handoff records direct inspection of those four frames and viewport estimates. Library byte transfer was transiently unavailable during this run, so this annex does not add new visual claims; Content QA owns retrieval continuity. Visible 2x playback prevents uncorrected movement or animation timing inference.

## Current canonical inventory

| Surface | Current canonical state | Reference-visible gap |
| --- | --- | --- |
| Spawn | One `SchoolCampus.MainSpawn` at `CFrame.new(0, 1, 105)`; `FoundationBootstrap` assigns it through `Player.RespawnLocation` | Player currently spawns inside the lobby spine, so the spawn-to-frontage approach is not observable |
| Entrance | Flat `FrontPlaza` 116x34, `EntryWalk`, metal canopy, three 7-stud glass doors | A@00:05 shows a broad stair approach, stronger red/white/blue facade hierarchy, landscaping, and a crest |
| Lobby | `FrontLobbyFloor` 54x32 with desk and trophy case | A@00:25 shows a substantially broader bright atrium with a low circular focal display and circulation on both sides |
| Corridor | `CentralHall` is 34x218 with wood-plank floor, lockers and ceiling beams | A@00:45 shows a broad corridor connected to a visible staircase; canonical has no comparable stair core |
| Stairwell | No school stair or upper landing is generated | A@00:45 and A@02:05 require a continuous stair/landing composition |
| Lighting | One Rojo-mapped Lighting owner: Brightness 2, ClockTime 10.5, ShadowMap, Ambient 0.55, OutdoorAmbient 0.60 | Bright clean interior is visible, but exact light intensities, color temperature and exposure are not established |
| Location seam | `SchoolConfig.WorldLocations.SchoolEntrance = Vector3.new(0, 3, 142)` | Any raised landing or relocated approach must move this existing seam atomically; do not add another entrance registry |
| Clock authority | `FoundationBootstrap` owns schedule progression with `os.clock()`; no second world-clock writer is required | Appearance work must not add a second schedule or Lighting clock authority |

## Bounded implementation specification

The following dimensions are engineering starting points against the current 190-stud school shell, not measurements inferred from the video. Rendered comparison must tune them.

1. Exterior approach and facade
   - Preserve the existing named centerline and replace the flat entrance composition coherently: a raised entry podium, one broad centered stair run, symmetric planted edges, three-door glass entry, white canopy, saturated blue field, red framing, and a prominent crest zone.
   - Target a stair clear width of at least 36 studs, risers no higher than 1 stud, treads at least 2.25 studs, and an unobstructed landing at least 12 studs deep. These are navigation thresholds, not reference-derived dimensions.
   - Keep `FrontPlaza`, `EntryWalk`, `FrontGlassDoor`, and `SchoolEntrance` as stable semantic anchors, or update every consumer and contract in the same candidate.
   - Do not guess a crest asset ID. Use an original/authorized crest treatment or a procedural placeholder and leave exact artwork for Content QA evidence.

2. Singular exterior spawn
   - Relocate the existing `MainSpawn`; never instantiate a second `SpawnLocation`.
   - Place it on the exterior approach centerline far enough from the stair landing to frame the full entrance on spawn, facing the entrance. Preserve a safe ten-stud character clearance and a continuous walk to the doors.
   - Update only the existing `SchoolEntrance` location seam if travel should land on the raised approach. `FoundationBootstrap.getMainSpawn()` and `Player.RespawnLocation` remain the only respawn path.

3. Atrium
   - Expand the current 54x32 lobby into an open entry volume approximately 80–96 studs wide and 52–68 studs deep, subject to rendered tuning without breaking the existing 190-stud shell.
   - Add one low circular focal display approximately 24–30 studs in diameter with two clear circulation arcs of at least 12 studs each.
   - Raise the atrium volume to read as two stories, using pale floor/wall fields, red and blue architectural bands, glass, and repeated bright ceiling strips. Decorative/seasonal props remain unknown and nonblocking.
   - The atrium must feed the existing `CentralHall` directly without teleporting, duplicating a room registry, or intersecting the current lobby/door geometry.

4. Corridor and stair core
   - Keep `CentralHall` as the single primary interior spine and retain at least 24 studs of clear walking width after benches, lockers, rails, and display geometry.
   - Add one visible staircase/landing composition connected to the atrium/corridor, with paired rails, head clearance, closed riser collision, and a bounded upper landing. The landing may be presentation-only for P1, but it must never imply a traversable upper corridor that ends in an unguarded void.
   - Preserve all `RoomSpawns`, classroom centers, Gym, Cafeteria, Courtyard, housing seams, AutoShop road seam, and their unique owners.

5. Lighting and materials
   - Keep `school/default.project.json` as the sole global Lighting mapping. Add fixture geometry/lights under `CampusBuilder`; do not add a runtime loop that writes `Lighting.ClockTime` or duplicates the school schedule.
   - Start from the existing navy `Color3.fromRGB(44, 62, 92)`, then add one red and one bright white architectural family. Exact RGB values require frame sampling/rendered comparison and are not certified here.
   - Prefer concrete/terrazzo or pale smooth floors in the atrium, brick/smooth panels on the facade, glass at doors/transoms, and metal rails. Do not import retired map geometry.

## Exact candidate collision inventory

Expected product touch set for the activated producer:

- `school/src/server/CampusBuilder.server.lua`: entrance, atrium, stairs, fixtures, and relocation of the one existing `MainSpawn`.
- `school/src/shared/SchoolConfig.lua`: only if `SchoolEntrance` moves; preserve all other registries and spawn seams.
- `school/default.project.json`: only if global Lighting values change; preserve one Lighting owner.
- `school/tests/foundation_world_contract_spec.lua`: extend navigation/anchor/unique-spawn assertions without weakening AutoShop or housing checks.
- A fresh exact-base lighting-authority contract: assert one project Lighting mapping and no runtime `Lighting.ClockTime` writer.

The historical prep branch `prep/high-school-foundation-spawn-authority-23cc398-v1` is 15 commits behind canonical and two test commits ahead. It must not be merged as preparation. Re-express any still-useful assertions from that branch on the future exact activated base.

Foundation must not touch `CanonicalSchoolClient.client.lua`, HUD placement, economy, progression, persistence, class activity, shopping, housing ownership, or vehicle logic. Free Roam owns the compact HUD and existing action wiring.

## Deterministic acceptance

The exact activated candidate must prove all of the following before independent QA:

- exactly one `SpawnLocation` named `SchoolCampus.MainSpawn`;
- exactly one assignment path to `Player.RespawnLocation`, still consuming that spawn;
- exactly one `SchoolEntrance` registry record and no parallel location table;
- no new schedule writer and no runtime `Lighting.ClockTime` writer;
- exterior spawn -> stairs -> door -> atrium -> either side of the circular display -> `CentralHall` is one continuous collision-safe route;
- at least 24 studs of clear corridor width and at least 12 studs around each side of the central display at the narrowest point;
- doors, risers, landings, rails, ceilings and streaming boundaries do not trap or drop the avatar;
- existing room spawns, AutoShopRoad, housing plot anchors, class travel, school schedule and three canonical guard suites remain intact;
- rendered checkpoints at A@00:05, A@00:25, A@00:45 and A@02:05 are captured at comparable camera/FOV;
- desktop and target phone/tablet comparisons remain `RENDERED_PENDING` until actually run.

## Exit status

Foundation preparation is complete for this bounded authority annex. No product parity gap is closed by this file. Product work remains blocked until Smoke -> Package -> Control Tower activation, after which the one Free Roam producer consumes this specification and Foundation reviews only its owned world/clock/spawn/environment surfaces.
