# Maze World Learning Adapter Contract

Status: **DESIGN ONLY — NOT AUTHORIZED FOR GAMEPLAY INTEGRATION**

Foundation authority: `7ebfd2f81ddfc3d740eee1641b859f49dc087323`  
Standalone education/content checkpoint: `10e933a0956605b5e1d99f2e162640da9175fec9`

## First seam decision

The first educational interaction will attach to **one existing native Maze World coin**
during a run. It will not create a new corridor, gate, finish condition, or replacement
collectible.

Maze World already generates native `Coin` / `PileOfCoins` models inside the
procedural `Maze` folder. Their `PrimaryPart` carries the native `CoinBrick` tag
and an `itemId` such as `9000001` or `9000008`.

The existing Maze World server remains the sole authority for:

- coin value;
- datastore increment;
- coin sound;
- native notification;
- coin destruction/respawn behavior;
- room lifecycle;
- finish/win;
- return/replay.

The learning adapter gets **no authority over those behaviors**.

## Trigger selection

After a new native `Maze` folder is generated:

1. wait until its native `FinishPlaceholder` exists, indicating generation is populated;
2. find `CoinBrick` parts that are descendants of that exact Maze folder;
3. require the native `itemId` value to remain present and unchanged;
4. ignore one-per-player treasure or non-standard items;
5. choose exactly one normal generated coin using deterministic run-local selection;
6. add learning observation only; do not rename, retag, reparent, clone, replace, or
   change the native coin's `itemId`, collision, or reward semantics.

A later implementation may add a small visual decoration using a child Highlight,
Attachment, or light, but the native model identity remains intact.

## Player interaction

When the selected native coin is touched:

- Maze World's existing `CoinBrick` handler continues normally;
- the coin reward is not delayed by education;
- the adapter captures everything it needs immediately because the native coin may
  be destroyed on the same touch;
- at most one learning session opens for that player for that maze run;
- if the adapter errors, times out, or is absent, Maze World continues normally.

**Base maze completion never depends on answering.**

## Server authority

Education Engine and question banks remain under `ServerStorage`.

The server selects the question and creates an opaque session id.

Server -> client presentation may contain only the sanitized engine `clientView`:

- id;
- subject / skill / tier;
- difficulty / DOK / question type;
- prompt;
- 2–4 options;
- optional sanitized rich content;
- question position metadata.

It must not contain:

- `correctIndex`;
- accepted-answer keys;
- internal diagnostics that reveal the answer;
- full server question objects.

Client -> server answer submission contains only:

- opaque session id;
- selected option index.

The server validates player, active session, option bounds, expiry, and answer.

## Session lifecycle

Per-player state is one of:

- `IDLE`
- `PRESENTED`
- `RESOLVED`
- `CANCELLED`

Required cancellation conditions:

- question timeout;
- player leaves;
- character reset when session cannot safely continue;
- native Maze folder is removed/reset;
- room/run identity changes;
- another run begins.

Cancellation restores normal play and grants no mastery evidence.

Touch spam must never create a second active session.

## Wrong-answer recovery

The existing Education Engine contract applies:

1. first miss -> misconception-specific clue when available;
2. second miss -> scaffold/support;
3. third miss -> modeled answer/explanation and resolution.

A supported/modelled resolution never counts as independent mastery.

No wrong-answer path may trap movement or prevent native maze finish.

## Success/evidence

Initial seam is a **bonus-learning checkpoint**, not a finish gate.

Resolution records run-local evidence:

- question id;
- skill;
- attempts;
- independent vs supported;
- points: 25 / 20 / 0;
- resolution timestamp/run identity.

Future Pip progression may consume that evidence, but Maze World's native coin reward and
native finish reward do not depend on it.

## UI contract

The first seam gets one transient question surface only.

- No persistent large Pips HUD.
- No black/dark full-width status box.
- No full-screen worksheet overlay.
- Landscape question UI targets <= 40% of useful viewport.
- Roblox movement/jump controls remain unobstructed.
- UI disappears immediately after resolution/cancel.
- Native Maze World finish/reward UI remains untouched.

## Acceptance before a second seam

Do not add another learning checkpoint until one-checkpoint acceptance proves:

1. native coin still rewards correctly;
2. selected coin keeps original Name/tag/itemId semantics;
3. unanswered question cannot block maze completion;
4. correct/wrong/modeled flows recover cleanly;
5. touch spam cannot duplicate sessions;
6. Maze reset destroys stale session state;
7. correct answer never dispatches native finish;
8. no answer key reaches the client;
9. UI does not materially obstruct mobile maze play;
10. disabling the adapter returns pure Maze World behavior.

This contract intentionally chooses the smallest additive seam possible.
