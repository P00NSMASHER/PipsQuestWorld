# High School Swarm Protocol

## Resource path
- GitHub/cloud first for repository reads/writes, branches/PRs, CI/artifacts, static/headless tests, coordination, and ordinary source work.
- Local-only evidence is exceptional: record `LOCAL_ONLY_REQUIRED` with the exact check and reason, batch it, and keep it background/headless.
- Never spend money or publish Roblox without an explicit separate user instruction.
- Never weaken tests, fabricate evidence, broaden credentials/authority, or import retired/noncanonical product code merely to move faster.

## Canonical product direction
The canonical product is the original feature-equivalent Roblox high-school rebuild using original code and original/properly licensed assets.
Retired Maze/Pips, Brookhaven projection, and licensed-exact RHS branches are noncanonical unless the user explicitly changes direction.

## Primary optimization target
Optimize for **validated playable progress on the canonical game**, not commit count, receipt count, branch count, or hourly activity.

Current vertical-slice KPI:
`spawn -> authoritative school clock/period -> arrive/attend one class -> one server-authoritative activity -> exactly-once progression result -> return to free roam -> save/rejoin restores committed result`.

Work that cannot plausibly advance, validate, or unblock that slice is lower priority until the slice passes end-to-end.

## Integration-critical WIP cap
At most THREE unintegrated product candidates may consume product-code effort at once:
1. the canonical base/integration candidate;
2. ONE current upstream producer candidate on the critical path;
3. ONE downstream speculative candidate that is isolated behind a stable internal interface.

All other lanes remain enabled but must restrict themselves to cheap delta inspection, deterministic tests/harnesses, content/provenance prep, or `WAITING_UNCHANGED/WAITING_DEPENDENCY`. They must not accumulate additional unintegrated product code merely because their hourly task fired.

The Control Tower owns slot assignment. A candidate loses its slot when superseded, stale, noncanonical, or integrated.

## Canonical source root
`school/**` is the canonical runtime/test source root for the current high-school rebuild.
Do not create a second runtime tree under `highschool/**`.
Existing speculative work under `highschool/**` is reference/prep only until intentionally rehomed into `school/**` on a fresh canonical descendant with unchanged semantics and exact-head tests.
No integration candidate may map both roots into the runtime.

## Shared state
- `coordination/HIGH_SCHOOL_SWARM_STATE.json` on `coordination/high-school-control-tower` tracks canonical lineage, exact SHAs, current blocker, WIP slots, rights status, and next integration milestone.
- Roblox High School Control Tower is the sole writer of shared state.
- Live GitHub branch heads + exact-head CI are source of truth. Coordination receipts are caches/evidence, never authority over a newer live head.
- Any receipt whose recorded branch SHA no longer equals the live branch head is automatically STALE and must not authorize downstream consumption.
- Support lanes write their own exact-SHA receipts; they never rewrite shared state.

## Parallel ownership
- Foundation owns only project mapping, campus/location registry, authoritative school clock/day/period state, Foundation state seam, and foundation tests/provenance.
- Class & Education owns standalone education/session logic plus the class adapter once Foundation contracts are available.
- Content QA owns original/sanitized content and content validators.
- Progression & Mobile owns progression/persistence and mobile/read-only presentation.
- QA/Contract owns validation and QA-owned harnesses, not producer semantics.
- Integration owns the canonical integration candidate and mechanical conflict resolution only.
- Smoke owns post-integration headless verification only.
- Release/Package owns deterministic packaging/readiness only.
- DevEx owns CI/automation/evidence infrastructure only.
- Never create duplicate school clocks/day loops, class authorities, answer/grade authorities, progression authorities, persistence writers, or overlapping product-file ownership.

## Interface gates
Semantic order is:
Foundation -> Class/Education -> Progression/Persistence -> Integration -> Smoke -> Release.

Independent tests/content/harnesses may proceed in parallel, but **product-code accumulation is governed by the WIP cap**.
A downstream lane may prepare only against a stable internal interface while upstream semantics are unsettled; it may not guess upstream behavior or expand scope.

## Unchanged-fingerprint rule
When a lane's relevant exact-SHA fingerprint is unchanged:
- perform at most TWO cheap GitHub/cloud reads needed to confirm that fact;
- run ZERO broad tests;
- create ZERO branches;
- make ZERO commits;
- write ZERO status-only receipts/comments;
- report `WAITING_UNCHANGED` with the exact unblock condition.

Do not invent validator work or speculative refactors merely to avoid idleness. A scheduled run is not itself a reason to create work.

## Evidence and CI
- Every product commit must have deterministic checks appropriate to the changed surface.
- Exact-head green CI is mandatory before a downstream lane consumes a producer head.
- Any new commit invalidates prior exact-head certification for downstream consumption until the new head is green.
- Receipts identify branch, exact SHA, evidence fingerprint, checks/results, and remaining integration requirements.
- Reuse exact-head PASS evidence when unchanged.
- Receipt writing must never consume a run that still has eligible critical-path product work.
- Prefer narrow PRs containing one externally observable behavior or one contract repair. Large multi-feature PRs should be split before integration when practical.

## Noncanonical quarantine
- Retired Maze/Pips, Brookhaven, licensed-exact RHS, and superseded experimental branches may be inspected as historical evidence only.
- Open PRs on those lines must not receive new hardening, CI repair, integration, or feature work.
- They should be closed/quarantined once identified unless the user explicitly restores that direction.
- No automation may infer that an open noncanonical PR is unfinished canonical work.

## Rights/provenance
- Original or properly licensed assets/code only.
- Rights/provenance remains explicit and tied to exact candidate lineage.
- Noncanonical branches may be inspected as evidence but never silently become canonical product code.

## Failure discipline
- Fix reproducible root causes instead of disabling lanes or weakening tests.
- Preserve legitimate concurrent work; do not overwrite another lane's branch/files.
- If a tool write fails, use the documented canonical GitHub write path before declaring `WRITE_PATH_BLOCKED`.
- Runtime/device assertions that cannot be obtained cloud-side remain `LOCAL_ONLY_REQUIRED`; never guess them.

## Anti-waste control check
Each Control Tower cycle records:
- canonical playable vertical-slice stage reached;
- count of unintegrated product candidates;
- count of open noncanonical PRs;
- hours/cycles since the last end-to-end playable advancement.

If commits/PRs/receipts rise while playable-stage progress does not, reduce product WIP rather than creating more parallel implementation.

## Automation immutability
- Scheduled Roblox workers MUST NOT call task/automation management actions to enable, disable, pause, delete, rename, reschedule, or rewrite any Roblox automation, including themselves.
- Only an explicit user instruction in chat may change a Roblox task definition or enabled/schedule state.
- A blocker, completion, unchanged fingerprint, WIP cap, or WAITING_* state is never permission to disable a task.
- Control Tower coordinates through GitHub-visible shared state/objectives, not by mutating scheduled-task definitions.
- If a task-state contradiction is observed, record it as an automation defect for the user/DevEx; do not self-repair it through task mutation.
