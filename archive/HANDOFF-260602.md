# Atlas — Handoff Notes (2026-06-02, session 16)

Web/PM session. Single 11-tour Portugal batch shipped via PR #110,
then build bump 23 → 24 via PR #111 (admin-merged). TestFlight 1.0
(24) live by session end. No Swift / asset / project-file changes
beyond the one-line `CURRENT_PROJECT_VERSION` bump.

---

## What happened this session

### 1. 11-tour Portugal batch (PR #110)

Source: `~/Downloads/wetransfer_output-vodafone-headquarters-…_2026-06-02_2259/`
— 11 subfolders, each with MP3 + transcript + numbered hero/gallery
images. Owner pre-assigned makers + categories in the briefing.

Per-tour data (duration rounded from `afinfo`):

| # | Maker | Tour | City | Category | Duration | Notes |
|---|---|---|---|---|---|---|
| 1 | Porto | Batalha Centro de Cinema | Porto | culturalHeritage | 167s | Art Deco, 1947; censorship history; Atelier 15 renovation 2022 |
| 2 | Porto | Building in Senhora da Luz | Porto | architecture | 139s | Souto de Moura, 2016; Foz do Douro |
| 3 | Porto | Mosteiro Santo Agostinho da Serra do Pilar | Vila Nova de Gaia | sacredSites | 151s | 1538–1670; Portugal's only circular cloister; UNESCO |
| 4 | Porto | Teatro Rivoli | Porto | musicAndPerformance | 167s | Júlio Brito Art Deco redesign, 1923 |
| 5 | Porto | Trindade Metro Station | Porto | architecture | 146s | Souto de Moura; 6-line interchange + 736-tile 2025 azulejo |
| 6 | Porto | Vodafone Headquarters | Porto | architecture | 158s | Barbosa & Guimarães, 2009; faceted concrete shell, Boavista |
| 7 | Porto | Municipal Library of Viana do Castelo | Viana do Castelo | literature | 158s | Siza, 2008; Távora's waterfront master plan |
| 8 | Porto | Biblioteca Pública e Arquivo Regional Luís da Silva Ribeiro | Angra do Heroísmo | literature | 167s | **First Azores tour.** Inês Lobo; Mies nominee 2017 |
| 9 | Lisbon | Adega Mayor | Campo Maior | architecture | 135s | Siza, 2006; Nabeiro coffee family winery; Alentejo |
| 10 | Lisbon | Óbidos | Óbidos | culturalHeritage | 155s | Vila das Rainhas; 1,565m walls |
| 11 | Lisbon | Capela do Monte | Lagos | sacredSites | 173s | Siza, 2016; only Algarve building; Monte da Charneca |

#### Categorisation notes

- Tour 11 (Capela do Monte) coords (37.13, -8.77) put the chapel on
  a hilltop above the abandoned hamlet of Monte da Charneca; the
  hamlet is administratively in **Lagos** (Algarve), so the city
  field is `Lagos`. Transcript only names the hamlet — Lagos
  resolved from the coordinates.
- Tour 9 (Adega Mayor): the audio file in the wetransfer folder is
  named `Campo Maior.mp3` (town), but the tour itself is the
  Nabeiro winery — slug + base remain `adega-mayor` /
  `Adega_Mayor`. Images in this folder are `.jpg` (not `.webp`) —
  preserved as-is in URLs.
- Tour 8 (Biblioteca Pública Angra): full Portuguese title
  preserved in JSON (`"Biblioteca Pública e Arquivo Regional Luís
  da Silva Ribeiro"`); slug + image base shortened to
  `biblioteca-publica-angra` / `Biblioteca_Publica_Angra` for
  readability.

#### gh-pages upload — fought the connection

Combined audio + image push (≈55 MB pack) repeatedly hit
HTTP 408 `RPC failed; sideband packet`. No SSH key on this machine
(`~/.ssh/` absent), so chunked over HTTPS instead:

- `f4e849d` audio batch 1/3 (4 MP3s — adega/batalha/biblioteca/building)
- `259309d` audio batch 2/3 (4 MP3s — capela/mosteiro/municipal-library/obidos)
- `7a67dc9` audio batch 3/3 (3 MP3s — teatro/trindade/vodafone)
- `24c6e36` images (42 webp + 3 jpg-for-Adega)

