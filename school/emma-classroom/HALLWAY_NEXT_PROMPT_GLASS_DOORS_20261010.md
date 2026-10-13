# Next autonomous prompt: Photo-authentic glass school doors — execute and verify

## Objective
Act as the lead Roblox environment reconstruction engineer and adversarial visual QA reviewer for Emma's classroom-only ABVM Roblox place. The last clean source-derived hallway render at commit 7a51a498b583f460284198d10c2b4c232ba2a644 shows the most important remaining visible defect: both open classroom doors are **opaque ten-stud oak slabs despite decorative translucent "Door glass" parts**. Compare screenshot \`24-hall-door-from-corridor.png\` from GitHub Actions run 38032005744 to the six owner's hallway photos in the conversation. Repair this particular photographed architectural feature in the actual showroom game source. Do not substitute a generated concept image for a Roblox code change.

## Source and scope
- Repository: \`P00NSMASHER/PipsQuestWorld\`; stacked draft PR #343 on top of draft classroom PR #339.
- Canonical Rojo place: \`school/emma-showroom.project.json\`, actual double doors in \`school/emma-classroom/showroom/Room.lua -> buildBackDoorAndHall()\`.
- Preserve exact doorway footprint, open leaf rotations, double-door count, brass threshold, transom, original doorway clearance, translucent green shamrock decorations, and both long-hallway walk routes.
- Preserve the parent classroom changes, curriculum archive, task automations, existing studio release gates and furniture-asset fallback.

## Implementation contract
1. Remove the *full-height opaque backplane* behind each door glass pane; retain genuine structural lower oak panels, side stiles, glass lintel, and glass sill. Make each pane reveal the actual room behind it, not an opaque timber slab or a faked texture.
2. Preserve old physical part IDs and part names where practical, especially \`Open classroom door\` (lower solid leaf), \`Door glass\`, \`Glazed door solid oak rail\`, and \`Glazed door oak side stile\`, with the latter physically forming the glass aperture's frame.
3. Add a thin crossbar dividing glazed lights and a modest metal pull to match original photos without introducing blocking physics. The decorative school signage stays anonymous; do not publish or embed photos of children.
4. Preserve \`CanCollide=false\` on all leaf/stile/crossbar/glass/handle parts. No in-world UI, scoring, teacher NPCs or lesson changes.
5. Keep the full built place under 3,100 physical Roblox Parts; instead of increasing that cap, recycle existing frame Parts.
6. Add an **executed Luau** construction probe that catches the exact prior failure: restoring a ten-stud opaque wood backplane, setting glass transparency to zero, disabling collision safety, or disconnecting the glass from its frame. Require deliberate adversarial negative tests to prove each regression is rejected.
7. Compile and Rojo-build the exact classroom-only source in CI; run photo-hallway audit, full navigation and independent child-eye corridor render cameras. Visual inspection must show the formerly solid-looking door has transparent glazing; if renderer limitations prevent confirmation, report that candidly.
8. Never publish or merge this to the live Roblox universe until a **native iPhone** camera/movement/performance pass proves the true glass, correct framing and collision-safe threshold.

## Recorded execution
Implemented two real-glass apertures with original outer wood frame parts reconfigured, plus one center crossbar and one brass handle per leaf. Added \`school/emma-classroom/showroom/audit_glazed_door_aperture.py\` with constructed-Luau and adversarial negative tests, invoked in \`.github/workflows/emma-showroom-ci.yml\`. First source build reports 3,096 physical parts and passes hallway/aisle navigation plus the new glass aperture assertions. Source-derived visual and native device review remain separate acceptance gates.