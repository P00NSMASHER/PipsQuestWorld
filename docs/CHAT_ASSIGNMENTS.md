# Parallel Chat Assignments

Every chat works on exactly one branch.

## 0 — Integrator
Branch: `develop`

Responsibilities:
- review worker handoffs
- integrate one verified branch at a time
- rebuild after every integration
- run integration smoke tests
- revert regressions
- maintain STATUS.md

Cannot:
- casually implement feature work
- merge several unverified branches together

## 1 — Maze Core
Branch: `feat/maze-core`

Owns:
- pristine Maze World baseline
- movement / maze generation / rounds
- collectibles
- removal of Robux/gamepass monetization
- noncommercial progression foundation

Cannot:
- own question content
- redesign mobile UX

## 2 — Education Engine
Branch: `feat/education-engine`

Owns:
- generic question schema
- question bank loader
- answer checking
- hints
- subject/skill metadata
- repeat avoidance
- difficulty metadata

Cannot:
- own maze/world code

## 3 — Learning Gates
Branch: `feat/learning-gates`

Owns:
- in-world question gates
- physical answer choices
- correct-answer progression
- wrong-answer friendly retry/hints

Blocked until Maze Core + Education Engine expose stable interfaces.

## 4 — Pip & Rewards
Branch: `feat/pip-rewards`

Owns:
- Pip companion
- follow/reaction behavior
- cosmetics
- trails
- reward chest/reveal
- visible reward feedback

## 5 — Mobile UX
Branch: `feat/mobile-ux`

Owns:
- phone HUD
- touch targets
- menu visibility
- screenshots
- visual composition
- first-minute clarity

Hard rule: normal roaming should show mostly WORLD, not UI.

## 6 — QA
Branch: `qa/gameplay`

Owns:
- runtime smoke tests
- movement tests
- maze start/finish
- collectible proof
- educational gate flow
- saving/rejoin
- mobile acceptance

QA never weakens acceptance criteria to accommodate a defect.

## 7 — Emma Content
Branch: `content/emma-schoolwork`

Owns data only:
- math
- spelling
- vocabulary
- reading comprehension
- faith/religion
- science/social studies

Cannot:
- modify gameplay code
