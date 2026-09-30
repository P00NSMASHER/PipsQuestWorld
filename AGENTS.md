# Agent Rules — Pip High

You are working on the active Pip High school-life game.

1. The active source root is `school/`.
2. The legacy `game/` Maze World tree is frozen historical material. Do not build new features on it.
3. Never push directly to `main`.
4. Re-read current main and open PRs before editing.
5. Do not rewrite unrelated systems.
6. Preserve failures. Never weaken tests just to get green.
7. Report separately: implemented, actually tested, not tested, known failures.
8. Never claim playable/polished/ready from code inspection alone.
9. Player experience is the score.
10. Use original code, layouts, UI, names, and assets or clearly licensed material.
11. Do not copy protected maps, code, branding, art, audio, or UI from another Roblox game.
12. Correct answers are server-authoritative and must not be exposed in client/shared code or payloads.
13. Wrong answers should teach, not punish.
14. Educational failures must not soft-lock normal movement/free roam.
15. No monetization, loot boxes, FOMO, streak punishment, artificial waits, or punitive learning mechanics.
16. When the user is away/at work, all local automation must remain background/headless and must not steal desktop focus.

## Definition of Done for an iteration

An iteration only counts as runtime-complete if the exact candidate:
- launches
- spawns the player
- permits movement
- keeps core controls working
- renders the school HUD at a phone-sized viewport
- allows travel to the current class
- presents a question without exposing the correct answer
- accepts an answer on the server
- updates points/state correctly
- survives a bell-period transition
- is visually inspected
