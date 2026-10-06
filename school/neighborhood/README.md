# Pip High: school and neighborhood

This is a separate first implementation of the user's new direction, not another RHS/RHS2 restoration. The loop is: enter a subject classroom, answer a question, save the learning reward, and choose a visible home, clothing, item, or vehicle upgrade.

## Scope and build target

Build `school/neighborhood.project.json`, not `school/default.project.json`. Only the new neighborhood server, client, and shared modules are mapped. The older RHS binary and procedural-school project remain untouched for history and rollback. This mode contains a school, four subject classrooms, a campus-shop counter, and a residential street with 24 independently assigned house plots. It does not load the old jobs, clubs, school-day schedule, visible clock, or old HUD.

World geometry, clothing overlays, vehicle models, and shop previews in this mode are original generated content. This is not the original RHS2 map or a claim of exact visual parity. All children begin with their own furnished starter home and a starter ride. The progression runs from modest to luxury; it does not attach insulting labels to players or publish a poorest-player ranking.

## Learning and curriculum

The server determines the classroom from the character's position. Entering the room offers the subject's question; leaving invalidates it. Initial client messages contain shuffled choices and a per-question token, not answer keys. An incorrect answer shows an explanation and a supported retry.

The initial bank is a curated 51-item snapshot from `P00NSMASHER/abvmschoolstarworld`, commit `aa2fe3fbcb9b25205948073ee284b96910733d79`, file `pages/study-games.js`, blob `85d901540218aefd7a0f54c439286c9e24143b1f`.

| Classroom | Initial questions |
| --- | ---: |
| Math | 16 |
| Reading / ELA | 13 |
| Spelling / Handwriting | 12 |
| Religion | 10 |

The question level is Grade 2 because that is the verified ABVM source; the high-school setting does not silently change the curriculum. Source ranges are recorded in `QuestionBank.lua`. Some questions instantiate the source's deterministic variants; wording is lightly adapted where necessary. No teacher emails, student identifiers, individual performance records, or uploaded worksheet photographs are copied.

This is not the whole ABVM question corpus and is not yet automatic weekly synchronization. The first import favors self-contained questions that do not require an unavailable illustration or external passage. Future imports must preserve subject mapping, answer correctness, explanations, and curriculum-only privacy boundaries.

## Reward and shop design

Correct on the first try earns 25 learning coins; correct after a guided retry earns 15. Wrong answers never subtract existing coins. Each completed set of five different paid questions adds 50 coins. Immediate repetition of the same question is practice-only; after 10 minutes that question may earn again. Time spent idle does not earn currency. Wealthier houses and clothes do not increase the reward rate.

Every player starts at zero coins, with a free house and cart. Six distinct first-try answers earn 200 coins including one lesson bonus, enough to buy the 180-coin garden cottage with 20 remaining. Smaller goals are accessible sooner: a rug costs 35, a sweatshirt 60, and a reading lamp 80.

The fixed-price catalog contains 19 entries: four homes, five clothing choices, six furnishings/wearable items, and four vehicles. Later goals include a 1,100-coin villa and a 5,200-coin estate. The five named lifestyle tiers are visual collections and personal progress labels, not hidden purchase restrictions. Buying and equipping are separate actions for homes, outfits, and vehicles. Furnishings appear automatically in the player's own house; the backpack is wearable.

No Robux purchase prompts, loot boxes, random rewards, daily-login losses, or premium income boosts are included. A personal goal bar displays the cost and current saved coins.

## Persistence and authority

`PipNeighborhoodV1` is a new DataStore namespace, separate from the old game. Balances, lifetime earnings, ownership, equipment, lesson progress, review state, and personal goals are saved on the server. UpdateAsync reducers use session leases and operation receipts. Retrying a purchase cannot charge again for an already-owned item. A failed or ambiguous save does not produce a confirmed reward message or replace a stored profile with defaults.

The 180-second lease is renewed periodically and released on departure where possible. An unavailable or invalid profile prevents entry rather than resetting progress. Local volatile preview mode requires an explicit Studio-only `NeighborhoodVolatilePreview=true` attribute; published servers never silently fall back to memory.

## Interface

The new HUD has only School, Home, Shop, and Ride navigation, a wallet, and a personal next-goal card. The classroom view uses readable answer buttons, feedback, a next-question action, and a close control. A wide/short landscape screen uses separate question and answer columns. The shop has Homes, Clothes, Items, and Vehicles tabs, small 3D previews, prices, owned/equipped states, and set-goal actions. Native Roblox movement remains enabled.

The implementation uses CoreUISafeInsets for the interactive ScreenGui. Pure geometry fixtures include portrait and landscape phone, iPad, and desktop canvases. Actual touch behavior, text wrapping, orientation changes during a lesson, avatar-clothing clipping, seat behavior, and frame rate still require runtime/device inspection.

## Reused work and research

- The existing canonical ProgressionBinding's 25/15 first-try/retry distinction informed the reward split.
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

The verifier compiles all 11 mapped Lua sources, runs 19 pure model/layout tests, builds the place, validates its exact script inventory, and checks three deliberately broken project/place cases. In a Git checkout, add `--expected-sha <full-commit>` to bind the run to an exact head. Logs, per-file hashes, the place hash, and the preview are written to the output directory.

`PASS_STATIC_PREVIEW_ONLY` is deliberately not a runtime or release result. The built artifact must contain exactly one server entrypoint, one client entrypoint, and the nine expected module scripts, with the question bank on the server only.

## Required playtest before production replacement

Observe a clean Roblox startup, walk from an owned home into every classroom, complete both first-try and correction flows, and verify saved coins after leave/rejoin. Buy and equip each category, confirm another player's house and balance remain unaffected, and inspect each home tier. Check driving, parking, collisions, and cleanup after death or exit. On a physical iPhone, inspect notch clearance, touch movement while panels are open, long reading prompts, shop scrolling, portrait/landscape changes, and visual quality against the user's recording.

Until that evidence exists, runtime execution, physical-iPhone testing, visual-polish approval, and publication of this new mode remain unverified. The legacy publisher pinned to `33a5a11` must not be used to publish this project.
