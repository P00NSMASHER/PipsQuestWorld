#!/usr/bin/env python3
"""Semantic pixel gate for Emma's photo-based 3D yellow hallway end window.

Tests exact headless, source-derived fixed 07-hall-yellow-end-window camera.
Not Roblox native rendering, surveyed geometry or iPhone acceptance.
Original people/photographs are not used or stored in this public repo.
"""
from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance

VIEWPORT = (1920, 1080)
SUN_CENTER = (960, 506)
# Strict ROIs for the *straight-axis* 07 camera (100,5.7,21 -> 155,7.35,15.5).
# In reviewed b6d0f2b0 pixels the left jamb occupies x=872..875 and the first
# mullion x=935..936. Earlier pre-rotation x=845 and x=923 ROIs falsely
# reported a missing window despite the actual gold frame being visible.
# Preserve all original minimum pixel counts, sun rays and negative controls.
FRAME_BANDS = {
    "top": ((867, 479, 1070, 491), 350),
    "bottom": ((867, 590, 1070, 603), 350),
    "left": ((868, 486, 881, 599), 170),
    "right": ((1059, 486, 1072, 599), 170),
    "mullion_left": ((932, 487, 945, 590), 120),
    "mullion_right": ((996, 487, 1008, 590), 120),
    "crossbar": ((870, 530, 1068, 548), 135),
}
GLASS_AREAS = {
    "left_upper": (878, 493, 925, 526),
    "right_upper": (1012, 493, 1053, 526),
}
SUN_REGION = (920, 484, 1001, 532)
SUN_CENTER_REGION = (948, 496, 975, 519)


def golden_sash(rgb: tuple[int, int, int]) -> bool:
    r, g, b = rgb
    return r >= 76 and g >= 60 and 7 <= r-g <= 22 and g-b >= 21 and b <= 90


def bright_sun(rgb: tuple[int, int, int]) -> bool:
    r, g, b = rgb
    return r >= 97 and g >= 91 and r <= g+16 and g-b >= 40 and b <= 85


def dark_glazing(rgb: tuple[int, int, int]) -> bool:
    r, g, b = rgb
    return (39 <= r <= 85 and 52 <= g <= 105 and 60 <= b <= 120
            and g-r >= 8 and b-g >= 5)


def count_pixels(pixels, rect, match) -> int:
    x0, y0, x1, y1 = rect
    return sum(bool(match(pixels[x, y])) for y in range(y0, y1)
               for x in range(x0, x1))


def inspect(image: Image.Image) -> dict:
    if image.size != VIEWPORT:
        raise AssertionError("HALL_END_WINDOW_VIEWPORT_CHANGED")
    pixels = image.convert("RGB").load()
    frame_counts = {}
    for label, (rect, minimum) in FRAME_BANDS.items():
        count = count_pixels(pixels, rect, golden_sash)
        frame_counts[label] = count
        if count < minimum:
            raise AssertionError(
                f"HALL_END_WINDOW_FRAME_MISSING_OR_OCCLUDED {label} "
                f"gold_pixels={count} minimum={minimum}")

    glass_counts = {}
    for label, rect in GLASS_AREAS.items():
        count = count_pixels(pixels, rect, dark_glazing)
        glass_counts[label] = count
        if count < 450:
            raise AssertionError(
                f"HALL_END_WINDOW_DARK_GLAZING_MISSING {label} "
                f"dark_pixels={count}")

    center_count = count_pixels(pixels, SUN_CENTER_REGION, bright_sun)
    if center_count < 30:
        raise AssertionError(
            f"HALL_END_WINDOW_SUNBURST_CENTER_MISSING bright_pixels={center_count}")

    cx, cy = SUN_CENTER
    sector_counts = [0] * 8
    x0, y0, x1, y1 = SUN_REGION
    for y in range(y0, y1):
        for x in range(x0, x1):
            if not bright_sun(pixels[x, y]):
                continue
            dx, dy = x-cx, y-cy
            distance = math.hypot(dx, dy)
            if 14 <= distance <= 45:
                angle = (math.atan2(dy, dx) + math.pi/8) % (2 * math.pi)
                sector = int(angle * 4 / math.pi)
                sector_counts[sector] += 1
    if any(c < 3 for c in sector_counts):
        raise AssertionError(
            "HALL_END_WINDOW_SUNBURST_RAY_SECTORS_MISSING "
            + ",".join(map(str, sector_counts)))
    return {
        "frame_gold_pixels": frame_counts,
        "dark_glazing_pixels": glass_counts,
        "sunburst_center_pixels": center_count,
        "sunburst_ray_sector_pixels": sector_counts,
        "source_derived_only": True,
        "native_roblox_iphone_qa_required": True,
    }