Mid-push, an early audio commit (`448832e`) accidentally landed on
`claude/mini-player-polish-trio` instead of `gh-pages` because a
branch switch between Bash invocations stuck the working directory
on the wrong branch. Recovered by `git checkout 448832e -- audio/…`
onto gh-pages and recommitting (`259309d`). No data lost, no
duplicates ended up in the published tree.

Lesson: **always `git symbolic-ref HEAD` before committing into
gh-pages from this repo** — gh-pages and main share a working
directory and a branch-switch between long Bash runs is easy to
miss.

#### PR + merge

PR [#110](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/110)
title: `content: add 11 Portugal tours (8 Porto incl Azores + 3
Lisbon)`. 22 UUIDs (11 tours + 11 stops) generated; entries
appended to end of `tours` array in the established
recent-Porto-tour shape (manual triggerMode, 30m radius,
`primaryCategory` from the briefing's *first* suggestion, centroid =
stop, `additionalImageURLs` array of `_2` / `_3` / `_N`). Validator:
3 makers / 113 tours / 117 stops, no issues. CI green (Validate +
Build iOS Simulator + Run unit tests). Squash-merged to main at
`41f4dda`; branch deleted. All 22 live-URL spot-checks (11 audio +
11 heroes including `Adega_Mayor_hero.jpg`) returned 200.

### 2. Build 23 → 24 (PR #111) + TestFlight upload

`CURRENT_PROJECT_VERSION` 23 → 24 in `project.pbxproj` (both Debug
+ Release variants). PR [#111](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/111)
admin-merged (single-line metadata change, same shape as #105/#108).
`xcodebuild archive` clean at `/tmp/Atlas-20260602-2146.xcarchive`.
`open /tmp/Atlas-…xcarchive` opened the archive directly in Xcode
Organizer when the keystroke-driven `Window → Organizer` shortcut
was blocked by Accessibility. Owner uploaded via Organizer.
**TestFlight 1.0 (24) is live.**

---

## State at session end

- **Catalog:** 113 tours, 3 makers, 117 stops (was 102 / 3 / 105 at
  session start).
- **Atlas Studio Porto:** 30 tours; **Atlas Studio Lisbon:** 5 tours.
- **First-time cities in catalog:** Viana do Castelo, Angra do Heroísmo
  (Azores — first offshore tour), Campo Maior (Alentejo), Óbidos,
  Lagos (Algarve).
- **Build:** TestFlight 1.0 (24), uploaded 2026-06-02 evening.
- **Mainland Portugal coverage:** north (Porto belt) → centre
  (Óbidos) → Lisbon belt → Alentejo (Campo Maior) → Algarve
  (Lagos). Plus Terceira in the Azores.

---

## Parked / known follow-ups

- Mini-player polish (parked since session 11): type hierarchy on
  the title (both lines are `caption`), skip-forward (20) +
  play/pause (18) glyph size alignment, avatar 32 → 36pt to match
  the play-ring diameter.
- PR #93 part 2 — stop-row timeline + thumbnails + animated
  `waveform` now-playing indicator + non-modal playback start.
- Home items #2 / #3 / #8 (informational only — owner has the
  measurements from session 15).
- Item #6 clustering visual verify — agreed to walk through together.
- 27 more NYC tours to reach 100 NYC-area.
- M-qa items 6+7 — AMNH Four Facades geofence walk on device.

---

## How to resume

1. `git fetch && git status && git log origin/main..HEAD` — tree
   should be clean on `main` at `401358f`
   (`chore(build): bump CURRENT_PROJECT_VERSION 23 to 24 for
   TestFlight (#111)`).
2. Read `CLAUDE.md` (Current State updated for 1.0 (24) + 113 tours)
   and this handoff.
3. If cutting another TestFlight build: bump
   `CURRENT_PROJECT_VERSION` 24 → 25, archive, upload via Organizer.
4. If continuing implementation, the natural starting points are
   the mini-player polish trio or PR #93 part 2 (stops timeline).
