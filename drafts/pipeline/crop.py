#!/usr/bin/env python3
"""
Crop picked candidates to final 1200x900 WebP and drop them in the gh-pages worktree.

The canonical Atlas image format: 1200x900 (4:3), WebP quality 82. Center-crop to 4:3
then resize. exif_transpose FIRST (handles rotated phone/Wikimedia shots); do NOT add a
manual rotate on top (that double-rotates — a bug we hit early).

gh-pages worktree lives at /tmp/ghpages. Before pushing:
    cd /tmp/ghpages && git fetch origin gh-pages -q && git reset --hard origin/gh-pages -q
Then run this, then:
    git add images/<slug>_*.webp && git commit -m "..." && git push origin gh-pages
(retry push with backoff on non-fast-forward: fetch + rebase, then push again.)

Image URL base: https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/
Naming: <slug>_hero.webp, <slug>_2.webp, <slug>_3.webp, ...
"""
from PIL import Image, ImageOps

def crop43(src_path, dst_path):
    im = ImageOps.exif_transpose(Image.open(src_path)).convert("RGB")
    w, h = im.size; tar = 4/3
    if w/h > tar:
        nw = int(h*tar); x = (w-nw)//2; im = im.crop((x, 0, x+nw, h))
    else:
        nh = int(w/tar); y = (h-nh)//2; im = im.crop((0, y, w, y+nh))
    im.resize((1200, 900), Image.LANCZOS).save(dst_path, "WEBP", quality=82)
    print("->", dst_path.split("/")[-1])

if __name__ == "__main__":
    S = "/tmp/madrid_src"; O = "/tmp/ghpages/images"
    # EXAMPLE — map picked label -> output name:
    jobs = [("some-landmark/XX3.jpg", "some-landmark_hero.webp"),
            ("some-landmark/XX7.jpg", "some-landmark_2.webp")]
    for s, d in jobs:
        crop43(f"{S}/{s}", f"{O}/{d}")
