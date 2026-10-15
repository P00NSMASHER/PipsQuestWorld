# ABVM Grade 2 — Mrs. Benulis portrait NPC staging

## Intended result
A user-photo-guided, custom static GLB model replaces **only** the stationary
Mrs. Benulis display at the front of the classroom. No questions, menus,
curriculum, other Roblox experiences, or player-avatar swap.

## Source and privacy
The supplied three-view photograph was used locally to create a textured,
sculpted-geometry GLB review candidate. The private portrait and its embedded
face texture are **not** committed to this public repository. Do not expose
the private reference photo, model texture, or generated face material on
GitHub. Ask for appropriate consent before public release of a recognizable
real teacher's likeness.

## Implementation
- `TeacherPortraitAdapter.lua`: uses Roblox `InsertService:LoadAsset` only
  after explicitly enabling a verified owner-controlled Model asset ID.
- `TeacherPortraitConfig.lua`: defaults to disabled and zero ID.
- The existing anchored Mrs. Benulis R15 display remains the **live fallback**.
- The model is vetted against an allowlist (Model/Folder/MeshPart/
  SurfaceAppearance/Attachment only), has a maximum part budget and size
  limits, and is aligned to the existing display's stance and floor level.
- Async import does not block the walk-through or player spawn.

## Acceptance / remaining
1. Obtain an owner-approved, moderated Roblox **Model** asset ID from the
   privately generated GLB (not a GitHub-hosted portrait).
2. Preview the exact asset in Roblox Studio. Check front, quarter, back and
   eye-level close-ups; floor contact, correct orientation, texture mapping,
   no hair/face intersections and iPhone frame rate.
3. Set `TeacherPortraitConfig.ModelAssetId` to that verified ID, enable in an
   isolated review build, and verify the fallback is preserved on failure.
4. Publish the classroom-only place only after real Roblox/iPhone acceptance
   and the existing protected release workflow's safety checks.

## Verification honesty
Only a local offline mesh export and its independent non-Roblox render were
performed for the initial asset prototype. **No Roblox importer moderation,
native runtime acceptance, or published game version is claimed here.**
The candidate is a static decorative model, not a wearable R15 avatar.


## 2026-10-15: Quality gate and technical safety iteration

### Implemented and run
- Added isolated offline GLB geometry checker: mesh/validate_teacher_portrait.py.
- Added five synthetic, fully generated regression tests: sealed anatomy passes;
  left/right parts cannot be confused; missing hand fails; photo-only eyes fail;
  absent GLB fails.
- Added .github/workflows/emma-teacher-portrait-gate.yml to run those checks
  and verify disabled release flags, teacher fallback, and private data isolation.
- Dedicated Emma Teacher Portrait Structural Gate succeeded on candidate
  a8d7b7c36ead512d99d011be5d542b3b8813d446
  (GitHub Actions run 38684066818). This is not a native render test.
- Original local V2 GLB fails these quality checks: no properly named separate
  arm solids, no individually sculpted 3D eyes, head slightly over per-mesh
  triangle budget.
- Another local V3 sculpting experiment added 3D eyes, separate natural arms,
  shaped hands and fuller hair. Visual result remained unsuitable; 140 mesh
  nodes exceeded the 95-node budget. V3 is REJECTED, not imported.
- Roblox adapter now requires FOUR separate approvals, all default false:
  verified creator ownership, real Studio visual acceptance, actual iPhone
  visual acceptance, and teacher likeness-publication permission.
  It retains the original R15 teacher until safe load, texture preload,
  and placement succeed.

### Next production 3D sculpt acceptance
1. Build sculpted adult face with matching lids, eyes, brow shape, nose, cheeks,
   chin, and natural smile. No flat photo mask; no protruding doll eyes.
2. Build coherent, shoulder-length, side-parted highlighted bob with volumetric
   layers, curled tips, correct face framing, and no helmet/stringy hair shapes.
3. Give clothing, hands, shoulders, pants, and shoes natural adult proportions.
4. Use approximately 95 or fewer MeshParts, <=95k total triangles,
   <19.5k triangles per MeshPart, <18MB private Model candidate; all central
   anatomy must be closed. These are staging targets, not verified Roblox caps.
5. Inspect actual model renders front/quarter/side/back AND close-up against
   the original three-view references; reject mismatches even if tests pass.
6. Confirm public likeness permission, Roblox creator ownership/moderation,
   native Roblox Studio appearance and real iPhone frame rate before enabling.

### Unrelated CI failures retained
Emma Classroom CI fails the preexisting older tiny-game contract, and Emma
Classroom Replica CI fails the left-hall/closet sky/floor audit. Do not weaken
those tests; PR #353 is not globally green.
