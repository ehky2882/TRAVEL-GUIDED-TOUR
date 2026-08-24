#!/usr/bin/env python3
"""Turn a public TikTok / YouTube post into an Atlas link-pin catalog entry.

A link pin stands for someone else's post. It appears everywhere a tour
appears — map, rails, search, library — and its detail page sends you to the
platform instead of playing anything.

    python3 scripts/make-link-pin.py \
        --url https://www.tiktok.com/@someone/video/123 \
        --lat 40.7727 --lon -73.9930 \
        --maker 00000000-0000-0000-0000-000000000001 \
        --city "New York" --country "United States" \
        --category architecture --tags "Notable Building,Architecture"

Writes the cropped hero next to the script and prints the `Tours.json` entry.

WHAT IT DOES NOT DO, deliberately
---------------------------------
It never downloads the video. TikTok's own API exposes no video-file field and
their terms forbid obtaining one another way, so a link pin links — the post
stays where its creator put it. Only the thumbnail is re-hosted, and only
because TikTok's thumbnail URLs are signed and expire (`x-expires`), so a pin
pointing at one would go blank within days.

NETWORK
-------
Uses `curl`, never `urllib` — urllib fails SSL verification on the owner's Mac,
which is how `check-image-duplicates.py` once printed "OK" having fetched
nothing at all. Any fetch failure exits non-zero and says so.
"""

import argparse
import io
import json
import subprocess
import sys
import uuid

OEMBED = {
    "tiktok": "https://www.tiktok.com/oembed?url=",
    "youtube": "https://www.youtube.com/oembed?format=json&url=",
}

HERO_W, HERO_H = 1200, 900


def platform_of(url: str) -> str:
    """Match the REGISTRABLE domain — the label immediately before the TLD.

    🔴 Not `"tiktok" in labels`. That was the first version and the self-test
    caught it: `tiktok.evil.com` splits to ["tiktok", "evil", "com"] and would
    have passed as TikTok, so anyone could mint a pin that looked official and
    sent people to their own host. Only the second-to-last label decides.
    """
    from urllib.parse import urlparse
    host = (urlparse(url).hostname or "").lower().rstrip(".")
    labels = host.split(".")
    if len(labels) < 2:
        return "other"
    domain = labels[-2]
    if domain == "tiktok":
        return "tiktok"
    if domain in ("youtube", "youtu"):
        return "youtube"
    if domain == "instagram":
        return "instagram"
    return "other"


def curl(url: str, binary: bool = False):
    r = subprocess.run(
        ["curl", "-sSL", "--max-time", "45", "-A",
         "Dozent/1.0 (link-pin tool; +https://dozent.world)", url],
        capture_output=True,
    )
    if r.returncode != 0:
        raise RuntimeError(f"curl failed ({r.returncode}): {r.stderr.decode(errors='replace')[:300]}")
    return r.stdout if binary else r.stdout.decode("utf-8", errors="replace")


def oembed(url: str) -> dict:
    plat = platform_of(url)
    if plat not in OEMBED:
        raise SystemExit(
            f"COULD NOT VERIFY — no supported oEmbed for '{plat}'.\n"
            "TikTok and YouTube work with no key. Instagram's needs a Meta app\n"
            "token and is deliberately out of scope."
        )
    from urllib.parse import quote
    body = curl(OEMBED[plat] + quote(url, safe=""))
    try:
        data = json.loads(body)
    except json.JSONDecodeError:
        raise SystemExit(
            "COULD NOT VERIFY — the platform did not return JSON. This is NOT a\n"
            f"pass; the post may be private, deleted, or region-locked.\n{body[:300]}"
        )
    if not data.get("thumbnail_url"):
        raise SystemExit("COULD NOT VERIFY — no thumbnail in the oEmbed response.")
    return data


