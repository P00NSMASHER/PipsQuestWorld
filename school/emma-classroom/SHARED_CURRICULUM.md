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

Future automatic refreshes may prepare a draft PR from ABVM main. They must retain
exact-source receipts, pass the same checks, and obtain review before integration.
Bot-created PRs cannot be assumed to trigger GitHub CI; marking ready via an
independently authorized user/controller fires the ready-for-review CI event.
No runtime HTTP loading, client-side answer download, automatic merging or Roblox
publishing is enabled. A live server uses its bundled snapshot until an accepted
new place version is released. A malformed or unreviewed future source cannot
replace the last accepted bank.

## Release status

This is source integration only. Static service doubles and a Rojo build do not
prove actual Roblox play, live DataStore isolation, four-choice readability or the
new test menu on a physical iPhone. Actual runtime and physical-device evidence for
the exact candidate is required before publishing. PUBLISH_REQUEST and the Roblox
publishing workflow are untouched. No new live version is claimed.
