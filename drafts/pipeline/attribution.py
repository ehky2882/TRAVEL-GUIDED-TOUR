#!/usr/bin/env python3
"""
Capture Wikimedia attribution for CC BY / CC BY-SA picks, matched by PERCEPTUAL hash.

Why perceptual (average-hash), not exact md5: the cropped/re-encoded WebP won't byte-match
a fresh Wikimedia download, and even a re-download decodes to slightly different pixels than
the JPEG you saved. aHash (16x16 grayscale, mean-threshold, Hamming distance <= 6) matches
reliably across JPEG re-encoding.

Give it the picked source JPEGs (the /tmp/madrid_src/<slug>/<LABEL>.jpg files that are CC),
and the Wikimedia category they came from. Prints file / author / license / source URL for
each — paste those into the batch README + drafts/CREDITS.md.

Policy reminder: Atlas has NO in-app attribution UI, so CC BY/BY-SA images are only used
where no PD/CC0/stock version of the exact subject exists, AND the owner OKs it. CC0 and
Public Domain need NO credit. Log everything else.
"""
import requests, json, re
from PIL import Image
from io import BytesIO

UA = "AtlasTourApp/1.0 (edward.yung@gmail.com) image-sourcing"

def ahash(im):
    g = im.convert("L").resize((16, 16)); px = list(g.getdata()); avg = sum(px)/len(px)
    return [1 if p > avg else 0 for p in px]
def dist(a, b): return sum(1 for x, y in zip(a, b) if x != y)
def strip(s): return re.sub("<[^>]+>", "", s or "").strip()

def match(targets, cats, threshold=6):
    """targets: {key: jpg_path}; cats: list of 'Category:...'. Returns {key: {...}}."""
    S = requests.Session(); S.headers.update({"User-Agent": UA})
    th = {k: ahash(Image.open(v)) for k, v in targets.items()}
    found = {}
    for cat in cats:
        r = S.get("https://commons.wikimedia.org/w/api.php",
            params={"action": "query", "list": "categorymembers", "cmtitle": cat,
                    "cmtype": "file", "cmlimit": "200", "format": "json"}, timeout=25).json()
        files = [m["title"] for m in r.get("query", {}).get("categorymembers", [])]
        for i in range(0, len(files), 25):
            rr = S.get("https://commons.wikimedia.org/w/api.php",
                params={"action": "query", "titles": "|".join(files[i:i+25]),
                        "prop": "imageinfo", "iiprop": "url|size|extmetadata", "format": "json"}, timeout=30).json()
            for _, p in rr.get("query", {}).get("pages", {}).items():
                ii = p.get("imageinfo", [{}])[0]; url = ii.get("url", ""); w = ii.get("width", 0); h = ii.get("height", 0)
                if not url or w < 1200 or h < 900 or w < h: continue
                try: c = ahash(Image.open(BytesIO(S.get(url, timeout=25).content)))
                except: continue
                for k, t in th.items():
                    if k in found: continue
                    if dist(c, t) <= threshold:
                        em = ii.get("extmetadata", {})
                        found[k] = {"file": p["title"], "artist": strip(em.get("Artist", {}).get("value", "")),
                                    "license": em.get("LicenseShortName", {}).get("value", ""),
                                    "descurl": ii.get("descriptionurl", "") or url}
        if len(found) == len(th): break
    return found

if __name__ == "__main__":
    targets = {"XX3": "/tmp/madrid_src/some-landmark/XX3.jpg"}
    for k, f in match(targets, ["Category:Some Landmark"]).items():
        print(f"{k}: {f['file']} | {f['artist']} | {f['license']} | {f['descurl']}")
