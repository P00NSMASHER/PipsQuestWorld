# Canonical Branch Authority

Effective immediately for the Maze World-first rebuild:

- **Canonical development/integration branch:** `rebuild/maze-world-foundation`
- **Pristine behavioral root:** `7ebfd2f81ddfc3d740eee1641b859f49dc087323`
- **Live custom Pips v132:** archived/reference-only
- **`rebase/maze-world-chassis`: QUARANTINED LEGACY**
- **old `feat/*` Pips branches/worktrees: QUARANTINED LEGACY**

## Why this exists

A stale coordination path temporarily treated `rebase/maze-world-chassis` as canonical even
though that branch contains direct Maze World gameplay modifications, including a finish-flow
LearningGate integration and earlier collectible identity mutation work.

That contradicts the current executive product rule:

> Maze World remains the protected game chassis; education and Pip are additive, removable
> adapters only.

The canonical `rebuild/maze-world-foundation` lineage preserves the protected Maze World
files while adding only server-side education/content/session/selector preparation, static
guards, documentation, and future removable adapter seams.

## Integration rule

No producer, reviewer, QA lane, or Integration Director may:

- use `rebase/maze-world-chassis` as a base;
- cherry-pick gameplay code from the quarantined rebase/custom branches;
- repair quarantined branches as a substitute for working from current canonical foundation;
- treat a stale coordination receipt naming the rebase branch as current authority.

If a useful idea exists on a quarantined branch, it must be re-derived as a new minimal change
from the current `rebuild/maze-world-foundation` head and pass all foundation guards.

## Protected Maze World authority

The pristine Maze World remains authoritative for:

- procedural maze generation;
- room/start/reset lifecycle;
- movement/camera assumptions;
- native CoinBrick/itemId/value/onePerPlayer semantics;
- native finish detection;
- native reward/UI/cooldown/replay;
- Place, terrain, models, and native mobile/game shell.

No learning or Pip layer may take over those responsibilities.

## Current gate

Background/headless preparation is allowed only when it does not alter protected gameplay.
Fresh target-device Maze World acceptance remains required before a live learning hook or
question UI is authorized.

This file supersedes any older coordination text that names another branch as canonical.
