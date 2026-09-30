#!/usr/bin/env python3
from pathlib import Path

CLIENT = Path("school/src/client/Main.client.lua").read_text(encoding="utf-8")

REQUIRED = [
    'modal.Position = UDim2.fromScale(0.5, 0.42)',
    'modal.Size = UDim2.new(0.86, 0, 0, 254)',
    'modalSize.MaxSize = Vector2.new(410, 254)',
    'grid.CellSize = UDim2.new(0.5, -5, 0, 48)',
    'grid.FillDirectionMaxCells = 2',
    'answer.TextWrapped = true',
]
for snippet in REQUIRED:
    if snippet not in CLIENT:
        raise SystemExit(f"missing mobile layout invariant: {snippet}")

VIEWPORTS = {
    "iphone16_landscape": (852, 393),
    "narrow_landscape": (667, 375),
}
WIDTH_SCALE = 0.86
MAX_WIDTH = 410
HEIGHT = 254
CENTER_Y = 0.42
MIN_SIDE_CLEARANCE = 120
MIN_BOTTOM_CLEARANCE = 90
MIN_TOP_CLEARANCE = 28
MIN_TOUCH_HEIGHT = 44
ANSWER_TOUCH_HEIGHT = 48

for name, (width, height) in VIEWPORTS.items():
    card_width = min(width * WIDTH_SCALE, MAX_WIDTH)
    left = (width - card_width) / 2
    top = height * CENTER_Y - HEIGHT / 2
    right = width - (left + card_width)
    bottom = height - (top + HEIGHT)

    if left < MIN_SIDE_CLEARANCE or right < MIN_SIDE_CLEARANCE:
        raise SystemExit(f"{name}: side control clearance too small: left={left:.1f}, right={right:.1f}")
    if top < MIN_TOP_CLEARANCE:
        raise SystemExit(f"{name}: top clearance too small: {top:.1f}")
    if bottom < MIN_BOTTOM_CLEARANCE:
        raise SystemExit(f"{name}: bottom control clearance too small: {bottom:.1f}")
    if HEIGHT / height > 0.68:
        raise SystemExit(f"{name}: class card occupies too much viewport height")

if ANSWER_TOUCH_HEIGHT < MIN_TOUCH_HEIGHT:
    raise SystemExit("answer touch targets are below 44 px")

print("school mobile layout: PASS")
for name, (width, height) in VIEWPORTS.items():
    card_width = min(width * WIDTH_SCALE, MAX_WIDTH)
    left = (width - card_width) / 2
    top = height * CENTER_Y - HEIGHT / 2
    bottom = height - (top + HEIGHT)
    print(f"{name}: card={card_width:.1f}x{HEIGHT}, x={left:.1f}, y={top:.1f}, bottom-clear={bottom:.1f}")
