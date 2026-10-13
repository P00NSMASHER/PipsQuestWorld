# Native Studio review — October 12, 2026

## Owner scope
Use the authorized laptop and current classroom photographs to improve the actual classroom-only Roblox build. Keep the straight left/staff hallway and enclosed right-side closet. Exclude people, identifying photographs, cheer props and gym mats. Do not republish an older build or alter release request markers.

## Actual native execution
Opened an isolated Rojo 7.7.0 build from source `090d4cfc7ba7d0a880b9ad82aeacec0ed749c2a5` in Roblox Studio `0.742.0.7421053`. Used the Studio-native local MCP tools, not the independent headless renderer.

The real engine rejected `ArtPass.lua` during room construction:

```
Unable to assign property Face. Invalid value "" for enum NormalId
ArtPass:60 function printed
ArtPass:557 function focalTeachingArea
ArtPass:593 function decorate
World:2693 function build
```

The call supplied six arguments to a five-argument helper:

```lua
-- Rejected in the actual Roblox engine:
printed(face,"","",Enum.NormalId.Back,C.navy,face.Color)
-- Corrected:
printed(face,"",Enum.NormalId.Back,C.navy,face.Color)
```

The extra empty string shifted the surface direction and color arguments. Permissive headless property doubles did not reject it, so earlier green CI was insufficient proof that the complete native room could initialize.

Executed a native construction smoke test BEFORE repair and observed this failure. Applied the repair to the isolated source and Studio module. Repeated the same test against fresh cloned modules (no require-cache reuse), including the GalleryPass and disabled-mesh fallback. The actual engine returned:

```json
{"completeConstructor":true,"native":true,"parts":3047}
```

The test verifies the flipchart face, blank decorative text, hallway, spawn creation and <=3,050 physical Parts. Its reusable code is `qa/native-showroom-construction-smoke.luau`; it is not included in the shipping Rojo project. This is an Edit-mode construction test, NOT a Play-mode navigation, iPhone FPS or device-acceptance result.

## Native photographs of the game, actually inspected
Five native Studio screenshots were captured and reviewed locally after the construction repair: front teaching wall, rear wall, bookcase, word wall and reading rugs. They are labelled `native-before-*.jpg` in the private laptop evidence directory `StarBloxStudioBridge/emma-native-20261012`.

The real room still needs visual refinement: the floor is too plain, several signs and apple letters are too small, rug decoration has excessive raised relief, chairs/metal read too flat, and cabinet/ceiling detail remains less convincing than the supplied classroom photographs. Native screenshot review is not a declaration that the existing room is polished.

## Original material candidates generated, NOT shipping
Studio's own material-generation tool completed job `84455b0e-01b5-4921-bb3e-64b161eb7197`, creating four original narrow-board varnished oak variants. No school photos were uploaded as textures. Candidate IDs are retained to avoid generating duplicate assets on reconnection:

| Variant | Color | Normal | Roughness | Metalness |
|---|---|---|---|---|
| EmmaVarnishedSchoolOak | 109112929607127 | 134313144940116 | 140425088338626 | 96728857854661 |
| EmmaVarnishedSchoolOak1 | 79489601440793 | 103095967513906 | 118947892080900 | 98424816027237 |
| EmmaVarnishedSchoolOak2 | 96126311828550 | 74167683779259 | 114549890729763 | 84908776837610 |
| EmmaVarnishedSchoolOak3 | 132882671066604 | 81738916712755 | 79500329311923 | 106492835632212 |

The first variant was applied ONLY to the open isolated Studio scene as an exploratory floor trial (Wood, 12 studs per tile, tint 220/213/199). It is not wired into repository runtime or release files. A successful material job does not establish asset delivery or acceptable appearance in the published place. No completed post-material native screenshot was obtained.

## Interruption and restart point
Desktop Commander became unavailable during the material/visual review and then reported the laptop Offline. Repeated mutation calls were not blindly retried. The isolated worktree is named `emma-native-polish-20261012`; the open Studio file is `Emma-090d4cfc-baseline.rbxlx`. Source contains the native construction repair; the material trial exists only in the unsaved Studio scene unless subsequently saved by its owner.

On reconnection: inspect current Studio state and local/remote heads before changing anything; preserve local unsaved work; rebase the isolated source on the latest authoritative PR #351, retaining the verified flipchart repair; enlarge native signage; review actual floor, chair, rug and ceiling improvements; then perform native Play traversal and device-simulator checks. Never label desktop-emulated device testing as physical iPhone FPS.

**Release state:** PR #351 remains draft. No merge, Roblox publication, schedule changes, privacy changes or edits to `PREVIEW_REQUEST`/`PUBLISH_REQUEST` occurred during this native review. The source repair is a verified improvement, not completion of the owner's requested polished classroom.
