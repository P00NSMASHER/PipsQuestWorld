#!/usr/bin/env python3
"""Reject obsolete child-height cameras from the former through-hallway layout.

After the owner's October 11 topology correction, the rear double doors are
a sealed supply closet. The main 108-stud paper gallery is reached through
the left/staff doorway. A formerly valid camera at (0, 5.5, 34) now aims at
the inside of closet shelving while its nonblank PNG can fool generic QA.

This checks the exact *shipped* workflow camera labels and constructed Luau
collision geometry. It does not claim native Roblox camera/FOV verification.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re
from typing import NamedTuple

from walkability_audit import get_source_blockers

ROOT=Path(__file__).resolve().parents[3]
WORKFLOW=ROOT/".github"/"workflows"/"emma-showroom-visual-preview.yml"

class Camera(NamedTuple):
    eye: tuple[float,float,float]
    aim: tuple[float,float,float]

FAST = (
    "05-closet-double-doors",
    "06-hall-paper-rail",
    "07-hall-yellow-end-window",
    "08-hall-adjacent-oak-door",
    "09-hall-straight-entry-seam",
)
FULL = (
    "15-eye-closet-shelves",
    "22-hall-look-left",
    "23-hall-look-right",
    "24-hall-entry-from-gallery",
)
REGISTERED=FAST+FULL

# The 07/08 hallway cameras feed pixel-level geometry/visibility gates
# calibrated against real source-derived 1920x1080 frames. A small camera
# move may satisfy generic corridor topology yet invalidate those ROIs.
# Fail *before rendering* on unreviewed camera drift. A deliberate new
# composition must update its semantic ROIs, evidence, and this contract.
SEMANTIC_PIXEL_CAMERA_CONTRACT = {
    "07-hall-yellow-end-window":
        Camera((100,5.7,21),(155,7.35,15.5)),
    "08-hall-adjacent-oak-door":
        Camera((145,5.6,16),(153.5,6.8,25.7)),
}

def triple(raw: str) -> tuple[float,float,float]:
    parts=raw.split(",")
    assert len(parts)==3, "HALL_CAMERA_INVALID_TRIPLE "+raw
    result=tuple(float(v) for v in parts)
    assert all(-180<=v<=180 for v in result), "HALL_CAMERA_OUT_OF_BOUNDS"
    return result

def read_cameras(text: str) -> dict[str,Camera]:
    cameras={}
    lines=text.splitlines()
    for i,line in enumerate(lines):
        line=line.strip()
        name=None;eye=None;aim=None
        if line.startswith("render_eye_checked "):
            _,name,eye,aim=line.split(maxsplit=3)
        elif line.startswith('render_checked "$RUNNER_TEMP/actual-room.rbxmx"'):
            assert i+1<len(lines), "HALL_CAMERA_MISSING_RENDER_ARGS"
            entries=lines[i+1].strip().split()
            assert len(entries)==3, "HALL_CAMERA_INVALID_RENDER_ARGS"
            name,eye,aim=entries
        if name is None or name not in REGISTERED:
            continue
        assert name not in cameras, "HALL_CAMERA_DUPLICATE "+name
        cameras[name]=Camera(triple(eye),triple(aim))
    assert set(cameras)==set(REGISTERED), (
        "HALL_CAMERA_INVENTORY_OR_NAMING_REGRESSED "+
        str(sorted(set(REGISTERED)-set(cameras))))
    return cameras

def check_role(name: str, cam: Camera) -> None:
    x,y,z=cam.eye
    tx,ty,tz=cam.aim
    assert 4.5<=y<=6.2 and 5.0<=ty<=10.0, (
        "HALL_CAMERA_NOT_CHILD_EYE "+name)
    assert sum((a-b)**2 for a,b in zip(cam.eye,cam.aim))>5, (
        "HALL_CAMERA_ZERO_DIRECTION "+name)

    # Source-constructed floor/roof bounds; native Roblox FPS and camera
    # behavior remain a separate device gate.
    main=(55.0,160.0,5.5,25.5)
    closet=(-4.6,4.6,28.3,34.3)
    side=(38.0,53.0,6.0,25.5)
    def inside(bounds):
        xmin,xmax,zmin,zmax=bounds
        return xmin<=x<=xmax and zmin<=z<=zmax
    if name in ("05-closet-double-doors","15-eye-closet-shelves"):
        assert inside(closet), "HALL_CAMERA_CLOSET_EYE_OUTSIDE_CLOSET "+name
        if name=="05-closet-double-doors":
            assert tz<27.5, "HALL_CAMERA_CLOSET_DOOR_AIM_WRONG "+name
        else:
            assert tz>34, "HALL_CAMERA_CLOSET_SHELVES_AIM_WRONG "+name
    elif name=="09-hall-straight-entry-seam":
        assert inside(side) and tx>=65 and 9<=tz<=23, (
            "HALL_CAMERA_STRAIGHT_JUNCTION_WRONG_SIDE "+name)
    else:
        assert inside(main) and not inside(closet), (
            "HALL_CAMERA_INSIDE_SUPPLY_CLOSET_NOT_GALLERY "+name)
        if name=="06-hall-paper-rail":
            # On-source rendered evidence: the initial close-up showed 4
            # papers, and the first corrected look-along-wall shot showed 7.
            # The second must exceed the seven-paper independent overview.
            # Reject overly short, head-on, or wrong-room fallback cameras.
            assert 90<=x<=110 and 12<=z<=17.5 and 128<=tx<=152 and (
                7<=tz<=11 and 28<=tx-x<=53
            ), "HALL_CAMERA_PAPER_AIM_TOO_SHORT_OR_OFF_GALLERY"
        elif name=="07-hall-yellow-end-window":
            assert tx>=150 and 12<=tz<=19, (
                "HALL_CAMERA_YELLOW_WINDOW_AIM_MISSES_FAR_END")
        elif name=="08-hall-adjacent-oak-door":
            assert tx>=150 and 23<=tz<=27, (
                "HALL_CAMERA_OAK_DOOR_AIM_MISSES_NORTH_FACADE")
        elif name=="22-hall-look-left":
            assert tx<=90, "HALL_CAMERA_WRONG_LEFT_DIRECTION"
        elif name=="23-hall-look-right":
            assert tx>=140, "HALL_CAMERA_WRONG_RIGHT_DIRECTION"
        elif name=="24-hall-entry-from-gallery":
            assert tx<=42 and 10<=tz<=22, (
                "HALL_CAMERA_MISSES_ONLY_CONNECTED_EXIT")

def inspect(cameras: dict[str,Camera], blockers=None) -> None:
    assert set(cameras)==set(REGISTERED), "HALL_CAMERA_INVENTORY_REGRESSION"
    for name,expected in SEMANTIC_PIXEL_CAMERA_CONTRACT.items():
        assert cameras[name]==expected, (
            "HALL_SEMANTIC_PIXEL_ROI_CAMERA_DRIFT "+name
            +"; recalibrate the real screenshot gates before updating this camera"
        )
    for name,cam in cameras.items():
        check_role(name,cam)
        if blockers is not None:
            bad=sorted(set(b.name for b in blockers if b.covers(cam.eye[0],cam.eye[2])))
            assert not bad, "HALL_CAMERA_EYE_INSIDE_REAL_COLLIDER "+name+":"+repr(bad[:8])

def self_test() -> None:
    # Synthetic, publicly safe camera location mutation fixtures.
    example={
        "05-closet-double-doors":Camera((0,5.5,31),(0,6.9,26.8)),
        "06-hall-paper-rail":Camera((100,5.5,16),(130,8,9)),
        "07-hall-yellow-end-window":Camera((100,5.7,21),(155,7.35,15.5)),
        "08-hall-adjacent-oak-door":Camera((145,5.6,16),(153.5,6.8,25.7)),
        "09-hall-straight-entry-seam":Camera((44,5.5,15.5),(78,6,15.5)),
        "15-eye-closet-shelves":Camera((0,5.5,30),(0,7.5,35.15)),
        "22-hall-look-left":Camera((111,5.5,15.5),(76,7,15.5)),
        "23-hall-look-right":Camera((111,5.5,15.5),(150,7,15.5)),
        "24-hall-entry-from-gallery":Camera((75,5.5,15.5),(39,6.9,15.5)),
    }
    inspect(example)
    mutation_specs={
        "obsolete_paper_eye_in_closet":
            ("06-hall-paper-rail",Camera((0,5.5,34),(125,9,4.98))),
        "obsolete_closet_exit_camera_outside":
            ("05-closet-double-doors",Camera((4,5.5,40),(0,6.9,26.8))),
        "old_full_camera_inside_closet":
            ("22-hall-look-left",Camera((0,5.5,32),(76,7,15.5))),
        "wrong_turn_aim":
            ("24-hall-entry-from-gallery",Camera((75,5.5,15.5),(75,7,38))),
        "not_child_eye":
            ("06-hall-paper-rail",Camera((100,17.5,16),(130,8,9))),
        "old_four_sheets_false_accept":
            ("06-hall-paper-rail",Camera((112,5.5,17),(125,9,4.98))),
        "camera_crosses_gallery_centerline":
            ("06-hall-paper-rail",Camera((100,5.5,20),(151,8,8))),
        # Both are otherwise valid/walkable and would have passed the
        # existing broad hallway-role checks, but shift actual pixel ROIs.
        "moved_end_window_while_pixel_gate_unchanged":
            ("07-hall-yellow-end-window",
             Camera((100,5.7,21),(155.5,7.35,15.5))),
        "moved_oak_door_while_pixel_gate_unchanged":
            ("08-hall-adjacent-oak-door",
             Camera((145,5.6,16),(153.5,6.8,25.2))),
    }
    for reason,(name,incorrect) in mutation_specs.items():
        changed=dict(example)
        changed[name]=incorrect
        try:
            inspect(changed)
        except AssertionError:
            pass
        else:
            raise AssertionError("HALL_CAMERA_NEGATIVE_TEST_ACCEPTED "+reason)
    print("HALL_CAMERA_LAYOUT_SELF_TEST_PASS "
          "obsolete_closet_camera,wrong_hall,wrong_aim,height_rejected=true "
          "old_four_sheets_view_and_wrong_distance_rejected=true"
          " photo_pixel_roi_camera_drift_rejected=true")

def main() -> None:
    ap=argparse.ArgumentParser()
    ap.add_argument("--luau",help="Pinned Luau executable; required for physical collision validation")
    ap.add_argument("--self-test",action="store_true")
    args=ap.parse_args()
    if args.self_test:
        self_test()
        if not args.luau:
            return
    if not args.luau:
        ap.error("--luau required unless --self-test")
    cameras=read_cameras(WORKFLOW.read_text(encoding="utf-8"))
    blockers=get_source_blockers(args.luau)
    inspect(cameras,blockers)
    print("HALL_CAMERA_REAL_SCENE_PASS cameras="+str(len(cameras))
          +" real_colliders="+str(len(blockers))
          +" closet_and_hall_distinguished=true"
          +" stale_camera_regression_rejected=true"
          +" native_iphone_acceptance=false")
    for name,cam in cameras.items():
        print("HALL_CAMERA_VALID",name,cam.eye,"aim",cam.aim)

if __name__=="__main__":
    main()
