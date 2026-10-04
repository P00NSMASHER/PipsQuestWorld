# PR 188 exact-head Integration hold and menu-flow seam inventory

## Artifact contract

- **Owner:** Roblox High School Integration Director
- **Live candidate SHA:** `ab8dfa8c8c19a4eca47a196a447ea7652dd35ccf` (PR 188)
- **Last independently reviewed SHA:** `3cde55e5a40f24dd2386b8b78757992f6d32bfb3`
- **Canonical base SHA:** `43230492964ea637f69747e25a3e72d6cb268ebe`
- **Reference clip/time:** A/B/C recurring HUD and bottom slots; C@00:05–00:08 Travel panel; B@00:45 dealership browse/details; A@00:45 and A@02:05 preserved world/stair references
- **Acceptance criteria:** integrate only one exact PR 188 SHA with all three green guards and independent QA authorization bound to that same SHA; preserve the repaired world/HUD contracts, unique server authorities, read-only client state, and all existing gates
- **Output location:** `coordination/integration/PR188_AB8DFA8_QA_HOLD_AND_MENU_SEAMS.md`
- **Blocker:** live head `ab8dfa8` has all three green guards but no independent QA verdict; the last exact-head QA verdict on `3cde55e` explicitly fails `PR188_MENU_INTERACTION_FLOW_GAP` and does not authorize Integration
- **Next handoff:** Pip High Free Roam repairs the interaction flow on the existing producer PR only, then changed-head CI, independent same-SHA QA, protected Integration, and immediate Smoke handoff
- **Status:** `HOLD__LIVE_HEAD_UNREVIEWED__PRIOR_HEAD_INTERACTION_SOURCE_FAIL__NO_PRODUCT_MERGE`

No product file is created or changed by Integration. Exact RHS2 parity is not claimed.

## Live gate snapshot

- Live PR 188 is open and mergeable at `ab8dfa8c8c19a4eca47a196a447ea7652dd35ccf`.
- Canonical remains `43230492964ea637f69747e25a3e72d6cb268ebe`.
- Live exact-head workflows all succeeded:
  - Foundation `37244424637`;
  - Class/Education `37244424628`;
  - Progression `37244424662`.
- Independent QA review on `3cde55e` returned:
  `PASS_WORLD_HUD_STATIC_EXACT_HEAD__FAIL_INTERACTION_SOURCE_CONTRACT__HOLD_RENDERED_VISUAL_TRAVERSAL_DEVICE`.
- That review assigns `PR188_MENU_INTERACTION_FLOW_GAP` only to Pip High Free Roam and explicitly withholds Integration.
- No QA review is bound to current `ab8dfa8`.

Integration decision: **do not merge PR 188**.

## Changed-head reconciliation

Compared with reviewed `3cde55e`, live `ab8dfa8` is four commits ahead, zero behind. Its net delta is limited to four responsive-HUD files:

| Path | Net delta | Integration interpretation |
| --- | ---: | --- |
| `school/src/client/CanonicalSchoolClient.client.lua` | +4/-18 | delegates touch exclusion geometry to the shared layout helper |
| `school/src/shared/ResponsiveHudLayout.lua` | +18/-0 | adds pure `touchExclusionZones` geometry |
| `school/tests/legacy_hud_contract_spec.lua` | +5/-0 | binds frame placement to validated layout coordinates |
| `school/tests/responsive_hud_layout_spec.lua` | +29/-17 | strengthens safe-inset, normalized-zone, slot and rail bounds |

This delta preserves and tightens the responsive static contract. It does **not** repair the independently reported interaction-source defect:

- `QuickSlot1..4` are still created as `TextLabel`;
- Shop still consumes only a server confirmation and does not present a browse/details/close-back flow;
- Travel still directly invokes `RequestTravel` instead of first presenting a destination panel;
- Avatar directly toggles the external outfit panel;
- House, Avatar, Shop, Travel, Cafe, Vehicle and class/activity surfaces have no shared one-active-feature-panel controller;
- repeat-open idempotency, explicit close/back, denial restoration and respawn restoration are not yet established by exact source.

The green guards therefore prove only their present static contracts. They do not override the same-SHA QA requirement.

## Protected repair seams

