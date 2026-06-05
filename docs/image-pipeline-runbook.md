# Image Pipeline Runbook

How to source, verify, crop, and publish hero + gallery images for Atlas tours.

**When to run:** Any tour that lacks a `heroImageURL` or has no `additionalImageURLs`, or when the owner asks to improve existing images. Run automatically when a new tour is added without images (CLAUDE.md Rule #8).

**When NOT to run:** Portugal / Porto / Lisbon tours — the owner supplies those images directly.

---

## Prerequisites

- **Unsplash API key** — owner pastes fresh each session. Header: `Authorization: Client-ID {KEY}`. Free tier: 50 requests/hour (rolling window, not fixed reset).
- **Gemini API key** — owner pastes fresh each session. Format: starts with `AQ.` — never prepend `AIzaSy`. Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key={KEY}`
- **Python 3** with `Pillow` and `requests` installed.
- **gh-pages worktree** at `/tmp/ghpages` (detached HEAD). If missing: `git worktree add /tmp/ghpages gh-pages`.

---

## Step 1 — Search Unsplash

Run **5–6 targeted queries per tour**, 3 results each (`per_page=3`). Cover different vantage points: exterior, interior, aerial, detail, night, golden hour, etc. Always include `orientation=landscape&content_filter=high`.

```python
import requests, os

KEY = "<unsplash-key>"
BASE = "https://api.unsplash.com/search/photos"

queries = [
    "Empire State Building observation deck",
    "Empire State Building aerial New York",
    "Empire State Building facade architecture",
    "Empire State Building night lights",
    "Empire State Building midtown Manhattan",
]

seen = set()
candidates = []
for q in queries:
    r = requests.get(BASE, headers={"Authorization": f"Client-ID {KEY}"},
                     params={"query": q, "per_page": 3,
                             "orientation": "landscape", "content_filter": "high"})
    print("Rate limit remaining:", r.headers.get("x-ratelimit-remaining"))
    for photo in r.json().get("results", []):
        if photo["id"] not in seen:
            seen.add(photo["id"])
            candidates.append({
                "id": photo["id"],
                "url": photo["urls"]["regular"],
                "desc": photo.get("description") or photo.get("alt_description") or "",
            })
```

Check `x-ratelimit-remaining` after each request. If it hits 0, stop all requests and wait ~60 minutes (rolling window). Do not poll — every poll consumes a request and resets the 60-minute clock on that slot.

---

## Step 2 — Download candidate images

```python
import os, requests
from pathlib import Path

OUT = Path("/tmp/<tour-slug>")
OUT.mkdir(exist_ok=True)

for i, c in enumerate(candidates, 1):
    img_path = OUT / f"raw_{i}.jpg"
    img_path.write_bytes(requests.get(c["url"]).content)
    print(f"{i}. {c['desc'][:60]}")
```

---

## Step 3 — Verify with Gemini

Send each image to `gemini-2.5-flash-lite` with a YES/NO subject-specific prompt. Reject any image that gets NO.

```python
import base64, json, requests

GEMINI_KEY = "<gemini-key>"
GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/"
    f"models/gemini-2.5-flash-lite:generateContent?key={GEMINI_KEY}"
)

def verify(img_path: Path, subject_prompt: str) -> bool:
    b64 = base64.b64encode(img_path.read_bytes()).decode()
    body = {"contents": [{"parts": [
        {"text": subject_prompt},
        {"inline_data": {"mime_type": "image/jpeg", "data": b64}},
    ]}]}
    r = requests.post(GEMINI_URL, json=body)
    text = r.json()["candidates"][0]["content"]["parts"][0]["text"].strip().upper()
    return text.startswith("YES")

# Example subject prompt:
PROMPT = (
    "Does this image show the Empire State Building — the Art Deco skyscraper "
    "at 350 Fifth Avenue, Manhattan, with its distinctive stepped crown and antenna? "
    "Answer YES or NO only."
)

verified = []
for i, c in enumerate(candidates, 1):
    img_path = OUT / f"raw_{i}.jpg"
    if verify(img_path, PROMPT):
        verified.append((i, c))
        print(f"  ✓ {i}")
    else:
        print(f"  ✗ {i} rejected")
```

Write a tight, specific prompt per tour: name the exact building/site, mention identifying features, and ask YES or NO only. Generic prompts produce false positives.

---

## Step 4 — Crop to 1200×900 and add labels

Crop rule: `scale = max(1200/w, 900/h)` → resize → center crop. This fills the frame without letterboxing.

Add a **white rounded-corner box** top-left, with a large number (52pt DejaVuSans-Bold) and a small category label (16pt) for owner review.

```python
from PIL import Image, ImageDraw, ImageFont
import io

TARGET_W, TARGET_H = 1200, 900

def crop_1200x900(img_path: Path) -> Image.Image:
    img = Image.open(img_path).convert("RGB")
    w, h = img.size
    scale = max(TARGET_W / w, TARGET_H / h)
    new_w, new_h = int(w * scale), int(h * scale)
    img = img.resize((new_w, new_h), Image.LANCZOS)
    left = (new_w - TARGET_W) // 2
    top  = (new_h - TARGET_H) // 2
    return img.crop((left, top, left + TARGET_W, top + TARGET_H))

