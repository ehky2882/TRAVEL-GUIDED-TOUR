# HANDOFF — 2026-08-07 (session 85, web) — Marrakech launched: 26 tours + 25th maker Atlas Studio RAK

**One-line summary:** Marrakech goes live as the catalog's **first African city** — 26 single-stop
tours under new maker **Atlas Studio RAK** 🇲🇦, wired the same day the owner's complete Dropbox
drop arrived. Catalog **1164 → 1190 tours / 24 → 25 makers / 1471 → 1497 stops**. The
audio-pending queue is untouched: **Chicago alone, 30 tours / 53 MP3s.**

Branch: `claude/new-tours-upload-nxezi4`.

## What shipped

- **New maker:** Atlas Studio RAK (`c4e51efc-846e-5e78-b699-67e7f9d203e8` = uuid5
  `atlas-maker:rak`, 🇲🇦), the 25th.
- **26 single-stop tours**, all geofenced 30 m, 26 MP3s (3,093 s ≈ 51.5 min, 44.1 kHz/128 kbps):
  Aït Benhaddou · Almoravid Koubba · Bacha Coffee · Bahia Palace · Baromètre · Dar Si Said
  Museum · El Badi Palace · El Fenn Boutique · Jajjah by Hassan Hajjaj · Jardin Majorelle ·
  Jemaa el-Fna · Kabana Rooftop · Koutoubia · La Grande Table Marocaine · Le Jardin Secret ·
  Le MAP — Monde des Arts de la Parure · L'mida · MACAAL · Madrasah Ben Youssef · Marrakech
  Museum · MCC Gallery · Menara Gardens · Nomad Marrakech · Saadian Tombs · Sahbi Sahbi ·
  Yves Saint Laurent Museum.
- **Category mix:** 7 foodAndDrink · 6 culturalHeritage · 3 natureAndParks · 3 visualArt ·
  2 history · 2 sacredSites · 2 architecture · 1 hiddenGems.
- **Assets:** 26 MP3s + 109 images to `gh-pages` (commit `4b45432`), Tours.json diff
  **1,191 insertions / 0 deletions**.

## The delivery — third zero-image-work drop, and the cleanest scripts yet

- Dropbox `/scl/fo/` shared-folder link, 66 MB zip, **downloaded first try** with `dl=1` —
  the Dubai/Rio/Berlin transport rule holds again.
- Same `output <Name> <lat>, <long> <native>` folder convention (`#UXXXX`-escaped), Arabic
  script this time. 26 folders, each exactly 1 MP3 + `_clean`/`_tts-safe` script pair +
  2–6 images. Nothing spare, nothing missing.
- **All 109 images arrived already 1200×900**, byte-distinct, numbered `01..NN` with `01` =
  hero — no pipeline, no cropping, no owner picks, no Gemini gate (Rio/São Paulo shape).
- **0 `[beat]` markers across all 26 scripts** (Berlin had 42, Rome 44) — the cleanest set any
  city has delivered. The only header is a bare title line, stripped for `transcriptText`.
- Slugs derived from the `_clean.txt` filename stems (underscores → hyphens), giving an
  unambiguous 1:1 mapping back to the source folders.

## First Arabic-script city

- **Bilingual `English | العربية` titles on 18 of 26** (tour + stop). The other 8 are
  proper-noun venues carrying a single name, per the SGN convention: Baromètre, El Fenn
  Boutique, Jajjah, La Grande Table Marocaine, Le MAP, MACAAL, MCC Gallery, Sahbi Sahbi.
- Two supplied Arabic names cleaned (Kyoto precedent): Nomad's run-together `نومادمراكش` →
  `نوماد مراكش`, and the YSL Museum's folder-name-truncated `متحف إيف سان لورا` →
  `متحف إيف سان لوران`.

## Flagged, not actioned

- **⚠️ Aït Benhaddou is ~180 km southeast of Marrakech** (`31.048, -7.132`, near Ouarzazate) —
  ships under RAK with `city: "Aït Benhaddou"`, the Campinas/Niterói/Củ Chi convention. All
  other 25 coordinates sanity-checked inside greater Marrakech (Jajjah + MCC Gallery are Sidi
  Ghanem on the north edge; MACAAL is Al Maaden).
- **⚠️ Studio KO is not in the controlled tag vocabulary — and Marrakech is *their* city.**
  The Yves Saint Laurent Museum (the building that made their name) and Sahbi Sahbi both ship
  with `Designed by a Master` as the honest fallback. Jacques Majorelle (painter) and Paul
  Sinoir also absent. Same class as the Schinkel / Niemeyer / Bo Bardi gap — the combined
  `Models/Tag.swift` PR keeps getting stronger. (A code change needing owner OK + sim review,
  so again deliberately kept out of a content PR.)
- **✅ No tour ships hero-only** — minimum gallery is hero + 1 (Jemaa el-Fna, Almoravid
  Koubba); most carry hero + 3–5.

## Verification

- **0 errors, 0 warnings across all 1190 tours**, via the Python mirror of
  `validate-tours.swift` (no Swift toolchain in a Linux web session). The mirror parses the
  tag vocabulary from **both** `Models/Tag.swift` **and** the Swift validator and raises if
  the two disagree or either parse is empty; **self-tested against 34 injected fault classes
  first — 34/34 caught** (including decode-level classes: bad kind/category/triggerMode,
  non-UUID ids, bad createdAt).
- **uuid5 scheme reverse-verified** against 7 live makers (BER/SAO/RIO/DXB/YUL/ROM/MAD) plus
  the Brandenburg Gate tour/stop pair and a Rio tour before minting RAK. 0 duplicate
  tour/stop/maker ids across 1190/1497/25.
- `check-image-duplicates.py --maker RAK` clean; **109 uploaded = 109 referenced, 0 orphaned**
  (the São Paulo count rule).
- **All 135 asset URLs live-verified by hashing downloaded bytes against the uploaded git
  blob SHAs**, not by 200s. The Pages deploy lagged serving 404; the Actions API showed
  **`in_progress`, not `cancelled`** (the CLAUDE.md distinction).

## Mechanics (established playbook, nothing novel)

- **Assets-first via pure plumbing:** blobless fetch → `read-tree` into a temp
  `GIT_INDEX_FILE` → `hash-object -w` → `update-index --cacheinfo` →
  `write-tree --missing-ok` → `commit-tree` → push sha. Verified **none of the 135 target
  paths pre-existed** and the tree diff was **exactly 135 additions, 0 deletions, nothing
  outside `audio/` + `images/`** before committing.
- **Key-order discipline:** full single-stop key set with explicit `introAudioURL: null` /
  `walkingDistanceMeters: null`, centroid mirroring the stop at full source precision;
  Tours.json confirmed **byte-stable under a Python re-dump before editing**, so the append
  produced no unrelated line churn.
- Captions = script opening sentence(s) extended past 60 chars with the abbreviation-safe
  splitter; `shortDescription`/`longDescription` freshly written per tour (the
  Gendarmenmarkt/Jobi pattern).

## Queue after this session

**Chicago alone: 30 tours / 53 MP3s** — image-complete, awaiting narration only, staged on
`claude/amsterdam-handoff-preserve-hlhyp8` (new maker Atlas Studio ORD at wire-in).
⚠️ Chicago's staging READMEs still carry the two known spec errors (singles
`stop0.imageURL: null`, walk galleries listing the hero) — correct them at wire-in exactly as
Dubai/Berlin did.
