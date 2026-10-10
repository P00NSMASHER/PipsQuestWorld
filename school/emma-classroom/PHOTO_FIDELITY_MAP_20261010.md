# Emma classroom: 10 October photo-grounded layout map (Phase 0)

## Evidence handling
The October 10, 2026 cheer-day photographs and the 44-second iPhone Roblox recording were reviewed in the owner's conversation. **Originals contain identifiable children and adults; they are intentionally not committed to this public repo.** This document records only non-identifying architectural observations. Do not embed full event photos in the game or use their people as NPCs.

## Existing game's coordinate basis
Source: `school/emma-classroom/showroom/Room.lua`, inspected PR #339 parent `d1b5cdaefa385eef6ba814c535b7acdae834788a`.

| Game landmark | Established source location | Confidence / observation |
| --- | --- | --- |
| Architectural shell | x -37..+37, z -35..+27; height about 18 studs | Verified source, not a measured real-world floor plan |
| Real-window candidate wall | x ≈ -37; windows at z=-19 and +6 | Source-verified; photos confirm two curtained windows, lower-left AC and radiators |
| Lower-left photographed AC | (-35.55, 5.23, -19) | Photo supports type and window; exact coordinate source-defined |
| Front teaching wall | z ≈ -35 | Source-verified; photos show dark chalkboard and mobile white-framed Smartboard |
| Back built-in wall | z ≈ +27; existing bookcase x -31..-13, cubbies x 7.5..34.5, doorway in center | Strong photo evidence for long dark-wood built-ins; **assignment of exact side/window orientation remains a provisional room-model interpretation** |
| Blue vocabulary word wall | x ≈ +36, z around +1 | Strong photo evidence for board style; wall assignment photo-perspective provisional |
| Circular sun/number/ABC rug | game at (-25, 0.6, +14) | Photos confirm appearance, not normal-day position |
| Rectangular black polka-dot rug | game near (-25, 0.6, -20) | Photos confirm appearance, not normal-day position |
| 16 student desks with molded chairs | existing source grid; not changed by this phase | Current baseline preserved; cheer event rearranged chairs |
| Single purple chair | (-32.45, ~1.62, -19.60), rotated toward workstation | Child reports chair exists; occupied photo obscures chair styling and precise location |

## October 10 change contract
1. Improve **the existing left reading case**, not a duplicate freestanding cabinet. Install a shallow, dark built-in display inset above its shelves, aligned with the right cubby cabinet across the room's rear wall.
2. Retain the real central doorway entirely; never extend dark display panels through the doorway.
3. Put nine existing shape cards over solid wall to the doorway's left. Do not add more parts for cards.
4. Retire the three old decorative left-of-door framed gallery pictures that overlay the dark notice inset; retain the three original right-of-door generic artworks. This is source cleanup, not use of real children's assignments.
5. Add a small left-hand numeric strip (0–60) above the bookcase; change the existing right strip to the subsequent 70–120 range to avoid duplicate teaching numbers.
6. Use *anonymous*, hand-authored paper rectangles, not reproduced photographs, actual students' work, names, or other personal school data.
7. Preserve current visual style, both rugs, curtains/AC, 16 desk/chair pairs, unique provisional purple chair, doors, navigation, and <=3,100 physical parts.

## Fidelity confidence and what's not established
The photographs show a cheer activity setup. They do **not** document permanent daily placement of the chairs, Smartboard, teacher equipment, easel, mats, and rugs. No real-world tape measurements, complete four-wall panoramic survey, or unoccupied purple-chair picture was supplied. The shell/world-axis mapping is the existing model's coordinate convention, **not** verified true-to-scale survey data.

## October 10 next visual correction: varnished floor surface
The owner's native phone recording shows heavily exaggerated plank joints in the game.
The real photos show smaller, tighter, much darker polished wood boards.
The *existing one-piece floor* changed from Roblox `WoodPlanks` to fine-grain
`Wood`, RGB (83,59,45), reflectance 0.10. This is a photographic inference,
not a claim of matching actual measured gloss or texture.
No new Parts, textures, uploaded photo assets, or geometry changes.
`audit_lighting.py` now rejects a reversion to `WoodPlanks`,
and `export_source_scene.py` verifies the actual source material and color.
Owner's native Roblox/iPhone visual acceptance is still required.

## October 10 phone-visible dark-ceiling defect and candidate fix
The October 10 iPhone video shows nearly black, vertically grooved ceiling
panels, unlike the real white acoustic suspended ceiling in the school
photographs. The existing 30 inset parts were `Fabric` and the ten thin
grid bars were metallic, despite bright source RGB. The candidate retains
all 30 tiles, ten bars, positions, six fluorescent diffusers and unchanged
lighting schedule, but assigns the tiles and grid native
`SmoothPlastic` with near-white colors to avoid cloth grooves and dark
metallic overhead response. Exact Luau constructor checks reject the old
Fabric/Metal regression; *actual new native iPhone rendering is still pending*.

## Test and release gates
- Actual Luau construction geometry and negative tests: `showroom/audit_photo_landmarks.py`.
- Same-source Roblox build: `school/emma-showroom.project.json` / `.github/workflows/emma-showroom-ci.yml`.
- Source-only rendered rear-wall camera in `.github/workflows/emma-showroom-visual-preview.yml`; headless colors do not prove native Roblox.
- A human must review real iPhone screenshots against the source photographs before final visual acceptance. Keep PR #339 draft; no automated final publish or curriculum modifications.
