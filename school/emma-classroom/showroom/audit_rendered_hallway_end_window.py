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
# Fixed ROI remeasured on exact 1920x1080 direct-corridor 07 evidence from
# PR #351 commit fb2b115. The straight-hall transform moves the original
# yellow window by approximately +25 px to the right inside this camera.
# Every structural band retains its original minimum pixel count; blank,
# shifted, pane-colored, missing-ray, and exposure mutations must still fail
# or pass as intentionally specified. Not native Roblox acceptance.
FRAME_BANDS = {
    "top": ((867, 483, 1070, 501), 350),
    "bottom": ((867, 586, 1070, 603), 350),
    "left": ((865, 485, 882, 600), 170),
    "right": ((1057, 485, 1078, 600), 170),
    "mullion_left": ((929, 485, 943, 597), 120),
    "mullion_right": ((992, 485, 1007, 597), 120),
    "crossbar": ((863, 531, 1074, 552), 135),
}
GLASS_AREAS = {
    "left_upper": (876, 493, 912, 526),
    "right_upper": (1012, 493, 1046, 526),
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
    draw.rectangle((871, 486, 1067, 597), fill=pane_color)
    for rect in ((871, 486, 1067, 493), (871, 590, 1067, 597),
                 (871, 486, 877, 598), (1061, 486, 1067, 598),
                 (934, 486, 941, 598), (999, 486, 1006, 598),
                 (871, 537, 1067, 543)):
        draw.rectangle(rect, fill=sash_color)
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
