#!/usr/bin/env python3
"""
check-image-duplicates.py — catch images staged under the wrong tour.

WHY THIS EXISTS
---------------
Twice during the Madrid launch the same image shipped under two different
filenames, and both slipped through review:

  * museo-thyssen-bornemisza_hero.webp was byte-identical to
    museo-reina-sofia_hero.webp — the staging commit re-used the image decoded
    40 seconds earlier, so the owner-supplied Thyssen photo was never written.
    Two tours (and one walk gallery) showed the wrong building for a month.
  * estacion-de-atocha_6.webp and _7.webp were identical — one dead swipe.

Neither is detectable from Tours.json alone: the URLs are distinct and every
one of them returns HTTP 200. Only the *bytes* differ, so catching this class
of bug means hashing the actual files.

WHAT IT DOES
------------
Downloads every image the catalog references, groups them by SHA-256, and
classifies each group of identical files:

  ERROR  two gallery slides of one tour are identical — a dead swipe
         (estacion-de-atocha_6 == _7)
  ERROR  two different tours share an image — the Thyssen/Reina Sofía bug, OR
         one photo that genuinely shows two adjacent landmarks (Millennium
         Bridge and St Paul's). No script can tell those apart, so this is a
         flag for human eyes, not an assertion of wrongness.
  INFO   a multi-stop walk reusing a single-stop tour's image, or a tour's hero
         also appearing in its own gallery. Both are documented conventions and
         never fail the run.

Exit codes: 0 = no errors (INFO reuse is fine), 1 = duplicates that look wrong,
2 = file/network error.

LINK PINS
---------
Link pins do NOT live in the `tours` array — they travel in a sibling `linkPins`
array, because one unfamiliar `kind` inside `tours` fails the whole catalog
decode on every build shipped before TourKind.link (PR #597). This script read
only `tours` from the day it was written until 2026-08-30, so for five days
`--all` reported success over a catalog it was not fully checking: every one of
the 244 link-pin heroes was invisible to it. Six link-pin batches worked around
it by hand. `--all` now covers both; `--pins` scopes to link pins alone.

SCOPES
------
    --maker <CODE>   tours by that maker only. Matches displayName as a
                     substring, and pinned creators' handles collide with city
                     codes (STO matches @urbanstoriesyt), so this deliberately
                     does NOT include link pins.
    --pins           link pins only — the right scope when staging a batch.
                     Combine with --maker <handle> for one creator.
    --all            everything: tours AND link pins.

USAGE
-----
    python3 scripts/check-image-duplicates.py --maker MAD    # one city (fast)
    python3 scripts/check-image-duplicates.py --pins         # all link pins
    python3 scripts/check-image-duplicates.py --pins --maker thedesigndetourist
    python3 scripts/check-image-duplicates.py --all          # everything (slow)
    python3 scripts/check-image-duplicates.py --selftest     # logic only, no network

Run it with --maker <CODE> when staging a new city's images, or --pins when
staging a link-pin batch — that is when this bug class appears, and it keeps the
download to one batch instead of thousands of files. Downloads are cached under
.cache/image-dupes/ so re-runs are cheap.

Places are deliberately out of scope: a place hero is allowed to be a member's
own hero at the SAME url (Legion of Honor, Hotel Casa del Mar), which produces
no group at all, and nothing else references a place image.
"""
import argparse
import collections
import hashlib
import io
import subprocess
import json
import os
import re
import sys
import urllib.request

try:
    from PIL import Image
except ImportError:          # perceptual checking is skipped, and SAID so
    Image = None
