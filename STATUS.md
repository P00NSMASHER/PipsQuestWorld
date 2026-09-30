# Pip's Quest World Status — School Life

## Active direction

- Active gameplay project: **`school/`**
- Maze World: **retired from the active product**
- Legacy Maze World source: preserved under **`game/`** for provenance/rollback only
- Active implementation branch: **`feat/school-life-pivot`**
- Runtime/visual QA in Roblox Studio: **NOT YET PROVEN**

## Implemented on the school-life pivot

- standalone Rojo project with no Maze World runtime dependency
- original procedural school campus and town
- rotating school-day clock, class periods, lunch, passing time, and after-school time
- Math, Science, P.E., and Art class activities
- server-only answer metadata and server-authoritative rewards
- wrong-answer retry without exposing the correct answer
- persistent Credits and XP through DataStore
- claimable starter homes
- starter car spawn/drive system
- appearance/style presets
- cafe delivery job
- mobile HUD, phone/schedule panel, class modal, and notifications

## Not yet proven

- exact branch launches cleanly in Roblox Studio
- spawn/movement and all prompts work end-to-end
- phone-sized visual QA
- multiplayer behavior
- DataStore persistence under production conditions
- vehicle handling quality
- full-day repeat without reset or soft-lock

## Later feature gaps

- Cooking, Dance, and Performance Arts
- distinct subject-specific minigames beyond starter question activities
- deeper avatar editor
- furniture placement/home decorating
- expanded vehicles, jobs, clubs, and social spaces

## Hard acceptance gate

Do not call the school-life build playable or polished until the exact candidate is run in Roblox Studio and visibly proves:

spawn → movement → school schedule → attend current class → wrong-answer retry → correct-answer reward → Credits/XP update → claim home → spawn/drive car → change style → complete cafe shift → advance through the next school period → verify phone-sized UI.

No further Maze World runtime work should be started unless the user explicitly reverses the school-life pivot.
