# Mobile UX Status

Status: **READY_STATIC / LOCAL_ONLY_REQUIRED**

Base implementation: `feat/school-life-pivot` at `883fa92583e58791443798330d8b61d22807df62`
Tested implementation commit: `117fcf4aba37e745b92504d0d66319670ac6008b`

## Objective

Prevent the active class question interface from behaving like a full-screen worksheet on iPhone-sized landscape screens while preserving Roblox movement/jump/menu space.

## Change

- Class activity UI remains hidden except during an active class encounter.
- Modal is capped at 410x254 and moved upward to leave the lower control strip clear.
- Four-answer questions use a compact 2x2 grid.
- Answer targets are 48 px tall and wrapped for short/medium choice text.
- No persistent HUD, schedule, progression, server, or world behavior changed.

## Static viewport evidence

- iPhone 16 landscape 852x393: card 410x254, left/right clearance 221 px, top clearance ~38 px, bottom clearance ~101 px.
- Narrow fallback 667x375: card 410x254, left/right clearance ~129 px, top clearance ~31 px, bottom clearance ~91 px.
- Responsive guard: `scripts/verify-school-mobile-layout.py`.
- Headless static check for the tested implementation commit: **PASS**.
- Roblox core controls are not disabled or rebound by this change.

## Remaining blocker

`LOCAL_ONLY_REQUIRED`: fresh target-device runtime evidence is still required to confirm Roblox's actual device inset, camera-drag behavior, and joystick/jump coexistence on the exact candidate. Defer and batch that check; do not poll or foreground the user's machine.
