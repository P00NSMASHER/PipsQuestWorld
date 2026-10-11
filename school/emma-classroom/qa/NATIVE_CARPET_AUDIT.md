# Native iPhone carpet audit — private review tool

This is an **offline, reviewer-guided screen**, not a replacement for a real Roblox Studio/iPhone walkthrough or a release approval. It exists because older source-derived renders and constructor tests passed while a real iPhone recording showed a nearly black alphabet rug, dot-like sun rays, and dot-like clouds.

## Versioned numeric receipt

The current screening profile is **`rug-native-v3`**. It retains v2's
cloud ring-distance and angular-distribution checks, and adds a **36-sector
camera-coverage gate**. At least 83% of the expected sun-ray or cloud ring
must lie within the reviewed polygon before missing shapes can be called a
defect. Partly off-camera art is **INCONCLUSIVE**, not a false failure.
Independently measurable carpet darkness can still fail even when cropped.

Historical v1 and v2 receipts retain their own profile labels; v3's cropped
view results must not be compared as if equivalent. Even a
`REVIEW_REQUIRED` result cannot approve the game without native inspection.

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
- **Before calling artwork missing**, confirm at least 83% of 36 sampled
  radial directions lie inside the user-reviewed carpet polygon and image
  for the relevant ray or cloud ring. A cropped view is insufficient evidence
  of missing shapes, though actual dark carpet pixels remain measurable.
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

## Three-frame consensus mode (recommended for a new iPhone walkthrough)

The original `audit_native_carpet_video.py` screens a single frame and remains
available for historical v2 receipts. Because the camera moves during Roblox
walkthroughs, it is too easy to select a frame that is momentarily occluded.

Use `audit_native_carpet_sequence.py` for new review recordings. Its
`rug-native-sequence-v2` profile applies the *same* v3 pixel detector to three closely spaced frames, by default
the manually reviewed time plus/minus **0.10 seconds**. It never uploads
media, stores decoded images, changes Roblox or guesses the source commit.

```sh
python3 school/emma-classroom/qa/audit_native_carpet_sequence.py --self-test
python3 school/emma-classroom/qa/audit_native_carpet_sequence.py \
  --video /private/local/Roblox_iPhone_review.mp4 \
  --seconds 11.4 --sample-offset 0.10 \
  --polygon "340,310;600,275;680,330;750,455;720,510;230,510;200,450;260,350" \
  --sun-hint 499,383 \
  --report-json /private/local/three_frame_receipt.json
```

The coordinates are for the *older known-defective recording only*.
For a new recording, select the region and sun center visually;
reusing these coordinates with a different camera angle is invalid.

Screening rules are intentionally conservative:

- **FAIL** only when the *same specific defect* occurs in at least two
  distinct comparable frames.
- **REVIEW_REQUIRED** when at least two frames satisfy the pixel screen and
  no frame reports a known defect. A person must still inspect the original
  native video for shape fidelity, readable letters/numbers and movement/FPS.
- **INCONCLUSIVE** for camera movement, bad regions, mixed one-off failures,
  or duplicate decoded frames. Do not call these runs passes. The latest
  reviewer also measures yellow sun-center drift across the three frames
  (at most 1.4% of frame width, minimum 10px) and sun-area scale change
  (at most 30%). Significant camera pans or zooms explicitly invalidate
  consensus, even if two frames separately report the same defect.

The older private October 9 12:49 recording visually shows the dark rug,
dot-like orange rays and absent cloud silhouettes. Historical v2 screens
reported three concurrent defects. However, the reviewed 11.4-second region
contains only **24 of 36 (67%)** cloud-ring sampling directions, so under v3
that frame's *missing-cloud count* is **INCONCLUSIVE**: shapes outside the
screen cannot be measured. Its dark-rug pixels remain independent evidence
of failure. This is a new screening rule, not an assertion that the older
recording contains properly visible clouds.
Nearby frames taken while the phone camera turns are INCONCLUSIVE.
The known failure is *not* evidence of the separately published version 72.

The output includes only scalar metrics, statuses, sampling times and the
recording's SHA-256 fingerprint. It explicitly marks source commit and
published version as `NOT_VERIFIABLE`; neither can be proven from ordinary
screen pixels. Do not upload that fingerprint or the private numeric
receipt unless the user wants to share it. CI runs synthetic tests only,
never video files.

---
## Release controls

Use this test locally on any later iPhone footage. Attach only a plain numeric receipt to the PR after removing paths and identifying details. Release/progress-preview authorization is separate: protect study systems, keep 16 approved fallback desk/chair pairs, keep premium mesh activation disabled, and require native reviewer acceptance before describing a build as visually accepted. Never accept a green static/headless screenshot or this numeric screen as proof of true native rendering quality.

## New version-74 video acceptance

Version 74 is the latest confirmed owner-review publication recorded on
October 9; no uploaded native iPhone walkthrough has been proven to belong
to that version. Obtain a short steady clip including the **entire circular
rug**, all numbered white clouds, sun rays and the alphabet border. If the
view is cropped, moving or obscured by a chair, return **INCONCLUSIVE**
instead of fabricating a positive or negative result. Script success never
certifies reading legibility, photographic identity or mobile FPS.
