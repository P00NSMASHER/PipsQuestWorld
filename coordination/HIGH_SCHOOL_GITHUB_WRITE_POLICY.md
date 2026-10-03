# Pip High GitHub Write Safety Policy

This policy applies to **every canonical Pip High / Roblox high-school worker lane**. It is coordination policy only; it does not change any Roblox task definition, schedule, or enablement.

## Required write path
1. GitHub/cloud first. Never use PAAM-L044, Remote Desktop Commander, Roblox Studio, or another local machine for routine repository or coordination writes.
2. Read the live target branch head and the current blob SHA for every file that will be changed.
3. For durable source or coordination changes, create a temporary branch from the exact live base SHA, make the narrow change there, open a PR to the intended base branch, inspect the exact PR head, and use the repository's normal protected integration path.
4. Never weaken tests, branch protections, review requirements, or exact-head evidence to make a write easier.
5. Never spend money, publish Roblox, broaden credentials/authority, or mutate any Roblox automation definition as a write-path workaround.

## Small-payload rule
- Mutable coordination state is sharded under `coordination/state/**`.
- `coordination/HIGH_SCHOOL_SWARM_STATE.json` is a small manifest/index, not a monolithic mutable state payload.
- Change only the smallest authoritative shard that owns the field being updated.
- The live local-machine lease remains `coordination/HIGH_SCHOOL_LOCAL_MACHINE_LEASE_V2.json`; do not duplicate its mutable lease body into another state file.
- Lane receipts remain lane-owned and exact-SHA scoped. Do not copy logs, large evidence bodies, or unrelated state into them.
- Protocol/rule documents are not state stores. Do not rewrite a large policy document merely to advance a SHA, WIP counter, lease status, blocker, or playable-stage pointer.

## Connector safety-denial classification
If a GitHub mutation returns a platform message equivalent to `blocked by OpenAI's safety checks` before GitHub accepts the mutation:
- classify it as `CONNECTOR_SAFETY_DENIAL`, **not** a GitHub permission failure, branch-protection failure, stale-SHA conflict, or CI failure;
- do not retry the same or semantically identical full-file payload;
- do not fan out into blob/tree/commit/ref writes carrying the same blocked content;
- do not fall back to a local machine;
- preserve the exact live base SHA, target path, intended minimal diff, and unblock condition so a later supported writer or a human GitHub edit can apply it;
- make no status-only commit/comment merely to record the denial.

A real GitHub error must retain its real class (for example permission denied/403, stale SHA/conflict/409, validation/422, rate limit, or branch/ruleset rejection). Do not relabel those as safety denials.

## Retry budget
- Identical safety-denied payload: **0 retries**.
- A different supported GitHub action may be attempted only when it materially reduces or changes the payload/risk surface and still follows repository protections.
- After a confirmed `CONNECTOR_SAFETY_DENIAL`, return the lane to useful cloud-safe work or `WAITING_CONNECTOR_WRITE_PATH` with the exact unblock condition. Never invent work to fill the run.

## Exact-head and WIP discipline
Live branch head + exact-head CI outrank receipts. Any new commit invalidates downstream certification until the new exact head is green. The canonical product root remains `school/**`; retired Maze/PipsQuest, StarBlox/Brookhaven, RHS-exact/licensed-exact, `game/**`, old `feat/*`, and parallel retired runtimes never become fallback write targets.

This policy is mandatory for Control Tower, Foundation, Class & Education, Content QA, Progression & Mobile, QA/Contract, Integration, Integration Smoke, Release/Package, DevEx, and any future canonical Pip High lane.

## Worker-wide connector reliability preflight
This section is mandatory for every canonical Roblox worker before its first GitHub mutation in a run.

1. Discover/read the exact connected GitHub action schema for the object being changed. Use the object-specific action, not a generic mutation.
2. Read the live target branch/head and current blob/object identity immediately before the write.
3. Perform one mutation at a time. Never parallelize writes to the same object or send unrelated mutations together.
4. Keep mutation payloads minimal: no raw tool dumps, long logs, copied CI output, unrelated state, binary/base64 data, secrets, or duplicated context in commit messages, PR bodies, comments, or reviews. Point to SHA/run/PR IDs instead.
5. New text file: use create_file on the lane branch. Existing text file: use update_file with the exact current blob SHA and preserve unrelated bytes/formatting. Do not rewrite a large file merely to record status or evidence that can live in a smaller owned receipt/fixture.
6. PR creation, issue/PR comments, reviews, and merges use their dedicated connector actions with the exact discovered schema. A bookkeeping comment should be concise and consolidated.
7. If a mutation is rejected as CONNECTOR_SAFETY_DENIAL, the denial is specific to that object/action/payload. It is not evidence that GitHub or every worker is blocked. Do not retry the same or semantically equivalent payload, do not replay it through blob/tree/commit/ref, and do not use a laptop/browser workaround.
8. Continue any independent assigned work after a denial. Optional receipt/comment failure is non-blocking unless that exact object is a formal gate.
9. Do not carry a prior denial forward as a blocker when currentBlockers is empty. A later attempt on the same object is allowed only after a material input changes, such as base/head SHA, target blob SHA, intended content, or the supported action schema.
10. Schema errors, 403/409/422 responses, rate limits, branch protection, CI failures, and transport errors are not CONNECTOR_SAFETY_DENIAL. Classify and repair them through the normal supported path.
