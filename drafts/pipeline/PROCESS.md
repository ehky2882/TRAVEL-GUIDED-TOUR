# Atlas image-staging pipeline — the process (handoff)

This is the repeatable workflow developed across the Toronto + LA builds for
image-staging audio tours **ahead of narration audio**. Keep it; it works.

## The one-line summary
For each tour: **fetch candidates → self-inspect a montage → send the owner full-size
numbered candidates → owner picks hero + gallery → crop to 1200×900 WebP → push to
gh-pages → capture any CC credits → stage the script as a draft.** Nothing goes live
until the owner records narration MP3s and a city maker is created at first wire-in.

## Scratch + hosting layout (⚠ /tmp is EPHEMERAL — a new container wipes it)
- `/tmp/madrid_src/` — working dir. Per-tour subfolder `<slug>/` holds fetched `<LABEL>.jpg`
  + `manifest.json` ({label, src, path}); `<slug>/labeled/` holds the numbered full-size
  images sent to the owner. **This whole dir is lost on a fresh session — re-fetch as needed.**
- `/tmp/ghpages/` — the gh-pages worktree (durable, pushed). Cropped WebPs go in `images/`.
  Refresh before use: `cd /tmp/ghpages && git fetch origin gh-pages -q && git reset --hard origin/gh-pages -q`
- Image URL base: `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`
- Drafts branch (scripts + READMEs + this folder + CREDITS.md): **`claude/dreamy-wozniak-nM6a4`**
  (stage via a `git worktree` off `origin/<branch>` so you never flip the primary checkout;
  the trailing "getcwd" error after `git worktree remove` is harmless — cwd was the removed tree).

## Scripts in this folder (drafts/pipeline/)
- `fetch.py` — no-gate sourcing (Unsplash + Pexels + Pixabay ship-safe; Wikimedia w/ license capture).
  Paste FRESH API keys each session (they expire). Owner-pasted images need no keys.
- `montage.py` (= mk_montage.py) — build a labeled grid to self-inspect. **Label-accurate**
  (uses manifest order/labels, NOT alphabetical glob — a real bug we fixed: alphabetical order
  put badge "N" on the wrong file for any 2-digit number, so descriptions didn't match. Fixed.)
- `mk_pg.py` — paginated/compact montage (≤20 imgs, ~1100×880) for when the image-read API
  rejects tall montages ("media removed — rejected by API"); see gotcha below.
- `label.py` — burns a number badge + source tag onto each candidate at ~1000px; writes
  `<slug>/labeled/<LABEL>.jpg`. THESE are what you SendUserFile to the owner (full-size,
  NOT a cramped grid — owner feedback: grid tiles are too small to judge).
- `crop.py` — final crop to 1200×900 WebP q82 (exif_transpose first; no manual rotate).
- `attribution.py` — perceptual-hash match a CC pick back to its Wikimedia file → author/license/URL.

## Step by step
1. **Fetch.** 5–6 targeted queries/tour. For landmark buildings that stock gets wrong
   (Aga Khan → Doha's MIA; Olvera St → Paramount/Universal), ADD the Wikimedia category —
   those are guaranteed-subject. Run in the background; it's slow.
2. **Self-inspect** with `montage.py` + Read the montage. Identify genuine vs contaminated;
   note licenses from the manifest `src` field (Wiki:CC BY* = credit; Wiki:CC0/PD & Uns/Pex = ship-safe).
3. **Send** `label.py` output — full-size numbered candidates, a handful per SendUserFile call,
   ship-safe first, CC-licensed flagged. Drop contaminants; say what you dropped and why.
4. **Owner picks** e.g. "WD1 hero, WD13, WD67". First = hero; rest = gallery order.
5. **Crop** picks with `crop.py` → push to gh-pages (retry push w/ fetch+rebase on non-ff).
6. **Credits.** For any CC BY/BY-SA pick, run `attribution.py` and log file/author/license/URL
   in the batch README **and** `drafts/CREDITS.md`. CC0/PD/stock = no credit.
7. **Stage** the script (.txt + _TTS.txt) into `drafts/<city>-batchN/` (or `<city>-<walk>-walk/`)
   with a README carrying the pick map, coords, categories, license notes, and a wire-in checklist.
   **Do this even before all picks are final — the .txt scripts only live in the ephemeral upload
   cache; if you don't commit them, a fresh session loses them.**

## Multi-stop walks
`kind: multiStop`; intro = stop 0 (manual, `introAudioURL: null`); stops 1..N geofenced radius 40.
`totalDurationSeconds` = Σ stop durations; centroid = avg of stop coords; `walkingDistanceMeters`
non-null. `additionalImageURLs` = one image per stop. Walks frequently **reuse** existing
single-stop heroes (4 of Toronto's walks were near-zero new sourcing). Only credit is inherited
from the reused single-stop image.

## Owner-pasted images (when stock/Wikimedia can't get it)
Owner pastes inline → NOT written to /root/.claude/uploads; they're base64 in the session
transcript `.jsonl` (`/root/.claude/projects/*/<session-id>.jsonl`). Extract: walk the JSON,
collect `image` blocks with `source.type==base64`, dedupe by md5, take the newest distinct,
base64-decode. **Flush lag:** a paste from the CURRENT turn is often NOT on disk yet — the
distinct-count won't rise until a later turn. Wait a turn, re-extract. **Always verify the
extracted image (Read) before cropping** — we hit a duplicate-hash bug once (extracted the hero
again as a gallery image). Owner-supplied = ship-safe, no credit.

## Categories / conventions
`architecture, visualArt, culturalHeritage, history, sacredSites, natureAndParks,
musicAndPerformance, literature, hiddenGems`. Audio slug = filename stem of the tour's
`audioURL`; image filename prefix = same slug. Validate with `swift scripts/validate-tours.swift`.

## Known gotchas (learned the hard way)
- **Montage numbering** must use manifest labels, not alphabetical glob (fixed in montage.py).
- **Tall montages get rejected** by the image-read API ("media removed — rejected by API").
  Keep montages short (mk_pg.py, ≤20 imgs). NOTE: late in the LA session the image-READ step
  degraded and rejected *everything* (even small images + owner pastes) — a service/session-length
  issue, NOT file size and NOT the owner's uploads (which kept delivering fine). If reads fail
  wholesale, a fresh session clears it; meanwhile you can still crop/push blind and bounce the
  cropped result back to the owner to verify (their side works).
- **exif_transpose then NO manual rotate** (double-rotate bug).
- **Pexels/Unsplash/Pixabay = no attribution; Wikimedia CC BY/BY-SA = credit; CC0/PD = none.**
- **Stage scripts early** — the upload cache is per-session; uncommitted .txt = lost on restart.
- **gh-pages CDN lag:** images can 404 for a few minutes after push; the in-tree file is correct.
