# RHS2 housing interaction contract

Owner: Pip High Free Roam (contract preparation only; no product-write authority in this artifact).
Input product SHA: `43230492964ea637f69747e25a3e72d6cb268ebe`.
Coordination evidence branch input: `56e8261086fda4f3ccc0960578e185ad9cdcd32a`.
Reference clip/time: B (`libfile_427a25a0e78881919c3128e193b9df4d`) at approximately 00:14-00:35 for neighborhood approach/doorway/interior and 00:48-00:58 for the `Buy House` browser, plus the recurring compact HUD.
Output location: `coordination/reference/rhs2-housing-interaction-4323049/HANDOFF.md`.
Blocker: exact canonical `4323049` still requires Smoke PASS and deterministic Package, followed by a fresh Control Tower producer activation. P1_SPAWN_SCHOOL_HUD remains ahead of housing implementation.
Next handoff: Control Tower keeps this as future Free Roam evidence; Pip High Free Roam implements only when explicitly activated; Roblox High School QA & Contract validates the exact candidate independently.

This records observable presentation and bounded behavior from footage. It does not prove hidden source, catalog IDs, ownership rules, plot allocation, purchase remotes, currency backend, destination coordinates, or save semantics. Visible 2x playback prevents an original-speed transition-duration claim.

## Observable surface

- The player traverses a low-density neighborhood with detached homes and readable streets, approaches a house, passes through a brief dark transition, and appears inside a furnished interior with a bedroom-like room and kitchen.
- The sampled entry flow shows doorway-to-interior continuity, but not the exact door prompt, eligibility rule, loading implementation, spawn coordinate, or whether the property is owned by the player.
- A centered dark-blue `Buy House` panel appears over the still-visible exterior world. It has a bright-blue title strip, a back arrow, a close control, a dotted blue grid background, and eight image cards arranged in three columns.
- The compact balances/status stack, right-side icon rail, and bottom controls remain visible around the panel. The visible `House` rail action is consistent with this surface, but the exact opening tap is not established by the sampled frames.
- Visible reference cards and displayed prices/currencies are:
  - `Cozy Cottage` — 950 coins
  - `Nature Lodge` — 2,500 coins
  - `Farmhouse` — 5,000 coins
  - `Ranch Retreat` — 9,500 coins
  - `Family 2 Story Home` — 35,000 coins
  - `Getaway Chateau` — 6,000 gems
  - `Modern Abode` — 9,500 gems
  - `Exotic Manor` — 15,000 gems
- The footage does not show a confirmation step, completed purchase, debit, duplicate purchase, ownership badge, equipped/current-home state, plot claim, editor launch, save/rejoin, insufficient-funds response, or failure copy. The displayed values are visual evidence, not proof of current project catalog authority.

## Implementation contract after activation

1. Route the compact `House` rail action into the existing housing presentation without creating another housing, plot, economy, progression, or persistence writer.
2. Mount at most one housing surface. Repeated activation focuses/toggles the same panel; back/close/browse has no economic, ownership, position, inventory, progression, or save side effect.
3. Preserve the observed title/back/close hierarchy and three-column visual-card grid. Use only verified project catalog entries and authorized thumbnails; unavailable cards remain explicit gaps rather than invented IDs.
4. A buy/select request submits only a stable server-known house key and idempotency token. The server-owned housing/economy authorities resolve price, currency, availability, prior ownership, plot eligibility, and the resulting action.
5. The client must not author price, currency, balance, ownership, debit success, plot identity, doorway identity, or destination CFrame. Unknown, stale, unavailable, conflicting, or duplicate requests fail closed.
6. A confirmed purchase/debit is exactly once. Retry and duplicate confirmation cannot charge twice, grant twice, allocate multiple plots, or fork save state.
7. Opening or previewing a card never purchases. If confirmation UI is implemented, cancel performs no debit or state change and success copy is emitted only from a server-confirmed result.
8. Doorway/interior entry uses an existing server-approved property/door destination and preserves current ownership/access rules. The client cannot teleport to an arbitrary coordinate or another player's protected property.
9. Preserve the existing house editor, furniture/save state, plot assignment, rejoin restoration, pending-save feedback, and unique persistence owner. Presentation work must not fork these paths.
10. Keep the world readable behind the panel and avoid collisions with the right rail, balances/status, bottom items, Roblox inset, phone movement/jump controls, LegacyVehiclePanel, and LegacyCafePanel.
11. If a transition veil is used for doorway entry, it may reflect the observed brief dark handoff but must be driven by actual readiness and accessibility; do not copy a duration from the 2x footage.

## Acceptance criteria

- Reference-matched capture shows one `Buy House` panel with title/back/close, eight verified image cards, mixed coin/gem badges, and the recurring HUD still readable around it.
- Desktop and phone-landscape captures show safe insets, readable card labels/prices, reachable close/back, and no collision with balances, rail, bottom controls, movement/jump controls, vehicle panel, or cafe panel.
- Deterministic tests prove single-instance mount/toggle, browse/cancel without side effects, stable-key-only requests, server-owned price/currency/ownership, exact-once debit/grant, fail-closed unknown/stale requests, duplicate isolation, and no second persistence writer.
- Runtime tests cover allowed and denied doorway entry, valid interior spawn, no fall-through/stuck geometry, exit continuity, editor reachability, save/rejoin restoration, and another-player isolation.
- Existing housing/economy/progression guards remain green; all three repository guards bind to the exact candidate head.
- Independent QA validates the exact head before Integration. Smoke and Package bind to the integrated canonical SHA.
- Rendered/device comparison is mandatory before claiming appearance, feel, purchase flow, or doorway parity.

## Explicit unknowns

- Exact house catalog identity, ordering, thumbnails, and price/currency values in the current Pip High implementation.
- Confirmation UI, ownership/current-home badges, insufficient-funds copy, eligibility rules, and purchase success presentation.
- Door prompt/hierarchy, plot-selection rules, loading mechanism, interior spawn points, and transition timing.
- Whether all eight reference cards are available in every session or progression state.
- Exact interior floor plan, furniture catalog, editor hierarchy, and persistence contract beyond existing verified project behavior.

No `school/**` source was changed. This contract does not activate a second producer, alter canonical `4323049`, publish Roblox, spend currency, or claim parity.
