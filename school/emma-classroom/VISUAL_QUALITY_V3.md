# Phone recording visual rebuild — October 7, 2026

The supplied 13:47 recording of published version 54 is the before evidence. It shows working question attempts and star transitions on a physical iPhone, but poor visual presentation: dark floor and furniture, distant staff, fixed-pixel world names larger than the NPC, and block-like desks/chairs. The user rated it 2/5 and requested a substantial classroom/staff visual improvement.

## Implemented

- Native rounded silhouettes on all 18 staff torsos, sleeves, arms and trousers. Cylindrical facial/hand outlines, continuous hair cap and three swept layers, triangular suit lapels. Original staff names, roles, clothing colors and Bolich/McBreen/Boyer details remain.
- Fixed a smile mask intersecting the lower eyes; facial layers now have a geometry separation check.
- World name labels use stud dimensions and shrink with distance. The full staff name remains in the existing screen header.
- Rounded tan laminate desktops with dark edge bands, tubular metal chair legs, rubber feet, rounded seat/back/grip shapes, notebook rules/margins/spines, pencil erasers and ferrules.
- Open storage shelves and hollow colored bins, inset teacher drawers/handles, hollow supply baskets, small framed student work, denser radiator fins and staggered oak floor boards.
- Neutral daylight fill, higher indoor ambient light and warmer visible oak replace the murky green/yellow grade. Windows, blue trim/curtains, paired desks, two separated rug zones and the chalkboard/Smartboard remain guided by the actual classroom photos (IMG_2910 and IMG_2913).
- Close frontal study composition on launch. Separate portrait composition keeps the whole head above the answer panel; landscape keeps it beside the panel. Look around restores normal Roblox camera control. Starting to walk also restores that camera.

## Tested

Luau compilation, constructor/pose tests for all 18 staff (maximum 179 parts; original 180-part cap retained), floor/door fit, clear side aisle, eye/mouth separation, seven panel/camera projections, actual grading/persistence source with service doubles, 134-question bank, Rojo binary/XML build and server-only answer-key boundary.

An offline software staging view was generated from the real constructor output to check hair placement, facial clipping and camera composition. It exposed hair buried inside the head and the eye-mask overlap; both were corrected. That renderer approximates the built-in head mesh, omits SurfaceGui content, and does not simulate Roblox lighting/materials. It is not a Roblox screenshot or visual acceptance evidence.

## Acceptance still required

No new native Studio render or physical-iPhone capture of this revision has been accepted. Background-only laptop restriction was respected: this iteration used no laptop GUI, focus change or screen capture. The version-54 video is valid before evidence, not proof of this revision. Publication is for the user's next phone review under the existing upload/play authorization. Five-star visual quality and exact replica/portrait parity are not claimed.
