# School Life Pivot

## Decision

Stop extending Maze World. Preserve it only as legacy/provenance.

The active game becomes an original school-life roleplay experience inspired by the **genre loop**, not by copied proprietary implementation.

The official Roblox High School 2 listing describes a loop centered on going to class, meeting friends, dressing up, creating a home, and living around a town. Our implementation uses those broad ideas as genre references while using original code, map layout, names, UI, models, colors, and activities.

## Product pillars

### 1. School day
- visible clock and period
- passing time
- four short class activities in the first slice
- non-punitive retry
- server-authoritative completion and rewards

### 2. Town life
- campus plus roads and neighborhood
- claimable starter homes
- simple drivable cars
- appearance/style booth
- after-school delivery job

### 3. Progression
- Credits
- XP
- attendance/completions
- persistent profile through DataStore
- no paid shortcuts required for the core loop

### 4. Mobile
- large touch targets
- top status strip
- compact phone/schedule panel
- class modal designed for portrait-width screens

## Explicit non-goals

- no copied RHS/RHS2 map geometry
- no copied scripts
- no ripped models, textures, audio, decals, logos, icons, or UI
- no imitation branding such as Starcadia Bay/Cinder Studio
- no dependency on Maze World runtime systems

## Initial implementation

The `school/` project provides:
- runtime-built original campus/town
- school clock and rotating periods
- Math, Science, P.E., and Art class interactions
- server-side answer validation
- Credits/XP persistence
- home plot claims
- basic vehicle spawning/driving
- style presets
- cafe delivery job
- mobile HUD/phone/class UI

Runtime QA in Roblox Studio is still required before the branch can be called playable.
