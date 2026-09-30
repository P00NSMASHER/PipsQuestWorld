# Phase 1 Standalone Preparation Receipt

Tested exact code SHA: `10e933a0956605b5e1d99f2e162640da9175fec9`  
Foundation base: `b7eb3fbe1eb65f31f36bc08a1aeda7830f736a71`  
CI run: `36742954110` — **PASS**

## Scope

This candidate intentionally changes **no Maze World gameplay**. It contains only:

- server-only Education Engine;
- server-only full question archive;
- server-only curated release bank;
- deterministic education tests;
- content-quality tests;
- cross-contract Education + Content test;
- boundary checks preventing answer-authority leaks;
- CI and status receipts.

## Security boundary

`PipsEducationEngine.lua`, `PipsQuestionBank.lua`, and
`PipsReleaseQuestionBank.lua` live under `game/src/serverStorage`.

The CI boundary check fails if those answer-authority modules appear under
`game/src/common` or `game/src/client`.

`clientView` exposes prompt/options/metadata only and does not expose
`correctIndex`.

## Engine contract

- 5-question session model.
- 2–4 unique options.
- Current material before STAR fallback.
- No repeat inside one quest.
- Upward difficulty jump capped at +1 when an eligible item exists.
- At least one transfer/application item in a five-question run when available.
- Prefer skill variety; no same skill twice in a row when alternatives exist.
- Supported item schedules a same-skill comeback.
- Feedback progression: clue -> support -> model.
- Supported/modelled answers do not count as independent mastery.

## Evidence/scoring contract

- first-try correct: 25 points;
- corrected after one/two misses: 20 points;
- modelled resolution: 0 points;
- score normalized to percent across the quest;
- evidence grade bands: A / B / C / Practice;
- player mastery tier uses independent-correct evidence only.

## Curated content

Active release pool: 7 Grade-2 material items.

Five weak schoolwork-derived candidates are quarantined from active use.
Two additional technically-valid but weak items were replaced by stronger
skill-equivalent transfer questions for plural nouns and the Trinity.

The full certified archive remains server-side as provenance/evidence and is
not automatically eligible for gameplay.

## Maze World isolation

Compare against `rebuild/maze-world-foundation` shows **zero changes** to:

- maze generation;
- Place/terrain;
- room lifecycle;
- movement/camera;
- collectibles/coins;
- native finish/reward flow;
- Maze World UI;
- reset/replay.

CI explicitly diffs the protected foundation files and fails on drift.

## Future first learning seam — contract only

No gameplay implementation is authorized yet.

When Phase 0 target-device acceptance is available, the first learning feature
should be a **single removable bonus checkpoint** tied to a natural Maze World
interaction rather than the native finish.

Preferred contract:

1. Native Maze World remains fully completable if the adapter is disabled or fails.
2. Touching one designated learning checkpoint requests one server-selected question.
3. Client receives only sanitized `clientView`.
4. Correct answer awards learning evidence / future Pip bonus and immediately resumes play.
5. Wrong answers use clue/support/model recovery and never trap movement indefinitely.
6. Native Maze World finish, coin reward, finish screen, return-to-lobby, and replay remain unchanged.
7. The first seam must pass acceptance before any second checkpoint is added.

Verdict: **STANDALONE PHASE-1 PREP READY; GAMEPLAY INTEGRATION NOT AUTHORIZED.**
