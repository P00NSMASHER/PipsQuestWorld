# HANDOFF — Pip & Rewards

## Lane
- Branch: `feat/pip-rewards`
- Responsibility: enhance Maze World's native collectible/finish/reward presentation with Pip identity, cosmetics, pets/trails, and visible feedback. Reuse native systems. Never own room completion, create a parallel currency/progression loop, or add a separate finish/reward room.

## Exact implementation revision
- Commit SHA: `36e9895efc7b90634252b609d9e0d9e95d796d49`

## Implemented
- Added `clientPipNativeFinishCelebration`, dispatched only after Maze World's full native finish/reward/leaderboard sequence.
- Added idempotent Pip finish-feedback state keyed by `roomId:finishTime`.
- Layered a Pip cheer onto the existing native `FinishScreen`.
- Added `scripts/test-pip-rewards-native-finish.mjs` to lock the native reward order and no-paywall/no-parallel-loop boundary.

## Actually tested
- Exact-head headless contract/regression checks passed on `36e9895efc7b90634252b609d9e0d9e95d796d49`.
- Verified native finish dispatch, prize coins, coin notification, finish sound, leaderboard updates, and room replay loop remain present and in authority.
- Verified Pip dispatch occurs after the native completion sequence and duplicate Pip delivery is guarded.

## Not tested
- Roblox runtime rendering, animation, touch layout, saving/rejoin, and physical-device behavior were not tested because this lane is background/headless-only.
- No claim of playable, polished, or runtime-accepted status is made.

## Known failures / blockers
- `EXECUTIVE_PLAN.md` is absent on the current branch.
- Maze Core/Learning Gates have no implemented completion contracts beyond their lane handoffs yet.
- Baseline Roblox runtime acceptance remains outside this lane and is still required before integration claims.

## Files changed
- `game/src/common/thunks/playerFinishedRoom.lua`
- `game/src/common/actions/toClient/clientPipNativeFinishCelebration.lua`
- `game/src/client/clientReducers/player.lua`
- `game/src/client/Components/FinishScreen.lua`
- `scripts/test-pip-rewards-native-finish.mjs`

## Integration notes
- Learning Gates must hand back to Maze World's original finish flow after resolution.
- Do not move Pip celebration ahead of native prize/notification/leaderboard work.
- Do not replace `clientFinishGame`, `GameDatastore:incrementCoins`, native audio, or room-loop authority.

## Player-experience impact
After Maze World itself finishes the room and awards its native coins, the existing finish screen gains a small Pip cheer that reflects the native coin reward. No extra chest room, finish pad, currency, purchase interruption, or bespoke replay flow appears.

## Evidence
- Implementation: `36e9895efc7b90634252b609d9e0d9e95d796d49`
- Regression artifact: `scripts/test-pip-rewards-native-finish.mjs`
- Exact-head result: PASS for native order, native audio, idempotency, native FinishScreen reuse, untouched room replay loop, and absence of new paywall surfaces.