def add_label(img: Image.Image, number: int, category: str) -> Image.Image:
    img = img.copy()
    draw = ImageDraw.Draw(img)
    try:
        font_big = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 52)
        font_sm  = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
    except OSError:
        font_big = font_sm = ImageFont.load_default()
    pad, margin = 12, 16
    text = str(number)
    bb = draw.textbbox((0, 0), text, font=font_big)
    bw, bh = bb[2] - bb[0], bb[3] - bb[1]
    box_w = max(bw, draw.textbbox((0,0), category, font=font_sm)[2]) + pad * 2
    box_h = bh + 4 + 16 + pad * 2
    draw.rounded_rectangle([margin, margin, margin + box_w, margin + box_h],
                            radius=8, fill="white")
    draw.text((margin + pad, margin + pad), text, fill="black", font=font_big)
    draw.text((margin + pad, margin + pad + bh + 4), category, fill="#555", font=font_sm)
    return img

# Save labeled previews
LABELED = OUT / "labeled"
LABELED.mkdir(exist_ok=True)
for idx, (orig_n, c) in enumerate(verified, 1):
    img = crop_1200x900(OUT / f"raw_{orig_n}.jpg")
    img = add_label(img, idx, "exterior")   # adjust category per image
    img.save(LABELED / f"labeled_{idx}.webp", "WEBP", quality=82)
```

Send the labeled images to the owner for review.

---

## Step 5 — Owner picks hero + gallery

Owner replies with something like: `"3 hero, 1, 7, 9"`

- First number = hero image
- Remaining numbers = gallery order

Special instructions:
- **"keep current hero"** — leave `heroImageURL` in Tours.json unchanged; only add `additionalImageURLs`
- **"keep current hero in gallery"** — append the old `heroImageURL` value as the last entry in `additionalImageURLs`
- **"None, leave as-is"** — skip this tour entirely; no Tours.json change

---

## Step 6 — Produce final crops (no labels)

```python
# Given owner's picks, e.g.: hero_pick=3, gallery_picks=[1,7,9]
# verified list is indexed from 1 as shown to owner

FINAL = OUT / "final"
FINAL.mkdir(exist_ok=True)

SLUG = "empire-state-building"  # stem of the tour's audioURL

picks = [3, 1, 7, 9]  # first = hero
for out_n, pick in enumerate(picks, 1):
    orig_n = verified[pick - 1][0]
    img = crop_1200x900(OUT / f"raw_{orig_n}.jpg")
    if out_n == 1:
        name = f"{SLUG}_hero.webp"
    else:
        name = f"{SLUG}_{out_n}.webp"
    img.save(FINAL / name, "WEBP", quality=82)
    print(f"Saved {name}")
```

**Audio slug** = filename stem of the tour's `audioURL`. Example: `audio/empire-state-building.mp3` → `empire-state-building`. Check Tours.json for the exact value — some older slugs have dots or mixed case.

---

## Step 7 — Upload to gh-pages

```bash
cd /tmp/ghpages
git pull origin gh-pages --rebase   # avoid non-fast-forward rejections
cp /tmp/<tour-slug>/final/*.webp images/
git add images/
git commit -m "images: add <Tour Name> hero + gallery"
git push origin HEAD:gh-pages
```

If the push is rejected (non-fast-forward), always rebase before retrying — never force-push gh-pages.

---

## Step 8 — Patch Tours.json

Open `TRAVEL GUIDED TOUR/Resources/Tours.json`. Find the tour by name or `audioURL`. Update:

```json
"heroImageURL": "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/empire-state-building_hero.webp",
"additionalImageURLs": [
  "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/empire-state-building_2.webp",
  "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/empire-state-building_3.webp",
  "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/empire-state-building_4.webp"
],
```

If "keep current hero": leave `heroImageURL` as-is, only add/replace `additionalImageURLs`.

If "keep current hero in gallery": append the original `heroImageURL` value as the last item in `additionalImageURLs` before saving.

Then validate and commit:

```bash
swift scripts/validate-tours.swift
git add "TRAVEL GUIDED TOUR/Resources/Tours.json"
git commit -m "content: add Empire State Building gallery images"
git push -u origin <branch>
```

---

## Batching multiple tours

Process one tour fully (search → verify → label → owner pick → crop → upload → patch) before starting the next. Exception: you can kick off the next tour's Unsplash search in the background while the current tour's gh-pages commit is in flight, to minimize rate-limit dead time.

Keep a running count of Unsplash requests per session. Free tier is 50/hour rolling; 5–6 queries × 3 results = 15–18 requests per tour, so 2–3 tours per hour at most before hitting the ceiling.

---

## Rate limit recovery

If `x-ratelimit-remaining` drops to 0–2:

1. Stop all Unsplash requests immediately (including background scripts).
2. Note the time of the last request.
3. Wait ~60 minutes from that last request — the slot opens on a rolling basis, not at a fixed clock reset.
4. Do not poll to check recovery — each poll consumes a slot and extends the wait.
5. While waiting: continue gh-pages uploads, Tours.json patches, and any other non-Unsplash work.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Push rejected (non-fast-forward) on gh-pages | `git pull origin gh-pages --rebase` then push again |
| Gemini returns empty/malformed response | Check the key starts with `AQ.`, not `AIzaSy`. Re-run the single image. |
| Too few verified images after Gemini | Tell owner, offer to run more queries with different vantage points, or skip the tour |
| `DejaVuSans-Bold.ttf` not found | Install with `apt-get install -y fonts-dejavu` or adjust font path |
| `x-ratelimit-remaining` header missing from response | Parse headers in Python (`r.headers.get(...)`), not shell `grep` — shell picks up `access-control-expose-headers` line instead |
