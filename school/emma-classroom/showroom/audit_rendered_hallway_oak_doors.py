#!/usr/bin/env python3
"""Semantic pixel QA of the fixed adjacent-oak-door hallway camera.

Applies only to the 1920x1080 source-derived headless view
08-hall-adjacent-oak-door. Does NOT certify native Roblox, iPhone frame
rate, real-world dimensions, or original-photo parity.
"""
from __future__ import annotations

import argparse
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageEnhance

VIEWPORT=(1920,1080)
# Fixed 08-hall-adjacent-oak-door camera (145,5.6,16 -> 153.5,6.8,25.7).
# Strict 1920x1080 source-derived pixels from 2026-10-16 artifact
# 12016763442: the former x750-830 left-stile band captured mostly wall
# after the owner's straight-hall correction. Preserve ALL minimum thresholds
# and every negative mutation; recalibrate regions to visible solid geometry.
WOOD={
    "top_lintel":((815,256,1138,366),4000),
    "left_stile":((817,343,879,727),5500),
    "right_stile":((1065,302,1155,802),7000),
    "center_crossbar":((855,472,1078,508),1600),
    "lower_sill":((825,637,1136,691),12000),
    "raised_panel":((865,732,1121,990),20000),
}
GLASS={
    "upper_pane":((880,331,1050,448),10000),
    "lower_pane":((880,520,1050,615),10000),
}
BRASS_REGION=(1026,738,1090,878)
PANEL_CORE=(900,760,1050,930)
PANEL_BORDER=(827,790,842,920)


def is_wood(v):
    r,g,b=v
    return (45<=r<=155 and 28<=g<=118 and 15<=b<=85
            and r-g>=7 and g-b>=7)


def is_glass(v):
    r,g,b=v
    return (88<=r<=155 and 112<=g<=185 and 119<=b<=200
            and g-r>=16 and b-g>=6)


def is_brass(v):
    r,g,b=v
    return (105<=r<=225 and 105<=g<=210 and 64<=b<=165
            and g-b>=20 and abs(r-g)<=50)


def count_region(pixels,rect,check):
    x0,y0,x1,y1=rect
    return sum(bool(check(pixels[x,y])) for y in range(y0,y1)
               for x in range(x0,x1))


def mean_red(pixels,rect):
    x0,y0,x1,y1=rect
    return sum(pixels[x,y][0] for y in range(y0,y1)
               for x in range(x0,x1))/((x1-x0)*(y1-y0))


def inspect(image):
    if image.size != VIEWPORT:
        raise AssertionError("PHOTO_HALL_OAK_DOOR_VIEWPORT_CHANGED")
    pixels=image.convert("RGB").load()
    wood={}
    for name,(rect,minimum) in WOOD.items():
        total=count_region(pixels,rect,is_wood)
        wood[name]=total
        if total<minimum:
            raise AssertionError(
                f"PHOTO_HALL_OAK_DOOR_3D_WOOD_MISSING {name} "
                f"count={total} minimum={minimum}")
    glazed={}
    for name,(rect,minimum) in GLASS.items():
        total=count_region(pixels,rect,is_glass)
        glazed[name]=total
        if total<minimum:
            raise AssertionError(
                f"PHOTO_HALL_OAK_DOOR_GLASS_INVISIBLE {name} "
                f"count={total} minimum={minimum}")
    brass=count_region(pixels,BRASS_REGION,is_brass)
    if brass<200:
        raise AssertionError(
            f"PHOTO_HALL_OAK_DOOR_BRASS_HANDLE_INVISIBLE count={brass}")
    contrast=mean_red(pixels,PANEL_CORE)-mean_red(pixels,PANEL_BORDER)
    if contrast<7.0:
        raise AssertionError(
            f"PHOTO_HALL_OAK_DOOR_LOWER_PANEL_FLAT contrast={contrast:.2f}")
    return {"wood":wood,"glass":glazed,"brass":brass,
            "raised_panel_red_contrast":round(contrast,2)}


def synthetic_door():
    im=Image.new("RGB",VIEWPORT,(53,66,79))
    d=ImageDraw.Draw(im)
    # Unlike screenshots this is entirely invented geometry. Keep it aligned
    # to the exact fixed camera so mutation tests exercise the REAL bands.
    d.rectangle((820,269,1141,1037),fill=(56,41,29))
    d.rectangle((852,320,1080,474),fill=(108,139,152))
    d.rectangle((852,510,1080,631),fill=(108,139,152))
    d.rectangle((850,475,1090,509),fill=(70,53,38))
    d.rectangle((850,720,1120,990),fill=(73,55,39))
    d.rectangle((1041,760,1059,850),fill=(138,140,106))
    return im


def reject(im,needle):
    try:
        inspect(im)
    except AssertionError as exc:
        if needle not in str(exc):
            raise AssertionError(
                f"Unexpected synthetic mutation: {exc}; expected {needle}") from exc
    else:
        raise AssertionError("PHOTO_HALL_OAK_DOOR_MUTANT_FALSE_ACCEPT "+needle)


def self_test():
    sample=synthetic_door()
    inspect(sample)
    reject(Image.new("RGB",VIEWPORT,(53,66,79)),"3D_WOOD_MISSING")
    reject(ImageChops.offset(sample,370,0),"3D_WOOD_MISSING")
    def painted(rect,color):
        out=sample.copy()
        ImageDraw.Draw(out).rectangle(rect,fill=color)
        return out
    reject(painted((850,318,1082,474),(56,41,29)),"GLASS_INVISIBLE")
    reject(painted((850,509,1082,633),(53,66,79)),"GLASS_INVISIBLE")
    reject(painted((850,473,1092,511),(108,139,152)),"3D_WOOD_MISSING")
    reject(painted((1038,754,1064,857),(73,55,39)),"BRASS_HANDLE_INVISIBLE")
    flat=painted((850,720,1120,990),(56,41,29))
    ImageDraw.Draw(flat).rectangle((1041,760,1059,850),fill=(138,140,106))
    reject(flat,"LOWER_PANEL_FLAT")
    reject(sample.resize((1112,512)),"VIEWPORT_CHANGED")
    for factor in (.85,.95,1.10):
        inspect(ImageEnhance.Brightness(sample).enhance(factor))
    print("PHOTO_HALL_OAK_DOOR_PIXEL_SELF_TEST_PASS "
          "blank,shift,upper_glass,lower_glass,crossbar,brass,panel,viewport "
          "mutations_rejected=true")


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("image",nargs="?",type=Path)
    parser.add_argument("--self-test",action="store_true")
    args=parser.parse_args()
    if args.self_test:
        self_test()
    if args.image:
        with Image.open(args.image) as im:
            metrics=inspect(im)
        print(f"PHOTO_HALL_OAK_DOOR_RENDER_PIXELS_PASS {metrics} "
              "source_derived_only=true native_iphone_review_pending=true")
    elif not args.self_test:
        parser.error("image required unless --self-test")


if __name__=="__main__":
    main()
