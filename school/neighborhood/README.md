# Pip High: school and neighborhood

This is a separate first implementation of the user's new direction, not another RHS/RHS2 restoration. The loop is: enter a subject classroom, answer a question, save the learning reward, and choose a visible home, clothing, item, or vehicle upgrade.

## Scope and build target

Build `school/neighborhood.project.json`, not `school/default.project.json`. Only the new neighborhood server, client, and shared modules are mapped. The older RHS binary and procedural-school project remain untouched for history and rollback. This mode contains a recognizable Assumption BVM-inspired three-story school, six subject classrooms, an admin/lobby/leaderboard core, a school shop, and a residential street with 24 independently assigned house plots. It does not load the old jobs, clubs, school-day schedule, visible clock, or old HUD.

World geometry, clothing overlays, vehicle models, and shop previews in this mode are original generated content. This is not the original RHS2 map or a claim of exact visual parity. All children begin with their own furnished starter home and a starter ride. The progression runs from modest to luxury; it does not attach insulting labels to players or publish a poorest-player ranking.

## Authoritative Roblox visual target — 2026-10-06

The latest user-approved Roblox render is now the **gold standard for visual language and exterior presentation**. The target is deliberately achievable with native Roblox geometry rather than a photorealistic one-off render. Preserve the real-school photo cues, but stylize them into a polished, warm, readable Roblox world.

Required exterior cues now encoded in source and static guards are: warm bright daytime lighting with soft shadows/clouds; brown brick with tan infill panels; a four-bay upper window rhythm with a narrower first bay; strong vertical pilasters, stone belts and a stepped parapet silhouette; three large curve-following segmented arched front bays, with two door bays; a two-stage ceremonial stair with a broad middle terrace, masonry cheeks and terraced planters; a dark flat roof with chimney; an oversized two-panel green/gold street sign with arched crown and gold flourishes; a restrained green/gold vertical faith/family/academics/service banner; warm window depth, clipped shrubs, flower planters and chunky low-poly tree canopies; a continuous front sidewalk/curb and east-side sidewalk; fenced asphalt parking; nearby rowhomes, retaining walls, utility poles, a distant green ridge/water tower/radio mast, and the steep Howard Avenue edge.

Do not chase the render by adding giant textures, pre-baked building images, or expensive mesh detail that cannot be maintained in Studio. The desired read is “high-end Roblox interpretation of the real school,” not “photo pasted into Roblox.” Architecture remains primary; branding supports it.

School travel now deliberately places the avatar on a front-right three-quarter approach matching the approved hero composition: the facade fills the center, the green/gold sign reads on the left, and the heavy east corner plus side elevation remain visible on the right. This is a composition aid, not a forced cinematic camera.

## Learning and curriculum

The server determines the classroom from the character's position. Entering the room offers the subject's question; leaving invalidates it. Initial client messages contain shuffled choices and a per-question token, not answer keys. An incorrect answer shows an explanation and a supported retry.

The active bank is a deterministic **338-item** curriculum-only import from `P00NSMASHER/abvmschoolstarworld` pinned to commit `aa2fe3fbcb9b25205948073ee284b96910733d79`. The import verifies exact source-file SHA-256 values before generating the server-only bank, removes duplicate prompts, excludes invalid choices, and exports no roster, email, child identity, progress, calendar, or worksheet-image metadata.

| Classroom | Questions | Teacher |
| --- | ---: | --- |
| Math | 121 | Mrs. Campion |
| Reading | 91 | Mrs. Russek |
| Religion | 56 | Mr. Bolich |
| Spelling | 41 | Mrs. Kochol |
| Grammar | 16 | Mrs. Benulis |
| Vocabulary | 13 | Mr. Yordy |

The question level remains Grade 2 because that is the verified ABVM learning source; the school building does not silently change the curriculum. The generated receipt is `school/neighborhood/abvm-import-receipt.json`, and answer keys remain in ServerScriptService only.

## Reward and shop design

Correct independently on the first try earns a **10-Credit** base reward; correct after a guided retry earns **6 Credits**. Consecutive paid correct answers add **+0, +2, +4, +6, +8, then +10** while the streak continues. A wrong answer resets the positive streak and starts a bounded negative streak of **-2, -4, -6, -8, then -10 Credits**. The wallet never drops below zero. A correct answer immediately clears the negative streak.

Selecting the same wrong choice twice on one question cannot double-charge the player. Wrong attempts count toward persisted accuracy, but the client receives a hint rather than the full explanation until the question is answered correctly. Every five different reward-eligible completions adds **+15 Credits**. Immediate same-question reward farming remains blocked; later legitimate review can earn again. Time spent idle does not earn currency, and wealthier houses or clothes never increase question payouts.

