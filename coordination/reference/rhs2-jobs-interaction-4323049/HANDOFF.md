# RHS2 jobs interaction contract

Owner: Pip High Free Roam (contract preparation only; no product-write authority in this artifact).  
Input product SHA: `43230492964ea637f69747e25a3e72d6cb268ebe`.  
Coordination evidence branch input: `2af9ad56b5ccefb3e13577e509fffc1d86ffefda`.  
Reference clip/time: C (`libfile_a5903480efe88191a87e5f98ec9729bc`) at approximately 00:12-00:22 for the Umbra's job entry, 00:20-01:02 for the purple obstacle/collection run, and 01:02-01:08 for the performance result and Jobs menu.  
Output location: `coordination/reference/rhs2-jobs-interaction-4323049/HANDOFF.md`.  
Blocker: P1 spawn/school/HUD PR #188 must complete exact-head QA, Integration, Smoke, and Package; classroom, housing, avatar, and vehicle priorities remain ahead of P6 Jobs.  
Next handoff: Control Tower retains this as future P6 evidence; Pip High Free Roam implements only after a fresh explicit producer activation; Roblox High School QA & Contract independently validates the exact candidate.

This contract records observable presentation and bounded behavior from the footage. It does not prove hidden source, remote names, job IDs, reward formulas, anti-cheat rules, item identities, checkpoint data, obstacle collision settings, backend progression, inventory delivery, or save semantics. The recording visibly includes a `2x` playback overlay; that overlay is not product UI, and no original movement speed, countdown rate, collection cadence, or animation timing is inferred from it.

## Observable entry surface

- The player approaches a purple neon venue signed `UMBRAS` and interacts across a counter with an NPC labeled `Linkin`.
- A dark dialogue panel appears with the NPC name `Linkin`; the sampled response option reads `Can I get a job here?`.
- The footage establishes a conversation-to-job transition, but not the exact proximity prompt, NPC identity contract, eligibility rules, dialogue tree, transition implementation, or whether other job variants exist.
- The recurring compact balances/status stack, colored right-side rail, and bottom quick slots are visible before and after the job. The dialogue and job surfaces must not create a second HUD runtime.

## Observable active-job surface

- The player is placed in a dark purple obstacle space with neon magenta highlights, floating platforms, rings/tubes, small collectible or waypoint-like purple spheres, wall ledges, and elevated traversal.
- A compact job strip spans the top center. It includes a small job/icon marker, a colored progress fill that advances during the run, and a circular countdown indicator at the left.
- A red `Cancel Job` button remains at the top right throughout the sampled active run.
- Collection feedback includes a floating `+10` near the avatar. The footage does not establish what the 10 represents or whether every visible sphere is an item, checkpoint, score source, or visual guide.
- The run remains third-person traversal with the standard right rail present. The sampled course shows jumping and falling/recovery states, but does not prove checkpoint respawn policy, damage rules, failure rules, exact obstacle ordering, or original-speed physics.
- The center-top `2x` badge and transport controls belong to video playback and must not be reproduced as game UI.

## Observable completion and Jobs menu

- Completion returns to the venue and opens a centered white card with a purple dotted `Jobs` header, back arrow, and close control.
- The sampled performance card reads:
  - `Servant of the Void - Hard`
  - `Performance`
  - `Excellent! (7 Items Collected)`
  - `Earnings`
  - coin `+66`
  - `+664 XP`
  - `9 Levels to Promotion (Professional)`
  - `You received a Gift Box for your excellent performance on the job!`
  - green `OK` action
- Visible level/title text includes `Lv. 31` and `Assistant`. These values, the balance stack, rewards, collection count, and promotion distance are session evidence, not fixed product constants or verified formulas.
- After `OK`, the Jobs menu shows `Servant of the Void`, descriptive copy about adventuring through the Void to collect ingredients for Umbra's, and difficulty actions `Easy`, `Medium`, and `Hard`.
- Visible difficulty modifiers are `+0%`, `+25% Rewards`, and `+50% Rewards`. The sampled footer also shows `Daily Shifts Left: 9/10`, `Replay Tickets: x6`, plus `Rewards`, `Buy Boosts`, and `Inventory` actions.
- The footage does not establish purchase behavior, boost pricing, replay-ticket acquisition, inventory contents, other job definitions, daily reset rules, reward odds, promotion formulas, or failure/cancel rewards.

