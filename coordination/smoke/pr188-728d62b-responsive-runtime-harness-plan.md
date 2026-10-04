# PR 188 exact-head responsive runtime smoke harness plan

## Artifact contract

- **Owner:** Roblox High School Integration Smoke
- **Input candidate SHA:** `728d62b909bf8d8b7bd9d0466f3fb18c80ebb895` (PR 188)
- **Current integrated canonical SHA:** `43230492964ea637f69747e25a3e72d6cb268ebe`
- **Reference clips/times:** A@00:05 frontage/entrance, A@00:25 atrium, A@00:45 corridor/stairs, A@02:05 stairwell/item slots, and the compact right rail/top-right status/bottom slots recurring across A/B/C
- **Acceptance criteria:** execute only after Integration hands Smoke the exact canonical derived from independently approved PR 188 head; prove responsive runtime geometry, camera listener rebinding, modal restoration, traversal, and save/rejoin as implemented; retain rendered/device comparison as pending until actual captures exist
- **Output location:** `coordination/smoke/pr188-728d62b-responsive-runtime-harness-plan.md`
- **Blocker:** PR 188 exact head has green static CI but no independent QA approval and has not been integrated; Roblox runtime, physical traversal, target-device rendering, touch obstruction, and live DataStore rejoin are not executed
- **Next handoff:** independent QA approves an exact PR 188 head; Integration integrates only that same SHA; Smoke executes this contract on the resulting exact canonical and hands the exact result to Release/Package
- **Status:** `BLOCKED_ON_EXACT_HEAD_QA_AND_INTEGRATION__RENDERED_DEVICE_PENDING`

No product source is changed by this artifact. Headless/static evidence is not visual parity.

## Live gate snapshot

| Gate | Exact evidence | State |
| --- | --- | --- |
| Producer | PR 188 head `728d62b909bf8d8b7bd9d0466f3fb18c80ebb895` | Open and mergeable |
| Foundation guard | run `37237332258` | PASS |
| Class/Education guard | run `37237332337` | PASS |
| Progression guard | run `37237332270` | PASS |
| Independent QA | no review/receipt bound to `728d62b` | BLOCKED |
| Integration | canonical remains `43230492964ea637f69747e25a3e72d6cb268ebe` | NOT STARTED |
| Smoke | requires exact integrated canonical | BLOCKED |

The earlier QA evidence for `3aad19e` is stale for downstream authorization because PR 188 changed.

## Coverage gap closed by this plan

The prior P1 smoke plan names viewport and obstruction captures, but PR 188 now adds a `Workspace.CurrentCamera` replacement listener plus a per-camera `ViewportSize` listener. It did not pin:

1. exact expected group rectangles for the three deterministic profiles;
2. the rebinding sequence when `CurrentCamera` changes;
3. proof that the old camera listener is disconnected;
4. geometry restoration after menus/modals close;
5. a concrete runtime mismatch record tied to one exact canonical.

This plan supplies those oracles and execution steps. Execution remains pending.

## Exact geometry oracle

Read actual `AbsolutePosition` and `AbsoluteSize` from:

- `PlayerGui.RobloxHighSchoolLegacyUI.CompactSchoolStatus`
- `PlayerGui.RobloxHighSchoolLegacyUI.RHS2ActionRail`
- `PlayerGui.RobloxHighSchoolLegacyUI.RHS2QuickBar`

The expected rectangles below are derived from candidate `ResponsiveHudLayout.compute`. Allow at most one pixel of engine rounding for half-pixel horizontal centering; do not widen tolerance to hide a mismatch.

| Profile | Insets L/T/R/B | Status x/y/w/h | Rail x/y/w/h | Quick x/y/w/h |
| --- | --- | --- | --- | --- |
| desktop 909x483 | 0/0/0/0 | 728/6/118/71 | 854/91/49/212 | 329.5/421/250/56 |
| iPhone landscape 852x393 | 47/0/47/21 | 627/6/118/70 | 753/84/46/176 | 309/318/234/48 |
| iPad landscape 1024x768 | 24/0/24/20 | 794/9/133/86 | 936/145/55/230 | 386/681/252/58 |

For touch profiles, also capture actual Roblox movement/jump/gesture bounds. The candidate’s declared exclusion zones are only a deterministic approximation; an actual control overlap is a runtime FAIL even when the static contract passes.

## Ordered post-integration runtime harness

1. Confirm the live canonical SHA exactly equals Integration’s handoff SHA and that all push guards passed on that SHA.
2. Start a clean client and record the three HUD rectangles, viewport, safe insets, FOV, camera transform, orientation, and touch-control bounds.
3. At each profile, wait one rendered frame after the camera viewport settles; compare actual rectangles to the table and capture menu-closed frames at A@00:05, A@00:25, A@00:45, and A@02:05 checkpoints.
4. Resize iPhone -> iPad -> desktop -> iPhone in one session. Each transition must update all three groups within one rendered frame, remain inside the actual safe area, and avoid mutual/control overlap.
5. Replace `Workspace.CurrentCamera` with a new camera, then change the new camera viewport. All three groups must follow the new camera within one rendered frame.
6. After rebinding, change only the old camera viewport. HUD rectangles must remain unchanged. Any movement proves a stale listener and is a smoke FAIL.
7. Open and close each implemented class/activity modal and Shop, Avatar, House, Travel, cafe, and vehicle panel that is reachable on the exact canonical. After every close, the three compact groups must be visible, return to the current profile oracle, and leave the central traversal sightline unobstructed.
8. Traverse spawn -> entrance -> atrium -> corridor/stairs -> class/free roam. Record collision stalls, camera occlusion, decorative-step snagging, and checkpoint transforms; do not infer movement timing from 2x reference segments.
9. Commit one implemented progression result, leave to free roam, and rejoin. Confirm committed state restoration and responsive HUD remount. Mark live DataStore rejoin pending unless an actual isolated Roblox runtime test executes it.
10. Store captures and a machine-readable result keyed by exact canonical SHA; a changed canonical invalidates the execution.

## Result classification

- `PASS_CLOUD_SAFE_EXACT_HEAD_WITH_RENDERED_PENDING`: only static/headless checks ran.
- `PASS_RUNTIME_EXACT_HEAD__RENDERED_DEVICE_PENDING`: runtime flow ran, but target-device timestamp captures or obstruction evidence is incomplete.
- `PASS_RUNTIME_AND_RENDERED_DEVICE_EXACT_HEAD`: all ordered steps and actual desktop/iPhone/iPad captures pass on one exact canonical.
- `FAIL_RUNTIME_EXACT_HEAD`: any oracle mismatch, stale-camera response, panel restoration failure, traversal block, authority regression, or save/rejoin failure.

Never convert a headless pass into a rendered/device pass.
