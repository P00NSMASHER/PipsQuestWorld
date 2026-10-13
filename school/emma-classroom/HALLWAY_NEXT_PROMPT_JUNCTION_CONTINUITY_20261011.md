# ABVM hallway continuation — left exit floor/ceiling continuity

## Executed prompt

Act as the senior Roblox classroom-architecture engineer, Luau/Rojo
integration developer, and adversarial source-geometry QA reviewer.

The owner's final doorway direction is authoritative:

- The classroom's LEFT exit is the **actual navigable entrance to the
  photographed long school corridor**, via the right-edge staff-side
  hallway that turns north into the 108-stud gallery.
- The OTHER original rear **double-door opening is a walk-in supply CLOSET**
  with real collidable side and back walls. It must not serve as a second
  route into the photographed corridor.
- Do not silently restore the obsolete older study room or add new rooms.

An analysis of actual authored CFrames on the latest photo-hallway review
branch found a **1.25-stud missing floor and ceiling strip** at the new
junction. The side hall floor and roof both ended at z=25.50; the main
photo corridor starts at z=26.75. A horizontal 2D walkability route can
pass across that gap without testing whether a player has supporting
floor or roof at the turn. This is not native Roblox engine physics.

Fix both surfaces **without adding any Parts** and without adding
separate floating bridges:
1. Extend the existing side floor to the main polished-tile floor by
   moving its north edge to z=27.30, preserving south edge z=5.50,
   and keeping the surface 0.02 studs lower than the main floor so
   coplanar overlaps do not flicker.
2. Extend the existing side ceiling to the same z=27.30. Preserve
   actual enclosure with the ivory school hallway ceiling and the
   solid side outer-corner wall.
3. Use the same Roblox shapes, same room build, and same classroom-only
   Rojo target. Keep the user's original classroom, photographed rail,
   children/privacy exclusions, source tests and schedule settings.
4. Run a real constructed-Luau acceptance test, not a regex-only
   assertion. Verify continuous **X and Z** floor support, ceiling
   enclosure, <0.06-stud step, sole left hallway route and sealed
   right supply closet. Make adversarial tests fail when the old floor
   gap, sky gap, excessive drop, missing closet wall, or lost outer
   corner is restored.
5. Keep the original static avatar route checks and physical mobile
   part limit of 3,100 intact. Create a reproducible uncut source-derived
   child-height camera for the left-door turn. The renderer cannot prove
   actual Roblox/iPhone lighting, collision or device FPS.
6. Commit as a draft stacked PR onto the CURRENT photo-hallway PR #343.
   Do not merge or publish; a prior version-81 publication receipt is
   not permission to push new unreviewed layout changes live.

## Changes authored

- `school/emma-classroom/showroom/Room.lua`: existing `Side hall floor`
  extends z=5.50–27.30 with top y=0.48, beneath main hallway top y=0.50.
  Existing `Side hall ceiling` extends z=5.50–27.30; its underside
  y=13.00 lies within 0.02 studs of the main ivory hall ceiling.
  Expected z overlap with the photographed main hall: **0.55 studs**
  for floor and roof. **Zero new physical Parts.**
- `school/emma-classroom/showroom/audit_left_hall_junction.py`:
  actual Luau constructor validation and five counterexample mutations;
  validates physical X/Z footprints, levels, closure and 3,100-Part cap.
- `.github/workflows/emma-showroom-ci.yml`: a dedicated early
  junction safety gate, independent of unrelated word-wall checks.
- `.github/workflows/emma-showroom-visual-preview.yml`: uncut
  `09-hall-left-floor-roof-junction` child-eye screenshot as a
  source-derived review artifact.

## Boundaries

The hallway's real-world dimensions and axis are still provisional;
no actual school photograph containing students is stored in this
public repository. An automated static model and third-party renderer
cannot certify human-scale physical movement, glass or SurfaceGui
appearance, shading or iPhone frame rate. A native iPhone walk and
visual acceptance are still required before publishing.
