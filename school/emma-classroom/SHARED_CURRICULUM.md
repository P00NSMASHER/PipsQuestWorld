# Governed ABVM classroom curriculum

The editable educational authority is the ABVM repository's reviewed teacher pack,
cumulative archive and original schoolwork practice. Its schema-v2 exporter creates
one deterministic content-only exchange bundle. `curriculum.json` is a pinned build
input; `server/QuestionBank.lua` and `curriculum-receipt.json` are generated outputs,
not independently editable question banks.

Initial integration: 357 questions (134 current, 65 cumulative, 158 original STAR).
All 134 existing source IDs remain present. Original worksheet practice adds fact
families, sentence subjects/writing and Religion Chapter 2, among other reviewed
skills. Undated worksheets remain cumulative. No responses, grades, private
history, source photo names/hashes, targeting reasons, or cross-app progress sync.
Only governed content hashes and public source references cross the boundary.

Mix selects every unseen current question before cumulative review, then original
STAR. Completing ten answers does not discard this rotation. Selecting a test
resets only the session, not lifetime saved progress. The star/progress chip opens
a menu with the exact teacher announcement and date. Grammar, spelling and Math
remain distinct. Tests never borrow unrelated chapters or STAR questions; unavailable
coverage stays unavailable. The game NPC is a presenter, not inferred evidence about
which teacher authored a test. Existing staff profiles and the playable ten-question
loop remain independent from curriculum source.

Answers, question memberships and provenance live only in ServerScriptService.
The client receives prompt, shuffled choices, token and tier; test menus receive
only ID, date, label and availability. Wrong answers still show hints; explanations
are returned only after a correct server grade. DataStore identity/schema, lifetime
progress, movement, camera, staff, room and assets are preserved. Four-option items
use two columns on short screens; each option keeps a 44px target.

## Future updates

Run `tools/refresh_curriculum.sh /path/to/clean/exact-sha-abvm-checkout` from any
working directory. The ABVM checkout must include the merged v2 exporter. The
script runs source contract tests, creates and validates a packet, and regenerates
only the bundle, server bank and receipt. IDs reused for changed prompts, keys,
skills or choice sets fail closed; changed questions require reviewed new IDs. It never pushes, merges or publishes.
Classroom CI reproduces the pinned ABVM checkout, compares the real regenerated
bundle, runs importer/server/client/device-layout/geometry regressions, compiles
Luau, builds the isolated place and verifies answer-key replication boundaries.

The main-branch refresh workflow checks ABVM main every four hours and prepares at
most one draft curriculum PR at a time. An unchanged educational bundle keeps its
accepted source receipt. Candidates must retain
exact-source receipts, pass the same checks, and obtain review before integration.
Bot-created PRs cannot be assumed to trigger GitHub CI; marking ready via an
independently authorized user/controller fires the ready-for-review CI event.
No runtime HTTP loading, client-side answer download, automatic merging or Roblox
publishing is enabled. A live server uses its bundled snapshot until an accepted
new place version is released. A malformed or unreviewed future source cannot
replace the last accepted bank.

## Permanent content contract through game redesigns

The source authority is **ABVM**, not this Roblox build. A rebuilt classroom,
a replacement character/avatar system, and rewritten phone UI must not alter
the governed import roots `curriculum.json`, `server/QuestionBank.lua`,
`curriculum-receipt.json`, or the reviewed importer without a separate
contract review. The `Emma Curriculum Contract` GitHub Actions workflow
checks these files independently of the world, visuals and Rojo place build.

The four-hour scheduler lives on GitHub `main` and chooses its target game
branch from `.github/emma-curriculum-target.json`. Changing the game's
canonical branch requires updating that reviewed route, not stopping schoolwork
ingestion or merging the unfinished parent PR. A changed study pack becomes
a draft, content-only PR; a separately approved Roblox release is still
required before players see the new bundle. A matching JSON export with a
missing/tampered server question bank or receipt is a repair, not a no-op.

## Session-completion guarantees

The server credits a ten-answer session as soon as the tenth correct answer is
graded, in the same operation that increments lifetime correct answers. A student
may restart, change test modes, or leave before the 1.9-second celebration callback
and still retain earned completion credit. An interrupted or recreated HUD can
recover a finished ten-answer session through its own server state and show the
"Do another 10" control without relying on a missed final RemoteEvent. Stale
grading callbacks cannot replace a newly selected practice round. Save operations
retain monotonic per-user lifetime totals; no learner history is exported to ABVM.

## Release and QA boundary

The governed curriculum was first published to the existing Emma classroom
place in Roblox version 60 through GitHub Actions, with 357 questions and no
automatic content publishing. Later classroom releases retain the same place,
source-receipt verification and manual PUBLISH_REQUEST gate. Check the GitHub
publish run for the actual current version and binary digest, not this document.

Static service doubles, Luau compilation and an isolated Rojo place build do
not establish actual Roblox play, native staff rendering, live DataStore
leave/rejoin isolation, or four-choice readability on a physical iPhone.
Runtime and device acceptance must remain explicitly unverified until
appropriate recordings and live-session evidence are reviewed.
