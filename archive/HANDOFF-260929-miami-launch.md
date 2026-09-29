# Handoff 2026-09-29: Miami launches (Atlas Studio MIA, 30 singles)

**What shipped:** a new bureau, **Atlas Studio MIA** 🇺🇸 (maker id `aed488af-23d3-514f-90f1-035ca2285d0d`
= uuid5 `atlas-maker:mia`, `NAMESPACE_URL`), the **38th studio**, with **30 single-stop tours**. The
catalogue went from 1683 to 1713 tours and from 549 to 550 makers. Tour/stop ids are uuid5
`atlas-tour:mia:<slug>` / `atlas-stop:mia:<slug>:1`, the same scheme as ATL, reverse-verified
against Atlanta's live ids. Cities and countries did not move, because creator pins already
covered Miami and Miami Beach. Eight tours carry `city: "Miami Beach"`, matching the existing
pins there; 22 carry `Miami`.

**Source:** the owner's Dropbox `/scl/fo/` drop, 101 MB. It held the 30 single MP3s, **33 MP3s for
five walks**, and three planning docs. The single MP3s run 1.99–2.49 min, 67.9 min in all, in
three encodings (128k mono 48 kHz, 64k mono 48 kHz, 128k stereo 44.1 kHz). All play. There are no
duplicate files. Each file's speaking rate against its script's word count was 164–191 wpm,
median 174, so no file looks mislabelled. That check cannot catch a swap between two
similar-length files. `miami_18_miami_river_lummus_park.txt.mp3` had a stray `.txt`. It was
renamed on upload, like every file, to `audio/<slug>.mp3`.

**Assembled from the staged pick-map** (`drafts/miami-batch1/README.md` on
`claude/new-city-staging-260925`). Coordinates, radii and categories are verbatim from it. The
assembler lives only in the scratchpad. Its rules:
- **Tour titles are shortened** (e.g. "Royal Palm Hotel Site", not "Flagler Street at the
  river, the Royal Palm Hotel site").
- `transcriptText` is the clean script, minus its header and `*[beat]*` lines.
- `shortDescription` is the transcript cut to 145 characters.
- `longDescription` is paragraph 1 plus the first paragraph after the standpoint paragraph.
- `caption` is the standpoint sentence ("You should be…", "You are…", "You're…"). Seven scripts
  have no standpoint paragraph (08, 09, 10, 11, 25, 29, 30); their caption is the opening
  sentence.
- ⚠️ The clean scripts spell some numbers for speech, so captions read "three oh one Washington
  Avenue" and "eleven sixteen Ocean Drive". This is left verbatim.

**Images:** 87 references, all present on gh-pages. The mix:
- **Commons photos** (60 credit rows, owner option 1). See `drafts/CREDITS.md` § Miami, and
  § Correction 2026-09-29 of `HANDOFF-260925-miami-staging.md`.
- **Owner photographs**, AI-edited, used on the owner's decision.
- **The Overtown aerial.** Its source is unknown. Reverse-search it before relying on it.

**Checks:**
- Validator mirror: 0 errors, 0 Miami warnings. Overtown gained a `District` place-type tag.
- `check-image-duplicates --maker MIA`: 87 images, OK.
- `spine-lookup`: 30 asked, 0 failed.
- `check-city-outliers`: no Miami tour. It exits 1 on `main` too, because of four Homestead-area
  pins.
- `join-places --max-move 100`: only an unrelated Rome entry.
- The coordinate audit was done at staging: GROSS none, no bias.

## Places: the owner said "join all" (done in the same PR)
`check-place-candidates` found five new tours sitting on existing creator pins.
- **Four new places**, each on the point its two members already shared, so nothing moved:
  *The Barnacle*, *Miami-Dade County Courthouse*, *Historic Virginia Key Beach Park* and *Casa
  Casuarina*. The last one pairs the house with the pin for its mosaic pool, which is a
  part-vs-whole case; the owner ruled it in. Ids use the documented
  `atlas-place:{slug(city)}:{slug(name)}` formula.
- **Vizcaya joined the existing place** *Vizcaya Museum and Gardens* (`8cf359f8…`), which already
  held the two creator pins at OSM's estate point. The tour's stop moved **113 m**, from
  25.744381,-80.210502 onto 25.744699,-80.211577, and its radius went **100 → 120 m** so the
  entrance drive the script is written for stays inside the circle.
- The catalogue has 452 → 456 places. The validator reports 0 errors, and a re-run of
  `check-place-candidates` lists no Miami group.

## Not done
- **The five walks** (W1 *The Pitch*, W2 *Ocean Drive*, W3 *Calle Ocho*, W4 *The Grove*, W5 *The
  Water Line*; 33 MP3s). Scripts, stop coordinates and images were never staged. See the tracker's
  PENDING row. The MP3s are only in the owner's drop.
- **Architect tags** missing for Lapidus (07, 24), Treister (22), Hohauser (06), Enrique Gutiérrez
  (28) and Schultze & Weaver (02). Those tours carry *Designed by a Master*. A Job 5 PR can add
  them.
- **10 Commons licences unverified** (Commons 429 all day), and the Overtown provenance.
- The author's own **pre-record flags 25–66** (factual claims to verify or soften) are listed as
  open in `miami_session_handoff.md` in the drop.
