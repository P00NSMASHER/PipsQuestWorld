# PipsQuestWorld Contract Guardian Review

**Verdict: BLOCKED**

GitHub/static review only. No PAAM-L044 or GUI access was used.

## Exact contract fingerprint

- Pristine Maze World: `7ebfd2f81ddfc3d740eee1641b859f49dc087323`
- Canonical foundation: `rebuild/maze-world-foundation@8acc2b34b6fcce94b81c3b3729249b6d6cc90450`
- Reused green tree: `0ef7f29500537f81cc75526ad593bfcd301db765`
- `0ef7f29...` -> `8acc2b3...`: one commit, zero file changes
- Foundation Guard `36759370251`: PASS
- Standalone Education Content CI `36759370126`: PASS
- Fingerprint: `sha256:96cf881f030e6eeaa91af41a0e80bc025ac747555371d442488d4782e9139962`

Canonical surface blobs:
- Education Engine `ed5cc095843655cf5d5023ac853f45301f1f5b44`
- Learning Session `b718c374349640bef19e2dad63d7a99239d3b0b3`
- Learning Coin Selector `94ac9a6fc6fc560371ba16962ba13f963ace3ed8`
- Release Question Bank `a5dcd3855c4e4f7a307a118f169b2d6a0c22dd02`
- Overlay Config `40ab8d2c8f379349ed93d45348a7f5622365bc2f`
- Shadow observer `9d743ca92767a44f29dd878cea33ff82ab241960`

Protected Maze World blobs are byte-identical to pristine:
`Maze.lua 972e56f...`, `MazeGenerator.lua 8d4ff89...`, `TouchItem.lua b44b4c2...`,
`TagItem.lua 766d7c8...`, `startGame.lua db7e073...`,
`startRoomGameLoop.lua bf6deec...`, `playerFinishedRoom.lua 707d720...`,
`Room.lua 2bc577a...`, `FinishScreen.lua 7de0c9e...`.

## Contract matrix

| Contract | Status | Owner | Exit criterion |
|---|---|---|---|
| Maze Core -> native Maze World | PASS | Maze World Foundation | Keep all protected native blobs identical except separately approved visual-only theming. |
| Maze Core -> Learning Gates | NOOP | Learning Adapter | No live hook candidate. First hook must be one deterministic native-coin observer, fail-open, with no tag/item/value/native-handler mutation. |
| Education -> Learning Gates | PASS | Education Engine | Keep answer authority server-only; clientView omits `correctIndex`; one-question session and metadata contract unchanged. |
| Learning Gates -> Maze World finish | NOOP | Learning Adapter | Correct resolution may only dismiss the transient encounter and return control; native `playerFinishedRoom` remains sole finish authority. |
| Pip Rewards -> Maze World rewards | NOOP | Pip Rewards | No canonical candidate. Any future candidate must augment native completion/rewards idempotently and never own currency, replay, or finish. |
| Mobile UX -> Maze World controls | NOOP | Mobile UX | No canonical candidate. Future question UI must exist only while active and must not obstruct native controls. |
| Content -> Education | PASS | Content | Release bank remains server-only; current QA records 12 active material items and no accepted-answer leakage in prompt/hint/scaffold. |

## Incompatible open candidates

- PR #8, head `883fa92583e58791443798330d8b61d22807df62`: **BLOCKED**. Owner: school-life pivot lane. It introduces an independent `school/` game/runtime rather than a removable Maze World adapter. Exit: supersede it with work rooted at the canonical Maze World foundation.
- PR #11, head `ff60b7160f554f51d7289bce596dc5aeadbb8ed8`: **BLOCKED**. Owner: school-life pivot lane. It explicitly replaces the Maze direction with a standalone `school/` vertical slice. Exit: no separate world/runtime loop; any reusable education logic must be re-derived as a fail-open Maze World adapter.
- PR #12, head `aee67f5c83dc3e765758e2b73d190f446cfc38c6`: **BLOCKED**. Owner: school-life pivot lane. It explicitly retires Maze World and creates `school_game/`. Exit: future work must preserve Maze World's room/maze/coin/finish/reward/replay authority.

Explicit rejection scan: parallel world loop is present only in PRs #8/#11/#12 and is blocked. On the canonical head there is no replacement finish/replay/reward authority, no persistent learning HUD, no duplicate progress authority, and no client-known `correctIndex`.

`LOCAL_ONLY_REQUIRED: none`

No producer code, merge, Studio session, deployment, or publish target was modified.
