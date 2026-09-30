# Maze World Foundation Rules

Baseline: `7ebfd2f81ddfc3d740eee1641b859f49dc087323`  
Upstream Maze World snapshot: `2dba386`

This rebuild treats Maze World as the game chassis. Education is an additive layer.

## Hard invariants

Until an unchanged end-to-end Maze World playthrough is re-certified, do **not** modify:

- `game/maze-world.rbxl`
- `game/Place.rbxmx`
- `game/PlaceTerrain.rbxmx`
- `game/src/common/Maze.lua`
- `game/src/common/MazeGenerator.lua`
- `game/src/common/TouchItem.lua`
- `game/src/common/TagItem.lua`
- `game/src/common/thunks/startGame.lua`
- `game/src/common/thunks/startRoomGameLoop.lua`
- `game/src/common/thunks/playerFinishedRoom.lua`
- `game/src/client/Components/Room.lua`
- `game/src/client/Components/FinishScreen.lua`

Those files define or materially participate in the Maze World generation, room loop, movement/finish path, original reward handling, and original UI.

## Shadow-mode rules

The first Pips integration layer may:

- observe that a maze was generated;
- observe the original finish being touched;
- maintain diagnostic attributes;
- prepare question content off-path.

It may **not**:

- stop or teleport the player;
- close or replace the original finish;
- replace the room/finish UI;
- change maze geometry;
- change coin/reward behavior;
- insert a modal quiz over normal Maze World play.

## Promotion gate

No learning mechanic may become player-blocking until:

1. pristine Maze World launches;
2. player enters the original room;
3. procedural maze is generated;
4. player movement/camera feel unchanged;
5. original pickups still work;
6. original finish triggers;
7. original reward/return flow still works;
8. replay starts another Maze World run;
9. the above is verified on the target phone layout.

The prior custom corridor build is archived and is not an implementation source for this branch.
