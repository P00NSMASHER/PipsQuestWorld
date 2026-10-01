# High School Swarm Protocol

## Resource path
- GitHub/cloud first for repository reads/writes, branches/PRs, CI/artifacts, static/headless tests, coordination, and ordinary source work.
- Local-only evidence is exceptional: record `LOCAL_ONLY_REQUIRED` with the exact check and reason, batch it, and keep it background/headless.
- Never spend money or publish Roblox without an explicit separate user instruction.
- Never weaken tests, fabricate evidence, broaden credentials/authority, or import retired/noncanonical product code merely to move faster.

## Canonical product direction
The canonical product is the original feature-equivalent Roblox high-school rebuild using original code and original/properly licensed assets. Retired Maze/Pips, Brookhaven projection, and licensed-exact RHS branches are noncanonical unless the Control Tower explicitly changes direction.

## Throughput mode
- Maximize useful parallel output. There is NO producer WIP cap and no ACTIVE-only gate for work that stays inside a lane's exclusive ownership.
- Every enabled producer should keep building independent, contract-safe work every run until its owned release surface is complete.
- A producer may make multiple coherent tested commits in one run when time/tool budget permits. Do not stop after one slice if another independent owned slice is ready.
- Upstream dependencies gate only the adapter/binding that truly consumes the upstream contract. They do NOT block standalone engines, deterministic tests, content packs, validators, persistence cores, mobile components, or other work that can be built without guessing the upstream interface.
- When an upstream contract is unavailable, build the largest useful isolated component that does not invent that contract, then continue with another independent owned item.
- NOOP is reserved for genuinely complete work, unchanged support evidence, or a real tool/safety blocker. Do not NOOP merely because another lane is incomplete.
- Status-only commits are forbidden.

## Shared state
- `coordination/HIGH_SCHOOL_SWARM_STATE.json` on `coordination/high-school-control-tower` tracks canonical lineage, exact SHAs, current release blocker, stage readiness, rights status, and next integration milestone.
- Roblox High School Control Tower is the sole writer of shared state.
- Shared state coordinates lineage and readiness; it MUST NOT be used to idle otherwise-independent producers.
- If state is missing/stale/contradictory, support lanes repair/report the evidence path and producers continue only work that is safely isolated by their file ownership and does not depend on the disputed value.
- Support lanes write their own exact-SHA receipts; they never rewrite shared state.

## Parallel ownership
- Foundation owns only project mapping, campus/location registry, authoritative school clock/day/period state, Foundation state seam, and foundation tests/provenance.
- Class & Education owns only standalone education/session logic plus the class adapter once Foundation contracts are available.
- Content QA owns only original/sanitized content and content validators.
- Progression & Mobile owns only progression/persistence and mobile/read-only presentation; it may build isolated cores before upstream binding is available.
- QA/Contract owns validation and QA-owned harnesses, not producer semantics.
- Integration owns the canonical integration candidate and mechanical conflict resolution only.
- Smoke owns post-integration headless verification only.
- Release/Package owns deterministic packaging/readiness only.
- DevEx owns CI/automation/evidence infrastructure only.
- Do not create duplicate school clocks/day loops, class authorities, answer/grade authorities, progression authorities, persistence writers, or overlapping product-file ownership.

## Interface gates, not work gates
Foundation -> Class adapter -> Progression binding -> Integration -> Release remains the semantic dependency order.
That order restricts only the dependent binding. It does not serialize independent implementation or tests.
Content, standalone Education Core, isolated progression/persistence core, mobile components against read-only local models, QA harnesses, DevEx, and provenance work should proceed in parallel.

## Evidence and CI
- Every producer commit should carry deterministic tests/checks appropriate to the changed surface.
- All actionable receipts identify branch, exact commit SHA, evidence fingerprint, checks/results, and remaining integration requirements.
- CI must run on live canonical producer heads without requiring a merge merely to obtain evidence.
- Reuse exact-head PASS evidence when unchanged, but do not let receipt-writing block product work.
- QA should evaluate every changed independent surface in a run, not stop after the first unrelated blocker.
- Integration may maintain a continuously updated candidate from producer heads that pass their own deterministic checks and contract checks; release readiness remains fail-closed.
- Smoke should report all independently reproducible blockers discovered in one pass rather than stopping after the first when continued checks are safe.
- Packaging may be exercised early on non-release candidates to detect deterministic packaging defects; only the final READY verdict requires all release gates.

## Rights/provenance
- Original or properly licensed assets/code only.
- Rights/provenance remains explicit and tied to exact candidate lineage.
- Retired/noncanonical branches may be inspected as evidence but never silently become canonical product code.

## Failure discipline
- Fix reproducible root causes instead of disabling lanes or weakening tests.
- Preserve legitimate concurrent work; do not overwrite another lane's branch/files.
- If a tool write fails, try another GitHub-native supported write path when available before declaring blocked.
- Runtime/device assertions that cannot be obtained cloud-side remain `LOCAL_ONLY_REQUIRED`; never guess them.
