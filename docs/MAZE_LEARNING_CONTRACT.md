# Maze / Learning Contract v1

This is the committed seam between Maze World Learning Gates and the Education Engine.

## Boundary

Learning Gates may ask the engine for exactly one brief encounter. The engine returns question presentation data and later grades the answer. It does not create geometry, rooms, movement, UI shells, rewards, currency, or progression. If the engine cannot produce an encounter, the caller must fail open to normal Maze World play rather than replacing the game loop.

## Begin encounter

`EducationEngine.beginEncounter(questionBank, context)`

`context` may contain:
- `currentMaterialSkills`: ordered/array-like set of currently taught skill IDs.
- `lastQuestionId`: most recently shown question ID.
- `independentOpportunitiesBySkill`: counts used to balance under-practiced skills.
- `dueComebackSkills`: skills whose spaced comeback is now due.

Returns either `nil, reason` or:
- `state`: server-only encounter state containing the private answer key.
- `presentation`: safe client payload containing `questionId`, `subject`, `skill`, `prompt`, `options`, `difficulty`, and `responseType` only.

The presentation never includes `correctIndex`, modeled answer, explanation, rubric, or diagnostics.

## Question selection

1. Validate item shape and quality before selection.
2. Exclude `lastQuestionId`; if no alternative exists, return `nil, "no-nonrepeat-question"` rather than immediately repeat it.
3. Prefer questions whose `tier == "material"` and whose `skill` is in `currentMaterialSkills`.
4. If none exist, prefer any `material` question before fallback tiers.
5. Within the active pool, prefer a due spaced-comeback skill, then the skill with fewer independent opportunities, then `transfer`/`application` items over `direct` items, then lower difficulty/tie by stable question ID.
6. A trivial item whose exact correct option is copied into the prompt is rejected unless `allowAnswerInPrompt == true`.

## Submit answer

`EducationEngine.submitAnswer(state, choiceIndex)` is server-authoritative.

- Correct with zero prior misses: complete encounter, return to Maze World, `independent=true`, `masteryEligible=true`.
- First miss: retry same item with `feedback.kind="clue"`; include misconception feedback when available plus the item clue/hint.
- Second miss: retry same item with `feedback.kind="support"`; include misconception feedback plus scaffold/support.
- Third or later miss: complete encounter with `feedback.kind="modeled"`; reveal the modeled answer and explanation, then immediately return control to Maze World.
- Any correct response after a miss is supported evidence: `independent=false`, `masteryEligible=false`.
- Any modeled outcome is `independent=false`, `masteryEligible=false`.
- Any non-independent resolution requests a same-skill comeback after at least two other encounters (`afterEncounters=2`).

## Question-bank compatibility

Production items remain compatible with the existing 156-question shape. Required fields are `id`, `subject`, `skill`, `prompt`, `options`, and `correctIndex`. Existing metadata such as `tier`, `difficulty`, `questionType`, `hint`, `scaffold`, `explanation`, `choiceDiagnostics`, `provenance`, and standards may pass through without expanding the bank.
