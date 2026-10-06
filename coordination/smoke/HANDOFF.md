# Strict runtime smoke acceptance handoff

## Lane and revision

- Responsibility: QA-owned smoke acceptance, downstream gating, and current Control Tower directions.
- Branch: `coordination/smoke-strict-acceptance-33a5a11`.
- Coordination base: `dfafaffec7cc2d4fc76762f32f751b56a3d398fb`.
- Exact product canonical: `33a5a11ba771e0bbfbc82ed40ce5417c772a2f17`.
- Review and integration must use the resulting PR's exact head and its Smoke Contract Guards check. This file does not certify its own future commit.

## Implemented

The old validator printed the acceptance marker for HOLD and the execution plan assigned PASS afterward. Draft validation now emits only `SMOKE_RUNTIME_CAPTURE_CONTRACT_DRAFT_OK`. Final acceptance requires the completed receipt, explicit strict mode, the independently reread canonical SHA, and its existing evidence directory; only that invocation can emit `SMOKE_RUNTIME_CAPTURE_PASS_OK`.

Schema 2 requires startup, every camera/reference checkpoint including C Travel, every panel including Vehicle on all three profiles, specific route observations, and matching player/state/completion identity across save and rejoin. Evidence files must remain within the canonical directory and match their recorded hashes. The same-profile C Travel screenshot can also substantiate its identical Travel-panel state; unrelated image reuse fails.

Physical mobile observations and Studio emulation remain explicit. Emulation can supply partial rendered evidence on HOLD. Full device acceptance requires observed iPhone and iPad interaction. File/signature validation does not replace independent inspection of image content or actual device behavior.

The current plan and package gate strictly revalidate the completed evidence before handoff. P2 now requires Mapped Build plus Foundation, Class/Education and Progression on both candidate and integrated canonical. WIP's stale P1 producer reservation, resolved source defect, and outdated P2 branch directions are reconciled with the current canonical.

## Actually tested

- `python3 -m unittest discover -s coordination/smoke -p 'test_*.py' -v`: 27 tests passed locally.
- Real HOLD template with `--self-test --expected-canonical 33a5a11ba771e0bbfbc82ed40ce5417c772a2f17`: draft marker only.
- `git diff --check`: passed.
- Dedicated read-only CI runs the same regression suite and draft check on the exact coordination PR head. Its PASS tests the guard, not the game.

The tests create temporary synthetic evidence for validator behavior only. They never write into the real evidence directory, alter a runtime receipt to PASS, or establish runtime/visual/device acceptance.

## Not tested and current blocker

PAAM-L044 was observed offline. Actual Roblox startup, traversal, rendered desktop/mobile comparisons, feature interaction, and save/rejoin on the canonical remain unexecuted. The real capture template remains HOLD with all checks PENDING. Package eligibility remains false and P2 remains unactivated.

The existing local-machine lease, background/GUI constraints, no-publication direction, no-spend rule, and task immutability remain prerequisites for any later device session. No game source or server authority was modified by this repair.

## Integration and next action

Independent review must verify the changed head and its CI before merging to `coordination/high-school-control-tower`. When authorized runtime access is available, execute `PR292_33A5A11_LOCAL_SMOKE_EXECUTION_PLAN.json`, preserve the completed evidence bundle, obtain independent rendered/device review, and run its strict final-validation command. Release/Package must independently repeat that command before emitting the reserved package or activating P2.

## Player-experience impact

This repair changes acceptance infrastructure. It prevents incomplete testing from being reported as a finished game and prevents workers from reopening already resolved P1 work. It does not itself change or certify what a player sees.
