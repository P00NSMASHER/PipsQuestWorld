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
