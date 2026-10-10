#!/usr/bin/env python3
"""Test visual content in actual headless renders, not merely nonblank frames.

The headless renderer does not simulate native Roblox Lighting/SurfaceGui and
is NOT proof of actual iPhone or Roblox Studio rendering. Fixed 16 and 17
QA cameras only. Never read private gameplay videos in this CI script.
"""
from __future__ import annotations
import argparse
import math
from pathlib import Path
from PIL import Image, ImageDraw

SIZE=(960,540)
SUN=(479,270)
BOOKS=((315,270),(396,270),(472,270),(547,270),(625,270))

def normalized(path:Path)->Image.Image:
    with Image.open(path) as original:
        result=original.convert("RGB")
    return result if result.size==SIZE else result.resize(SIZE,Image.Resampling.LANCZOS)

def warm(rgb)->bool:
    r,g,b=rgb
    return r>105 and g>65 and b<95 and r>g*1.08 and g>b*1.4

def white_cloud(rgb)->bool:
    r,g,b=rgb
    return r>125 and g>138 and b>150 and abs(r-g)<40 and abs(g-b)<40

def connected_areas(points:set[tuple[int,int]])->list[int]:
    unseen=set(points);out=[]
    while unseen:
        stack=[unseen.pop()];size=1
        while stack:
            x,y=stack.pop()
            for q in ((x-1,y),(x+1,y),(x,y-1),(x,y+1),
                      (x-1,y-1),(x-1,y+1),(x+1,y-1),(x+1,y+1)):
                if q in unseen:
                    unseen.remove(q);stack.append(q);size+=1
        out.append(size)
    return out

def inspect_rug(im:Image.Image)->dict[str,int]:
    im=im if im.size==SIZE else im.resize(SIZE,Image.Resampling.LANCZOS)
    pix=im.load();cx,cy=SUN
    center=0; sectors=[0]*16; cloud_points=set()
    for y in range(cy-160,cy+161):
        for x in range(cx-160,cx+161):
            radius=math.hypot(x-cx,y-cy)
            color=pix[x,y]
            if radius<=26 and warm(color):
                center+=1
            if 50<radius<80 and warm(color):
                # Assign each warm pixel to its *nearest authored ray*.
                # Floor-binning put every 22.5-degree ray ON a sector edge:
                # adjacent rays then falsely supplied enough pixels to make
                # one deliberately missing ray pass the visual acceptance.
                # Preserve the original >=24 pixels and all-16 requirements.
                angle=math.atan2(y-cy,x-cx)%(2*math.pi)
                k=int(math.floor(angle*16/(2*math.pi)+.5))%16
                sectors[k]+=1
            if 75<radius<146 and white_cloud(color):
                cloud_points.add((x,y))
    rays=sum(v>=24 for v in sectors)
    clouds=sum(a>=140 for a in connected_areas(cloud_points))
    assert center>=700, f"RUG_CENTER_SUN_MISSING center_pixels={center}"
    # A source render with a single missing ray or numbered cloud must FAIL.
    # Native QA recorded the completed authored rug at 16 ray sectors and
    # 10 cloud components. The old 11/16 and 8/10 thresholds concealed
    # obvious incomplete art despite a green nonblank/image workflow.
    assert rays==16, f"RUG_SUN_RAYS_MISSING sectors={rays}/16"
    assert len(cloud_points)>=2500 and clouds==10, (
        f"RUG_WHITE_CLOUDS_MISSING pixels={len(cloud_points)} groups={clouds}/10"
    )
    return dict(sun_pixels=center,ray_sectors=rays,cloud_pixels=len(cloud_points),
                cloud_groups=clouds)

def inspect_books(im:Image.Image)->dict[str,int]:
    im=im if im.size==SIZE else im.resize(SIZE,Image.Resampling.LANCZOS)
    pix=im.load(); colors=[];low_saturation=1.;pale_max=0.
    for index,(cx,cy) in enumerate(BOOKS,1):
        patch=[pix[x,y] for y in range(cy-18,cy+18)
                         for x in range(cx-16,cx+16)]
        mean_rgb=[sum(c[k] for c in patch)/len(patch) for k in range(3)]
        values=[sum(c)/3 for c in patch]
        mean=sum(values)/len(values)
        contrast=(sum((v-mean)**2 for v in values)/len(values))**.5
        chromatic=sum(max(c)-min(c)>25 for c in patch)/len(patch)
        pale=sum(min(c)>120 and c[0]>145 and c[1]>140
                 and max(c)-min(c)<65 for c in patch)/len(patch)
        assert mean<145 and pale<.25 and chromatic>.20 and contrast>4.5, (
            f"STORYBOOK_{index}_BLANK_OR_UNILLUSTRATED lum={mean:.1f} "
            f"pale={pale:.2f} chromatic={chromatic:.2f} contrast={contrast:.1f}"
        )
        colors.append(tuple(round(c/12) for c in mean_rgb))
        low_saturation=min(low_saturation,chromatic);pale_max=max(pale_max,pale)
    assert len(set(colors))==5, (
        f"STORYBOOK_FIVE_DISTINCT_COVERS_MISSING colors={colors}"
    )
    return dict(illustrated_covers=5,min_chromatic_pct=int(low_saturation*100),
                max_pale_pct=int(pale_max*100))

