# School-Life Pivot

## Decision

The Maze World direction is abandoned for active development.

All maze-specific runtime, progression, collectible, finish, and adapter work remains in repository history only. New gameplay work should target the school-life branch and should not depend on Maze World systems.

## Product direction

Build an original Roblox school-life experience with the familiar high-level loop players expect from the genre:

- spawn at a school campus
- follow a repeating class schedule
- move between rooms during passing periods
- attend classes
- receive short interactive class activities/questions
- earn persistent school points and rewards
- expand later into lockers, cafeteria, clubs, avatar customization, vehicles, homes, social spaces, and after-school activities

This project may match common school-roleplay mechanics and pacing, but must use original code, world geometry, UI, names, assets, audio, text, and branding.

## Foundation implemented in this branch

- standalone Rojo project under `school_game/`
- procedurally generated five-room campus
- Homeroom, Math, Science, English, and Art rotation
- timed classes and passing periods
- automatic classroom routing
- server-authoritative answer checking
- correct answers never sent to clients
- school-points reward loop
- iPhone-friendly top-card HUD and answer controls

## Next implementation order

1. Persistent player profile/DataStore
2. Bell/audio and visible room signage
3. Locker assignment and inventory
4. Cafeteria/lunch period
5. Avatar editor and clothing presets using permitted assets
6. Clubs and after-school activities
7. Vehicle spawning and parking
8. Home/apartment ownership
9. Friend/social party system
10. Device QA and Roblox Studio acceptance
