# Development Workflow

## Core rule

**Player experience is the score.**

Architecture, test count, branch activity, and code volume do not count as progress unless they improve a verified player experience or prevent regressions.

## Protected integration flow

`main`  
Release-quality, QA-accepted builds only.

`develop`  
Sole integration branch. Only the Integrator lane merges verified feature work here.

Feature branches:
- `feat/maze-core`
- `feat/education-engine`
- `feat/learning-gates`
- `feat/pip-rewards`
- `feat/mobile-ux`
- `qa/gameplay`
- `content/emma-schoolwork`

Baseline:
- `baseline/maze-world-pristine`

## Worker rules

1. Work only on the assigned branch.
2. Never push directly to `main` or `develop`.
3. Never merge your own branch.
4. Do not rewrite unrelated systems.
5. Preserve failures; do not weaken acceptance checks to obtain a pass.
6. Update `HANDOFF.md` before handing work to the Integrator.
7. Report separately:
   - implemented
   - actually tested
   - not tested
   - known failures
8. Never call something playable/polished/ready from code inspection alone.

## First milestone

One fun educational maze:

spawn → meet Pip → enter maze → collect → learning gate → answer → gate opens → finish → reward → replay.

No broad feature expansion until this loop is visibly good.
