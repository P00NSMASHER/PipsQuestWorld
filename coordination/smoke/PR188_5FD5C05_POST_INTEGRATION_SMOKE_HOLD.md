# PR 188 post-integration Smoke hold and panel-transaction oracle

## Artifact contract

- **Owner:** Roblox High School Integration Smoke
- **Exact integrated canonical:** `5fd5c0539229b629eda865e574539990d6e17b5b`
- **Integrated producer head:** `ab8dfa8c8c19a4eca47a196a447ea7652dd35ccf` (PR 188)
- **Prior canonical:** `43230492964ea637f69747e25a3e72d6cb268ebe`
- **Observed merge:** PR 188 merged at 2026-10-04T23:47:08Z
- **Reference clip/time:** A@00:05 frontage/entrance, A@00:25 atrium, A@00:45 corridor/stairs, A@02:05 stairwell/quick slots; B@00:45 dealership browse/details; C@00:05-00:08 destination selection; recurring A/B/C compact right rail, top-right status and bottom slots
- **Acceptance criteria:** bind every Smoke result to exact canonical `5fd5c05`; require post-merge Foundation/Class/Progression guards; execute implemented spawn -> entrance -> atrium -> corridor/stairs -> class/free roam -> menus -> save/rejoin; keep rendered/device/traversal/live-rejoin states pending unless actually executed; reject Package while a required gate is absent
- **Output location:** `coordination/smoke/PR188_5FD5C05_POST_INTEGRATION_SMOKE_HOLD.md`
- **Blocker:** no independent QA authorization is bound to producer head `ab8dfa8`; the last QA verdict on `3cde55e` fails `PR188_MENU_INTERACTION_FLOW_GAP`; no post-merge push-guard evidence was available at observation time; no Roblox runtime or rendered device session was executed
- **Next handoff:** Control Tower reconciles the unexpected merged canonical and routes a bounded interaction repair through one producer, exact-head CI and independent QA; Integration then provides a compliant exact handoff; Smoke re-runs this oracle before Release/Package
- **Status:** `HOLD_EXACT_CANONICAL__TREE_EQUIVALENCE_ONLY__QA_AND_POST_MERGE_GUARDS_ABSENT__RUNTIME_RENDERED_DEVICE_PENDING`

No product source changes are made here. Static/source evidence is not a runtime, rendered, device, traversal or parity PASS.

## Exact live reconciliation

- `rebuild/high-school-foundation` resolves exactly to `5fd5c0539229b629eda865e574539990d6e17b5b`.
- Comparing producer head `ab8dfa8` to the merge commit is one commit ahead with no changed files. This proves tree equivalence only.
- Candidate pull-request guards previously passed on `ab8dfa8`:
  - Foundation `37244424637`
  - Class/Education `37244424628`
  - Progression `37244424662`
- PR 188 reviews available at observation time are bound only to `728d62b` and `3cde55e`; neither authorizes `ab8dfa8`.
- The `3cde55e` review explicitly records `FAIL_INTERACTION_SOURCE_CONTRACT` and withholds Integration.
- The live coordination WIP and Integration receipt remain stale for the new canonical and must not authorize Package.

Smoke decision: **do not issue a Smoke PASS and do not hand this canonical to Release/Package.**

## Real harness gap closed: feature-panel transaction oracle

The earlier Smoke plan says to open and close reachable panels, but it does not define an auditable transition result for simultaneous activation, denial, respawn and rejoin. Use the following oracle on the repaired exact canonical.

### Required captured state

For every transition record:

- exact canonical SHA;
- viewport, safe insets and input mode;
- `activeFeaturePanel` identity or `NONE`;
- visibility of Shop, Travel, Avatar, House, class/activity, Cafe and Vehicle surfaces;
- `CompactSchoolStatus`, `RHS2ActionRail` and `RHS2QuickBar` rectangles;
- server request name and count;
- spend/currency delta;
- player root and camera transform;
- result after one rendered frame and after response/denial.

### Transition matrix

| Start | Action | Required result |
| --- | --- | --- |
| NONE | Open Shop | Shop alone becomes active; no purchase or currency change |
| Shop | Open Travel | Travel replaces Shop; no direct travel request before destination confirmation |
| Travel | Back/Close | NONE; compact HUD returns to the current profile oracle |
| NONE | Open Avatar | Existing outfit surface becomes the sole active feature surface |
| Avatar | Open House | House replaces Avatar without remounting or duplicating outfit persistence |
| Any panel | Repeat same open | Idempotent; one panel instance and no duplicate listeners |
| Any panel | Server denial/unavailable backing UI | NONE or documented prior safe state; no stuck overlay, spend or movement lock |
| Any panel | Character respawn | Panel state clears or restores deterministically; compact HUD rebinds once |
| Any panel | CurrentCamera replacement | Geometry follows the new camera within one rendered frame; old-camera viewport changes have no effect |
| NONE | QuickSlot1..4 activate | Deterministic existing action only; empty/unavailable slot is neutral and creates no item, equip, spend or persistence semantics |
| Committed supported state | Leave/rejoin | Only committed state restores; feature panel starts in the documented neutral state; HUD remounts once |

A failure in any row is `FAIL_RUNTIME_EXACT_CANONICAL`. A source-only observation may block execution, but it cannot be promoted to a runtime result.

## Ordered Smoke execution

1. Require all three post-merge push guards on exact `5fd5c05`.
2. Require Control Tower to identify the same-SHA QA and Integration handoff chain. If absent, remain HOLD.
3. Start a clean client and record desktop 909x483, iPhone landscape 852x393 and iPad landscape 1024x768 rectangles using the PR 198 one-pixel rounding tolerance.
4. Capture comparable-FOV checkpoints at A@00:05, A@00:25, A@00:45 and A@02:05; record FOV and transforms. Do not infer movement speed from 2x playback.
5. Traverse spawn -> entrance -> both atrium circulation arcs -> corridor stairs up/down -> implemented class/free roam. Record first blocking instance and transforms for any stall, snag, fall-through or camera occlusion.
6. Execute every row in the feature-panel transaction matrix at desktop, then the interaction-critical rows on iPhone and iPad with actual Roblox movement/jump/gesture bounds.
7. Replace `Workspace.CurrentCamera`, resize the new camera, then mutate the old camera viewport to prove stale-listener disconnection.
8. Commit one supported durable state, return to free roam, leave and rejoin. Keep live DataStore rejoin pending unless an isolated runtime session actually executes it.
9. Store captures and a machine-readable result keyed to `5fd5c05`. Any canonical change invalidates the result.
10. Hand to Release/Package only after `PASS_RUNTIME_AND_RENDERED_DEVICE_EXACT_HEAD`, or an explicitly scoped package policy that preserves every unexecuted rendered/device gate as pending.

## Current result classification

- Tree identity: **PASS_TREE_EQUIVALENCE_ONLY**
- Candidate pull-request static guards: **PASS on `ab8dfa8`**
- Post-merge exact canonical guards: **PENDING/UNOBSERVED**
- Independent QA on `ab8dfa8`: **ABSENT**
- Interaction source contract: **OPEN FAIL from last reviewed head; no repaired delta exists**
- Runtime route/panels/camera: **PENDING**
- Rendered timestamp comparison: **PENDING**
- Physical traversal: **PENDING**
- iPhone/iPad obstruction and safe-area checks: **PENDING**
- Save/rejoin/DataStore: **PENDING**
- Smoke: **HOLD**
- Release/Package eligibility: **BLOCKED**
