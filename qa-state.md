# QA State — RHS School-Life

Verdict: **BLOCKED**

QA cycle: `rhs-school-life-qa-3ffa9b75`

QA fingerprint: `sha256:6cd8196fc9c1541da2b59470cc2c098e5b0224254a9e8ca9b868192a55b79d50`

## Exact candidate

- Producer PR: #16 — `rebuild/rhs-licensed-exact`
- Producer SHA: `3ffa9b75f18f51fc26feb0b1e3ec03862b46e5e3`
- Working build SHA-256: `04efd02d60dbf2388c230402888a21f0f3240efdf1b8971abcb0bc582b4ad8c4`
- Rights/licensing: **VERIFIED BY USER**; licensing is not a QA blocker for this cycle.

## Contract verdict consumed

- Contract review blob: `c8fab1af0a50160d7e1063e4208074509518a58d`
- Recorded verdict: **BLOCKED**
- Recorded review target PR head: `111d91a31bbc7f2820b6bbe86f99fbc6e1426f63`
- Status for this cycle: **STALE / SUPERSEDED TARGET**. That review blocks replacement of Maze World, but the current executive QA target explicitly retires Maze World and accepts the rights-verified RHS school-life direction. It is therefore consumed as historical/stale evidence, not as the current release blocker.

## Headless coverage run

Existing exact-producer-head guards are green:

- RHS Baseline Integrity — run `36772699702` — PASS
- RHS Structural Parity — run `36772699713` — PASS
- RHS Compatibility Audit — run `36772699743` — PASS
- RHS Startup Risk Audit — run `36772699813` — PASS
- RHS Runtime Side-Effect Audit — run `36772699712` — PASS

QA-only cloud branch: `qa/rhs-school-life-3ffa9b75`

- Diagnostic source: `qa/rhs-school-life-diagnostic.py`
- Diagnostic report blob: `25cd601b8e601e53973e9127ded8853398995721`
- Regression: `qa/test_rhs_class_activity_contract.py`
- Regression blob: `e83878907a211e7f2933e3b550d28908690f2697`
- Tightened diagnostic run `36783129256`: PASS
- Regression run `36783353211`: **FAIL at "Enforce server-authoritative class activity"**, as expected for the reproduced defect.

## Reproduced release blocker

The exact candidate has a coherent school clock/class-location skeleton:

- server `ServerScriptService/Time_ScheduleScript`
- server `ServerScriptService/ClassroomZones`
- client schedule/class display surfaces

The tightened exact-binary diagnostic found:

- schedule candidates: present
- class-flow candidates: present
- client/replicated answer-key candidates: 0
- **strict server-authoritative class-activity candidates: 0**

The only general server question hits are unrelated administrative/item/analytics scripts. None qualifies as a server-side class/subject flow that also owns question semantics and grade/points authority.

This fails the current acceptance requirement for **one concise server-authoritative class activity with no client-known answer key**.

## Single defect owner

**Owner: RHS school-life / class-activity producer lane (PR #16).**

Exit criterion: add one minimal class activity attached to the existing school schedule/class flow where the server owns the question answer key and completion/grade award, the client receives only display-safe prompt/choices, and one completion can update grade/points at most once.

No other owner is assigned for this root cause.

## Deferred checks

Stopped at the first release-blocking root cause. No broad unchanged suite was rerun.

`LOCAL_ONLY_REQUIRED` — deferred, **not invoked**:

1. exact-candidate Roblox runtime spawn/free-roam and class entry/exit;
2. actual save/rejoin idempotency across a Roblox runtime session;
3. iPhone 16 landscape controls/HUD usability.

Reason: these assertions require Roblox Studio/device/runtime behavior and cannot be proven by static/headless GitHub analysis. They are deferred until the class-activity blocker is fixed and can be batched into one local-only session.

## Safety / execution record

- GitHub/cloud first: **YES**
- PAAM-L044 / Remote Desktop Commander invoked: **NO**
- Studio/GUI foregrounded: **NO**
- Producer code modified by QA: **NO**
- Tests weakened/deleted: **NO**
- Merge: **NO**
- Publish/deploy: **NO**
- Spend/purchase authorization: **NO**
