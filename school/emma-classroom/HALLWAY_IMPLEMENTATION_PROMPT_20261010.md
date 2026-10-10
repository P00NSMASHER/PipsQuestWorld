# Implementation prompt — Emma's ABVM hallway, October 10, 2026

You are the lead Roblox environment artist, school-architecture reconstruction specialist, Luau/Rojo engineer, and independent visual QA reviewer working in 'P00NSMASHER/PipsQuestWorld'.

## Mission
Use the owner's six newly provided photographs of the hallway immediately outside Emma's Assumption BVM classroom to replace the current simplified exterior corridor with the highest-fidelity **navigable, recognizable** hallway possible on an iPhone. This is a real Roblox source-code change, not a 2D image mockup. Write and execute the implementation, inspection, and regression tests. Preserve the existing user-approved classroom-only replica direction.

## Canonical context
- Existing work belongs to **draft PR #339**, branch 'visual/emma-classroom-replica-only-20261008', not the old classroom study-game build.
- Authoritatively build 'school/emma-showroom.project.json'. Main source: 'school/emma-classroom/showroom/Room.lua'; existing entry: 'buildBackDoorAndHall()'.
- User's original photographs contain children; the GitHub repo is **public**. Document architecture and recreate anonymous original props, but do not upload identifying student/event photos, names, assignments, or portraits.
- Photos depict a temporary activity; do not freeze the crowd, money bag or donated food into the everyday architectural scene.

## Reconstruct the actual visual signatures
1. Dark polished square stone floor with tight offset-free grout, restrained reflections and correct level transition at the classroom threshold.
2. Glazed warm golden/ochre glazed-brick courses over the lower third of blue-gray plaster walls. Model horizontal bond, alternate vertical joints, subtle shifts in tile color, dark mortar and narrow wood separation rails. Prefer low-cost SurfaceGui patterns to hundreds of colliders.
3. Detailed aged wood double classroom door: thick stiles, horizontal center rail, glazed upper lights, frosted glass, handles, brass threshold and small green shamrock decoration. Avoid blocking the real in-game entrance or duplicating it.
4. Ceiling painted ivory/light acoustic white, flat and enclosed, with elongated recessed fluorescent diffusers. No outdoors sky leaks, low roof, dark metallic planks or neon billboards.
5. Long hallway perspective with classroom doors along the perimeter, generous child-safe walking width, legible player-height views in **both directions** from Emma's room.
6. A long strip of hanging diamond-rotated white schoolwork sheets, original anonymous guidelines rather than reproductions of real assignments.
7. Thin black WELCOME sign, subtle warm school posters and yellow-framed distant glazing with an abstract sunburst, preserving the photos' distinctive silhouette.
8. Preserve real classroom furniture, window wall, teacher front wall, native mobile controls and independent staff entrance.

## Evidence, uncertainty and safety
Create a nonidentifying, persistent photographic-fidelity map, with confirmed vs inferred observations and provisional Roblox world-axis orientation. **Do not claim measured/photogrammetric precision** from crowded oblique pictures. If photographs don't establish a corridor junction, never assert one: build a navigable approximation that preserves the true classroom opening, and ask for empty-hall panoramas later to calibrate.

Keep anonymous decorations noncolliding; floor, outer walls and other blocking structural geometry should have simple, predictable collision. Optimize for mobile: ≤3,100 physical Parts for the entire classroom and hallway, with low transparency overdraw and bounded SurfaceGui draw cost.

## Execution and acceptance
- Implement on a review branch derived from the latest PR #339, as a **draft stacked pull request**, not an overlapping rewrite of the curriculum game or production place.
- Retire old rear-pocket parts and update tests that assert those *obsolete* geometry names; retain independent staff-vestibule tests.
- Build the exact shipped Rojo target. Run all existing Luau constructors and 'export_source_scene.py' scene/part-budget validation, 'walkability_audit.py' and new photo-hallway runtime audit. Prevent an accidentally blocked or narrowed doorway.
- Run real-source visual previews including fixed child-eye cameras to the left and right of the doorway. Inspect image pixels; if a view is blank, clipped or blocked by the roof/door, reject it and fix the source. Third-party headless renders do **not** prove native SurfaceGui texture appearance.
- Verify real Roblox/iPhone captures for walkability, floor/brickwork, translucent glazed doors, fluoro lights, device performance and subjective visual match. Keep the PR draft and do not claim live publication or final acceptance until device review; preserve all prior tasks and release gates.
- Report the exact branch/PR, evidence links, checks actually run and any remaining limitations.

## Status of this execution
Implemented on branch 'visual/emma-hallway-photo-faithful-20261010'. Source and tests have been changed. Actual native device inspection is a release requirement, not automatically asserted by this prompt.