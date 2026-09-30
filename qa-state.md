# QA State

Verdict: BLOCKED

Executive cycle: control-4-2026-09-30

Candidate fingerprint:
- control: 394570a059a8811fd960cc256fc172e9306877c0
- foundation: 87658f31ebf2a78f922cbcb47a1948e0538384a6
- integration: 384c8914a434ff6880b904517f038670a478e1bc
- contract: DEFERRED / NOT RUN

Rights status: user-confirmed verified. Licensing is not the blocker.

Exact-head QA evidence:
- active project maps SchoolConfig.lua, CampusBuilder.server.lua, and FoundationBootstrap.server.lua only;
- MainSpawn exists and is assigned as RespawnLocation;
- FoundationBootstrap owns the only mapped school day/period clock;
- CampusBuilder is the only mapped world builder;
- no client or HUD runtime is mapped at this candidate.

First release blocker:
The canonical candidate has no mapped class discovery/attendance/entry-exit controller and no mapped server-authoritative class activity. The full release path therefore cannot yet progress past foundation schedule/free-roam.

Single owner: Class Loop / Education.

Exit:
Commit one exact candidate based on 87658f31ebf2a78f922cbcb47a1948e0538384a6 that consumes Foundation clock state, owns class entry/exit/resume only, uses server-authoritative education logic without exposing the answer key to clients, emits one completion result without mutating grades/persistence, preserves CampusBuilder authority, and includes deterministic duplicate-submit/period-change coverage.

Regression action:
No new regression added because there is no canonical Class Loop/Education implementation to reproduce a code defect against.

LOCAL_ONLY_REQUIRED: none.

No laptop/Studio use. No merge, publish, purchase, deployment, or test weakening.
