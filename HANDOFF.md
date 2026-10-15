# ABVM Grade 2 — Mrs. Benulis portrait NPC handoff

## Implemented
- Isolated optional static Roblox portrait replacement adapter and Rojo mapping.
- Existing stationary Mrs. Benulis R15 display is preserved by default.
- Four fail-closed permissions/review gates: creator ownership, native Studio,
  actual iPhone, and public likeness permission. All are disabled, as is the
  asset ID (zero) and feature flag.
- Asset class/scale budget allowlist; texture preload; exact original fallback
  retained unless the verified Model has loaded and is placed.
- Private standalone 3D structural GLB quality gate and five synthetic
  regression tests. Public GitHub contains no teacher photos, skin textures,
  or GLB binary.
- Structural quality CI workflow for the isolated teacher integration.
- Private professional sculpt handoff/turnaround package created locally,
  not published to this public repo.

## Actually tested
- New five-case synthetic geometry acceptance regression suite: passed.
- Dedicated GitHub Actions workflow, head a8d7b7c36ead512d99d011be5d542b3b8813d446,
  run 38684066818: success.
- Actual private V2 GLB fails the acceptance checker (no separate arm
  solids/3D eyes; per-mesh face triangle budget).
- Private V3 sculpting candidate improved component breakdown but remains
  visibly unacceptable; rejected, 140 > 95 mesh budget. Never import.
- Existing non-portrait failures continue: old Emma tiny-game CI contract and
  hallway left-turn floor/sky audit. They are not relaxed.

## Not tested / blocked
- No artist-quality accepted likeness or Blender project yet.
- No successful verified Roblox Model import/moderation for this portrait.
- No native Studio preview or iPhone performance/close-up acceptance.
- No permission to publish a recognizable real teacher is established.
- No merged PR and no live Roblox place publication.

## Next
A genuinely high-fidelity human-crafted or professionally generated 3D sculpt
must match the user-supplied three-view image and approved polished turnaround.
Keep portrait images private, inspect real 3D front/quarter/profile/rear,
run the offline geometry checker, then only after full owner/likeness/native
acceptance activate the adapter in a review-only build. No premature merges.

## 2026-10-15 follow-up: Private v6 3D sculpt study

- Built a **real**, private standalone static GLB with colored 3D surfaces,
  rather than another concept illustration. Source generator, five actual
  camera renders, an editable-Blender import script and structural QA report
  are retained outside this public repository.
- Reconstructed and independently re-imported **53 closed component meshes**,
  **59,294 triangles**, **6.21-stud height**, GLB **1,024,696 bytes**.
  The previously added structural checker accepted the **exact v6 GLB**
  with zero reported violations. SHA256:
  `02db13fd44218d6f7be7df78a50825f2935f4e429ccd4f1f98ccc08e38239e53`.
- Actual geometry rendered offline in five views using VTK. **Visual review
  rejected v6**: the portrait lacks the required human likeness, hair still
  resembles a helmet, and shoulders/face require professional sculpting.
- Blender is absent from the build environment. The new staging script was
  syntax checked but NOT executed in Blender; no editable .blend delivered.
- Private photographs, derived facial vertex colors, and GLB are deliberately
  excluded from GitHub. No Roblox upload, game publish, or Studio/iPhone test
  performed. All four release approvals remain false.
- Next: use the local GLB as a modest shape-blockout for an actual Blender
  sculpt, or an appropriately private high-quality 3D reconstruction tool,
  then repeat native device QA and verify publication permission.
