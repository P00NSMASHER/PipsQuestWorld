# Foundation exact-canonical spawn/entry collision delta

- Owner: Roblox High School Foundation
- Input product SHA: `43230492964ea637f69747e25a3e72d6cb268ebe`
- Input coordination SHA: `fe15c1e41ea9a5b26ff33712d33c3eff25500159`
- Reference clip/time: A@00:05 frontage/steps/crest; A@00:25 bright atrium/circular display; A@00:45 broad corridor/staircase; A@02:05 stairwell/item view
- Acceptance criteria: preserve one spawn/clock/location/Lighting authority; remove the exact spawn-footprint collision; provide one uninterrupted exterior spawn -> steps -> entry -> atrium -> corridor/stair route; retain all existing room and town seams; require exact-head guards, independent QA, and rendered/device comparison.
- Output location: `coordination/reference/rhs2-entry-6fe2541/FOUNDATION_4323049_SPAWN_AABB_DELTA.md`
- Blocker: no product producer is active. Exact canonical Smoke, deterministic Package, and Control Tower activation of the sole Pip High Free Roam P1 producer are required before `school/**` writes.
- Next handoff: Pip High Free Roam consumes this contract only after activation; Roblox High School QA & Contract independently validates the resulting exact candidate.

This coordination-only delta adds one bounded, exact-canonical geometry finding to `FOUNDATION_AUTHORITY_ACCEPTANCE.md`. It does not alter product code or close a visual-parity gap.

## Exact current geometry

The repaired canonical retains these byte-identical Foundation surfaces:

| Surface | Blob |
| --- | --- |
| `school/src/server/CampusBuilder.server.lua` | `402bc78ab622464e2f6ee12cc737ad32b6e8143a` |
| `school/src/shared/SchoolConfig.lua` | `334705e54cab66bd586f356d3f6ba0cfe28a5340` |
| `school/default.project.json` | `ba5e85e82652f137cb17e76016f062731c033761` |
| `school/tests/foundation_world_contract_spec.lua` | `bbf5f7ed9a8bcb55556e0280eb1690b9bed1634a` |

Derived directly from the canonical builder:

| Named geometry | Center / size | Exact implication |
| --- | --- | --- |
| `MainSpawn` | center (0, 1, 105), size (10, 1, 10) | X footprint [-5, 5], Z footprint [100, 110] |
| `EntryMat` | center (0, 1.05, 111), size (16, 0.12, 8) | X footprint [-8, 8], Z footprint [107, 115] |
| `FrontLobbyFloor` | center (0, 0.75, 101), size (54, 0.45, 32) | lobby Z span [85, 117] |
| `FrontGlassDoor` plane | Z=121.6 | exterior is beyond the current lobby/spawn |
| `FrontPlaza` | center (0, 0.7, 140), size (116, 0.45, 34) | exterior plaza Z span [123, 157] |
| `CentralHall` | center (0, 0.7, 0), size (34, 0.4, 218) | primary spine Z span [-109, 109] |
| `SchoolEntrance` seam | (0, 3, 142) | single registered travel seam on the exterior plaza |

### New bounded finding: spawn AABB intersects the entry mat

`MainSpawn` and `EntryMat` overlap across X [-5, 5] and Z [107, 110], a 10-by-3-stud horizontal intersection. Both are generated with collision enabled: `MainSpawn` uses the default `SpawnLocation.CanCollide`, while `EntryMat` inherits the default from `makePart`. Their vertical volumes also intersect: the spawn spans Y [0.5, 1.5], and the mat spans approximately Y [0.99, 1.11].

Therefore the current spawn footprint is not only inside the lobby (16.6 studs behind the door plane); it is penetrated by collidable decorative geometry. Static guard success does not validate this route, because the current Foundation contract covers the AutoShop road seam but not school-entry spawn clearance.

This is a deterministic authority/geometry gap. It is separate from the still-pending rendered comparison.

## P1 implementation contract

When Control Tower activates the sole P1 producer:

1. Relocate the existing `MainSpawn` to the exterior approach; do not create a second `SpawnLocation`. Place its complete character-clearance envelope outside stairs, curbs, mats, rails, planters, roadway parts, doors, and decorative collision.
2. Keep `SchoolEntrance` as the only entry travel record. If the approach elevation changes, update this existing seam atomically rather than adding a parallel location.
3. Build the A@00:05 hierarchy on the existing centerline: broad stair run, deep landing, readable crest zone, and red/white/blue architectural massing. Dimensions and RGB values remain engineering targets to tune under rendered comparison, not facts extracted from footage.
4. Feed the doors into one bright atrium organized around one low circular display, with two avatar-safe circulation arcs, then directly into the existing `CentralHall`.
5. Add one visible, guarded stair/landing composition from the atrium/corridor. Do not create an unguarded upper-level void or a second room registry.
6. Preserve the current unique schedule/clock owner, global Lighting mapping, all `RoomSpawns`, classroom centers, Gym, Cafeteria, Courtyard, housing anchors, and town/vehicle seams.
7. HUD layout remains Free Roam-owned. Foundation geometry must leave the A@02:05 stairwell route observable without assuming player-authored nameplate text or uncorrected 2x playback timing.

Suggested palette tokens remain provisional: retain the existing navy family `Color3.fromRGB(44, 62, 92)`, add one saturated red family and bright neutral white family, and tune only with authorized rendered comparison. No crest asset ID, exact luminance, or exact reference RGB is asserted.

## Deterministic checks to add on the activated candidate

Extend the existing Foundation contract without weakening its AutoShop assertion:

- exactly one `SpawnLocation` named `SchoolCampus.MainSpawn`;
- `MainSpawn` is exterior to the door plane and does not intersect any collidable geometry AABB;
- one `SchoolEntrance` record and one respawn assignment path;
- named entrance stair, landing, atrium display, and guarded stair-core anchors exist;
- the sampled path from spawn center through landing, door, both sides of the circular display, `CentralHall`, and stair landing maintains character clearance;
- no runtime `Lighting.ClockTime` writer and no second schedule loop;
- existing room/town/housing/vehicle anchor assertions remain unchanged and green.

Rendered desktop, iPhone, and iPad checks remain `RENDERED_PENDING` until actually captured. Library A byte materialization is presently a Content QA-owned transient 502 and does not authorize invented visual detail or block this exact-code finding.
