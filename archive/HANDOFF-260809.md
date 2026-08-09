# HANDOFF — 2026-08-09 (session 87, web) — Chicago launched: 30 tours + 27th maker Atlas Studio ORD; the audio-pending queue is EMPTY

**One-line summary:** Chicago goes live — 25 single-stop tours + 5 walks under new maker
**Atlas Studio ORD** 🇺🇸, wired the same day the owner's Dropbox drop arrived. Catalog
**1226 → 1256 tours / 26 → 27 makers / 1543 → 1596 stops**. **The audio-pending queue is
now EMPTY for the first time since the tracker existed** — Chicago was the last staged city.

Branch: `claude/chicago-audio-upload-3g3ymq`.

## What shipped

- **New maker:** Atlas Studio ORD (`f34cd76e-1e41-5c38-865d-d8eccd775cd3` = uuid5
  `atlas-maker:ord`, 🇺🇸), the 27th. (Staging predicted "22nd" — five complete-drop cities
  jumped the queue between staging and wire-in.)
- **25 single-stop tours**, geofenced 30 m: Cloud Gate · DuSable Bridge/Riverwalk · Art
  Institute · Willis Tower · Historic Water Tower · Wrigley & Tribune · Buckingham Fountain ·
  Marina City · The Rookery · Pritzker Pavilion · Navy Pier · Michigan Avenue Streetwall ·
  Cultural Center · Daley Plaza & the Picasso · Monadnock · LaSalle Canyon & Board of Trade ·
  Merchandise Mart · North Avenue Beach · Old Town & St Michael's · Museum Campus ·
  Chinatown & Ping Tom · Pilsen & 18th Street · Robie House · Griffin MSI · Obama Center.
- **5 walks:** `chicago-riverwalk-walk` (intro+5, 2.0 km, history) ·
  `chicago-loopskyscraper-walk` (intro+5, 0.55 km, architecture) · `chicago-lakefront-walk`
  (intro+5, 2.4 km, culturalHeritage) · `chicago-magmile-walk` (intro+4, 0.8 km, history) ·
  `chicago-pilsen-walk` (intro+4, 1.8 km, culturalHeritage).
- **53 tracks, 6,238 s ≈ 1h44m** to `gh-pages` (commit `99c3150`, pure plumbing, exactly 53
  additions); Tours.json diff **1,675 insertions / 0 deletions**.

## The delivery — first non-MP3 drop

- Dropbox `/scl/fo/` link, **600 MB zip of 53 WAVs (48 kHz mono 16-bit)** — every prior city
  delivered MP3s. Transcoded to the catalog-standard 44.1 kHz/128 kbps MP3 with ffmpeg
  (`apt-get update && apt-get install -y ffmpeg` works in the web container; the install
  404s without the update first). All 53 byte-distinct post-transcode.
- Delivery matched staging **1:1**: singles carried exactly the documented numbering gaps
  (18/19/22/26/27), walks arrived as five folders matching the staged structure, nothing
  spare, nothing missing. Also in the zip: the owner's `chicago_tour_master_list.md` + four
  drafting-session handoffs — **the master list marks the five gap singles as drafted**
  (Wrigley Field, Lincoln Park, Gold Coast/Astor, Wicker Park, The 606). No scripts, images
  or audio for them ever arrived: **a future second batch**, recorded in the survey. Same
  drafting→staging handoff leak as Rome's extras.
