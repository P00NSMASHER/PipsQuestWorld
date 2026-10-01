# High School Class & Education Contract

Base lineage: `rebuild/high-school-foundation@f763b243f4ec22951f432e66f807f187c960583f`.

This producer adds one server-authoritative class activity seam without creating another school clock, world authority, progression system, persistence writer, or UI.

## Foundation seams consumed
- Schedule is read from Foundation-owned Workspace attributes: `SchoolDay`, `SchoolPeriodIndex`, `SchoolPeriodId`, and `SchoolPeriodRoom`.
- Room location and attendance radius are read from `SchoolConfig.Rooms` and `SchoolConfig.ATTENDANCE_RADIUS`.
- Period/session exit is driven by Foundation-owned `PeriodChanged` and `SessionEnded` BindableEvents.
- No Class/Education code advances time, mutates schedule attributes, teleports players, or writes world state.

## Runtime contract
`ReplicatedStorage/SchoolFoundation/ClassEducation` exposes four RemoteFunctions:
- `GetClassState`: discovery only. Returns the current Foundation period/room, whether the period is academic, whether the player is in attendance radius, active safe activity state, and ephemeral completion count.
- `EnterClass`: server re-reads Foundation schedule and validates player location before opening exactly one activity.
- `SubmitAnswer`: server validates the current class key, room presence, submission id, and answer. Duplicate submissions are idempotent; late submissions are rejected.
- `LeaveClass`: closes the ephemeral class session immediately and returns the player to free-roam state.

The server-only `EducationEngine` holds answer keys and supports one hint/retry. After the maximum attempts, it returns the explanation and resolves the activity so a wrong answer cannot soft-lock movement or class exit.

`ClassSessionController` records an ephemeral completion marker per player/class key. A completion transition is emitted once. Replaying the completing submission returns a duplicate receipt with `classCompleted=false` and `completionAlreadyRecorded=true`.

## Explicit non-ownership
This lane does not own grades, points, rewards, persistence, mobile presentation, world geometry, integration, release, or Roblox publication.
