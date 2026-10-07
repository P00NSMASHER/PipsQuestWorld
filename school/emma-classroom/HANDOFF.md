## Current visual revision

Version 54 was reviewed on a physical iPhone and rated 2/5 by the user. The next visual revision is documented in `VISUAL_QUALITY_V3.md`: rounded staff/furniture, daylight, actual storage detail and close study camera. Source/projection checks pass; a new native/device render must still be reviewed. Previous evidence below remains historical.

# Emma Study Classroom handoff

## Implemented

- Made lifetime progress persistence monotonic across out-of-order DataStore
  completions. Older asynchronous saves can no longer reduce total correct,
  completed sessions, or per-skill correct counts.
- Player-removal and server-shutdown paths now await their final DataStore write
  instead of starting a task and relying on a fixed two-second delay.
- Restored normal Roblox movement, jump, autorotation and touch camera control.
- Added a 44px `Study view` / `Look around` toggle. Study view retains the intentional teacher/Smartboard/doorway composition; Look around restores the character camera.
- Strengthened classroom CI so a future permanent movement lock fails the tiny-game contract.

## Actually tested

- Executed the actual server source against a forced stale-save regression and
  verified that newer lifetime/session/skill totals survive.
- Executed the shutdown callback and verified its final write is visible before
  the callback returns.
- Luau compilation for every classroom client/server/shared source.
- Isolated Rojo place build.
- Classroom CI contract checks, including both camera modes and absence of movement-lock assignments.

## Not tested

- Roblox Studio runtime launch.
- Live Roblox DataStore behavior under throttling, shutdown, and reconnect.
- Physical iPhone thumbstick, jump, camera orbit and safe-area interaction.
- Final composed Study view against the authorized classroom reference.

## Known release hold

This candidate is not runtime-complete or publishable until an actual Roblox/iPhone capture proves movement, camera restoration, Study view composition, question interaction and the 10-question loop on the exact candidate head.

## Staff/detail continuation

The next candidate includes `STAFF_DETAIL_PASS.md`: a new native staff factory
for all 18 profiles, detailed Bolich/McBreen/Boyer outfits/accessories, grouped
limb-detail poses, paired desks and photo-guided window/rug/coat-storage details.
`tests/geometry_behavior.py` executes both actual constructors with service/math
doubles. The previous stale-save and awaited-shutdown fixes remain intact.
This candidate has no Studio or physical-iPhone visual pass and does not claim
portrait-level rendering or a measured exact classroom replica.

## Authorized native Studio check and visible fixes

At 1:00–1:11 PM Eastern the user authorized foreground laptop use. Native Studio
constructed all 18 staff and the room successfully, then rendered the three
portrait-target staff. The render failed the final visual target: noisy Fabric,
stretched SurfaceGui lettering and rounded hair bumps. Follow-up source fixes
address those concrete defects; they are not a rendered visual pass. Physical
iPhone, real Play-mode question loop and final likeness still need inspection.
At 1:11 PM the user requested background-only operation; Studio was minimized
and remaining source/check work continued without bringing it forward.
