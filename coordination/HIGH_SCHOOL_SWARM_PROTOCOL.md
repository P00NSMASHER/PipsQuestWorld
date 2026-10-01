# High School Swarm Protocol

## Resource path
- GitHub/cloud first.
- Never use Remote Desktop Commander or PAAM-L044 for routine repository/status/coordination reads, branches/PRs, CI/artifacts, static/headless tests, or ordinary source work.
- Local-only evidence must be recorded as `LOCAL_ONLY_REQUIRED` with the exact check and reason. Do not poll the machine.
- Any local-only work must remain background/headless. Never foreground Roblox Studio or another GUI.
- Never spend money, publish Roblox, weaken tests/gates, broaden credentials/authority, or change task schedules/enablement.

## Canonical product direction
The canonical product is the original, feature-equivalent Roblox high-school rebuild using original code and original/properly licensed assets. Retired Maze/Pips, Brookhaven projection, and licensed-exact RHS branches are noncanonical unless the Control Tower explicitly changes direction in shared state.

## Shared state authority
- `coordination/HIGH_SCHOOL_SWARM_STATE.json` on `coordination/high-school-control-tower` is authoritative for CURRENT_RELEASE_BLOCKER, canonical branches/exact SHAs, ACTIVE producers, support lanes, deferred lanes, rights status, and the next measurable milestone.
- Roblox High School Control Tower is the sole writer of the shared state.
- Every other lane must read protocol + shared state first and fail closed/NOOP if shared state is absent, stale, contradictory, or SHA-mismatched.
- Support lanes write their own receipts; they never rewrite shared state.
- Bootstrap rule for the Control Tower: if this protocol exists but shared state is absent, the Control Tower must reconstruct and write shared state from live GitHub heads/PRs/CI before downstream producer work is activated.

## Dependency order
Foundation -> Class/Education -> Progression/Mobile -> QA/Contract -> Integration -> Smoke -> Release/Package.
Content QA is schema-aware support and must not invent upstream contracts.

## Evidence contract
- All actionable receipts identify branch, exact commit SHA, evidence fingerprint, commands/checks, result, and one blocker owner with one measurable exit criterion when blocked.
- Reuse exact-head PASS evidence when the fingerprint is unchanged.
- Never accept stale receipts merely because they are green.
- Integration/release evidence must resolve to one consistent canonical lineage.
- CI/evidence plumbing must be GitHub-visible and obtainable without PAAM-L044 unless the evidence is inherently runtime/device-only.

## Ownership and duplicate-work prevention
- Each product surface has one owner at a time.
- Do not create duplicate school clocks/day loops, class authorities, answer/grade authorities, progression authorities, persistence writers, or integration candidates.
- Downstream lanes do not implement around an upstream blocker.
- Semantic conflicts return to exactly one producer owner; integration resolves only mechanical conflicts with unambiguous intent.

## Rights/provenance
- Original or properly licensed assets/code only.
- Rights/provenance must be explicit and tied to the exact candidate lineage.
- Retired/noncanonical branches may be inspected as evidence but must not silently become canonical product code.

## Failure discipline
- Fix reproducible root causes rather than disabling lanes or weakening tests.
- Status-only churn is forbidden.
- A lane with no eligible changed work returns NOOP and remains enabled.
- Runtime/device assertions that cannot be obtained cloud-side are `LOCAL_ONLY_REQUIRED`, never guessed or fabricated.
