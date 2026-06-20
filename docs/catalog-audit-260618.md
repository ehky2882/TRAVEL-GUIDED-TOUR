# Atlas Catalog Integrity Audit — 2026-06-18

**Scope:** Read-only integrity sweep of the entire live tour catalog (`TRAVEL GUIDED TOUR/Resources/Tours.json`).
**Catalog at audit time:** 300 tours · 309 stops · 4 makers (100 NYC · 80 LDN · 66 LIS · 54 OPO).
**Method:** schema validation (Swift validator + an independent Python re-check), HTTP-HEAD of *every* audio and image URL, coordinate bounding-box checks, and cross-catalog duplicate detection. Nothing was modified — this is a findings document only.

---

## Executive summary

| Check | Result |
|---|---|
| **Dead audio** (won't play) | **0** — all 310 audio files load (HTTP 200) |
| **Dead images** | **4** — all NYC, all *secondary* images (2 gallery slides, 2 stop photos). **No tour has a broken hero.** |
| **Mis-geocoded tours** (wrong place) | **0** — every tour's coordinates match its stated city |
| **Exact / near-duplicate tours** | **0** exact, **0** near-dupes. 2 same-subject pairs worth a glance (not bugs). |
| **Schema / data errors** | **0** — validator clean; no duplicate IDs, no broken maker links, all prices £0/free |
| **Gallery gaps** | **11** tours have no gallery; **46** tours still use an external (Wikimedia) hero — the image-pipeline backlog |
| **Empty transcripts** | **16** stops (5%) have no on-screen transcript text (audio still plays) |

**Bottom line: nothing is user-facing-broken in a serious way.** No silent dead audio, no broken hero images, no tours pointing at the wrong city. The catalog is in good health. The real work is *cosmetic/coverage*: 4 stray dead thumbnails to clean up, and a known image-pipeline backlog (galleries + external heroes).

### Top 5 most urgent

1. **4 dead images** (broken thumbnails) — The Oculus, The Charging Bull, Madison Square Garden, Riverside Church. All are leftover Wikimedia links; each tour already has healthy gh-pages images, so the fix is to drop or replace the one dead link. **(P0/P1 — see §1)**
2. **7 NYC tours + Casa da Música have *both* no gallery and an external hero** — the weakest imagery in the catalog, top candidates for the image pipeline. **(P1 — see §3)**
3. **46 tours still served by a Wikimedia hero** (45 NYC + Casa da Música) — external hosting is a standing risk; these should migrate to gh-pages. **(P1 — see §3)**
4. **16 stops missing transcript text** (8 OPO, 5 NYC, 3 LIS) — audio plays fine, but the "Read more" panel is blank. **(P2 — see §6)**
5. **2 same-subject tour pairs** — AMNH (single) vs AMNH: Four Facades (multi-stop), and Stonewall Inn vs Stonewall National Monument. Likely intentional, but worth confirming they don't read as duplicates. **(P2 — see §5)**

---

## Prioritized punch-list

### P0 — broken / user-facing
*Nothing critical.* No dead audio, no broken heroes, no mis-geocoded tours. The four dead images below are the only user-visible breakage, and they're all secondary slides — listed under P1.

### P1 — visible-but-not-blocking

| # | Tour | Issue | Suggested fix |
|---|------|-------|---------------|
| 1 | **The Oculus** (NYC) | `additionalImageURLs[1]` is a dead Wikimedia link (`Oculus_NYC.jpg`, 404) | Remove the entry, or replace with a gh-pages `oculus_3.webp`. Hero + `oculus_2` are fine. |
| 2 | **The Charging Bull** (NYC) | `additionalImageURLs[2]` dead Wikimedia (`Charging_Bull`, 404) | Remove the entry. Hero + 2 gallery slides are fine. |
| 3 | **Madison Square Garden** (NYC) | stop-level `imageURL` dead Wikimedia (`MSG_Front_Entrance.jpg`, 404) | Clear/replace the stop image. Hero + gallery are fine. |
| 4 | **Riverside Church** (NYC) | stop-level `imageURL` dead Wikimedia (`Riverside_Church`, 404) | Clear/replace the stop image. Hero + 6 gallery slides are fine. |
| 5 | **8 tours: no gallery AND external hero** (weakest imagery) | El Museo del Barrio, MoMA PS1, New Museum, Strivers' Row, Tenement Museum, The Strand Bookstore (NYC) + Casa da Música (OPO) | Run the image pipeline: source 1 gh-pages hero + a small gallery for each. |
| 6 | **46 tours on a Wikimedia hero** | 45 NYC + Casa da Música (OPO) | Migrate heroes to gh-pages via the image pipeline (full list in §3). External hosts can vanish without notice. |
| 7 | **4 more no-gallery tours (gh-pages hero already good)** | Dennis Severs' House, Hatton Garden, The Royal Festival Hall (LDN), Pink Street (LIS) | Add a gallery when convenient — hero is healthy, so lower urgency. |

### P2 — cosmetic / planning

| # | Item | Detail |
|---|------|--------|
| 8 | **16 empty transcripts** | Audio plays; the transcript panel is blank. 8 OPO, 5 NYC, 3 LIS (full list §6). |
| 9 | **Same-subject pairs** | AMNH single vs Four Facades (13 m apart); Stonewall Inn vs Stonewall National Monument (45 m). Confirm intentional. |
| 10 | **Category skew** | `architecture` (74) dominates; `foodAndDrink` (6), `literature` (7), `hiddenGems` (8) are thin. Content-planning note, not a bug (§7). |

---

## §1 — Audio URLs (Check 1)

**All 310 unique audio URLs return HTTP 200.** Every tour will play. No dead, missing, or moved audio anywhere in the catalog. This includes every stop's `audioURL` and the (none-present) intro-audio tracks. Audio is the strongest part of the catalog.

## §2 — Image URLs (Check 2)

1,138 unique image URLs checked (heroes + galleries + stop photos).

- **gh-pages-hosted: 1,068 / 1,068 live (100%).** The owned image host is rock-solid.
- **External (Wikimedia): 70 total → 66 live, 4 dead.**

**The 4 dead images** (all NYC, all secondary — see P1 table for fixes):

| Tour | Where | Dead URL (Wikimedia) |
|------|-------|----------------------|
| The Oculus | gallery[1] | `…/Oculus_NYC.jpg/1280px-Oculus_NYC.jpg` |
| The Charging Bull | gallery[2] | `…/Bowling_Green_td_(2018-12-13)_06_-_26_Broadway,_Charging_Bull.jpg/1280px-…` |
| Madison Square Garden | stop image | `…/Madison_Square_Garden_Front_Entrance.jpg/1280px-…` |
| Riverside Church | stop image | `…/Neo-Gothic_-_New_York,_NY_-_Riverside_Church_(1).jpg/1280px-…` |

**No hero image is dead.** All four affected tours have a healthy gh-pages hero and additional gh-pages gallery slides, so users still see good imagery — these are stray broken thumbnails, not blank tours.

> **Note on external risk:** these 4 deaths are exactly the failure mode that external hosting invites — a Wikimedia file gets renamed/deleted and the link rots silently. This is the strongest argument for finishing the hero migration in §3.

## §3 — Gallery / weak-imagery coverage (Check 3)

### Tours with no gallery (`additionalImageURLs` empty): 11

| Maker | Tours |
|---|---|
| NYC (6) | El Museo del Barrio\*, MoMA PS1\*, New Museum\*, Strivers' Row\*, Tenement Museum\*, The Strand Bookstore\* |
| LDN (3) | Dennis Severs' House, Hatton Garden, The Royal Festival Hall |
| LIS (1) | Pink Street |
| OPO (1) | Casa da Música\* |

\* = *also* has an external (Wikimedia) hero → **weakest imagery in the catalog, highest priority for the pipeline.**

### Tours with an external (Wikimedia) hero: 46

All are hosted on `upload.wikimedia.org`. **45 are NYC; 1 is OPO (Casa da Música).** London, Lisbon, and the rest of Porto are fully migrated to gh-pages heroes — this backlog is essentially "the older NYC half of the catalog."

<details>
<summary>Full list of 46 external-hero tours (click to expand)</summary>

American Museum of Natural History · American Museum of Natural History: Four Facades · Apollo Theater · Beacon Theatre · Brooklyn Bridge Park · Brooklyn Museum · Cathedral of St. John the Divine · Chelsea Market · Columbus Park, Chinatown · Cooper Hewitt, Smithsonian Design Museum · Cooper Union Foundation Building · El Museo del Barrio · Ford Foundation Building · Governors Island · Grand Army Plaza, Brooklyn · High Line, 10th Avenue Square · LOVE Sculpture · MoMA PS1 · Museum of Arts and Design · Museum of Modern Art (MoMA) · Neue Galerie · New Museum · Queens Museum · Radio City Music Hall · Schomburg Center for Research in Black Culture · Snug Harbor Cultural Center · Stonewall National Monument · Strivers' Row · Tenement Museum · The Ansonia · The Astor Place Cube · The Breuer Building · The Chelsea Hotel · The Dakota · The Morgan Library & Museum · The Plaza Hotel · The Shed · The South Facade of Grand Central · The Strand Bookstore · The Unisphere · Vessel, Hudson Yards · Wall Street · Washington Square Park · Wave Hill · Whitney Museum of American Art · Casa da Música (OPO)

</details>

**Coverage scorecard (galleries):** NYC 6/100 missing · LDN 3/80 missing · LIS 1/66 missing · OPO 1/54 missing. London/Lisbon/Porto galleries are near-complete; NYC is the only city with a real external-hero backlog.

## §4 — Coordinate sanity (Check 4)

**No mis-geocoded tours.** Every tour's centroid sits inside the bounding box of its own stops (validator confirms, 0 warnings), and every centroid matches its stated `city`. The "Cloisters-into-New-Jersey" class of bug is **not** present.

Seven tours fall *outside* the tight per-maker boxes from the audit brief, but all are legitimate — the OPO and LIS "studio" makers host tours across all of Portugal, not just their home metro. Each was verified against its `city` field:

| Tour | City | Coordinates | Verdict |
|------|------|-------------|---------|
| Braga Municipal Stadium | Braga | 41.56, −8.43 | ✅ correct (Braga, N. Portugal) |
| Church of Santa Maria | Marco de Canaveses | 41.19, −8.15 | ✅ correct |
| Municipal Library of Viana do Castelo | Viana do Castelo | 41.69, −8.83 | ✅ correct |
| Biblioteca Pública (Angra) | Angra do Heroísmo | 38.66, −27.22 | ✅ correct (Terceira, **Azores**) |
| Adega Mayor | Campo Maior | 39.05, −7.09 | ✅ correct (far-east, by Spain) |
| Óbidos | Óbidos | 39.36, −9.16 | ✅ correct |
| Capela do Monte | Lagos | 37.13, −8.77 | ✅ correct (Algarve) |

**Action:** none for the data. If the validator is ever extended with per-region boxes, widen OPO/LIS to "all of Portugal incl. Azores" so these don't false-positive.

## §5 — Duplicate / near-duplicate detection (Check 5)

Clean across all 300 tours:

- **Exact title duplicates:** none.
- **Near-duplicate titles** (same core title modulo "The"/punctuation): none.
- **Audio URL reused by >1 tour:** none.
- **Hero image reused by >1 tour:** none.

**Proximity (centroids <50 m apart):** 10 pairs, almost all genuinely distinct neighbours (Vessel/The Shed, Wall St/Federal Hall, Palácio da Bolsa/Mercado Ferreira Borges, Burlington Arcade/Royal Academy, the two adjacent Alfama miradouros, etc.). **Two pairs cover the same subject** and are worth a sanity check:

1. **American Museum of Natural History** (single-stop) **vs American Museum of Natural History: Four Facades** (multi-stop, 13 m) — almost certainly intentional (the multi-stop is a deliberate architecture walk around the building), but the single-stop tour overlaps it.
2. **Stonewall Inn vs Stonewall National Monument** (45 m) — the bar vs the across-the-street monument/park. Distinct landmarks, same story.

Neither is a true duplicate; flagging only so the owner can confirm they're meant to coexist.

## §6 — Schema / field consistency (Check 6)

`swift scripts/validate-tours.swift` → **OK, no issues** (4 makers / 300 tours / 309 stops). Independent Python re-check agrees:

- ✅ No duplicate tour UUIDs; no duplicate stop UUIDs.
- ✅ Every `makerId` resolves to a real maker.
- ✅ `kind` ↔ stop-count consistent (single = 1 stop, multiStop ≥ 2).
- ✅ Every `primaryCategory` is a valid `TourCategory` enum case.
- ✅ Every stop has a valid `triggerMode` (geofenced/manual) and positive `triggerRadiusMeters`.
- ✅ **All `priceUSD` = 0** — V1-all-free holds; no accidental paid tour.
- ✅ No suspiciously short descriptions; no audio-duration anomalies.

**One content gap — 16 stops with empty transcript text** (5% of stops; the other 95% average ~2,200 chars). Audio plays normally; only the on-screen "Read more" transcript is blank:

- **OPO (8):** Batalha Centro de Cinema · Building in Senhora da Luz · Mosteiro Santo Agostinho da Serra do Pilar · Teatro Rivoli · Trindade Metro Station · Vodafone Headquarters · Municipal Library of Viana do Castelo · Biblioteca Pública (Angra)
- **NYC (5):** New York City Hall · St. Paul's Chapel · The Ansonia · The Chelsea Hotel · Park Avenue Armory
- **LIS (3):** Adega Mayor · Óbidos · Capela do Monte

*(All 80 London tours have transcripts.)*

## §7 — Category & maker distribution (Check 7)

| Category | Tours |
|---|---|
| architecture | 74 |
| culturalHeritage | 63 |
| history | 55 |
| sacredSites | 29 |
| natureAndParks | 28 |
| visualArt | 19 |
| musicAndPerformance | 11 |
| hiddenGems | 8 |
| literature | 7 |
| foodAndDrink | 6 |

**By maker × top categories:**
- **NYC:** architecture 30, history 27, culturalHeritage 14 — skews built-environment.
- **LDN:** culturalHeritage 23, history 14, architecture 11 — broadest spread.
- **LIS:** culturalHeritage 15, natureAndParks 13 (miradouros/parks), architecture 10.
- **OPO:** architecture 23 — heavily architecture-led.

Not a bug, but a content-planning signal: `foodAndDrink`, `literature`, and `hiddenGems` are thin everywhere — room to grow if those categories matter for discovery.

## §8 — Multi-stop tours (Check 8)

Exactly **2** multi-stop tours, as expected. Both are fully wired — every stop has live audio:

1. **American Museum of Natural History: Four Facades** (NYC) — 5 stops: Introduction (71 s) · Theodore Roosevelt Memorial (118 s) · Original Main Facade (107 s) · Richard Gilder Center (107 s) · Rose Center (121 s). All audio 200. ✅
2. **Fifth Avenue Walk** (NYC) — 6 stops: Grand Army Plaza (104 s) · The Apple Cube (112 s) · Fifth and Fifty-Seventh (135 s) · Cartier Mansion (167 s) · St. Patrick's Cathedral (73 s) · Saks & Rockefeller Center (112 s). All audio 200. ✅

The other 298 tours are single-stop, as designed.

---

## Methodology & caveats

- **URLs:** every audio (310) and image (1,138) URL was HTTP-checked. gh-pages and audio were checked in parallel; Wikimedia URLs were re-checked **serially with ~1.5 s spacing and a browser User-Agent** after an initial parallel pass returned rate-limit (429) responses — so the 4 reported deaths are genuine 404s, confirmed on a polite second pass, not rate-limiting false positives. 0 URLs were left unverified.
- **Read-only:** `Tours.json`, audio, and images were not modified. This document is the only artifact created.
- **Coordinates** were checked against each tour's `city` field rather than only the brief's per-maker boxes, because the OPO/LIS makers legitimately span all of Portugal (incl. the Azores).
