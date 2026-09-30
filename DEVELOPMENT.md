# Development Workflow — School Life

## Current direction

The maze concept is retired as the active product direction.

- `game/` = frozen legacy Maze World import and provenance.
- `school/` = active standalone school-life roleplay game.

## Product loop

spawn in town → school schedule → class activity → credits/XP → free time → home/style/vehicle/job → repeat

## Integration flow

`main`  
Release-quality, accepted work.

`develop`  
Integration branch when used for multi-worker development.

Feature branches should be scoped to one player-facing system, for example:

- `feat/school-life-pivot`
- `feat/classes`
- `feat/housing`
- `feat/vehicles`
- `feat/jobs`
- `feat/avatar-style`
- `feat/mobile-ui`
- `qa/school-life`

## Rules

1. No direct pushes to `main` or `develop`.
2. Do not modify the legacy Maze World tree during normal School Life work.
3. Clean-room implementation only; no proprietary code/assets/maps/UI from other Roblox experiences.
4. Server owns progression, rewards, attendance, jobs, and answer validation.
5. Client owns presentation and input only.
6. Wrong class answers give feedback and permit retry; no punishment.
7. Mobile is a first-class target.
8. Runtime evidence is required before calling the game playable.

## First acceptance milestone

A player can:

1. spawn on the school campus,
2. see the current time/period,
3. attend the scheduled class,
4. complete a short class activity,
5. earn persistent credits/XP,
6. claim a home,
7. spawn and drive a basic vehicle,
8. change an appearance preset,
9. complete a simple after-school delivery job,
10. repeat the next school day without a reset or soft-lock.
