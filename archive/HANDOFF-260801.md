# HANDOFF — 2026-08-01 (session 81, web/content)

## What shipped

**Rio de Janeiro launched as the 22nd city/maker.** New maker **Atlas Studio RIO**
🇧🇷 (`016bddbe-c759-56fd-8558-869df74b179b` = uuid5 `atlas-maker:rio`) with **46
single-stop, geofenced (30 m) tours** and **46 MP3s / 5,102 s ≈ 1h25m**.

**Catalog 1040 → 1086 tours / 21 → 22 makers / 1320 → 1366 stops.**

Branch `claude/tour-uploads-audio-scripts-photos-4boyu3`. Assets are already live
on `gh-pages`; the catalog change is one commit touching only `Tours.json`
(+2,035 lines, no deletions), plus this docs commit.

**Not from the audio-pending queue.** Rio arrived complete — audio, scripts and
images together in one drop — and was wired the same day. Berlin and Chicago are
untouched and still pending.

### Coverage

11 foodAndDrink · 7 visualArt · 6 culturalHeritage · 6 musicAndPerformance ·
6 natureAndParks · 5 architecture · 2 history · 2 sacredSites · 1 literature.

It splits roughly in half between the landmarks (Christ the Redeemer, Sugarloaf,
Maracanã, Theatro Municipal, Museu do Amanhã, MAR, Escadaria Selarón, Real
Gabinete, Catedral Metropolitana, Candelária) and the bar/restaurant scene that
gives the city its evenings (Jobi, Bip Bip, Guimas, Oseille, Balcão 201, Boteco
Belmonte, Armazém São Thiago, Libô, Madame Olympe, Grado, Gonza, SO_Lo).
Niemeyer runs through the batch: Casa das Canoas, Hotel Nacional, the Sambódromo,
MAC Niterói, Teatro Popular.

## What was easy, and why it's worth naming

**This was the cleanest delivery the project has had, and the reason is the
images.** All 149 arrived **already 1200×900**, byte-distinct, numbered `01..NN`
per folder with `01` = hero. So the image pipeline, cropping, sourcing, owner
picks and the two-call Gemini verification gate were **all zero work** — the step
that normally dominates a city launch simply did not exist. 46 MP3s and 46
`_clean.txt` / `_tts-safe.txt` pairs mapped 1:1 with nothing spare and nothing
missing.

Folder convention was the Ho Chi Minh City one — `output <Name> <lat>, <long>`
with `#UXXXX` unicode escapes — so coordinates came out of the folder names and
needed no geocoding.

**The Dropbox rule held again.** A `/scl/fo/…` shared-folder link with `dl=1`
returned a 106 MB zip on the first try, confirming the Dubai finding. The `/t/`
Transfer distinction remains the thing to check before declaring a link
undownloadable.

## Open for the owner

1. **⚠️ Oscar Niemeyer is not in the controlled tag vocabulary** — despite five
   Rio tours being his work. Affonso Eduardo Reidy (Pedregulho, MAM), Christian
   de Portzamparc (Cidade das Artes), Lúcio Costa and Roberto Burle Marx are
   likewise absent. Those tours carry **`Designed by a Master`**, the honest
   fallback. `Le Corbusier` (Capanema consultant) and `Santiago Calatrava`
   (Museu do Amanhã) **are** in the vocabulary and are used.
   Adding Niemeyer means editing `Models/Tag.swift` — a **code** change needing
   owner OK + simulator review — so it was deliberately kept out of a content PR.
   He is now the most-represented architect in the catalog without a tag.
2. **4 tours ship hero-only** — Álef Antiguidades, Bip Bip, Hotel Nacional,
   Santa Teresa Tram. Seven more have hero + 1. Backfillable without touching
   audio.
3. **Two tours are in Niterói**, across Guanabara Bay — MAC Niterói and the
   Teatro Popular Oscar Niemeyer, both on the Caminho Niemeyer. They ship under
   the Rio maker with `city: "Niterói"`, following Kyoto's La Collina and HCMC's
   Củ Chi Tunnels. Flagging in case the owner wants them elsewhere.
