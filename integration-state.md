# Pip High Integration State

STATUS: BLOCKED
CANONICAL_PRODUCT: original feature-equivalent Roblox high-school life game
CANONICAL_BRANCH: rebuild/high-school-foundation
CANONICAL_SHA: 87658f31ebf2a78f922cbcb47a1948e0538384a6
ELIGIBLE_FINGERPRINT: eligible-ready=[]
INTEGRATED_PRODUCER_SHAS: none
FINAL_INTEGRATOR_SHA: none

## Cloud-first review

The Maze World / PipsQuest release path is retired. GitHub/cloud review only; no Remote Desktop or PAAM-L044 access was used.

Canonical foundation:
- rebuild/high-school-foundation `87658f31ebf2a78f922cbcb47a1948e0538384a6`
- active project: `school/default.project.json`
- active source root: `school/`
- active mapped gameplay is foundation-only: SchoolConfig, CampusBuilder, FoundationBootstrap
- legacy Maze World under `game/` is frozen historical material and is not an eligible source

Current relevant producer heads reviewed:
- pivot/school-life-foundation `aee67f5c83dc3e765758e2b73d190f446cfc38c6`
- feat/school-life-pivot `883fa92583e58791443798330d8b61d22807df62`
- fix/school-life-answer-leak `145d91c25cf39f108f271e43c9359862900be7e3`
- fix/school-life-mobile-class-modal `a45a47b9b6c5cd01e3514f764bb7afde87f45330`
- qa/gameplay `63782d52e0515cce9aeaabea8b8406b05cf24134` — stale Maze-era QA evidence
- coordination/contract-guardian `e751135bce4afc6bc80d8aa23b55a1e4f58c3421` — stale Maze-era contract evidence
- coordination/high-school-contract-guardian has no current high-school review commit

Open PR review:
- PR #16 “Rebuild from licensed exact ROBLOX High School baseline” is REJECTED from the canonical path. It intentionally imports an exact historical implementation and is incompatible with the current original-code / original-presentation rule.

## Rights / provenance verdict

Canonical foundation: PASS for current active mapped foundation scope.

Evidence:
- README and DEVELOPMENT explicitly require original code, layouts, UI, names, and assets (or clearly licensed material).
- docs/PIP_HIGH_PIVOT.md explicitly forbids importing, scraping, decompiling, tracing, or reconstructing another Roblox game's protected implementation.
- active foundation code is procedural first-party Lua and contains no mapped third-party asset IDs.
- `scripts/verify-high-school-foundation.py` rejects `rbxassetid://` in the active foundation and keeps QuestionBank / leaderstats / client UI out of the foundation project.

`UPSTREAM.md` still names Maze World as the primary foundation. That receipt is stale under the current product law and is not consumed as canonical evidence.

## Dependency / authority review

Required dependency order:
Foundation -> Class Loop/Education -> Progression/Persistence -> Mobile UX -> optional Social/Customization/Vehicles/Housing -> Contract Guardian -> QA -> Integration.

Foundation is the only currently eligible canonical layer.

The existing inactive `school/src/server/SchoolLoop.server.lua` on the foundation branch is NOT eligible to activate as-is because it owns a second independent school clock (`periodIndex`, `periodStartedAt`, bell loop) while `FoundationBootstrap.server.lua` already owns the authoritative period clock.

The school-life producer family is also NOT eligible to merge directly:
- `fix/school-life-answer-leak` / `feat/school-life-pivot` create their own world/config/runtime authority.
- their server runtime owns a separate `phaseIndex` / `phaseStartedAt` clock and its own progression/persistence model.
- direct integration would create duplicate school clocks, duplicate progression authority, and competing campus/runtime semantics.

Owner for the semantic conflict: Class Loop / Education producer.

Required producer contract before the next integration attempt:
1. Layer onto `FoundationBootstrap` as the single school-clock authority.
2. Consume authoritative period/day state instead of starting another clock.
3. Keep correct answers server-only; no client answer key.
4. Add class/education behavior without replacing CampusBuilder or creating a second world authority.
5. Keep progression hooks additive; persistence remains a later layer.
6. Commit one exact READY SHA with deterministic static/headless tests.

Mobile UX `a45a47b9b6c5cd01e3514f764bb7afde87f45330` is DEFERRED because its base is the parallel school-life architecture and Progression/Persistence has not yet been integrated onto the canonical foundation.

## Contract / QA

No current Contract Guardian PASS exists for canonical SHA `87658f31ebf2a78f922cbcb47a1948e0538384a6` plus a compatible Class Loop/Education producer SHA.

No current QA PASS exists for that same exact candidate.

Existing Contract Guardian and QA receipts are Maze-era/stale and must not be consumed.

## Verification

No combined integration head was created, so the deterministic combined test was not rerun.

The canonical branch contains `.github/workflows/school-pivot-ci.yml`, but the available exact-head GitHub commit status for `87658f31ebf2a78f922cbcb47a1948e0538384a6` currently exposes no completed PR-triggered run. Do not claim CI green for this exact head without a matching run.

LOCAL_ONLY_REQUIRED: none at this stage. The current blocker is fully established by GitHub/source evidence. Studio/device work is deferred until a cloud-eligible candidate reaches the runtime gate.

## Result

BLOCKED.

Reason: no committed READY Class Loop/Education unit layers onto the single canonical foundation clock without introducing parallel runtime/progression authority, and there is no exact-head Contract Guardian PASS or QA PASS.

No merge to main. No Roblox publication. No spend. No desktop access.
