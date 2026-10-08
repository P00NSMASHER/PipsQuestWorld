# Emma classroom: rounded school chair profile

Implementation source commit: `fba640e9fb1fcb7aa41f53c25b810962b3ccb736`

Independent visual build: [GitHub Actions run 37804430404](https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/37804430404) — SUCCESS.
Roblox classroom Rojo assembly: PASS. All six source-head GitHub workflows passed.
Geometry exporter: 2,768 room parts; still under the 3,100 part limit.

**These JPEGs are real output of the source-derived independent renderer, NOT native Roblox Studio/gameplay screenshots.** Engine lighting, mobile touch play, true collision and iPhone performance remain unverified.

## Same eye-height camera: oval chair versus rounded rectangular chair

| Rejected oval-stool silhouette | New rounded rectangular school-chair silhouette |
| --- | --- |
| ![Before: oval-backed elementary chair](before-oval-chair.jpg) | ![After: rounded rectangular back of classroom chair](after-rounded-school-chair.jpg) |

![After: child desk side close-up](after-desk-side.jpg)

## What changed

- Preserved the separate invisible back collider and all student desk/chair positions.
- Replaced the full ellipsoid-shaped visible chair back with a rounded rectangular manufactured school-style contour.
- Constructed the back with one continuous rounded center and corner returns, not the previously rejected horizontal stack of separate plates.
- Kept the thin laminate desk rims and steel supports from the prior accepted furniture revision.
- Added source geometry assertions: exactly 16 primary backs and centers, 64 rounded corners, 16 invisible collision shells, 32 chair underseat steel runners.
- Preserved room budget, original schoolwork source and no-quiz showroom build.

## Visual verdict

The independent render shows the current backrest is less oval and reads closer to elementary school furniture. It is a limited **incremental visual acceptance**, not a claim of a professional fabricated seat, exact ABVM classroom dimensions, or final quality. Steel tubing and desk bases remain primitive part geometry; proper original mesh furniture would offer a stronger final improvement once native asset import/render acceptance is available.

## Renderer reliability

A previous source-identical doc-only run failed with an all-white isometric PNG. The workflow now retains its original blank-image rejection threshold (minimum channel span 65, maximum near-white ratio 0.94) and tries one alternate camera when an aerial image fails. A self-test proves flat white images are rejected. Run 37804430404 passed both self-test and actual image-gating and emitted the screenshots above. It does not prove the retry pathway fired in this particular successful run.

No production publishing, no PR merge, no edits to educator source files or unrelated automations.
