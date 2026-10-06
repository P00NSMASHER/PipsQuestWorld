# Agent Rules — Pip High

You are working on the active Pip High school + neighborhood game.

1. The active source root is `school/`.
2. The active build target for the current user direction is `school/neighborhood.project.json`.
3. The legacy `game/` Maze tree, RHS/RHS2 restoration lines, and `school/default.project.json` are historical/reference material, not fallback runtime candidates.
4. Never push directly to `main`.
5. Re-read current main, PR #301, issue #304, and live exact heads before editing.
6. Do not rewrite unrelated systems or create a second wallet, profile store, question authority, world controller, or client HUD.
7. Preserve failures. Never weaken tests just to get green.
8. Report separately: implemented, actually tested, not tested, known failures.
9. Never claim playable/polished/ready from code inspection, static CI, or a successful upload alone.
10. Player experience and rendered fidelity to the authorized Assumption BVM references are the score.
11. Use original code/assets or material the user is authorized to use. For this project, the user has explicitly authorized the supplied Assumption BVM name/logo/reference material.
12. Correct answers remain server-authoritative and the correct key must never be exposed in client/shared payloads before grading.
13. Wrong answers must teach through a hint/retry. They may apply the user-approved bounded Credit deduction/negative streak, but never debt, lost possessions, shame labels, disabled learning, or movement lockout.
14. Educational failures must not soft-lock normal movement/free roam.
15. No Robux monetization, loot boxes, FOMO, artificial waits, idle income, or penalties beyond the explicit bounded answer-streak Credit rules.
16. The visible school clock, bell schedule, jobs, clubs, and unrelated destinations are not part of the active neighborhood mode.
17. When the user is away/at work, all local automation must remain background/headless and must not steal desktop focus.
18. Current explicit user direction requires the supplied full Assumption BVM faculty/staff roster in the active Roblox candidate: preserve exact displayed names/roles, a faculty directory, and stylized NPC likeness cues derived only from the user-supplied photos. This is not speculative drift and must not be reverted to the older pre-faculty state.

## Definition of Done for an iteration

An iteration only counts as runtime-complete if the exact candidate:
- launches
- spawns the player at their owned home
- permits normal movement and camera control
- keeps core controls working on a phone-sized viewport
- allows travel to Assumption BVM and entry through a usable school entrance
- allows the player to reach the intended named classroom
- presents a question without exposing the correct answer
- accepts correct and wrong attempts on the server with idempotent Credit/streak effects
- updates saved progression correctly
- keeps School / Home / Shop / Ride navigation functional without any visible bell/clock dependency
- preserves the house/shop/vehicle/leaderboard loop
- survives leave/rejoin with committed state intact
- is visually inspected against the authorized ABVM building references
- records physical-iPhone status separately from headless/static status
