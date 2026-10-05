# PR 214 Foundation authority audit and entrance/atrium implementation specification

## Artifact contract

- **Owner:** Roblox High School Foundation
- **Input SHA:** `baa6a24f6bcf11d01e014d0c3caa2ef29ae78eb8` (PR 214), based on canonical `5fd5c0539229b629eda865e574539990d6e17b5b`
- **Reference clip/time:** A@00:05 exterior entrance; A@00:25 atrium; A@00:45 corridor/stairs; A@02:05 stair flight and item-stack view
- **Acceptance criteria:** preserve exactly one mapped CampusBuilder, one mapped Foundation clock/schedule authority and one `MainSpawn`; keep the exterior entrance centered and readable; preserve a low circular atrium display with open circulation; maintain a broad centerline from atrium to corridor/stair; retain blue stair rails and red/blue wall bands; keep all rendered/device and traversal claims pending until executed
- **Output location:** `coordination/foundation/pr214-baa6a24-environment-authority-and-entrance-atrium-spec.md`
- **Blocker:** Foundation does not own the current product producer slot; PR 214 is owned by Pip High Free Roam. Rendered comparable-FOV desktop/iPhone/iPad captures and physical traversal are unavailable and remain required.
- **Next handoff:** independent QA reviews exact PR 214 head for the current interaction repair. Control Tower may assign this bounded entrance/atrium implementation only after the current producer completes the full CI -> QA -> Integration -> Smoke -> Package pipeline.
- **Status:** `PASS_STATIC_AUTHORITY_CONTINUITY__REFERENCE_GAPS_PINNED__IMPLEMENTATION_PREP_ONLY__NO_PRODUCT_WRITE`

No product file, automation, clock, spawn or schedule was changed.

## Evidence basis and limits

The durable Content QA pack at PR 200 head `b40d677c3c821da3400e0b31ce1ccef4a080269e` is the visual evidence source. It pins the three Library identities, byte hashes, video metadata and extracted-frame hashes. No new raw-frame claim is created here.

Observed, not inferred:

- A@00:05 shows a centered entrance and broad stairs together, a crest/shield in the entrance zone, red/white/blue massing, and compact edge HUD.
- A@00:25 shows a bright atrium with one low circular multi-tier display, repeated linear ceiling lights, red/white/blue bands, and visible open floor around the display.
- A@00:45 shows a broad central traversal sightline toward an ascending red/blue circulation element.
- A@02:05 shows a stair flight with blue rails and red/blue wall bands; the visible 2x marker forbids movement-speed or animation-timing inference.

Exact RGB, asset IDs, hidden hierarchy, collision values and lighting configuration are not established by the footage.

## Exact-head authority audit

PR 214 changes five files, all in client/shared mapping or tests. Its `CampusBuilder.server.lua` blob is unchanged from canonical at `1e49e99026352ffd5e412515636cc662097a3305`. It introduces no server or world builder.

The only project-map change adds `FeaturePanelController.lua` under `ReplicatedStorage.Shared`. The mapped server tree remains unchanged:

- one `CampusBuilder`;
- one `FoundationBootstrap`;
- one `MainSpawn` construction;
- no mapped `SchoolLoop.server.lua`;
- no new world, clock, schedule, location, economy, progression or persistence authority.

All three exact-head PR guards are green on `baa6a24`: Foundation run 37247220569, Class/Education run 37247220604 and Progression run 37247220568. No independent review is present. Static authority continuity passes; QA, rendered/device and runtime status remain pending.

## Current implementation inventory

| Surface | Current source geometry | Reference disposition |
| --- | --- | --- |
| Spawn/approach | `MainSpawn` at (0, 1.55, 177), 10×1×10, blue Neon; school lies toward decreasing Z | Single spawn authority and centered approach are present; visible spawn-pad prominence needs rendered adjudication |
| Exterior massing | Blue facade panels centered at x ±49; red columns at x ±80/±18; white header; red roofline | Red/white/blue massing is present |
| Entrance | Three glass doors at x -8/0/8; 116×34 plaza; 18×82 center walk; seven broad decorative step bands | Centered entrance and broad stair composition are present statically; physical/avatar visual traversal is unproved |
| Crest | 15×17 crest at x 49 rather than the entrance centerline | Concrete parity gap: reference places the crest/shield in the entrance zone |
| Atrium | 54×32 marble lobby floor; three-tier circular display centered at (0, z 91), max diameter 26; 16 repeated ceiling strips | Low circular focal display and repeated lights are present |
| Atrium circulation | Front desk spans x -30..-8 and z 93.5..98.5; circular display projects to x ±13 and z 78..104 | Concrete source-level risk: desk and display envelopes overlap in plan on the left, reducing the reference's open circulation |
| Corridor | 34-stud central hall; 25-stud stair flight; wall centers x ±16.5 | Broad central spine and centered stair are present |
| Stair details | Two blue flight rails, eight blue posts, four red/blue wall bands; accents noncollidable | A@02:05 static composition is present; rendered clipping and ascent/descent remain pending |
| Lighting | Brightness 2, ClockTime 10.5, ShadowMap, repeated Neon strips | Daylight baseline exists, but no rendered luminance/readability PASS is available |

