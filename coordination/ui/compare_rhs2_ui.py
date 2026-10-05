#!/usr/bin/env python3
"""Local-only RHS2 UI ROI comparison helper.

This is a triage harness, not a parity certificate. It compares normalized UI
regions from authorized reference frames with rendered captures taken from an
exact product SHA. Requires Pillow + numpy.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

try:
    import numpy as np
    from PIL import Image
except Exception as exc:
    raise SystemExit(
        "compare_rhs2_ui.py requires Pillow and numpy in the local QA environment: "
        + str(exc)
    )


def parse_map(values):
    out = {}
    for value in values:
        if "=" not in value:
            raise SystemExit(f"Expected FRAME_ID=/path/to/image, got: {value}")
        key, path = value.split("=", 1)
        out[key.strip()] = Path(path).expanduser().resolve()
    return out


def crop_normalized(image, box):
    x0, y0, x1, y1 = box
    width, height = image.size
    left = max(0, min(width - 1, round(x0 * width)))
    top = max(0, min(height - 1, round(y0 * height)))
    right = max(left + 1, min(width, round(x1 * width)))
    bottom = max(top + 1, min(height, round(y1 * height)))
    return image.crop((left, top, right, bottom))


def rgb_array(image):
    return np.asarray(image.convert("RGB"), dtype=np.float32)


def rgb_mae(reference, candidate):
    return float(np.abs(rgb_array(reference) - rgb_array(candidate)).mean())


def grayscale_array(image):
    rgb = rgb_array(image)
    return (rgb[..., 0] * 0.299) + (rgb[..., 1] * 0.587) + (rgb[..., 2] * 0.114)


def edge_map(image):
    gray = grayscale_array(image)
    gx = np.zeros_like(gray)
    gy = np.zeros_like(gray)
    gx[:, 1:] = np.abs(gray[:, 1:] - gray[:, :-1])
    gy[1:, :] = np.abs(gray[1:, :] - gray[:-1, :])
    return np.sqrt((gx * gx) + (gy * gy))


def edge_mae(reference, candidate):
    return float(np.abs(edge_map(reference) - edge_map(candidate)).mean())


def dct_matrix(size):
    matrix = np.zeros((size, size), dtype=np.float64)
    factor = math.pi / (2.0 * size)
    for k in range(size):
        scale = math.sqrt(1.0 / size) if k == 0 else math.sqrt(2.0 / size)
        for n in range(size):
            matrix[k, n] = scale * math.cos((2 * n + 1) * k * factor)
    return matrix


_DCT32 = dct_matrix(32)


def perceptual_hash(image):
    gray = image.convert("L").resize((32, 32), Image.Resampling.LANCZOS)
    values = np.asarray(gray, dtype=np.float64)
    coeffs = _DCT32 @ values @ _DCT32.T
    low = coeffs[:8, :8].flatten()
    body = low[1:]
    median = float(np.median(body))
    return (body > median).astype(np.uint8)


def phash_hamming(reference, candidate):
    return int(np.count_nonzero(perceptual_hash(reference) != perceptual_hash(candidate)))


def resize_like(candidate, reference):
    if candidate.size == reference.size:
        return candidate
    return candidate.resize(reference.size, Image.Resampling.LANCZOS)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--reference", action="append", default=[], metavar="FRAME=PATH")
    parser.add_argument("--capture", action="append", default=[], metavar="FRAME=PATH")
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    manifest_path = Path(args.manifest).expanduser().resolve()
    manifest = json.loads(manifest_path.read_text())
    references = parse_map(args.reference)
    captures = parse_map(args.capture)

    thresholds = manifest.get("thresholds", {})
    rgb_warn = float(thresholds.get("rgbMaeWarn", 45))
    edge_warn = float(thresholds.get("edgeMaeWarn", 55))
    hash_warn = int(thresholds.get("pHashHammingWarn", 18))

    report = {
        "schemaVersion": 1,
        "manifest": str(manifest_path),
        "status": "TRIAGE_ONLY",
        "regions": [],
        "missing": [],
        "exactParityClaimed": False,
    }

    image_cache = {}

    def load(path):
        key = str(path)
        if key not in image_cache:
            image_cache[key] = Image.open(path).convert("RGB")
        return image_cache[key]

    for region in manifest.get("regions", []):
        frame = region["frame"]
        region_id = region["id"]
        if frame not in references or frame not in captures:
            report["missing"].append({
                "region": region_id,
                "frame": frame,
                "referencePresent": frame in references,
                "capturePresent": frame in captures,
            })
            continue

        reference_image = load(references[frame])
        capture_image = load(captures[frame])
        ref_crop = crop_normalized(reference_image, region["box"])
        cap_crop = crop_normalized(capture_image, region["box"])
        cap_crop = resize_like(cap_crop, ref_crop)

        metrics = {
            "rgbMae": rgb_mae(ref_crop, cap_crop),
            "edgeMae": edge_mae(ref_crop, cap_crop),
            "pHashHamming": phash_hamming(ref_crop, cap_crop),
        }
        warnings = []
        if metrics["rgbMae"] > rgb_warn:
            warnings.append("RGB_MAE")
        if metrics["edgeMae"] > edge_warn:
            warnings.append("EDGE_MAE")
        if metrics["pHashHamming"] > hash_warn:
            warnings.append("PHASH")

        report["regions"].append({
            "id": region_id,
            "frame": frame,
            "priority": region.get("priority"),
            "box": region["box"],
            "metrics": metrics,
            "warnings": warnings,
            "status": "REVIEW" if warnings else "NUMERICALLY_CLOSE",
            "note": region.get("note"),
        })

    if report["missing"]:
        report["status"] = "INCOMPLETE"
    elif any(item["warnings"] for item in report["regions"]):
        report["status"] = "REVIEW_REQUIRED"
    else:
        report["status"] = "NUMERIC_TRIAGE_PASS__HUMAN_RENDER_REVIEW_STILL_REQUIRED"

    Path(args.out).write_text(json.dumps(report, indent=2) + "\n")
    print(report["status"])
    for item in report["regions"]:
        print(
            f"{item['id']}: rgb={item['metrics']['rgbMae']:.2f} "
            f"edge={item['metrics']['edgeMae']:.2f} "
            f"phash={item['metrics']['pHashHamming']} "
            f"status={item['status']}"
        )
    if report["missing"]:
        print("Missing frame pairs:", ", ".join(x["region"] for x in report["missing"]))


if __name__ == "__main__":
    main()
