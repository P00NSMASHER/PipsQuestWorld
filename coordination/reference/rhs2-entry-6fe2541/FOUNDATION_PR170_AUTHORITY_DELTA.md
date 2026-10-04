# Foundation authority delta — PR 170

Owner: Roblox High School Foundation  
Input SHA: PR 170 head `dfbbb5e2c52930beae7ebaea66d9ab5019c8914f` on canonical base `6fe254139ae3382f0ab71e6725df00c1c1a69822`  
Reference clip/time: A@00:05 frontage/spawn approach; A@00:25 atrium; A@00:45 corridor/staircase; A@02:05 stairwell/items  
Acceptance criteria: PR 170 must preserve the existing Foundation world, spawn, registry, lighting, and contract blobs exactly; the future P1 producer must start from the repaired packaged canonical and retain one spawn, clock, location registry, and global Lighting owner.  
Output location: `coordination/reference/rhs2-entry-6fe2541/FOUNDATION_PR170_AUTHORITY_DELTA.md`  
Blocker: PR 170 still requires formal QA, protected Integration, exact canonical push CI, Smoke, and Package. P1 product work is not authorized.  
Next handoff: Roblox High School QA & Contract validates PR 170; after repaired packaging, Pip High Free Roam consumes this delta with `FOUNDATION_AUTHORITY_ACCEPTANCE.md`.

## Exact changed-surface finding

PR 170 changes only:

- `.github/workflows/high-school-progression-ci.yml`
- `school/repair-outfit-mount/HANDOFF.md`
- `school/src/shared/LegacyOutfitEntry.lua`

It does not change a Foundation product surface. The four collision-critical Foundation blobs are byte-identical between canonical `6fe2541` and candidate `dfbbb5e2`:

| Surface | Canonical blob | PR 170 blob | Result |
| --- | --- | --- | --- |
| `school/src/server/CampusBuilder.server.lua` | `402bc78ab622464e2f6ee12cc737ad32b6e8143a` | `402bc78ab622464e2f6ee12cc737ad32b6e8143a` | unchanged |
| `school/src/shared/SchoolConfig.lua` | `334705e54cab66bd586f356d3f6ba0cfe28a5340` | `334705e54cab66bd586f356d3f6ba0cfe28a5340` | unchanged |
| `school/default.project.json` | `ba5e85e82652f137cb17e76016f062731c033761` | `ba5e85e82652f137cb17e76016f062731c033761` | unchanged |
| `school/tests/foundation_world_contract_spec.lua` | `bbf5f7ed9a8bcb55556e0280eb1690b9bed1634a` | `bbf5f7ed9a8bcb55556e0280eb1690b9bed1634a` | unchanged |

Foundation CI run `37218515500` is successful on the exact PR 170 head. Class/Education `37218515472` and Progression `37218515509` are also successful, but formal independent QA remains mandatory.

## Consumption rule for the visible slice

The geometry, palette, layout, and navigation specification in `FOUNDATION_AUTHORITY_ACCEPTANCE.md` remains valid as evidence because PR 170 introduces no world-authority drift. It is not permission to implement on `6fe2541`.

When Control Tower later activates P1 from the repaired packaged canonical, the producer must first compare these same four paths against the blobs above:

- If all remain unchanged, consume the existing Foundation specification directly.
- If any blob changed during Integration or a later gate, Foundation reviews only the changed world/clock/spawn/environment surface before product edits.
- Never reintroduce the historical prep branch, create a second `SpawnLocation`, add a second schedule loop, add a runtime `Lighting.ClockTime` writer, or create a parallel location registry.

No rendered comparison, device check, navigation pass, or product-parity gap is closed by this delta.