Five uninterrupted independent answers earn **85 Credits** including the lesson bonus. Twenty uninterrupted independent answers earn **430 Credits**, enough for the 400-Credit Cozy Cottage with 30 remaining. The larger home ladder is intentionally slower so clothing, decor, and vehicle purchases matter between house upgrades.

Three global boards are mounted inside the school. **Top Accuracy** ranks saved accuracy after a 20-answer minimum, **Most Questions** ranks all saved answer attempts, and **Most Credits** ranks current spendable balance. Leaderboard writes are best-effort mirrors only; the session-locked profile store remains the authority for rewards, penalties, purchases, and ownership.

The fixed-price catalog preserves all previously shipped IDs while expanding the progression to five home tiers and a wider clothing ladder. Home prices are 0 / 400 / 1,500 / 4,500 / 12,000 Credits; the paid vehicles are 900 / 2,400 / 6,500 Credits. Every enabled shop listing has an actual renderer/equip path; placeholders are not sold. A personal goal bar shows exact current balance versus the selected item price.

No Robux purchase prompts, loot boxes, random rewards, daily-login losses, or premium income boosts are included.

## Persistence and authority

`PipNeighborhoodV1` is a new DataStore namespace, separate from the old game. Balances, lifetime earnings, ownership, equipment, lesson progress, review state, and personal goals are saved on the server. UpdateAsync reducers use session leases and operation receipts. Retrying a purchase cannot charge again for an already-owned item. A failed or ambiguous save does not produce a confirmed reward message or replace a stored profile with defaults.

The 180-second lease is renewed periodically and released on departure where possible. An unavailable or invalid profile prevents entry rather than resetting progress. Local volatile preview mode requires an explicit Studio-only `NeighborhoodVolatilePreview=true` attribute; published servers never silently fall back to memory.

## Interface

The ABVM HUD has only School, Home, Shop, and Ride navigation, a Credit balance, streak/accuracy feedback, and a personal next-goal card. The classroom view uses readable answer buttons, feedback, a next-question action, and a close control. A wide/short landscape screen uses separate question and answer columns. The shop has Homes, Clothes, Items, and Vehicles tabs, small 3D previews, prices, owned/equipped states, and set-goal actions. Native Roblox movement remains enabled.

The implementation uses CoreUISafeInsets for the interactive ScreenGui. Pure geometry fixtures include portrait and landscape phone, iPad, and desktop canvases. Actual touch behavior, text wrapping, orientation changes during a lesson, avatar-clothing clipping, seat behavior, and frame rate still require runtime/device inspection.

## Reused work and research

- Earlier progression work informed server authority/idempotency, but the active user-approved reward tuning is now 10/6 with bounded ±2-step streak ladders.
- EconomyRepository and vehicle work informed ownership, serialized mutation, bounded inputs, and one active vehicle per player.
- ABVM's study engine supplies the initial curriculum and the question/explanation/retry structure.
- The reviewed hunter ledger's `COMPONENTS.md`, at `P00NSMASHER/github-value-hunt-ledger@4d1a450b94be7298ce678d6718becfc7dc65e09b`, informed stable-operation receipts, cautious handling of unknown outcomes, pinned provenance, and the distinction between passing a validator and proving real behavior. No third-party hunter code was copied into this mode. This does not claim an exhaustive review of every hunter repository.

## Reproduce the static preview checks

```sh
python3 school/neighborhood/tests/verify_build.py \
  --compiler /path/to/luau-compile \
  --luau /path/to/luau \
  --rojo /path/to/rojo \
  --out /path/to/preview-output
```

The verifier compiles all 12 mapped Lua sources, runs 26 pure model/layout tests, builds the place, validates its exact script inventory, and checks three deliberately broken project/place cases. In a Git checkout, add `--expected-sha <full-commit>` to bind the run to an exact head. Logs, per-file hashes, the place hash, and the preview are written to the output directory.

`PASS_STATIC_PREVIEW_ONLY` is deliberately not a runtime or release result. The built artifact must contain exactly one server entrypoint, one client entrypoint, and the nine expected module scripts, with the question bank on the server only.

## Required playtest before production replacement

Observe a clean Roblox startup, walk from an owned home into every classroom, complete both first-try and correction flows, and verify saved coins after leave/rejoin. Buy and equip each category, confirm another player's house and balance remain unaffected, and inspect each home tier. Check driving, parking, collisions, and cleanup after death or exit. On a physical iPhone, inspect notch clearance, touch movement while panels are open, long reading prompts, shop scrolling, portrait/landscape changes, and visual quality against the user's recording.

Until that evidence exists, runtime execution, physical-iPhone testing, visual-polish approval, and publication of this new mode remain unverified. The legacy publisher pinned to `33a5a11` must not be used to publish this project.
