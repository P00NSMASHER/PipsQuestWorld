## October 16 — correct Grade 2 release source, teacher retained

The owner identified the ABVM Grade 2 game with Mrs. Benulis at the front
and authorized publishing the requested fixes once finished. The earlier
PR #355 targeted a different, teacher-free source lineage. This candidate
instead starts at release/emma-classroom-61e9b56@dffe6178 (recorded v107).

Implemented all nine photo corrections on that source, preserving its
stationary Mrs. Benulis, compact white Smartboard and existing furniture.
The nameplate now resolves above constructed hair/head bounds after scaling
and floor alignment, with a world-space vertical offset so camera tilt cannot
pull the plate through her head. No portrait assets, curriculum or saves change.

Actually tested: owner-polish runtime and negative control; all 18 staff
constructors and pose/floor/nameplate bounds; 3,009-part room export; Rojo XML
assembly and absence of educational runtime; 21 constructed showroom audits
including all requested wall/desk/closet changes; navigation self-tests and
all nine source-built routes through the full straight hallway.
Corrected the floor parser's rejection of cardinal 90-degree yaw with swapped
world extents and a regression test; preserved pitch/roll/diagonal rejection.
Corrected the literacy guard's stale dark-screen expectation to the release's
existing exact pale idle-screen palette; all its mutation controls still pass.

Resolved release blockers: the staff exit and photographed corridor now stay
on the required straight +X axis, with the complete avatar footprint supported
across the threshold. The unrelated interactive-study CI no longer evaluates
showroom release bases. The inherited publisher identified by release-security
PR #352 now listens only for a dedicated PUBLISH_REQUEST commit, verifies its
exact parent/target/authorization and reruns the teacher, owner-polish, hallway,
navigation and assembled-place gates before upload. Editing the workflow cannot
publish. Independent review and native Roblox/iPhone appearance remain separate
release evidence; no successful publication is claimed here.

---

## October 12, 2026 â€” owner-requested classroom photo detail candidate

Base: `4dd2547386ff4b1c6e42f0a10ab86de6c91f6233`, existing draft PR #343.
This is implementation under the direct photo-match request, **not independent
QA approval, a merge, or a new Roblox publication**. The canonical receipt is
still the successfully published v83 QA preview; older release notes below are
historical, not current publication authority.

Implemented from private review of all eight IMG_2903â€“2910 references:

- Restore the missing rectangular blue alphabet/sun rug, alongside the round
  alphabet rug and black polka-dot rug. One thin noncolliding fabric Part carries
  original vector artwork: Aâ€“Z once, ten numbered clouds, sixteen sun rays.
  Its provisional clear-floor position preserves all sixteen desk/chair pairs.
- Refine all five red/white tablecloth surfaces from coarse checker squares to
  finer crossing translucent gingham threads (ivory, rose, deeper-red crossings).
  This reduces the table's UI-instance count instead of adding physical checks.
- Replace the incorrectly inferred pedestal fan with the photographed low,
  off-white square box-fan silhouette: floor feet, housing, handle, blades and
  front SurfaceGui grille. No new collider or animated fan script.
- No children/adults, gym mat, source photographs, names, external textures or
  private schoolwork added. No lesson/gameplay archive or publishing marker edits.

Actually tested in a materialized exact-base source snapshot:

- Luau 0.741 compilation of every shipped showroom Lua script.
- All **19** constructed-scene `audit_*.py --luau` suites, including existing
  lighting, mobile complexity, windows, doors, lettering, furniture and rugs.
- Added negative tests reject repeated alphabet letters, rug collision/overlap,
  upside-down artwork, missing/opaque gingham threads, floating fan feet and a
  backward fan grille. Existing negative tests and thresholds remain intact.
- Scene export: **3,048 physical Parts**, down from 3,049 at the base; both the
  general 3,100 and stricter 3,050 existing gates pass. All 16 desk/chair pairs stay.
- Navigation self-tests and all nine source-constructed routes pass; furniture
  adapter fallback, permission-denial, partial rollback and atomic activation tests
  pass. These are test doubles, not native Roblox physics or FPS observations.
- Rojo 7.7.1 binary/XML build and assembled classroom-only exclusion guard pass.
  Candidate RBXL SHA256: `37dfbbc799c2fe7186550545f90b6ab857888efbbbb1aa2e0f00802ce0a41ba0`.
- Release-receipt audit and its forged/rollback self-tests pass, still identifying
  v83. Existing synthetic artwork mutation suite passes.

Remaining review gates:

