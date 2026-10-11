# October 11 — independent paper-gallery and yellow-window camera acceptance

## Chosen and executed engineering prompt

Act as a senior Roblox hallway architectural QA engineer, source-derived
rendering specialist and mobile release gatekeeper. The classroom-only
Emma place now has a correctly **sealed rear supply closet** and one
walkable left/staff-door connection to the long photo hallway. Restore
independent visual verification of the anonymous paper display in BOTH
existing hallway cameras without altering the room's scenery.

The fast-render check was changed on the hallway parent to run the
6-region `audit_rendered_hallway_papers.py` on only
`07-hall-yellow-end-window.png`, even though `06-hall-paper-rail.png`
is a purpose-built, child-eye camera showing the same suspended display
from a genuinely different perspective. This creates a future false
acceptance risk: a blank or occluded 06 screenshot could pass while
07 remains perfect.

- Keep **both** render files and unchanged fixed Luau eye/aim positions.
- Require the original per-camera 6-region/25,000-pixel silhouette
  checker independently on **06 and 07**; retain the existing window,
  oak-door, 3,100-Part mobile, nine-source-route, right closet and
  floor/ceiling checks.
- Add a separate two-view verifier with distinct perspective requirements,
  reject identical rendered RGB frames (even if encoded differently),
  swapped views, missing one or more diamonds, and weak oblique gallery
  visibility. Include synthetic non-sensitive negative test fixtures.
- Use only original anonymous geometric indicators. Do not store the real
  October school photographs, students' identities, handwriting, or
  assignments in the public repository or output artifacts.
- This work is a **stacked draft**, not a Roblox live publication or
  proof of native iPhone FPS, glass transparency, GUI coloring or physics.

## Ground truth from actual full-source renderer, before implementation

At prior head `c1463f7e56e53605803c3df78b639a8cb1694271`,
[fast visual run 38163920385](https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/38163920385)
passed. I downloaded the corresponding
`emma-fast-photo-c1463f...` artifact and inspected both real PNGs
with connected-component pixel counts using the existing pale-paper
predicate and its fixed crop `(0,145,925,570)`:

| Actual fixed source-derived camera | Distinct accepted paper regions | Accepted pale paper pixels |
|---|---:|---:|
| `06-hall-paper-rail` | **7** | **68,713** |
| `07-hall-yellow-end-window` | **6** | **41,523** |

`06` is not blocked or missing its papers; its last regression
was caused by an older camera inside the closet. Its current image
shows large close paper diamonds on the wall, timber hanging rail,
blue-gray wall/amber brick, yellow end window, lamps and oak doors.
The seven accepted oblique components total 1.65 times the six
accepted yellow-window components. Fixed-camera review should fail if
this relationship or the existence of either independent exposure
is erased.

## Implemented test and workflow

- `school/emma-classroom/showroom/audit_rendered_hallway_papers_dual.py`:
  builds upon the **same** existing `inspect` connected-component
  checker, and requires >=7 independent oblique components and
  >=50,000 paper pixels in 06, >=6 / >=25,000 in 07, with
  >1.20x near-vs-far silhouette coverage, genuinely different raw
  RGB pixel hashes and the exact 1920x1080 source-render viewport.
  Deliberate negative inputs: missing either view, swapped 06 and 07,
  duplicated identical frames, one missing diamond per view,
  a too-weak closeup and an invalid phone-sized substitute.
- `.github/workflows/emma-showroom-visual-preview.yml`:
  invokes the established single-view semantic checker on both
  original images, then the dual-view verifier and self-tests before
  writing the evidence manifest. Both original image artifacts remain
  available for review.
- The 3D room constructor, iPhone controls, navigation topology,
  existing safe furniture, props and publish workflow **are untouched**.

## Release limitation

The source-derived renderer has no authoritative native Roblox material
appearance or phone performance. A passing CI proof is not live
publication. The last recorded Roblox version remains whatever the
repository's verified release receipt says; no automatic publication
occurs from this QA-only branch.
