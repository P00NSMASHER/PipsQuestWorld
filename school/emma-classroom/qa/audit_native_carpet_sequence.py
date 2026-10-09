#!/usr/bin/env python3
"""Review three nearby native Roblox iPhone frames, locally and fail-closed.

Source footage and sampled pixels never leave this process; printed reports
contain only numeric screening evidence and a private file checksum. Even
positive results require human review and do not establish a Roblox version.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
import math
from pathlib import Path
import sys

import cv2

from audit_native_carpet_video import (
    PROFILE as FRAME_DETECTOR_PROFILE,
    center_argument, polygon_argument, screen, video_sha256,
    self_test as pixel_detector_self_test,
)

PROFILE = "rug-native-sequence-v1"
SAMPLE_COUNT = 3
SAMPLE_OFFSETS = (-1, 0, 1)
DECISIVE_FRAMES = 2


def decide(samples: list[dict]) -> dict:
    """Require corroboration; never convert one favorable frame to approval."""
    if len(samples) != SAMPLE_COUNT:
        raise ValueError("Three independently sampled frames required")
    allowed = {"FAIL", "INCONCLUSIVE", "REVIEW_REQUIRED"}
    if any(s.get("status") not in allowed for s in samples):
        raise ValueError("Unexpected per-frame screening status")
    fail = [s for s in samples if s["status"] == "FAIL"]
    review = [s for s in samples if s["status"] == "REVIEW_REQUIRED"]
    uncertain = [s for s in samples if s["status"] == "INCONCLUSIVE"]
    counts = Counter(defect for frame in fail for defect in frame.get("defects", []))
    confirmed = sorted(k for k,v in counts.items() if v >= DECISIVE_FRAMES)
    if confirmed:
        status,reason = "FAIL", "Same visual defect in multiple comparable frames"
    elif len(review) >= DECISIVE_FRAMES and not fail:
        status,reason = "REVIEW_REQUIRED", "Repeated usable frames require native human inspection"
    else:
        status,reason = "INCONCLUSIVE", "Camera movement or mixed results prevent consensus"
    return {
        "status": status,
        "reason": reason,
        "confirmed_defects": confirmed,
        "frames_failed": len(fail),
        "frames_reviewable": len(review),
        "frames_inconclusive": len(uncertain),
        "frames_total": len(samples),
        "native_visual_acceptance": "NOT_GRANTED",
    }


def check_camera_consistency(samples: list[dict], width: int) -> dict:
    """Reject camera motion or rapid zoom without storing any video pixels.

    Distinct decoder frame indices alone do not prove comparable frames:
    a rotating camera can make two dot-like observations misleading. The
    verified yellow sun is the same anchored in-world landmark in each frame.
    If it moves too far or grows substantially, require a static re-recording.
    """
    centers=[s.get("sun_center") for s in samples
             if isinstance(s.get("sun_center"), list)
             and len(s["sun_center"])==2]
    areas=[float(s["central_sun_area_pixels"]) for s in samples
           if isinstance(s.get("central_sun_area_pixels"),(int,float))
           and s["central_sun_area_pixels"]>0]
    drift=max((math.dist(a,b) for i,a in enumerate(centers)
               for b in centers[i+1:]),default=0.0)
    scale=max(areas)/min(areas) if len(areas)>=2 else 1.0
    max_drift=max(10.0,width*.014)
    return {
        "stable":drift<=max_drift and scale<=1.30,
        "sun_center_max_drift_px":round(drift,2),
        "sun_area_max_ratio":round(scale,3),
        "allowed_drift_px":round(max_drift,2),
    }


def inspect_video(video: Path, seconds: float, offset: float,
                  polygon: list[tuple[int,int]],
                  sun_hint: tuple[int,int]) -> dict:
    """Time-local sampling; no tracking, frame export, or guessed source SHA."""
    if not video.is_file() or seconds < offset or offset < .06 or offset > .25:
        raise ValueError("Existing video, center>=offset, and .06<=offset<=.25 required")
    cap = cv2.VideoCapture(str(video))
    if not cap.isOpened():
        raise ValueError("Cannot read the private local video")
    results=[]
    frame_numbers=[]
    frame_width=int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    if frame_width<=0:
        cap.release()
        raise ValueError("Decoder cannot establish width for frame motion audit")
    try:
        for multiplier in SAMPLE_OFFSETS:
            target = round(seconds + multiplier * offset, 3)
            cap.set(cv2.CAP_PROP_POS_MSEC, target*1000)
            ok, frame = cap.read()
            if not ok:
                result={"status":"INCONCLUSIVE", "reason":"No decodable frame at requested offset"}
            else:
                result=screen(frame, polygon, sun_hint)
                frame_numbers.append(int(cap.get(cv2.CAP_PROP_POS_FRAMES)) - 1)
            # Only bounded metrics, timestamps and statuses. No pixels or filenames.
            numeric={"requested_second":target, "status":result["status"]}
            for key in ("reason", "defects", "carpet_blue_median_b",
                        "blue_carpet_fraction", "ray_components_large_enough",
                        "cloud_components_large_enough", "sun_ray_angular_sectors",
                        "cloud_angular_sectors", "sun_center",
                        "central_sun_area_pixels"):
                if key in result:
                    numeric[key]=result[key]
            results.append(numeric)
    finally:
        cap.release()
    aggregate=decide(results)
    camera=check_camera_consistency(results,frame_width)
    if not camera["stable"]:
        aggregate.update(status="INCONCLUSIVE", confirmed_defects=[],
                         reason="Rug viewpoint moved or zoomed between sampled frames")
    if len(set(frame_numbers)) != len(frame_numbers):
        aggregate.update(status="INCONCLUSIVE", confirmed_defects=[],
                         reason="Decoder returned repeated frame identities")
    aggregate.update({
        "camera_comparability":camera,
        "profile":PROFILE,
        "single_frame_detector_profile":FRAME_DETECTOR_PROFILE,
        "center_second":seconds,
        "sample_offset_seconds":offset,
        "per_frame_metrics":results,
        "source_commit_from_video":"NOT_VERIFIABLE",
        "published_version_from_video":"NOT_VERIFIABLE",
        "video_sha256":video_sha256(video),
    })
    return aggregate


def self_test() -> None:
    pixel_detector_self_test()  # Pixel-level adversarial scenes, no real video
    defective={"status":"FAIL", "defects":["CARPET_TOO_DARK", "CLOUDS_STILL_DOT_LIKE"]}
    healthy={"status":"REVIEW_REQUIRED"}
    unknown={"status":"INCONCLUSIVE", "reason":"camera moved"}
    assert decide([defective,defective,unknown])["status"] == "FAIL"
    assert decide([defective,healthy,healthy])["status"] == "INCONCLUSIVE"
    assert decide([healthy,healthy,unknown])["status"] == "REVIEW_REQUIRED"
    assert decide([healthy,unknown,unknown])["status"] == "INCONCLUSIVE"
    assert decide([unknown,unknown,unknown])["status"] == "INCONCLUSIVE"
    different={"status":"FAIL", "defects":["SUN_RAYS_STILL_DOT_LIKE"]}
    assert decide([defective,different,unknown])["status"] == "INCONCLUSIVE"
    assert decide([defective,defective,healthy])["status"] == "FAIL"
    assert decide([healthy,healthy,healthy])["status"] == "REVIEW_REQUIRED"
    stationary=[
        {"status":"FAIL", "defects":["CARPET_TOO_DARK"],
         "sun_center":[500,350], "central_sun_area_pixels":5200},
        {"status":"FAIL", "defects":["CARPET_TOO_DARK"],
         "sun_center":[505,351], "central_sun_area_pixels":5270},
        {"status":"INCONCLUSIVE", "reason":"brief obstruction"},
    ]
    assert check_camera_consistency(stationary,1112)["stable"]
    panned=[dict(s) for s in stationary]
    panned[1]={**stationary[1], "sun_center":[550,350]}
    assert not check_camera_consistency(panned,1112)["stable"]
    zoomed=[dict(s) for s in stationary]
    zoomed[1]={**stationary[1], "central_sun_area_pixels":8100}
    assert not check_camera_consistency(zoomed,1112)["stable"]
    assert check_camera_consistency(stationary,1112)["allowed_drift_px"]<16
    try:
        decide([healthy,unknown])
    except ValueError:
        pass
    else:
        raise AssertionError("Too few frames accepted")
    print("NATIVE_RUG_SEQUENCE_SELF_TEST_PASS repeated_failure=true "
          "single_defect_not_overclaimed=true mixed_frames_inconclusive=true "
          "missing_frames_fail_closed=true positive_requires_human=true "
          "camera_pan_rejected=true rapid_zoom_rejected=true")


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--video",type=Path)
    parser.add_argument("--seconds",type=float)
    parser.add_argument("--sample-offset",type=float,default=.10)
    parser.add_argument("--polygon",type=polygon_argument)
    parser.add_argument("--sun-hint",type=center_argument)
    parser.add_argument("--report-json",type=Path)
    parser.add_argument("--self-test",action="store_true")
    args=parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if any(x is None for x in (args.video,args.seconds,args.polygon,args.sun_hint)):
        parser.error("--video, --seconds, --polygon, --sun-hint required")
    try:
        result=inspect_video(args.video,args.seconds,args.sample_offset,
                             args.polygon,args.sun_hint)
    except ValueError as exc:
        parser.error(str(exc))
    if args.report_json:
        args.report_json.parent.mkdir(parents=True,exist_ok=True)
        args.report_json.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result,indent=2))
    return {"REVIEW_REQUIRED":0,"FAIL":1,"INCONCLUSIVE":2}[result["status"]]


if __name__=="__main__":
    sys.exit(main())