4. **No merge yet** — merging publishes to real users over the air, so that's the
   owner's call.

## Verification

- **0 errors, 0 warnings across all 1086 tours.** No Swift toolchain in a Linux
  web session, so this ran through a **Python mirror of `validate-tours.swift`**.
- **The mirror parses the vocabulary out of the Swift source rather than
  retyping it, and `load_vocab` raises on an empty parse** — the Dubai near-miss,
  where a mirror silently matched a shape `Tag.swift` no longer used. Parsed
  clean: 88 tags across 5 facets, 10 categories.
- **Self-tested against 23 injected fault classes first — 23/23 caught**
  (bracketed stage direction, SEGMENT header, unknown tag, bad category, bad
  kind, duplicate tour/stop id, hero-in-gallery, duplicate gallery URL, zero
  duration, duration mismatch, out-of-range lat/lon, single-with-2-stops,
  near-duplicate transcripts, bad trigger mode, non-UUID id, dangling makerId,
  missing required key, empty longDescription, invalid hero URL, bad order
  packing, absurd trigger radius). Baseline asserted clean first, so an injected
  fault can't hide behind a pre-existing error.
- **Its one real finding was fixed, not suppressed:** Prainha had two Place types
  and two Experience tags but **no Theme** → added `Maritime`.
- **uuid5 scheme reverse-verified** against the live DXB, YUL, ROM and MAD makers
  *and* a DXB tour/stop pair before minting RIO. 0 duplicate tour/stop/maker ids
  across 1086/1366/22.
- **`check-image-duplicates.py --maker RIO` clean** over 149 images.
- All 46 MP3s decode, 44.1 kHz, **byte-distinct** (the Thyssen duplicate-bug class
  applied to audio).

## gh-pages

Pure plumbing, as Dubai established — blobless (`--filter=blob:none`) fetch, then
`read-tree` into a temp `GIT_INDEX_FILE` → `hash-object -w` → `update-index
--cacheinfo` → **`write-tree --missing-ok`** → `commit-tree` → push the sha.
Commit `76d86e1`.

Two guards worth repeating:

- **Checked that none of the 195 target paths already existed on gh-pages**
  before writing, so nothing could be silently overwritten.
- **Proved the tree diff was exactly 195 additions, 0 deletions, nothing outside
  `audio/` and `images/`** before committing.

**The Pages deploy lagged the push by ~5 minutes and served 404 throughout.**
Rather than wait blind, the run was checked against the Actions API and found
**`in_progress`, not `cancelled`** — the distinction CLAUDE.md warns about. Then
**all 195 assets were confirmed by hashing the downloaded bytes against the
uploaded git blob SHAs** — not by the push succeeding, and not by a 200.

## Transcripts and captions

`transcriptText` = each display script with its **single `[beat]` marker**
stripped (46 of them). The validator hard-errors on any `\[[A-Za-z]` — the same
gotcha as Dubai, Madrid, Rome, Montreal and Ho Chi Minh City.

Captions use the abbreviation-aware splitter (`St.`, `Sr.`, `Dom`, `Av.`, …) and
extend across paragraphs until they clear 60 chars. **Shortest shipped is 73**,
so nothing ships as a fragment.

## Next

- **Audio-pending queue unchanged: Berlin (36 tours / 57 MP3s) + Chicago
  (30 tours / 53 MP3s) = 66 tours / 110 MP3s.** Both image-complete, awaiting
  narration only.
- ⚠️ The two **staging-README errors** found during Dubai (`stop0.imageURL: null`
  on singles; walk `additionalImageURLs` listing every stop image, which
  hard-errors the hero-in-gallery check) are **still unfixed** and will recur on
  both Berlin and Chicago.
- ⚠️ Berlin has the **`St.` caption hazard** flagged since Montreal. The splitter
  handles it; just don't regress it.
