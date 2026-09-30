# Executive Directive — Maze World Rebuild

## Current state

- **Phase:** 0 — Foundation parity
- **Pristine behavioral baseline:** `7ebfd2f81ddfc3d740eee1641b859f49dc087323`
- **Upstream Maze World snapshot:** `2dba386`
- **Active rebuild branch:** `rebuild/maze-world-foundation`
- **Current rebuild head at directive creation:** `a26e9269e013d7791bee94383b0ac283b93bc624`
- **Live Roblox chassis:** pristine Maze World published as **version 133**
- **Legacy build:** Pips Quest v132 is archived/reference-only and must not be used as the active foundation.

## Executive product decision

**Maze World is the game.**

We are not rebuilding the maze, room flow, movement, camera, collectible loop, finish loop, rewards, or general presentation from scratch.

Education, Pip progression, and any future branded systems are **small removable adapters** layered onto Maze World.

If an adapter is disabled, the player must still have a complete, enjoyable Maze World game.

## Current release blocker

**P0 — Certify Maze World foundation parity on the actual product path.**

No gameplay feature work advances until we have defensible evidence that the pristine chassis still preserves:

1. room/waiting/start flow;
2. procedural maze generation;
3. movement and camera feel;
4. coin/collectible pickup behavior;
5. original maze challenge/pacing;
6. finish detection;
7. native reward/finish UI;
8. return/reset/replay;
9. acceptable phone layout/performance;
10. no fatal datastore/bootstrap/runtime defect in the deployed chassis.

## Active work

### ACTIVE — Maze World Foundation

Owner: Maze World Foundation lane.

Objective:
- prove the baseline builds and boots reproducibly;
- identify only defects that prevent baseline play;
- preserve protected Maze World behavior byte-for-byte where possible;
- produce a parity receipt against the pristine baseline.

Exit criterion:
- all deterministic foundation checks pass;
- protected-file guard is green;
- any required Studio-safe bootstrap repair is narrowly isolated and proven not to change gameplay;
- exact candidate SHA is ready for target-device acceptance.

### ACTIVE — Education Engine Adapter, standalone only

Objective:
- maintain a clean server-authoritative question engine;
- improve question-selection/adaptive logic without touching gameplay.

Exit criterion:
- deterministic API/schema tests pass;
- no Maze World dependency;
- no UI/world ownership.

### ACTIVE — Grade 2 Content QA, standalone only

Objective:
- remove weak/ambiguous/trivial items;
- preserve only questions worth interrupting a maze for.

Exit criterion:
- no answer-in-prompt items;
- no absurd distractors;
- no duplicate/ambiguous stems;
- meaningful age-appropriate application/transfer items are present.

## Deferred work

### DEFERRED — Maze Learning Adapter

May prepare contract notes only.

Do not insert questions into Maze World until Phase 0 is certified.

### DEFERRED — Pip Reward Adapter

Do not replace Maze World's native reward path.

May prepare an additive idempotent contract only.

### DEFERRED — Mobile UX

Do not redesign Maze World's shell.

May document baseline mobile constraints only.

### DEFERRED — Integration

No producer gameplay integration until foundation parity is PASS.

## Protected baseline systems

These remain authoritative:

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

No worker may modify these merely to make educational integration easier.

## Phase 1 — Shadow integration

After Phase 0 PASS:

- education engine can observe/query session state;
- Pip can exist cosmetically;
- question selection can run in the background;
- telemetry can verify adapter seams.

**Zero player blocking. Zero replacement UI. Zero reward replacement.**

## Phase 2 — Minimal learning integration

Only after Phase 1 proves clean:

- introduce **one** learning seam;
- use a natural Maze World checkpoint/event;
- one compact contextual question interaction;
- resume immediately after resolution;
- no persistent HUD;
- no finish soft-lock;
- no custom maze geometry;
- no more than one new behavioral dependency at a time.

A single successful seam is required before adding a second.

## Phase 3 — Pip progression and polish

Only after learning integration is stable:

- Pip rewards hook **after/alongside** native Maze World completion;
- persistence/rejoin;
- cosmetic progression;
- iPhone-specific polish;
- stronger presentation only where it improves the existing Maze World experience.

## Non-negotiable rejection criteria

Reject any candidate that:

- creates a new corridor/maze instead of using Maze World;
- replaces MazeGenerator;
- replaces room/start/finish lifecycle;
- replaces native reward flow;
- adds a large persistent custom HUD;
- turns play into a worksheet overlay;
- blocks finish because an educational adapter failed;
- leaks the correct answer to the client;
- copies the v132 custom world back into the rebuild;
- weakens tests/guards to make integration pass.

## Executive development cadence

One release blocker at a time.

1. Prove foundation.
2. Add one removable adapter.
3. Prove Maze World still works.
4. Add the next adapter.
5. Repeat.

No feature-count optimization. No “busy” commits. No parallel speculative gameplay work.

The success metric is simple:

> **Would this still feel like Maze World if all educational/Pip adapters were switched off?**

If the answer is no, the change is architecturally wrong.
