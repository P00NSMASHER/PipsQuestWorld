# Pip's Quest World Status

Updated: 2026-10-01

## Product direction

- Maze World direction: **RETIRED**
- Standalone/homegrown school prototype direction: **RETIRED**
- Active foundation: **licensed archived ROBLOX High School build**
- Source archive commit: `b817aef0eaf77d3382acacdc8f22537e54c76822`
- Source archive blob: `95ee3d762f419bb3572e18db57c03682651dc8c4`
- Canonical SHA-256: `d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360`
- Canonical byte size: `2,283,775`

## Verified static inventory

- 41,257 instances
- 122 instance classes
- 1,192 non-empty scripts
- 2,196,914 bytes of Lua source
- 1,835 GUI instances
- 278 remote/bindable objects
- 93 tools
- 8 teams
- 346 seats/vehicle seats
- 205 sounds
- 869 unique Roblox asset IDs / 4,248 references

Major systems present include school schedules/classes, vehicles, housing/furniture, clubs/dance/music, inventory/items, outfits, cash/data systems, companions, tools, gamepasses/products, teleports, and mobile/client control code.

## Known compatibility work

The archived build is substantial but not yet proven runtime-compatible in 2026. Known dependency families include:

- legacy `cindering.xyz` HTTP calls
- old GameAnalytics HTTP integration
- DataStoreService persistence
- Marketplace/GamePass/Badge logic
- TeleportService
- InsertService / numeric require(assetId) dependencies
- legacy services/APIs including GamePassService and PointsService
- thousands of externally hosted Roblox asset references

## Runtime status

- Baseline bootstrap importer: **RETIRED** after exact import; baseline verification is read-only
- Exact baseline imported: **YES** — immutable baseline matches SHA-256 `d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360`
- Working copy created: **YES**
- Compatibility patches applied: **10** — legacy ranking/GameAnalytics traffic is sandboxed; car, apartment, outfit, house/furniture, and economy remotes are server-hardened; the two live NewHoverboard `ServerControl` handlers now require exact player ownership and typed keypress payloads
- Working-copy SHA-256 after current patches: `c96d6b9feba135d3367d11d33d72e841cdad666492d8314b6ef41f486cf72b3e`
- Baseline integrity guard: **PASSING**
- Compatibility audit: **PASSING**
- Structural parity: **PASSING** — 41,258 instances, 1,062 unique script paths, exactly 10 approved script-source changes, no unapproved hierarchy/source drift
- Current Roblox documentation still exposes `GamePassService` and `PointsService` as deprecated services, so they are not being rewritten solely because they are deprecated
- Executable legacy HTTP calls: **0 detected** after the three sandbox patches; remaining `http://` matches are non-`HttpService` strings such as asset/documentation URLs
- Numeric module dependency probe: **COMPLETE** — 191816425 resolves publicly; 258548692 is unavailable anonymously but already fail-soft; four unavailable-anonymous modules are isolated to skateboard/hoverboard paths and require runtime proof before any replacement
- Runtime side-effect preflight: **COMPLETE** — purchase prompts are player-click driven; literal old-place teleports are remote/admin driven; startup-sensitive DataStore access is guarded by `pcall`, and the shared retry helpers cap attempts at 10 rather than retrying forever
- Startup risk audit: **COMPLETE** — 175 auto-server scripts, 464 auto-client scripts, 32 auto-running scripts containing side-effect-capable code; no new game patch was added from this audit
- Current Roblox API compatibility: **PASSING STATIC REVIEW** — 121/122 serialized classes remain in the current API; the only missing class is one empty top-level `RenderHooksService` record (Name only, zero children/descendants, zero script references), treated as non-blocking residue pending Studio proof. Explicit service-use audit found 501 current uses, 109 deprecated-but-present uses, and **0 missing service/member uses**.
- Luau syntax scan: **PASSING** — 1,192 embedded scripts compiled, 0 syntax failures, pinned Luau revision `b18032e8926f4d1b539c1e9374fc4e20d4b12207`
- Current Roblox API class audit: **PASSING** against client tracker `0.741.19.7411056` (2026-09-29) — 121/122 serialized classes remain in the current API; the only absent class is one inert top-level `RenderHooksService` instance with no children, descendants, extra properties, or script references
- Current Roblox service/member audit: **PASSING** — 501 explicit service API uses are current, 109 are deprecated-but-still-present, 0 referenced services are missing, and 0 explicit service members are missing
- Targeted legacy members: **ALL PRESENT** — `PlayerHasPass`, `AwardPoints`, `AwardBadge`, `CustomizedTeleportUI`, and `GlobalDataStore.OnUpdate` are deprecated but still exposed; `InsertService.LoadAsset`, `PromptProductPurchase`, and `GetDataStore` remain current
- Static compatibility policy: deprecated-but-present APIs and the inert `RenderHooksService` singleton are preserved until runtime evidence proves a narrow repair is required
- School-loop structural audit: **PASSING** — 12/12 required markers present (schedule, classroom zones, class notification/teleport remotes, Math/English/Science/History, cafeteria, lockers); runtime Gate B is still required
- Car remote ownership hardening: **PASSING BUILD PARITY** — 3 client-triggered car handlers now validate against the exact server-tracked `Workspace` car before mutation
- Core remote hardening candidate: **BUILD + STRUCTURAL PARITY PASS** — apartment purchase validates direct Workspace ownership/schema and 30-stud proximity using current `Vector3.Magnitude`; outfit save/wear validates canonical fields, one in-flight request, slots 1–24, and hat-load failure; dedicated PR contract remains green
- House/furniture remote hardening: **BUILD + CONTRACT PASS** — lock/restriction/whitelist calls require the exact server-owned house/apartment; get/sell/remove are furniture-only; painting requires a direct owned-house target with `BrickColor`; furniture movement requires the player’s edit mode, owned `furni_*` model, typed CFrame/rotation, and a floor in that same house; reload placement is derived from the server-owned `HousePlacement` marker. Contract run: `36895670608`
- Economy purchase hardening: **BUILD + PARITY PASS** — malformed temporary-shop identifiers fail closed; permanent and loyalty purchase mutations complete before success is returned; both helpers are serialized per player across callers. Temporary-shop proximity remains a documented follow-up because the archive does not expose a complete stable shop-name-to-Workspace-NPC mapping for all five temporary shops.
- Hoverboard ServerControl hardening: **BUILD + CONTRACT PASS** — only the two live NewHoverboard/NewPinkHoverboard handlers were changed; `Equipped` requires the invoking player's own Character, `Unequipped` is owner-only, and `KeyPress` requires the established owner with an `Enum.KeyCode` + boolean payload. Empty legacy board handlers remain untouched. Standalone contract run: `36899662215`
- Static preflight evidence: `rhs/compatibility/PREFLIGHT.json`
- Static preflight verdict: **READY FOR LOCAL STUDIO SMOKE** with Studio API-service access disabled; runtime behavior is still unproven
- Roblox Studio runtime proof: **NOT YET PERFORMED**
- Roblox publication: **NOT REQUESTED / NOT PERFORMED**
