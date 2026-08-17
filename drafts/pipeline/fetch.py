#!/usr/bin/env python3
"""
Atlas image-sourcing fetch — the no-gate workhorse.

Sources per-subject candidates from Unsplash + Pexels + Pixabay (all ship-safe:
no attribution required) plus optional Wikimedia Commons categories (guaranteed
subject match, but capture the license — most are CC BY / CC BY-SA and need credit;
some are CC0/PD and are ship-clean).

Writes JPEGs to  /tmp/madrid_src/<slug>/<PREFIX><n>.jpg  and a manifest.json with
{label, src, path} per image. `src` is "Uns"/"Pex"/"Pix" for stock, or
"Wiki:<LicenseShortName>" for Wikimedia (so you can filter credit-required later).

Gemini verify gate is DELIBERATELY OMITTED — it was flaky/down during the Toronto+LA
builds, so the flow is: fetch no-gate -> montage-inspect yourself (montage.py) ->
send labeled full-size candidates to the owner -> owner picks. For thin/ambiguous
subjects (where stock returns wrong buildings), lean on the Wikimedia category —
those are guaranteed the right subject.

API KEYS: paste fresh each session (they expire). Owner-pasted images always work
regardless and need no keys.

Usage: edit the run(...) calls at the bottom, then `python3 fetch.py`.
Size filter: keeps images that can crop to 1200x900 without upscaling
(min(w,h) >= 900 AND max(w,h) >= 1200), landscape only for Wikimedia.
"""
import os, json, time, requests, hashlib
from PIL import Image
from io import BytesIO

UNS = "PASTE_UNSPLASH_KEY"      # Client-ID header on api.unsplash.com/search/photos
PEX = "PASTE_PEXELS_KEY"        # Authorization header on api.pexels.com/v1/search
PIX = "PASTE_PIXABAY_KEY"       # key= param on pixabay.com/api/
UA  = "AtlasTourApp/1.0 (edward.yung@gmail.com) image-sourcing"  # Wikimedia needs a descriptive UA
BASE = "/tmp/madrid_src"        # scratch dir (ephemeral — commit finished work to gh-pages)

def ok(im):
    w, h = im.size
    return min(w, h) >= 900 and max(w, h) >= 1200

