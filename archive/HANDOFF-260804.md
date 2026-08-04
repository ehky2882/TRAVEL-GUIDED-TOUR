# HANDOFF — 2026-08-04 (session 82, web/content)

## What shipped

**São Paulo launched as the 23rd city/maker.** New maker **Atlas Studio SAO**
🇧🇷 (`b366d042-881b-5226-aaa8-1dce36c7a2cb` = uuid5 `atlas-maker:sao`) with
**41 single-stop geofenced (30 m) tours + 1 multi-stop walk**, narrated by
**48 MP3s / 5,279 s ≈ 1h28m**.

**Catalog 1086 → 1128 tours / 22 → 23 makers / 1366 → 1414 stops.**

Branch `claude/tours-upload-9ex1w1`. Assets went to `gh-pages` first
(commit `2984f48`); the catalog change is one commit touching only
`Tours.json` (+1,989 lines, **0 deletions**), plus this docs commit.

**Not from the audio-pending queue.** Like Rio, São Paulo arrived complete —
audio, scripts and images in one drop — and was wired the same day. **Berlin
and Chicago are untouched and still pending** (66 tours / 110 MP3s).

Brazil now has two bureaus (RIO 46, SAO 42).

### The walk

`sao-ibirapuera-walk` — "Ibirapuera Park", manual intro + 6 geofenced stops
at 40 m, 3.0 km, `natureAndParks`. Auditório Ibirapuera → the Oca → Museu
Afro Brasil → Planetário → Pavilhão Japonês → Mirante MAC USP. Unlike
Dubai's and Montreal's walks it reuses **no** single-stop hero — every stop
image is walk-owned (`sao-ibirapuera-walk_stopN_*`), so the hero-in-gallery
trap needed handling only within the walk's own image set (hero = stop 1,
gallery = the other six).

### Coverage

13 culturalHeritage · 9 foodAndDrink · 8 visualArt · 5 architecture ·
5 musicAndPerformance · 1 hiddenGems · 1 natureAndParks.

It splits between the modernist canon — MASP, Copan, SESC Pompéia, SESC 24
de Maio, Casa de Vidro, Pinacoteca, Memorial da América Latina, the whole
Ibirapuera ensemble — and the restaurant, bar and design scene the city
actually runs on: A Casa do Porco, Nelita, Jacó, KOTORI, Hirá, Varal, Dōmo,
Misci, Monica Pondé, VERNIZ, Casa Teo.

## What was easy, and what that now tells us

**Second delivery running that needed zero image work.** All **173 images
arrived already 1200×900**, byte-distinct, numbered `01..NN` per folder with
`01` = hero. No pipeline, no cropping, no Openverse/Unsplash sourcing, no
two-call Gemini gate, no owner picks. 48 MP3s and 48 `_clean.txt` /
`_ttssafe.txt` pairs mapped 1:1 with nothing spare and nothing missing.

Folder convention was Rio's and Ho Chi Minh City's — `output <Name> <lat>,
<long>` with `#UXXXX` escapes — so coordinates came out of folder names and
needed no geocoding.

**Two cities in a row like this is a pattern, not luck.** Worth telling the
owner plainly: a drop shaped this way turns a multi-session city launch into
a single session. The expensive part of a launch is image sourcing, and this
shape removes it entirely.

**The Dropbox rule held again.** A `/scl/fo/…` shared-folder link with
`dl=1` returned a 106 MB zip on the first try. The `/t/` Transfer
distinction remains the thing to check before declaring a link
undownloadable.

## Verification

- **Validator: 0 errors, 0 warnings across all 1128 tours**, via the Python
  mirror of `validate-tours.swift`. This revision **parses the vocabulary out
  of the validator AND cross-checks it against `Models/Tag.swift`**, raising
  if the two disagree or if either parse returns empty — closing the Dubai
  failure mode where a mirror silently matched nothing. **Self-tested against
  26 injected fault classes first: 26/26 caught.**
- **uuid5 scheme reverse-verified** against the live RIO/DXB/YUL/ROM/MAD
  makers, a live tour/stop pair (Álef Antiguidades) and a live walk's stops
  (Dubai Creek Crossing) before minting SAO. 0 duplicate tour/stop/maker ids
  across 1128/1414/23.
- **Assets-first via pure plumbing** — blobless fetch, `read-tree` into a temp
  `GIT_INDEX_FILE`, `hash-object -w`, `update-index --cacheinfo`,
  `write-tree --missing-ok`, `commit-tree`. Verified **before** committing
  that the tree diff was exactly **221 additions, 0 deletions, nothing
  outside `audio/` and `images/`**, and that **none of the 221 paths already
  existed on gh-pages**.
- **Pages deploy lagged the push**, serving 404 throughout. Checked against
  the Actions API and found **`in_progress`, not `cancelled`** — the
  distinction CLAUDE.md warns about. Assets confirmed by hashing downloaded
  bytes against the uploaded git blobs, not by the push succeeding.

## The bug this session caught, and how

