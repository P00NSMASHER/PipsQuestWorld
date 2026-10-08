## October 8 — furniture reconstruction and adversarial close-up visual review

**Current source checkpoint:** `4ab68c81456d0fb898ad86429d508b700cc3b3dc`. The new classroom-only chair/desks changes and source-derived previews are archived in [the furniture QA gallery](../../docs/visual-qa/emma-furniture-20261008/README.md).

Implemented: Reworked all 16 chairs with single continuous rounded physical shells and invisibly simple collision; rejected an intermediate multi-panel shell after inspecting actual rendered close-ups because it visibly resembled stacked plates. Added underseat steel runners, thin laminate desk edge, front bevel, slimmer underdesk baskets, and support stretchers. Retained all desk positions, classroom-only first-person movement and isolated schoolwork systems. Fixed blank aerial preview false positives with an explicit camera and pixel occupancy check.

Actually tested: Luau compilation, Rojo binary/XML assembly, schoolwork-runtime exclusion, executed Luau scene constructors, 2,688-part geometry budget, and all six exact-source GitHub workflow checks including the independent visual screenshots (run 37798089586). Verified actual image pixels for front, back, isometric, chair and desk close-ups. A four-piece chair-back attempt was *rejected by visual QA*, and its screenshots were retained.

Not tested/known remaining limitations: Native Roblox rendering on Studio/iPhone, true seat collision or mobile fps, exact photo-to-world room measurements. Current continuous chairs still look too oval to meet a premium professionally meshed chair target; desks remain original part geometry, not production imported meshes. **No production publish / PR merge**. Keep the draft until native capture and substantive visual quality acceptance.

---

# CURRENT DIRECTION: classroom replica only (October 8, 2026)

## Continued geometry/visual iteration, no laptop

Based on the rejected October 8 phone capture and a simplified offline 3D model built
from the actual room's **source coordinates**, not from imaginary marketing renders:

- Resized all 16 physical student tabletops from 7 x 4.6 to 5.78 x 3.86
  studs (laminate top 5.72 x 3.80). Updated lower trays, metal legs, glides,
  desk edges and sign placement accordingly. Same desk count and aisle topology.
- Reduced every oversized chair from 2.9 wide to 2.5 wide, with smaller
  molded backs, handhold, hardware and re-aligned accents. Chairs remain
  solid physical colliders, not image props.
- Horizontal gaps between the 8-stud-center neighboring desktops increase
  from roughly 1 stud to 2.28 studs. This is static dimensional evidence,
  **not** an independently measured Roblox walk collision clearance.
- Moved three supply baskets from unsupported mid-gap x=-20,-4,16 onto actual
  middle-row table centers x=-24,-8,12, preventing floating school supplies.
- Removed five remaining oversized flat rule cards that overlapped the
  new right-wall framed boards; removed eight back-wall number cards that
  clipped into the student artwork gallery.
- Forked ArtPass inside the showroom, preserving the original education
  game/study mode sources and independent ABVM schoolwork update pipeline.
- Original still-to-check visual limitations: room height, exact furniture
  silhouette, smoothness of part-built hardware, Roblox surface/decal visibility,
  clipping in running engine, physical iPhone FOV and performance.
- Independent previews: source-derived 3D bounding proxies and a measured
  floor plan were created outside Roblox for visual/spatial correction;
  they **are not** native game captures or an exact imported/engine-rendered
  copy of all Roblox pieces. Available in the originating ChatGPT task
  as PNG and glTF assets, not assumed as acceptance evidence.

The showroom build CI compiles the actual shipped scripts and builds an RBXL
and RBXLX. The independent place guard checks no question bank, quiz remotes,
study UI, or study persistence is included. Live place remains unchanged;
publication requires a new specific user-approved acceptance marker.



The October 8 iPhone recording rejects v63's quiz-first classroom. The user
explicitly stopped the question/teacher/UI work. New single objective: build
the highest-quality recognizable ABVM classroom environment we can and show
actual Roblox renders before approving a live version.

New build target: **school/emma-showroom.project.json**.
This is NOT the old school/emma-classroom.project.json study mode.

Implemented in the replica candidate:
- Compiled runtime contains only the room, two non-interactive art passes,
  spawn bootstrap, and native first-person exploration.
- No QuestionBank, EmmaStudy client/server scripts, progress UI, teaching
  NPCs, answer remotes, score handling or DataStore are included in the
  showcase place.
- Maintains the photographed room cues: warm walls, navy trim, timber floor,
  double classroom doors/hall glimpse, chalkboard and Smartboard,
  16 paired desks, tall wood windows, radiator, cubbies, reading corner,
  teacher desk, crucifix and school motto.
- Replaces oversize wall values signs and question board with human-scale
  non-interactive wall art, physical fixtures, small notice boards and
  ambient classroom details; no screen-covering UI.
- Spawn is in a clear rear aisle, not an invisible seat. Native mobile
  thumbstick/jump/camera movement stays functional.
- Keeps the old educational files in the repository without bundling them.
  Existing content-refresh jobs are not renamed, stopped or rewritten.
- Publisher targets this showroom only; requires a NEW
  `requested-mode: classroom-replica-only` marker AND
  `visual-acceptance: approved` in PUBLISH_REQUEST. Existing v63
  marker cannot silently release this build.

Verification status:
- GitHub source writes are complete. Independent exact-source Luau/Rojo CI
  and built-place XML screening are required and not yet described as passing.
