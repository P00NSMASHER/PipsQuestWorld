#!/usr/bin/env python3
"""Reject oversized foreground closet walls in the yellow-window camera.

Supplementary third-party source-image gate; NOT native Roblox/iPhone QA.
The supply closet stays physically sealed. Correct camera framing instead
of hiding the wall or weakening the existing paper/window semantic tests.
"""
from __future__ import annotations

import argparse
from pathlib import Path
from PIL import Image, ImageDraw

VIEWPORT = (1920, 1080)
SAMPLE = 8
MAX_FRAME_NEUTRAL = 0.14
MAX_RIGHT_HALF_NEUTRAL = 0.28


def closet_wall_color(rgb: tuple[int, int, int]) -> bool:
    """Rendered shaded pale-ochre closet wall, not blue plaster or stone."""
    r, g, b = rgb
    return (105 <= r <= 150 and 110 <= g <= 155 and 90 <= b <= 137
            and 1 <= g-r <= 13 and 7 <= g-b <= 24 and 1 <= r-b <= 20)


def inspect(image: Image.Image) -> dict:
    if image.size != VIEWPORT:
        raise AssertionError("HALL_OVERVIEW_FOREGROUND_VIEWPORT_CHANGED")
    pixels = image.convert("RGB").load()
    total = frame_wall = right = right_wall = 0
    for y in range(60, 1020, SAMPLE):
        for x in range(0, VIEWPORT[0], SAMPLE):
            wall = closet_wall_color(pixels[x, y])
            total += 1
            frame_wall += int(wall)
            if x >= VIEWPORT[0] // 2:
                right += 1
                right_wall += int(wall)
    frame_ratio = frame_wall / total
    right_ratio = right_wall / right
    if (frame_ratio > MAX_FRAME_NEUTRAL
            or right_ratio > MAX_RIGHT_HALF_NEUTRAL):
        raise AssertionError(
            "HALL_OVERVIEW_CLOSET_WALL_OCCLUDES_WINDOW_CAMERA "
            f"frame_fraction={frame_ratio:.3f} "
            f"right_half_fraction={right_ratio:.3f} "
            f"limits={MAX_FRAME_NEUTRAL:.2f},{MAX_RIGHT_HALF_NEUTRAL:.2f}")
    return {"frame_wall_fraction": round(frame_ratio, 4),
            "right_half_wall_fraction": round(right_ratio, 4),
            "source_renderer_only": True, "iphone_acceptance_pending": True}


def self_test() -> None:
    clear = Image.new("RGB", VIEWPORT, (53, 66, 79))
    assert inspect(clear)["frame_wall_fraction"] == 0
    thin = clear.copy()
    ImageDraw.Draw(thin).rectangle((1740, 0, 1919, 1079),
                                  fill=(122, 127, 114))
    inspect(thin)
    for color in ((122, 127, 114), (130, 136, 120), (115, 121, 103)):
        blocked = clear.copy()
        ImageDraw.Draw(blocked).rectangle((1100, 0, 1919, 1079), fill=color)
        try:
            inspect(blocked)
        except AssertionError as exc:
            assert "CLOSET_WALL_OCCLUDES" in str(exc)
        else:
            raise AssertionError("LARGE_FOREGROUND_WALL_FALSELY_ACCEPTED")
    try:
        inspect(clear.resize((1112, 512)))
    except AssertionError as exc:
        assert "VIEWPORT_CHANGED" in str(exc)
    else:
        raise AssertionError("WRONG_SCREENSHOT_SIZE_ACCEPTED")
    print("HALL_OVERVIEW_FOREGROUND_SELF_TEST_PASS "
          "oversized_wall_color_variants_and_viewport_rejected=true")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("image", nargs="?", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    if args.image:
        with Image.open(args.image) as img:
            stats = inspect(img)
        print("HALL_OVERVIEW_FOREGROUND_PIXELS_PASS "
              f"frame_wall={stats['frame_wall_fraction']:.3f} "
              f"right_half_wall={stats['right_half_wall_fraction']:.3f} "
              "native_iphone_qa_pending=true")
    elif not args.self_test:
        parser.error("image required unless --self-test")


if __name__ == "__main__":
    main()
