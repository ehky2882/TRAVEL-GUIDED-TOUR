# HANDOFF — 2026-07-22 (session 68)

**Ho Chi Minh City launched — 43 tours + 16th maker Atlas Studio SGN.** Web/PM
content session. Merged to `main` via [PR #419](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/419)
(`1ad9e38`, squash) and confirmed live on both catalog sources.

## What shipped

- **Atlas Studio SGN** 🇻🇳 (`atlas-maker:sgn` = `40a6f268-82f9-53f0-8f30-91015633cfaf`)
  — Vietnam's first city, the 16th maker.
- **43 single-stop, geofenced (30 m) tours.** District 1 colonial landmarks
  (Notre-Dame, Central Post Office, Opera House, Independence Palace, Bitexco,
  Landmark 81), Cholon temples/markets (Thiên Hậu, Binh Tay, Hào Sỹ Phường, Jade
  Emperor), and a deep food/coffee/cocktail cut (19 of 43 `foodAndDrink`).
- **Bilingual `English | Tiếng Việt`** on tour + stop where a Vietnamese name
  exists; proper-noun venues (Anan, CieL, YUNKA, NÔM, STIR…) carry a single name.
- **Catalog: 828 → 871 tours / 15 → 16 makers / 1033 → 1076 stops.**

## How it was done (reusable notes)

- **Delivery:** owner dropped a ~123 MB Dropbox *folder* link. Downloaded with
  `dl=1` appended → one zip of 43 `output <Name> <lat>, <long>` folders. Coords
  are baked into each folder name, unicode **`#UXXXX`-escaped** (4 hex digits) —
  decode with `re.sub(r'#U([0-9a-fA-F]{4})', lambda m: chr(int(m.group(1),16)), s)`.
  Each folder: 1 mp3, a `_clean.txt`/`_tts` script pair, 1–5 webp (all already
  **1200×900** — no cropping needed). Durations read via `pip install mutagen`.
- **Bilingual split** was done with a Vietnamese marker-word heuristic
  (`Chợ`, `Chùa`, `Nhà thờ`, `Bảo tàng`, `Dinh`, `Miếu`, `Bưu điện`, `Phố`,
  `Cầu`, `UBND`, `Địa Đạo`, …) + manual overrides for the messy cases
  (Jade Emperor `CHÙA` uppercase, Madame Lam duplicated English, Hào Sỹ Phường's
  `(Chợ Lớn)` locator). Don't fully trust the heuristic — eyeball all rows.
- **`[beat]` MUST be stripped from `transcriptText`.** The Swift validator
  hard-errors on any bracketed stage direction (`\[[A-Za-z]`); 33 `[beat]`
  markers were present. Strip them (collapse to a paragraph break) *and* the
  word-count footer — "verbatim clean narration" still means no production markers.
- **No `swift` in a Linux web session** → wrote a **Python port of
  `validate-tours.swift`** (`/tmp/hcmc_dl/pyvalidate.py`) mirroring every rule
  (id uniqueness, closed tag vocabulary, ≥1 Place type + ≥1 Theme, kind↔count,
  order packing, duration math, centroid box, bracketed-marker check). 0 errors,
  0 warnings on the new content before push. CI runs the authoritative Swift one.
- **gh-pages staging without downloading the whole binary tree:**
  `git fetch --filter=blob:none --depth 1 origin gh-pages` (metadata only, fast),
  then `git worktree add --no-checkout -B gh-pages /tmp/ghpages origin/gh-pages`
  + `git reset --quiet`. Copy the new files in, `git add audio/*.mp3 images/*.webp`
  (**never `-a`** — that would stage deletions of the unmaterialised existing
  files), commit, push. 178 new blobs (43 mp3 + 135 webp), 0 deletions. All 178
  URLs live-verified 200.
- **Slug** = ASCII-folded English name (or Vietnamese romanized), lowercase-hyphen.
  `unicodedata.normalize('NFD')` + strip combining marks + `Đ/đ→d`.
- **ids** = `uuid5(NAMESPACE_URL, "atlas-{maker,tour,stop}:sgn[:<slug>]")` — scheme
  reverse-verified against existing BKK/AMS/SEL/LAX makers + a Bangkok tour/stop.
- **Live verification:** poll Supabase `get_catalog` RPC + gh-pages `Tours.json`
  mirror **on tour count, not maker count** — the RPC reports *more* makers (19)
  than Tours.json via upsert accumulation (a known trap; asserting on `/16` never
  matches). Supabase anon/publishable key is in `Data/SupabaseConfig.swift`.

## Decisions made (owner said "continue" after declining the confirm question)

- Maker name **Atlas Studio SGN** (airport-code convention).
- Trigger **geofenced 30 m** (city-launch default; BKK/SEL launched mostly
  `manual` — owner can flip SGN to manual later if the food/venue set prefers it).
- Two **geographic outliers kept as supplied**, `city` = "Ho Chi Minh City":
  **Củ Chi Tunnels – Bến Dược** (`11.14993, 106.45944`, ~75 km NW — its own HCMC
  district) and **Bửu Long Pagoda** (`10.87911, 106.83503`, far east near Biên
  Hòa). Same pattern as Kyoto's out-of-city La Collina.

## Owed / next

- **Branch cleanup:** `claude/tours-upload-audio-photos-3pcty4` is merged; the git
  proxy blocks branch deletion from web sessions → delete in the GitHub UI.
- **Owner's call:** flip SGN triggers to manual if preferred; add more HCMC tours;
  or a different city/feature.
