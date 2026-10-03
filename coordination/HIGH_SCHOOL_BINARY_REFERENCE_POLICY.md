# High School Binary Reference Extraction Policy

Purpose: prevent binary Roblox place files from becoming false blockers for the canonical Roblox High School clone.

## Verified baseline

The authorized Legacy reference is pinned by both identities:

- Git blob SHA: 95ee3d762f419bb3572e18db57c03682651dc8c4
- SHA-256: d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360

Known public mirrors currently carrying the same exact Git blob:

1. MisoNotSoupx/Old-Roblox-Place-Archive at commit b817aef0eaf77d3382acacdc8f22537e54c76822:
   Created by Users/Cindering/ROBLOX High School.rbxl
2. IIIStatusIII/Roblox-Uncopylocked-Games:
   RobloxHighSchool.rbxl

Only bytes matching BOTH pinned identities may be treated as this exact baseline.

## Hard rule for all canonical workers

A GitHub connector UTF-8 decode failure on a .rbxl, blob, or raw binary response is a transport limitation, not a provenance failure and not a product blocker.

Before declaring BINARY_REFERENCE_BLOCKED:

1. Read this policy.
2. Prefer existing verified extraction evidence when it is for the same pinned baseline.
3. If a fresh extraction is needed, create exactly one support branch named:
   support/high-school-binary-reference-extract-<purpose>
   from the exact canonical SHA or current DevEx support base.
4. Ensure that branch contains the canonical extractor and workflow:
   - scripts/extract-roblox-binary-reference.py
   - .github/workflows/high-school-reference-extract.yml
5. Create or update coordination/reference-extraction/request.json on that support branch when a new push trigger is needed.
6. Let GitHub Actions download the public binary, verify Git blob SHA + SHA-256, decompress Roblox binary chunks, extract UTF-8 evidence, and upload the extraction artifact.
7. Consume the Actions job log for compact evidence. If deeper evidence is needed, use the dedicated GitHub workflow-artifact download action and inspect the artifact in the cloud workspace.
8. Never use a paid browser, personal laptop, Roblox Studio, blob/tree/ref write workaround, or guessed data merely to overcome connector binary decoding.

## Existing verified extraction

The first validated extraction ran successfully on support/high-school-binary-reference-extractor-db0a700:

- Workflow run: 37117603516
- Job: 111187324599
- Artifact: 11272277500
- Extractor head at successful run: 819c78ac0c4b8ab0fe56e99b9a05afd7c7619b2d
- Verified bytes: 2,283,775
- Parsed Roblox binary chunks: 1,196
- Extracted string records: 66,832
- Housing-related hits: 7,428
- Script-like hits: 4,958
- Distinct asset IDs: 1,678

This run proves the path works and may be reused as immutable evidence for the pinned baseline.

Examples already recovered from decompressed binary chunks include:

- SaveHouse
- OpenFurnitureMenu
- AddFurniture
- SellFurniture
- HouseEditMenu
- FurnitureCost
- FurnitureCount
- GetFurniture
- SendNewFurniturePosition
- RemoveFurniture
- PaintbrushGui
- UnrenderedHouses
- numerous exact rbxassetid values

These strings are evidence candidates, not automatic authorization to import unrelated product code. Content QA must bind any product-facing claim to the exact object/script/context and provenance before Free Roam or another producer uses it.

## Ownership

- DevEx owns the extraction mechanism and workflow.
- Content QA owns provenance interpretation and reference fixtures.
- Product lanes may consume only Content-QA-verified outputs.
- QA verifies that binary-derived material was used without creating duplicate semantic authorities.
- Integration never performs extraction or invents missing reference data.

## Failure classification

Use BINARY_REFERENCE_BLOCKED only when:
- the exact pinned bytes cannot be retrieved from any verified mirror, OR
- hash verification fails on all verified mirrors, OR
- the canonical GitHub Actions extraction itself fails after one exact supported attempt and the failure cannot be repaired within DevEx ownership.

Do not use BINARY_REFERENCE_BLOCKED for:
- UnicodeDecodeError / UTF-8 connector failures,
- raw binary responses rejected by GitHub fetch,
- lack of text indexing,
- one mirror being unavailable when another verified mirror succeeds,
- optional bookkeeping/comment write failures.