def render_hero(raw: bytes) -> bytes:
    """Square-crop the source, then extend to 4:3 behind a blurred copy of
    itself.

    🔴 The square crop is the load-bearing part. `AtlasSpacing.heroAspectRatio`
    is 1.0, so the app displays the MIDDLE SQUARE of a stored 1200x900 image.
    Centre-cropping a 576x1024 vertical thumbnail straight to 4:3 and letting
    the app crop again would show the middle ~42% of the original frame — the
    subject's midriff. Cropping square first and padding sideways means the
    square the app actually shows IS the square that was chosen.
    """
    try:
        from PIL import Image, ImageFilter, ImageOps
    except ImportError:
        raise SystemExit(
            "Pillow is not installed, so the hero cannot be cropped.\n"
            "  pip3 install Pillow\n"
            "Refusing to write an uncropped image — every other hero in the\n"
            "catalog is 1200x900 and one that is not would letterbox on device."
        )

    src = Image.open(io.BytesIO(raw))
    src = ImageOps.exif_transpose(src).convert("RGB")

    side = min(src.size)
    square = ImageOps.fit(src, (side, side), method=Image.LANCZOS, centering=(0.5, 0.5))
    square = square.resize((HERO_H, HERO_H), Image.LANCZOS)

    # The 4:3 surround: the same picture, blown up and blurred, so the pad
    # reads as part of the image rather than as a bar.
    bg = ImageOps.fit(src, (HERO_W, HERO_H), method=Image.LANCZOS, centering=(0.5, 0.5))
    bg = bg.filter(ImageFilter.GaussianBlur(28)).point(lambda v: int(v * 0.55))
    bg.paste(square, ((HERO_W - HERO_H) // 2, 0))

    out = io.BytesIO()
    bg.save(out, "WEBP", quality=82, method=6)
    return out.getvalue()


def slugify(text: str, fallback: str) -> str:
    import re
    s = re.sub(r"[^a-z0-9]+", "-", (text or "").lower()).strip("-")
    s = "-".join(s.split("-")[:6])
    return s or fallback


def build_entry(*, url, meta, slug, maker, lat, lon, city, country,
                category, tags, created_at, image_base) -> dict:
    """Deterministic ids keyed on the source URL, so re-running on the same
    post produces the same entry rather than a duplicate pin."""
    tour_id = str(uuid.uuid5(uuid.NAMESPACE_URL, f"atlas-tour:link:{url}")).upper()
    stop_id = str(uuid.uuid5(uuid.NAMESPACE_URL, f"atlas-stop:link:{url}")).upper()
    author = meta.get("author_name") or ""
    unique = meta.get("author_unique_id")
    handle = f"@{unique}" if unique else author
    caption = (meta.get("title") or "").strip()
    title = caption if len(caption) <= 60 else caption[:57].rstrip() + "…"

    return {
        "id": tour_id,
        "createdAt": created_at,
        "title": title or f"A post by {handle}",
        "shortDescription": f"A post by {handle} on {meta.get('provider_name', 'the web')}.",
        "longDescription": caption or f"A post by {handle}.",
        "makerId": maker,
        "heroImageURL": f"{image_base}/{slug}_hero.webp",
        "additionalImageURLs": None,
        "videoURLs": None,
        "videoRole": None,
        "kind": "link",
        "sourceURL": url,
        "sourceAuthor": handle,
        "stops": [{
            "id": stop_id,
            "order": 0,
            "title": title or f"A post by {handle}",
            "caption": (caption[:140] or f"A post by {handle}."),
            "latitude": lat,
            "longitude": lon,
            # 🔴 Empty audio + zero duration is the representation a fresh
            # maker draft already writes, and it is what makes a link pin safe:
            # every reader goes through URL(string:), which rejects "".
            "audioURL": "",
            "audioDurationSeconds": 0,
            # manual, so ProximityMonitor never registers it — it only ever
            # monitors `.geofenced` stops.
            "triggerMode": "manual",
            "triggerRadiusMeters": 30,
            "imageURL": f"{image_base}/{slug}_hero.webp",
            "transcriptText": None,
        }],
        "introAudioURL": None,
        "totalDurationSeconds": 0,
        "walkingDistanceMeters": None,
        "centroidLatitude": lat,
        "centroidLongitude": lon,
        "city": city,
        "country": country,
        "primaryCategory": category,
        "tags": tags,
        "priceUSD": 0,
    }


# --------------------------------------------------------------------------
# Self-test — offline, so a broken tool is caught without touching a network.
# --------------------------------------------------------------------------
def selftest() -> int:
    fails = []

    def check(name, got, want):
        if got != want:
            fails.append(f"{name}: got {got!r}, want {want!r}")

    check("tiktok host", platform_of("https://www.tiktok.com/@a/video/1"), "tiktok")
    check("tiktok bare", platform_of("https://tiktok.com/@a/video/1"), "tiktok")
    check("youtube", platform_of("https://www.youtube.com/shorts/abc"), "youtube")
    check("youtu.be", platform_of("https://youtu.be/abc"), "youtube")
    check("instagram", platform_of("https://www.instagram.com/reel/x/"), "instagram")
    # A look-alike must NOT match: label equality, not substring.
    check("lookalike", platform_of("https://tiktok.evil.com/@a/video/1"), "other")
    check("notatiktok", platform_of("https://nottiktok.com/x"), "other")
    check("no host", platform_of("not a url"), "other")

    e1 = build_entry(url="https://www.tiktok.com/@a/video/1",
                     meta={"author_name": "A", "author_unique_id": "a",
                           "title": "hello", "provider_name": "TikTok"},
                     slug="s", maker="M", lat=1.0, lon=2.0, city="C",
                     country="X", category="architecture", tags=["T"],
                     created_at="2026-08-24", image_base="https://x/images")
    e2 = build_entry(url="https://www.tiktok.com/@a/video/1",
                     meta={"author_name": "A", "author_unique_id": "a",
                           "title": "hello", "provider_name": "TikTok"},
                     slug="s", maker="M", lat=1.0, lon=2.0, city="C",
                     country="X", category="architecture", tags=["T"],
                     created_at="2026-08-24", image_base="https://x/images")
    check("ids are deterministic", e1["id"], e2["id"])
    check("kind", e1["kind"], "link")
    check("audio empty", e1["stops"][0]["audioURL"], "")
    check("duration zero", e1["stops"][0]["audioDurationSeconds"], 0)
    check("total zero", e1["totalDurationSeconds"], 0)
    check("trigger manual", e1["stops"][0]["triggerMode"], "manual")
    check("credits handle", e1["sourceAuthor"], "@a")

    e3 = build_entry(url="https://www.tiktok.com/@a/video/2",
                     meta={"author_name": "A", "title": "x"}, slug="s",
                     maker="M", lat=1.0, lon=2.0, city=None, country=None,
                     category="architecture", tags=[], created_at="2026-08-24",
                     image_base="https://x/images")
    if e3["id"] == e1["id"]:
        fails.append("different URLs produced the same id")
    check("falls back to author_name", e3["sourceAuthor"], "A")

    long_caption = "w" * 200
    e4 = build_entry(url="https://www.tiktok.com/@a/video/3",
                     meta={"author_name": "A", "title": long_caption},
                     slug="s", maker="M", lat=1.0, lon=2.0, city=None,
                     country=None, category="architecture", tags=[],
                     created_at="2026-08-24", image_base="https://x/images")
    if len(e4["title"]) > 60:
        fails.append(f"title not truncated: {len(e4['title'])}")
    if len(e4["stops"][0]["caption"]) > 140:
        fails.append("caption not truncated")

    check("slugify", slugify("Hello, World! Again", "f"), "hello-world-again")
    check("slugify empty", slugify("!!!", "fallback"), "fallback")

    total = 18
    if fails:
        print(f"SELFTEST FAILED — {len(fails)}/{total}")
        for f in fails:
            print("  ✗", f)
        return 1
    print(f"SELFTEST OK — {total}/{total}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--url", help="Public TikTok or YouTube post URL")
    ap.add_argument("--lat", type=float, help="Where the pin goes")
    ap.add_argument("--lon", type=float)
    ap.add_argument("--maker", help="makerId (UUID) this pin files under")
    ap.add_argument("--city")
    ap.add_argument("--country")
    ap.add_argument("--category", default="architecture")
    ap.add_argument("--tags", default="", help="Comma-separated")
    ap.add_argument("--slug", help="Filename stem; derived from the caption if omitted")
    ap.add_argument("--created", default="", help='ISO "YYYY-MM-DD"; today if omitted')
    ap.add_argument("--image-base",
                    default="https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images")
    ap.add_argument("--out-dir", default=".", help="Where to write the cropped hero")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()

    if a.selftest:
        return selftest()

    missing = [n for n, v in (("--url", a.url), ("--lat", a.lat),
                              ("--lon", a.lon), ("--maker", a.maker)) if v is None]
    if missing:
        ap.error("missing required: " + ", ".join(missing))

    import datetime
    import os

    meta = oembed(a.url)
    slug = a.slug or slugify(meta.get("title", ""), f"post-{platform_of(a.url)}")

    raw = curl(meta["thumbnail_url"], binary=True)
    if len(raw) < 1000:
        raise SystemExit(f"COULD NOT VERIFY — thumbnail came back {len(raw)} bytes.")
    hero = render_hero(raw)

    os.makedirs(a.out_dir, exist_ok=True)
    path = os.path.join(a.out_dir, f"{slug}_hero.webp")
    with open(path, "wb") as fh:
        fh.write(hero)

    entry = build_entry(
        url=a.url, meta=meta, slug=slug, maker=a.maker, lat=a.lat, lon=a.lon,
        city=a.city, country=a.country, category=a.category,
        tags=[t.strip() for t in a.tags.split(",") if t.strip()],
        created_at=a.created or datetime.date.today().isoformat(),
        image_base=a.image_base,
    )

    print(f"\n# Wrote {path} ({len(hero):,} bytes)", file=sys.stderr)
    print(f"# Upload it to gh-pages at  images/{slug}_hero.webp", file=sys.stderr)
    print(f"# Credited to {entry['sourceAuthor']} — check that is right before shipping.\n",
          file=sys.stderr)
    print(json.dumps(entry, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
