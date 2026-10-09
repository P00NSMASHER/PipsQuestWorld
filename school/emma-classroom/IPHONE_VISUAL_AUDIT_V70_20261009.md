# Native iPhone visual regression — version 70, October 9, 12:10 PM

## Unredacted recording held in user conversation only
User-provided video `ScreenRecording_10-09-2026 12-10-56_1.mp4` (44.27s,
1112x512, 30fps). Locally inspected 0–44 seconds, especially 9.5–14.5.
Do not upload the user recording, screen captures, personal account state,
teacher/student photographs or identifiable participant information to GitHub.

## Two confirmed defects on a real iPhone
1. At 10–13 seconds the circular blue alphabet rug shows the solid golden
   sun center, yet no visible orange rays and none of the ten numbered
   off-white clouds. The original very thin Ball parts (.025–.038 stud thick)
   passed static geometry tests but were unreliable on the iPhone.
2. At 10–12 seconds the five face-out storybooks on the child-sized display
   show blank cream page backs with thin colored edges instead of illustrated
   covers. The previously authored covers and physical illustrations were
   directed away from the positive-Z player approach.

## Development changes
- Preserve the original sixteen orange/gold sun rays and the ten sets of
  three-lobed clouds, but give the already-existing parts shallow .12–.14
  stud relief above the carpet rather than paper-thin ellipsoids. Disable
  decorative shadow casting. Lift the ten original transparent number
  SurfaceGuis enough to clear the cloud tops. **No added physical parts.**
- Face all five original illustrated book covers, captions and physical
  illustrated relief toward the actual positive-Z player side of the story
  shelf; leave book centers, physical cream pages, book counts and bookcase.
- Add actual constructed-Luau geometry/depth assertions and a standalone
  runtime SurfaceGui-facing audit, including a regression that deliberately
  reverses a book GUI and must fail. Require that audit in both showroom CI
  and the protected preview publishing workflow.
- Retain 26 carpet letters, first-person camera, 16 desks, school photo cues,
  curriculum isolation, student progress and disabled premium meshes.

## Acceptance limits
This is a native-iPhone-driven defect repair, but tests and source-derived
screenshots cannot guarantee the replacement is visible in Roblox. Obtain
a NEW real-device recording of the same 10–14 second rug and book approach
on the subsequently published review preview, before claiming native
visual acceptance or approving production desk/chair mesh assets.
