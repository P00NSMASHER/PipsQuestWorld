# ABVM Grade 2 — Mrs. Benulis portrait NPC staging

## Intended result
A user-photo-guided, custom static GLB model replaces **only** the stationary
Mrs. Benulis display at the front of the classroom. No questions, menus,
curriculum, other Roblox experiences, or player-avatar swap.

## Source and privacy
The supplied three-view photograph was used locally to create a textured,
sculpted-geometry GLB review candidate. The private portrait and its embedded
face texture are **not** committed to this public repository. Do not expose
the private reference photo, model texture, or generated face material on
GitHub. Ask for appropriate consent before public release of a recognizable
real teacher's likeness.

## Implementation
- `TeacherPortraitAdapter.lua`: uses Roblox `InsertService:LoadAsset` only
  after explicitly enabling a verified owner-controlled Model asset ID.
- `TeacherPortraitConfig.lua`: defaults to disabled and zero ID.
- The existing anchored Mrs. Benulis R15 display remains the **live fallback**.
- The model is vetted against an allowlist (Model/Folder/MeshPart/
  SurfaceAppearance/Attachment only), has a maximum part budget and size
  limits, and is aligned to the existing display's stance and floor level.
- Async import does not block the walk-through or player spawn.

## Acceptance / remaining
1. Obtain an owner-approved, moderated Roblox **Model** asset ID from the
   privately generated GLB (not a GitHub-hosted portrait).
2. Preview the exact asset in Roblox Studio. Check front, quarter, back and
   eye-level close-ups; floor contact, correct orientation, texture mapping,
   no hair/face intersections and iPhone frame rate.
3. Set `TeacherPortraitConfig.ModelAssetId` to that verified ID, enable in an
   isolated review build, and verify the fallback is preserved on failure.
4. Publish the classroom-only place only after real Roblox/iPhone acceptance
   and the existing protected release workflow's safety checks.

## Verification honesty
Only a local offline mesh export and its independent non-Roblox render were
performed for the initial asset prototype. **No Roblox importer moderation,
native runtime acceptance, or published game version is claimed here.**
The candidate is a static decorative model, not a wearable R15 avatar.
