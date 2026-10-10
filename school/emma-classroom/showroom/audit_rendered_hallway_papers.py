#!/usr/bin/env python3
"""Fail closed if the real Luau hallway render loses its diagonal paper silhouettes.

Photo-based geometry only: this headless source-render checker cannot validate
native Roblox SurfaceGui appearance, true transparency, lighting or iPhone FPS.
"""
from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw

CAMERA_CROP = (0, 145, 925, 570)  # Fixed 06-hall-paper-rail child-eye camera.
MIN_CONNECTED_AREAS = 6
MIN_AREA_PIXELS = 900
MIN_TOTAL_PAPER_PIXELS = 25000


def inspect(image: Image.Image) -> tuple[int, int]:
    if image.size != (1920, 1080):
        raise AssertionError('HALL_PAPER_RENDER_VIEWPORT_CHANGED')
    img = image.convert('RGB').crop(CAMERA_CROP)
    w, h = img.size
    selected = bytearray(w * h)
    pixels=img.tobytes()
    for i in range(w*h):
        r,g,b=pixels[3*i],pixels[3*i+1],pixels[3*i+2]
        if 115 <= r <= 165 and 125 <= g <= 178 and 132 <= b <= 190 and g-r >= 8 and b-g >= 4:
            selected[i] = 1
    regions = 0
    total = 0
    for initial in range(w*h):
        if selected[initial] != 1:
            continue
        selected[initial] = 2
        queue = deque([initial])
        n = 0
        xmin, ymin, xmax, ymax = w, h, 0, 0
        while queue:
            pos = queue.pop()
            n += 1
            x, y = pos % w, pos // w
            xmin, ymin = min(xmin,x), min(ymin,y)
            xmax, ymax = max(xmax,x), max(ymax,y)
            for near in (pos-1, pos+1, pos-w, pos+w):
                if 0 <= near < w*h and not (abs(near-pos)==1 and near//w!=pos//w) and selected[near]==1:
                    selected[near]=2
                    queue.append(near)
        if n >= MIN_AREA_PIXELS and xmax-xmin >= 25 and ymax-ymin >= 30:
            regions += 1
            total += n
    if regions < MIN_CONNECTED_AREAS or total < MIN_TOTAL_PAPER_PIXELS:
        raise AssertionError('HALL_PAPER_RENDER_BARE_WALL_OR_MISSING_SHEETS ' +
                             f'areas={regions} pale_pixels={total}')
    return regions, total


def self_test() -> None:
    blank=Image.new('RGB',(1920,1080),(53,66,79))
    try:
        inspect(blank)
        raise AssertionError('HALL_PAPER_RENDER_BLANK_NEGATIVE_NOT_REJECTED')
    except AssertionError as exc:
        assert 'BARE_WALL' in str(exc), str(exc)
    full=blank.copy()
    artist=ImageDraw.Draw(full)
    for i in range(8):
        x=65+i*106
        y=350
        artist.polygon([(x,y-46),(x+43,y),(x,y+46),(x-43,y)],fill=(128,141,150))
    regions,pixels=inspect(full)
    assert regions>=7 and pixels>=MIN_TOTAL_PAPER_PIXELS, (regions,pixels)
    single=blank.copy()
    artist=ImageDraw.Draw(single)
    artist.rectangle((140,220,590,450),fill=(128,141,150))
    try:
        inspect(single)
        raise AssertionError('HALL_PAPER_RENDER_ONE_FAKE_PANEL_NOT_REJECTED')
    except AssertionError as exc:
        assert 'BARE_WALL' in str(exc), str(exc)
    print('PHOTO_HALL_RENDER_SELF_TEST_PASS blank_rejected=true single_panel_rejected=true eight_diamonds_detected=true')


def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument('image',nargs='?',type=Path)
    parser.add_argument('--self-test',action='store_true')
    args=parser.parse_args()
    if args.self_test:
        self_test()
    if args.image:
        with Image.open(args.image) as image:
            regions,pixels=inspect(image)
        print(f'PHOTO_HALL_RENDER_SILHOUETTES_PASS regions={regions} pale_pixels={pixels} ' +
              'source_derived_only=true native_roblox_review_pending=true')
    elif not args.self_test:
        parser.error('image is required unless --self-test is used')


if __name__=='__main__':
    main()
