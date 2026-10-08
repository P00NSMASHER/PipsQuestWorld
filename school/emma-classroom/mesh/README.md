# ABVM original classroom furniture: asset integration

**Mission:** Replace primitive school desk and chair shapes with source-authored, low-poly 3D mesh assets. No educational UI or game mechanics are involved.

## What is genuinely implemented

- `build_meshes.py` creates original GLBs: `abvm_student_chair.glb` and `abvm_student_desk.glb`.
- `preview_meshes.py` independently previews the actual polygon geometry in four camera angles.
- `emma-original-furniture-mesh.yml` reproduces and retains the binary GLBs and a visual image as an Actions artifact. No cloud upload, marketplace publishing, or game deployment occurs.
- `FurnitureMeshAdapter.lua` is loaded by the actual `school/emma-showroom.project.json` place. It will install two creator-owned imported models at all **16** existing desks, but only if both model assets pass validation. If either cannot load, the entire original classroom remains unchanged.
- `FurnitureMeshConfig.lua` currently has `Enabled=false` and both Roblox asset IDs equal to 0. **The newly authored mesh has not replaced Roblox runtime furniture yet.**

## Geometry and intended scale

The source-authored student chair is roughly 2.46 × 3.77 × 2.37 Roblox studs, with a smoothly molded and modestly contoured rounded-rectangle back, matching seat, thin tubular steel supports and rubber glides. The desk is roughly 5.78 × 3.09 × 3.86 studs with a single continuous rounded laminate worktop, slim edge, metal T supports and open wire book basket. These are intentionally simple original low-poly geometry, not copied mesh assets or screenshots.

## Laptop-free Roblox Open Cloud import boundary

Roblox's Assets API accepts **Model** uploads of `.glb` files using `model/gltf-binary`. The distinct **Mesh** upload endpoint is restricted and should not be used to submit arbitrary new GLB files.

The import needs an appropriately scoped Open Cloud API key and the verified Roblox **creator userId or groupId** of the place owner. Never infer an owner ID from GitHub IDs. No creator-ownership validation, Assets API permission, or successful Roblox moderation operation has been established in this PR.

Once a trusted import yields asset IDs, enter the two returned IDs in `FurnitureMeshConfig.lua` on a separate nonproduction review commit, set `Enabled=true` only for the accepted candidate, and perform a native Roblox Studio/iPhone test before any published release. Asset models must contain only intended MeshParts/materials and no executable scripts. The runtime loader rejects model contents containing code and preserves the old classroom when either asset fails validation.

## Evidence and rejection policy

Local independent GLB round-trip and polygon/dimension tests are not equivalent to Roblox import, true physics, iPhone visual fidelity or native material correctness. The GLB preview is only an external graphics validation. Retain existing part-built furniture until native render evidence proves the replacement is better.

No change to scores, teacher NPCs, questions, UI, educational source files, scheduled tasks or production releases. PR #339 remains draft and **not published**.


## October 8 implementation and independent acceptance

Original geometric meshes and a four-angle image preview are built from source code and validated as GLBs, not fabricated images. Exact candidate geometry:

- Student chair: **2,360 triangles**, **2.460 × 3.774 × 2.365 Roblox studs**; SHA-256 `6094eb89c7467be429eeb2999ae537ca4bfe0f7a5c3f58882c4862c49a8742c4`.
- Student desk: **2,336 triangles**, **5.780 × 3.085 × 3.860 studs**; SHA-256 `5bf8558ce7ec9fcbab55d21fd5702d70438229604b6cf628918fadc3b037a084`.

Verified GitHub model generation and real preview [run 37812419207](https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/37812419207) **passed**. Both model binaries, generated manifest, and four-view image are available in that job's artifact. [Classroom-only source build run 37812419121](https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/37812419121) **passed**.

The one-time nonproduction [Open Cloud model import attempt 37812419612](https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/37812419612) **did not upload any assets**. Its strict ownership preflight could not independently resolve the creator ID of universe `10769455759` from Roblox's public game metadata, so it stopped before the API upload request. Do not infer ownership from the GitHub account, universe number, or place number. Also do not assume the existing Roblox place-publish key includes Model asset-creation permissions.

**Current blocker:** Verify the correct Roblox creator account/group and the Assets API permission. Only after both model uploads return approved owned asset IDs can the nonproduction configuration be enabled for Roblox-native inspection. This is not a laptop requirement for GLB creation, but is a Roblox authorization/import requirement. The current showroom has the loader wired in, but it intentionally retains the existing playable Part-based furniture.

The independent preview is an offline material/geometry study, not a native Roblox Studio render or proof of iPhone frame rate, camera behavior, smooth normals, final package moderation or collision.

## Creator ownership verified; Assets API authorization denied (October 8 follow-up)

Roblox's Developer Universe API returns the authenticated target's public ownership:
- Universe `10769455759`, root place `114603280760042`
- Creator: Roblox **User 6064228083**, username **DadSharkins**.
- The separate place-to-universe endpoint confirmed the same universe. The old games discovery API returned an `id=0` placeholder because the universe is private/unrated; it is unsuitable for this verification.

The importer now fetches those endpoints live and matches their IDs; the verified owner is **not hard-coded as an override**. Actual GitHub import run [37813643610](https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/37813643610) recorded `VERIFIED_CREATOR_SOURCE developer-universe and place-link` before Roblox returned **HTTP 403** to the model upload. A second run also failed in the same upload step. No asset IDs or accepted asset-operation receipts were returned. The originals remain staged, never activated.

The result establishes that the credential supplied to this job is not authorized for the requested model creation. The response does **not** establish whether the cause is missing `Assets: Read/Write` scope, an API-key creator mismatch, or another Roblox permission restriction. We will not invent a positive authorization.

The workflow now uses **manual dispatch only** and accepts **only the dedicated `ROBLOX_ASSET_API_KEY` secret**, never the place publisher's `ROBLOX_API_KEY`. This prevents duplicate model imports on routine pull-request edits and keeps existing production deploy permissions separate.

**Remaining required authorization:** Supply a creator-authorized Roblox Open Cloud API key for **Assets Read/Write** under the verified DadSharkins creator in GitHub Actions repository secret `ROBLOX_ASSET_API_KEY`. Do not paste credentials in chat. Trigger the existing import workflow once after confirming access, and inspect receipts and moderation status before enabling any visuals. Roblox has not uploaded either model, and native/iPhone visual acceptance has not occurred.


## Final authorization diagnostic

Read-only, redacted GitHub Actions check [37814123035](https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/37814123035) returned `DEDICATED_ASSET_KEY_MISSING`. The reviewed furniture GLBs and image preview generated successfully. Thus the prior HTTP 403 import attempts used the place-publishing secret fallback (`ROBLOX_API_KEY`), which Roblox denied for Model creation. The diagnostic did not display or export either key.

**Required human-controlled credential step:** Create a Roblox Open Cloud API key in the verified creator's account (**DadSharkins**, Roblox user ID `6064228083`) with **Assets Read and Write** access, then save it directly as the GitHub Actions repository secret named `ROBLOX_ASSET_API_KEY`. Do not post it in ChatGPT, a PR, or a repository file.

The import workflow no longer runs automatically on pull-request changes, and no longer falls back to the place-publishing key. Once the dedicated key exists, rerun the failed import job [37813670543](https://github.com/P00NSMASHER/PipsQuestWorld/actions/runs/37813670543), which uses the verified universe creator metadata and will prefer the new dedicated asset key. This should be done only once. Review the returned moderation and ownership data before enabling furniture visuals. No Roblox-owned furniture IDs currently exist in this branch.
