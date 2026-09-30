# Development Workflow — Licensed RHS Rebuild

## Goal

Restore the licensed archived ROBLOX High School build to faithful working behavior on current Roblox, then add educational systems without replacing the original game loop.

## Immutable baseline

`rhs/baseline/ROBLOX High School.rbxl`

This file is evidence. Its hash and size are fixed in `rhs/BASELINE.json`. Any baseline mutation is a hard failure.

## Working copy

`rhs/working/ROBLOX High School.rbxl`

The working copy begins byte-for-byte identical to the baseline. Compatibility changes must be deterministic and documented.

## Repair order

1. Prove exact import identity.
2. Headlessly inventory assets, scripts, services, remotes, and external dependencies.
3. Build a compatibility matrix for removed/deprecated Roblox APIs and dead external services.
4. Repair startup blockers first.
5. Prove spawn, movement, camera, HUD, and core interactions.
6. Prove school schedule/classes.
7. Prove vehicles.
8. Prove housing/furniture.
9. Prove clubs/social systems and tools.
10. Prove persistence using a safe project-specific test namespace.
11. Only after core parity is proven, add the educational question layer as an additive system.

## Integrity

Each repaired build must retain a receipt linking it back to the immutable baseline and listing all deliberate behavioral deviations.

No direct pushes to `main`. No Roblox publication without explicit user instruction.