- Obtain the six exact-new-head GitHub workflow results and independent review.
  Local results are not replacements for those required checks. Optional private
  video-auditor self-tests were not completed locally (OpenCV is absent); CI keeps
  its existing pinned environment and gates.
- Native iPhone/iPad review of the new rug/table/fan SurfaceGuis, readability,
  lighting and frame time. Source/headless geometry previews cannot display this
  SurfaceGui artwork or certify native controls/camera. Prior v83 footage is not
  acceptance of these changed details.
- The separately recorded request for a straight outward hallway from the staff
  door remains with the hallway/product owner. This detail pass leaves all hallway
  and closet geometry unchanged; it does **not** resolve that layout requirement.
- Keep PR draft and v83 publication untouched until owner-controlled acceptance.

---

## Historical release-state clarification â€” October 8, 2026 (verified GitHub receipt)

**Published classroom preview:** GitHub Actions [run 37870907504](https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/37870907504) successfully published **Roblox place version 67** from exact source commit `1e67943a0394c4196f630cc5566a1f153ec401b5` to place `114603280760042` on October 9 UTC (October 8 Eastern). The runtime is the classroom-only progress preview, **not** a final visually accepted release.

**Important:** Newer commits in draft PR #339 are *development candidates*. A green Rojo/Luau/GitHub check, source-derived image, or newly staged furniture model is **not evidence of a newer Roblox publication**. The 16 original furniture sets remain fallback; imported premium furniture meshes are still gated (`FurnitureMeshConfig.Enabled=false`). Native iPhone rendering, mobile performance, collision and exact photo parity are not yet certified. The connected Windows machine was offline at the latest check.

The receipt is tracked in [RELEASE_RECEIPT.json](RELEASE_RECEIPT.json) and checked by `verify_release_receipt.py`; CI verifies internal consistency and release gates but cannot query the *current* live Roblox version. Historical sections below that say "live place unchanged" were written **before** the authorized version-67 preview and must not be misread as the latest status. Never publish another candidate from this note alone.

---

## October 8 â€” furniture reconstruction and adversarial close-up visual review

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

## Current continuation â€” stable display avatars / classroom objects (v6)

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

At 1:00â€“1:11 PM Eastern the user authorized foreground laptop use. Native Studio
constructed all 18 staff and the room successfully, then rendered the three
portrait-target staff. The render failed the final visual target: noisy Fabric,
stretched SurfaceGui lettering and rounded hair bumps. Follow-up source fixes
address those concrete defects; they are not a rendered visual pass. Physical
iPhone, real Play-mode question loop and final likeness still need inspection.
At 1:11 PM the user requested background-only operation; Studio was minimized
and remaining source/check work continued without bringing it forward.



## October 13 native finish iteration
- Preserved the existing sixteen desk pairs and straight staff hallway.
- Restored native scaling on counting/phonics labels and enlarged word-wall lettering.
- Applied the original oak material via runtime-safe variant assignment; no Plugin-only map reads during server startup.
- Restored a three-panel blue practice mat beside the front activity rugs (latest owner brief).
- Exact current candidate: 3,050 physical parts, 25/25 classroom source/build checks; native Play construction, typography, mats, and a full out-and-back hallway walk pass.
- Studio iPhone 16 landscape simulation passes startup; the captured scene and touch controls were visually inspected. This is NOT a physical-iPhone FPS result. Console empty after checks.
- Evidence: `qa/NATIVE_FINISH_RECEIPT_20261013.json`; native tests in `qa/native-detail-*.luau`, `qa/native-folding-mat.luau`, and `qa/native-straight-hall-walk.luau`.
- No merge, live publication, marker edits or schedule changes. More architectural/furniture refinement and physical-device validation remain; do not label this the completed photo replica.


## October 13 architectural finish pass
- Corrected ceiling light faces, cross-rail alignment and floating side trim.
- Flattened raised rug graphics; polished existing steel and cabinet joinery without new Parts.
- 25/25 existing source/build checks and new native regression tests pass; native no-teleport hallway walk and iPhone 16 simulator repeated successfully.
- Evidence: `qa/ARCHITECTURAL_REFINEMENT_RECEIPT_20261013.json` and matching review note.
- Original mesh experiment rejected; adapter remains disabled. Photo-fidelity work and physical-iPhone performance remain unfinished.
- Saved a new Documents review file; no merge or Roblox publication.

Complete-export follow-up: 27/27 expanded checks now pass. Strict exporter calibration updated for flat rug print; four bad-geometry mutations rejected in `showroom/audit_flat_rug_source.py`, which is wired into CI. This follow-up changes no runtime geometry.
