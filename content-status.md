# Content Status — PAAM-L044

## Plan and schema anchor

- Base branch: `rebase/maze-world-chassis`
- Base commit: `5b898bd97c0b54033ed3a537fdaaa73ce4a308c5`
- `EXECUTIVE_PLAN.md` is not present on this base branch. This cycle follows the supplied PAAM-L044 direction plus `docs/MAZE_CHASSIS_REBASE.md`.
- Current runtime contract read from `game/src/common/education/EducationEngine.lua` and `game/src/common/education/LearningGate.lua`.
- LearningGate admits only `transfer` or `reasoning` items with difficulty >= 2, while EducationEngine keeps current `material` ahead of `star-fallback`.

## Quality batch 1

Scope: three ABVM-derived material items already eligible for the Maze World checkpoint pool. No questions were added and no STAR fallback item was promoted.

1. `abvm-b9d55008a7c4-629ea7-photo-reading-main-character-transfer-ev1`
   - Replaced implausible non-passage distractors with three named characters that all appear in the passage.
   - The player now identifies which character drives the key actions instead of spotting the only named choice.

2. `abvm-b9d55008a7c4-629ea7-photo-reading-setting-reasoning-ev1`
   - Replaced definition-style worksheet framing and joke distractors with a short passage and three grounded details.
   - Difficulty corrected from 3 to 2 while preserving DOK 2 and the stable ID.

3. `abvm-b9d55008a7c4-629ea7-photo-plural-s-es-reasoning-ev1`
   - Replaced the abstract rule prompt and implausible distractors with a brief label-edit application.
   - Distractors now represent plausible singular/plural spelling errors.
   - Difficulty corrected from 3 to 2 while preserving DOK 2 and the stable ID.

For manually reviewed replacements, stale generated `contentHash` values are omitted rather than falsely certifying changed text against an old hash.

## Static validation

- Certified bank shape preserved: 156 total questions; 36 material; 120 STAR fallback.
- Active Maze checkpoint pool preserved at 7 items; no count padding.
- Stable IDs unique across the full bank: PASS.
- Active required metadata (subject, skill, domain, difficulty, DOK, questionType, hint/scaffold, explanation): 7/7 PASS.
- Accepted answer resolves through `correctIndex` to one of exactly three unique choices: 7/7 PASS.
- Distractor misconception feedback coverage: 14/14 PASS.
- Exact normalized prompt duplicates in active pool: 0.
- Hint/scaffold exact accepted-answer leakage: 0.
- Batch ambiguity review: 3/3 PASS; each revised item has one defensible best answer and two plausible skill-relevant distractors.
- Revised prompts are brief enough for an in-world phone checkpoint.
- No copyrighted story text or answer key was introduced.
- Privacy provenance remains skill-only/equivalent with no raw images, identity, responses, teacher marks, grades, or raw worksheet text.

## Cycle boundary

Stopped after this three-item quality unit. Remaining active items and all STAR fallback items are unchanged for this cycle.
