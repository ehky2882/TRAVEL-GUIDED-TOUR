# Atlas — Handoff Notes (2026-06-01, session 13)

Web/PM session only — no Swift or `.xcodeproj` changes. All commits are
content-only (`Tours.json` updates), going direct to `main`.

---

## What happened this session

### 1. Caught up from `main` (16 commits ahead)

Pulled in everything from builds 18 and 19 that landed from local sessions
before this web session started. Build is currently **1.0 (19)**. The latest
TestFlight build was cut from a local session — check Apple Developer / TestFlight
for processing status.

---

### 2. 10 new NYC tours added (catalog 81 → 91 tours)

All are Atlas Studio NYC, single-stop, `geofenced`, `architecture` or relevant
primary category. Audio was uploaded by the owner one-by-one during this session.

| Tour | City | Coords | Duration |
|------|------|--------|----------|
| Domino Park | Brooklyn | 40.7128, -73.9635 | (per script) |
| Wave Hill | Bronx | 40.9005, -73.9120 | (per script) |
| Queens Museum | Queens | 40.7461, -73.8460 | (per script) |
| Museum of the Moving Image | Queens | 40.7561, -73.9256 | (per script) |
| Snug Harbor Cultural Center | Staten Island | 40.6432, -74.1016 | (per script) |
| Yankee Stadium | Bronx | 40.8296, -73.9262 | (per script) |
| Citi Field | Queens | 40.7571, -73.8458 | (per script) |
| Madison Square Garden | New York | 40.7505, -73.9934 | (per script) |
| Riverside Church | New York | 40.8098, -73.9632 | (per script) |
| One World Trade Center | New York | 40.7127, -74.0134 | (per script) |

Audio files are on `gh-pages` at the standard path:
`https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/audio/<slug>.mp3`

---

### 3. Hero image audit + fixes

All 10 new tours initially had guessed/unverified Wikimedia URLs that returned
404. Fixed by searching Commons for each landmark and verifying the correct
hash-based path with `curl`. All 10 now have confirmed live hero images.

---

### 4. Two coordinate fixes

- **The Cloisters** — was `40.86486, -74.01858` (that longitude puts it in New
  Jersey, across the Hudson). Corrected to owner-provided
  `40.865220141491584, -73.93112156312351`.
- **Beacon Theatre** — was `40.7798, -73.9817`. Corrected to owner-provided
  `40.7804913093391, -73.98125671900641`.

---

### 5. Flatiron Building hero image replaced

Owner said the existing photo was "terrible." Replaced with a nearly-square
portrait (3024 × 3903 px) from the iconic prow angle — much better fit for
square card frames.

- **Old:** `Flatiron_Building_252930243_a57b1b3f78.jpg` (wide landscape)
- **New:** `The_Flatiron_Building_in_Manhattan.jpg` (CC BY-SA 4.0, ~4:5 portrait)
  `https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/The_Flatiron_Building_in_Manhattan.jpg/1280px-The_Flatiron_Building_in_Manhattan.jpg`

---

## Catalog state as of session end

- **91 tours, 3 makers**
- **73 NYC-area tours** (New York + Brooklyn + Bronx + Queens + Staten Island)
- 14 Porto-area + 1 Braga + 1 Lisbon + 1 Cascais + 1 Matosinhos + 1 Leixões
- 58 single-stop + 1 multi-stop (AMNH Four Facades)
- All tours have `heroImageURL` (all verified live)
- Latest build: **1.0 (19)** — uploaded from local session 2026-05-31

---

## Commits this session (all direct to `main`)

```
0567760  content(flatiron): replace hero image with square-friendly portrait shot
c0d1cc8  fix: correct coordinates for Beacon Theatre tour
36af372  fix: correct coordinates for The Cloisters tour
e2ab1d7  fix: correct hero image URLs for 10 new NYC tours (verified Wikimedia paths)
1ecbe60  content: add Riverside Church + One World Trade Center tours
08771ca  content: add Citi Field + Madison Square Garden tours
873e814  content: add Snug Harbor + Yankee Stadium tours
c2e8e4b  content: add Queens Museum + Museum of the Moving Image
de74cec  content: add Domino Park + Wave Hill tours
```

---

## Parked / known follow-ups (carried forward)

- **27 more NYC tours** — owner reviewed the suggested list (High Line,
  Grand Central, Brooklyn Bridge, etc.) but recording hasn't started. Need 27
  more to reach 100 NYC-area tours.
- **Porto hero images** — still need the owner to push from Mac to
  `gh-pages/images/`. The Porto/Braga tours use owner-supplied webps; the
  local session has them.
- **Build 20** — not yet cut. Ready to cut whenever the next content or
  code batch is ready to ship.
- **PR #93 part 2** — stop-row timeline + thumbnails + animated `waveform`
  now-playing indicator + non-modal playback start. Needs an implementation
  session (new branch).
- **Mini-player polish (parked since session 11)** — title type hierarchy
  (both lines are `caption`), align skip-forward (20) + play/pause (18)
  glyph sizes, bump avatar 32 → 36pt.
- **M-qa items 6+7** — AMNH Four Facades geofence walk; needs physical device.

---

## How to resume (local session at home)

1. `git fetch && git status && git log origin/main..HEAD`
   Tree should be clean on `main`; you're 9 commits ahead of the last
   local pull from before this web session.
2. `git pull origin main` to pick up the 9 commits above.
3. No Xcode project changes this session — no need to re-index or clean build.
4. If cutting a TestFlight build: bump `CURRENT_PROJECT_VERSION` 19 → 20
   in `project.pbxproj`, archive, upload via Organizer.
5. Next likely work: either more NYC tour recordings (27 to go for 100),
   or kick off PR #93 part 2 in a new implementation session.
