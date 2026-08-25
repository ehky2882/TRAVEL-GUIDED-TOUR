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

Writes the cropped hero next to the script and prints the `Tours.json` entry
— under `linkPins`, the top-level array older builds skip, never `tours`.

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
from urllib.parse import urlparse

OEMBED = {
    "tiktok": "https://www.tiktok.com/oembed?url=",
    "youtube": "https://www.youtube.com/oembed?format=json&url=",
}

HERO_W, HERO_H = 1200, 900

# How a pinned creator is named and drawn. The maker line reads
# "TikTok @handle" — the platform first, because that is what tells a reader
# what they are about to get (owner decision 2026-08-24).
PLATFORM_LABEL = {"tiktok": "TikTok", "youtube": "YouTube", "instagram": "Instagram"}

# ⚠️ Tours.json carries only avatarURL + avatarEmoji for a maker, so the emoji
# is the only avatar lever here. oEmbed exposes no creator avatar on any of the
# three platforms. A platform mark also does the badge's job on the profile.
PLATFORM_EMOJI = {"tiktok": "\U0001F3B5", "youtube": "\u25B6\uFE0F", "instagram": "\U0001F4F7"}


# 🔴 A WHITELIST, not a blacklist. The first version listed the tracking
# parameters to strip and immediately missed one: a shared Short arrived as
# `?is=VMBRxPqd_b5LBIJV` while the list only knew YouTube's `si`. Since the
# tour id is uuid5 over sourceURL, an unstripped parameter means the SAME post
# shared twice hashes to two ids and lands as two pins — so the failure is
# silent duplication, and chasing new parameter names is a losing game.
#
# Across all three platforms exactly one query parameter is ever identity:
# YouTube's `v` on a /watch URL. Everything else lives in the path.
IDENTITY_PARAMS = {"youtube": {"v"}}


def normalize_url(url: str) -> str:
    """Keep only the query parameters that identify the post. Pure, so the
    selftest covers it without a network."""
    from urllib.parse import parse_qsl, urlencode, urlunparse
    u = urlparse(url)
    plat = platform_of(url)
    if plat in IDENTITY_PARAMS:
        keep = IDENTITY_PARAMS[plat]
        kept = [(k, v) for k, v in parse_qsl(u.query) if k in keep]
    elif plat == "other":
        kept = parse_qsl(u.query)          # unknown host: change nothing
    else:
        kept = []                          # tiktok / instagram: id is in the path
    return urlunparse((u.scheme, u.netloc, u.path, "", urlencode(kept), ""))


def canonical_url(url: str) -> str:
    """Follow a share link to the real post, then normalise it.

    🔴 A TikTok share link is `tiktok.com/t/XXXX`, which has no `/video/{id}`
    in its path — and that path is exactly what the app parses to build the
    player. Storing the short form produces a pin that validates, uploads, and
    renders a hero with NO PLAYER. Found by feeding the tool a real shared link.
    """
    out = subprocess.run(
        ["curl", "-sSL", "-o", "/dev/null", "--max-time", "45",
         "-A", "Dozent/1.0 (link-pin tool; +https://dozent.world)",
         "-w", "%{url_effective}", url],
        capture_output=True)
    if out.returncode != 0:
        raise SystemExit(f"COULD NOT VERIFY — could not resolve {url}")
    return normalize_url(out.stdout.decode().strip() or url)


def derivable_embed(url: str) -> str | None:
    """Mirror of `LinkSource.embedURL` in Swift — what the app will actually
    build for this URL.

    ⚠️ This exists so the tool REFUSES a pin the app cannot play, rather than
    writing one that looks fine everywhere except on screen. Keep it in step
    with Models/Tour.swift.
    """
    parts = [c for c in urlparse(url).path.split("/") if c]
    plat = platform_of(url)
    if plat == "tiktok":
        if "video" not in parts:
            return None
        i = parts.index("video")
        vid = parts[i + 1] if i + 1 < len(parts) else ""
        return f"https://www.tiktok.com/player/v1/{vid}" if vid.isdigit() else None
    if plat == "youtube":
        from urllib.parse import parse_qs
        v = parse_qs(urlparse(url).query).get("v", [None])[0]
        if not v and "shorts" in parts:
            i = parts.index("shorts")
            v = parts[i + 1] if i + 1 < len(parts) else None
        if not v and "youtu.be" in (urlparse(url).hostname or ""):
            v = parts[0] if parts else None
        return f"https://www.youtube.com/embed/{v}" if v else None
    if plat == "instagram":
        for k in ("p", "reel", "tv"):
            if k in parts:
                i = parts.index(k)
                if i + 1 < len(parts) and parts[i + 1]:
                    return f"https://www.instagram.com/{k}/{parts[i + 1]}/embed"
        return None
    return None


