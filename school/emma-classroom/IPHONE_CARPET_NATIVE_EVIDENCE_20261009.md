# Emma's Classroom — Native iPhone carpet visibility regression, October 9, 2026

## Evidence (private media retained in ChatGPT, never checked in)

A user-supplied 30.835-second, 1112×512, 30-fps landscape iPhone
screen recording captured around 12:49 PM Eastern on October 9 was inspected
at one-second intervals, with full-resolution checks at approximately
8.4 and 11.5 seconds.

- **11–13 seconds:** the circular alphabet rug appears extremely dark
  blue/navy rather than the visible brighter blue of the supplied room photos.
  Several actual dark-rug pixels near the center of the frame fall around
  RGB (25–39, 37–51, 49–63), despite the construction source dye RGB
  (68,117,181). These are screen pixels, not calibrated material measurements.
- **11–13 seconds:** the 16 sun rays are rendered as small orange specks
  around an otherwise plainly visible yellow center, even though the
  published source has .12-stud thick ray shapes.
- **11–13 seconds:** the white cloud lobes are rendered as tiny scattered
  dots, not ten recognizable 3-lobed clouds; the numbers cannot be clearly
  read from the same view. This demonstrates that earlier
  `IPHONE_NATIVE_RELIEF_GEOMETRY_PASS` tests were necessary but insufficient.
- **8–10 seconds:** five cream-colored storybook backs are visible on the
  older freestanding rack. Separate, newer development commits have already
  relocated those original covers and face them into the reading-book shelf.
  Do not revert or duplicate that fix.
- The recording itself does **not** display a definitive Roblox place
  version identifier. Its timestamp follows the verified v71 progress-preview
  publication, but this document does not claim to prove the playable version.

The recording, extracted frames, platform UI, participant images, account
details, and EXIF are NOT uploaded to GitHub or copied into the public game.

## Subtractive, same-part-count repair candidate

Development commits `a7c410937f39fa3f02c8404021ae4a7fe3010dc2`
and `465b6bb6f2d8bdd87364023722b19a895d80483f`:

1. Brighten the existing 14.2-stud **Fabric** rug from RGB (68,117,181)
   to RGB (107,165,222) without overlay textures or geometry.
2. Use the **same 16 original sun-ray ellipsoids**, with larger
   (1.06/.95)-stud radial profiles and .22-stud vertical relief rather
   than .82/.58 profiles and .12-stud thickness.
3. Use the **same 10 cloud bodies + 20 lobes** with 1.70-stud cream
   central bodies, 1.00-stud side lobes, and .22–.24-stud relief.
   Preserve approximate 2.24-stud spacing between neighboring clouds.
4. Move the same **10 invisible numeric anchors** up with the increased
   relief; increase only cloud number text to 104px, retaining 92px
   A–Z letters and transparent numeric label backgrounds.
5. Strengthen actual-constructed geometry and UI assertions for
   dye, footprint, relief, cloud grouping, number-face clearance and
   distinct letter/numeral text sizes.

No new physical Parts, collisions, personal media, furniture, teachers,
quiz data, scores or scheduled automations.

## Verification / release boundary

Exact-head classroom CI at `465b6bb6f2d8bdd87364023722b19a895d80483f`
passed with `SNAPSHOT_OK 2890 physical parts`,
`IPHONE_CLOUD_OCCLUSION_PASS`,
`IPHONE_NATIVE_RELIEF_GEOMETRY_PASS`,
`RUG_UI_RUNTIME_PASS`, four UI negative tests, all six conservative
static navigation routes, furniture rollback, and assembled classroom-only
study-authority isolation.

**IMPORTANT:** These are source-construction guards and do not prove
native iPhone carpet visibility. The headless renderer does not reproduce
Roblox's real fabric shader, SurfaceGui text, postprocessing, mobile
view-angle behavior or FPS. Do not publish/merge/activate premium furniture
meshes on this evidence alone.

**Required new test:** On a separately authorized playable preview, capture
the same in-game approach from the reading corner at player-eye height,
including a close-up of the rug from roughly the 11–13-second viewpoint.
Human reviewer must see an obviously blue rug, elongated distinguishable
orange/gold sun rays, ten white cloud shapes and readable numbers.
Any small dots / navy-black failure remains **visual acceptance FAIL**;
do not relax the source or image test thresholds to mask it.


## Engine-level root cause and corrective action
Roblox's Creator announcement at
https://devforum.roblox.com/t/improvements-to-part-shape-size/2443389
clarifies that `Shape=Ball` renders an actual sphere of diameter equal to
the **smallest** of the three size axes. Earlier independent renderers
interpreted e.g. 1.70×0.22×0.98 as a flattened elliptical shape, while the
native iPhone showed a 0.22-stud DOT. Increasing the other axes could never
resolve this mismatch.

Corrective development replaces all 16 sun rays with guaranteed elongated
shallow Blocks plus flat circular cylinder caps (16 additional noncolliding
Parts), and the ten white clouds with horizontal rectangular centers and
20 physically wide, floor-facing Cylinders. The carpet size, blue fabric,
sun center, ten text labels, 26 alphabet letters, all sixteen desks and
published gameplay remain unchanged. These are ORIGINAL authored primitives,
not copied photographs or downloaded assets.

The dedicated `audit_native_rug_primitives.py` runs the actual room
constructor and rejects malformed Ball clouds/rays with adversarial
mutation; required by both development CI and protected preview publication.
The actual Roblox game is still pending native acceptance, regardless of
source geometry or independent-renderer success.
