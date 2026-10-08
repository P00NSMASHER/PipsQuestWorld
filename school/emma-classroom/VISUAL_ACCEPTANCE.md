# Emma Study Classroom — Visual Acceptance Gate

This file exists because source-code success is not visual success. A build may compile perfectly and still look ridiculous. Been there.

## Authoritative visual target

The user-approved “Emma’s Study Classroom” concept image is the composition and polish target.

The game is accepted only when an actual iPhone Roblox capture shows the following at normal play scale:

- at least 75% of the screen remains visible 3D classroom during questions
- Emma’s seated position reads in the foreground without blocking the teacher or Smartboard
- teacher is fully visible at the front of the room
- Smartboard is readable and carries the current prompt plus A/B/C/D choices
- classroom door is visible on the right side and staff visibly enter through it
- left window/radiator wall, teacher desk, chalkboard, cubbies, classroom rugs and ABVM wall details all read as one coherent room
- answer UI is confined to a compact bottom strip and never covers the teacher’s torso/head or the Smartboard
- no large modal, focus card, shop UI, neighborhood HUD, vehicle controls, or unrelated navigation exists
- teacher speech bubble does not overlap the answer bar or Smartboard
- staff proportions, hair, face, clothing, hands and shoes read as intentionally modeled Roblox characters rather than primitive placeholders
- wrong-answer feedback is visible without punishing Emma or obscuring the scene
- 10-question completion flow works on iPhone

## Evidence rule

CI and Rojo build success prove only that the source compiles and assembles.

They do **not** prove:
- visual quality
- camera composition
- mobile readability
- likeness quality
- animation quality
- reference parity

Publishing is therefore manual-only. A new live version should be released only after an actual Roblox/iPhone capture is reviewed against this checklist.

## Current state

The live game may be ahead of the last visually reviewed capture. Treat every live build as a candidate, not as “polished” or “finished,” until screenshot/video evidence passes this gate.

## October 7 candidate review additions

The reference recording exposes that the prior compact-strip goal omitted the readable prompt. For this candidate, inspect the right-side landscape panel and lower portrait panel at actual device scale. The complete prompt, hints and all options must be accessible at readable type, with no overlap on native movement/jump controls. Check the teacher remains visible to the left in Study view. The earlier 75% scenery target is not an acceptance substitute for question readability. No rendered pass is recorded for the new candidate.

Verify the smaller staff scale and side-aisle route; front-facing Smartboard text; lit window openings; and all 18 labeled profiles. Publishing remains subject to the existing actual-capture gate.

## Staff/detail continuation checks

Inspect all 18 staff with close-ups before treating the new native geometry as
accepted. Prioritize Bolich's beard/mouth/glasses, McBreen's hair/tie/lapels and
Boyer's swept bob/pearls/gold details. Confirm the classic head mesh renders as
intended, accessories remain attached through turns, soles meet the floor, and
C-hand contours read cleanly. Source geometry tests are not likeness scores.
Check the 16 paired desks, clear back-left reading area, separated rugs, inward
alphabet cards, blinds/curtain folds and coat storage against the real photos.

## Shared curriculum candidate

Before publishing this candidate, capture actual Roblox play and a physical iPhone
showing Mix/test selection, unavailable test handling, a three-choice and a
four-choice question in portrait and short landscape, all choices readable, wrong
hint/retry, correct grading, ten-question completion/restart, movement and Look
around restoration. Verify leave/rejoin and two-player progress isolation against
the live DataStore. Record exact source SHA and binary hash with the evidence.
Headless source/service-double checks are not runtime or device acceptance.
