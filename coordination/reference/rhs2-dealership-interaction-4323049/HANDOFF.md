# RHS2 dealership interaction contract

Owner: Pip High Free Roam (contract preparation only; no product-write authority in this artifact).
Input product SHA: `43230492964ea637f69747e25a3e72d6cb268ebe`.
Coordination evidence branch input: `dc4201733f2d7b64de45fdf6f84103d3a1e10d7e`.
Reference clip/time: B (`libfile_427a25a0e78881919c3128e193b9df4d`) at approximately 00:36-00:46, plus the recurring compact HUD before/after the dealership surface.
Output location: `coordination/reference/rhs2-dealership-interaction-4323049/HANDOFF.md`.
Blocker: deterministic Package must bind exact canonical `4323049`, Control Tower must activate P1_SPAWN_SCHOOL_HUD, and earlier priorities must clear before any dealership `school/**` implementation.
Next handoff: Control Tower keeps this as future Free Roam evidence; Pip High Free Roam implements only when explicitly activated; Roblox High School QA & Contract validates the exact candidate independently.

This is observable presentation evidence from footage. It does not prove hidden source, catalog IDs, purchase/spawn remotes, ownership rules, vehicle physics, skin application, backend currency semantics, or timing. Visible 2x playback prevents original-speed interaction or animation claims.

## Observable surface

- The dealership uses a large modal workspace that temporarily replaces/covers the ordinary compact right rail and bottom-item controls. Balances are repeated in a footer inside the dealership surface.
- The layout is split: a large left preview stage with the heading `Select an Item` and the instruction `Select an item to see more information about it!`, plus a dark-blue catalog panel on the right.
- The catalog header reads `Larry's Car Dealership`, includes the subtitle `Buy a new car here!`, and has a top-right close control.
- Top category tabs are `All`, `Vehicles`, and `Skins`; `Vehicles` is yellow-highlighted in the sampled frames. A search field and `Sort by: New` control are visible below the tabs.
- Selecting/hovering `RHS Fan Car` exposes an inline details card with `STANDARD`, `Vehicle`, `Top Speed: 60`, `Acceleration: 15`, progress-style stat bars, and fan-club unlock copy. This is visible reference copy, not proof of the current Pip High entitlement backend.
- Other readable cards and displayed price badges include:
  - `Trailblazer Truck` — 950 coins
  - `Limo` — 1,200 gems
  - `Minivan` — 1,500 coins
  - `Classic Car` — 4,500 coins
  - `Wildwind` — 6,000 gems
  - `Elite Sports Car` — 35,000 coins
  - `Robloxian Racecar` — 60,000 coins
  - `Blitzer`, `Electron`, and `SuperVelocita` — each displays 1,170 with a separate silver circular currency/token icon whose meaning is not established by the footage
- Two middle card identities are obscured by the selected details overlay in the sampled frame; their exact names, currency types, and prices remain unknown.
- The footage shows catalog browsing and details presentation. It does not show a completed purchase, confirmation, debit, ownership badge, vehicle spawn, drive behavior, skin purchase/application, insufficient-funds response, duplicate purchase, or failure copy.

## Implementation contract after activation

1. Route the dealership presentation through the existing vehicle/economy/ownership authorities; do not create another vehicle lifecycle, purchase, currency, progression, or persistence writer.
2. Mount at most one dealership surface. Open/close/category/search/sort/selection/preview has no economic, ownership, spawn, inventory, progression, or save side effect.
3. Preserve the observed split preview/catalog layout, title/subtitle/close hierarchy, three top tabs, search, sort, image-card grid, inline details card, and footer balances. Populate only verified project entries and authorized thumbnails.
4. The panel may temporarily suppress the compact free-roam rail and bottom items as observed, but close must restore the same HUD state without duplicate mounts or lost handlers.
5. A buy/unlock request submits only a stable server-known item key and idempotency token. The server-owned catalog resolves item class, price, currency, entitlement, prior ownership, eligibility, and result.
6. The client must not author price, currency, balance, ownership, entitlement success, stats, skin compatibility, vehicle model, spawn transform, or debit result. Unknown, stale, unavailable, conflicting, or duplicate requests fail closed.
7. Confirmed debit/grant is exactly once. Retry or duplicate confirmation cannot charge twice, grant twice, create multiple ownership records, or fork persistence.
8. Preview/selection never purchases or spawns. If confirmation is later supported, cancel changes nothing and success UI is emitted only from a server-confirmed result.
9. Vehicle spawning uses the existing server-authoritative lifecycle: owned catalog key, validated spawn point, one active vehicle per applicable policy, server-owned model/stats, and existing seat/driver/input validation. No client-supplied arbitrary model, speed, physics, or CFrame.
10. Skin selection validates server-known compatibility and ownership. Applying/browsing a skin cannot alter base vehicle ownership, price, stats, or persistence authority.
11. Search and sort are presentation state only. They cannot change prices, unlocks, result ordering authority, or hide a required failure state.
12. Preserve save/rejoin ownership restoration, balances, pending-save feedback, vehicle cleanup/respawn, player isolation, and all existing vehicle/economy guards.
13. Respect Roblox safe insets and phone landscape touch access. The large modal must not leave hidden active HUD buttons underneath, collide with system controls, or strand the player without a reachable close action.

## Acceptance criteria

- Reference-matched capture shows the split preview/catalog composition, `Larry's Car Dealership` header, close control, `All`/`Vehicles`/`Skins` tabs, search, `Sort by: New`, card grid, inline selected details, and footer balances.
- Closing restores the compact free-roam HUD exactly once. Reopening retains no duplicated handlers, stale details card, or phantom modal.
- Desktop and phone-landscape captures demonstrate readable cards/details, reachable tabs/search/sort/close, safe insets, and no accidental activation of hidden free-roam controls.
- Deterministic tests prove single-instance mount, browse/search/sort/preview without side effects, stable-key-only requests, server-owned price/currency/entitlement/ownership/stats, exact-once debit/grant, fail-closed unknown/stale requests, duplicate isolation, and no second persistence writer.
- Runtime tests prove authorized vehicle spawn, denied unowned/unknown spawn, validated spawn transform, active-vehicle cleanup policy, driver/seat/input authority, skin compatibility, another-player isolation, and save/rejoin ownership restoration.
- Existing vehicle/economy/progression guards remain green; all three repository guards bind to the exact candidate head.
- Independent QA validates the exact head before Integration. Smoke and Package bind to the integrated canonical SHA.
- Rendered/device comparison is mandatory before claiming appearance, feel, purchase, preview, spawn, driving, or skin parity.

## Explicit unknowns

- Exact current Pip High catalog IDs, thumbnails, ordering, prices, currency mapping, unlock rules, entitlement service, and availability.
- Identities/details of the two cards obscured by the selected reference overlay.
- Meaning of the silver 1,170 currency/token badge.
- Exact left-preview model/camera behavior, selection animation, purchase confirmation, success/failure copy, ownership badges, and skin workflow.
- Original-speed modal, preview, spawn, and driving timing.
- Exact vehicle physics and stats beyond the one visible RHS Fan Car reference card.

No `school/**` source was changed. This contract does not activate a second producer, alter canonical `4323049`, publish Roblox, spend currency, or claim parity.
