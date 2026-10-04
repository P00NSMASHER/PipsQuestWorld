# RHS2 first visual slice — implementation handoff

Owner: executive direction. Consumer: Pip High Free Roam, with Foundation and Progression/Mobile support.
Inspected product commit: 6fe254139ae3382f0ab71e6725df00c1c1a69822.
Coordination base: 15dc9ee27090065b3edd5ce8e272d49617730aac.
This document adds implementation evidence; it does not assign a second product writer or certify parity.

## Actual runtime entry points
school/default.project.json explicitly maps CampusBuilder.server.lua and CanonicalSchoolClient.client.lua.
SchoolHud.client.lua is NOT mapped. Editing that file alone will not change the running HUD.
Active client blob: 86ef317f8cae9cd3ae0051fdc103e06fc3c6a55a.
Preserve existing server remotes and callback behavior while changing presentation.

## Frame geometry and measured layout
Source A: libfile_94cb10b32d9c819186b9ad708b9d4736, 1112x512.
Frames directly inspected for this handoff: 00:05, 00:25, 00:45 and 02:05.
Approximate game viewport is x=101..1011, y=0..512; the dark side bars are recording framing, not game UI.
All measurements below are manual visual estimates, not source constants or pixel-exact acceptance limits. Recording coordinates include the Roblox top bar; convert through ScreenGui safe-area/inset handling rather than directly copying y values.

| Element | Recording bounds, approx px | Viewport interpretation |
| --- | --- | --- |
| Primary right rail | x958..1009, y119..331 | Four vertically stacked roughly 51px buttons, right-aligned |
| Rail labels/order | Shop, Avatar, House, Travel | Red, cyan, green, amber backgrounds |
| Secondary rail | x959..1008, y334..411 | Two columns of small buttons below Travel |
| Balances/status | x890..1008, y29..100 | Compact top-right stack, dark fields with colored borders |
| Bottom items | x459..709, y450..507 | Four separated controls centered near viewport bottom; semantics partly unknown |
| World view | remaining center/left | No permanent large school menu in these sampled frames |

Do not copy the sample balances (13,914 coins / 400 gems), player nameplate, weather/time values or player biography as fixed game data. Missing gem/weather services remain explicit data gaps; never fabricate balances or introduce another writer to fill the UI.

## Product gaps and narrow implementation route
1. CanonicalSchoolClient creates LegacySchoolMenu at bottom-left, 236x184. Move schedule/progression display into the compact HUD; expose class details/actions on demand while retaining pending-save feedback, travel, class exit and answer handling.
2. Move existing House and outfit actions into the right rail while preserving their current handlers. LegacyOutfitEntry creates a separate ScreenGui and exposes no controller return; use a small presentation adapter or explicit existing-button lookup rather than assuming the mount call returns a handle. Keep all available actions reachable by touch and keyboard.
3. Do not assume the four bottom controls are four inventory slots. A02:05 shows a numbered tool popup above the second dark control; the other controls resemble bag/phone shortcuts, with behavior not established by these frames. Preserve verified functionality and record unknown actions explicitly.
4. Existing CampusBuilder entrance uses a flat FrontPlaza, EntryWalk, EntryCanopy and three noncolliding glass doors. Replace the entrance composition as one coherent geometry change: broad stairs, symmetrical planted approach, blue facade, red framing, white canopy and prominent crest to the right of the entrance, as seen at A00:05.
5. Current FrontLobbyFloor is 54x32 with a front desk and trophy case. A00:25 shows a broad bright open atrium, low round central display with red/white/blue illuminated tiers, pale floor, perimeter red/blue wall bands, bright ceiling strips, red/blue bunting and clear circulation on both sides.
6. Central display decorations in the footage may be seasonal/user content. Prioritize permanent architectural silhouette and circulation; record exact prop assets as unknown rather than guessing IDs.
7. Reuse the existing room registry and spawn owner. Changing floor elevation requires checking spawn clearance, room connectors, stair risers/landings and door headers together. Do not leave the old flat geometry intersecting the replacement.

## Completion evidence for this slice
- Pin the post-package canonical base at activation; current inspected SHA is evidence, not permission to skip Smoke/Package.
- Capture entrance from across the approach, atrium from entry, corridor/stairs and free-roam HUD at comparable camera angle and field of view.
- Compare against cropped game viewport, excluding recording bars and creator overlay.
- Verify a walk from spawn through entrance and around both sides of the display into the existing corridor; no stuck steps, collision barriers or falling through streaming boundaries.
- Check desktop and phone landscape layouts. Proposed engineering requirement: touch controls remain usable and do not overlap movement/jump or Roblox system controls; this is not a dimension inferred from the desktop footage.
- Open/close House, Avatar and class detail surfaces; preserve server-authoritative data and existing actions.
- Check active vehicle and cafe states: existing LegacyVehiclePanel (bottom-center) and LegacyCafePanel (bottom-right) can overlap the new bottom controls/right rail. Preserve actions while resolving layout conflicts.
- Check class travel, active class exit, pending-save feedback and bell transition after the HUD relocation.
- CI and independent QA bind to exact candidate SHA. Rendered/runtime comparison remains required before claiming appearance or feel matched.

## Handoff status
Implemented: evidence-based change map and viewport calibration only.
Actually checked: four reference frames; explicit Rojo mapping; active client layout and campus builder source.
Not tested: changed gameplay, Roblox render, movement, touch behavior or frame timing; no product source changed by this handoff.
Known gaps: original RHS2 source, exact assets/measurements, full scene geometry and corrected animation timing are not established by these sampled frames.
Next: Control Tower consumes this handoff when activating its existing reserved P1 producer. Free Roam implements; QA reviews independently.
