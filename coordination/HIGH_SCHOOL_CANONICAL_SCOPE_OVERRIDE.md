# Pip High Canonical Scope Override

This file records the current user-specified canonical scope and coordination override for the high-school swarm. It governs when older protocol/state wording conflicts.

## Canonical target
- Canonical product: **Pip High**, built as one progressive effort toward exact player-facing parity with the original/Legacy Roblox High School experience.
- Canonical runtime/test root: `school/**` only.
- The parity target is rebuilt forward on the current certified Pip High lineage. Retired Maze/PipsQuest, StarBlox/Brookhaven, RHS-exact/licensed-exact, `game/**`, old `feat/*`, retired worktrees/branches, and Roblox places titled StarBlox remain historical-only and must not be reopened as runtime candidates or merged into canonical WIP.
- Parity means matching the approved reference baseline's visible layout, navigation flow, school-day behavior, class interactions, HUD/presentation, free-roam/after-school loop, and other verified player-facing systems while preserving the canonical server-authoritative progression/persistence contracts.

## Progressive build order
0. **Certified core loop — COMPLETE:** spawn -> authoritative school clock/period -> attend class -> server-authoritative activity -> exactly-once progression -> free roam -> restored progression. Canonical exact head: `b44cff4c64843001b178a6f6bd4aacabecfee30c`.
1. **Campus + presentation parity:** school/campus geometry and landmarks, spawn/navigation flow, then HUD/mobile presentation against stable Foundation interfaces.
2. **School-day/class parity:** full period routing, attendance/class entry/exit behavior, subject activities, and class feedback using the same authorities already present.
3. **Free-roam/after-school parity:** social/world interaction loop and verified non-class locations without creating duplicate clocks, progression writers, or parallel runtimes.
4. **Remaining verified Legacy systems:** add one externally observable system at a time from the approved parity checklist; each slice must integrate and certify before the next expands.
5. **Readiness:** exact-head smoke, persistence/mobile/performance checks, deterministic packaging/readiness. Roblox publishing still requires a separate explicit user instruction.

## Worker coordination
- **Foundation — current upstream producer:** Stage 1A campus/spawn/location/navigation parity only. It owns geometry/location registry and Foundation navigation contracts; it does not own HUD, class authority, progression, or persistence.
- **Progression & Mobile — current downstream producer:** Stage 1B HUD/mobile presentation parity only, isolated behind the existing stable Foundation/Class read interfaces. It must not guess or duplicate campus, class, clock, grading, or persistence semantics.
- **Class & Education:** no parallel product expansion during Stage 1. Prepare narrow parity tests/content mappings for Stage 2 against the existing class interfaces; become the next producer only after Stage 1 integration is certified.
- **Content QA:** maintain the shared reference/parity checklist and approved asset/provenance mapping; no competing runtime.
- **QA/Contract:** maintain deterministic contracts/harnesses for each active parity slice; never implement producer semantics.
- **Integration:** consume at most the active producer candidates, one gate at a time, into the same canonical `school/**` lineage.
- **Integration Smoke:** certify each new canonical exact head; a new commit invalidates old downstream certification until the new exact head passes.
- **Release/Package:** wait for the requested parity milestone; package/readiness only, never publish without explicit user instruction.
- **DevEx:** CI/evidence infrastructure only; do not create product features.

## WIP discipline
The existing cap of three unintegrated product candidates remains hard: canonical base + one upstream producer + one downstream producer behind a stable interface. All other workers perform cheap delta checks, tests/harnesses, reference/content/provenance preparation, or `WAITING_*` only. Commit/receipt count is never a success metric; playable parity advancement is.

## Worker-wide coordination override
Every canonical high-school lane MUST read and follow `coordination/HIGH_SCHOOL_GITHUB_WRITE_POLICY.md`.

`coordination/HIGH_SCHOOL_SWARM_STATE.json` remains a small manifest. Mutable state lives in the authoritative shards under `coordination/state/**`, while the local-machine lease remains `coordination/HIGH_SCHOOL_LOCAL_MACHINE_LEASE_V2.json`. Workers update only the smallest owning shard.

A platform safety rejection before GitHub accepts a mutation is `CONNECTOR_SAFETY_DENIAL`, not a GitHub permission/branch-protection failure. Never retry an identical blocked payload or replay the same full content through blob/tree/commit/ref.

Durable changes are branch/PR-first from an exact live base SHA. Never weaken tests/protections, use the laptop as a GitHub-write workaround, spend money, publish Roblox, broaden authority, or mutate any Roblox automation definition to bypass a write failure.
