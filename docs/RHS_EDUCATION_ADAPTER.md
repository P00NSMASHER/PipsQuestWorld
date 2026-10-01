# RHS Education Adapter — Staged Core

This branch stages only the reusable, server-authoritative education engine for the licensed archived ROBLOX High School foundation.

It does **not** modify `rhs/working/ROBLOX High School.rbxl`, create a replacement campus, replace RHS UI, add remotes, change the school clock, change rewards, or publish anything.

## Why this is separate

The exact RHS compatibility build remains the acceptance foundation. Runtime smoke must prove the original game first. Educational behavior will be additive and removable after that proof.

The old standalone Pip High branch also contained a generated `CampusBuilder`, custom school HUD, custom schedule loop, and replacement world. Those pieces are intentionally excluded here.

## Engine contract

`rhs/education/EducationEngine.lua` owns only deterministic activity/session logic:

- validates activity schemas;
- keeps `correctIndex`, hints, explanations, and misconception maps server-side;
- returns client-safe activity views with prompt + choices only;
- supports idempotent submissions;
- tracks ephemeral attempts/history;
- adapts a session-local difficulty target;
- owns no Roblox services, world state, persistence, remotes, scoring, or UI.

## Integration boundary

Future runtime integration must be a thin adapter around proven RHS systems. It should:

1. observe an existing RHS class/session event;
2. open an education session on the server;
3. send only client-safe activity data;
4. validate answers server-side;
5. return feedback;
6. close cleanly without blocking the original RHS class flow.

It must **not** replace:

- the RHS map or classroom geometry;
- `Time_ScheduleScript` / original bell flow;
- existing RHS movement/camera;
- original HUD or school navigation before runtime proof;
- existing persistence or economy semantics.

## Current state

- pure engine staged: yes;
- deterministic tests: yes;
- injected into RHS binary: **no**;
- runtime adapter: **no** — PR #19's minimal class activity is intentionally separate from this reusable engine;
- Roblox Studio proof: **no**.

The reusable engine remains staged only. PR #19 now supplies the minimal RHS-native class-activity seam and is headlessly green, but broader engine integration must still wait for Roblox Studio runtime Gates A/B.
