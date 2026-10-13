# ABVM hallway — photo-grounded 3D adjacent school doors

## Executed implementation prompt

Act as an expert Roblox environment artist, Luau/Rojo developer, and
adversarial visual QA reviewer for Emma's classroom-only school replica.

**Mission:** Fix the two adjacent school door facades in the long October 10
hallway. Source-derived child-eye images exposed their painted wood/glass
details as dark, featureless rectangles: the scene had one entirely solid
wood Part per door plus SurfaceGui-only simulated glazing, trim and hardware.
Recreate believable dimensional varnished-oak doors, framed upper frosted
glazing, center rails, lower molded panels and visible brass hardware.
Use original non-identifying geometry: do not upload photographs of students,
their assignments, their names, or event-day participants.

**Non-negotiable:** Both neighboring doors remain **closed, fake facades**,
backed by the original collidable front corridor wall. There are no made-up
rooms, interactable doors, NPCs, question widgets, or new player passages.
Leave Emma's genuine central double classroom door and independent side
staff entrance untouched. Keep the exact full-room build below 3,100 Parts
and preserve all eight static avatar routes, plus the original curriculum
archive and 15 scheduled tasks. This PR stays draft, with no live publication.

Work in `P00NSMASHER/PipsQuestWorld`, stacked draft [hallway PR #343]
(https://github.com/P00NSMASHER/PipsQuestWorld/pull/343),
`school/emma-showroom.project.json`, constructor
`school/emma-classroom/showroom/Room.lua`.

## Implemented changes

- `Room.lua`: retained 2 original adjacent oak door Parts as lower solid
  panels, with real vertical upper glazing apertures. Added per door a
  noncolliding frosted Glass pane, 2 oak stiles, lintel, sill, crossbar,
  raised timber panel, brass plate and brass pull. **+18 physical Parts
  across two closed facades.**
- `audit_hallway_photo.py`: constructed-Luau source test verifies actual
  upper apertures, 2 panes, 4 stiles, 6 wood rails, 2 raised panels, 4
  metal components, original sealed structural walls and no collisions.
  Negative mutations reject an opaque ten-stud backing slab, opacity,
  missing stile or collidable hardware.
- `walkability_audit.py`: blocks any future promotion of these 9 kinds
  of decorative facade Pieces into avatar colliders.
- `export_source_scene.py`: asserts actual source-built geometry and
  glass, rather than accepting SurfaceGui-only paintings.
- `.github/workflows/emma-showroom-visual-preview.yml`: captures fixed,
  uncut, real-source child-eye camera
  `08-hall-adjacent-oak-door` from (-41.8,5.6,39) toward
  (-45.5,6.8,27.85), and preserves the PNG in its contact-sheet artifact.
- `audit_rendered_hallway_oak_doors.py`: separately checks **actual
  pixels** from the fixed 1920x1080 render for all oak frame edges,
  both frost panes, physical crossbar, contrast-enhanced lower wood
  panel, and brass. Synthetic negative tests remove each visual
  component, fake a solid slab or shift the camera. Uses no original
  school photo data.

## Verification record and boundaries

At head `03fdc882bac32149f60bed4f227b720a09defb91`,
[Emma Classroom Replica CI](https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/38113637766)
passed: **3,086 physical Parts of 3,100**, **eight of eight static routes
connected**, unchanged sealed walls and no study-game assets.
The [fast source-derived visual job]
(https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/38113637740)
passed all eight fixed screenshot outputs; the specific newly generated
door screenshot was visually inspected: dark stained oak surround,
visible horizontal mullion, two pale blue-gray glazed sections, light
raised timber lower panel and brass grip all render as 3D silhouettes.

The standalone pixel-gate script was tested locally against the actual
`08-hall-adjacent-oak-door.png` artifact and against blank, shifted,
missing-panel, missing-glazing, absent-crossbar and missing-handle
synthetic mutations. Its workflow integration is committed separately.

**Do not treat any static-render pass as native Roblox acceptance.**
Glass appearance, UI brick grout, collisions in the actual engine,
frame rate and photographic proportions need native iPhone testing.
Draft PR #343 remains unmerged/unpublished, nested under draft PR #339.
