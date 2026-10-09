# Native iPhone visual QA — October 9, 2026, version 68

## Source and restrictions
User-supplied 59-second iPhone Roblox gameplay recording (`ScreenRecording_10-09-2026 09-12-36_1.mp4`), visually inspected locally. This document is a text-only defect receipt. Do not commit or publish the video, screen recordings, account notifications, personal information, or real classroom child photographs.

## What the actual phone showed
- Approximately 25–27 seconds: a wheeled interactive whiteboard stands ahead of the chalkboard, rather than duplicating a wall-hung screen.
- Approximately 32–38 seconds: the windows show exterior greenery and radiator panels; some classroom lettering is legible, but floor signage needs improvement.
- Approximately 49–52 seconds: the circular carpet reads substantially darker than the real photograph. The center sun looks dark brown, the cloud marks look like gray circles overlaid with opaque white rectangular stickers, and A–Z letters are tiny inside otherwise large pastel border panels.
- Approximately 56–59 seconds: Emma's desk remains personalized and visible. No change to its place or data is requested.

## Applied development corrections
- Preserve 26 original alphabet tile physical instances but give their already-present SurfaceGui labels an explicit small canvas (180 by 120 pixels), fixed large 92px text and minimal padding.
- Preserve the existing 20 cloud lobes and ten numeral anchors. Keep the dark numeral GUI visible while making each white rectangular backing part fully transparent. This is not a new gameplay UI.
- Lighten the carpet's blue material color and sun's warm orange/gold colors; use low-reflectance native SmoothPlastic for the 17 sunlight shapes so the sunshine reads in the shadowed room rather than as dark fabric.
- No added physical Parts, furniture changes, curriculum/gameplay changes, publication authorization, or original photo/video assets.

## Acceptance boundary
Require exact-head Luau compilation, Rojo build, source geometry and static navigation checks. The independent source renderer does not render native SurfaceGui text reliably; source geometry/CI passing therefore does **not** prove iPhone label readability or color fidelity. Native iPhone re-recording at the identical 49–52 second carpet viewpoint is the necessary acceptance evidence. Do not merge PR #339 or activate the verified but production-disabled original furniture meshes on the basis of these checks.
