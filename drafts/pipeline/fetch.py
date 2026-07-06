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
import os, json, requests, hashlib
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
    for cat in wiki_cats:
        try:
            r = S.get("https://commons.wikimedia.org/w/api.php",
                params={"action": "query", "list": "categorymembers", "cmtitle": cat,
                        "cmtype": "file", "cmlimit": "70", "format": "json"}, timeout=20).json()
            files = [m["title"] for m in r.get("query", {}).get("categorymembers", [])]
            for i in range(0, len(files), 30):
                rr = S.get("https://commons.wikimedia.org/w/api.php",
                    params={"action": "query", "titles": "|".join(files[i:i+30]),
                            "prop": "imageinfo", "iiprop": "url|size|extmetadata", "format": "json"}, timeout=25).json()
                for _, p in rr.get("query", {}).get("pages", {}).items():
                    ii = p.get("imageinfo", [{}])[0]; w = ii.get("width", 0); h = ii.get("height", 0); url = ii.get("url", "")
                    if not url or w < 1200 or h < 900 or w < h: continue
                    lic = ii.get("extmetadata", {}).get("LicenseShortName", {}).get("value", "?")
                    try: im = Image.open(BytesIO(S.get(url, timeout=25).content)).convert("RGB")
                    except: continue
                    if ok(im): add(im, f"Wiki:{lic}")
        except Exception as e: print("wiki", cat, e)
    json.dump(items, open(f"{d}/manifest.json", "w")); print(slug, "kept", len(items))

if __name__ == "__main__":
    # EXAMPLE — edit per batch:
    run("some-landmark", "XX",
        ["Some Landmark City", "Some Landmark exterior", "Some Landmark interior"],
        ("Category:Some Landmark",))
