# PR 188 exact-head integration readiness — 728d62b

- **Owner:** Roblox High School Integration Director
- **Product candidate:** PR #188, `rebuild/high-school-p1-spawn-school-hud-4323049-v1`
- **Exact input SHA:** `728d62b909bf8d8b7bd9d0466f3fb18c80ebb895`
- **Exact base/canonical SHA:** `43230492964ea637f69747e25a3e72d6cb268ebe`
- **Reference clip/time:** A@00:05 school frontage, A@00:25 atrium, A@00:45 corridor/stair, A@02:05 item rail; recurring A/B/C compact HUD
- **Status:** `BLOCKED_NO_INDEPENDENT_QA_ON_EXACT_728d62b__DO_NOT_INTEGRATE`
- **Output location:** this file
- **Blocker:** the latest independent QA receipt is bound to superseded head `3aad19e`; no QA review/receipt authorizes `728d62b`. Rendered desktop/iPhone/iPad comparison, physical traversal and panel restoration also remain pending.
- **Next handoff:** Roblox High School QA & Contract reviews only `728d62b`; Integration may proceed only if that same SHA is explicitly authorized.

## Exact changed-head evidence

PR #188 moved six commits from QA-bound `3aad19ea4e3a47753307c8f9d8422f55cbba082a` to responsive-layout repair head `76c814434506051175c75c0c3ffed677352c8077`, then one test-only commit to current head `728d62b909bf8d8b7bd9d0466f3fb18c80ebb895`.

The first responsive repair head failed Progression run `37237233091` in `school/tests/responsive_hud_layout_spec.lua:102`: the status/rail mutation expected `status overlaps rail`, but its oversized mutated status left the safe bounds first. Current head changes only that mutation fixture to use the rail rectangle, so the intended overlap branch is exercised without creating an earlier containment failure.

Exact current-head PR workflows:

| Workflow | Run | Result |
|---|---:|---|
| High School Foundation Static Guards | 37237332258 | success |
| High School Class Education Guards | 37237332337 | success |
| High School Progression Guards | 37237332270 | success |

Green CI proves deterministic static contracts only. It does not substitute for exact-head independent QA or rendered/device/runtime evidence.

## Collision and conflict inventory

| Path | Canonical blob | Candidate blob | Integration seam / rejection rule |
|---|---|---|---|
| `school/default.project.json` | `ba5e85e82652f137cb17e76016f062731c033761` | `e7b6fc9755a62dc6e4ed1a24a3ce6e563d3c23ea` | Adds the single `ResponsiveHudLayout` shared mapping. Reject a second runtime root or a mapping collision. |
| `school/src/client/CanonicalSchoolClient.client.lua` | `86ef317f8cae9cd3ae0051fdc103e06fc3c6a55a` | `25ee0d9bd48516f107e53d2abca6535181e2f68b` | Shared monolithic client/HUD surface. Preserve server-owned class, travel, shopping, outfit, housing, cafe and vehicle boundaries; verify one HUD mount and viewport-listener lifecycle. |
| `school/src/server/CampusBuilder.server.lua` | `402bc78ab622464e2f6ee12cc737ad32b6e8143a` | `6655ea0dfabda98433b5cc08d4e68a45bbe9a80a` | Spawn/world geometry. Preserve exactly one `MainSpawn`, the repaired positive-volume AABB clearance, existing clock/location authority and all navigation seams. |
| `school/src/shared/ResponsiveHudLayout.lua` | absent | `0f4fb2c5d6d8ac58a7741567fe4738146d79cbeb` | New pure geometry module. It must remain state-free and must not become an economy/progression/persistence writer. |
| `school/tests/foundation_world_contract_spec.lua` | `bbf5f7ed9a8bcb55556e0280eb1690b9bed1634a` | `56d318708d04af9f13c5699df6a4bf3a624376d9` | Preserve one-spawn and collidable AABB assertions; never weaken to literal-only checks. |
| `school/tests/legacy_hud_contract_spec.lua` | `c5cf32c28b8bf0ef177fa0154767394d5cfd3544` | `5cb8c25b3df5e5a7411905fc76bd689d1741c91e` | Mounts the responsive contract in the existing Progression gate. Preserve avatar/shopping/housing/runtime authority checks. |
| `school/tests/responsive_hud_layout_spec.lua` | absent | `1a6dbd0aeead14eda46330bf083d943a36e5211e` | Covers nominal, iPhone-landscape and iPad-landscape safe bounds/exclusion zones plus adverse mutations. Current green head is required. |

## Runtime and rendered risks that remain open

1. `IgnoreGuiInset = true` plus `GuiService:GetGuiInset()` is now the client safe-area seam; target-device captures must prove the computed top/right/bottom placement is correct.
2. `Workspace.CurrentCamera` and `ViewportSize` drive reflow. QA/Smoke must verify initial mount, camera replacement, viewport resize and respawn do not leak or duplicate listeners/HUD roots.
3. The minimum status size is 118×70 with compressed text/action geometry. Rendered desktop/iPhone/iPad evidence must verify legibility, clipping and tap reachability.
4. The pure layout contract proves rectangle containment/overlap for declared fixtures; it does not prove Roblox control zones, modal stacking, panel close/dismiss restoration or physical world traversal.
5. The seven-path PR still changes both shared client startup and world/spawn geometry. A clean mechanical merge is insufficient without exact-head QA.

## Merge authorization checklist

Integration must stop if any item is false:

- PR #188 remains open at exact head `728d62b909bf8d8b7bd9d0466f3fb18c80ebb895`.
- Canonical remains exact base `43230492964ea637f69747e25a3e72d6cb268ebe`.
- All three PR workflows above remain successful on `728d62b`.
- Independent QA explicitly authorizes Integration on `728d62b`; receipts for `3aad19e`, `76c8144` or any other SHA are stale.
- The changed-path set remains exactly the seven paths inventoried above.
- Unique spawn, clock, location, economy, progression and persistence authorities remain intact.
- No rendered/device PASS is inferred from static contracts.

## Ordered handoff

1. Free Roam freezes `728d62b` and posts the exact-head CI handoff.
2. QA independently reviews `728d62b`, recording functional, visual, interaction and device statuses separately.
3. If and only if QA explicitly authorizes Integration on that SHA, Integration rechecks live head/base/CI/path inventory and performs the protected mechanical merge with expected-head enforcement.
4. Canonical push guards run on the resulting exact canonical SHA.
5. Integration hands that exact canonical SHA immediately to Smoke.
6. Smoke executes PR #189's route/camera/device/save-rejoin plan rebound to the new canonical; rendered tests stay pending where execution is unavailable.
7. Release & Package emits a deterministic package only after exact-canonical Smoke acceptance.