Current palette values are implementation anchors only, not reference-extracted truth: blue `#2570BE`, red `#D83F46`, white `#F5F7FA`, wall `#E8ECF3`, neutral floor `#CBD2DC`, and warm hall wood `#EEE1BE`.

## Bounded next implementation specification

This is preparation only. If Control Tower later grants Foundation the sole product producer slot, constrain the change to `school/src/server/CampusBuilder.server.lua` and `school/tests/foundation_world_contract_spec.lua`. Do not touch clock, schedule, remotes, persistence, economy, client HUD or menu behavior.

### 1. Exterior entrance and crest — A@00:05

- Keep `MainSpawn` as the only `SpawnLocation`; do not add a second spawn or teleport authority.
- Preserve the approach centerline at x=0 and the school-facing orientation toward decreasing Z.
- Keep the broad stair/plaza silhouette within the current x ±36 visual envelope and the three-door entrance within x ±12.
- Move the crest/shield composition into the entrance-zone envelope: center x within ±12, y 12..21, front plane z 121.8..123.5. Do not infer an asset ID; a source-built shield placeholder remains acceptable until licensed art is explicitly pinned.
- Preserve the blue side masses, red vertical framing, white header/canopy and red roofline. Current RGB values remain provisional.
- Keep one continuous collidable approach surface from spawn to doors. Decorative tread parts may remain noncollidable only if a rendered traversal proves no feet/root/camera/accessory clipping.
- The visible spawn pad must not dominate the comparable A@00:05 camera. If it does, make the existing spawn presentation unobtrusive without replacing the spawn object.

### 2. Atrium display and circulation — A@00:25

- Preserve exactly one low circular multi-tier focal display centered on x=0.
- Keep its maximum current diameter at 26 studs or smaller unless a rendered comparison supports expansion.
- Guarantee a minimum 8-stud clear navigable ring around the display's 13-stud radius: no collidable desk, wall, planter or rail may enter the derived x/z clearance envelope.
- Move the existing `FrontDesk` and `FrontDeskTop` outside that ring; a bounded source placement near x=-38, z=101 is compatible with the current school floor, but the final position must be selected by rendered comparable-FOV review.
- Retain repeated linear ceiling lights across both axes. The current 4×4 array is a valid provisional implementation, not an asserted reference count.
- Retain red and blue longitudinal bands while leaving the center view visually bright and uncluttered.

### 3. Corridor and stair sightline — A@00:45 and A@02:05

- Preserve the 34-stud central hall and 25-stud stair width.
- Keep the center corridor lane x ±10 free of new collidable props between the atrium exit and the stair approach.
- Preserve the two separately named blue flight rails, eight posts, four local wall bands and the distinct transverse landing rail.
- Keep rail/post/band accents noncollidable unless runtime evidence proves an intentional collision surface is needed.
- Do not derive traversal speed or animation timing from A@02:05.

## Deterministic acceptance contract

Static tests for a future authorized product head must prove:

1. exactly one `Instance.new("SpawnLocation")` and one `MainSpawn` assignment;
2. one mapped `CampusBuilder` and one mapped `FoundationBootstrap`;
3. crest center x inside ±12 and facade/door centerline preserved at x=0;
4. one circular atrium display group with maximum diameter <=26;
5. no collidable atrium prop intersects the derived 8-stud clearance ring;
6. central hall width >=34 and stair width >=25;
7. center corridor x ±10 contains no newly introduced collidable obstruction;
8. both flight rails, eight posts, four wall bands and a distinct landing rail remain present;
9. all three exact-head guards are green.

Rendered/runtime acceptance remains separate and mandatory:

- comparable-FOV desktop, iPhone-class and iPad-class captures at A@00:05, 00:25, 00:45 and 02:05;
- spawn -> approach -> doors -> atrium -> both sides of display -> corridor -> stair ascent/descent;
- no avatar, camera, accessory or decorative-tread clipping;
- clear crest readability, open atrium circulation and bright ceiling-light readability;
- no promotion of static/headless success to visual parity.
