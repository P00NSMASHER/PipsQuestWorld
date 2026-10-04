# RHS2 travel interaction contract

Owner: Pip High Free Roam (contract preparation only; no product-write authority in this artifact).
Input product SHA: `43230492964ea637f69747e25a3e72d6cb268ebe`.
Coordination base: `452f83ecfea1826974c92b048cf7bb0e968bcf25`.
Reference clip/time: C (`libfile_a5903480efe88191a87e5f98ec9729bc`) at approximately 00:04-00:10, plus the recurring A/B/C compact HUD.
Output location: `coordination/reference/rhs2-travel-interaction-6fe2541/HANDOFF.md`.
Blocker: PR #170 QA and Integration are complete; all three exact-canonical push guards pass on `43230492964ea637f69747e25a3e72d6cb268ebe`. Smoke passed on that exact canonical SHA (PR #181 / receipt schema 15; rendered/device evidence remains pending), and Release & Package is active next. P1 implementation still waits for deterministic Package and Control Tower activation before any `school/**` implementation.
Next handoff: Release & Package completes deterministic packaging on exact canonical `43230492964ea637f69747e25a3e72d6cb268ebe`; Control Tower then activates the reserved P1 producer; Pip High Free Roam implements only after activation; Roblox High School QA & Contract validates the exact candidate independently.

This is an observable interaction contract from footage, not proof of hidden source, remotes, destination IDs, teleport backend, asset IDs, or timing. The visible recording is at 2x in parts, so this artifact makes no movement-speed, transition-duration, or animation-timing claim.

## Observable surface

- The Travel control is part of the compact colored right-side rail and opens one centered dark-blue panel over the still-visible world.
- The panel has a bright blue `Travel` title strip, a top-right close control, and two visible top tabs: `Locations` and `Servers`.
- `Locations` is the active yellow-highlighted tab in the sampled frames. The location browser is a scrollable image-tile grid rather than a permanent full-screen map.
- Readable tile labels in the sampled scroll states include `Food District`, `Beach`, `Skate Park`, `Neighborhood`, `Outskirts`, `Forest`, `Campsite`, `Lake`, `Club Red`, `Sunblox Cafe`, `Chef Umbra's`, and `Maisy's Mystical Dining`.
- The compact balances/status stack, right rail, and bottom controls remain visible around the modal. Sample player nameplate text and balances are user/session state, not fixed product copy.
- The footage demonstrates opening, browsing/scroll state, tab affordances, and closing presentation. It does not establish what every tile does, server-list semantics, eligibility rules, destination coordinates, transition effects, failure copy, or backend authority.

## Implementation contract after activation

1. Route the existing Travel action into the compact rail without creating another travel, spawn, economy, progression, or persistence authority.
2. Mount at most one travel panel. Repeated activation focuses/toggles the same panel; close/cancel destroys no state and performs no travel.
3. Preserve the two observed top tabs and the scrollable visual-card hierarchy. Populate cards only from verified project data; unknown thumbnails, destinations, ordering, and server fields remain explicit gaps rather than invented constants.
4. Browsing, scrolling, changing tabs, or closing must never mutate position, balances, inventory, progression, or saved data.
5. A destination choice, when separately authorized by existing product contracts, submits only a stable destination key. The server-owned location/spawn authority resolves and validates the target; the client must not submit or author arbitrary CFrame/position data.
6. Unknown, unavailable, malformed, duplicate, or stale selections fail closed and leave the player at the current valid location. No fallback to an unverified destination.
7. Keep the world readable behind the panel and retain access to close, balances/status, and touch-safe system controls. Do not allow the panel to collide with the right rail, bottom items, Roblox inset, phone movement/jump controls, LegacyVehiclePanel, or LegacyCafePanel.
8. Preserve existing class travel, bell transition, active-class exit, pending-save feedback, and save/rejoin authority. Presentation work must not redirect those flows through a new writer.
9. Do not copy sample player names, sample balances, or player-authored biography text. Do not infer original transition timing from the 2x footage.

## Acceptance criteria

- Reference-matched capture shows the compact rail opening one centered Travel panel with title, close control, `Locations`/`Servers` tabs, and image-tile browsing while the world remains visible.
- Desktop and phone-landscape captures show safe insets and no collision with balances/status, bottom controls, movement/jump controls, vehicle panel, or cafe panel.
- Deterministic tests prove single-instance mount/toggle, close-without-side-effects, scroll/tab state isolation, stable-key requests only, fail-closed unknown selections, and no duplicate authority or persistence writer.
- Existing travel/class transition tests remain green; all three repository guards bind to the exact candidate head.
- Independent QA verifies the exact head before Integration. Smoke and Package bind to the integrated canonical SHA.
- Rendered/runtime comparison on the target device is required. Static tests cannot certify appearance, feel, destination execution, or server-browser parity.

## Explicit unknowns

- Exact location-card order outside the sampled scroll states.
- Exact thumbnails, destination IDs, coordinates, loading/transition treatment, eligibility gates, prices, and error copy.
- `Servers` tab contents and join semantics.
- Whether every readable card is available in every session.
- Original-speed interaction and animation timing.

No `school/**` source was changed. This contract does not activate a second producer, alter PR #170, publish Roblox, authorize spending, or claim parity.
