# School Life

Standalone clean-room Roblox school-life project.

## Run

Use Rojo with:

```powershell
rojo serve school/default.project.json
```

Then connect Roblox Studio to the served project.

## What is implemented in this first slice

- generated campus, neighborhood, roads, cafe, style booth, vehicle lot
- school-day clock and rotating periods
- class check-in prompts
- server-authoritative multiple-choice class activities
- Credits and XP with DataStore persistence
- claimable starter houses
- simple driveable hover-style school cars
- appearance color presets
- cafe delivery job
- mobile-first HUD, phone panel, notifications, and class modal

## Important

This project does not depend on `../game/` and does not use Maze World systems.

Runtime QA is still required before calling it playable.
