# Pip Rewards Status

## Current cycle — native Rainbow Trail unlock on Maze World finish
- Status: **READY**
- Step 7 objective: add one free Pip-themed unlock to Maze World's existing successful finish path by reusing its native pet/trail inventory system.
- Implementation commit: `322e545c57f98daeec611a5b25ad9daedc4e73e0`
- Validation: **PASS** — exact-commit, headless contract/regression verification against `322e545c57f98daeec611a5b25ad9daedc4e73e0`.
- Runtime/visual claim: **NONE**. Roblox Studio and every GUI surface remained untouched.

## Plan and completion-contract inputs
- `EXECUTIVE_PLAN.md`: not present on current `PipsQuestWorld` main or on `feat/pip-rewards`; no plan contents were invented.
- Maze Core `HANDOFF.md`: still a placeholder and exposes no newer completion interface.
- Learning Gates `HANDOFF.md`: still a placeholder and exposes no implemented finish handoff contract.
- Exact Maze World completion contract consumed this cycle:
  - `game/src/common/thunks/playerFinishedRoom.lua`
  - `game/src/common/actions/toClient/clientFinishGame.lua`
  - `game/src/client/clientReducers/player.lua`
  - `game/src/common/thunks/startRoomGameLoop.lua`
- Exact native reward/inventory contract inspected this cycle:
  - `game/src/common/GameDatastore.lua`
  - `game/src/common/objects/InventoryObjects.lua`
  - `game/src/common/Pet.lua`
  - `game/src/common/PetManager.lua`
  - `game/src/server/main.lua`
- Conservative Learning Gate boundary remains unchanged: if a gate delays access to the finish, successful resolution must return control to Maze World's original finish path. Pip Rewards never marks a room complete.

## Native event consumed
Authority remains `playerFinishedRoom`. The authoritative sequence remains:

`transport home -> record native finish -> clientFinishGame -> award prize coins -> native coin notification -> leaderboard updates -> optional Pip inventory unlock -> Pip celebration`

The Pip unlock runs only after Maze World's native completion/reward/leaderboard work has succeeded.

## Proof the original reward still fires
Exact-head proof for `322e545c57f98daeec611a5b25ad9daedc4e73e0` confirmed:
- `Transporter:placePlayersToHomeSpawn` remains first in the completion sequence;
- `addPlayerFinishToRoom` and `clientFinishGame` remain unchanged and precede Pip work;
- `GameDatastore:incrementCoins(player, coins)` still awards Maze World's native prize;
- the original `You won ... coins` notification still fires before the Pip unlock;
- both native leaderboard updates remain before Pip work;
- the native finish timestamp is still captured once and shared with Pip finish feedback;
- `startRoomGameLoop.lua` remains untouched by Pip Rewards, so Maze World's cooldown/replay authority is preserved;
- the existing native-finish regression artifact remains: `scripts/test-pip-rewards-native-finish.mjs`.

## Pip enhancement added
- First successful native finish now unlocks Maze World's existing inventory item `20004` — **Path Pet Rainbow**, which already uses `PET_TYPES.TRAIL` and `RainbowTrail`.
- Persistence reuses `GameDatastore:setInventoryItem`; that native method stores inventory with `M.unique(M.push(...))`.
- The unlock helper first reads the native inventory and returns without writing if item `20004` is already owned, so repeated finishes do not duplicate the reward.
- Immediate feedback reuses Maze World's existing notification presentation: `Pip unlocked Path Pet Rainbow in your Inventory!`
- The existing Pip finish cheer still renders inside Maze World's native `FinishScreen`.
- No separate chest room, finish pad, currency, progression system, or replay structure was added.
- No coin deduction, Robux prompt, game-pass purchase, developer-product call, or paywall was added to the finish path.
- No question content or maze geometry was changed.

## Idempotency / regression proof
- New regression artifact: `scripts/test-pip-rewards-native-trail-unlock.mjs`.
- Exact-head verification proves the native reward sequence is unchanged, the existing Rainbow Trail pet asset is reused, ownership is checked before the native inventory write, native inventory persistence is duplicate-safe, and the room replay loop remains outside Pip ownership.

## Files changed in the tested unit
- `game/src/common/thunks/playerFinishedRoom.lua`
- `scripts/test-pip-rewards-native-trail-unlock.mjs`

## Next safe objective
Audit the existing equip/unequip and inventory replication path for item `20004` and add a headless regression proving the newly unlocked native pet/trail can flow through Maze World's existing inventory/equip contract without auto-equipping it or creating a second reward/progression system.
