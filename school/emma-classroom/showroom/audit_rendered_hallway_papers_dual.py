#!/usr/bin/env python3
"""Require independent source-rendered evidence of ABVM hallway student art.

The 06 gallery camera is an oblique close-up, while 07 faces the real
yellow end window. After the closet topology changed, the paper test was
moved to 07 only, leaving 06 covered by a generic nonblank test. This
script rejects that blind spot without weakening either existing image gate.

These source-derived screenshots do NOT verify native Roblox materials,
SurfaceGui coloring, mobile physics, measured FPS or real student artwork.
"""
from __future__ import annotations

import argparse
from hashlib import sha256
from pathlib import Path

from PIL import Image, ImageDraw
from audit_rendered_hallway_papers import inspect

VIEWPORT = (1920, 1080)
MIN_GALLERY_REGIONS = 7
MIN_GALLERY_PALE_PIXELS = 50000
MIN_OVERVIEW_REGIONS = 6
MIN_OVERVIEW_PALE_PIXELS = 25000
MIN_PERSPECTIVE_RATIO = 1.20


def metrics(gallery: Image.Image, overview: Image.Image) -> dict:
    if gallery.size != VIEWPORT or overview.size != VIEWPORT:
        raise AssertionError("HALL_DUAL_CAMERA_VIEWPORT_CHANGED")

    gallery_regions, gallery_pixels = inspect(gallery)
    overview_regions, overview_pixels = inspect(overview)
    if gallery_regions < MIN_GALLERY_REGIONS or gallery_pixels < MIN_GALLERY_PALE_PIXELS:
        raise AssertionError(
            "HALL_DUAL_GALLERY_CAMERA_MISSING_INDEPENDENT_PAPERS "
            f"areas={gallery_regions} pale_pixels={gallery_pixels}")
    if overview_regions < MIN_OVERVIEW_REGIONS or overview_pixels < MIN_OVERVIEW_PALE_PIXELS:
        raise AssertionError(
            "HALL_DUAL_OVERVIEW_CAMERA_MISSING_STUDENT_WORK "
            f"areas={overview_regions} pale_pixels={overview_pixels}")

    # Verify rendered PIXELS, not just file hashes: differently compressed
    # copies of the same screenshot must be rejected too.
    gallery_digest = sha256(gallery.convert("RGB").tobytes()).digest()
    overview_digest = sha256(overview.convert("RGB").tobytes()).digest()
    if gallery_digest == overview_digest:
        raise AssertionError("HALL_DUAL_CAMERA_IDENTICAL_RENDERED_PIXELS")
    if gallery_regions <= overview_regions or (
        gallery_pixels <= overview_pixels * MIN_PERSPECTIVE_RATIO
    ):
        raise AssertionError(
            "HALL_DUAL_CAMERA_WRONG_PERSPECTIVE_OR_SWAPPED "
            f"gallery_areas={gallery_regions} overview_areas={overview_regions} "
            f"gallery_pixels={gallery_pixels} overview_pixels={overview_pixels}")

    return {
        "gallery_regions": gallery_regions,
        "gallery_pale_pixels": gallery_pixels,
        "overview_regions": overview_regions,
        "overview_pale_pixels": overview_pixels,
        "independent_cameras": True,
        "source_derived_only": True,
        "native_iphone_qa_required": True,
    }


def invented_test_frame(count: int, half_width: int, half_height: int,
                        first_x: int, gap_x: int) -> Image.Image:
    """Only anonymous synthetic diamonds; never real children's schoolwork."""
    result = Image.new("RGB", VIEWPORT, (53, 66, 79))
    painter = ImageDraw.Draw(result)
    for i in range(count):
        cx = first_x + i * gap_x
        cy = 350 + i * 4
        painter.polygon(
            [(cx, cy-half_height), (cx+half_width, cy),
             (cx, cy+half_height), (cx-half_width, cy)],
            fill=(128, 141, 150),
        )
    return result


def expect_rejected(gallery: Image.Image, overview: Image.Image,
                    error_part: str) -> None:
    try:
        metrics(gallery, overview)
    except AssertionError as exc:
        if error_part not in str(exc):
            raise AssertionError(
                f"Unexpected mutation result: {exc}; expected {error_part}"
            ) from exc
    else:
        raise AssertionError(
            "HALL_DUAL_CAMERA_ADVERSARIAL_FALSE_ACCEPT " + error_part)


def self_test() -> None:
    gallery = invented_test_frame(7, 53, 70, 85, 130)
    overview = invented_test_frame(6, 38, 75, 100, 125)
    result = metrics(gallery, overview)
    assert result["gallery_regions"] == 7
    assert result["overview_regions"] == 6
    blank = Image.new("RGB", VIEWPORT, (53, 66, 79))
    expect_rejected(blank, overview, "BARE_WALL")
    expect_rejected(gallery, blank, "BARE_WALL")
    expect_rejected(overview, gallery, "GALLERY_CAMERA_MISSING")
    expect_rejected(overview, overview, "GALLERY_CAMERA_MISSING")
    # Same raw RGB image, even if independently encoded, is not two views.
    expect_rejected(gallery, gallery, "IDENTICAL_RENDERED_PIXELS")
    # Distinct valid-sized views with the wrong perspective relationship
    # must be rejected rather than passing each camera in isolation.
    expect_rejected(gallery, invented_test_frame(6, 55, 75, 100, 125),
                    "WRONG_PERSPECTIVE_OR_SWAPPED")
    expect_rejected(gallery.resize((1112, 512)), overview, "VIEWPORT_CHANGED")
    expect_rejected(invented_test_frame(6, 53, 70, 85, 130),
                    overview, "GALLERY_CAMERA_MISSING")
    expect_rejected(gallery, invented_test_frame(5, 38, 75, 100, 125),
                    "OVERVIEW_CAMERA_MISSING")
    # A visually similar but too-small oblique view must not be allowed to
    # borrow credibility from the strong yellow-window overview.
    expect_rejected(invented_test_frame(7, 39, 51, 85, 130),
                    overview, "GALLERY_CAMERA_MISSING")
    print("HALL_DUAL_CAMERA_SELF_TEST_PASS "
          "missing_gallery,missing_overview,swapped,duplicated,"
          "duplicates,perspective_ratio,small_viewport,"
          "one_missing_each,weak_gallery_rejected=true")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gallery", type=Path)
    parser.add_argument("--overview", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    if args.gallery or args.overview:
        if not args.gallery or not args.overview:
            parser.error("both --gallery and --overview are required")
        with Image.open(args.gallery) as gallery, Image.open(args.overview) as overview:
            result = metrics(gallery, overview)
        print("PHOTO_HALL_DUAL_CAMERA_PIXELS_PASS "
              f"gallery_areas={result['gallery_regions']} "
              f"gallery_pale={result['gallery_pale_pixels']} "
              f"overview_areas={result['overview_regions']} "
              f"overview_pale={result['overview_pale_pixels']} "
              "two_independent_actual_source_views=true "
              "native_iphone_qa_pending=true")
    elif not args.self_test:
        parser.error("both screenshots are required unless --self-test")


if __name__ == "__main__":
    main()
