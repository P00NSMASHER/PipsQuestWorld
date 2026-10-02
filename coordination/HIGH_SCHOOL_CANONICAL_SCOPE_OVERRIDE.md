# Pip High Canonical Scope Override

This file records the current user-specified canonical scope and coordination override for the high-school swarm. It governs when older protocol/state wording conflicts.

- Canonical product: original Pip High / Roblox high-school life game.
- Canonical runtime/test root: `school/**` only.
- Historical-only categories: Maze/PipsQuest, StarBlox/Brookhaven runtime projection, RHS-exact/licensed-exact, `game/**`, old `feat/*`, retired Maze/Pips worktrees/branches, and Roblox places titled StarBlox.
- Historical-only work must not consume canonical WIP, local-machine leases, QA, CI repair, packaging, release, or product-development effort.
- If historical-only evidence conflicts with the live Pip High canonical state, treat the historical evidence as stale.

## Worker-wide coordination override
Every canonical high-school lane MUST read and follow `coordination/HIGH_SCHOOL_GITHUB_WRITE_POLICY.md`.

`coordination/HIGH_SCHOOL_SWARM_STATE.json` is now a small manifest. Mutable state lives in the authoritative shards under `coordination/state/**`, while the live local-machine lease remains `coordination/HIGH_SCHOOL_LOCAL_MACHINE_LEASE_V2.json`. Workers must update only the smallest owning shard rather than rewriting a large monolithic state document.

A platform safety rejection that occurs before GitHub accepts a mutation is `CONNECTOR_SAFETY_DENIAL`. It is not a GitHub permission/branch-protection failure. Never retry an identical blocked payload or send the same full content through blob/tree/commit/ref as a workaround. Preserve the exact minimal diff and unblock condition instead.

Durable changes are branch/PR-first from an exact live base SHA. Never weaken tests/protections, use the local laptop as a GitHub-write workaround, spend money, publish Roblox, broaden authority, or mutate any Roblox automation definition to bypass a write failure.
