# Emma classroom: focused early geometry render

The 21-camera headless rendering workflow remains the full diagnostic suite,
but often takes much longer than source validation. A parallel job in the existing event-triggered visual workflow runs
four views separately for quicker evidence of gross geometry
problems and provides a compact contact sheet with a fixed SHA and image hashes.

**Cameras** (stud coordinates):
- Back built-ins: eye (-4,5.6,6) -> aim (-22,7.7,25), full physical room.
- Blue word wall and red checked table: eye (22,5,-2) -> aim (35.5,6.5,1), full room.
- Both rugs: eye (-5,35,-4) -> aim (-25,0,-3), labelled cutaway geometry.
- Window analog clock: eye (3,5,-6.5) -> aim (-36,11.6,-6.5), full physical room; confirms clock assembly lies on the pier between two actual school windows.

This renderer **does not implement Roblox SurfaceGui**, so the red-and-white
table checkers and fine text will look plain. It also cannot test mobile
controls, physical collisions, Roblox materials, real device framerate, or
photo parity. It only supplies static camera geometry evidence and must never
be used as native iPhone visual acceptance or an authorization to publish.

No photos of identifiable school children are uploaded to the public GitHub
repository. The workflow never receives a Roblox production credential.

The standalone workflow file from the initial prototype was retired in
favor of a parallel job in the existing PR-triggered visual workflow.

Every fast-camera render undergoes the same strict nonblank pixel test;
a single identical-camera retry handles transient all-white outputs from
the independent renderer. A second rejected image still fails the job.
The four-view contact sheet is evidence of source-only geometry, not
native Roblox SurfaceGui rendering or acceptance.

## October 11 — render the exact source on development-branch pushes

GitHub's connected-app updates sometimes do not emit a
`pull_request.synchronize` event. After the rolling-cart repair, the
room's new exact-head source CI passed but the renderer still showed a
screenshot from the older desk-only repair. This let an old blue cart
occlude the alphabet rug without a new comparison render.

The existing, registered `.github/workflows/emma-showroom-visual-preview.yml`
now listens to **only the single authorized development branch's classroom
source/model and workflow changes**. On a source `push`, it runs ONLY the
same fast 4-camera source-derived screenshot job with nonblank-pixel checks
and the exact commit SHA manifest. On `pull_request` or manual dispatch,
the original 21-view screenshot suite remains available unchanged,
alongside the quick job. No scheduled task, polling service, secret,
external image upload, Roblox Studio or Roblox place publication is
introduced. `permissions: contents: read` and the original build/release
hold remain intact. The fast renderer does not emulate SurfaceGui fonts,
textures, Roblox mobile controls or native phone materials.

Owner review must still explicitly accept the current game on an actual
iPhone before final publication. A rendered artifact from any past SHA
is not evidence for the current head, and a source-only CI green check
is not evidence of rendered geometry or native appearance.
