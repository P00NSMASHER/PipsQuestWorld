# Staff and classroom detail candidate — October 7, 2026

## Implemented in native Roblox source

`server/StaffModel.lua` replaces the former sphere-head/ball-hand staff factory.
It creates all 18 named profiles with a built-in classic rounded head mesh,
oval eyes/catchlights, eyebrows, eyelashes where appropriate, a filled smiling
mouth, shaped hair locks and contour strands, rounded glasses, C-shaped hands,
fabric clothing, collars, hems, trouser creases, belts, badges and shaped footwear.
No generated image is presented as a runtime screenshot. No asset IDs are invented.

The supplied three portraits direct these specific model details:

| Staff | Implemented details | Reference |
| --- | --- | --- |
| David Bolich | Balding gray sides, black glasses, layered beard/strands, blue checked short-sleeve polo, khaki trousers, belt/buckle, navy sneakers with white laces/toe caps | B2E1B3AE-6FEF-43FC-904D-1BF721F7CF41(2).jpeg |
| Carl McBreen | Gray swept hair, navy suit, pale blue shirt, lapels/pockets/buttons, striped blue tie, dark shoes | F1E69CB3-B0CC-48B9-9B3D-F6679AAAD0F4(2).jpeg |
| Carol Boyer | Swept blonde bob, pearl studs, black jacket, lavender shirt, gold buttons/mission pin, black trousers/shoes | 9DA59E38-E8C4-443E-9509-6B4C83BA99FF(1).jpeg |

Each sleeve, cuff, hand, trouser detail, sole and lace follows its arm/leg pose.
The prior independent limb animation left attached details behind. One staff
model contains at most 163 native parts in the current roster; the test budget
is 180. This is a construction budget, not measured phone performance.

## Classroom photo pass

- IMG_2913: 16 tan laminate desks arranged as pairs, dark aprons, book trays,
  black school chairs, books and small table supplies. Emma stays at the same
  desk/spawn position. The back-left reading zone and side staff aisle stay open.
- IMG_2910: blue window trim, radiator wall, folded blue curtains/blinds,
  separate dotted and alphabet/flower carpets, framed black chalkboard,
  Smartboard bezel/pen tray, chalk and eraser. Alphabet cards face the room.
- IMG_2919 and other storage photos: wood ledge, eight coat hooks and hanging
  bags with pockets/zippers above the colored storage bins.
- The clock dial now sits in front of its rim instead of being covered by it.

The supplied perspective photos do not establish a measured floor plan.
This remains a photo-guided reconstruction, not a certified exact replica.
Children's faces/photos are not used as decorative textures.

## Actually tested

- Actual StaffModel constructors for all 18 profiles, classic head mesh presence,
  positive finite geometry, noncolliding parts, floor/doorway fit, accessory
  counts, limb-relative transforms, idempotent walking/rest poses.
- Actual World constructor with math/service doubles: desk count, personalized
  desk, coat/storage details, separate rugs, window details, inward-facing
  question board and clear solid-furniture side aisle.
- Actual grading/server regression suite, including wrong-answer hints,
  invalid/replayed tokens, completion/restart/skip, monotonic progress and
  awaited shutdown save. Existing persistence fixes are retained.
- Luau compilation, seven device panel layouts, 134 server-only questions,
  Rojo binary/XML assembly and built-place answer-key replication boundary.

These service doubles do not execute Roblox rendering, physics or network replication.

## Not tested / remaining visual work

Studio and physical iPhone capture are still required for the exact candidate:
close-up faces, mesh silhouette, hair intersections, faceted hand contours,
beard/mouth separation, clothing seams, walking foot contact, lighting, camera
composition, mobile frame rate and the complete question loop. The desktop was
offline during this pass; no rendered acceptance result is recorded.

The attached portraits have sculpted meshes, detailed surface textures and
cinematic lighting. Native-part additions alone do not establish that level of
fidelity. Custom sculpted/textured meshes and actual in-engine refinement may
still be needed after visual review. Existing manual publication gate remains.