def run(slug, prefix, queries, wiki_cats=(), pixabay=False):
    d = f"{BASE}/{slug}"; os.makedirs(d, exist_ok=True)
    seen = set(); items = []; n = 0
    def add(im, src):
        nonlocal n
        hh = hashlib.md5(im.tobytes()).hexdigest()
        if hh in seen: return
        seen.add(hh); n += 1; lbl = f"{prefix}{n}"; fp = f"{d}/{lbl}.jpg"
        im.save(fp, "JPEG", quality=90); items.append({"label": lbl, "src": src, "path": fp})
    for q in queries:
        try:
            r = requests.get("https://api.unsplash.com/search/photos",
                params={"query": q, "per_page": 5, "orientation": "landscape", "content_filter": "high"},
                headers={"Authorization": f"Client-ID {UNS}"}, timeout=15).json()
            for p in r.get("results", []):
                try: im = Image.open(BytesIO(requests.get(p["urls"]["raw"] + "&w=2000", timeout=15).content)).convert("RGB")
                except: continue
                if ok(im): add(im, "Uns")
        except Exception as e: print("uns", q, e)
    for q in queries:
        try:
            r = requests.get("https://api.pexels.com/v1/search",
                params={"query": q, "per_page": 6, "orientation": "landscape"},
                headers={"Authorization": PEX}, timeout=15).json()
            for p in r.get("photos", []):
                try: im = Image.open(BytesIO(requests.get(p["src"]["original"], timeout=15).content)).convert("RGB")
                except: continue
                if ok(im): add(im, "Pex")
        except Exception as e: print("pex", q, e)
    if pixabay:
        for q in queries:
            try:
                r = requests.get("https://pixabay.com/api/",
                    params={"key": PIX, "q": q, "image_type": "photo", "orientation": "horizontal", "per_page": 5},
                    timeout=15).json()
                for p in r.get("hits", []):
                    try: im = Image.open(BytesIO(requests.get(p["largeImageURL"], timeout=15).content)).convert("RGB")
                    except: continue
                    if ok(im): add(im, "Pix")
            except Exception as e: print("pix", q, e)
    S = requests.Session(); S.headers.update({"User-Agent": UA})

    def wiki_api(params, tries=5):
        """Commons API with retry. Returns parsed JSON, or None if unreachable.

        Wikimedia intermittently answers with an HTML error page rather than JSON;
        a bare .json() on that raises and — before this was fixed — the whole
        category was abandoned silently. Retry, then report."""
        for a in range(tries):
            try:
                r = S.get("https://commons.wikimedia.org/w/api.php", params=params, timeout=30)
                if r.status_code == 200 and r.text.lstrip().startswith("{"):
                    return r.json()
            except Exception:
                pass
            time.sleep(2 * (a + 1))
        return None

    def wiki_download(url, title=""):
        """Fetch one file, honouring 429. Returns a PIL image or None.

        upload.wikimedia.org rate-limits bursts with HTTP 429 and an HTML body.
        Handing that body to Image.open raises, which used to be swallowed as
        'bad image' — so a rate-limited run looked exactly like a thin category."""
        for a in range(5):
            try:
                r = S.get(url, timeout=60)
                if r.status_code == 429:
                    wait = min(120, 15 * (a + 1))
                    print(f"   wiki 429 — backing off {wait}s ({title[:40]})")
                    time.sleep(wait); continue
                if r.status_code != 200:
                    time.sleep(4); continue
                return Image.open(BytesIO(r.content)).convert("RGB")
            except Exception:
                time.sleep(5)
        print("   wiki give-up:", title[:60])
        return None

    for cat in wiki_cats:
        if not cat.startswith("Category:"):
            # The API answers `invalidcategory` for a bare name and returns no
            # members, which is indistinguishable from an empty category.
            print(f"   wiki: adding missing 'Category:' prefix to {cat!r}")
            cat = "Category:" + cat
        r = wiki_api({"action": "query", "list": "categorymembers", "cmtitle": cat,
                      "cmtype": "file", "cmlimit": "100", "format": "json"})
        if r is None:
            print("   wiki UNREACHABLE (not empty):", cat); continue
        if "error" in r:
            print("   wiki API ERROR:", cat, r["error"].get("code")); continue
        files = [m["title"] for m in r.get("query", {}).get("categorymembers", [])]
        if not files:
            print("   wiki: category is genuinely empty:", cat); continue
        for i in range(0, len(files), 20):
            rr = wiki_api({"action": "query", "titles": "|".join(files[i:i+20]),
                           "prop": "imageinfo", "iiprop": "url|size|extmetadata", "format": "json"})
            if rr is None:
                print("   wiki UNREACHABLE mid-category:", cat); break
            for _, p in rr.get("query", {}).get("pages", {}).items():
                ii = (p.get("imageinfo") or [{}])[0]
                w = ii.get("width", 0); h = ii.get("height", 0); url = ii.get("url", "")
                # NB: portrait files are KEPT. They crop fine with crop43(top_bias=...)
                # and for tall subjects they are usually the best available frame.
                if not url or min(w, h) < 900 or max(w, h) < 1200: continue
                lic = ii.get("extmetadata", {}).get("LicenseShortName", {}).get("value", "?")
                im = wiki_download(url, p.get("title", ""))
                if im is None: continue
                if ok(im): add(im, f"Wiki:{lic}")
                time.sleep(1.5)   # documented spacing for upload.wikimedia.org
    json.dump(items, open(f"{d}/manifest.json", "w")); print(slug, "kept", len(items))

if __name__ == "__main__":
    # EXAMPLE — edit per batch:
    run("some-landmark", "XX",
        ["Some Landmark City", "Some Landmark exterior", "Some Landmark interior"],
        ("Category:Some Landmark",))
