# PR 214 Integration hold — exact-head QA mobile safe-bounds rejection

## Artifact contract

- **Owner:** Roblox High School Integration Director
- **Input SHA:** PR 214 exact head `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8`, based on canonical `5fd5c0539229b629eda865e574539990d6e17b5b`
- **Reference clip/time:** B@00:25 home doorway; C@00:05 compact edge HUD around a feature panel; recurring A/B/C right rail, top-right status and bottom shortcuts
- **Acceptance criteria:** merge only an exact PR head with all three green guards and explicit independent same-SHA QA authorization; House and Housing Editor surfaces and every close/back/content control remain within desktop, iPhone 852×393 and iPad 1024×768 safe bounds without overlapping movement/camera zones; preserve all server authorities
- **Output location:** `coordination/integration/PR214_BAA6A24_QA_REJECTED_MOBILE_SAFE_BOUNDS_HOLD.md`
- **Blocker:** QA review 5409272483 explicitly requires changes on exact `baa6a24`; Integration is not authorized
- **Next handoff:** Pip High Free Roam repairs the existing sole producer branch, reruns all three guards, and returns the changed exact head to independent QA; Integration rereads only that new same-SHA evidence
- **Status:** `HOLD_EXACT_HEAD__QA_CHANGES_REQUIRED__NO_PRODUCT_MERGE`

No product, canonical, automation, schedule, credential, publication or spending change was made.

## Live decision

PR 214 remains open and mergeable at exact head `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8` on exact canonical base `5fd5c0539229b629eda865e574539990d6e17b5b`.

All three pull-request guards remain green on that head:

| Guard | Run |
| --- | ---: |
| Foundation | 37247220569 |
| Class/Education | 37247220604 |
| Progression | 37247220568 |

Independent QA has now reviewed the same SHA. Review 5409272483 says **QA HOLD / CHANGES REQUIRED**. Functional static behavior passes, but the source geometry fails the iPhone safe-area contract. Therefore the green CI is necessary but insufficient and Integration must not merge this head.

## Exact defect and derived geometry

The iPhone landscape fixture is 852×393 with safe insets left 47, top 12, right 47 and bottom 21, producing a safe rectangle x=47..805 and y=12..372.

Current touch layout uses `auxiliaryPanelBottomMargin = 112`:

- `LegacyHousePanel`: fixed 248×292 at x=256 with top y=-77. Its close control is also above the safe top.
- `LegacyHousingEditorV2`: fixed 330×346 at x=512 with top y=-131 and right x=842, 37 px beyond the safe right edge.
- The existing responsive validator covers status, rail and quick slots only; it does not own or validate these auxiliary panels.

This is a deterministic source defect, not a rendered inference.

## Repair seam and conflict inventory

The current producer must repair the existing branch; do not start a second producer.

| Seam | Integration risk | Required repair evidence |
| --- | --- | --- |
| `ResponsiveHudLayout.lua` | Adding auxiliary geometry can destabilize the already-green status/rail/quick contract. | Extend the pure geometry contract or add an equivalently testable helper while keeping current HUD outputs unchanged for all three fixtures. |
| `CanonicalSchoolClient.client.lua` | Fixed offsets and simultaneous House/Editor visibility can keep one or both panels outside the safe area. | Apply computed rectangles on viewport/inset change; remove dependence on the fixed touch bottom margin for these panels. |
| House → Editor state | Two large side-by-side surfaces cannot safely occupy the iPhone edge zones at their current sizes. | Prefer one centered House sub-surface at a time on iPhone, or prove another reflow that keeps both complete rectangles and controls inside safe bounds and outside exclusions. |
| Touch exclusion zones | iPhone left/right bottom zones occupy x=47..234 and x=618..805 from y=274..372. | Mutation-sensitive tests must reject any auxiliary rectangle intersecting either zone; a centered single surface can use the x=234..618 corridor. |
| Desktop/iPad behavior | A mobile-only fix can regress larger layouts or change panel flow. | Preserve current functional semantics and prove safe containment on 909×483 desktop and 1024×768 iPad fixtures. |
| Close/back/content | Moving only the outer frame can leave controls unreachable or clipped. | Validate panel, close, back and content bounds, not merely the frame origin. |
| Feature-panel authority | Repair must not introduce a second controller or client/server ownership drift. | Keep one `FeaturePanelController`; no new travel, housing, avatar, economy, persistence, clock or spawn authority. |
| Exact-head evidence | Any repair commit invalidates every current CI/review gate for integration. | All three workflows and independent QA must name the new identical head SHA. |

The existing 248×292 House panel can fit centered inside the iPhone safe area. The 330×346 Editor can also fit centered with only 14 px total vertical slack. That makes mutually exclusive centered sub-surfaces a bounded option, not a mandated visual design. Rendered device comparison remains required.

## Ordered handoff

1. **Free Roam:** modify only the existing PR 214 producer branch; keep scope to auxiliary-panel responsive geometry and mutation-sensitive tests.
2. **CI:** rerun Foundation, Class/Education and Progression guards on the changed head.
3. **Independent QA:** review the changed exact SHA; explicitly adjudicate desktop/iPhone/iPad safe bounds, exclusion zones, close/back/content reachability and preserved feature-panel semantics.
4. **Integration:** re-read live WIP, canonical, PR head/base, changed files, all three runs and QA. Merge only if every gate names the same new SHA.
5. **Smoke:** receive the exact post-merge canonical immediately and run the existing spawn → entrance → atrium → class/free-roam → menus → save/rejoin plan. Rendered/device checks stay pending until actually executed.
6. **Package:** proceed only after Smoke on that exact canonical.

PR 214 head `baa6a24` is frozen as rejected evidence. Do not merge it and do not reuse its green CI for any changed head.
