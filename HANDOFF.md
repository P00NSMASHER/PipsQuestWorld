# Schoolwork pipeline handoff (2026-10-08)

**Scope:** Keep Emma's reviewed ABVM Grade 2 material arriving in the game while
the Roblox classroom is independently redesigned. No visual/gameplay changes
or Roblox publication are part of this infrastructure change.

**Implemented on infrastructure review branch:**
- Four-hour default-branch scheduler reads validated, configurable game branch
  from `.github/emma-curriculum-target.json`.
- Candidate branches are keyed to exact ABVM Git SHA and target branch.
- Preparation updates only curriculum JSON, server-only QuestionBank.lua and
  source receipt. Draft PR is attempted; token restriction is a visible failure
  with immutable candidate and receipt preserved.
- Separate source-only contract workflow belongs to the game branch; it is
  intentionally independent of 3D/phone UI and PR #309's final visual QA.
- Prior closed/rejected candidates are not silently recreated.

**Actually tested:** The prior scheduler's no-change ABVM export passed on
GitHub before this infrastructure refactor. New exact-head GitHub CI validation
of this branch must be checked before accepting it.

**Not tested here:** Future source update, GitHub bot permission to create PRs
under a changed curriculum, long-term target migration, or Roblox device
rendering. All remain separate acceptance work.

**Next owner action:** Merge only after safe route CI passes. Verify a
`Prepare Reviewed Emma Curriculum` push/dispatch run on the merged default
branch, then keep `school/emma-classroom/` intact during redesign. Never
auto-merge curriculum candidates or auto-publish Roblox.
