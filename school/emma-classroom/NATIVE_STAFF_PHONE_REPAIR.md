# Native staff and phone-answer repair — October 7, 2026

## Evidence and scope

The 5:19 PM physical-iPhone recording of published version 57 shows repeated block bodies, flat hat-like hair, poorly attached-looking features in profile, and only the first choice partially visible beneath a long Religion prompt. Emma never completes an answer in the supplied 35-second recording. It is a rejected build, not evidence of acceptance. Version 55 and 57 remain in Git history; their face/geometry tests did not establish visual quality.

This repair stays in the isolated Emma classroom target. No new game, profile, wallet, or question authority is introduced. The 134 reviewed server-only questions and lifetime save fixes remain.

## Implemented

- Replaced the procedural staff bodies/hair/face overlays with standard Roblox Man/Woman R15 mesh limbs, Roblox-made hair accessories, classic clothing, and native smile face assets. Visual models are bundled under the server-only StaffAssets folder, stripped of downloaded scripts and arbitrary data. Asset IDs and hashes are in NATIVE_ASSETS_V5.json.
- Native rig attachment pairs retain their original positions. Hair aligns through the standard HairAttachment. All body segments and accessories stay attached during movement; feet normalize to the classroom floor. At most 26 physical parts per profile instead of 141–145.
- Reserved visible answer buttons outside the independently scrolling question/hint area. All three choices have at least 44px touch targets at seven tested GUI-area sizes, including short landscape screens. Long labels scale between 12 and 16px.
- Look around hides the answer card so native movement/jump controls remain accessible; Study view restores the current card.
- Questions become usable immediately. Staff take a short 0.4-second step into the teaching spot; the long side-aisle entrance is preserved for other preview callers but no longer delays the study loop.
- A failed teacher constructor cannot prevent the question from appearing. Removed the extra 1.05-second transition wait and protected the client against a new-question event arriving before Skip's RPC returns.

## Actually tested

- Executed actual client source: all three choices received, answers outside the question scroll frame, camera/card restoration, hint response, skip RPC/event race, token/index submission, correct feedback, and session-finish replay control.
- Executed actual server source: transient load/save retries, wrong hint, invalid/stale tokens, no replay star, ten-question finish, restart, skip even with a forced visual-constructor failure, monotonic and awaited-shutdown persistence.
- Executed actual StaffModel and World constructors with instance/math doubles deserialized from the bundled XML assets: 18 profiles, 14 native mesh limbs each, paired rig attachment alignment, floor/door fit, max 26 parts, hair/body pose coherence, and original 16-desk/rug/storage/window/board/aisle checks.
- Seven layout/camera projections, all-choice bounds with long prompts/hints, Luau compilation, isolated Rojo binary/XML builds, and built-place server-only answer-key boundary.
- Initial test failures exposed the importer stripping accessory handles, GUI-double false-value handling, and missing service methods. These were fixed; no budget, authority, or persistence assertions were relaxed. The previous procedural appearance-specific assertions are superseded by native-asset tests; the rejected version's tests remain at commit 159a08e747fe28a0809028af5d7038bf9cff957d.

## Not tested and known limitations

- Roblox Studio rendering, avatar engine behavior, live asset delivery, actual touch interaction, actual live DataStore/rejoin, and physical-iPhone ten-question completion have not passed on this candidate.
- The laptop was reported offline during this repair. No foreground application was opened and no desktop was captured.
- The replacements are standard avatars with approximate hair/skin/color direction, not bespoke photo-accurate staff replicas. The supplied polished renders remain a higher target. Bolich's beard, Boyer's tailored suit/pearls, and distinct bob styles are not implemented by these free baseline avatars. The classroom itself is unchanged.
- Smallest landscape screens may need to scroll the question/hint; answers remain separate. Font fitting and native controls still require an actual phone check.
- No new publishing request is included. Existing manual actual-render acceptance applies. Do not call this candidate playable, polished, or visually accepted from CI or a place upload.

## Exact next check

When the laptop is connected and native foreground testing is authorized: open the CI candidate for this PR in Studio, inspect Benulis/Kochol/Bolich/McBreen/Boyer in front and profile and all 18 in a lineup, run a real ten-question session with wrong/retry/skip, verify Look around/Study view and save/rejoin, and capture the exact candidate. Fix any native defects before issuing the existing isolated publication request. Physical-iPhone acceptance remains separate from laptop evidence.
