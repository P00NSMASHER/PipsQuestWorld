# Education Engine Executive Plan

Authority: 2026-09-30 product direction for the Maze World education layer.

## Product boundary

Maze World remains the complete game. The Education Engine is a server-side backend service invoked only by narrow Learning Gate checkpoints. When education is absent or unavailable, the Maze World game loop, geometry, movement, rooms, HUD, rewards, and progression remain untouched.

The Education Engine owns Step 4 and the education side of Steps 5-6 only: question selection, server-authoritative grading, teaching feedback, and learning-evidence semantics. It does not own world generation, movement, HUD shells, rewards, or alternate progression.

## Current milestone

Expose one brief Grade-2 encounter at a time:

`checkpoint -> one question -> answer / teaching support -> return control to Maze World`

A checkpoint must never require a five-question modal sequence unless a later committed executive plan explicitly restores that behavior.

## Content contract

The existing 156-question bank remains a compatible production input. Do not grow the bank while gameplay quality is the blocker. Selection prioritizes current school material, avoids immediate repeats, balances skills, favors transfer/application over copy-the-answer recall, and honors spaced same-skill comeback requests.

The engine rejects trivially answer-leaking multiple-choice items by default when the exact correct option is already copied into the prompt. Passage-style exceptions must opt in explicitly with `allowAnswerInPrompt = true`.

## Teaching contract

Answers are graded on the server. The client receives no answer key. First miss gives a clue, second miss gives stronger support, and only a third miss may reveal/model the answer. Wrong choices may carry misconception-specific feedback.

Only an independently correct response with no prior clue/support counts as independent mastery evidence. A correct response after a miss, a supported response, or a modeled answer is never mastery-eligible and schedules a spaced same-skill comeback opportunity.

## Acceptance for this lane

- pure/headless engine module; no Studio/GUI requirement
- no world/HUD/reward/progression construction
- one encounter per checkpoint invocation
- deterministic current-material-first selection
- deterministic no-immediate-repeat behavior
- deterministic skill balancing and transfer/application preference
- server-authoritative answer key remains private
- first-miss clue, second-miss support, third-miss modeled answer
- supported/modeled outcomes are not mastery evidence
- deterministic static/contract tests run in Node/GitHub Actions
