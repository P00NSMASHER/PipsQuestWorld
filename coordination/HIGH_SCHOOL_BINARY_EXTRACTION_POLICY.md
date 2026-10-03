# High School Binary Reference Extraction Policy

## Purpose
Binary Roblox place/model files such as `.rbxl` and `.rbxm` are evidence sources for the authorized Roblox High School parity program. A UTF-8 decode failure from a GitHub text reader is a transport mismatch, not a product blocker.

## Mandatory rule for all canonical workers
1. Never classify a binary `.rbxl/.rbxm` as unreadable merely because `fetch_file`, `fetch_blob`, web fetch, or another text-only reader returns a UTF-8/decode error.
2. First check `coordination/evidence/rbxl/<slug>/` for an existing verified extraction and consume the domain report owned by the lane.
3. Only Content QA or DevEx may initiate a new binary extraction. Other lanes request/consume evidence and do not create competing extractors.
4. For a new extraction, create exactly one support branch from the current coordination head named `devex/rbxl-extract-<slug>`, update `coordination/state/RBXL_EXTRACTION_REQUEST.json`, and let `.github/workflows/high-school-rbxl-binary-extract.yml` perform the download and extraction.
5. The extractor must verify the expected Git blob SHA before evidence is trusted. When an independent SHA-256 is known, it must also match.
6. Raw binary bytes are temporary runner input only. Do not commit the source `.rbxl/.rbxm` into PipsQuestWorld. Commit only deterministic text/JSON evidence.
7. Use only the standard GitHub-hosted runner on this public repository. Do not use larger/billable runners, paid browsers, the user's laptop, Remote Desktop Commander, or another paid service for routine binary extraction.
8. One extraction request = one source object. No broad archive scraping in the workflow.
9. Evidence extraction does not grant asset rights. Content QA must preserve source provenance and determine which recovered strings/assets are authorized for product use.
10. A failed extraction run is a DevEx defect with the exact run/job/error. It does not authorize guessing, weakening parity criteria, or importing a different game/version.

## Evidence layout
The extractor writes compact reports under:
`coordination/evidence/rbxl/<slug>/`

Standard files:
- `SUMMARY.md`
- `manifest.json`
- `housing.json`
- `vehicles.json`
- `avatar_shopping.json`
- `jobs.json`
- `school_class.json`
- `ui_mobile.json`
- `world_presentation.json`

Each report contains chunk/tag/offset context so Content QA can trace claims back to the exact verified binary.

## Lane consumption
- Foundation: `world_presentation.json` and relevant `ui_mobile.json` spawn/navigation presentation evidence.
- Class & Education: `school_class.json`.
- Content QA: all reports plus `manifest.json`; owns provenance decisions.
- Progression & Mobile: `ui_mobile.json`, plus economy/persistence strings in the relevant domain report.
- Free Roam: `housing.json`, `vehicles.json`, `avatar_shopping.json`, `jobs.json`.
- QA: validate candidate claims against exact extracted evidence.
- Integration/Smoke/Release: consume evidence only; never reinterpret unknown extraction gaps as PASS.

## Current verified baseline
The licensed Roblox High School baseline is:
- Git blob SHA: `95ee3d762f419bb3572e18db57c03682651dc8c4`
- SHA-256: `d71efe44c35a60cb1699c290aed708d901a3a532db74307ae502518616423360`
- Size: 2,283,775 bytes
- Source: `MisoNotSoupx/Old-Roblox-Place-Archive@b817aef0eaf77d3382acacdc8f22537e54c76822:Created by Users/Cindering/ROBLOX High School.rbxl`

The first successful extraction parsed 1,196 binary chunks and recovered lane-specific text evidence without using a laptop or paid service.
