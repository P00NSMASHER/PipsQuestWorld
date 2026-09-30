# Baseline Acceptance — Pristine Maze World

No feature work counts until the untouched imported base passes this checklist.

## Runtime

- [ ] Exact pinned upstream revision is present in `game/`
- [ ] Roblox Studio opens the project without fatal load errors
- [ ] Character spawns
- [ ] WASD / thumbstick movement works
- [ ] Jump works
- [ ] Maze generation completes
- [ ] A maze can be started
- [ ] At least one collectible coin/item can be picked up
- [ ] Finish can be reached
- [ ] Another round can begin
- [ ] Core UI controls respond

## Visual evidence

Capture and retain:
- [ ] spawn screen
- [ ] lobby / maze selection
- [ ] active maze
- [ ] collectible pickup
- [ ] finish / reward state
- [ ] mobile-sized viewport

## Failure rule

Do not fix the base before recording the defect. First prove what stock Maze World does, then create a separate repair commit.

## Acceptance

Baseline is accepted only when movement, maze generation, start, collectible pickup, and finish are demonstrated in Roblox runtime—not inferred from code.
