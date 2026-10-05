# PR 214 exact-head mobile obstruction preflight

## Artifact contract

- **Owner:** Roblox High School Integration Smoke
- **Input candidate:** PR [#214](https://github.com/P00NSMASHER/PipsQuestWorld/pull/214) at `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8`
- **Input canonical:** `rebuild/high-school-foundation@5fd5c0539229b629eda865e574539990d6e17b5b`
- **Reference clip/time:** C@00:05–00:08 Travel surface and the compact right rail/top-right status/bottom slots recurring across A/B/C; A@00:05, A@00:25, A@00:45 and A@02:05 remain the route/camera checkpoints
- **Acceptance criteria:** an exact integrated canonical must pass the existing PR 212 panel-transaction oracle and PR 198 responsive runtime oracle; every visible feature surface and close/back control must remain inside actual safe bounds; modal geometry must not obstruct movement/jump/gesture regions or the required compact HUD; desktop/iPhone/iPad rendered evidence stays pending until executed
- **Output:** `coordination/smoke/PR214_BAA6A24_MOBILE_OBSTRUCTION_PREFLIGHT.md`
- **Blocker:** PR 214 has no independent same-SHA QA review and has not been integrated. Source geometry predicts an iPhone-landscape out-of-bounds House surface and inaccessible close control. Roblox runtime/rendered/device traversal was not executed.
- **Next handoff:** Independent QA evaluates the exact source-level obstruction on `baa6a24`; the sole producer repairs it if confirmed. Integration acts only after same-SHA authorization. Smoke executes this oracle only on the resulting exact integrated canonical.
- **Status:** `HOLD_PREINTEGRATION__STATIC_MOBILE_OBSTRUCTION_PREDICTED__RENDERED_DEVICE_PENDING`

This is a coordination-only Smoke preflight. It is not product implementation, independent QA authorization, runtime evidence, a rendered/device PASS, or a parity claim.

## Live gate snapshot

| Gate | Exact evidence | State |
| --- | --- | --- |
| Canonical | `5fd5c0539229b629eda865e574539990d6e17b5b` | unchanged |
| Producer | PR 214 `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8`; base is exact canonical | open, mergeable |
| Class/Education guard | run `37247220604` | PASS on `baa6a24` |
| Progression guard | run `37247220568` | PASS on `baa6a24` |
| Foundation guard | run `37247220569` | PASS on `baa6a24` |
| Independent same-SHA QA | no review submissions observed | BLOCKED |
| Integration | PR 214 remains open | NOT STARTED |
| Smoke | exact repaired integration handoff required | HOLD |

## Real coverage gap closed

The existing responsive harness pins the compact status, rail and quick-bar rectangles. The PR 212 transaction oracle pins feature-panel state transitions. Neither turns PR 214's newly enlarged House surface and newly created centered Shop/Travel surfaces into explicit safe-bound and HUD-intersection oracles.

PR 214 changes the House surface from 248×252 to 248×292 while retaining:

- anchor `(0, 1)`;
- position `(256, viewportHeight - (auxiliaryPanelBottomMargin + 66))`;
- touch bottom margin `112`;
- a 26×24 close control at the House panel's top-right.

It also creates centered Shop and Travel surfaces sized to 82%×76% of the viewport, constrained to 286–560 px wide and 250–390 px high.

## Deterministic source-geometry preflight

The target profiles and safe insets are inherited from the PR 198 oracle:

| Profile | Viewport | Safe insets L/T/R/B |
| --- | ---: | ---: |
| desktop | 909×483 | 0/0/0/0 |
| iPhone landscape | 852×393 | 47/0/47/21 |
| iPad landscape | 1024×768 | 24/0/24/20 |

### House surface

For touch profiles, House bottom is `height - 178`; top is `height - 470`.

| Profile | Predicted House rect x/y/w/h | Safe-bound result |
| --- | --- | --- |
| desktop | 256/113/248/292 | inside viewport |
| iPhone landscape | 256/-77/248/292 | **FAIL_SOURCE_GEOMETRY:** 77 px above safe top |
| iPad landscape | 256/298/248/292 | inside safe bounds |

On iPhone landscape, the new House close control is predicted at x=475..501 and y=-75..-51, entirely outside the visible viewport. The Back control remains lower in the panel, but an inaccessible Close control does not satisfy the explicit close/back mobile contract. This is a deterministic source-level prediction, not a rendered result.

When House edit mode is active, the existing 330×346 editor surface is predicted at x=512..842 and y=-131..215 on iPhone landscape. It is 131 px above the viewport and extends 37 px beyond the safe right edge at x=805. Smoke must capture House and editor rectangles separately and together.

### Centered Shop and Travel surfaces

| Profile | Predicted centered rect x/y/w/h | Intersection to capture |
| --- | --- | --- |
| desktop | 174.5/58/560/367 | about 4 px vertical intersection with the quick bar |
| iPhone landscape | 146/47/560/299 | about 28 px vertical intersection with the quick bar |
| iPad landscape | 232/189/560/390 | no predicted quick-bar or rail intersection |

The exact engine rounding, draw order, input capture, and whether the quick bar is intentionally hidden or visibly obstructed require rendered/runtime evidence. Static geometry alone must remain `PREDICTED`, never `PASS` or `FAIL_RENDERED`.

## Required post-integration capture matrix

At each profile, record `AbsolutePosition`, `AbsoluteSize`, `Visible`, `ZIndex`, and the actual safe rectangle for:

- `VerifiedStyleShopPanel`;
- `CurrentClassTravelPanel`;
- the avatar `OutfitInputs` panel;
- `LegacyHousePanel`;
- `LegacyHousingEditorV2`;
- `CompactSchoolStatus`;
- `RHS2ActionRail`;
- `RHS2QuickBar`;
- actual Roblox movement, jump and gesture bounds.

For each Shop → Travel → Avatar → House transition:

1. wait one rendered frame;
2. assert exactly one feature panel is active;
3. assert the active surface, Close and Back controls are contained by actual safe bounds;
4. assert close/back is tappable without activating movement, jump, camera gestures, a quick slot or another rail item;
5. record all pairwise intersections with status, rail, quick bar and touch controls;
6. execute explicit Close, explicit Back, repeat-open, Escape/ButtonB where available, denial restore and respawn reset;
7. retain quick-slot activation as pending unless existing item semantics are genuinely reachable; empty labels are not proof of activatability;
8. run House both before ownership and in edit mode so the editor pair is captured;
9. repeat the C@00:05–00:08 Travel checkpoint and the A@00:05/00:25/00:45/02:05 route checkpoints at comparable FOV without deriving speed from 2× footage.

Any surface or required control outside actual safe bounds is `FAIL_RUNTIME_EXACT_CANONICAL`. Any required compact HUD or touch-control intersection must be classified with a screenshot and interaction result, not waived from source assumptions.

## Handoff rule

Do not merge PR 214 on the basis of this Smoke artifact. Independent QA owns candidate disposition. If the producer changes the head, all three CI runs, the QA decision, Integration readiness and this source-geometry fingerprint become stale. Smoke begins only after Integration hands off one exact repaired canonical and keeps all rendered/device checks pending until actually executed.
