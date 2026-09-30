# Pip High Pivot

Date: 2026-09-30

## Decision

The Maze World-first concept is retired. The new product is an original school-life Roblox game.

The goal is to capture the useful *genre mechanics* of a Roblox high-school roleplay game without copying any protected implementation:

- school-day schedule and bells
- named classes and classrooms
- attend-class loop
- educational questions
- points/progression
- campus navigation
- cafeteria, gym, library, courtyard, and social areas
- free-roam periods
- future clubs, avatar/social features, vehicles, homes, jobs, and activities

## First vertical slice

The first branch intentionally uses a procedural blockout campus so gameplay can be proved before visual polish. Required proof:

1. Player spawns on campus.
2. HUD shows current and next period.
3. "Go to Class" moves the player to the correct room.
4. "Class Question" only works when the player is physically near the correct room.
5. Client receives prompt and choices only.
6. Server checks the answer using a server-only question bank.
7. Correct answers award points.
8. Wrong answers give a hint and another try without punishment.
9. A period change updates all players.
10. Free-roam periods never block movement.

## Copyright / provenance rule

Do not import, scrape, decompile, trace, or reconstruct another Roblox game's map, scripts, proprietary assets, logos, names, UI, audio, or other protected expression. Any later third-party dependency must have documented reuse rights.