## Implementation contract after activation

1. Route job entry through the existing Free Roam job authority; do not create a second job, economy, progression, inventory, clock, spawn, or persistence writer.
2. The client submits only a stable server-known job key, difficulty key, and idempotency token. The server validates availability, eligibility, venue/proximity or approved entry state, daily/replay allowance, active-job exclusivity, and destination.
3. The server owns the authoritative run state, allowed checkpoints/collectibles, collected set, cancel/completion state, performance grade, reward calculation, XP, currency, promotion progress, gift/inventory grant, and exactly-once persistence.
4. The client must not author elapsed time, collected count, score, performance, reward amount, XP, currency, level, promotion, gift result, spawn CFrame, obstacle completion, or success copy.
5. Starting the same request twice is idempotent. It cannot consume two shifts/tickets, create two runs, or teleport twice. Only one active job session and one active job HUD may exist per player.
6. Each collectible/checkpoint claim uses a stable server-known identifier and is accepted at most once after server validation. Unknown, stale, duplicate, out-of-order, impossible-distance, wrong-session, or post-cancel claims fail closed.
7. `Cancel Job` requires server acknowledgement, terminates at most one active session, cannot award completion rewards, and restores an approved return location/HUD state. Repeated cancel is harmless.
8. Completion is server-confirmed and exactly once. Retry/reconnect cannot duplicate currency, XP, promotion credit, gift boxes, inventory items, daily counters, or replay consumption.
9. The result card renders only server-confirmed values. Closing or pressing `OK` acknowledges presentation; it does not recompute, grant, debit, or persist rewards.
10. Difficulty browsing, Rewards, Inventory, and Buy Boosts are side-effect free until a separately verified server action is selected. No spending or boost purchase is authorized by this contract.
11. Preserve the compact recurring HUD and touch controls without obstruction. The active-job strip, countdown, cancel action, result card, and Jobs menu must have one mount each and restore the prior HUD cleanly on exit.
12. Keep the purple obstacle silhouette, luminous waypoints/platforms, top progress/countdown grouping, cancellation affordance, and performance/reward hierarchy as the visual target. Do not reproduce the recording's `2x` playback overlay.
13. Do not infer original-speed movement, countdown duration, animation timing, or reward cadence from the recording.

## Acceptance criteria

- A reference-matched capture shows the Umbra's dialogue entry, purple obstacle/collection run, top progress/countdown grouping, visible `Cancel Job`, collection feedback, performance card, and Jobs menu hierarchy.
- Desktop and phone-landscape captures show safe insets and no collision among the active-job strip, cancel action, Roblox inset, balances/status, right rail, bottom slots, movement/jump controls, and any open result/menu surface.
- Deterministic tests prove single active session and HUD mount, stable-key requests, server-owned proximity/entry, validated collectible IDs, duplicate/out-of-order rejection, harmless cancel replay, exactly-once completion/reward persistence, and reconnect safety.
- Adversarial tests prove the client cannot forge time, count, score, difficulty modifiers, performance, currency, XP, promotion, gift delivery, position, or completion.
- Existing cafe-job, economy, progression, inventory/ownership, spawn/travel, and save/rejoin contracts remain green; all three repository guard suites bind to the exact candidate head.
- Independent QA reviews the exact candidate before Integration. Smoke and Package bind to the integrated canonical SHA.
- Rendered/runtime and target-device comparison remain required. Static tests cannot certify obstacle feel, traversal continuity, collision, timing, reward correctness, or visual parity.

## Explicit unknowns

- Exact NPC/venue/job stable keys and the full dialogue tree.
- Exact obstacle sequence, checkpoint/respawn policy, failure conditions, collision settings, collectible identities, and authoritative validation radii.
- Original-speed movement, countdown rate/duration, animation timing, collection cadence, and transition timing.
- Reward, XP, performance, promotion, daily-shift, replay-ticket, gift-box, boost, and inventory formulas or persistence rules.
- Whether `+10` is score, collection value, XP, currency, or another metric.
- Other jobs, difficulties, course variants, menu ordering, reward tiers, and availability gates.
- Exact phone/tablet responsive geometry outside the sampled landscape viewport.

No `school/**` source was changed. This coordination contract does not activate another product producer, authorize spending or publication, modify PR #188, claim parity, or close the rendered/device gate.
