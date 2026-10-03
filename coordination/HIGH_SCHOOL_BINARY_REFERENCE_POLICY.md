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


## Proven cloud artifact consumption path

This path has been validated end-to-end and is mandatory before any worker calls a binary reference local-only or blocked.

Validated extraction:
- Workflow run: 37117831711
- Job: 111187960403
- Extractor head: 8a7363c785b15fd5ff3110a22abf5e22b14f152e
- Artifact ID: 11271783526
- Artifact name: high-school-binary-reference-extract
- Verified Git blob SHA: 95ee3d762f419bb3572e18db57c03682651dc8c4
- Verified SHA-256: d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360

Deep-evidence procedure:
1. Read the workflow run and confirm success on the expected extractor head.
2. List artifacts for that run and select only the expected extraction artifact.
3. Use the dedicated GitHub workflow-artifact download action with the exact artifact ID. Do not fetch the raw .rbxl through a text endpoint.
4. The downloaded ZIP is materialized into the cloud workspace by the connector. Use the returned file reference/path; do not involve a personal laptop.
5. Unzip only in the cloud workspace.
6. Read reference_manifest.json first. Evidence is admissible only when verified=true and BOTH the Git blob SHA and SHA-256 equal the pinned baseline identities above.
7. For targeted reference work, search the UTF-8 outputs instead of re-reading the binary:
   - script_like_strings.txt for recoverable source/script seams,
   - housing_hits.txt for housing/editor evidence,
   - all_strings.txt for exact object/property/UI strings,
   - asset_ids.txt for candidate asset identifiers,
   - chunk_manifest.json for decompressed-chunk provenance.
8. Content QA must bind any recovered product-facing string, asset ID, constant, hierarchy, or code seam to the surrounding extracted context before a producer treats it as exact.
9. Reuse this immutable artifact for the same pinned baseline. Do not rerun extraction merely because another worker needs a different search term.
10. If the artifact has expired or a materially different binary reference is required, trigger the canonical support-branch extraction workflow once, then consume the new verified artifact by the same procedure.

Successful cloud materialization has been demonstrated for artifact 11271783526, including direct inspection of script_like_strings.txt and housing_hits.txt. Therefore a UnicodeDecodeError, raw-binary rejection, connector text-size limit, or inability to display the .rbxl itself is NOT LOCAL_ONLY_REQUIRED and is NOT BINARY_REFERENCE_BLOCKED.

High-signal exact evidence already recovered from the verified artifact includes:
- OpenFurnitureMenu and the original event wiring,
- AddFurniture and SellFurniture event/server seams,
- SaveHouse and ExitHouse,
- HouseMoveIncrement values 1, 2, 4, 8, 16,
- HouseRotateIncrement values 45 and 15,
- original editing tool names Move, Paint, Remove,
- FurnitureShopCategory with default Seating,
- furniture item thumbnails sourced from ModelID,
- inventory quantity display and item cost behavior,
- sell confirmation at 70 percent of ItemCost,
- original text explaining that furniture can be tried before paying when the house is saved.

These are verified extraction facts. Whether and how they become product code still follows Content QA provenance and normal QA/Integration gates.

## Zero-spend runner rule

Keep binary extraction on the repository's standard public-repository GitHub-hosted runner labels (for example ubuntu-latest). Never select a larger/paid runner for this workflow. Artifact retention should be bounded and existing verified artifacts should be reused when possible.
