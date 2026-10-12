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

from walkability_audit import (Blocker, FloorSupport, Grid, START,
                               get_source_geometry)

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
    "09-hall-left-floor-roof-junction",
)
FULL = (
    "15-eye-closet-shelves",
    "22-hall-look-left",
    "23-hall-look-right",
    "24-hall-entry-from-gallery",
)
REGISTERED=FAST+FULL

def triple(raw: str) -> tuple[float,float,float]:
    parts=raw.split(",")
    assert len(parts)==3, "HALL_CAMERA_INVALID_TRIPLE "+raw
    result=tuple(float(v) for v in parts)
    assert all(-120<=v<=120 for v in result), "HALL_CAMERA_OUT_OF_BOUNDS"
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

    # Actual authored floor bounds, checked elsewhere against the built
    # geometry by audit_left_hall_junction and export_source_scene.
    main=(-53.0,53.0,27.5,48.5)
    closet=(-4.6,4.6,28.3,34.3)
    side=(38.0,53.0,7.0,27.0)
    def inside(bounds):
        xmin,xmax,zmin,zmax=bounds
        return xmin<=x<=xmax and zmin<=z<=zmax
    if name in ("05-closet-double-doors","15-eye-closet-shelves"):
        assert inside(closet), "HALL_CAMERA_CLOSET_EYE_OUTSIDE_CLOSET "+name
        if name=="05-closet-double-doors":
            assert tz<27.5, "HALL_CAMERA_CLOSET_DOOR_AIM_WRONG "+name
        else:
            assert tz>34, "HALL_CAMERA_CLOSET_SHELVES_AIM_WRONG "+name
    elif name=="09-hall-left-floor-roof-junction":
        assert inside(side) and tz>=30, (
            "HALL_CAMERA_LEFT_JUNCTION_WRONG_SIDE "+name)
    else:
        assert inside(main) and not inside(closet), (
            "HALL_CAMERA_INSIDE_SUPPLY_CLOSET_NOT_GALLERY "+name)
        if name in ("06-hall-paper-rail",):
            assert tx<=-25 and tz>=47.8, (
                "HALL_CAMERA_PAPER_AIM_MISSES_REAR_RAIL")
        elif name in ("07-hall-yellow-end-window",):
            assert tx<=-53 and 36<=tz<=40, (
                "HALL_CAMERA_YELLOW_WINDOW_AIM_MISSES_END")
            # The original x=0 camera still passed as walkable but showed
            # the closet's SOLID ochre rear wall across >1/3 of the pixels.
            # Preserve the same yellow-window target from an unobstructed
            # point slightly west of the closet's projected side edge.
            assert x<=-3.5 and 37<=z<=41, (
                "HALL_CAMERA_OVERVIEW_OLD_CLOSET_WALL_OCCLUSION")
        elif name=="08-hall-adjacent-oak-door":
            assert tx<=-40 and 26<=tz<=30, (
                "HALL_CAMERA_OAK_DOOR_AIM_MISSES_FACADE")
        elif name=="22-hall-look-left":
            assert tx<=-35, "HALL_CAMERA_WRONG_LEFT_DIRECTION"
        elif name=="23-hall-look-right":
            assert tx>=39, "HALL_CAMERA_WRONG_RIGHT_DIRECTION"
        elif name=="24-hall-entry-from-gallery":
            assert tx>=37.5 and tz<25.5, (
                "HALL_CAMERA_MISSES_ONLY_CONNECTED_EXIT")

def inspect(cameras: dict[str,Camera], blockers=None, floors=None) -> None:
    assert set(cameras)==set(REGISTERED), "HALL_CAMERA_INVENTORY_REGRESSION"
    for name,cam in cameras.items():
        check_role(name,cam)
        if blockers is not None:
            bad=sorted(set(b.name for b in blockers if b.covers(cam.eye[0],cam.eye[2])))
            assert not bad, "HALL_CAMERA_EYE_INSIDE_REAL_COLLIDER "+name+":"+repr(bad[:8])
    if floors is not None:
        # Only the collidable floors actually constructed by Room.lua are
        # accepted; a visible poster, tile grout or preview-only prop is not
        # evidence of support. Existing per-camera geometry/role gates remain.
        assert blockers is not None, "HALL_CAMERA_NAV_COLLIDERS_REQUIRED"
        grid=Grid(blockers,floors)
        reachable,_=grid.connected(START)
        for name,cam in cameras.items():
            point=(cam.eye[0],cam.eye[2])
            assert any(f.supports(*point) for f in floors), (
                "HALL_CAMERA_EYE_HAS_NO_STRUCTURAL_FLOOR "+name)
            # The source renderer can draw an image from an isolated room
            # that Emma cannot physically walk to. A connected, full-geometry
            # approximate player grid must lead near each camera as well.
            cell=grid.closest_reachable(point,reachable,radius=1.5)
            assert cell is not None, (
                "HALL_CAMERA_UNREACHABLE_FROM_CLASSROOM "+name)


