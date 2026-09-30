# Maze World Learning Adapter Contract

Status: **DESIGN + SERVER SESSION CORE ONLY — GAMEPLAY HOOK NOT AUTHORIZED**

Foundation authority: `5988b2d674495903b11f1db2ef41e2159d4fff00`  
Pristine behavioral authority: `7ebfd2f81ddfc3d740eee1641b859f49dc087323`

## First seam

The first educational interaction will attach to exactly **one existing native Maze World coin**
during a run. It will not create a new maze, corridor, gate, finish condition, chest, or replacement
collectible.

The native Maze World server remains the sole authority for coin value, datastore increments,
pickup sound, coin destruction/respawn, room lifecycle, finish/win, return and replay.

The learning adapter gets no authority over those behaviors.

## Verified native seam

The pristine Maze World coin assets carry the native `CoinBrick` tag and item ids:

- `Coin.rbxmx` -> `9000001`
- `PileOfCoins.rbxmx` -> `9000008`

The existing server registers the authoritative `CoinBrick` pickup handler and may destroy the
coin model on the same touch.

### Important implementation constraint

**Do not register a second `TagItem.create(..., 'CoinBrick', ...)` listener.**

`TagItem.lua` owns a module-global per-player touch debounce. Reusing it for the learning
adapter could cause the educational callback and the native coin callback to compete for the same
player touch and risk suppressing the native reward path.

The future world adapter must instead:

1. deterministically select one already-generated native coin;
2. cache its run id, item id and immutable selection metadata before player contact;
3. attach one independent direct `.Touched` observation to that selected part only;
4. never change the CoinBrick tag, itemId, parent, collision or native handler;
5. disconnect its observation when the run closes;
6. never depend on the coin still existing after the touch callback begins.

## Deterministic native-coin selection

The future world adapter must hand the selector normalized records only after verifying that each
record belongs to the exact generated Maze folder for the current run.

`PipsLearningCoinSelector.lua` is pure/server-only preparation. It:

- accepts only normal native coin item ids `9000001`, `9000005`, or `9000008`;
- rejects one-per-player treasure ids and unknown ids;
- requires a stable unique candidate key;
- sorts candidates before selection so discovery order cannot change the result;
- derives one run-local choice deterministically from the run id;
- never mutates the selected coin record.

It does not inspect Workspace, attach touch listeners, mutate native coins, or award anything.

## Server-only learning session core

`PipsLearningSession.lua` is allowed as standalone preparation because it owns no world,
RemoteEvent, UI, movement, reward or finish behavior.

It enforces:

- one active learning session per player;
- at most one learning session per player per run;
- opaque session id;
- run/session identity validation;
- option-bound validation;
- configurable timeout;
- clue -> support -> model wrong-answer recovery;
- independent vs supported evidence;
- 25 / 20 / 0 scoring from the accepted Education Engine contract;
- cancellation and run cleanup;
- no native Maze World reward authority.

The client-facing question payload is the Education Engine `clientView` only, with one-checkpoint
position metadata. It never includes `correctIndex`.

## Fail-open gameplay rule

Education may fail closed for mastery evidence, but must **fail open for Maze World gameplay**.

An adapter error, timeout, wrong answer, player reset, run reset, or missing educational service
must never block:

- native coin reward;
- movement/camera;
- native finish;
- native finish reward/UI;
- return to lobby;
- replay.

## Future UI contract

No gameplay UI is authorized yet. When target-device foundation acceptance exists, the first seam
gets one transient question surface only:

- no persistent Pips HUD;
- no black full-width status box;
- no full-screen worksheet overlay;
- target <= 40% of useful landscape viewport;
- do not cover Roblox movement/jump controls;
- disappear immediately after resolve/cancel;
- leave native Maze World finish/reward UI untouched.

## Acceptance before any second seam

A second learning checkpoint is prohibited until one-checkpoint acceptance proves:

1. native coin reward still fires;
2. selected coin retains native tag/itemId semantics;
3. unanswered education cannot block maze completion;
4. correct/wrong/modeled paths recover;
5. touch spam cannot duplicate sessions;
6. run reset clears stale active state;
7. education never dispatches native finish;
8. no answer key reaches the client;
9. mobile maze controls remain usable;
10. disabling the adapter returns pure Maze World behavior.

Gameplay integration remains blocked until the executive Phase-0 target-device gate permits it.
