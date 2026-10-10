# Emma classroom: focused early geometry render

The 21-camera headless rendering workflow remains the full diagnostic suite,
but often takes much longer than source validation. This event-triggered
three-view comparison runs separately for quicker evidence of gross geometry
problems and provides a compact contact sheet with a fixed SHA and image hashes.

**Cameras** (stud coordinates):
- Back built-ins: eye (-4,5.6,6) -> aim (-22,7.7,25), full physical room.
- Blue word wall and red checked table: eye (22,5,-2) -> aim (35.5,6.5,1), full room.
- Both rugs: eye (-5,35,-4) -> aim (-25,0,-3), labelled cutaway geometry.

This renderer **does not implement Roblox SurfaceGui**, so the red-and-white
table checkers and fine text will look plain. It also cannot test mobile
controls, physical collisions, Roblox materials, real device framerate, or
photo parity. It only supplies static camera geometry evidence and must never
be used as native iPhone visual acceptance or an authorization to publish.

No photos of identifiable school children are uploaded to the public GitHub
repository. The workflow never receives a Roblox production credential.
