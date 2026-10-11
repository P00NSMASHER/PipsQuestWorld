# Hallway continuation — reject visually invisible end-window geometry

## Executed engineering prompt

Act as a senior Roblox visual QA engineer, architectural replica artist,
Luau/Rojo guardian and mobile optimization reviewer. Keep the work inside the
stacked **draft PR #343** for the isolated classroom-only Roblox place.
Inspect the **actual rendered** player-height corridor evidence, not just
source greps or a renderer's zero exit code. The prior end-window test checked
only that an image was nonblank, which would pass an otherwise solid blue
wall with no yellow window.

Add a dedicated semantic pixel checker to the existing full-scene,
source-derived fixed hallway camera `07-hall-yellow-end-window`. Validate:
a continuous ochre/yellow timber top, bottom and side frame; two separated
vertical window dividers; a horizontal crossbar; both dark glazed top panes;
a brighter circular sun center; and all eight distinct radial sun sectors.
Fail if any required element is invisible or occluded.

Use the known 1920x1080 rendered camera; verify exact resolution to reject
changed FOV/crops rather than silently weakening the thresholds.
Include adversarial image mutations, not just a passing sample: blank
wall, brown impostor, filled solid panel, shifted camera, deleted sun, and
each of the eight individual missing rays. Keep the original screenshot
artifact for human review. Maintain the whole classroom, sealed endcap,
student-work sheets, existing navigation, CI safeguards, no-student-photo
rule, and 3,100-physical-Part budget. No live publish or PR merge until
native iPhone capture, collision inspection and measured device FPS.

## Actual starting evidence (source-rendered, not native Roblox)

From earlier completed visual workflow run
https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/38099222204,
the same-source screenshot
`07-hall-yellow-end-window.png` in artifact
`emma-fast-photo-633bbccb19e2160ca548622c0435b17be50f7838`
**visually shows**:
- An ochre window outline and two vertical mullions at the far closed end.
- Dark blue/gray glazed panes with a smaller yellow eight-ray sunburst.
- The physically suspended row of anonymous white diagonal papers on
  the left wall; flat warm-ochre glazed-brick fallback below.
- A still-stylized corridor whose photo fidelity is not validated by
  this renderer; SurfaceGui grout, rich materials and real iPhone lighting
  are not visible in this tool.

Pixel-grounded baseline (exact fixed camera and screenshot, not any source
photo): top sash 1140 pixels, bottom 1255; side frames 596/593;
vertical dividers 235/239; horizontal crossbar 458; two upper dark panes
1188/1122; brighter sun center 140; radial sector counts
[66,28,12,27,71,20,8,20]. The checker tolerates moderate exposure shifts
but fails if a required architectural feature vanishes.

## Implemented files

- `showroom/audit_rendered_hallway_end_window.py` — deterministic
  Pillow-based semantic screenshot validation and explicit positive/negative
  tests; does not need any original school photos.
- `.github/workflows/emma-showroom-visual-preview.yml` — runs the
  self-tests and semantic image gate after the source-derived renderer
  generates the exact fixed camera, before writing the evidence manifest.

## Scope and remaining gate

These pixel tests prove only **visibility in a third-party renderer
applied to real constructed Luau parts**. They cannot certify native Roblox
Glass shading, SurfaceGui brick bonding, true dynamic collisions, actual
hardware FPS, exact building dimensions or the photographic likeness
of the original hallway. Those require an actual Roblox iPhone playtest.

**Do not publish or merge** this draft PR on pixel success alone.
