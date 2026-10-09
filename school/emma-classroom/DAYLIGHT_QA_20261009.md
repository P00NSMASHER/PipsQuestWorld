# Emma classroom daylight — development-only lighting QA, October 9, 2026

## Evidence and problem
The supplied eight school photographs show bright fluorescent/daylight
interiors, warm pale-yellow walls and dark, moderately polished wood flooring.
Exact-source render snapshots (including visual run 37948129536) show a dimmer,
cool gray classroom. Previously `Room.applyLighting` authored lighting values
and `GalleryPass.decorate` *then overwrote* exposure, color correction and
environment bounce. This made lighting governance unclear and created an
avoidable second authority.

## Implemented controlled adjustments
- One authoritative soft daytime lighting profile in `Room.applyLighting`;
  no post-hoc lighting override in GalleryPass.
- Modest increase in ambient fill and lamp brightness, neutral-warm daylight
  and a small positive exposure correction; preserve six existing recessed
  frosted fluorescent fixtures, daylight sun anchor and shadows.
- Retain subtle bloom / sun-rays limits and four existing named effects.
- Slightly refine dark classroom floor varnish response without changing its
  physical height, WoodPlanks material or collision.
- Add `audit_lighting.py`, executed in exact-head classroom CI, using actual
  constructed Luau lighting and six diffuser SurfaceLights. Reject darker
  overrides and duplicate postprocessing. No new physical parts, new
  spotlights, textures, camera code, animations, educational systems or child
  images.

## Acceptance boundary
CI values and independent source-rendered screenshots cannot establish how
Roblox's native shaders look on iPhone. In particular the third-party renderer
does not reproduce Lighting, postprocessing and GUI exactly. Treat color,
brightness and floor sheen as an **unpublished visual review candidate** until
an updated native iPhone walkthrough is reviewed. Do not merge PR #339 or
activate unaccepted premium desk/chair meshes based on these tests.
