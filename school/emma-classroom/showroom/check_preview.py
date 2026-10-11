"""Reject blank source-derived renders without weakening the image acceptance gate.

The headless third-party renderer intermittently generates white frames even
when Lua geometry construction and binary place assembly are correct.
This gate checks pixels, NOT just file existence. It is not a Roblox Studio test.
"""
from pathlib import Path
import sys
from PIL import Image

def acceptable(image: Image.Image):
    im=image.convert("RGB")
    spans=[maximum-minimum for minimum,maximum in im.getextrema()]
    dynamic=max(spans)
    # Same original thresholds. Resize is only for determining white coverage.
    sample=im.resize((96,54))
    pixels=list(sample.getdata())
    white_ratio=sum(min(rgb)>245 for rgb in pixels)/len(pixels)
    return dynamic>=65 and white_ratio<=.94, dynamic, white_ratio

def self_test():
    blank=Image.new("RGB",(960,540),(255,255,255))
    assert not acceptable(blank)[0], "White frame must fail"
    blank2=Image.new("RGB",(960,540),(235,235,235))
    assert not acceptable(blank2)[0], "Low-dynamic flat frame must fail"
    nearly_blank=Image.new("RGB",(960,540),(255,255,255))
    for y in range(0,540):
        for x in range(0,16):
            nearly_blank.putpixel((x,y),(33,78,143))
    assert not acceptable(nearly_blank)[0], (
        "A high-contrast but 98% blank camera must fail the unchanged coverage threshold"
    )
    scene=Image.new("RGB",(960,540),(14,21,27))
    for y in range(110,400):
        for x in range(180,790):
            scene.putpixel((x,y),(135,98,68) if (x+y)%2 else (92,142,172))
    assert acceptable(scene)[0], "Source-like colored room must pass"
    print("PASS: pixel gate rejects flat and white images while permitting actual room-like pixels")

if __name__=="__main__":
    if len(sys.argv)!=2:
        raise SystemExit("Usage: check_preview.py <png-path> | --self-test")
    if sys.argv[1]=="--self-test":
        self_test()
    else:
        path=Path(sys.argv[1])
        if not path.is_file() or path.stat().st_size<1000:
            raise SystemExit(f"VISUAL_REJECT missing or tiny image {path}")
        with Image.open(path) as image:
            valid,dynamic,white=acceptable(image)
        if not valid:
            raise SystemExit(f"VISUAL_REJECT {path.name} channel_span={dynamic} white_ratio={white:.3f}")
        print(f"VISUAL_NONBLANK_PASS {path.name} channel_span={dynamic} white_ratio={white:.3f}")
