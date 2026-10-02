# Pip High Canonical Scope Override

This file records the current user-specified canonical scope and coordination override for the high-school swarm. It governs when older protocol/state wording conflicts.

## Canonical target
- Canonical product: **Pip High**, built as one progressive effort toward exact player-facing parity with the original/Legacy Roblox High School experience.
- Canonical runtime/test root: `school/**` only.
- The parity target is rebuilt forward on the current certified Pip High lineage. Retired Maze/PipsQuest, StarBlox/Brookhaven, RHS-exact/licensed-exact, `game/**`, old `feat/*`, retired worktrees/branches, and Roblox places titled StarBlox remain historical-only and must not be reopened as runtime candidates or merged into canonical WIP.
- Parity means matching the approved reference baseline's visible layout, navigation flow, school-day behavior, class interactions, HUD/presentation, free-roam/after-school loop, and other verified player-facing systems while preserving the canonical server-authoritative progression/persistence contracts.

## Progressive build order
The current Phase-1 goal is the exact live Roblox High School clone on the canonical `school/**` / `rebuild/high-school-foundation` lineage. Second-grade/Emma/STAR/K-8 content is `DEFERRED_PHASE_2` until the clone is functionally complete and the user explicitly advances phases.

After the certified café/economy slice, player-facing priority is:
1. vehicles;
2. housing/property;
3. avatar/outfit/customization and shopping;
4. jobs beyond café;
5. social/free-roam;
6. animations/presentation;
7. mobile polish.

Live parity evidence may promote a more critical regression ahead of that sequence. Release/Package is a deterministic checkpoint, never product completion.

## Pipeline and worker coordination
Control Tower coordinates all canonical workers through `coordination/state/WIP.json`. Every lane consumes the same exact canonical product SHA and the same private-server target from current Release/publish evidence.

Semantic order is:
`Control Tower -> producer/support preparation -> QA -> Integration -> Smoke -> Release/Package -> Control Tower`.

The WIP cap remains three including canonical base: one critical-path producer plus at most one non-overlapping downstream product candidate. Other lanes may receive only narrow tests/contracts/fixtures/provenance/support that materially advance the same upcoming slice. If no useful owned work exists, they use `WAIT_PIPELINE` and perform only the minimum freshness read.

Lane ownership remains unique:
- **Foundation:** world/clock/location/spawn.
- **Class & Education:** class/session/activity.
- **Content QA:** authorized fixtures/assets/provenance.
- **Progression & Mobile:** durable progression/economy/ownership/mobile read-only presentation.
- **Free Roam:** jobs/vehicles/housing/customization/social.
- **QA/Contract:** validation only.
- **Integration:** mechanical integration only.
- **Integration Smoke:** post-integration certification.
- **Release/Package:** deterministic package checkpoint only.
- **DevEx:** CI/evidence infrastructure only.

When QA, Integration, Smoke, or Release clears a stage, Control Tower immediately assigns the next highest-priority clone gap in the same run or the next run. Never leave `NEXT_PRIORITY_UNASSIGNED` when useful non-overlapping work exists.

## WIP and write discipline
Each non-wait directive identifies the exact canonical SHA/base, one measurable objective, owned paths/contracts, dependency consumed, required evidence/exit criterion, and handoff receiver. Producers never write directly to protected canonical; product edits use one current-base lane branch, exact-head CI, QA, then Integration.

If a GitHub mutation receives `CONNECTOR_SAFETY_DENIAL`, do not retry the identical payload through blob/tree/ref or local-machine workarounds. Preserve the intended diff and either pursue a different independently owned objective or record the precise denial for DevEx/Control Tower. Ordinary protected-branch rejection is not a blocker when a lane branch can be used.

The success metric is validated player-facing parity advancement per hour, not commit/receipt/run count. An unchanged worker run is expected only when its explicit WIP directive is `WAIT_PIPELINE` and there is genuinely no non-overlapping owned work.

## Worker-wide coordination override
Every canonical high-school lane MUST read and follow `coordination/HIGH_SCHOOL_GITHUB_WRITE_POLICY.md`.

`coordination/HIGH_SCHOOL_SWARM_STATE.json` remains a small manifest. Mutable state lives in the authoritative shards under `coordination/state/**`, while the local-machine lease remains `coordination/HIGH_SCHOOL_LOCAL_MACHINE_LEASE_V2.json`. Workers update only the smallest owning shard.

A platform safety rejection before GitHub accepts a mutation is `CONNECTOR_SAFETY_DENIAL`, not a GitHub permission/branch-protection failure. Never retry an identical blocked payload or replay the same full content through blob/tree/commit/ref.

Durable changes are branch/PR-first from an exact live base SHA. Never weaken tests/protections, use the laptop as a GitHub-write workaround, spend money, publish Roblox, broaden authority, or mutate any Roblox automation definition to bypass a write failure.
