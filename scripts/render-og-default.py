#!/usr/bin/env python3
"""Renders site/og-default.png — the brand card used as the link-preview image
wherever a shared subject has no picture of its own.

Kept in the repo for the same reason `render-launch-mark.swift` is: the asset
is derived from the app's own splash geometry, and if the wordmark, the disc
or the brass value ever change, this regenerates it rather than leaving a
mystery binary that slowly drifts away from the product.

    python3 scripts/render-og-default.py      # needs Pillow + macOS system fonts

⚠️ 1200x630 is the size asserted in the `og:image:width`/`height` tags that
`site/api/share.js` emits for this file specifically. Change the canvas and you
must change those too, or clients lay out the card against a size it isn't.
"""

import pathlib
from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 630
BG = (0, 0, 0)             # AtlasColors.background, dark
BRASS = (0x8B, 0x75, 0x35)  # AtlasColors.accent / --brass
TEXT = (255, 255, 255)      # SplashView draws the wordmark white

# SplashView's geometry, scaled: a 44pt disc, the wordmark AtlasSpacing.md
# (16pt) beneath it. x4 reads cleanly at the size clients render a 1200x630
# card down to.
SCALE = 4
DISC = 44 * SCALE
GAP = 16 * SCALE
WORDMARK = "Dozent"
FONT_SIZE = 15 * SCALE      # .system(size: 15, design: .serif)
TRACKING = 2 * SCALE        # tracked 2, as the app and the site both draw it
FONT_PATH = "/System/Library/Fonts/NewYork.ttf"

OUT = pathlib.Path(__file__).resolve().parent.parent / "site" / "og-default.png"


def main() -> None:
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT_PATH, FONT_SIZE)

    # Measure per glyph: PIL has no letter-spacing, and the tracking is part of
    # how the mark reads.
    widths = [draw.textlength(c, font=font) for c in WORDMARK]
    text_w = sum(widths) + TRACKING * (len(WORDMARK) - 1)
    ascent, descent = font.getmetrics()
    text_h = ascent + descent

    top = (H - (DISC + GAP + text_h)) // 2
    draw.ellipse(
        [(W - DISC) // 2, top, (W + DISC) // 2, top + DISC], fill=BRASS
    )

    x = (W - text_w) / 2
    y = top + DISC + GAP
    for char, width in zip(WORDMARK, widths):
        draw.text((x, y), char, font=font, fill=TEXT)
        x += width + TRACKING

    img.save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT} ({W}x{H})")


if __name__ == "__main__":
    main()
