# Maze World Chassis Rebase

Branch: `rebase/maze-world-chassis`

## Decision

Pip's Quest will use the real MIT-licensed Maze World project as its gameplay chassis.

The prior corridor prototype is not the design baseline.

## Preserve from Maze World

- Dynamic maze generation and random maze layouts
- Easy / Medium / Hard room structure
- Waiting-room and game-start loop
- Maze spawning and player transport
- Native movement/camera behavior
- Finish detection and timing
- Collectible coins/items
- Maze cleanup/cooldown/replay loop
- Existing world assets, room presentation, sounds, pets/trails where appropriate
- Streaming and loading behavior
- Existing completion/reward plumbing

## Replace or adapt

- Robux/game-pass monetization paths: remove from the child-facing product
- Branding: Pip's Quest identity
- Educational progression: add as gates inside Maze World's real loop
- Rewards: convert earned progression/cosmetics to learning/adventure rewards
- Mobile UI: use Maze World's game UI as the visual baseline; avoid persistent full-width overlays
- Question presentation: in-world by default, not a worksheet covering gameplay

## First playable integration

The first integration is deliberately small and reversible:

1. Player joins a normal Maze World room.
2. Maze World generates the maze exactly as usual.
3. Player explores the maze and collects normal world items.
4. At the generated finish, a Pip learning gate appears.
5. The gate selects a certified Grade-2 transfer/reasoning question.
6. The prompt and three choices are presented as world objects at the finish.
7. Player steps on an answer pad.
8. Wrong answers give a short clue and keep the player in the maze.
9. Correct answer destroys the learning gate.
10. Maze World's original `playerFinishedRoom` executes unchanged.

This means education is grafted onto a working game instead of replacing the game.

## Non-negotiable acceptance gates

Do not publish over the live place until all are true:

- Stock Maze World first-screen presentation remains recognizable and functional.
- Dynamic maze generation works.
- Spawn -> maze -> finish works with mobile controls.
- No persistent question/HUD panel covers the play field.
- Learning gate renders inside the world and is legible on iPhone landscape.
- Correct answer completes the actual Maze World room.
- Wrong answer does not accidentally finish the room.
- Original maze cleanup/restart loop still works after the learning gate.
- No Robux purchase is required for educational progression or rewards.
- Server validates answers.
- At least one full native Play-mode loop passes.

## Licensing

Maze World is reused under its MIT license. Preserve the upstream copyright/license notice in substantial reused portions and distributions.
