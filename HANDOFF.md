# Second-grade overlap repair (2026-11-01)

Implemented: separated the window radiators, open-shell bookcases, rug, west-wall decor, entry, teaching-wall carriers, activity mats, teacher desk/chair/papers/pencils/flowers, student-work layers, blinds/worksheets, and the duplicated classroom/hall wall return. Added exact constructed-scene overlap guards plus ten overlap mutation controls.

Actually tested: pinned Luau 0.741 compilation; all 23 showroom/runtime audits; 13 dedicated second-grade negative controls; 3,649-Part exact source export under the 3,650 cap; all 11 continuously supported routes; release-provenance and synthetic visual self-tests; Rojo 7.7.1 RBXL/RBXLX assembly. Candidate RBXL SHA-256: `44bc7f280f450c3654692d9b6fd8b0b7f49e285e5f4353de557dbaabce3e593b`.

Not tested: native Roblox Studio rendering/physics, physical-iPhone performance, or device visual acceptance. This evidence does not itself prove publication.

---

# ABVM first/second-grade across-hall candidate (2026-10-31)

Implemented on `feat/second-grade-classroom-replica-20261031`: retained the existing first-grade room, opened a true doorway directly across its vestibule, and added the photo-matched second-grade room with 20 burgundy-chair desks, dual windows/radiators, blackboard/Smartboard wall, polka-dot rug, coat storage, activity/teacher areas, and private-reference-safe decor.

Actually tested: all showroom Luau compilation; Rojo assembly; 3,637-Part complete source construction; dedicated second-grade positive/negative audit; all original room/hallway audits; five supported floors and 11 continuous routes including the new room; source-derived 1920x1080 visual review from the hall, entry, board, windows, teacher area and cutaway. The fidelity pass added physical student-work sheets, anchor charts, lesson cards, clipped window work, and ceiling leaves while staying below the 3,650-Part cap.

Not tested: native Roblox Studio Play rendering/physics, physical iPhone performance, or device visual acceptance. Not published or pushed. Source-derived screenshots do not render every SurfaceGui label and are not native acceptance.

Private source photos remain outside this repository under the October 31 task folder. Do not add them to Git or embed them in Roblox.

---

# ABVM Grade 2 Storytime Corner Handoff (2026-10-16)

**Scope:** Owner screenshot request only; large purple upholstered armchair in the front-right corner of the ABC/sun reading rug, and move the original box fan left along the teaching wall. The existing 16 student seats, the smaller purple molded chair behind the teacher desk, all schoolwork, walls, rugs, hallway, and Roblox IDs are unchanged.

**Implemented on `feat/emma-storytime-armchair-fan-left-20261016`:** 
- `school/emma-classroom/showroom/Room.lua`: adult-size fabric chair with curved cushion/back/arm profiles, lumbar pillow, contrast piping, two tuft buttons, and one collidable base. Angled 20 degrees toward the reading rug at (33.10, -31.80).
- Repositioned all 13 original low-box-fan parts and native grille as one assembly by changing their shared X anchor from 31 to 18. Fan remains noncolliding and faces into the classroom.
- Strengthened `audit_photo_landmarks.py` and `audit_purple_corner_chair.py` with position, floor, noncollision, mobile part-budget, carpet clearance and negative mutation checks.

**Verification:** Exact-head GitHub Actions checks are required before acceptance. In-source tests are not equivalent to an in-engine Roblox Studio render, a published-place screenshot, mobile FPS, or iPhone walkability.

**Not done:** No merge to the protected release branch, no Roblox publication, and no changes to the guarded publish request. The authorized Studio laptop was offline at inspection.

---

# Grade 2 third-round visual repairs

Implemented: attachment-aligned, wider native R15 limbs for Mrs. Benulis;
matching cream/navy reading banner relocated above the right window;
hallway-side brick finish around the staff doorway and solid upper gap infill.

Tested: Luau compilation, Rojo showroom assembly, showroom isolation check,
executed owner-polish geometry audit and its negative control.

Not tested: native Roblox rendering, physical-iPhone appearance, traversal.
The avatar mesh silhouette requires native visual acceptance; source checks
cannot establish that it looks natural. No publish receipt for this round yet.