def handle_of(meta: dict, platform: str) -> str:
    """The creator's @handle, which is not where every platform puts it.

    TikTok and Instagram hand back a real username. ⚠️ YouTube's oEmbed gives
    `author_name`, which is a DISPLAY name — using it produced the maker
    "YouTube @Blippi - Educational Videos for Kids". The @handle is in
    `author_url` (youtube.com/@Blippi), so that is preferred when present.
    """
    import re as _re
    uid = (meta.get("author_unique_id") or "").strip()
    if uid:
        return uid.lstrip("@")
    g = _re.search(r"/@([A-Za-z0-9._-]+)", meta.get("author_url") or "")
    if g:
        return g.group(1)
    # ⚠️ Deliberately empty rather than falling back to author_name. That is a
    # DISPLAY name ("Blippi - Educational Videos for Kids"), and prefixing it
    # with @ invents a handle that does not exist. Callers decide what to show.
    return ""


# 🔴 WHICH PLATFORMS GET A REAL PROFILE PICTURE, AND WHY INSTAGRAM DOES NOT.
#
# The maker page renders the avatar at 96pt — 288 physical pixels on a 3x
# screen. Measured against what each platform actually serves:
#
#   YouTube    900x900  (channel page)      -> comfortable
#   TikTok     400x400  (avatarLarger)      -> comfortable
#   Instagram  100x100  (profile_pic_url)   -> visibly soft at 288px
#
# Instagram exposes no `profile_pic_url_hd` in its embed payload — checked,
# it is absent — so 100x100 is the ceiling, not a lazy pick. Rather than have
# one platform always look mushy on the largest surface it appears on,
# Instagram creators keep the platform mark. Owner decision 2026-08-25.
AVATAR_PLATFORMS = {"tiktok", "youtube"}

AVATAR_PX = 320          # >= 288 so 96pt @3x is covered with a little headroom


def avatar_source(platform: str, post_url: str, author_url: str | None) -> str | None:
    """The creator's profile picture, or None when we deliberately don't take one.

    ⚠️ Scraping, and the most brittle thing in this tool: these are internal
    keys in page HTML, not a documented API, and either platform can rename
    them without notice. It returns None rather than raising, because a missing
    avatar must never fail a batch - the maker simply keeps the platform mark.
    """
    import re as _re
    if platform not in AVATAR_PLATFORMS:
        return None
    try:
        if platform == "tiktok":
            html = curl(post_url)
            for pat in (r'"avatarLarger":"(.*?)"',
                        r'"avatarThumb":\{"urlList":\["(.*?)"'):
                g = _re.search(pat, html)
                if g:
                    return g.group(1).replace("\\u002F", "/").replace("\\/", "/")
        elif platform == "youtube" and author_url:
            html = curl(author_url)
            g = (_re.search(r'"avatar":\{"thumbnails":\[\{"url":"(.*?)"', html)
                 or _re.search(r'(https://yt3\.googleusercontent\.com/[A-Za-z0-9_\-=]+)', html))
            if g:
                return g.group(1).replace("\\/", "/")
    except Exception:
        return None                      # never let an avatar break a pin
    return None