- Actual Roblox Studio or published-place screenshots, iPhone movement,
  part lighting/material appearance, and physical reference-parity are
  **NOT verified** by source edits.
- Do NOT publish, merge or describe this as polished until a real Roblox render
  and hallway/window/desk walkthrough meets visual acceptance.

Visual acceptance sequence:
1. Capture iPhone entry view showing the front board and the whole room with
   no study widgets or staff NPCs.
2. Walk through the center and right aisles without collision traps, sitting,
   teleporting or controls stealing focus.
3. Compare yellow/cream walls, blue trim, desk/chair proportions, window
   wall, reading corner, doorway and ABVM board treatment to the saved real
   classroom photographs. Reject any generic/primitive-looking elements.
4. Check phone frame time, materials, lighting, distance-readability and
   clipping before release. Favor correcting the actual 3D geometry rather
   than adding menus or more graphics test infrastructure.

---

## Current continuation — stable display avatars / classroom objects (v6)

Version 58 failed the user's real recording: detached/missing heads during swaps,
poor staff likeness and an unfinished room. This continuation removes native rig
joint construction and Humanoid state evaluation from anchored display NPCs;
whole-model positioning owns their neutral pose. Teacher replacement destroys the
previous model synchronously. The detailed-object pass adds bound/ruled notebooks,
desk hardware, hinged keyboard/trackpad laptop, spherical globe/cradle/continents,
raised cabinet doors/hardware, cart rails and tissue/trash-can detail.

Source, behavior, object-budget and build checks pass locally. Native Roblox
rendering, likeness, live asset delivery and physical iPhone acceptance are still
UNVERIFIED: PAAM-L044 is offline. No visual pass or five-star claim is recorded.
See `DISPLAY_RIG_CLASSROOM_V6.md` for exact scope and reuse limits.

# Current repair: native avatar bodies and visible phone answers

The October 7 5:19 PM iPhone recording rejects published version 57. The prior procedural teacher repair did not meet the user's goal. `NATIVE_STAFF_PHONE_REPAIR.md` records its failures, the replacement, actual test results, and the pending Roblox/iPhone acceptance. This candidate has not been published; version 57 remains live until the replacement is inspected in Roblox.

# Current repair: friendly, readable teachers

The October 7 4:11 PM iPhone recording rejects version 55. See `FRIENDLY_STAFF_FIX.md` for the concrete face/hair/light repair and regression checks. Native/device acceptance of the replacement remains pending; earlier visual pass descriptions are historical.

## Current visual revision

Version 54 was reviewed on a physical iPhone and rated 2/5 by the user. The next visual revision is documented in `VISUAL_QUALITY_V3.md`: rounded staff/furniture, daylight, actual storage detail and close study camera. Source/projection checks pass; a new native/device render must still be reviewed. Previous evidence below remains historical.

# Emma Study Classroom handoff

## Implemented

- Made lifetime progress persistence monotonic across out-of-order DataStore
  completions. Older asynchronous saves can no longer reduce total correct,
  completed sessions, or per-skill correct counts.
- Player-removal and server-shutdown paths now await their final DataStore write
  instead of starting a task and relying on a fixed two-second delay.
- Restored normal Roblox movement, jump, autorotation and touch camera control.
- Added a 44px `Study view` / `Look around` toggle. Study view retains the intentional teacher/Smartboard/doorway composition; Look around restores the character camera.
- Strengthened classroom CI so a future permanent movement lock fails the tiny-game contract.

## Actually tested

- Executed the actual server source against a forced stale-save regression and
  verified that newer lifetime/session/skill totals survive.
- Executed the shutdown callback and verified its final write is visible before
  the callback returns.
- Luau compilation for every classroom client/server/shared source.
- Isolated Rojo place build.
- Classroom CI contract checks, including both camera modes and absence of movement-lock assignments.

## Not tested

- Roblox Studio runtime launch.
- Live Roblox DataStore behavior under throttling, shutdown, and reconnect.
- Physical iPhone thumbstick, jump, camera orbit and safe-area interaction.
- Final composed Study view against the authorized classroom reference.

## Known release hold

This candidate is not runtime-complete or publishable until an actual Roblox/iPhone capture proves movement, camera restoration, Study view composition, question interaction and the 10-question loop on the exact candidate head.

## Staff/detail continuation

The next candidate includes `STAFF_DETAIL_PASS.md`: a new native staff factory
for all 18 profiles, detailed Bolich/McBreen/Boyer outfits/accessories, grouped
limb-detail poses, paired desks and photo-guided window/rug/coat-storage details.
`tests/geometry_behavior.py` executes both actual constructors with service/math
doubles. The previous stale-save and awaited-shutdown fixes remain intact.
This candidate has no Studio or physical-iPhone visual pass and does not claim
portrait-level rendering or a measured exact classroom replica.

## Authorized native Studio check and visible fixes

At 1:00–1:11 PM Eastern the user authorized foreground laptop use. Native Studio
constructed all 18 staff and the room successfully, then rendered the three
portrait-target staff. The render failed the final visual target: noisy Fabric,
stretched SurfaceGui lettering and rounded hair bumps. Follow-up source fixes
address those concrete defects; they are not a rendered visual pass. Physical
iPhone, real Play-mode question loop and final likeness still need inspection.
At 1:11 PM the user requested background-only operation; Studio was minimized
and remaining source/check work continued without bringing it forward.
