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
