# ABVM Grade 2 — teacher portrait staging handoff (2026-10-14)

## Implemented
- Isolated optional static portrait-Model adapter and disabled-by-default config.
- Showroom Rojo mapping and one teacher-only call site, without adding gameplay.
- Fail-closed loaded-model allowlist, scale limits, anchored/noncolliding parts,
  inherited orientation/floor alignment, and original R15 teacher fallback.
- Verify-build expectations updated to include new modules and the disabled gate.
- Prototype GLB was created from the user-supplied three-view portrait OUTSIDE
  GitHub; its photographic texture is not committed to this public repository.
- All changes are on branch `feat/abvm-grade2-portrait-npc-staging-20261014`,
  based on the verified classroom release branch, not merged.

## Actually tested
- The offline prototype GLB round-tripped with finite geometry, 24,342
  triangles, 45 mesh nodes, 1.92 × 5.86 × 1.406 studs, and <20 MB payload.
- Actual GLB rendered with VTK in front, three-quarter, and rear views.

## Not tested
- Roblox upload/moderation, native Studio rendering, Roblox-sourced MeshPart
  material fidelity, floor alignment on-device, mobile FPS, CI on current head,
  or game publication.

## Known blockers
- Need a verified creator-owned Roblox asset ID for the PRIVATE textured model
  and permission for publishing this recognizable teacher likeness.
- Keep portrait configuration disabled until native visual/iPhone QA passes.

No gameplay, questions, other Roblox experiences, scheduled tasks, or live
release versions changed. Full acceptance plan is in
`school/emma-classroom/TEACHER_PORTRAIT_STAGING_20261014.md`.
