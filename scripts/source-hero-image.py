#!/usr/bin/env python3
"""Find a public-domain hero photograph for one subject, and prove it.

Wikimedia Commons only, `pd`/`cc0` only. `CLAUDE.md` § Image Pipeline records
the owner's policy: the app has no attribution UI, so CC BY / BY-SA cannot
ship, and public-domain imagery carries no such obligation.

🔴 BOTH GATES, AS SEPARATE CALLS. A single compound prompt gets answered on
subject match alone and silently drops the rest — that shipped a set of
19th-century Rijksmuseum prints to the owner as photographs.

  Gate A  a MODERN COLOUR PHOTOGRAPH? (rejects engravings, scans, plans)
  Gate B  the subject, with the look-alikes NAMED — naming the distractors is
          what caught the Column of Marcus Aurelius posing as Trajan's Column

⚠️ COMMONS RATE LIMITS ARE REAL AND THIS SCRIPT RESPECTS THEM. `upload.wikimedia.org`
returns **429** on bursts and **400** on a thumbnail width that is not on its
allowed list, so the width is never guessed: the API is asked for `thumburl`
and that URL is used verbatim, spaced by `SLEEP_S`.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import runstamp  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
API = "https://commons.wikimedia.org/w/api.php"
UA = ("AtlasCatalog/1.0 (https://github.com/ehky2882/TRAVEL-GUIDED-TOUR; "
      "hero image sourcing)")
SLEEP_S = 1.6
THUMB_W = 1280
MIN_SHORT, MIN_LONG = 900, 1200

# Public domain only. ⚠️ `cc-by-sa` and friends are NOT here on purpose.
PD_CODES = {"pd", "cc0"}


def _get(url):
    request = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def search(term, limit=8):
    url = API + "?" + urllib.parse.urlencode({
        "action": "query", "list": "search", "srsearch": f"{term} filetype:bitmap",
        "srnamespace": "6", "srlimit": str(limit), "format": "json"})
    return [hit["title"] for hit in _get(url).get("query", {}).get("search", [])]


def is_public_domain(license_code):
    """🔴 Substring matching would let `cc-by-sa-pd-mark-ish` through."""
    return (license_code or "").strip().lower() in PD_CODES


def big_enough(width, height):
    """Can it crop to 1200x900 without upscaling?"""
    if not width or not height:
        return False
    return min(width, height) >= MIN_SHORT and max(width, height) >= MIN_LONG


def file_info(title):
    url = API + "?" + urllib.parse.urlencode({
        "action": "query", "titles": title, "prop": "imageinfo",
        "iiprop": "url|size|extmetadata", "iiurlwidth": str(THUMB_W),
        "format": "json"})
    page = next(iter(_get(url)["query"]["pages"].values()))
    info = (page.get("imageinfo") or [None])[0]
    if not info:
        return None
    meta = info.get("extmetadata", {})
    return {"title": title,
            "width": info.get("width"), "height": info.get("height"),
            "license": (meta.get("License", {}) or {}).get("value"),
            "license_name": (meta.get("LicenseShortName", {}) or {}).get("value"),
            # ⚠️ Never a guessed width: Commons 400s on one not on its list.
            "thumb": info.get("thumburl")}


def selftest():
    fails, ran = [], []

    def check(name, ok):
        ran.append(name)
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    check("pd is public domain", is_public_domain("pd"))
    check("cc0 is public domain", is_public_domain("cc0"))
    check("case and padding do not matter", is_public_domain("  PD "))
    check("🔴 cc-by-sa is NOT — the app has no attribution UI",
          not is_public_domain("cc-by-sa-4.0"))
    check("🔴 nor cc-by", not is_public_domain("cc-by-3.0"))
    check("🔴 nor a code merely CONTAINING pd",
          not is_public_domain("cc-by-sa-pd-mark"))
    check("an absent licence is not public domain",
          not is_public_domain(None) and not is_public_domain(""))

    check("1280x960 is big enough for a 1200x900 crop", big_enough(1280, 960))
    check("exactly 1200x900 is big enough", big_enough(1200, 900))
    check("🔴 1200x800 is NOT — the short side would upscale",
          not big_enough(1200, 800))
    check("🔴 1000x1000 is NOT — the long side would upscale",
          not big_enough(1000, 1000))
    check("a portrait 900x1200 is big enough", big_enough(900, 1200))
    check("missing dimensions are not big enough",
          not big_enough(None, 900) and not big_enough(0, 0))

    print(f"\nSELFTEST {'OK' if not fails else 'FAILED'} — "
          f"{len(ran) - len(fails)}/{len(ran)}")
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--term", help="what to search Commons for")
    ap.add_argument("--limit", type=int, default=8)
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()

    run = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        if not a.term:
            print("need --term")
            return 2
        titles = search(a.term, a.limit)
        print(f"{len(titles)} Commons hit(s) for {a.term!r}\n")
        kept = 0
        for title in titles:
            time.sleep(SLEEP_S)
            try:
                info = file_info(title)
            except Exception as exc:                        # noqa: BLE001
                print(f"  ERR  {title[:60]}: {type(exc).__name__}")
                continue
            if not info:
                continue
            pd = is_public_domain(info["license"])
            big = big_enough(info["width"], info["height"])
            mark = "KEEP" if (pd and big) else "    "
            kept += pd and big
            print(f"  {mark} {title[:58]}")
            print(f"       {info['width']}x{info['height']} · "
                  f"{info['license_name']} ({info['license']}) · "
                  f"pd={pd} big={big}")
            if pd and big:
                print(f"       {info['thumb']}")
        print(f"\n{kept} candidate(s) survived licence + size")
        # 🔴 Surviving these is NOT approval. The pixels still have to pass
        # gate A and gate B before anything is published.
        print("⚠️  Licence and size are necessary, not sufficient — verify the")
        print("    PIXELS through both gates before using any of these.")
        return 0 if kept else 1
    finally:
        run.close()


if __name__ == "__main__":
    sys.exit(main())
