# Emma classroom: isolated Roblox Open Cloud engine QA

**Status:** Workflow implemented. Cloud execution requires a dedicated private Roblox QA universe/place and QA-only key.

## One-time Roblox provisioning

1. In [Roblox Creator Dashboard](https://create.roblox.com/dashboard/creations), create a **new private experience** named "Emma Classroom Engine QA". Do not use the existing published/private Pip High playtest place or the original StarBlox universe.
2. Record the new universe ID and its root place ID.
3. In [Creator Dashboard API Keys](https://create.roblox.com/dashboard/credentials), create a key called EMMA_ENGINE_QA_CI. Restrict the key **only** to the new QA universe and grant exactly these operations:
   - universe.places:write
   - universe.place.luau-execution-session:write
   No DataStore, messaging, monetization or live-place restart permissions. GitHub-hosted runners have dynamic IPs.
4. In GitHub repository Settings > Secrets and variables > Actions, create:
   - Secret ROBLOX_QA_API_KEY (never put the key in source control)
   - Variable ROBLOX_QA_UNIVERSE_ID
   - Variable ROBLOX_QA_PLACE_ID
5. Dispatch the Emma Engine Cloud QA (isolated) workflow and require an exact-head successful cloud run before merging the draft PR.

## What it checks

The workflow runs local guardrails, verifies the QA key's universe and exact scopes through Roblox introspection, hash-pins Rojo, builds the candidate from school/default.project.json, and uploads to a **Saved** version of the QA place, never Published. It executes real Roblox engine Luau against that version and demands an explicit PASS receipt.

The Luau test checks that classroom server modules load, validates question bank structure and privacy, tests wrong/correct answers, feedback, idempotency conflicts, duplicate-completion blocking, and class completion. No DataStore write or live player mutation is performed.

## Explicit limitations

This is **headless engine QA**, not visual gameplay QA. It does not verify the appearance of the classroom, NPC animations, physical mobile controls, camera feel, or multiplayer player experience.

Missing credentials, wildcard/unscoped keys, wrong target IDs, invalid builds, API errors, task failures and missing PASS receipts fail closed. Do not copy an existing production ROBLOX_API_KEY into ROBLOX_QA_API_KEY. Do not schedule recurring tests until first-time provisioning and a successful cloud execution.
