# Emma's ABVM hallway — photographic reconstruction reference (2026-10-10)

## Source and privacy
Six owner-provided photos in this ChatGPT conversation show the **school corridor outside Emma's classroom**. The photos include identifiable schoolchildren and adults. **Do not commit, publish, embed, use as textures, or turn people into NPCs from the original photographs in this public repository.** The original owner retains the originals in the conversation; this file preserves only architectural observations. Student assignments, names, event participants, and fundraising labels are omitted.

## Confirmed photographic landmarks
| Landmark | Photo-grounded visual treatment | Confidence |
| --- | --- | --- |
| Corridor floor | Dark charcoal/slate square stone tiles, thin regular dark grout, worn/reflected daylight and fluorescent highlights | High |
| Wall lower third | Glazed amber/ochre rectangular brick courses with dark mortar, alternating brick bond and varied golden/earthy shades | High |
| Wall upper | Blue-gray/slate painted plaster; continuous wall with slim natural-wood hanging rail at upper level | High |
| Doors | Older medium-dark varnished wood frames, glazed/frosted window inserts, horizontal rails, rectangular panel work, brass/dark metal handles | High |
| Emma's classroom entrance | Classroom visible through open door, warm pale-yellow walls and dark chalkboard; green shamrock decoration on glazed wood leaf | High |
| Schoolwork display | Long line of evenly spaced portrait papers hung on the diagonal, suspended along a narrow wooden strip | High |
| Doorway decoration | Tall narrow black **WELCOME** strip and bright yellow room-side posters near the door | High |
| Ceiling/lighting | Pale flat/acoustic ceiling with elongated recessed white fluorescent diffusers, not a dark wood-plank roof or skylight | High |
| Distant end | Mustard/yellow timber-and-glass sash/paned transom with dark glazing and stylized yellow sunburst in upper glazing | Medium (angle/partially obscured) |
| Cross-corridor | A brick-lined side passage is visible in one photo; its precise junction to this classroom corridor is not established | Medium |
| Temporary objects | Children, teachers, food collection bags/boxes, handheld money sack, event clothes and decorations are temporary | Exclude |

## Approximate photo-specific color swatches (illustrative, not spectrophotometric)
- Painted upper wall: slate blue gray around RGB **107 / 117 / 125**.
- Brick/ceramic faces: warm ochre/gold/orange around RGB **174–211 / 111–148 / 48–72**, dark brown mortar.
- Stone floor: aged dark charcoal around RGB **75 / 73 / 70**.
- Door stain: medium-dark oak/walnut around RGB **112 / 77 / 50**.
- Ceiling panels: cream-white RGB **237 / 236 / 226**.
- Small accents: green shamrock, yellow-painted distant glazing, paper-white hallway assignments.

Lighting and camera white balance vary across six photographs; these are intentional *design approximations*, not claims of calibrated photographic sampling.

## Existing Roblox world axes vs unknown actual measurements
- Canonical place: 'school/emma-showroom.project.json'; room shell and real doorway remain in 'showroom/Room.lua'.
- The real classroom rear entrance is centered near **(x=0,z=27)** in the existing source. Preserve open passage at x roughly -5.5..+5.5.
- The prior game had a **23-stud dead-end placeholder** occupying x -9..9 and z roughly 26.5..49.5. It did not faithfully represent these photos.
- New room-adjacent corridor is *provisionally* oriented along **X** so users exit Emma's doorway and can turn left or right; its estimated gameplay envelope is x -54..54, z 26.75..49.25, height ~13 studs. **Neither this axis nor these dimensions are surveyed real-world geometry.**
- The photographs show the passage extending past Emma's door with classroom doors distributed along the walls. Additional closed wooden doors outside the established classroom shell are purely architectural facades, not interactive rooms.
- The separate staff-door vestibule already in the game is preserved independently. **Do not invent a physical junction between the two hallway systems from these six photos alone.**

## Implementation, source, and provenance
- Canonical shipped implementation: 'school/emma-classroom/showroom/Room.lua' -> 'buildBackDoorAndHall()'.
- In source use one continuous physical floor and structural walls; no per-tile physical colliders.
- Tile mortar is flat noncolliding trim. Individual glazed brick courses are generated as native SurfaceGui frames on a handful of noncolliding dado surfaces. No external texture asset, catalog dependency, personal names, or image asset IDs.
- Retain existing opening leaf geometry, hinges, hall-facing room view, threshold height, visitor movement, classroom/desk counts, and existing side staff hall.
- Photo display sheets are **anonymous original geometry** with invented abstract pencil guidelines. The photographed content is never copied.
- Existing 'export_source_scene.py' and 'walkability_audit.py' must validate this assembled source. 'audit_hallway_photo.py' adds a runtime constructed-Luau check of tiles, door, paper displays and collision invariants.
- The existing mobile budget is at most 3,100 physical Parts for the assembled classroom. SurfaceGui Frames are **not physical Parts** but still require native mobile draw-cost review.

## Acceptance gates
1. Compile exact Luau source, Rojo-assemble the **classroom-only** project; confirm no question widgets, study-game remotes, people/NPC replicas, or student photographs.
2. Run actual constructed-Luau scene validation and mobile part budget. Both the existing 'rear_entry_hallway' route and classroom-to-rear-corridor clearance must remain navigable; the separate staff route remains unchanged.
3. Capture non-cutaway player-eye renders from the actual source at the doorway **(0,5.5,30)** looking left **(-40,7,38)**, then right **(40,7,38)**; check door/shamrock, brown brick bond, schoolwork rail, floor grid, window endcap and ceiling lights. Independent renderers do **not** accurately draw SurfaceGuis.
4. Finally inspect **native Roblox on iPhone** with movement, collision, lighting, text legibility, device FPS and exterior sky leaks. **Do not claim photo-perfect parity or publish the live place before native acceptance.**
5. Preserve draft PR #339, scheduled tasks, archived study/curriculum source and unapproved furniture mesh configuration. Do not repurpose real student photos as public assets.

## Future source photography
For true architectural accuracy, gather an empty hallway wide-angle image straight down each direction, an orthogonal photo of the classroom door, and optionally actual length/width measurements. No need to upload unredacted photos of other children.