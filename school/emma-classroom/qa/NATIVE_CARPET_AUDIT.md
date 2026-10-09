# Native iPhone carpet audit — private review tool

This is an **offline, reviewer-guided screen**, not a replacement for a real Roblox Studio/iPhone walkthrough or a release approval. It exists because older source-derived renders and constructor tests passed while a real iPhone recording showed a nearly black alphabet rug, dot-like sun rays, and dot-like clouds.

## Running locally

Requires Python 3.10+, NumPy and OpenCV:

```sh
python3 -m pip install "numpy>=2,<3" "opencv-python-headless==4.13.0.92"
python3 school/emma-classroom/qa/audit_native_carpet_video.py --self-test
python3 school/emma-classroom/qa/audit_native_carpet_video.py \
  --video /private/path/to/new_iphone_walkthrough.mp4 \
  --seconds 12.0 \
  --polygon "200,300;620,270;780,380;730,500;220,500" \
  --sun-hint 500,380 \
  --report-json /private/local/results.json
```

The polygon and sun center in the example above are **illustrative coordinates**, not generally valid detections. A reviewer must inspect each new video, select a time when the complete circular rug is in view, trace a polygon over the blue carpet (excluding desks, alphabet border and Roblox UI), and mark the yellow sun center. A noncomparable camera angle should produce **INCONCLUSIVE**, not a fabricated pass.

The tool identifies the large central sun in that selected area and measures:

- Median blue-channel value in the carpet pixels (threshold 85 for this screen).
- Warm-colored ray components of meaningful area (at least 8).
- White cloud components of meaningful area (at least 8).
- Cloud components must fall within a source-relative radial ring around
  the visually selected sun (1.9–4.3 sun radii), not on unrelated classroom
  papers or window panels.
- At least seven of twelve angular sectors must contain substantial cloud
  and sun-ray components; one clustered corner is not a ring. A sample with
  enough blobs but implausible geometry is **INCONCLUSIVE**, not accepted.
  These are conservative screening heuristics, never an automatic approval.
- Source-video SHA-256 to distinguish recordings. The video itself supplies **no proven Roblox source commit**.

The three outcome states are **FAIL** (measured dark/dot-like regression), **INCONCLUSIVE** (viewpoint or region unsuitable), and **REVIEW_REQUIRED** (minimal pixel thresholds met, but a person must check the actual sun/cloud shapes, ten numbers, 26 letters, photographic fidelity, collisions and FPS). **This tool never reports a native-device approval or independently confirms the published Roblox version.**

## Known failing native reference

A private October 9 landscape iPhone recording, measured at 11.5 seconds with a reviewed carpet region, produced:

| Measurement | Known failing result |
| --- | ---: |
| Median blue-channel brightness | 54 |
| Sufficiently large warm ray components | 2 |
| Sufficiently large white cloud components | 0 |
| Screening verdict | **FAIL** on all three conditions |

An independently generated bright synthetic rug with broader rays/clouds passes the numeric thresholds only as **REVIEW_REQUIRED**; synthetic dark/dot-like geometry, unrelated white paper rectangles,
fake cloud clusters, clustered orange ray stickers and invalid ROI are rejected
by the self-test. Thresholds are deliberately conservative, not a claim that pixel segmentation is perceptually sufficient. The private source video, frames, screenshots, file paths, Roblox account screens, identifiers, and EXIF **must never be pushed to GitHub or uploaded to a workflow artifact**.

## Release controls

Use this test locally on any later iPhone footage. Attach only a plain numeric receipt to the PR after removing paths and identifying details. Release/progress-preview authorization is separate: protect study systems, keep 16 approved fallback desk/chair pairs, keep premium mesh activation disabled, and require native reviewer acceptance before describing a build as visually accepted. Never accept a green static/headless screenshot or this numeric screen as proof of true native rendering quality.