`check-image-duplicates.py --maker SAO` passed on the first run — but it
reported **161 images when 173 had been uploaded**. Chasing that 12-image gap
found a real defect: **a walk stop can carry only ONE `imageURL`**, so every
*additional* photo of a walk stop is invisible unless it also appears in the
walk's `additionalImageURLs`. The first pass put only the seven stop *heroes*
in the gallery, which left **12 uploaded-but-unreferenced images** — including
five of the six photos the owner supplied of the Auditório Ibirapuera.

Nothing would have failed. The validator passes, every URL returns 200, the
duplicate check exits 0. The images would simply never have been seen.

Fixed by putting all 19 walk images into the gallery in stop order (hero
excluded) — 18 entries, well within convention: existing walks run to 13
gallery entries on a 7-stop walk and 30 on a 20-stop one. Now **173 uploaded,
173 referenced, 0 orphaned, 0 dangling.**

**Durable check for any future walk wire-in:** compare the maker's uploaded
image count against the count `check-image-duplicates.py` reports. They should
be equal. A shortfall means images exist that nothing points at — and the tool
prints the number without flagging the discrepancy, so it only surfaces if you
read it. This applies to Berlin and Chicago, whose walks have multi-image stops.

## A reusable finding: don't copy the first tour's key order

The first single in `Tours.json` is **not** representative of the file. The
dominant convention — 768 tours, and both Rio and Dubai — gives singles the
**full** key set: explicit `introAudioURL: null`, `walkingDistanceMeters:
null`, and `centroidLatitude`/`centroidLongitude` mirroring the single stop
at **full coordinate precision** (not rounded).

Matching that exactly produced a diff of **1,989 insertions / 0 deletions**.
Rounding the coordinates to 6 dp, or omitting the nulls, would have
reformatted unrelated lines and buried the real change. Worth checking key
signatures against the most *recent* maker, not the first entry, on every
future wire-in.

## Open for the owner

1. **⚠️ The missing-architect-tag problem is much sharper in São Paulo than
   it was in Rio, and the two together make a strong case.** São Paulo's
   canon is almost entirely architects absent from the controlled vocabulary:
   **Lina Bo Bardi ×4** (Casa de Vidro, MASP, SESC Pompéia, Teatro Oficina),
   **Paulo Mendes da Rocha ×3** (Galeria Leme, Pinacoteca, SESC 24 de Maio),
   **Oscar Niemeyer ×3** plus the entire Ibirapuera walk, **Vilanova Artigas
   ×2** (Morumbi, his own houses), **Ramos de Azevedo ×3**, **Rino Levi ×2**,
   and Burle Marx. All ship as `Designed by a Master`, the honest fallback.
   `Kengo Kuma` (Japan House) and `Jean Nouvel` (Cidade Matarazzo) **are** in
   the vocabulary and are used by name.
   Adding the missing names means editing `Models/Tag.swift` — a **code**
   change needing owner OK + simulator review — so it was deliberately kept
   out of a content PR, same as Rio. Between the two Brazilian bureaus,
   Niemeyer, Bo Bardi and Mendes da Rocha are now among the most-represented
   architects in the catalog with no tag of their own.

2. **⚠️ Mercado Municipal de Campinas is not in São Paulo.** It sits at
   `-22.9030, -47.0638` — Campinas, ~90 km northwest, a different
   municipality. It ships under the SAO maker with `city: "Campinas"`,
   following Rio's Niterói pair, HCMC's Củ Chi Tunnels and Kyoto's La
   Collina. Flagging rather than silently relabelling; say if you'd rather it
   moved or dropped.

3. **⚠️ MAC USP appears twice, deliberately.** Once as a single-stop tour
   about the museum and its collection, and again as walk stop 6 (`Mirante
   MAC USP`) about the free public rooftop. Different scripts, different
   subjects, ~30 m apart. Not a duplicate — noted here so nobody "fixes" it
   later.

4. **4 tours ship hero-only** — Estádio do Morumbi, Feira Benedito Calixto,
   Nubank Parque, Residências Vilanova Artigas — as do walk stops 0 and 6.
   Backfillable any time without touching audio.

5. **One source filename was typo'd**: `lanetário do Ibirapuera.mp3` is
   missing its leading "P". Harmless — it was mapped to the correct
   `sao-ibirapuera-walk_stop4.mp3` — but worth a look at whatever produced it.

## Still pending after this session

**Berlin (36 tours / 57 MP3s) + Chicago (30 tours / 53 MP3s) = 66 tours /
110 MP3s.** Both image-complete on
`claude/amsterdam-handoff-preserve-hlhyp8`, awaiting narration only.
Unchanged by this session.

⚠️ The two staging-README errors recorded at Dubai still apply to both and
are still unfixed in those READMEs: singles should set `stop0.imageURL` to
the tour hero (not `null`), and a walk's `additionalImageURLs` must **drop**
whichever stop image is used as the walk hero, or the validator hard-errors
on `heroImageURL also appears in additionalImageURLs`.
