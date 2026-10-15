# Architectural finish review - October 13

Native tests execute the actual Roblox engine; headless checks are reported separately.

## Implemented
Six bounded, occlusion-respecting frosted fluorescent face graphics; five ceiling cross rails at tile-edge gaps; side trim moved against the plaster; reduced carpet art relief; brushed-steel finish on 192 existing furniture pieces; restrained varnish on 44 existing cabinet pieces. No added physical Parts, lights, external assets, colliders, furniture relocation or hallway change.

## Verification
All 25 existing source/build checks passed. Three new native regression tests were each observed failing on the old scene, then passing after repair. Native Play startup, 16 desk pairs, 3,050 parts, full straight hallway out-and-back movement without teleporting, and iPhone 16 landscape simulator startup all passed. Simulator touch controls and before/after native images were inspected. Console empty after final checks. This is not physical-iPhone FPS evidence or completion of the photo replica.

## Independent review adjudication
A read-only Studio explorer review was rerun in Edit mode after its first Client-mode attempt could not see server scripts. Its suspected geometry/count defects were checked rather than blindly implemented:
- Tiles have centers at -28,-16,-4,8,20 with width 11.72 and center spacing 12. Interior edge gaps are centered at -22,-10,2,14, so those rail centers are correct; z26 is the final edge gap. The reviewer incorrectly treated 11.72 as center spacing.
- Walls are centered at +/-37 but are one stud thick: their inner surfaces are +/-36.5. Trim at +/-36.55 overlaps the inner face slightly as mounted molding.
- Native tests counted 192 targeted metal instances and 44 targeted wood instances; whitelist entries represent repeated pieces, not total instance count. Unrelated metal props intentionally remain unchanged.
- SurfaceLight.Shadows remains false, exactly as before this change. No extra shadowed lights were introduced.

## Excluded experiment
Approved original chair/desk mesh models loaded, but the exploratory runtime exceeded the current part budget and rendered default grey until streaming. No adapter/config change was retained; the trial was stopped and complete original furniture was verified restored. Do not enable those models from this receipt.

## Remaining
Further architectural and furniture fidelity, more calibrated mobile lighting review, real-phone frame-rate and published asset delivery validation. Existing PR stays draft; no publication or marker/schedule changes.


## Complete-export CI follow-up
The first push failed the full exporter, which was not included in the original 25-command local runner. It still required the old raised cloud height, .820-stud floating number anchors and thick ray caps. The same failure was reproduced locally before changes. No game code was altered to satisfy the old shape. Instead, narrow geometry guards now enforce the actual native-verified thin artwork, positive number clearance, nonburied geometry, original shapes/counts and original collision rules. A full-export regression rejects old raised clouds, floating labels, sunken clouds and opaque number stickers. The new audit is part of Classroom Replica CI. The expanded local runner passes 27/27 checks, including full scene export. Historical red CI is preserved.
