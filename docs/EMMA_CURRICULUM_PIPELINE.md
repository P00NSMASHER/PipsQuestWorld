# Emma schoolwork integration: permanent data lane

**Purpose:** Assumption BVM reviewed schoolwork must continue moving through a
governed export/validation path even while the Roblox classroom is visually
redesigned, rebuilt, or replaced. The educational authority is
`P00NSMASHER/abvmschoolstarworld`; the game is a **consumer**, never a second
editable curriculum authority.

## Immutable content boundary

Keep these files at the stable adapter root `school/emma-classroom/`:

- `curriculum.json`: reviewed schema-v2, content-only exchange payload.
- `server/QuestionBank.lua`: generated, server-only answer keys and test IDs.
- `curriculum-receipt.json`: exact ABVM source commit, deterministic content
  checksum, tier/test counts, and explicit private-data exclusion.
- `tools/import_study_universe.py`, `tools/refresh_curriculum.sh`,
  `tests/test_curriculum_import.py`: validation and regeneration contract.

Game designers may replace the entire world, characters, phone UI, camera,
animations, sound, rewards or other scripts without rewriting these generated
files. A new game architecture must keep this content adapter available and
map the server-only bank into its new lesson presenter. Do not put answers,
question membership IDs, private history, grades, or worksheet provenance into
client/shared modules. Do not download keys through Roblox runtime HTTP.

The separate `Emma Curriculum Contract` GitHub workflow validates source SHA,
real ABVM exporter compatibility, deterministic output, privacy, original STAR
labelling, answer/ID integrity and exact output reproduction **without depending
on game visuals, the Rojo place, or the physical device**. Full game build and
physical-device QA remain separate release gates.

## Regular refresh, independent of PR #309 or visual QA

The scheduler on the repository's default branch
(`.github/workflows/emma-curriculum-refresh.yml`) polls reviewed ABVM `main`
every four hours. It first reads
`.github/emma-curriculum-target.json` from the default branch, validates the
consumer branch and checks out **that current game branch**. This makes changing
to a replacement game branch a small, reviewed routing change instead of
editing the scheduler, copying gameplay files, or waiting for PR #309 to merge.

If the content bundle and both generated files match their pinned receipt,
the refresh reports `NO_CHANGE`, even if ABVM's Git head moved without a change
in governed educational content. If any generated bank/receipt is damaged or
drifts, the refresh detects it and prepares a repaired **data-only** candidate.

When reviewed questions change, the scheduler validates the source and generates
only the three content files above, then creates **one draft curriculum PR** to
the active game branch. Old candidates are not overwritten. If GitHub Actions
blocks draft-PR creation, a retained content branch and workflow artifact remain,
and the job fails visibly; later runs may retry PR creation without replacing
that branch. It never silently calls such a failure successful.

A curriculum PR is **not** a Roblox place publication or proof the classroom
looks good. A reviewer must approve changed question scope, source provenance,
any genuinely new tests, and consumer compatibility. Do not merge an invalid
candidate, invent test coverage, or auto-publish Roblox. A redesign should be
able to continue without interfering with this content review path.

## Migrating the game architecture

1. Maintain the stable `school/emma-classroom` content adapter in the new game
   branch, even if the rest of `school/` is replaced.
2. Run the independent `Emma Curriculum Contract` workflow on the new branch.
3. Review a small change to `.github/emma-curriculum-target.json` on `main`,
   setting `activeBranch` to the new branch. The resolver rejects default-branch,
   ambiguous, and arbitrary-reference targets.
4. Check the next scheduled or manual `Prepare Reviewed Emma Curriculum` run.
   Keep content PRs draft until reviewed. Published Roblox content advances only
   through a separately authorized release.

**Failure handling:** A missing adapter, unsupported schema, changed historical
question ID, malformed key, rejected teacher-lineage evidence, or unavailable
GitHub permissions produces a visible failure rather than replacing accepted
schoolwork. A blocked review leaves the existing accepted bank intact.

## Evidence that is and is not available

On October 8, 2026, the existing exporter and original importer passed their
initial source and classroom checks with 357 questions. The first scheduled
workflow simulation found identical content and correctly prepared no PR.
This is not a test of future content changes, draft creation permissions, Roblox
execution, or the quality of the game's current artwork. Independent new workflow
checks and the first real changed-source refresh must be evaluated separately.
