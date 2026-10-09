#!/usr/bin/env python3
"""Screen native classroom carpet video locally, without exporting frames.

The clip stays on the reviewing computer. Output numeric metrics and SHA-256
only. A favorable screen is REVIEW_REQUIRED, never visual acceptance.
Dependencies: numpy, opencv-python-headless. No network requests.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
try:
    import cv2
    import numpy as np
except ImportError as exc:
    raise SystemExit("Install numpy and opencv-python-headless") from exc

PROFILE="rug-native-v2"
BLUE_MEDIAN_MIN=85
MIN_CLOUDS=8
MIN_RAYS=8
MIN_SECTORS=7


def polygon_argument(value: str) -> list[tuple[int,int]]:
    try:
        pts=[tuple(map(int,p.strip().split(","))) for p in value.split(";")]
    except ValueError as exc:
        raise argparse.ArgumentTypeError("Expected x,y;x,y;x,y;x,y") from exc
    if len(pts)<4 or any(len(p)!=2 for p in pts):
        raise argparse.ArgumentTypeError("At least four x,y vertices required")
    return pts


def center_argument(value: str) -> tuple[int,int]:
    try:
        pair=tuple(map(int,value.split(",")))
    except ValueError as exc:
        raise argparse.ArgumentTypeError("Expected x,y sun hint") from exc
    if len(pair)!=2:
        raise argparse.ArgumentTypeError("Expected x,y sun hint")
    return pair


def components(mask: np.ndarray, minimum: int) -> list[dict]:
    count,_,stats,centers=cv2.connectedComponentsWithStats(
        np.asarray(mask,dtype=np.uint8),8)
    return [
        {"area_pixels":int(stats[i,4]),
         "center":[round(float(v),1) for v in centers[i]]}
        for i in range(1,count)
        if stats[i,4]>=minimum and stats[i,2]>=7 and stats[i,3]>=6
    ]


def screen(frame: np.ndarray, polygon: list[tuple[int,int]],
           sun_hint: tuple[int,int]) -> dict:
    height,width=frame.shape[:2]
    if not all(0<=x<width and 0<=y<height for x,y in polygon) or not (
        0<=sun_hint[0]<width and 0<=sun_hint[1]<height
    ):
        return {"status":"INCONCLUSIVE","reason":"ROI or sun hint outside frame"}
    roi=np.zeros((height,width),np.uint8)
    cv2.fillPoly(roi,[np.asarray(polygon,np.int32)],1)
    roi_area=int(np.count_nonzero(roi))
    if not width*height*.08<=roi_area<=width*height*.62:
        return {"status":"INCONCLUSIVE","reason":"Reviewer ROI too broad or narrow"}
    hsv=cv2.cvtColor(frame,cv2.COLOR_BGR2HSV)
    rgb=cv2.cvtColor(frame,cv2.COLOR_BGR2RGB).astype(np.float32)
    hue,saturation,brightness=cv2.split(hsv)
    blue=((rgb[:,:,2]>rgb[:,:,0]*1.12)
          & (rgb[:,:,2]>rgb[:,:,1]*1.06)
          & (rgb[:,:,1]>rgb[:,:,0]*1.08) & (roi>0))
    blue_fraction=float(np.count_nonzero(blue)/roi_area)
    if blue_fraction<.22:
        return {"status":"INCONCLUSIVE",
                "reason":"Reviewer ROI not predominantly blue carpet",
                "blue_fraction":round(blue_fraction,3)}
    median_blue=float(np.median(rgb[:,:,2][blue]))
    yellow=((hue>=10)&(hue<=36)&(saturation>=115)
            &(brightness>=145)&(roi>0)).astype(np.uint8)
    number,_,stats,centers=cv2.connectedComponentsWithStats(yellow,8)
    found=sorted(
        ((int(stats[i,4]),centers[i]) for i in range(1,number)),
        key=lambda obj:obj[0],reverse=True)
    if not found or found[0][0]<(width/1112)**2*1000:
        return {"status":"INCONCLUSIVE","reason":"Central yellow sun not identifiable"}
    sun_area,center=found[0]
    sun_x,sun_y=[float(v) for v in center]
    if math.hypot(sun_x-sun_hint[0],sun_y-sun_hint[1])>max(22,.03*width):
        return {"status":"INCONCLUSIVE",
                "reason":"Detected yellow object differs from reviewed sun"}
    radius=math.sqrt(sun_area/math.pi)
    rows,cols=np.ogrid[:height,:width]
    distance=np.sqrt((cols-sun_x)**2+(rows-sun_y)**2)
    annulus=((roi>0)&(distance>=radius+5*width/1112)
             &(distance<=radius*2.4))
    orange=((hue>=4)&(hue<=35)&(saturation>=110)
            &(brightness>=110)&annulus)
    rays=components(orange,max(55,round(.011*sun_area)))
    white=((saturation<=65)&(brightness>=160)
           &(roi>0)&(distance>=radius*1.8))
    # Size by itself is not enough: unrelated paper rectangles beyond the
    # circle could previously be counted as ten legitimate rug clouds.
    # A cloud needs to lie on the photographed ring around the verified sun.
    white_candidates=components(white,max(105,round(.020*sun_area)))
    clouds=[item for item in white_candidates
            if radius*1.90<=math.hypot(
                item["center"][0]-sun_x,item["center"][1]-sun_y
            )<=radius*4.30]
    def angular_sectors(items: list[dict]) -> int:
        bins=set()
        for item in items:
            cx,cy=item["center"]
            theta=math.atan2(cy-sun_y,cx-sun_x)%(2*math.pi)
            bins.add(min(11,int(theta*12/(2*math.pi))))
        return len(bins)
    ray_sectors=angular_sectors(rays)
    cloud_sectors=angular_sectors(clouds)
    distributed=(ray_sectors>=MIN_SECTORS and cloud_sectors>=MIN_SECTORS)
    defects=[]
    if median_blue<BLUE_MEDIAN_MIN:
        defects.append("CARPET_TOO_DARK")
    if len(rays)<MIN_RAYS:
        defects.append("SUN_RAYS_STILL_DOT_LIKE")
    if len(clouds)<MIN_CLOUDS:
        defects.append("CLOUDS_STILL_DOT_LIKE")
    # The screen may be cropped, or there may be stray papers/rays in one
    # quadrant. In either case, do not call it REVIEW_REQUIRED as if ten
    # well-distributed classroom clouds had been found.
    status="FAIL" if defects else (
        "REVIEW_REQUIRED" if distributed else "INCONCLUSIVE"
    )
    return {
        "status":status,
        "defects":defects,
        "carpet_blue_median_b":round(median_blue,1),
        "blue_carpet_fraction":round(blue_fraction,3),
        "central_sun_area_pixels":sun_area,
        "ray_components_large_enough":len(rays),
        "cloud_components_large_enough":len(clouds),
        "sun_ray_angular_sectors":ray_sectors,
        "cloud_angular_sectors":cloud_sectors,
        "geometric_distribution_ok":distributed,
        "sun_center":[round(sun_x,1),round(sun_y,1)],
        "notes":"Thresholds screen obvious regressions only. They do not certify readable numbers, fidelity or FPS.",
    }


def self_test() -> None:
    from math import cos,sin,pi
    height,width=512,1112
    polygon=[(110,190),(890,190),(890,506),(110,506)]
    hint=(500,360)

    def synth(good: bool) -> np.ndarray:
        frame=np.zeros((height,width,3),np.uint8)
        frame[:]=(200,130,95) if good else (54,41,28)
        cv2.circle(frame,hint,40,(65,190,250),-1)
        for n in range(16):
            angle=2*pi*n/16
            pos=(round(500+71*cos(angle)),round(360+71*sin(angle)))
            if good:
                cv2.ellipse(frame,pos,(13,8),math.degrees(angle),
                            0,360,(45,145,238),-1)
            else:
                cv2.circle(frame,pos,3,(45,145,238),-1)
        for n in range(10):
            angle=2*pi*n/10
            pos=(round(500+120*cos(angle)),round(360+120*sin(angle)))
            if good:
                cv2.ellipse(frame,pos,(18,9),0,0,360,(235,245,250),-1)
            else:
                cv2.circle(frame,pos,3,(235,245,250),-1)
        return frame

    defective=screen(synth(False),polygon,hint)
    assert defective["status"]=="FAIL" and set(defective["defects"])=={
        "CARPET_TOO_DARK","SUN_RAYS_STILL_DOT_LIKE",
        "CLOUDS_STILL_DOT_LIKE"
    },defective
    improved=screen(synth(True),polygon,hint)
    assert improved["status"]=="REVIEW_REQUIRED",improved
    bad_roi=screen(synth(True),[(5,5),(15,5),(15,15),(5,15)],hint)
    assert bad_roi["status"]=="INCONCLUSIVE",bad_roi
    # An actual false-positive from the former detector: replacing ten
    # real cloud silhouettes with ordinary white paper rectangles used to
    # yield REVIEW_REQUIRED even with no genuine cloud ring present.
    paper_color=(235,245,250)
    background=(200,130,95)
    papers=synth(True)
    for n in range(10):
        angle=2*pi*n/10
        pos=(round(500+120*cos(angle)),round(360+120*sin(angle)))
        cv2.ellipse(papers,pos,(20,12),0,0,360,background,-1)
    for n in range(10):
        px=210+(n%5)*48
        py=205+(n//5)*55
        cv2.rectangle(papers,(px,py),(px+29,py+20),paper_color,-1)
    fake_papers=screen(papers,polygon,hint)
    assert fake_papers["status"] in ("FAIL","INCONCLUSIVE"),fake_papers

    clustered=synth(True)
    for n in range(10):
        angle=2*pi*n/10
        pos=(round(500+120*cos(angle)),round(360+120*sin(angle)))
        cv2.ellipse(clustered,pos,(20,12),0,0,360,background,-1)
    for n in range(10):
        px=175+(n%5)*64
        py=285+(n//5)*55
        cv2.ellipse(clustered,(px,py),(18,9),0,0,360,paper_color,-1)
    clustered_result=screen(clustered,polygon,hint)
    assert clustered_result["status"] in ("FAIL","INCONCLUSIVE"),clustered_result

    # Likewise, 16 large orange stickers squeezed into one quadrant are
    # not a 16-ray sunburst, despite passing the old component-count gate.
    quadrant=synth(True)
    for n in range(16):
        angle=2*pi*n/16
        pos=(round(500+71*cos(angle)),round(360+71*sin(angle)))
        cv2.ellipse(quadrant,pos,(15,10),math.degrees(angle),
                    0,360,background,-1)
    for px in (545,558,571,584):
        for py in (330,342,354,366):
            cv2.rectangle(quadrant,(px,py),(px+8,py+8),
                          (45,145,238),-1)
    fake_rays=screen(quadrant,polygon,hint)
    assert fake_rays["status"] in ("FAIL","INCONCLUSIVE"),fake_rays

    print("NATIVE_RUG_SELF_TEST_PASS dark_and_dot_regressions_rejected=true "
          "improved_synthetic_requires_human_review=true "
          "invalid_roi_inconclusive=true unrelated_papers_rejected=true "
          "clustered_clouds_rejected=true quadrant_rays_rejected=true")


def video_sha256(path: Path) -> str:
    digest=hashlib.sha256()
    with path.open("rb") as source:
        while block:=source.read(1024*1024):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--video",type=Path)
    parser.add_argument("--seconds",type=float)
    parser.add_argument("--polygon",type=polygon_argument)
    parser.add_argument("--sun-hint",type=center_argument)
    parser.add_argument("--report-json",type=Path,
                        help="Optional local numeric JSON output; no media is saved")
    parser.add_argument("--self-test",action="store_true")
    args=parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if any(x is None for x in (args.video,args.seconds,args.polygon,args.sun_hint)):
        parser.error("--video, --seconds, --polygon and --sun-hint required")
    if not args.video.is_file() or args.seconds<0:
        parser.error("A real local video and nonnegative timestamp required")
    cap=cv2.VideoCapture(str(args.video))
    if not cap.isOpened():
        parser.error("Cannot read video")
    cap.set(cv2.CAP_PROP_POS_MSEC,args.seconds*1000)
    ok,frame=cap.read()
    cap.release()
    if not ok:
        parser.error("No video frame at specified timestamp")
    result=screen(frame,args.polygon,args.sun_hint)
    result.update({
        "profile":PROFILE,"timestamp_seconds":args.seconds,
        "frame_size":[frame.shape[1],frame.shape[0]],
        "source_commit_from_video":"NOT_VERIFIABLE",
        "native_visual_acceptance":"NOT_GRANTED",
        "video_sha256":video_sha256(args.video)
    })
    if args.report_json:
        args.report_json.parent.mkdir(parents=True,exist_ok=True)
        args.report_json.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result,indent=2))
    return {"REVIEW_REQUIRED":0,"FAIL":1,"INCONCLUSIVE":2}[result["status"]]


if __name__=="__main__":
    sys.exit(main())