from concurrent.futures import ThreadPoolExecutor

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOURS_JSON = os.path.join(REPO, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")
PHASH_TOLERANCE = 12  # bits of a 256-bit average hash - deliberately loose:
                      # it only proposes candidates, THUMB_TOLERANCE decides
THUMB_TOLERANCE = 8.0 # mean 0-255 difference; same picture scores under 1
CACHE_DIR = os.path.join(REPO, ".cache", "image-dupes")
UA = "AtlasTourBot/1.0 (edward.yung@gmail.com) duplicate-image check"

# Trailing role suffix on an image filename: _hero, _2.._99, _stop3, _tiles, ...
# Stripping it yields the "asset slug" that ties an image back to its tour.
# Applied twice so compound roles collapse too: the-ancient-city_stop0_hero
# -> the-ancient-city (walk stop images sometimes carry both markers).
_ROLE_SUFFIX = re.compile(r"_(?:hero|stop\d+|\d+|[a-z]+)$")


def asset_slug(url):
    """images/museo-del-prado_hero.webp -> museo-del-prado"""
    stem = os.path.splitext(os.path.basename(url))[0]
    for _ in range(2):
        stripped = _ROLE_SUFFIX.sub("", stem)
        if stripped == stem:
            break
        stem = stripped
    return stem


def is_hero(url):
    return os.path.splitext(os.path.basename(url))[0].endswith("_hero")


def tour_slug(tour):
    """The slug a tour's assets are named after, derived from its audio URL.

    Singles:    audio/museo-del-prado.mp3        -> museo-del-prado
    Walk stops: audio/madrid-retiro_stop3.mp3    -> madrid-retiro

    A link pin hosts no audio at all — every one carries audioURL "" — so the
    slug comes from its hero filename instead. Without this fallback all 244
    pins collapse onto one empty slug and the classifier cannot tell them apart.
    """
    stops = tour.get("stops") or []
    src = (stops[0].get("audioURL") if stops else None) or tour.get("introAudioURL") or ""
    stem = os.path.splitext(os.path.basename(src))[0]
    if not stem:
        return asset_slug(tour.get("heroImageURL") or "")
    return re.sub(r"_stop\d+$", "", stem)


def entries_in_scope(catalog, scope):
    """The catalog entries a given scope covers.

    `tours` and `linkPins` are two top-level arrays (see LINK PINS above), so
    "the whole catalog" has to read both or it silently checks a subset.
    """
    if scope == "pins":
        return list(catalog.get("linkPins") or [])
    if scope == "all":
        return list(catalog["tours"]) + list(catalog.get("linkPins") or [])
    return list(catalog["tours"])


def build_index(catalog, maker_code=None, scope="tours"):
    """-> (urls, slug_kind, walk_stop_urls) for the selected entries.

    walk_stop_urls are images used as a *stop* image of a multi-stop walk.
    That is the documented reuse slot — walk stops reuse imagery that already
    exists for the single-stop tour of the same landmark — and it is what makes
    a shared file expected rather than suspicious. Deliberately narrower than
    "any image on a walk": a walk's own gallery sharing bytes with a single-stop
    tour's hero is exactly the Thyssen bug, and must still be caught.
    """
    makers = {m["id"]: m for m in catalog["makers"]}
    slug_kind, urls, walk_stop_urls = {}, set(), set()

    for tour in entries_in_scope(catalog, scope):
        maker = makers.get(tour.get("makerId")) or {}
        if maker_code and maker_code.upper() not in maker.get("displayName", "").upper():
            continue
        slug_kind[tour_slug(tour)] = tour.get("kind", "single")
        for url in [tour.get("heroImageURL")] + (tour.get("additionalImageURLs") or []):
            if url:
                urls.add(url)
        for stop in tour.get("stops") or []:
            if stop.get("imageURL"):
                urls.add(stop["imageURL"])
                if tour.get("kind") == "multiStop":
                    walk_stop_urls.add(stop["imageURL"])
    return sorted(urls), slug_kind, walk_stop_urls


def thumbnail(data):
    """A 32x32 greyscale thumbnail, kept so a candidate pair can be CONFIRMED.

    The average hash below is a cheap way to find candidates, but on its own it
    is far too eager: it clustered the Empire State Building with the Pincio
    and a Naoshima sculpture purely because their tones are similar. Comparing
    the actual thumbnails separates them cleanly - identical pictures score
    under 1, genuinely different ones score 50 and up.
    """
    if Image is None:
        return None
    try:
        return Image.open(io.BytesIO(data)).convert("L").resize((32, 32)).tobytes().hex()
    except Exception:
        return None


def thumb_distance(hex_a, hex_b):
    a, b = bytes.fromhex(hex_a), bytes.fromhex(hex_b)
    return sum(abs(x - y) for x, y in zip(a, b)) / len(a)


def perceptual_hash(data):
    """A 256-bit average hash of the picture's CONTENT.

    The sha256 below compares BYTES, which is blind to the same photograph
    saved twice in two formats: a JPEG and a WebP of one picture share no
    bytes at all. Milan shipped exactly that - three tours whose carousels
    showed every photo twice, because the drop carried a .jpg and a .webp
    copy of each and both were wired in. The byte check passed them happily.
    """
    if Image is None:
        return None
    try:
        px = list(Image.open(io.BytesIO(data)).convert("L").resize((16, 16)).tobytes())
    except Exception:
        return None
    avg = sum(px) / len(px)
    return "".join("1" if v > avg else "0" for v in px)


def hamming(a, b):
    return sum(1 for x, y in zip(a, b) if x != y)


def fetch_hash(url):
    os.makedirs(CACHE_DIR, exist_ok=True)
    cached = os.path.join(CACHE_DIR, hashlib.sha256(url.encode()).hexdigest())
    if os.path.exists(cached):
        with open(cached) as fh:
            parts = fh.read().strip().split()
        if len(parts) == 3 or Image is None:
            return (url, parts[0],
                    (parts[1] if len(parts) > 1 else None),
                    (parts[2] if len(parts) > 2 else None), None)
        # cached before perceptual hashing existed - refetch to fill it in
    try:
        # curl, not urllib: urllib fails SSL verification on the owner's Mac,
        # which is how this script once reported "OK" having fetched nothing.
        proc = subprocess.run(["curl", "-sL", "--max-time", "90", "-A", UA, url],
                              capture_output=True, timeout=120)
        data = proc.stdout
        if proc.returncode != 0 or not data:
            return url, None, None, None, f"curl exit {proc.returncode}, {len(data)} bytes"
    except Exception as exc:
        return url, None, None, None, str(exc)
    digest = hashlib.sha256(data).hexdigest()
    ph = perceptual_hash(data)
    th = thumbnail(data)
    with open(cached, "w") as fh:
        fh.write(" ".join(x for x in (digest, ph, th) if x))
    return url, digest, ph, th, None


def classify(group, slug_kind, walk_stop_urls=frozenset()):
    """Classify one set of byte-identical URLs -> ('error'|'info', reason)."""
    slugs = [asset_slug(u) for u in group]

    if any(u in walk_stop_urls for u in group):
        return "info", "image also serves a multi-stop walk's stop (expected convention)"

    if len(set(slugs)) == 1:
        # All one tour's own assets. A hero that repeats one of the tour's own
        # gallery/stop images is a deliberate pick, not a mistake. Two gallery
        # slides that are identical is a dead swipe.
        if any(is_hero(u) for u in group):
            return "info", "tour's hero also appears in its own gallery (deliberate pick)"
        return "error", "same tour shows the same image twice in its gallery — one is a dead swipe"

    kinds = [slug_kind.get(s, "single") for s in slugs]
    if any(k == "multiStop" for k in kinds):
        return "info", "multi-stop walk reusing a single-stop image (expected convention)"

    if any(k == "link" for k in kinds):
        # A link pin re-hosts its own post's thumbnail and nothing else. Two
        # pins can legitimately be the same clip cross-posted to two platforms
        # (the Zacherlhaus case) — but those are two separate downloads, so
        # they are never byte-identical; they surface perceptually instead.
        # Byte-identical means one hero was written twice from one decode,
        # which is the Thyssen bug wearing a link pin's clothes.
        return "error", "a link pin shares bytes with another entry — a hero was written twice from one decode"

    # Distinct single-stop tours sharing bytes. Sometimes legitimate — one photo
    # can genuinely show two adjacent landmarks (Millennium Bridge and St Paul's).
    # Sometimes the Thyssen bug. A script cannot tell them apart; flag for eyes.
    return "error", "two tours share an identical image — confirm it depicts both, else one is mis-staged"


def report(groups, slug_kind, walk_stop_urls=frozenset()):
    errors = 0
    for digest, group in sorted(groups.items()):
        if len(group) < 2:
            continue
        level, reason = classify(sorted(group), slug_kind, walk_stop_urls)
        if level == "error":
            errors += 1
        print(f"{level.upper():5}  {reason}")
        for url in sorted(group):
            print(f"         {os.path.basename(url)}")
        print(f"         sha256 {digest[:16]}…")
        print()
    return errors


def report_perceptual(phashes, byte_groups, thumbs):
    """Same picture, different file. Byte-identical sets are already reported."""
    if not phashes:
        return 0
    seen_together = set()
    for g in byte_groups.values():
        for a in g:
            for b in g:
                seen_together.add((a, b))
    items = sorted(phashes.items())
    clusters, used = [], set()
    for i, (ua, ha) in enumerate(items):
        if ua in used:
            continue
        grp = [ua]
        for ub, hb in items[i + 1:]:
            if ub in used or hamming(ha, hb) > PHASH_TOLERANCE:
                continue
            # CONFIRM against the real thumbnails - the hash only nominates
            if ua in thumbs and ub in thumbs:
                if thumb_distance(thumbs[ua], thumbs[ub]) > THUMB_TOLERANCE:
                    continue
            grp.append(ub)
            used.add(ub)
        if len(grp) > 1:
            used.add(ua)
            clusters.append(grp)

    errors = 0
    for grp in clusters:
        if all((a, b) in seen_together for a in grp for b in grp):
            continue                      # already reported as byte-identical
        by_tour = collections.defaultdict(list)
        for u in grp:
            by_tour[tour_slug_of(u)].append(u)
        same_tour = [v for v in by_tour.values() if len(v) > 1]
        if same_tour:
            errors += 1
            print("ERROR  same picture appears more than once in ONE tour's gallery —")
            print("       the carousel shows a dead swipe (often a .jpg and .webp twin)")
            for u in grp:
                print(f"         {u}")
            print()
        else:
            print("INFO   visually identical across tours (different files):")
            for u in grp:
                print(f"         {u}")
            print()
    return errors


def tour_slug_of(url):
    base = os.path.basename(url)
    base = re.sub(r"\.(webp|jpg|jpeg|png)$", "", base, flags=re.I)
    return re.sub(r"_(hero|\d+)$", "", base)


def _selftest_perceptual():
    """The confirmation step is what stops the checker crying wolf."""
    same = ("00" * 1024, "01" * 1024)          # near-identical thumbnails
    diff = ("00" * 1024, "ff" * 1024)          # nothing alike
    ok = True
    if not thumb_distance(*same) <= THUMB_TOLERANCE:
        print("  FAIL identical thumbnails should confirm"); ok = False
    if not thumb_distance(*diff) > THUMB_TOLERANCE:
        print("  FAIL opposite thumbnails should be rejected"); ok = False
    if hamming("0000", "0011") != 2:
        print("  FAIL hamming"); ok = False
    print("  PASS  perceptual confirmation" if ok else "  FAIL  perceptual confirmation")
    return ok


def selftest():
    """Exercise the classification rules on the two real bugs + the 3 real
    intentional reuses from the Madrid batch. No network."""
    slug_kind = {
        "museo-thyssen-bornemisza": "single",
        "museo-reina-sofia": "single",
        "estacion-de-atocha": "single",
        "cuesta-de-moyano": "single",
        "la-rosaleda": "single",
        "circulo-de-bellas-artes": "single",
        "madrid-retiro": "multiStop",
        "madrid-austrias": "multiStop",
        "after-the-fire-wrens-city": "multiStop",
        "the-ancient-city": "multiStop",
    }
    cases = [
        # the two real Madrid bugs
        (["museo-thyssen-bornemisza_hero.webp", "museo-reina-sofia_hero.webp"], "error"),
        (["estacion-de-atocha_6.webp", "estacion-de-atocha_7.webp"], "error"),
        # the three real Madrid intentional reuses
        (["cuesta-de-moyano_hero.webp", "madrid-retiro_stop5.webp"], "info"),
        (["la-rosaleda_hero.webp", "madrid-retiro_stop4.webp"], "info"),
        (["circulo-de-bellas-artes_hero.webp", "madrid-austrias_hero.webp"], "info"),
        # a walk hero picked from its own stop images — deliberate, not a bug
        (["after-the-fire-wrens-city_hero.webp", "after-the-fire-wrens-city_stop5.webp"], "info"),
        # compound _stopN_hero role must still resolve to the walk's slug
        (["the-ancient-city_stop0_hero.webp", "the-ancient-city_stop5_2.webp"], "info"),
    ]
    # A file named after a landmark, used as a walk's stop image, shares bytes
    # with that landmark's own gallery slide. Expected — but only reachable via
    # walk_stop_urls, since "ponte-santangelo" is a stop, not a tour slug.
    walk_stops = {"ponte-santangelo_hero.webp"}
    cases.append((["castel-santangelo_3.webp", "ponte-santangelo_hero.webp"], "info"))
    # Link pins: two pins' heroes sharing bytes means one was written twice.
    slug_kind["papaya-king-thedesigndetourist"] = "link"
    slug_kind["shun-hing-restaurant-thedesigndetourist"] = "link"
    cases.append((["papaya-king-thedesigndetourist_hero.webp",
                   "shun-hing-restaurant-thedesigndetourist_hero.webp"], "error"))
    # A pin sharing bytes with an Atlas tour's hero is the same mis-stage.
    cases.append((["papaya-king-thedesigndetourist_hero.webp",
                   "museo-reina-sofia_hero.webp"], "error"))
    failures = 0
    for group, expected in cases:
        got, reason = classify(group, slug_kind, walk_stops if "ponte-santangelo_hero.webp" in group else frozenset())
        ok = got == expected
        failures += 0 if ok else 1
        print(f"  {'PASS' if ok else 'FAIL'}  expected {expected:5} got {got:5}  {' == '.join(group)}")
        if not ok:
            print(f"        reason: {reason}")
    print()
    if not _selftest_perceptual():
        failures += 1
    if not _selftest_scope():
        failures += 1
    print("selftest OK" if not failures else f"selftest FAILED ({failures})")
    return 0 if not failures else 1


def _selftest_scope():
    """Link pins live in a sibling array; --all must actually reach them."""
    hero = "https://x/images/papaya-king-thedesigndetourist_hero.webp"
    catalog = {
        "makers": [{"id": "M1", "displayName": "Atlas Studio NYC"},
                   {"id": "M2", "displayName": "TikTok @thedesigndetourist"}],
        "tours": [{
            "id": "T1", "makerId": "M1", "kind": "single",
            "heroImageURL": "https://x/images/empire-state-building_hero.webp",
            "stops": [{"audioURL": "audio/empire-state-building.mp3"}],
        }],
        "linkPins": [{
            "id": "P1", "makerId": "M2", "kind": "link", "heroImageURL": hero,
            "stops": [{"audioURL": "", "imageURL": hero}],
        }],
    }
    ok = True
    checks = [
        ("tours", 1, "papaya" , False),
        ("pins",  1, "empire" , False),
        ("all",   2, None     , None),
    ]
    for scope, want_n, absent, _ in checks:
        urls, slug_kind, _ = build_index(catalog, None, scope)
        if len(urls) != want_n:
            print(f"  FAIL scope {scope}: expected {want_n} urls, got {len(urls)}"); ok = False
        if absent and any(absent in u for u in urls):
            print(f"  FAIL scope {scope}: should not contain {absent}"); ok = False
    # the pin's slug must come from its hero, not collapse to ""
    _, slug_kind, _ = build_index(catalog, None, "pins")
    if slug_kind.get("papaya-king-thedesigndetourist") != "link":
        print(f"  FAIL pin slug fallback: {slug_kind}"); ok = False
    # --maker must not leak pinned creators into a city scope
    urls, _, _ = build_index(catalog, "NYC", "tours")
    if len(urls) != 1 or "empire" not in urls[0]:
        print(f"  FAIL --maker NYC scoping: {urls}"); ok = False
    print("  PASS  scope: tours / pins / all" if ok else "  FAIL  scope")
    return ok


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--maker", help="limit to one maker, e.g. MAD (matches displayName)")
    ap.add_argument("--pins", action="store_true", help="check link pins instead of tours")
    ap.add_argument("--all", action="store_true", help="check everything: tours AND link pins (slow)")
    ap.add_argument("--selftest", action="store_true", help="run classification tests, no network")
    ap.add_argument("--file", default=TOURS_JSON, help="path to Tours.json")
    ap.add_argument("--jobs", type=int, default=8, help="parallel downloads (default 8)")
    args = ap.parse_args()

    if args.selftest:
        sys.exit(selftest())

    if not args.maker and not args.all and not args.pins:
        ap.error("pass --maker <CODE> for one city, --pins for link pins, or --all for everything")
    if args.pins and args.all:
        ap.error("--pins and --all are different scopes; pass one")

    scope_name = "all" if args.all else ("pins" if args.pins else "tours")

    try:
        with open(args.file) as fh:
            catalog = json.load(fh)
    except Exception as exc:
        print(f"cannot read {args.file}: {exc}", file=sys.stderr)
        sys.exit(2)

    urls, slug_kind, walk_stop_urls = build_index(catalog, args.maker, scope_name)
    if not urls:
        print(f"no images found{' for maker ' + args.maker if args.maker else ''}"
              f" in scope {scope_name}")
        sys.exit(2)

    scope = {"all": "whole catalog (tours + link pins)",
             "pins": "link pins", "tours": "tours"}[scope_name]
    if args.maker:
        scope = f"{args.maker} ({scope})"
    print(f"Atlas duplicate-image check — {scope}: {len(urls)} images\n")

    groups, failed, phashes, thumbs = collections.defaultdict(list), [], {}, {}
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for url, digest, ph, th, err in pool.map(fetch_hash, urls):
            if digest is None:
                failed.append((url, err))
            else:
                groups[digest].append(url)
                if ph:
                    phashes[url] = ph
                if th:
                    thumbs[url] = th

    for url, err in failed:
        print(f"WARN   could not fetch {os.path.basename(url)}: {err}")
    if failed:
        print()

    # A checker that cannot reach the network must not be able to return a
    # pass. On 2026-08-22 every fetch here failed on SSL and this script still
    # printed "OK - no suspicious duplicates", having compared nothing at all.
    if urls and len(failed) / len(urls) > 0.20:
        print("=" * 70)
        print(f"COULD NOT VERIFY - {len(failed)}/{len(urls)} images could not be fetched.")
        print("NOTHING HAS BEEN CHECKED. This is not a pass. Fix the network and re-run.")
        print("=" * 70)
        sys.exit(2)

    if Image is None:
        print("NOTE   Pillow is not installed, so images are compared by BYTES ONLY.")
        print("       The same photo saved as .jpg and .webp will NOT be detected.")
        print("       pip3 install Pillow to enable it.\n")

    errors = report(groups, slug_kind, walk_stop_urls)
    dupes = sum(1 for g in groups.values() if len(g) > 1)
    errors += report_perceptual(phashes, groups, thumbs)

    if errors:
        print(f"{errors} duplicate group(s) need review — a dead swipe, or an image staged under the wrong name")
        sys.exit(1)
    print(f"OK — no suspicious duplicates ({dupes} expected walk-reuse group(s))")
    sys.exit(0)


if __name__ == "__main__":
    main()
