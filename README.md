# Pip's Quest World — School Life Pivot

The active product direction is now a **clean-room school-life roleplay game**.

The previous MayGo/maze-world foundation remains preserved under `game/` as legacy source and provenance, but it is no longer the target gameplay architecture.

## Active project

`school/` is a standalone Rojo-compatible Roblox project with no runtime dependency on Maze World.

Target loop:

**spawn in town → follow the school day → attend short class minigames → earn credits/XP → socialize/explore → claim a home → customize your look → drive around town → work after school → repeat**

The design intentionally uses original code, geometry, UI, and assets. It may reproduce broad genre mechanics found in school-life roleplay games, but it must not copy another game's proprietary map, source code, models, textures, audio, branding, or UI artwork.

See `docs/SCHOOL_LIFE_PIVOT.md` and `school/README.md`.