The next product write remains solely on the existing Free Roam producer branch. Integration expects the smallest interaction repair consistent with QA:

1. **Client orchestration seam**
   - Primary path: `school/src/client/CanonicalSchoolClient.client.lua`.
   - Introduce one explicit active-feature-panel state/controller.
   - Route Shop, Avatar, Travel and House activation through that controller.
   - Provide explicit close/back and repeat-open idempotency.
   - Restore neutral state after denial, respawn, panel destruction or unavailable backing UI.
   - Preserve class/activity, vehicle, cafe, housing-editor and job input ownership.

2. **Pure helper seam, only if needed**
   - A new or existing shared helper may model panel-state transitions, but it must remain deterministic and client-only.
   - If a new shared module is mapped, `school/default.project.json` may change only for that mapping.
   - Do not introduce a second client runtime root.

3. **Static contract seam**
   - Extend `school/tests/legacy_hud_contract_spec.lua` for controller routing, close/back, repeat-open idempotency, denial/respawn restoration and quick-slot activation type.
   - Add a focused pure state-machine spec only if a shared helper is introduced.
   - Preserve the exact responsive geometry checks already green at `ab8dfa8`.

4. **Authority boundary**
   - Do not add or rename server remotes.
   - Do not move travel, shopping, outfit, housing, class, vehicle, cafe, job, economy, progression or persistence authority to the client.
   - Do not add automatic spending.
   - Do not invent destination tiles, item semantics, prices, icon meanings or backend delivery behavior not supported by the reference evidence and existing server contract.

## Collision and conflict inventory

### Responsive HUD changes at ab8dfa8

The interaction repair must retain:

- `ResponsiveHudLayout.touchExclusionZones(viewport, insets)`;
- client delegation to that helper;
- status, rail and quick-bar placement from validated layout coordinates;
- top/bottom/left/right safe-inset coverage;
- normalized desktop/iPhone/iPad touch-zone assertions;
- rail-button and quick-slot bounds;
- existing negative overlap guards.

A repair that reintroduces inline exclusion rectangles, fixed status geometry or literal unvalidated positions is a regression even if menu tests pass.

### Existing UI surfaces

The controller must interoperate with existing separately owned surfaces:

- class/activity modal and class action;
- vehicle/Auto Shop card and input;
- cafe card and actions;
- legacy housing panel and Housing Editor V2;
- external outfit panel located through `Outfits`, `OutfitsMobile` or `OutfitsConsole`.

It must not destroy, remount or become a durability writer for those systems.

### Quick slots

The reference proves visible bottom item slots, not item semantics. Converting the slots to activatable controls is acceptable only if:

- activation is deterministic and read-only unless an existing server contract already defines an action;
- no item grant, equip, spend or inventory persistence is invented;
- empty/unavailable activation restores a neutral UI state;
- the four-slot layout and responsive bounds remain unchanged.

### Travel

The reference proves a destination-selection panel before travel. The repair may present evidence-backed selection UI, but the actual transition must still use the existing server-owned `RequestTravel` boundary. A client-side teleport or guessed destination catalog is forbidden.

### Shop and avatar

The reference proves browse/details-style presentation, not a new purchasing authority. Shop may open an evidence-backed panel while purchase remains server-owned. Avatar may coordinate the existing outfit panel, but must not duplicate its persistence or inventory ownership.

## Exact ordered handoff

1. Free Roam returns a changed PR 188 head that actually repairs `PR188_MENU_INTERACTION_FLOW_GAP`.
2. All three workflows must complete successfully on that exact SHA.
3. Independent QA must bind its verdict to that exact SHA and explicitly authorize Integration.
4. Integration rechecks:
   - PR head identity and mergeability;
   - canonical base identity;
   - exact workflow run conclusions;
   - QA verdict SHA;
   - changed-path scope;
   - responsive-HUD preservation;
   - unique authority and no automatic spend.
5. Only then merge mechanically with `expected_head_sha`.
6. Fetch the new canonical commit and verify all post-merge guards.
7. Hand the exact integrated canonical SHA immediately to Roblox High School Integration Smoke.
8. Smoke keeps rendered, traversal, touch/device, panel-restoration and save/rejoin states separate from headless/static results.

Until step 3 is satisfied, Integration remains blocked and PR 188 must remain open.
