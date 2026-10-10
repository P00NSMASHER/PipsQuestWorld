# Emma's classroom-only replica — native visual acceptance

**Scope:** PR #339's explorable classroom-only Rojo project
(`school/emma-showroom.project.json`). This acceptance sheet does **not**
supersede the study-game/teacher/question checklist in
`school/emma-classroom/VISUAL_ACCEPTANCE.md`.

**Status as of October 10:** SOURCE BUILD & LU AU STATIC CHECKS PASS;
**NATIVE ROBLOX/IPHONE VISUAL ACCEPTANCE IS PENDING.**
The latest publicly confirmed playable progress preview was v78. An
unmerged PR candidate, a GitHub checkmark, and a static third-party render
are **not evidence** that these edits are running on the live Roblox place.

## Evidence for each candidate
For each candidate, record its *exact* full Git commit SHA, constructed room
part count, all exact-head test URLs and conclusions, and at least one real
Roblox iPhone recording captured after a separately authorized owner-only
preview publication. Never use an older live-game capture to approve later
unpublished source. Record device orientation and approximate camera position
for each native view; do not synthesize Roblox engine frames.

The existing 21-view headless renderer and the parallel four-view camera
provide useful geometric debugging. They **cannot** simulate Roblox native
lighting, precise materials, SurfaceGui lettering/checkers, touch controls,
device physics, frame-rate or photo-parity. The four-view artifact includes
a manifest with `notNativeIphoneAcceptance=true`.

## Native inspection checklist — permanent scenery

- [ ] **Windows / AC:** Two windows with navy drapes; lower-left window AC
  is immediately recognizable; both radiators are beneath the windows.
  Wood returns, curtains and wall signs are not sunk behind the glass.
  The original five-piece white analog clock faces into the classroom from
  the yellow pier between the two windows, rather than the front chalkboard.
- [ ] **Wooden built-ins:** Tall dark timber display/shelves/cubbies
  read as a coherent built-in wall. Black teaching inset, number frieze,
  high shape cards and original opening are not overlapping the doorway.
  The frieze shows the consecutive **0–120** numbers (not only multiples
  of ten), and the upper dark panel physically joins the lower wood case.
- [ ] **Blue word wall:** Blue board is bright enough to see at child eye
  height; two rows of red A–Z apple markers and small word slips render
  legibly. The green historic **First Grade Word Wall** sign is small,
  centered above the board, not an oversized generic encouragement panel.
- [ ] **Gingham table:** Under the word wall, the table visually shows
  red/ivory checked fabric on the top AND hanging vertical apron faces,
  not a plain white box. SurfaceGui checks are legible from an iPhone
  and do not shimmer or interfere with nearby walking routes.
- [ ] **Teaching wall:** Larger chalkboard is visible behind the wheeled,
  white-framed Smartboard. Alphabet/handwriting panel is legible; 26
  small phonics cards stay on solid teaching wall and out of ceiling.
  Photo-backed white dry-erase flipchart has blue supports and wheels,
  not a fictional wooden award plaque.
- [ ] **Floor and ceiling:** Dark fine-grain polished wood floor does not
  show exaggerated Roblox plank seams. Pale ceiling tiles and narrow
  gray grid are bright and unbroken; six frosted troffers look like
  broad school fluorescent fixtures rather than emissive neon panels.
- [ ] **Both rugs:** Circular sun/number/ABC rug has readable letters,
  ten numbered clouds and visible orange sunburst. Separate black
  rectangular polka-dot rug uses colored round dots. Both are accessible.
- [ ] **Navigation:** First-person iPhone camera, movement thumbstick and
  jump button work; spawn, windows, bookcases, teacher wall, right aisle
  and both existing doors remain physically reachable. Check corners,
  desktop approach and under-table collision in the actual engine.
- [ ] **Mobile visual stability:** No blank views, floating trim, black
  material disappearance, clipped school text, excessively dark ceiling,
  z-fighting, or prolonged frame stalls while walking.

## Unresolved evidence, not approved coordinates

The photographs were taken during a cheer activity, **not** an empty daily
classroom survey. The photo **confirms furniture appearance**, but cannot
establish which desks/chairs were temporarily relocated. Do not treat the
photographed clear-floor performance formation as a measured normal-day
layout. Confirm with owner/child before moving the 16 preserved desk/chair
pairs, either rug, word-wall table, or rolling flipchart. In particular:

- [ ] Confirm whether the round and rectangular rugs are normally adjacent.
  In the photographed event they appear much closer than in the source.
- [ ] Confirm exact purple-chair style and resting location. Its existence
  is child-reported; its occupied silhouette is not independently visible.
- [ ] Confirm normal-day position of the checkered table, rolling easel and
  blue seating along the built-ins.
- [ ] Distinguish historic *First Grade* bulletin-board text from the
  child's current educational content; do not feed decorative words into
  the governed study-question bank.

## Privacy and release controls

- [ ] Original school/cheer photos with identifiable minors and adults are
  not publicly committed, converted to Roblox textures, or made into NPCs.
  Anonymous original classroom art is acceptable.
- [ ] The Rojo classroom-only build includes **no** teacher/question GUI,
  QuestionBank, score service, DataStore, quiz remote, or learning importer.
- [ ] Existing production furniture mesh activation remains disabled until
  its separate native authorization/QA.
- [ ] Preserve current deployment consent: **do not merge PR #339 or
  publish another owner progress preview merely because source QA passed**.
  Exact-SHA/native evidence and explicit approval are required for final
  visual acceptance. Keep failed checks and invalid snapshots visible.

## Native review record

| Field | Required evidence |
| --- | --- |
| Source SHA | Exact 40-character PR source commit |
| Roblox place/version | Verifiable deploy receipt, not inferred from PR |
| Device and orientation | Actual iPhone / landscape or portrait |
| Gameplay capture | Direct recording of the built place |
| Five photo landmarks | Window, built-ins, word-wall/table, teaching wall, both rugs |
| Navigation, surface artwork | Observed working without collisions or missing lettering |
| Decision | Approved, rejected with specific discrepancy, or pending |
| Owner/child input | Decisions on uncertain daily furniture placement |

This sheet is a **review gate**, not an automatic test pass or publication
authorization.
