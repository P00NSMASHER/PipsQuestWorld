# ABVM hallway continuation — dimensional mustard end window

## Executed implementation prompt

Act as the lead Roblox architectural-reconstruction artist, Luau/Rojo engineer,
mobile-performance specialist and adversarial visual QA reviewer for Emma's
**classroom-only** place. Improve the most recognizable remaining flat hallway
landmark: the distant mustard-yellow timber-and-glass sash with a small
geometric sunrise/sunburst. Use the owner's six October 10 hallway photographs
for architectural cues, without storing or copying the people or student
assignments depicted in those photos.

Work on the current stacked **draft hallway PR #343** in
`P00NSMASHER/PipsQuestWorld`; do not alter the independent classroom-study
archive, ABVM schoolwork importer, scheduled tasks, the parent's release gates,
or the live published Roblox place.

1. Replace the flat SurfaceGui-only end-window motif with a recognizable
   shallow 3D architectural assembly: dark real `Glass` pane, four mustard
   timber sash rails, three narrower dividers, circular original sunrise
   center and eight radial sunburst rays.
2. Mount the decoration on the **hall-facing** side of the original
   **sealed and collidable** left endcap. Do not carve any new physical passage
   or claim an unseen building junction from oblique photos.
3. Make each of the 17 new Pieces anchored, noncolliding and nonquerying,
   without external marketplace assets, people, imported student work or
   identifying school photo textures.
4. Assert actual Luau construction in both `audit_hallway_photo.py` and
   `export_source_scene.py`. In adversarial tests, a collidable pane or a
   missing sun ray must be rejected. Continue to enforce the 3,100 physical-
   Part budget and all eight classroom and corridor navigation checks.
5. Extend the fast screenshot workflow with an unmoved, repeatable child-eye
   end-window camera aimed down the long hall. Test nonblank output, retain
   actual pixels in the CI artifact, and do not mistake independent rendering
   for Roblox's real materials, transparency, glass response or device FPS.
6. Keep parent PR #339 and hallway PR #343 **draft** until native iPhone
   hall-walk inspection, visual comparison and collision/FPS review are done.

## Source changes made

- `school/emma-classroom/showroom/Room.lua`: 17 actual shallow native
  3D Parts added on x=-53.38..-53.02, centered near y=7.35, z=38,
  in front of the intact end cap; old flat mustard window graphic removed.
- `school/emma-classroom/showroom/audit_hallway_photo.py`:
  source-constructed detailed geometric/physics validation, negative mutations.
- `school/emma-classroom/showroom/export_source_scene.py`:
  source-derived 3D snapshot asserts exactly 17 identifiable components,
  physical pane location, and original sealed endcap boundary.
- `.github/workflows/emma-showroom-visual-preview.yml`: stable seventh
  camera `07-hall-yellow-end-window` plus contact-sheet inventory.

## Acceptance boundaries

The corridor direction, length and end-window dimensions are provisional
artistic interpretations, **not surveyed measurements**. No identifying
photographs of children are added to the public repository. Successful Luau
and headless source-render checks are useful geometric evidence, **not**
native Roblox/iPhone screenshot, collision or measured device-performance
acceptance. Do not mark the live place published.
