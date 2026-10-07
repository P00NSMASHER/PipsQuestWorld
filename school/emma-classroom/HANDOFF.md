# Emma Study Classroom handoff

## Implemented

- Restored normal Roblox movement, jump, autorotation and touch camera control.
- Added a 44px `Study view` / `Look around` toggle. Study view retains the intentional teacher/Smartboard/doorway composition; Look around restores the character camera.
- Strengthened classroom CI so a future permanent movement lock fails the tiny-game contract.

## Actually tested

- Luau compilation for every classroom client/server/shared source.
- Isolated Rojo place build.
- Classroom CI contract checks, including both camera modes and absence of movement-lock assignments.

## Not tested

- Roblox Studio runtime launch.
- Physical iPhone thumbstick, jump, camera orbit and safe-area interaction.
- Final composed Study view against the authorized classroom reference.

## Known release hold

This candidate is not runtime-complete or publishable until an actual Roblox/iPhone capture proves movement, camera restoration, Study view composition, question interaction and the 10-question loop on the exact candidate head.