def synthetic_window(missing_ray: int | None = None,
                     pane_color=(55, 72, 80),
                     sash_color=(106, 90, 35)) -> Image.Image:
    image = Image.new("RGB", VIEWPORT, (53, 66, 79))
    draw = ImageDraw.Draw(image)
    draw.rectangle((872, 483, 1065, 597), fill=pane_color)
    # The synthetic source-of-truth uses the same calibrated jambs as the
    # actual camera gate; mutations still independently remove each element.
    for rect, _minimum in FRAME_BANDS.values():
        x0, y0, x1, y1 = rect
        draw.rectangle((x0, y0, x1 - 1, y1 - 1), fill=sash_color)
    draw.ellipse((953, 499, 967, 513), fill=(128, 118, 39))
    cx, cy = SUN_CENTER
    for i in range(8):
        if i == missing_ray:
            continue
        angle = i * math.pi / 4
        draw.line((round(cx+15*math.cos(angle)),
                   round(cy+15*math.sin(angle)),
                   round(cx+24*math.cos(angle)),
                   round(cy+24*math.sin(angle))),
                  fill=(128, 118, 39), width=3)
    return image


def expect_rejected(image: Image.Image, reason: str) -> None:
    try:
        inspect(image)
    except AssertionError as exc:
        if reason not in str(exc):
            raise AssertionError(
                f"Unexpected failure: {exc}; expected {reason}") from exc
    else:
        raise AssertionError("HALL_END_WINDOW_NEGATIVE_TEST_ACCEPTED " + reason)


def self_test() -> None:
    good = synthetic_window()
    inspect(good)
    expect_rejected(Image.new("RGB", VIEWPORT, (53, 66, 79)),
                    "FRAME_MISSING")
    expect_rejected(synthetic_window(sash_color=(100, 75, 38)),
                    "FRAME_MISSING")
    expect_rejected(synthetic_window(pane_color=(106, 90, 35)),
                    "DARK_GLAZING_MISSING")
    expect_rejected(ImageChops.offset(good, 430, 0), "FRAME_MISSING")
    for i in range(8):
        expect_rejected(synthetic_window(missing_ray=i),
                        "SUNBURST_RAY_SECTORS_MISSING")
    erased_sun = good.copy()
    ImageDraw.Draw(erased_sun).rectangle((934, 484, 986, 532),
                                          fill=(55, 72, 80))
    expect_rejected(erased_sun, "SUNBURST_CENTER_MISSING")
    for factor in (0.85, 0.95, 1.1):
        inspect(ImageEnhance.Brightness(good).enhance(factor))
    print("PHOTO_END_WINDOW_SEMANTIC_SELF_TEST_PASS "
          "blank brown_fake floodfill shifted 8_missing_rays erased_sun "
          "exposure_variants_rejected_or_accepted_as_expected=true")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("image", nargs="?", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    if args.image:
        with Image.open(args.image) as image:
            stats = inspect(image)
        print("PHOTO_END_WINDOW_SEMANTIC_PIXELS_PASS "
              f"frame={stats['frame_gold_pixels']} "
              f"glass={stats['dark_glazing_pixels']} "
              f"sun_center={stats['sunburst_center_pixels']} "
              f"sun_ray_octants={stats['sunburst_ray_sector_pixels']} "
              "native_roblox_iphone_pending=true")
    elif not args.self_test:
        parser.error("image required unless --self-test")


if __name__ == "__main__":
    main()