def render_avatar(raw: bytes) -> bytes:
    """Centre-square crop to AVATAR_PX WebP. The view clips to a circle, so the
    square just has to be centred - no aspect decision to get wrong."""
    from PIL import Image, ImageOps
    im = ImageOps.exif_transpose(Image.open(io.BytesIO(raw))).convert("RGB")
    w, h = im.size
    side = min(w, h)
    im = im.crop(((w - side) // 2, (h - side) // 2,
                  (w - side) // 2 + side, (h - side) // 2 + side))
    im = im.resize((AVATAR_PX, AVATAR_PX), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "WEBP", quality=88, method=6)
    return buf.getvalue()


def avatar_slug(platform: str, handle: str) -> str:
    import re as _re
    bare = _re.sub(r"[^a-z0-9]+", "-", handle.lstrip("@").lower()).strip("-")
    return f"avatar-{platform}-{bare}"


def maker_for(platform: str, handle: str, author_url: str | None,
              avatar_url: str | None = None) -> dict:
    """A pinned creator IS a maker (owner decision 2026-08-24: they get a page
    and they count).

    🔴 The id is uuid5 over the platform AND the lowercased handle, so the same
    creator always lands on the same maker row no matter how many of their
    posts get pinned, and re-running the tool never mints a duplicate. Handles
    are case-insensitive on all three platforms, so the case must be normalised
    before hashing or @NASA and @nasa become two people.
    """
    label = PLATFORM_LABEL.get(platform, platform.title())
    bare = handle.lstrip("@")
    handled = bool(handle.startswith("@")) or " " not in bare
    key = f"atlas-maker:{platform}:@{bare.lower()}"
    return {
        "id": str(uuid.uuid5(uuid.NAMESPACE_URL, key)).upper(),
        # "@name" only when it really is a handle; a display name is shown as
        # given, so we never invent an @ that leads nowhere.
        "displayName": f"{label} @{bare}" if handled else f"{label} — {bare}",
        "avatarURL": avatar_url,
        # The platform mark stays as the FALLBACK even when a photo is set:
        # MakerAvatarView resolves photo -> emoji -> initials, so a photo that
        # ever fails to load degrades to the mark rather than to a monogram.
        "avatarEmoji": PLATFORM_EMOJI.get(platform),
        # Says plainly that we host none of it — this is the line a reader sees
        # on the creator's page, and it should not imply they signed up.
        "bio": f"{label} creator. These pins link to their posts; "
               f"Dozent hosts none of this content.",
        "websiteURL": author_url,
    }



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
    if plat == "instagram":
        # Instagram's oEmbed needs a Meta app token; its embed page does not.
        return instagram_meta(url)
    if plat not in OEMBED:
        raise SystemExit(
            f"COULD NOT VERIFY — unsupported link platform '{plat}'.\n"
            "TikTok, YouTube and Instagram are supported. Anything else has no\n"
            "embeddable player we can derive, so it cannot become a link pin."
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


def instagram_meta(url: str) -> dict:
    """Instagram's oEmbed needs a Meta app token, but its **embed page** is
    public and carries everything we need in a JSON blob.

    ⚠️ This is scraping, and it is the fragile part of this tool: the keys
    below are Instagram's internals and can be renamed without notice. It
    raises rather than guessing, so a batch fails loudly instead of writing
    pins with missing captions.
    """
    import re as _re
    parts = [c for c in urlparse(url).path.split("/") if c]
    code = None
    for i, c in enumerate(parts):
        if c in ("p", "reel", "tv") and i + 1 < len(parts):
            code = parts[i + 1]
            break
    if not code:
        raise SystemExit(f"COULD NOT VERIFY — not an Instagram post/reel URL: {url}")

    html = curl(f"https://www.instagram.com/{parts[parts.index(code) - 1]}/{code}/embed")

    def grab(pat):
        g = _re.search(pat, html)
        return g.group(1) if g else None

    handle = grab(r'\\"username\\":\\"(.*?)\\"')
    thumb = grab(r'\\"display_url\\":\\"(.*?)\\"')
    caption = grab(r'\\"edge_media_to_caption\\":\{\\"edges\\":\[\{\\"node\\":\{\\"text\\":\\"(.*?)\\"\}')
    if not handle or not thumb:
        raise SystemExit(
            "COULD NOT VERIFY — Instagram's embed did not yield a handle and a\n"
            "thumbnail. The post may be private or deleted, or Instagram may have\n"
            f"renamed its internal keys. URL: {url}"
        )

    def unesc(x):
        """⚠️ The blob is DOUBLE-escaped — JSON embedded in JSON inside a
        script tag — so one decode pass is not enough: it leaves `\\/` in the
        URL (curl then rejects it as a bad port) and `\\ud83e` in the caption.
        Two passes land on real text.

        `unicode_escape` looks like the obvious tool and is wrong: it mangles
        every non-ASCII character and turns a literal newline escape into the
        letter n, which reached the slug as `pls-pls-pls-ud83e-udef6-n`.
        """
        if not x:
            return ""
        for _ in range(2):
            try:
                nxt = json.loads(f'"{x}"')
            except json.JSONDecodeError:
                break
            if nxt == x:
                break
            x = nxt
        return x.replace("\\/", "/")

    return {
        "title": unesc(caption).strip(),
        "author_name": handle,
        "author_unique_id": handle,
        "author_url": f"https://www.instagram.com/{handle}/",
        "provider_name": "Instagram",
        "thumbnail_url": unesc(thumb),
    }


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
    # One handle rule for the whole tool: the maker line and the credit line
    # must name the same person. Reading author_name here is what produced
    # `sourceAuthor: "Blippi - Educational Videos for Kids"` beside the maker
    # `YouTube @Blippi`.
    h = handle_of(meta, platform_of(url))
    handle = f"@{h}" if h else (meta.get("author_name") or "").strip()

    # 🔴 Flatten newlines BEFORE truncating. A caption routinely spans lines,
    # and a title carrying one reaches the catalogue, the share card and the
    # lock screen — the same defect the upload wizard fixed for typed titles.
    caption = " ".join((meta.get("title") or "").split())
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

    # --- the creator's handle -------------------------------------------
    check("handle: tiktok unique id",
          handle_of({"author_unique_id": "tiktok", "author_name": "TikTok"}, "tiktok"),
          "tiktok")
    # 🔴 YouTube's author_name is a DISPLAY name; the handle is in author_url.
    check("handle: youtube prefers author_url",
          handle_of({"author_name": "Blippi - Educational Videos for Kids",
                     "author_url": "https://www.youtube.com/@Blippi"}, "youtube"),
          "Blippi")
    # ⚠️ Empty, not the display name — prefixing @ to it invents a handle.
    check("handle: no handle available",
          handle_of({"author_name": "Some Channel"}, "youtube"), "")

    # --- one creator, one maker row -------------------------------------
    m_lower = maker_for("tiktok", "@nasa", None)
    m_upper = maker_for("tiktok", "NASA", None)
    check("maker id ignores handle case", m_lower["id"], m_upper["id"])
    check("maker display name", m_lower["displayName"], "TikTok @nasa")
    if maker_for("youtube", "@nasa", None)["id"] == m_lower["id"]:
        fails.append("same handle on two platforms collapsed to one maker")

    # --- batch parsing ---------------------------------------------------
    rows = parse_batch(
        "# a note\n"
        "\n"
        "https://a.test/1 | 1.5,-2.5 | Rome | Italy\n"
        "https://a.test/2\n")
    check("batch skips notes and blanks", len(rows), 2)
    check("batch reads coords", (rows[0]["lat"], rows[0]["lon"]), (1.5, -2.5))
    check("batch reads city", rows[0]["city"], "Rome")
    check("batch leaves coords None", rows[1]["lat"], None)

    # --- canonical URLs --------------------------------------------------
    # 🔴 TikTok stamps a fresh _t on every share. Without stripping it the same
    # video shared twice hashes to two ids and lands as two pins.
    check("strips tiktok share params",
          normalize_url("https://www.tiktok.com/@a/video/123?_r=1&_t=ZP-99AI"),
          "https://www.tiktok.com/@a/video/123")
    check("keeps the youtube id",
          normalize_url("https://www.youtube.com/watch?v=abc123&si=xyz&feature=share"),
          "https://www.youtube.com/watch?v=abc123")
    check("strips instagram igsh",
          normalize_url("https://www.instagram.com/reel/ABC/?igsh=zzz"),
          "https://www.instagram.com/reel/ABC/")
    # 🔴 The one that caught the whitelist out: a real shared Short arrived as
    # `?is=...`, which no blacklist knew about.
    check("strips an unknown youtube share param",
          normalize_url("https://www.youtube.com/shorts/hSbYvigS0Ic?is=VMBRxPqd_b5LBIJV"),
          "https://www.youtube.com/shorts/hSbYvigS0Ic")
    check("leaves an unknown host's query alone",
          normalize_url("https://example.test/x?a=1"), "https://example.test/x?a=1")

    # --- creator avatars --------------------------------------------------
    # 🔴 Instagram is deliberately excluded: its embed exposes only 100x100
    # (no profile_pic_url_hd), which is soft at the 288px the 96pt maker page
    # needs. A platform mark beats a mushy photo.
    check("instagram takes no photo", avatar_source("instagram", "u", "a"), None)
    check("unknown platform takes no photo", avatar_source("other", "u", "a"), None)
    check("avatar slug is stable and filename-safe",
          avatar_slug("tiktok", "@Natural.History_Museum"),
          "avatar-tiktok-natural-history-museum")
    check("avatar slug ignores handle case",
          avatar_slug("youtube", "@NASA"), avatar_slug("youtube", "nasa"))

    # A maker with a photo keeps the platform mark as its FALLBACK, so a photo
    # that fails to load degrades to the mark rather than to a monogram.
    mk = maker_for("tiktok", "@x", None, "https://img.test/a.webp")
    check("photo is set", mk["avatarURL"], "https://img.test/a.webp")
    check("mark survives as fallback", mk["avatarEmoji"], PLATFORM_EMOJI["tiktok"])
    check("no photo leaves avatarURL nil", maker_for("instagram", "@y", None)["avatarURL"], None)

    # --- refuse a pin the app cannot play --------------------------------
    # A share link has no /video/{id}, which is what the app parses.
    check("short tiktok link yields no player",
          derivable_embed("https://www.tiktok.com/t/ZP87xkgbd/"), None)
    check("canonical tiktok link yields a player",
          derivable_embed("https://www.tiktok.com/@a/video/7673253792879611166"),
          "https://www.tiktok.com/player/v1/7673253792879611166")
    check("youtube shorts yields a player",
          derivable_embed("https://www.youtube.com/shorts/abc"),
          "https://www.youtube.com/embed/abc")
    check("instagram reel yields a player",
          derivable_embed("https://www.instagram.com/x/reel/ABC/"),
          "https://www.instagram.com/reel/ABC/embed")

    total = 43
    if fails:
        print(f"SELFTEST FAILED — {len(fails)}/{total}")
        for f in fails:
            print("  ✗", f)
        return 1
    print(f"SELFTEST OK — {total}/{total}")
    return 0


def make_one(*, url, lat, lon, city, country, category, tags, slug,
             created_at, image_base, out_dir) -> tuple[dict, dict, str, str | None]:
    """URL -> (maker, tour, hero_path, avatar_path|None). One post, everything derived.

    Shared by the single-link and batch paths so the two cannot drift.
    """
    import os
    url = canonical_url(url)
    if not derivable_embed(url):
        raise SystemExit(
            f"COULD NOT VERIFY — no player can be derived from {url}\n"
            "  The app builds its embed from the URL path, so a pin with a URL\n"
            "  it cannot parse would render a hero and never play.")
    plat = platform_of(url)
    meta = oembed(url)
    handle = handle_of(meta, plat)
    if not handle:
        raise SystemExit(f"COULD NOT VERIFY — no creator handle for {url}")

    # The avatar belongs to the CREATOR, not the post — one fetch per creator
    # per run, and skipped entirely for platforms we do not take photos from.
    av_path = av_url = None
    src = avatar_source(plat, url, meta.get("author_url"))
    if src:
        try:
            raw_av = curl(src, binary=True)
            if len(raw_av) > 500:
                a_slug = avatar_slug(plat, handle)
                os.makedirs(out_dir, exist_ok=True)
                av_path = os.path.join(out_dir, f"{a_slug}.webp")
                with open(av_path, "wb") as fh:
                    fh.write(render_avatar(raw_av))
                av_url = f"{image_base}/{a_slug}.webp"
        except Exception:
            av_path = av_url = None      # a bad avatar must never fail the pin

    maker = maker_for(plat, handle, meta.get("author_url"), av_url)
    slug = slug or slugify(meta.get("title", ""), f"post-{plat}")

    raw = curl(meta["thumbnail_url"], binary=True)
    if len(raw) < 1000:
        raise SystemExit(f"COULD NOT VERIFY — thumbnail came back {len(raw)} bytes for {url}.")
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, f"{slug}_hero.webp")
    with open(path, "wb") as fh:
        fh.write(render_hero(raw))

    tour = build_entry(url=url, meta=meta, slug=slug, maker=maker["id"],
                       lat=lat, lon=lon, city=city, country=country,
                       category=category, tags=tags, created_at=created_at,
                       image_base=image_base)
    return maker, tour, path, av_path


def parse_batch(text: str) -> list[dict]:
    """One line per pin:  <url> | <lat>,<lon> | <city> | <country>

    Everything after the URL is optional; a line that is just a URL comes back
    with lat/lon None so the caller can ask where it belongs. Blank lines and
    lines starting with # are ignored, so a batch file can carry notes.
    """
    rows = []
    for n, raw in enumerate(text.splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.split("|")]
        url = parts[0]
        lat = lon = None
        if len(parts) > 1 and parts[1]:
            try:
                lat, lon = [float(x) for x in parts[1].split(",")]
            except ValueError:
                raise SystemExit(
                    f"line {n}: could not read '{parts[1]}' as 'lat,lon'.\n  {line}")
        rows.append({"line": n, "url": url, "lat": lat, "lon": lon,
                     "city": parts[2] if len(parts) > 2 and parts[2] else None,
                     "country": parts[3] if len(parts) > 3 and parts[3] else None})
    return rows


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--url", help="Public TikTok, YouTube or Instagram post URL")
    ap.add_argument("--batch", help="File of '<url> | <lat>,<lon> | <city> | <country>' lines")
    ap.add_argument("--lat", type=float, help="Where the pin goes")
    ap.add_argument("--lon", type=float)
    ap.add_argument("--maker", help="(ignored) a pinned creator now gets their own maker row")
    ap.add_argument("--city")
    ap.add_argument("--country")
    ap.add_argument("--category", default="architecture")
    ap.add_argument("--tags", default="", help="Comma-separated")
    ap.add_argument("--slug", help="Filename stem; derived from the caption if omitted")
    ap.add_argument("--created", default="", help='ISO "YYYY-MM-DD"; today if omitted')
    ap.add_argument("--image-base",
                    default="https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images")
    ap.add_argument("--out-dir", default=".", help="Where to write the cropped heroes")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()

    if a.selftest:
        return selftest()

    import datetime
    created = a.created or datetime.date.today().isoformat()
    tags = [t.strip() for t in a.tags.split(",") if t.strip()]

    if not a.url and not a.batch:
        ap.error("give either --url or --batch")

    rows = []
    if a.batch:
        with open(a.batch) as fh:
            rows = parse_batch(fh.read())
        # 🔴 Refuse the whole batch when any line lacks a coordinate. A link pin
        # with no location is the one defect nothing downstream catches: it
        # validates, it uploads, and it sits in the ocean off West Africa.
        missing = [r for r in rows if r["lat"] is None]
        if missing:
            sys.stderr.write(
                f"{len(missing)} of {len(rows)} lines have no 'lat,lon'. "
                "Nothing was written.\nAdd a coordinate to each:\n")
            for r in missing:
                sys.stderr.write(f"  line {r['line']}: {r['url']}\n")
            return 1
    else:
        if a.lat is None or a.lon is None:
            ap.error("missing required: --lat, --lon")
        rows = [{"line": 1, "url": a.url, "lat": a.lat, "lon": a.lon,
                 "city": a.city, "country": a.country}]

    makers, tours, paths, failures = {}, [], [], []
    for r in rows:
        try:
            maker, tour, path, av_path = make_one(
                url=r["url"], lat=r["lat"], lon=r["lon"],
                city=r["city"] or a.city, country=r["country"] or a.country,
                category=a.category, tags=tags,
                slug=a.slug if len(rows) == 1 else None,
                created_at=created, image_base=a.image_base, out_dir=a.out_dir)
        except SystemExit as e:                       # one bad link must not
            failures.append((r["line"], r["url"], str(e)))   # lose the rest
            continue
        # Same creator across several links collapses to one maker row.
        makers[maker["id"]] = maker
        tours.append(tour)
        paths.append(path)
        if av_path:
            paths.append(av_path)

    for line, url, why in failures:
        sys.stderr.write(f"\n# SKIPPED line {line}: {url}\n#   {why}\n")

    sys.stderr.write(f"\n# {len(tours)} pin(s), {len(makers)} creator(s), "
                     f"{len(failures)} skipped\n")
    for p_ in paths:
        sys.stderr.write(f"#   hero {p_}\n")
    sys.stderr.write("# Upload the heroes to gh-pages under images/ before merging.\n")
    sys.stderr.write("# 🔴 The pins below go in Tours.json's top-level `linkPins` array,\n"
                     "#    NEVER inside `tours`: a build predating TourKind.link throws on\n"
                     "#    an unknown `kind` and loses the WHOLE catalog decode, silently.\n")
    for m in makers.values():
        sys.stderr.write(f"#   creator: {m['displayName']}\n")
    sys.stderr.write("\n")

    # Emitted under `linkPins`, not `tours`, so pasting this straight into
    # Tours.json puts the pins where every older build will skip them. See
    # TRAVEL GUIDED TOUR/Data/ToursData.swift for why that matters.
    print(json.dumps({"makers": list(makers.values()), "linkPins": tours},
                     indent=2, ensure_ascii=False))
    return 1 if failures and not tours else 0


if __name__ == "__main__":
    sys.exit(main())
