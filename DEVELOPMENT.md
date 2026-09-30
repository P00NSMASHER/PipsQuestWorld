# Development Workflow

## Core rule

**Player experience is the score.**

The active game is now Pip High. Do not resume maze gameplay unless the user explicitly reverses the pivot.

## Active architecture

- `school/` — active original school-life Roblox game
- `game/` — frozen legacy Maze World import; historical/reference only
- `docs/` — product and acceptance notes

## Branch rules

1. Never push directly to `main`.
2. Work on a dedicated feature/pivot branch.
3. Re-read current `main` before each implementation cycle.
4. Do not overwrite unrelated worker branches or open PRs.
5. Never weaken tests just to get green.
6. Report implemented, actually tested, not tested, and known failures separately.
7. Never call a build playable/polished/ready from code inspection alone.

## Product integrity

- Build original school layouts, UI, code, names, and assets.
- Do not import or recreate protected content from another Roblox game.
- Reusable generic mechanics are allowed: class schedules, attendance, quizzes, points, free roam, clubs, homes, vehicles, jobs, and social spaces.
- Correct answers stay server-side.
- Client payloads may include question text and choices, but never the answer key.
- Wrong answers should teach, not punish.
- Educational systems must never soft-lock free roam.
- No monetization, loot boxes, FOMO, streak punishment, or artificial waits.

## Background-only rule

When the user is away or at work, repository work, tests, and automation must remain headless/background-only. Do not foreground Roblox Studio, browsers, shells, terminals, or other GUI applications.

## First milestone

spawn -> read school HUD -> travel to current class -> request a question -> answer -> earn points -> bell changes -> continue or free roam.
