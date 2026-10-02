#!/usr/bin/env python3
"""Download each post's cover frame — the last thing to look at before asking.

WHY THIS EXISTS
---------------
A pin needs a coordinate before `make-link-pin.py` will mint it, and the caption
does not always name the place. Rule 8d says to search the venue's name first,
then its own site, then OSM — and only then ask the owner. This is one more
look before that last step: **the cover frame**, the one still every platform
serves for a post. A shop sign, a street name or a recognisable landmark in it
can settle a location that no caption states.

🔴 IT IS ONE FRAME, NOT THE VIDEO. The process never downloads a creator's video
— `make-link-pin.py` says so, deliberately, and TikTok's API exposes no video
file anyway. If the frame does not settle it, ask the owner, who can watch it.
On #1040 five posts with no name anywhere were resolved exactly that way.

It needs NO coordinate, which is the point: `make-link-pin.py` downloads the
same frame, but only after it already has one. The frame is saved UNCROPPED —
the hero crop would cut away the edges, and the edge is where a sign usually is.

The fetching is `make-link-pin.py`'s own, imported rather than copied, so the
two cannot drift: `oembed()` (TikTok, YouTube, and Instagram via its embed page)
and `best_thumbnail()` (the largest frame the platform will serve).

EXIT
----
0  every cover was fetched
2  COULD NOT VERIFY — at least one was not, or there was nothing to fetch.
   A cover that failed to download is not a cover that showed nothing.

    python3 scripts/fetch-cover.py --urls /tmp/urls.txt --out-dir /tmp/covers
    python3 scripts/fetch-cover.py --url https://www.tiktok.com/@x/video/123
"""
from __future__ import annotations

import argparse
import importlib.util
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import runstamp  # noqa: E402


def _mlp():
    spec = importlib.util.spec_from_file_location("_mlp", os.path.join(HERE, "make-link-pin.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def parse_urls(text: str) -> list[str]:
    """One URL per line. Accepts the batch format too — only what precedes the
    first `|` is read — so the same /tmp/links.txt can be handed to both tools.
    `#` lines and blank lines are notes."""
    out = []
    for line in text.splitlines():
        line = line.split("#", 1)[0] if line.lstrip().startswith("#") else line
        url = line.split("|", 1)[0].strip()
        if url:
            out.append(url)
    return out


def cover_name(n: int, platform: str, url: str) -> str:
    """`03-tiktok-7450382760847346951.jpg` — numbered in batch order, so the
    listing and the files line up, and carrying the post id so a file can be
    traced back to its link without a lookup."""
    ids = re.findall(r"[A-Za-z0-9_-]{6,}", url.rstrip("/").split("?")[0].split("/")[-1])
    tail = ids[-1] if ids else "post"
    return f"{n:02d}-{platform}-{tail}.jpg"


def run(urls, out_dir, fetch, emit=print) -> int:
    """`fetch(url) -> (platform, caption, jpeg bytes)`; injected so the selftest
    can exercise every exit path without the network."""
    if not urls:
        emit("COULD NOT VERIFY — no URLs to fetch. Nothing fetched is not a pass.")
        return 2
    os.makedirs(out_dir, exist_ok=True)
    failed = []
    for n, url in enumerate(urls, 1):
        try:
            platform, caption, raw = fetch(url)
        except (Exception, SystemExit) as exc:          # SystemExit: make-link-pin's own refusals
            failed.append(url)
            emit(f"  {n:2d}  FAILED  {url}\n        {str(exc).splitlines()[0] if str(exc) else type(exc).__name__}")
            continue
        path = os.path.join(out_dir, cover_name(n, platform, url))
        with open(path, "wb") as fh:
            fh.write(raw)
        emit(f"  {n:2d}  {len(raw)//1024:4d} KB  {path}\n        {' '.join((caption or '').split())[:110]}")
    emit(f"\n{len(urls) - len(failed)} of {len(urls)} cover(s) saved to {out_dir}"
         + (f" · {len(failed)} COULD NOT VERIFY" if failed else ""))
    if failed:
        emit("COULD NOT VERIFY — a cover that failed to download is not a cover that showed nothing.")
        return 2
    emit("Now LOOK at each one: a sign, a street name, a landmark. It is one frame, not the video —"
         "\nif it does not settle the place, ask the owner, who can watch it.")
    return 0


def live_fetch():
    mlp = _mlp()

    def fetch(url):
        url = mlp.canonical_url(url)
        plat = mlp.platform_of(url)
        meta = mlp.oembed(url)
        return plat, meta.get("title") or "", mlp.best_thumbnail(meta, plat)
    return fetch


def selftest() -> int:
    import tempfile
    fails, ran = [], []

    def check(name, ok):
        ran.append(name)
        print(f"  {'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            fails.append(name)

    txt = ("# a note\n\nhttps://www.tiktok.com/@a/video/111 | 1.0,2.0 | X | Y\n"
           "https://www.instagram.com/reel/ABCDEF/\n   \n")
    check("reads bare URLs and the batch format alike",
          parse_urls(txt) == ["https://www.tiktok.com/@a/video/111",
                              "https://www.instagram.com/reel/ABCDEF/"])
    check("a file of only notes yields nothing", parse_urls("# x\n\n#y\n") == [])
    check("the filename carries order, platform and post id",
          cover_name(3, "tiktok", "https://www.tiktok.com/@a/video/7450382760847346951")
          == "03-tiktok-7450382760847346951.jpg")
    check("an Instagram reel id survives a trailing slash",
          cover_name(1, "instagram", "https://www.instagram.com/reel/DQ9Db0lCT2r/")
          == "01-instagram-DQ9Db0lCT2r.jpg")

    quiet = lambda *_: None
    ok = lambda url: ("tiktok", "cap", b"\xff\xd8jpeg")

    def boom(url):
        raise SystemExit("COULD NOT VERIFY — private post")
    with tempfile.TemporaryDirectory() as d:
        check("every cover fetched -> exit 0", run(["u1", "u2"], d, ok, quiet) == 0)
        check("the file is actually written", len(os.listdir(d)) == 2)
    with tempfile.TemporaryDirectory() as d:
        mixed = lambda url: boom(url) if url == "bad" else ok(url)
        check("🔴 ONE failure -> exit 2, not 0", run(["good", "bad"], d, mixed, quiet) == 2)
        check("   …and the good one is still saved", len(os.listdir(d)) == 1)
    with tempfile.TemporaryDirectory() as d:
        check("🔴 make-link-pin's SystemExit is caught, not fatal",
              run(["bad"], d, boom, quiet) == 2)
        check("🔴 nothing to fetch -> exit 2 — nothing fetched is not a pass",
              run([], d, ok, quiet) == 2)
    total = len(ran)
    print(f"SELFTEST {'FAILED — ' + str(len(fails)) if fails else 'OK — ' + str(total)}/{total}")
    return 1 if fails else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--urls", help="file of URLs (the batch format is accepted too)")
    ap.add_argument("--url", action="append", default=[], help="a single URL; repeatable")
    ap.add_argument("--out-dir", default="/tmp/covers")
    ap.add_argument("--selftest", action="store_true")
    runstamp.add_out_argument(ap)
    a = ap.parse_args()
    run_ = runstamp.begin(__file__, out_path=a.out)
    try:
        if a.selftest:
            return selftest()
        urls = list(a.url)
        if a.urls:
            with open(a.urls, encoding="utf-8") as fh:
                urls += parse_urls(fh.read())
        return run(urls, a.out_dir, live_fetch())
    finally:
        run_.close()


if __name__ == "__main__":
    sys.exit(main())
