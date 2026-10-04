# Avatar mount syntax repair

Inspected base: 6fe254139ae3382f0ab71e6725df00c1c1a69822.

LegacyOutfitEntry opened mount at line 8 but never closed it before returning the module. CanonicalSchoolClient requires that module before creating its HUD. Add the missing end; preserve all handlers and authority.

Actually tested: Lua 5.4 compiler API rejects baseline with end expected to close function at line 8; repaired content compiles. No Roblox services were executed. CI now parses this required module and runs the existing canonical mount contract.

Not tested: Studio launch, rendered HUD, device input. These remain required runtime checks.

Next: independent QA reviews exact candidate and all three CI guards; Control Tower assigns this repair ahead of the reserved visual slice, and Integration merges only through the existing gates. Smoke/Package must not certify the broken base as runtime-ready. No publication.
