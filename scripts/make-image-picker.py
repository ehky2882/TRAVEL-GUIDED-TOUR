#!/usr/bin/env python3
"""Build the image picker: one page where the owner taps hero + gallery picks.

The owner's preferred way to choose images (2026-10-02, after Boston: "i really
like the image picker - can we remember that for future sessions"). It replaces
sending candidates inline in batches. Each tour is a row of numbered photos;
the first tap is the HERO and later taps are gallery 1, 2, ... in tap order. A
lightbox shows the full photo. Picks survive a reload, through localStorage.
A text box assembles every pick as one line per tour, ready to paste back:

    01 massachusetts-state-house: 01-4 hero, 01-1, 01-7

INPUT: a working directory holding `data.json` plus the candidate JPEGs it
names. Keep each JPEG about 1000-1600 px on the long side; Boston's 258 came to
32 MB. `data.json` is a list, one object per tour or walk stop, in display order:

    [{"num": "01", "slug": "massachusetts-state-house",
      "title": "Massachusetts State House",
      "imgs": [{"code": "01-1", "f": "img/01-1.jpg", "w": 5755, "h": 3842,
                "lic": "Unsplash", "credit": false, "by": "Aubrey Odom"}]}]

  num     the label the owner refers to; a walk stop uses e.g. "W3-2"
  code    shown as a badge on the card, and what comes back in the paste.
          It must be unique across the page
  w, h    the SOURCE photo's size, shown so the owner can see what crops well
  lic     a short licence label (Unsplash / Pexels / Public domain / CC BY 4.0)
  credit  true for CC BY / BY-SA. The page marks it CREDIT NEEDED, because the
          app has no credit line and the credit must then go in drafts/CREDITS.md
  by      the photographer, shown on the card

OUTPUT: `<out>` (default `picker.html` in the directory) plus `files.json`, the
map to hand the Artifact tool's `files` parameter so every image is published
beside the page:

    python3 scripts/make-image-picker.py <dir> --city Boston \\
        --subtitle "30 tours + 6 walk stops · Atlas Studio BOS"
    # then Artifact publish: file_path=<dir>/picker.html, files=<dir>/files.json's map

Re-running after adding candidates keeps the same localStorage key, so picks
the owner already made are kept.
"""
import argparse
import html
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(HERE, "image-picker", "template.html")
REQUIRED = ("num", "slug", "title", "imgs")
REQUIRED_IMG = ("code", "f", "w", "h", "lic", "credit", "by")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("dir", help="working directory holding data.json and the images")
    ap.add_argument("--city", required=True, help="e.g. Boston")
    ap.add_argument("--subtitle", default="", help="one line under the heading")
    ap.add_argument("--key", help="localStorage key (default: <city>-picks-v1)")
    ap.add_argument("--out", default="picker.html", help="page filename inside dir")
    a = ap.parse_args()

    data = json.load(open(os.path.join(a.dir, "data.json"), encoding="utf-8"))
    errors, codes, files = [], set(), {}
    for s in data:
        for k in REQUIRED:
            if k not in s:
                errors.append(f"{s.get('num', '?')}: missing '{k}'")
        for im in s.get("imgs", []):
            for k in REQUIRED_IMG:
                if k not in im:
                    errors.append(f"{im.get('code', '?')}: missing '{k}'")
            c = im.get("code")
            if c in codes:
                errors.append(f"{c}: code used twice; the paste-back would be ambiguous")
            codes.add(c)
            p = os.path.join(a.dir, im.get("f", ""))
            if not os.path.isfile(p):
                errors.append(f"{c}: image file not found: {im.get('f')}")
            else:
                files[im["f"]] = os.path.abspath(p)
    if errors:
        print("REFUSED — fix data.json first:", *errors[:40], sep="\n  ")
        sys.exit(1)

    key = a.key or re.sub(r"[^a-z0-9]+", "-", a.city.lower()).strip("-") + "-picks-v1"
    page = open(TEMPLATE, encoding="utf-8").read()
    # The data goes inside a <script>; stop a stray "</" in a title or credit from closing it.
    blob = json.dumps(data, ensure_ascii=False).replace("</", "<\\/")
    for tok, val in (
        ("__DATA__", blob),
        ("__KEY__", key),
        ("__TITLE__", html.escape(f"{a.city} Image Picks")),
        ("__HEADING__", html.escape(f"{a.city}: pick hero & gallery")),
        ("__SUBTITLE__", html.escape(a.subtitle)),
    ):
        assert page.count(tok) == 1, f"template must carry {tok} exactly once"
        page = page.replace(tok, val)

    out = os.path.join(a.dir, a.out)
    open(out, "w", encoding="utf-8").write(page)
    json.dump(files, open(os.path.join(a.dir, "files.json"), "w"), indent=0)
    mb = sum(os.path.getsize(p) for p in files.values()) / 1e6
    print(f"wrote {out}: {len(data)} tours, {len(codes)} images, {mb:.1f} MB of images")
    print(f"wrote {os.path.join(a.dir, 'files.json')} (pass as the Artifact 'files' map)")
    if mb > 60:
        print("WARN: over ~64 MB, so it needs more than one publish. Shrink the JPEGs, or publish in parts")


if __name__ == "__main__":
    main()
