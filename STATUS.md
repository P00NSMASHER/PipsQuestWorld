# Pip High Status

Updated: 2026-09-30

## Direction

- Maze World product direction: **ABANDONED**
- Active product: **Pip High**
- Active source root: `school/`
- Legacy Maze World import: preserved under `game/` as historical/reference material only
- Third-party high-school game code/assets/maps: **NOT USED**
- Roblox publication: **NOT REQUESTED / NOT PERFORMED**

## Implemented in the pivot branch

- Original Rojo project for the new school game
- Procedurally generated campus shell and room layout
- Homeroom, Math, ELA, Science, Lunch, Social Studies, PE, and Free Time periods
- Server-controlled bell schedule
- Mobile HUD showing current/next class and points
- Server-authoritative travel-to-class requests
- Server-only question bank and answer validation
- Forgiving retry flow and point rewards
- Static CI guard that rejects client/shared answer keys and Maze World references in the active school project

## Not yet runtime-proven

The branch has not been opened in Roblox Studio and visually accepted yet. Runtime claims must wait for a background-safe or user-approved Studio verification session.

## Next player-facing milestones

1. Runtime smoke: spawn -> move -> use HUD -> travel to class -> answer question -> earn points.
2. Replace blockout campus with an original polished school campus.
3. Add avatar/social interactions, lockers, clubs, cafeteria interactions, gym activities, and free-time activities.
4. Add persistent progression and cosmetics.
5. Expand the question rotation with the user's schoolwork-derived content while keeping answers server-only.
