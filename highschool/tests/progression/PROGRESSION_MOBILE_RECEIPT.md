# Progression & Mobile Receipt

Product code candidate: `9ee3594c48fe24ce55ba4a612c4bd8cff21bed98`
Required base: `f763b243f4ec22951f432e66f807f187c960583f`
Contract: `SAFE_PREP_PASS / UNBOUND`

## This run
- Added compact read-only mobile schedule/progression presentation with safe-area containment, 44-point minimum hit-target contract, bounded text sizing, loading/error/ready states, row caps, and obstruction guards.
- Hardened persistence restore so malformed rows fail closed and only a missing snapshot creates explicit default state.
- Added a transactional progression repository with player-scope enforcement, duplicate replay suppression, save/rejoin restore, and failed-save rollback semantics.

## Deterministic tests
- `highschool/tests/progression/progression_exactly_once_spec.lua`
- `highschool/tests/progression/progression_restore_spec.lua`
- `highschool/tests/progression/progression_repository_spec.lua`
- `highschool/tests/mobile/compact_school_panel_spec.lua`

Exact-head workflow evidence for the product code candidate: none. No workflow watches this owned `highschool/**` surface, and this lane does not edit workflow files outside ownership.

## Binding status
`WAITING_DEPENDENCY`

Authoritative shared state remains `coordination/HIGH_SCHOOL_SWARM_STATE.json@69d3987281db6303228bb93a0cf024b5919f6e71`, where Class/Education is still `ACTIVE` and has no canonical branch. PR #20 is currently at `5031708afe609e8c7ba6b33496b39869792c2b09` with Class/Education CI success, but the Control Tower has not published the authoritative Class/Education PASS/exact-SHA receipt.

Unblock condition: Control Tower records Class/Education PASS with the canonical branch and exact completion-contract SHA.

Next code slice after unblock: bind only that authoritative completion result into `ProgressionRepository`, add cross-contract duplicate/save-rejoin tests, and connect the minimum read-only mobile projection. Do not take school-clock, answer-validation, class-lifecycle, or world authority.