- The master list also carries the **locked sensitivity docket** (Eastland: one reverent
  treatment; fire toll stated once at the spine plant; superlatives soft-form: "widely
  called the first skyscraper") — the descriptions written this session follow it.

## 🐛 Two wrong images caught by the open-every-image audit — both OUTSIDE PR #475's scope

The owed audit (open every walk image + the flagged heroes) ran over 30 files. PR #475
audited only *reused* images; both finds were on **new** files it never covered.

1. **`dusable-bridge-riverwalk_hero.webp` showed the WRONG BRIDGE.** A raised single-deck
   bascule photographed from the LaSalle-area stretch with the Merchandise Mart filling the
   background — half a mile west of Michigan Avenue. The DuSable is the double-deck bridge
   with four monumental sculpted towers. The single's gallery **`_2` is unmistakably the
   real DuSable** ("Michigan Avenue" legible on the fascia, Wrigley clock tower directly
   behind, shot from the Riverwalk below — the script's exact vantage) → promoted to hero +
   `stop0.imageURL`; Riverwalk walk stop 4 and MagMile walk stop 1 (both reuse the DuSable
   image) now point at `_2`; the wrong-bridge file dropped entirely. **The Thyssen class:
   plausible slug, wrong picture, caught only by opening the file.**
2. **`chicago-riverwalk_stop1.webp` faced the wrong direction.** The stop stands at
   Franklin/Wells looking **northwest** at Wolf Point + the Mart; the staged Pexels image
   looks **east** at the St. Regis. Swapped to **`merchandise-mart_hero.webp`** — shot from
   the stop's exact position (tour 17's vantage coordinate is 30 m from the stop's; the
   Franklin St bridgehouse is in frame). Documented walk-stop reuse slot.

**Also deduped, per the session-76 convention** (`check-image-duplicates.py --maker ORD`
found both; keep where the subject is true): `michigan-avenue-streetwall_2` ==
`buckingham-fountain_4` (fountain centered → stays with Buckingham) and
`lasalle-board-of-trade_4` == the Loop walk hero (walk hero load-bearing → dropped from the
single's gallery). Post-fix: dup check **clean**; **93 referenced = 97 uploaded − 4
documented orphans** (`michigan-avenue-streetwall_2`, `lasalle-board-of-trade_4`,
`chicago-riverwalk_stop1`, `dusable-bridge-riverwalk_hero` — files remain on gh-pages,
nothing references them, none carried a credit row).

**✅ Cleared by the same audit:** Willis Tower's hero (the predicted crop43 decapitation —
intact, antennae to street); the Pilsen owner-image crossover (walk hero = `_2` both
buildings, stop 2 = `_hero` Thalia alone — exactly as designed); Federal Plaza Calder-free;
the Eastland wreath image; all Lakefront/Loop/MagMile reuses correct against their scripts.

## Wire-in decisions worth carrying

- **The staging READMEs' id forms were wrong; the live catalog was used instead** —
  reverse-verified against BUE/RAK/BER makers, a BUE single pair and Berlin walk stops
  before minting: walk stop ids are `atlas-stop:ord:<walkslug>-stop{N}` (not the READMEs'
  `…:<n>`), walk slugs are city-prefixed (`chicago-loopskyscraper-walk`, matching every
  other city; the READMEs said `loopskyscraper-walk`).
- The two **known** staging-README errors were pre-corrected as planned: singles set
  `stop0.imageURL` to the tour hero (not null); walk galleries omit any stop image that is
  the walk hero (none of Chicago's five needed it — the post-Dubai READMEs already learned
  it; Pilsen's crossed-over hero is not a stop image of its own walk).
- **Walk intros:** `imageURL: null`, radius 40, audio as `<walkslug>_stop0.mp3` — the
  Berlin/Dubai/Madrid convention (Montreal/SAO/BUE differ; Chicago's READMEs specify null).
- **Vantage coordinates preserved** (five singles + three riverwalk stops geofence the
  listener's position, not the landmark); **MagMile intro and stop 1 share one coordinate by
  design** (the AMNH already-inside case, PR #251 — not a data bug).
- **Five transcript header formats, one rule:** `transcriptText` starts after the `---`
  rule; both beat spellings stripped (`[beat]` ×20, `*[beat]*` ×29); script 21's
  `[FIRE SPINE — FINAL ECHO]` sits inside its header and strips with it. Captions extend
  across sentences to clear 60 chars; the `St.` splitter trap was live (St. Michael's,
  St. Louis); shortest shipped caption 61.
- **Sensitivity:** Eastland — wreath image, no mortality figure in any downstream surface
  (title/caption/descriptions); Fort Dearborn relief in no image, its framing named plainly
  in tour 02's description; 🔴 Pilsen walk stops 1+3 ship with **UNRESOLVED mural rights**
  (owner-directed 2026-07-30, OPEN in `drafts/CREDITS.md` — the one exception in the corpus,
  not precedent; single tour 25 stays buildings-only clean).

## Verification (all green before push)

- Python mirror of `validate-tours.swift`: vocab parsed from both `Tag.swift` and the Swift
  validator (raises on disagreement/empty), **self-tested 39/39 injected fault classes**,
  then **0 errors / 0 warnings across all 1256 tours**; 0 duplicate ids across 1256/1596/27.
- gh-pages: 0 of 53 target paths pre-existed; tree diff exactly 53 additions, nothing
  outside `audio/`; Pages deploy **completed/success**; **all 53 live audio URLs
  hash-matched against the uploaded git blob SHAs**; all 93 referenced image URLs 200.
- Tours.json byte-stable under `json.dumps(indent=2, ensure_ascii=False) + '\n'` before
  editing; key order mirrors the BUE entries exactly.

## Flagged, not actioned

- **The five master-list singles (18/19/22/26/27)** are drafted per the owner's own list but
  were never handed over — tell the owner they exist; a future drop makes them a second
  Chicago batch.
- **Missing-architect-tag list grows a Chicago wing:** Fazlur Rahman Khan (Willis),
  Bertrand Goldberg (Marina City), John Root (Rookery/Monadnock), William Le Baron Jenney
  (Home Insurance), Holabird & Roche, Tod Williams & Billie Tsien (Obama Center) — none in
  `Models/Tag.swift`. FLW/Gehry/Piano used by name; **Daniel Burnham is in the vocabulary
  but the staged pick-map didn't apply it** (kept as staged). The combined Tag.swift PR case
  (Schinkel/Niemeyer/Bo Bardi/Studio KO/Testa/…) keeps compounding.
- **Loop walk stop 1's image is a deliberate archival B&W photograph** of the 1885 Home
  Insurance Building itself (owner-supplied) — the building was demolished in 1931, so no
  modern photo can exist; documented in the pick-map, not a Gate-A violation.
- **Nothing is staged anywhere anymore.** The next city launch requires a fresh drop
  (complete drops with pre-sized images have been the winning shape five times running).

## Next

- Owner: install the over-the-air update path check — Chicago reaches build-50+ users via
  the remote catalog with no build (Supabase seed runs on merge via `publish-catalog.yml`).
- Standing non-content work: Paid tours Phase 3 (buyer UI), launch-runbook Step 1 (prove one
  fastlane TestFlight build), the combined `Models/Tag.swift` architect PR, PR #475 (still
  open — its Berlin fix shipped independently; close or merge its drafts-audit value),
  PR #469 (Paid tours Phase 3 — awaiting owner review).
