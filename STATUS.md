# Pip's Quest World Status

Updated: 2026-09-30

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

- Exact baseline imported: pending bootstrap workflow
- Working copy created: pending bootstrap workflow
- Byte-for-byte equality guard: configured
- Roblox Studio runtime proof: **NOT YET PERFORMED**
- Roblox publication: **NOT REQUESTED / NOT PERFORMED**