def self_test() -> None:
    # Synthetic, publicly safe camera location mutation fixtures.
    example={
        "05-closet-double-doors":Camera((0,5.5,31),(0,6.9,26.8)),
        "06-hall-paper-rail":Camera((0,5.5,40),(-36,9,48.52)),
        "07-hall-yellow-end-window":Camera((-4,5.7,38),(-54,7.35,38)),
        "08-hall-adjacent-oak-door":Camera((-41.8,5.6,39),(-45.5,6.8,27.85)),
        "09-hall-left-floor-roof-junction":Camera((42,5.5,22),(44,6,38)),
        "15-eye-closet-shelves":Camera((0,5.5,30),(0,7.5,35.15)),
        "22-hall-look-left":Camera((18,5.5,38),(-42,7,38)),
        "23-hall-look-right":Camera((18,5.5,38),(50,7,38)),
        "24-hall-entry-from-gallery":Camera((43,5.5,34),(43,6.9,17)),
    }
    inspect(example)
    mutation_specs={
        "obsolete_paper_eye_in_closet":
            ("06-hall-paper-rail",Camera((0,5.5,34),(-36,9,48.52))),
        "obsolete_closet_exit_camera_outside":
            ("05-closet-double-doors",Camera((4,5.5,40),(0,6.9,26.8))),
        "old_full_camera_inside_closet":
            ("22-hall-look-left",Camera((0,5.5,32),(-42,7,38))),
        "wrong_turn_aim":
            ("24-hall-entry-from-gallery",Camera((43,5.5,34),(-30,7,38))),
        "not_child_eye":
            ("06-hall-paper-rail",Camera((0,17.5,40),(-36,9,48.52))),
        "old_overview_obstructed_by_closet_rear_wall":
            ("07-hall-yellow-end-window",Camera((0,5.7,38),(-54,7.35,38))),
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
    # Connectivity is a distinct issue from a nonblank or collider-free
    # screenshot: the old straight-through hall could show nice rendered
    # evidence from a physically disconnected room. Use only invented floors.
    all_floor=FloorSupport("synthetic joined structural floor",
                           -56,56,-33,50,.5)
    inspect(example,[],[all_floor])
    try:
        inspect(example,None,[all_floor])
    except AssertionError as exc:
        assert "NAV_COLLIDERS_REQUIRED" in str(exc)
    else:
        raise AssertionError("HALL_CAMERA_NAV_WITHOUT_COLLIDERS_ACCEPTED")
    # All nine rendered eyes have support in the control case. Removing
    # support from the long hall must fail even if the camera image isn't blank.
    classroom_only=FloorSupport("synthetic classroom-only floor",
                                -56,56,-33,27,.5)
    try:
        inspect(example,[],[classroom_only])
    except AssertionError as exc:
        assert "EYE_HAS_NO_STRUCTURAL_FLOOR" in str(exc)
    else:
        raise AssertionError("HALL_CAMERA_UNSUPPORTED_GALLERY_ACCEPTED")
    # A continuous picture-perfect floor under the gallery is insufficient
    # if a solid wall isolates the gallery from the actual classroom spawn.
    sealed=Blocker("synthetic sealed portal",-56,56,26,27)
    try:
        inspect(example,[sealed],[all_floor])
    except AssertionError as exc:
        assert "UNREACHABLE_FROM_CLASSROOM" in str(exc)
    else:
        raise AssertionError("HALL_CAMERA_SEALED_GALLERY_ACCEPTED")
    print("HALL_CAMERA_REACHABILITY_NEGATIVE_PASS "
          "missing_floor,blocked_route,missing_colliders_rejected=true")
    print("HALL_CAMERA_LAYOUT_SELF_TEST_PASS "
          "obsolete_closet_camera,wrong_hall,wrong_aim,height_rejected=true "
          "old_overview_wall_occlusion_rejected=true")

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
    blockers,floors=get_source_geometry(args.luau)
    inspect(cameras,blockers,floors)
    print("HALL_CAMERA_REAL_SCENE_PASS cameras="+str(len(cameras))
          +" real_colliders="+str(len(blockers))
          +" structural_floors="+str(len(floors))
          +" all_nine_views_physically_reachable_on_source_grid=true"
          +" closet_and_hall_distinguished=true"
          +" stale_camera_regression_rejected=true"
          +" native_iphone_acceptance=false")
    for name,cam in cameras.items():
        print("HALL_CAMERA_VALID",name,cam.eye,"aim",cam.aim)

if __name__=="__main__":
    main()
