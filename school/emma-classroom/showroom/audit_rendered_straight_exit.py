#!/usr/bin/env python3
"""Fail closed on visible obstructions across Emma's straight staff exit.

Actual 09 camera: source-constructed 3D scene, 1920x1080 fixed perspective.
The previous build passed collision checks with an opaque noncolliding brick
carrier covering the lower doorway. Static imagery is not native Roblox
rendering, iPhone testing, FPS evidence or real-world architectural proof.
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance

VIEWPORT = (1920, 1080)
CLEAR_AISLE = (740, 600, 1180, 790)
FAR_WINDOW = (903, 505, 1015, 580)
MIN_CLEAR_NEUTRAL_FRACTION = 0.75
MAX_OPAQUE_OCHRE_FRACTION = 0.16
MIN_FAR_WINDOW_OAK_PIXELS = 1500


def floor_neutral(rgb):
    r, g, b = rgb
    return 25 <= r < 85 and -2 <= g-r <= 11 and -3 <= b-g <= 11 and b-r <= 17


def opaque_ochre(rgb):
    r, g, b = rgb
    return r >= 70 and r-g >= 7 and g-b >= 15


def oak_window(rgb):
    r, g, b = rgb
    return r >= 70 and 7 <= r-g <= 45 and g-b >= 15 and b <= 110


def tally(image, box, predicate):
    pixels = image.crop(box).tobytes()
    return sum(bool(predicate((pixels[i], pixels[i+1], pixels[i+2])))
               for i in range(0, len(pixels), 3))


def inspect(image):
    if image.size != VIEWPORT:
        raise AssertionError("STRAIGHT_EXIT_VIEWPORT_CHANGED")
    im = image.convert("RGB")
    x0, y0, x1, y1 = CLEAR_AISLE
    total = (x1-x0) * (y1-y0)
    neutral = tally(im, CLEAR_AISLE, floor_neutral)
    ochre = tally(im, CLEAR_AISLE, opaque_ochre)
    if neutral < total * MIN_CLEAR_NEUTRAL_FRACTION:
        raise AssertionError(
            "STRAIGHT_EXIT_VISIBLE_AISLE_OBSCURED "
            f"neutral_fraction={neutral/total:.3f}"
        )
    if ochre > total * MAX_OPAQUE_OCHRE_FRACTION:
        raise AssertionError(
            "STRAIGHT_EXIT_OPAQUE_BRICK_VENEER_RETURNED "
            f"ochre_fraction={ochre/total:.3f}"
        )
    far = tally(im, FAR_WINDOW, oak_window)
    if far < MIN_FAR_WINDOW_OAK_PIXELS:
        raise AssertionError(
            "STRAIGHT_EXIT_FAR_WINDOW_NOT_VISIBLE "
            f"wood_pixels={far}"
        )
    return {
        "clear_neutral_fraction": round(neutral/total, 3),
        "nearfield_ochre_fraction": round(ochre/total, 3),
        "far_window_wood_pixels": far,
        "source_renderer_only": True,
        "native_iphone_qa_required": True,
    }


def synthetic_clear_view():
    # Original anonymous fixture, not imported school photo pixels.
    im = Image.new("RGB", VIEWPORT, (52, 65, 79))
    draw = ImageDraw.Draw(im)
    draw.rectangle(CLEAR_AISLE, fill=(38, 42, 46))
    draw.rectangle(FAR_WINDOW, fill=(55, 71, 81))
    draw.rectangle((905, 507, 1013, 516), fill=(123, 95, 49))
    draw.rectangle((905, 570, 1013, 579), fill=(123, 95, 49))
    for x in (905, 1008):
        draw.rectangle((x, 509, x+6, 578), fill=(123, 95, 49))
    return im


def rejected(image, expected):
    try:
        inspect(image)
    except AssertionError as exc:
        assert expected in str(exc), (expected, str(exc))
    else:
        raise AssertionError("STRAIGHT_EXIT_FALSE_ACCEPT " + expected)


def self_test():
    good = synthetic_clear_view()
    inspect(good)
    rejected(Image.new("RGB", VIEWPORT, (53, 66, 79)),
             "VISIBLE_AISLE_OBSCURED")
    former = good.copy()
    ImageDraw.Draw(former).rectangle((710, 570, 1270, 820),
                                     fill=(100, 74, 37))
    rejected(former, "VISIBLE_AISLE_OBSCURED")
    opaque_blue = good.copy()
    ImageDraw.Draw(opaque_blue).rectangle((710, 570, 1270, 820),
                                          fill=(53, 66, 79))
    rejected(opaque_blue, "VISIBLE_AISLE_OBSCURED")
    absent_window = good.copy()
    ImageDraw.Draw(absent_window).rectangle(FAR_WINDOW, fill=(53, 66, 79))
    rejected(absent_window, "FAR_WINDOW_NOT_VISIBLE")
    rejected(good.resize((1112, 512)), "VIEWPORT_CHANGED")
    for factor in (0.90, 1.08):
        inspect(ImageEnhance.Brightness(good).enhance(factor))
    print("STRAIGHT_EXIT_PIXEL_SELF_TEST_PASS "
          "old_veneer,blue_barrier,missing_window,wrong_viewport,"
          "exposure_variation_checked=true")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("image", nargs="?", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    if args.image:
        with Image.open(args.image) as frame:
            evidence = inspect(frame)
        print("STRAIGHT_EXIT_RENDER_PIXELS_PASS " +
              " ".join(f"{name}={value}" for name, value in evidence.items()))
    elif not args.self_test:
        parser.error("image required unless --self-test")


if __name__ == "__main__":
    main()
