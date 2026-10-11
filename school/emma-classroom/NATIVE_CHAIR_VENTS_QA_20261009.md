# Emma Classroom — iPhone chair-back vent fidelity, October 9

## Reference and issue
The supplied classroom photographs contain actual blue molded student chairs
with narrow, elongated back ventilation details. The legacy fallback in
`Room.lua` constructed 3 per chair (48 total) as Ball Parts with dimensions
.18 × .65 × .034 studs. Native Roblox Ball geometry renders as a sphere using
its **smallest** axis rather than the independent renderer's flattened
ellipsoid interpretation. These tiny dark dots do not resemble manufactured
chair vent slots at child eye height.

## Implemented development correction
- Keep every original chair frame, desk position, side return and invisible
  collision back, all 16 desk-chair pairs and existing color variation.
- Replace just the 48 flattened Ball decorations with 48 shallow, tall,
  contrasting dark, smooth-plastic **Block** recesses in the same positions.
  `CanCollide`, `CanTouch`, `CanQuery` and `CastShadow` are false.
  These are visual molded-inset approximations, **not actual through-holes**.
- Add executed-Luau `audit_native_chair_vents.py` to verify correct 3D
  spacing relative to every modeled chair shell and surface, shape, size,
  collision separation and the original 16 one-piece back colliders.
  Deliberately mutate one vent to Ball, one to a tiny square and one to
  collidable geometry; all three must be rejected.
- Make the new test mandatory in the existing classroom-only CI **and**
  exact SHA-pinned review-preview publisher, with release-provenance guard.

## Safety / verification boundaries
No new scene Parts, native furniture assets, screenshots of children,
schoolwork data or gameplay changes. The performance budget stays at 3,100
source-created Parts. Same-view source-render comparison can confirm the
physical construction but **cannot** prove in-engine iPhone appearance.
Keep PR #339 draft and production-owned meshes disabled until a real native
Roblox Studio and iPhone visual/collision review. Publish only through the
existing authorized owner-review preview flow if applicable.
