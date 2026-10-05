# PR 214 Integration Readiness: QA Wait and Conflict Inventory

- **Owner:** Roblox High School Integration Director
- **Candidate:** PR [#214](https://github.com/P00NSMASHER/PipsQuestWorld/pull/214), `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8`
- **Base / current canonical input:** `rebuild/high-school-foundation@5fd5c0539229b629eda865e574539990d6e17b5b`
- **Reference evidence:** B @ 00:45 (dealership panel), C @ 00:05–00:08 (Travel selection), and the recurring compact HUD in A/B/C
- **Output:** `coordination/integration/PR214_BAA6A24_QA_WAIT_AND_CONFLICT_INVENTORY.md`
- **Decision:** **WAIT — do not merge PR 214.** Exact-head CI is green, but there is no explicit independent same-SHA QA authorization.
- **Blocker:** Independent QA has not reviewed `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8`. The quick-slot interaction acceptance criterion may also remain unclosed: the candidate removes invented slot labels but the four slots remain non-activatable `TextLabel` instances.
- **Next handoff:** Independent QA must review this exact SHA and explicitly authorize or reject it. Integration may act only on that same SHA after approval.

## Live candidate reconciliation

PR 214 is open and mergeable. Its base is the exact current canonical, it is one commit ahead and zero behind, and its five-path delta is:

| Path | Observed delta | Integration relevance |
|---|---:|---|
| `school/default.project.json` | +3 | Adds shared module mapping; verify no mapping/name collision. |
| `school/src/client/CanonicalSchoolClient.client.lua` | +330/-19 | Shared client hotspot for HUD, panels, travel, housing, avatar, and lifecycle reset behavior. |
| `school/src/shared/FeaturePanelController.lua` | +113 | New single deterministic panel authority; must not duplicate an existing controller. |
| `school/tests/feature_panel_controller_spec.lua` | +71 | Static controller coverage only; not rendered/device evidence. |
| `school/tests/legacy_hud_contract_spec.lua` | +19 | Rejects guessed slot labels, but does not demonstrate quick-slot activation semantics. |

Exact-head workflow runs observed green:

| Required guard | Run ID | Head |
|---|---:|---|
| Class/Education Regression Guard | 37247220604 | `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8` |
| Progression Regression Guard | 37247220568 | `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8` |
| Foundation Regression Guard | 37247220569 | `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8` |

Independent reviews observed: **none**.

## Acceptance criteria before Integration

All criteria are conjunctive and must apply to the exact candidate SHA:

1. All three required workflows remain green on `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8`.
2. Independent QA posts explicit same-SHA authorization after reviewing changed behavior and authority boundaries.
3. The candidate maintains one active feature-panel controller with explicit close/back, repeat-open idempotency, denial/unavailable recovery, respawn reset, and rejoin restoration.
4. Travel presents evidence-backed destination selection before the existing server request boundary, with no client-side authority expansion.
5. Existing server authorities for travel, housing, avatar, vehicles, inventory, progression, persistence, clock, and spawn remain unique.
6. Responsive HUD safe-area, touch-exclusion, camera-listener, keyboard, gamepad, and mobile behavior remain intact.
7. Quick slots are activatable only through existing item semantics. No invented item labels, auto-spend, invented entitlement, or fabricated persistence is allowed.
8. Static/headless results are not represented as rendered, iPhone, or iPad PASS.

## Collision and conflict inventory

| Seam | Risk | Required check |
|---|---|---|
| Rojo project mapping | New shared module can collide with an existing path or mapping convention. | Verify `FeaturePanelController` resolves exactly once under the expected shared container. |
| Client panel authority | Existing shop/avatar/house/travel bindings share a large client file. | Confirm all four use one controller and no legacy parallel visibility toggles survive. |
| Travel boundary | New selection UI may accidentally move validation or authority client-side. | Confirm the controller only prepares selection and the existing server request remains authoritative. |
| HUD layout | Centered panels and the enlarged house panel can obstruct the compact HUD. | Render at iPhone and iPad targets; inspect right rail, top-right balances/status, bottom slots, safe areas, and touch exclusions. |
| Lifecycle reset | Respawn/rejoin may retain stale panel or selection state. | Verify one visible panel maximum, clean respawn reset, and rejoin restoration from authoritative state. |
| Back/close inputs | Escape/gamepad back and explicit close can double-handle state. | Verify deterministic single transition and repeat-open idempotency. |
| Quick slots | Four slots remain labels rather than controls in the observed patch. | QA must determine whether the interaction requirement is satisfied or return the exact SHA for repair. |
| Shared hotspot merge | Concurrent HUD or environment work can overlap `CanonicalSchoolClient.client.lua`. | Keep PR 214 isolated until QA disposition; do not merge stale preparation over a moved head. |

## Ordered handoff

1. **Independent QA:** review the exact candidate `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8`, including the quick-slot acceptance question and authority preservation.
2. **Producer:** if QA rejects, repair only on the authorized producer slot and publish a new exact SHA; prior CI/review evidence becomes stale.
3. **Integration:** re-read live WIP, candidate head/base, all three CI runs, and the explicit QA decision. Merge only if every artifact names the same SHA.
4. **Smoke:** receive the exact integrated canonical immediately; test spawn → entrance → atrium → class/free roam → menus → save/rejoin as implemented, keeping rendered/device checks pending until actually performed.
5. **Package:** proceed only after Smoke reports on the exact integrated canonical.

This document is preparation only. It does not authorize product integration and does not claim reference parity.
