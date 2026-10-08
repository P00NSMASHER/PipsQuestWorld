# October 7 classroom reference pass

Base: `b2e23ab2413e0bbdfadcb01a4d1d475ef180b7bb`, the published one-room classroom.

The supplied 32-second iPhone recording shows answer choices without the question, oversized speech obscuring staff, a blank-looking Smartboard, overbright walls, and distant primitive staff. The current user direction is one classroom with visiting ABVM staff and Emma's schoolwork. The earlier neighborhood/RHS direction is superseded.

## Implemented

- Full prompt and wrapped choices in a device-safe scrolling panel. Choice targets are at least 56 pixels; Skip and camera toggle are 44 pixels. Landscape keeps the left side available for the classroom and thumbstick; the panel clears the bottom touch controls. Long text scrolls instead of shrinking to unreadable type.
- Correct-answer explanations and wrong-answer hints remain visible in the panel. Generic oversized greetings no longer obscure staff.
- Normal movement and player camera, with optional Study view. This incorporates the bounded movement correction prepared in PR #311.
- Smartboard/front-wall lettering faces the classroom. Previously the Front face pointed into the wall. Side-wall posters now have correct local dimensions before rotation.
- Window openings and frame rails replace opaque backing slabs. Reduced ceiling/window lights, bloom and exposure; softened wall color.
- Built-in reading shelf with 40 book spines, original student flower artwork, and colored reading-rug dots. No pupil photographs are pasted into the room.
- All 18 labeled staff screenshots now drive names, roles, hair, glasses, clothing colors and simple clothing layers. Mr. Bolich has gray facial hair, glasses and a balding profile; Mrs. Boyer has a blonde bob and jacket; Mrs. Kochol has glasses and a floral blouse. These remain native-part stylizations, not portrait-exact faces or imported professional meshes.
- Staff scale reduced to a normal classroom size, with proportionate limb motion. The entry route follows the side aisle and front teaching space rather than cutting diagonally through desks. Consecutive rounds use different staff.
- Existing 134 questions preserved byte-for-byte as question records, moved from shared metadata into ServerScriptService. Replicated metadata contains no answer keys.
- Client state handshake starts the first round and returns an existing pending question for reconnect recovery. Active-round restart requests are rejected; successful answer tokens cannot earn another star on replay.

## Reference mapping

| Supplied files | Applied cues |
| --- | --- |
| IMG_2903 through IMG_2917 | Yellow walls, blue trim, dark floor, chalkboard/Smartboard, room density |
| IMG_2919 through IMG_2923 | Low shelves, colorful bins, rugs, tall window wall |
| IMG_2929 through IMG_2932; IMG_2937; IMG_2940 | Wood/glass doors, blue-gray corridor, ochre brick, dark tile |
| IMG_2827 through IMG_2837; IMG_2843; IMG_2861/2863/2866/2867/2869/2871 | Labeled 18-person staff appearance and roles |
| Exterior photographs and property dossier | Building context only; no new campus or claimed verified room adjacency |

## Tested

Pinned Luau 0.741 compiles all mapped sources. Rojo 7.7.1 builds both binary and XML places. Tests exercise the actual server source with service doubles: client readiness, pending-question recovery, invalid tokens/indexes, wrong-answer hint without penalty, successful grading, duplicate-answer rejection, ten-question completion, saved counters, restart, and skip. Pure layout tests cover seven phone/tablet sizes. XML inspection checks that the built place replicates no answer bank.

These are compilation, behavior-double, layout-math and assembled-place tests. They are not Roblox physics, rendered UI, live DataStore, or physical-iPhone tests.

## Release status

Saved as a reviewable candidate. No publish marker changed. Roblox Studio device PAAM-L044 was offline during this pass, so an actual capture of this candidate remains required. Do not describe this candidate as live, visually accepted, polished or finished. The supplied recording is evidence of the base build, not evidence that these repairs render correctly.
