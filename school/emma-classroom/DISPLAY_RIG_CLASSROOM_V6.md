# Stable display avatars and assembled classroom objects

## Trigger and scope
The user's version-58 recording shows detached or missing teacher heads during
transitions. It is FAILED visual evidence. The native rig builder and per-part
CFrame animation were both writing anchored NPC transforms; this revision removes
that conflict rather than adding another animation system. Staff use the existing
14 native mesh limbs, standard smile heads and hair assets in a neutral rest pose.
RequiresNeck, AutoRotate and EvaluateStateMachine are disabled on these display
Humanoids. Player movement remains controlled by the existing player Humanoid.

Previous teacher models are destroyed before replacement. Study mode places each
new teacher directly at the front; the animated entrance is intentionally removed
for stability. Existing free-roam camera, answer authority and save state remain.
Hair textures on short styles are cleared and tinted to staff metadata, removing
the orange stock bun from brown/gray-haired teachers. These are stylized avatars,
not photo-accurate bespoke models.

The classroom adds coherent assembled details: notebook page margins, metal
bindings, desk bolts and rubber glides; laptop hinges, 40 keys, webcam and trackpad;
a tilted globe with curved meridian cradle, equator and low-relief land patches;
cabinet inset doors, hinges and pulls; cart uprights and supplies; tissue slot and
folded tissue; wastebasket opening and metal ribs. All small details are
noncolliding. Duplicate hidden notebook lines were removed to stay under the
unchanged 3,000-descendant classroom budget.

## Hunter repository reuse
Reviewed `P00NSMASHER/github-value-hunt-ledger/lanes/13-games-education-starblox.md`.
Its relevant avatar finding is M3-org/CharacterStudio, pinned at
293182bf4a6087f4a4a7fd00e4fbdfb590029da7. Inspected the actual
`src/library/characterManager.js` and LICENSE. The `removeCurrentCharacter` /
`removeCurrentManifest` clear-before-replace lifecycle is adapted to synchronous
Roblox Instance destruction in Main.server.lua. MIT notice is preserved under
THIRD_PARTY_LICENSES/CharacterStudio-MIT.txt.

Reuse is narrow. Three.js/VRM animation and export code is not a native Roblox
rig or a furniture pack, and no sample avatar assets were imported. BKT, IRT,
QTI and learning telemetry findings do not fix this visual defect. Existing
bundled Roblox body/hair/clothing assets are reused instead of rebuilding anatomy.
No claim is made that the small lifecycle adaptation saves weeks of work; it
avoids overlapping model replacement. Classroom detail code is original.

## Actually tested
- Compiled all classroom Lua; built the isolated binary and XML with Rojo 7.7.1.
- Executed all 18 StaffModel constructors using the actual bundled XML assets:
  14 native limbs, <=26 parts per staff, floor/doorway fit, standard face/hair.
- New regression rejects BuildRigFromAttachments and competing joints. Repeated
  61 whole-model rotations per teacher preserve relative head/torso and hair poses.
- The geometry double's PivotTo now sets the exact requested root target; its old
  repeated inverse-matrix multiplication introduced exponential rounding drift.
  Existing tolerance, object budget and geometry assertions were not relaxed.
- Actual server source tests cover correct/wrong/retry, invalid/replay tokens,
  ten-answer finish/restart, save retries/monotonic saves/shutdown and visual failure;
  a new assertion rejects construction while any prior teacher still has a parent.
- Actual client source tests cover all choices, hint/correct/session feedback,
  Skip RPC/event ordering and free-roam camera/native-control restoration.
- Existing seven viewport-layout tests and built-place server-only answer-key guard.

## Not tested / known limits
No native Roblox engine or iPhone visual acceptance: laptop is offline. Service
doubles do not prove Roblox rendering, loaded meshes, likeness, touch performance,
or live DataStore behavior. The supplied real classroom images are not available
in this scratch workspace; the existing photo-derived layout is preserved rather
than claiming a newly verified one-to-one replica. Actual before/after Roblox
capture remains necessary. No visual quality score is assigned.