def self_test()->None:
    rug=Image.new("RGB",SIZE,(37,43,48))
    draw=ImageDraw.Draw(rug);cx,cy=SUN
    draw.ellipse((cx-195,cy-195,cx+195,cy+195),fill=(55,99,152))
    for k in range(16):
        a=2*math.pi*k/16
        draw.line((cx+math.cos(a)*37,cy+math.sin(a)*37,
                   cx+math.cos(a)*68,cy+math.sin(a)*68),
                  fill=(190,115,42),width=8)
    draw.ellipse((cx-30,cy-30,cx+30,cy+30),fill=(190,151,50))
    for i in range(10):
        a=i*2*math.pi/10
        x=cx+int(math.cos(a)*110);y=cy+int(math.sin(a)*110)
        draw.ellipse((x-19,y-12,x+19,y+12),fill=(160,172,188))
    assert inspect_rug(rug)["cloud_groups"]==10
    # Test EVERY one-ray mutation. Each of the 16 original positions
    # must independently produce exactly one absent image sector. The
    # former boundary-bin test failed to detect the 0-degree deletion.
    for k in range(16):
        missing=rug.copy()
        d=ImageDraw.Draw(missing)
        a=2*math.pi*k/16
        d.line((cx+math.cos(a)*32,cy+math.sin(a)*32,
                cx+math.cos(a)*74,cy+math.sin(a)*74),
               fill=(55,99,152),width=15)
        try:
            inspect_rug(missing)
        except AssertionError as exc:
            assert "RUG_SUN_RAYS_MISSING" in str(exc), (
                f"Wrong error on missing ray {k}: {exc}"
            )
        else:
            raise AssertionError(
                f"One missing sun ray {k}/16 passed visual acceptance"
            )
    cloud_one_missing=rug.copy()
    d=ImageDraw.Draw(cloud_one_missing)
    i=0
    a=i*2*math.pi/10
    x=cx+int(math.cos(a)*110);y=cy+int(math.sin(a)*110)
    d.ellipse((x-22,y-15,x+22,y+15),fill=(55,99,152))
    try:
        inspect_rug(cloud_one_missing)
    except AssertionError as exc:
        assert "RUG_WHITE_CLOUDS_MISSING" in str(exc), str(exc)
    else:
        raise AssertionError("Single absent numbered cloud passed visual acceptance")
    rayless=Image.new("RGB",SIZE,(37,43,48))
    d=ImageDraw.Draw(rayless)
    d.ellipse((cx-195,cy-195,cx+195,cy+195),fill=(55,99,152))
    d.ellipse((cx-30,cy-30,cx+30,cy+30),fill=(190,151,50))
    for i in range(10):
        a=i*2*math.pi/10
        x=cx+int(math.cos(a)*110);y=cy+int(math.sin(a)*110)
        d.ellipse((x-19,y-12,x+19,y+12),fill=(160,172,188))
    try:
        inspect_rug(rayless)
    except AssertionError as exc:
        assert "RUG_SUN_RAYS_MISSING" in str(exc)
    else:
        raise AssertionError("Absent sun rays passed")
    cloudless=rug.copy()
    d=ImageDraw.Draw(cloudless)
    for i in range(10):
        a=i*2*math.pi/10
        x=cx+int(math.cos(a)*110);y=cy+int(math.sin(a)*110)
        d.ellipse((x-21,y-14,x+21,y+14),fill=(55,99,152))
    try:
        inspect_rug(cloudless)
    except AssertionError as exc:
        assert "RUG_WHITE_CLOUDS_MISSING" in str(exc)
    else:
        raise AssertionError("Absent clouds passed")
    books=Image.new("RGB",SIZE,(37,43,48))
    d=ImageDraw.Draw(books)
    colors=((66,118,101),(122,103,152),(78,110,152),(154,88,90),(62,75,126))
    for (x,y),color in zip(BOOKS,colors):
        d.rectangle((x-21,y-26,x+21,y+26),fill=color)
        d.ellipse((x-11,y-11,x+11,y+11),fill=(201,171,65))
        d.rectangle((x-12,y+12,x+12,y+15),fill=(22,33,58))
    assert inspect_books(books)["illustrated_covers"]==5
    blank=books.copy();d=ImageDraw.Draw(blank);x=BOOKS[2][0]
    d.rectangle((x-21,244,x+21,296),fill=(213,203,183))
    try:
        inspect_books(blank)
    except AssertionError as exc:
        assert "STORYBOOK_3_BLANK_OR_UNILLUSTRATED" in str(exc)
    else:
        raise AssertionError("Blank storybook passed")
    print("ARTWORK_PIXEL_NEGATIVE_TESTS_PASS "
          "every_single_ray_16_of_16 single_cloud "
          "missing_rays missing_clouds blank_book")

def main()->None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--self-test",action="store_true")
    parser.add_argument("--rug",type=Path)
    parser.add_argument("--books",type=Path)
    args=parser.parse_args()
    if args.self_test:
        self_test()
    if args.rug or args.books:
        if args.rug is None or args.books is None:
            parser.error("--rug and --books must be supplied together")
        rug=inspect_rug(normalized(args.rug))
        books=inspect_books(normalized(args.books))
        print("CARPET_SEMANTIC_PIXELS_PASS "+
              " ".join(f"{k}={v}" for k,v in rug.items()),flush=True)
        print("STORYBOOK_SEMANTIC_PIXELS_PASS "+
              " ".join(f"{k}={v}" for k,v in books.items()),flush=True)
    if not args.self_test and not args.rug:
        parser.error("Supply --self-test or --rug and --books")
if __name__=="__main__":
    main()
