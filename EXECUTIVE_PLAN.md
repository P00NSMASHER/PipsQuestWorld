# Roblox High School Executive Plan

CYCLE_ID: control-4-2026-09-30
EVIDENCE_FINGERPRINT: foundation=87658f31ebf2a78f922cbcb47a1948e0538384a6; integration=384c8914a434ff6880b904517f038670a478e1bc; main=5d72ec4414757025668495cbd96d4e5908df094b
RELEASE_STATE: NOT_READY
ACTIVE_PRODUCER_WIP_LIMIT: 3
ACTIVE_PRODUCERS: 0
LOCAL_ONLY_REQUIRED: none

## Canonical product

Original-code, original-presentation Roblox high-school life game inspired by publicly observable Roblox High School / Roblox High School 2 gameplay. Maze World/PipsQuest is retired. Exact historical/proprietary implementations, ripped assets, and one-for-one proprietary presentation are excluded from the canonical path.

## Canonical foundation

- Branch: `rebuild/high-school-foundation`
- Exact SHA: `87658f31ebf2a78f922cbcb47a1948e0538384a6`
- Active Rojo surface: `school/default.project.json`
- Mapped runtime: `SchoolConfig.lua`, `CampusBuilder.server.lua`, `FoundationBootstrap.server.lua`
- Foundation owns the sole school day/period clock.
- Rights/provenance verdict for the mapped foundation surface: PASS.
- Fresh exact-head runtime evidence: not required yet.

## CURRENT_RELEASE_BLOCKER

There is no committed READY Class Loop/Education candidate that layers onto the canonical Foundation clock without creating a second school clock, second world authority, or premature progression authority.

The old `school/src/server/SchoolLoop.server.lua` is not eligible: it owns its own `periodIndex` / `periodStartedAt` bell loop and points/progression behavior. Parallel school-life branches are also ineligible because they carry competing runtime/progression ownership.

BLOCKER_OWNER: Class Loop / Education
BLOCKER_AGE: 1 control-tower cycle in the current canonical direction
STALLED: false

### Exit criterion

Produce one committed exact SHA based on `87658f31ebf2a78f922cbcb47a1948e0538384a6` that:

1. consumes Foundation day/period state rather than creating another timer;
2. owns class entry/exit/resume only;
3. invokes a pure server-authoritative Education Engine for one concise activity;
4. exposes no correct-answer key to clients;
5. emits one completion result but does not mutate grades/persistence itself;
6. preserves CampusBuilder as the sole world authority;
7. includes deterministic headless tests proving duplicate submissions and period changes cannot double-complete or soft-lock;
8. leaves an exact-SHA READY receipt.

## Dependency order

1. Foundation — COMMITTED / ELIGIBLE SOURCE CONTRACT
2. Class Loop / Education — BLOCKED / CURRENT_RELEASE_BLOCKER
3. Progression / Persistence — DEFERRED
4. Mobile UX — DEFERRED
5. Optional Social / Customization / Vehicles / Housing — DEFERRED
6. Contract Guardian — DEFERRED until an exact Class/Education candidate exists
7. QA — DEFERRED until same exact candidate has contract evidence
8. Integration — BLOCKED

## Milestones

1. school/town spawn/free-roam source seam — IMPLEMENTED, runtime not yet claimed
2. authoritative school clock/day schedule source seam — IMPLEMENTED, runtime not yet claimed
3. class discovery/attendance/entry-exit — BLOCKED by current release blocker
4. one concise server-authoritative class activity — BLOCKED by current release blocker
5. grades/points exactly-once — DEFERRED
6. save/rejoin idempotency — DEFERRED
7. usable iPhone layout — DEFERRED
8. integrated exact-SHA candidate + provenance — BLOCKED
9. runtime acceptance — DEFERRED; only then may a specific LOCAL_ONLY_REQUIRED check be recorded

## Noncanonical evidence

Draft PR #16 / `rebuild/rhs-licensed-exact` remains excluded because it intentionally preserves an exact historical Roblox High School implementation, contrary to the current original-code/original-presentation product contract.

## Next measurable milestone

A committed Class Loop/Education SHA satisfying the eight exit criteria above, followed by Contract Guardian review against the same Foundation + Class/Education fingerprint.
